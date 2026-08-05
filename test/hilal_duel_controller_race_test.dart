import 'dart:async';

import 'package:arin/core/ads/admob_ids.dart';
import 'package:arin/data/services/admob_service.dart';
import 'package:arin/presentation/qibla/hilal_duel/hilal_duel_controller.dart';
import 'package:arin/presentation/qibla/hilal_duel/hilal_duel_repository.dart';
import 'package:arin/presentation/qibla/hilal_duel/hilal_duel_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAdMob extends AdMobService {
  @override
  Future<bool> showInterstitial(ArinAdUnit unit) async => false;

  @override
  Future<RewardedAdResult> showRewardedDetailed(
    ArinAdUnit unit, {
    String? serverSideCustomData,
  }) async {
    return RewardedAdResult.notRewarded;
  }
}

/// Delayed start + cancel that only succeeds after a waiting queue exists.
class _RaceRepo implements HilalDuelRepositoryApi {
  final Completer<void> startGate = Completer<void>();
  final List<String> calls = <String>[];
  int startCount = 0;
  int cancelCount = 0;
  bool queueWaiting = false;
  bool charged = false;
  bool orphanedAfterDispose = false;

  @override
  Future<HilalDuelProfileBundle> loadProfile(String name) async {
    calls.add('loadProfile');
    return HilalDuelProfileBundle(
      profile: HilalDuelProfile(
        name: name,
        hilals: 0,
        level: 1,
        levelFloorHilals: 0,
        nextLevelHilals: 40,
        hearts: 3,
        premium: false,
      ),
      queue: queueWaiting
          ? HilalDuelMatchStart(
              status: 'waiting',
              queuedAtMs: DateTime.now().millisecondsSinceEpoch,
            )
          : null,
    );
  }

  @override
  Future<HilalDuelMatchStart> startMatch(String name) async {
    startCount += 1;
    calls.add('start:begin');
    charged = true;
    await startGate.future;
    queueWaiting = true;
    calls.add('start:complete');
    return HilalDuelMatchStart(
      status: 'waiting',
      queuedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<HilalDuelMatchStart> cancelMatchmaking() async {
    cancelCount += 1;
    calls.add('cancel');
    if (!queueWaiting) {
      // Premature cancel — idle before queue exists (the bug).
      return const HilalDuelMatchStart(status: 'idle');
    }
    queueWaiting = false;
    charged = false;
    return const HilalDuelMatchStart(status: 'idle', refunded: true);
  }

  @override
  Future<HilalDuelMatchStart> pollMatch() async {
    calls.add('poll');
    if (queueWaiting) {
      return HilalDuelMatchStart(
        status: 'waiting',
        queuedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    }
    return const HilalDuelMatchStart(status: 'idle');
  }

  @override
  Future<HilalDuelMatch> loadMatch(String matchId) async {
    throw UnsupportedError('loadMatch');
  }

  @override
  Future<HilalDuelMatch> submitAnswer({
    required String matchId,
    required int round,
    required int choice,
  }) async {
    throw UnsupportedError('submitAnswer');
  }

  @override
  Future<HilalDuelMatch> forfeitMatch(String matchId) async {
    throw UnsupportedError('forfeitMatch');
  }

  @override
  Future<HilalDuelWeeklyBoard> loadWeeklyLeaderboard() async {
    throw UnsupportedError('loadWeeklyLeaderboard');
  }

  @override
  Future<HilalDuelRewardProof> beginReward({
    required String purpose,
    String? matchId,
  }) async {
    throw UnsupportedError('beginReward');
  }

  @override
  Future<void> claimReward(String proofId) async {}

  @override
  void clearCredentialsCache() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'cancel button awaits start: no premature cancel, single charge, refund',
    () async {
      final repo = _RaceRepo();
      final controller = HilalDuelController(
        repository: repo,
        adMob: _FakeAdMob(),
        displayName: () => 'Test',
      );

      await controller.bootstrap();
      expect(controller.phase, HilalDuelPhase.lobby);

      final startFuture = controller.startMatchmaking();
      // Start RPC in flight — queue not yet committed.
      await Future<void>.delayed(Duration.zero);
      expect(repo.startCount, 1);
      expect(controller.startInFlight, isTrue);
      expect(controller.queueMayExist, isTrue);

      final cancelFuture = controller.cancelMatchmaking();
      // Cancel must NOT hit the repo before start settles.
      await Future<void>.delayed(Duration.zero);
      expect(repo.cancelCount, 0, reason: 'cancel RPC before start completes');
      expect(repo.calls.where((c) => c == 'cancel'), isEmpty);

      // Duplicate start while cancel pending must be ignored.
      await controller.startMatchmaking();
      expect(repo.startCount, 1, reason: 'second start must not charge again');

      repo.startGate.complete();
      await startFuture;
      final cancelResult = await cancelFuture;

      expect(cancelResult, isNull);
      expect(repo.startCount, 1);
      expect(repo.cancelCount, 1);
      expect(repo.queueWaiting, isFalse);
      expect(repo.charged, isFalse);
      expect(controller.phase, HilalDuelPhase.lobby);
      expect(controller.requiresCancelBeforeLeave, isFalse);
      expect(
        repo.calls,
        containsAllInOrder(['start:begin', 'start:complete', 'cancel']),
      );

      // Dispose after clean cancel must not orphan a waiting queue.
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(repo.queueWaiting, isFalse);
      expect(repo.cancelCount, 1, reason: 'no extra dispose cancel needed');
    },
  );

  test(
    'dispose during in-flight start cancels after start; no orphan queue',
    () async {
      final repo = _RaceRepo();
      final controller = HilalDuelController(
        repository: repo,
        adMob: _FakeAdMob(),
        displayName: () => 'Test',
      );
      await controller.bootstrap();

      unawaited(controller.startMatchmaking());
      await Future<void>.delayed(Duration.zero);
      expect(repo.cancelCount, 0);

      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      // Dispose cancel must wait for start — no premature cancel yet.
      expect(repo.cancelCount, 0);

      repo.startGate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repo.startCount, 1);
      expect(repo.cancelCount, greaterThanOrEqualTo(1));
      expect(repo.queueWaiting, isFalse);
      expect(repo.charged, isFalse);
    },
  );

  test(
    'retryCancel also waits for in-flight start before cancel RPC',
    () async {
      final repo = _RaceRepo();
      final controller = HilalDuelController(
        repository: repo,
        adMob: _FakeAdMob(),
        displayName: () => 'Test',
      );
      await controller.bootstrap();

      unawaited(controller.startMatchmaking());
      await Future<void>.delayed(Duration.zero);

      // Force cancelRetry-like path: request cancel while start pending.
      final retry = controller.retryCancel();
      await Future<void>.delayed(Duration.zero);
      expect(repo.cancelCount, 0);

      repo.startGate.complete();
      await retry;

      expect(repo.cancelCount, 1);
      expect(repo.charged, isFalse);
      expect(controller.phase, HilalDuelPhase.lobby);
      controller.dispose();
    },
  );

  test('shouldRefreshQuizCredentialsCache pure decisions', () {
    expect(
      shouldRefreshQuizCredentialsCache(
        hasCachedSession: true,
        hasCurrentUser: false,
      ),
      isTrue,
    );
    expect(
      shouldRefreshQuizCredentialsCache(
        hasCachedSession: true,
        hasCurrentUser: true,
      ),
      isFalse,
    );
    expect(
      shouldRefreshQuizCredentialsCache(
        hasCachedSession: false,
        hasCurrentUser: false,
      ),
      isFalse,
    );
  });

  test('cancelMayIssueRpc gated on pending start', () {
    expect(cancelMayIssueRpc(startFuturePending: true), isFalse);
    expect(cancelMayIssueRpc(startFuturePending: false), isTrue);
  });
}
