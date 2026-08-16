import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ads/admob_ids.dart';
import '../../../core/analytics/arin_analytics.dart';
import '../../../core/constants/product_metric_features.dart';
import '../../../data/services/admob_service.dart';
import '../../../data/services/product_metrics_service.dart';
import 'hilal_duel_level.dart';
import 'hilal_duel_repository.dart';
import 'hilal_duel_sfx.dart';
import 'hilal_duel_sync.dart';

enum HilalDuelPhase {
  loading,
  lobby,
  matchmaking,
  playing,
  result,
  error,

  /// İptal RPC başarısız; pop engelli, yeniden dene.
  cancelRetry,
}

class HilalDuelController extends ChangeNotifier {
  HilalDuelController({
    required HilalDuelRepositoryApi repository,
    required AdMobService adMob,
    required String Function() displayName,
  }) : _repository = repository,
       _adMob = adMob,
       _displayName = displayName;

  static const _pendingHeartProofKey =
      'arin_hilal_duel_pending_heart_proof_v1';
  static const _pendingHeartProofExpiryKey =
      'arin_hilal_duel_pending_heart_proof_expiry_v1';
  static const _queueWait = Duration(seconds: 15);
  static const _pollInterval = Duration(milliseconds: 900);
  /// Rakip/bot cevabı beklerken daha sık yokla — sonuç geç düşmesin.
  static const _awaitingPollInterval = Duration(milliseconds: 350);

  /// UI, can/reklam kartını bu jetonla ayırt eder (ham kırmızı yazı göstermez).
  static const needHeartErrorToken = 'NEED_HEART';

  final HilalDuelRepositoryApi _repository;
  final AdMobService _adMob;
  final String Function() _displayName;

  HilalDuelPhase phase = HilalDuelPhase.loading;
  HilalDuelProfile? profile;
  HilalDuelMatch? match;
  List<HilalDuelChallengeSummary> challenges = const [];
  String? errorMessage;
  int? queuedAtMs;
  bool busy = false;
  bool doubledThisMatch = false;
  bool challengeMode = false;
  /// Challenger bitirdi → lobide tek seferlik 24 saat bilgilendirmesi.
  String? challengeSentNoticeOpponentName;
  int? selectedChoice;
  bool awaitingOpponent = false;
  /// Tur çözümü şıklar üzerinde; cihaz saatine bağlı değil (yerel timer).
  bool revealingResolution = false;
  /// Reveal / beklerken yerel ipucu; sunucu `-1` yazdıysa skor için kullanılmaz.
  int? lastSubmittedChoice;
  int? lastSubmittedRound;
  /// Oyun içi doğru/yanlış tahtası (sunucu çözümüne göre, tur indeksli).
  List<HilalDuelRoundMark> selfRoundMarks = const [];
  List<HilalDuelRoundMark> opponentRoundMarks = const [];

  HilalDuelQueueArms _arms = const HilalDuelQueueArms();

  static const _revealHold = Duration(milliseconds: 2600);

  Timer? _pollTimer;
  Timer? _queueTimer;
  Timer? _revealTimer;
  bool _disposed = false;
  String? _activeMatchId;
  int _matchRequestSeq = 0;
  bool _disposeCancelScheduled = false;
  bool _queuePollInFlight = false;
  bool _matchPollInFlight = false;
  bool _botAssignRequested = false;
  bool _heartProofRecoveryInFlight = false;
  bool _finalRevealScheduled = false;
  /// Aynı lastResolution.round için reveal bir kez başlatılır.
  int? _revealForRound;
  /// start/waiting sunucuda onaylanmadan poll yapılmaz.
  bool _queueConfirmed = false;
  Completer<HilalDuelLeaveSettle>? _leaveCompleter;
  Future<void>? _startFuture;
  Future<HilalDuelLeaveSettle>? _cancelFuture;

  bool get startInFlight => _arms.startInFlight;
  bool get queueMayExist => _arms.queueMayExist;
  bool get cancelPending => _arms.cancelPending;
  bool get requiresCancelBeforeLeave => _arms.requiresCancelBeforeLeave;
  bool get showCancelRetry => phase == HilalDuelPhase.cancelRetry;

  Future<void> bootstrap() async {
    phase = HilalDuelPhase.loading;
    errorMessage = null;
    _safeNotify();
    try {
      HilalDuelProfileBundle bundle;
      try {
        bundle = await _repository.loadProfile(_displayName());
      } on FirebaseFunctionsException catch (error) {
        // İlk açılışta App Check / oturum gecikmesi olabilir; bir kez temizleyip dene.
        final code = error.code.toLowerCase();
        final msg = (error.message ?? '').toLowerCase();
        if (code != 'unauthenticated' && !msg.contains('unauthenticated')) {
          rethrow;
        }
        _repository.clearCredentialsCache();
        bundle = await _repository.loadProfile(_displayName());
      }
      if (_disposed) return;
      profile = bundle.profile;
      unawaited(_recoverPendingHeartReward());
      final queue = bundle.queue;
      if (queue != null && queue.matched && queue.matchId != null) {
        await _enterMatch(queue.matchId!);
        return;
      }
      if (queue != null && queue.waiting) {
        _beginConfirmedMatchmaking(queue.queuedAtMs);
        unawaited(ArinAnalytics.hilalDuelLobbyOpen());
        _safeNotify();
        return;
      }
      _arms = afterQueueConfirmedAbsent(_arms);
      phase = HilalDuelPhase.lobby;
      unawaited(refreshChallenges());
      unawaited(ArinAnalytics.hilalDuelLobbyOpen());
    } catch (error) {
      if (_disposed) return;
      phase = HilalDuelPhase.error;
      errorMessage = _friendlyError(error);
    }
    _safeNotify();
  }

  Future<void> refreshProfile() async {
    if (_disposed) return;
    try {
      final bundle = await _repository.loadProfile(_displayName());
      if (_disposed) return;
      profile = bundle.profile;
      _safeNotify();
    } catch (_) {}
  }

  Future<void> refreshChallenges() async {
    if (_disposed) return;
    try {
      final items = await _repository.listChallenges();
      if (_disposed) return;
      challenges = items;
      _safeNotify();
    } catch (_) {}
  }

  Future<void> createChallenge(
    String opponentOwnerHash, {
    bool autoPlay = false,
  }) async {
    if (busy || _disposed || opponentOwnerHash.trim().isEmpty) return;
    final p = profile;
    if (p != null && !p.premium && p.hearts <= 0) {
      errorMessage = needHeartErrorToken;
      _safeNotify();
      return;
    }
    busy = true;
    errorMessage = null;
    _safeNotify();
    try {
      final created = await _repository.createChallenge(
        name: _displayName(),
        opponentOwnerHash: opponentOwnerHash.trim(),
        autoPlay: autoPlay,
      );
      if (_disposed) return;
      await refreshProfile();
      if (autoPlay) {
        await _returnToLobbyAfterChallengeSent(created);
        return;
      }
      await _enterChallenge(created.id, seed: created);
    } catch (error) {
      if (_disposed) return;
      errorMessage = _friendlyError(error);
      phase = HilalDuelPhase.lobby;
      _safeNotify();
    } finally {
      busy = false;
      if (!_disposed) _safeNotify();
    }
  }

  Future<void> acceptChallenge(String challengeId) async {
    if (busy || _disposed || challengeId.trim().isEmpty) return;
    final p = profile;
    if (p != null && !p.premium && p.hearts <= 0) {
      errorMessage = needHeartErrorToken;
      _safeNotify();
      return;
    }
    busy = true;
    errorMessage = null;
    _safeNotify();
    try {
      final accepted = await _repository.acceptChallenge(challengeId.trim());
      if (_disposed) return;
      await refreshProfile();
      if (accepted.isCompleted) {
        challengeMode = true;
        _activeMatchId = accepted.id;
        match = accepted;
        _hydrateResultRoundMarks(accepted);
        phase = HilalDuelPhase.result;
        unawaited(refreshChallenges());
        _safeNotify();
        return;
      }
      await _enterChallenge(accepted.id, seed: accepted);
    } catch (error) {
      if (_disposed) return;
      errorMessage = _friendlyError(error);
      phase = HilalDuelPhase.lobby;
      unawaited(refreshChallenges());
      _safeNotify();
    } finally {
      busy = false;
      if (!_disposed) _safeNotify();
    }
  }

  Future<void> openChallenge(String challengeId) async {
    if (busy || _disposed || challengeId.trim().isEmpty) return;
    busy = true;
    errorMessage = null;
    _safeNotify();
    try {
      final loaded = await _repository.loadChallenge(challengeId.trim());
      if (_disposed) return;
      if (loaded.canAccept) {
        busy = false;
        await acceptChallenge(challengeId);
        return;
      }
      if (loaded.isChallengePlayable && loaded.myTurn) {
        await _enterChallenge(loaded.id, seed: loaded);
        return;
      }
      if (loaded.isCompleted) {
        challengeMode = true;
        _activeMatchId = loaded.id;
        match = loaded;
        _hydrateResultRoundMarks(loaded);
        phase = HilalDuelPhase.result;
        _safeNotify();
        return;
      }
      phase = HilalDuelPhase.lobby;
      unawaited(refreshChallenges());
    } catch (error) {
      if (_disposed) return;
      errorMessage = _friendlyError(error);
      phase = HilalDuelPhase.lobby;
    } finally {
      busy = false;
      if (!_disposed) _safeNotify();
    }
  }

  Future<void> startMatchmaking() async {
    // cancel/start tek uçuş: iptal sürerken veya start uçarken ikinci start yok.
    if (busy ||
        _disposed ||
        _arms.startInFlight ||
        _arms.cancelPending ||
        _cancelFuture != null ||
        _startFuture != null) {
      return;
    }
    final p = profile;
    // 0 can: matchmaking ekranına hiç girme (UI de uyarır; burada savunma).
    if (p != null && !p.premium && p.hearts <= 0) {
      phase = HilalDuelPhase.lobby;
      errorMessage = needHeartErrorToken;
      queuedAtMs = null;
      _queueConfirmed = false;
      _safeNotify();
      return;
    }
    busy = true;
    errorMessage = null;
    _queueConfirmed = false;
    // RPC öncesi armed — geri/dispose/iptal atlamasın.
    _arms = armBeforeStartRpc(_arms);
    phase = HilalDuelPhase.matchmaking;
    // Sayaç hemen başlar; RPC 2–4sn sürse bile 0/15'te takılı kalmaz.
    queuedAtMs = DateTime.now().millisecondsSinceEpoch;
    _safeNotify();

    final startFuture = _runStartMatchmaking();
    _startFuture = startFuture;
    try {
      await startFuture;
    } finally {
      if (identical(_startFuture, startFuture)) {
        _startFuture = null;
      }
    }
  }

  Future<void> _runStartMatchmaking() async {
    try {
      var start = await _repository.startMatch(_displayName());
      if (_disposed) return;

      if (start.status == 'idle' && start.refunded) {
        // İade sonrası tek yeniden deneme — cancelPending ise ikinci charge yok.
        if (_arms.cancelPending) {
          await _applyStartWhileCancelPending(start);
          return;
        }
        start = await _repository.startMatch(_displayName());
        if (_disposed) return;
      }

      if (_arms.cancelPending) {
        // Cancel yolu startFuture'ı bekliyor; burada RPC çağırma (deadlock yok).
        await _applyStartWhileCancelPending(start);
        return;
      }

      if (start.matched && start.matchId != null) {
        await _enterMatch(start.matchId!);
        return;
      }
      if (start.waiting || start.status == 'waiting') {
        _beginConfirmedMatchmaking(start.queuedAtMs);
        return;
      }
      if (start.status == 'idle') {
        _arms = afterQueueConfirmedAbsent(_arms);
        phase = HilalDuelPhase.lobby;
        queuedAtMs = null;
        _queueConfirmed = false;
        await refreshProfile();
        return;
      }
      // Bilinmeyen status — kuyruk yok varsay; poll ile hayalet arama yok.
      _arms = afterQueueConfirmedAbsent(_arms);
      phase = HilalDuelPhase.lobby;
      queuedAtMs = null;
      _queueConfirmed = false;
      errorMessage = 'Eşleşme başlatılamadı. Tekrar dene.';
    } catch (error) {
      if (_disposed) return;
      try {
        final bundle = await _repository.loadProfile(_displayName());
        if (_disposed) return;
        profile = bundle.profile;
        final queue = bundle.queue;
        if (_arms.cancelPending) {
          await _applyAmbiguousStartWhileCancelPending(queue);
          return;
        }
        if (queue != null && queue.matched && queue.matchId != null) {
          await _enterMatch(queue.matchId!);
          return;
        }
        if (queue != null && queue.waiting) {
          errorMessage = null;
          _beginConfirmedMatchmaking(queue.queuedAtMs);
          return;
        }
        // Kuyruk yokken poll etme → "Eşleşme isteği bulunamadı" döngüsü olmasın.
        _arms = afterQueueConfirmedAbsent(_arms);
        phase = HilalDuelPhase.lobby;
        queuedAtMs = null;
        _queueConfirmed = false;
        errorMessage = _friendlyError(error);
      } catch (_) {
        if (_disposed) return;
        _arms = afterQueueConfirmedAbsent(_arms);
        phase = HilalDuelPhase.lobby;
        queuedAtMs = null;
        _queueConfirmed = false;
        errorMessage = _friendlyError(error);
      }
    } finally {
      if (!_disposed && _arms.startInFlight) {
        _arms = _arms.copyWith(startInFlight: false);
      }
      // Cancel bekliyorsa busy'yi cancel finally temizler — ikinci start kapalı.
      if (!_disposed && !_arms.cancelPending && _cancelFuture == null) {
        busy = false;
      }
      _safeNotify();
    }
  }

  void _mergeQueuedAtMs(int? candidate) {
    final local = queuedAtMs;
    if (candidate == null || candidate <= 0) {
      queuedAtMs ??= DateTime.now().millisecondsSinceEpoch;
      return;
    }
    if (local == null || candidate < local) {
      queuedAtMs = candidate;
    }
  }

  void _beginConfirmedMatchmaking(int? serverQueuedAtMs) {
    _arms = afterStartWaiting(_arms);
    _queueConfirmed = true;
    phase = HilalDuelPhase.matchmaking;
    // Yerel sayaç varsa geri alma — sunucu zamanı daha geçse 0'a sıçramasın.
    _mergeQueuedAtMs(serverQueuedAtMs);
    errorMessage = null;
    _startQueuePolling();
  }

  /// Cancel zaten uçuyor/bekliyor: sadece start sonucunu işle, cancel RPC yok.
  Future<void> _applyStartWhileCancelPending(HilalDuelMatchStart start) async {
    if (start.matched && start.matchId != null) {
      await _enterMatch(start.matchId!);
      _completeLeave(HilalDuelLeaveSettle.enteredMatch);
      return;
    }
    if (start.waiting || start.status == 'waiting') {
      _arms = afterCancelRequested(afterStartWaiting(_arms));
      _mergeQueuedAtMs(start.queuedAtMs);
      // Optimistic iptal lobideyse geri matchmaking'e sıçratma.
      if (phase != HilalDuelPhase.lobby) {
        phase = HilalDuelPhase.matchmaking;
      }
      return;
    }
    // idle: yine cancelPending tut — iptal yolu idle ile settle eder.
    _arms = afterCancelRequested(
      _arms.copyWith(startInFlight: false, queueMayExist: true),
    );
    if (phase != HilalDuelPhase.lobby) {
      phase = HilalDuelPhase.matchmaking;
    }
  }

  Future<void> _applyAmbiguousStartWhileCancelPending(
    HilalDuelMatchStart? queue,
  ) async {
    if (queue != null && queue.matched && queue.matchId != null) {
      await _enterMatch(queue.matchId!);
      _completeLeave(HilalDuelLeaveSettle.enteredMatch);
      return;
    }
    _arms = afterCancelRequested(afterStartWaiting(_arms));
    if (queue != null && queue.waiting) {
      _mergeQueuedAtMs(queue.queuedAtMs);
    }
    if (phase != HilalDuelPhase.lobby) {
      phase = HilalDuelPhase.matchmaking;
    }
  }

  /// Geri / swipe: kuyruk olasıysa iptali bekler; pop kararı döner.
  Future<HilalDuelLeaveSettle> requestLeave() async {
    if (_disposed) return HilalDuelLeaveSettle.poppedToLobby;

    final action = decideLeaveAction(_arms);
    if (action == HilalDuelLeaveAction.allowPop) {
      return HilalDuelLeaveSettle.poppedToLobby;
    }

    if (_leaveCompleter != null) {
      return _leaveCompleter!.future;
    }
    final leaveCompleter = Completer<HilalDuelLeaveSettle>();
    _leaveCompleter = leaveCompleter;
    final leaveFuture = leaveCompleter.future;
    _arms = afterCancelRequested(_arms);
    phase = HilalDuelPhase.matchmaking;
    _safeNotify();

    // Tüm cancel yolları gibi: önce mevcut start bitsin, sonra cancel RPC.
    await _executeCancel();
    return leaveFuture;
  }

  /// Arama ekranını RPC beklemeden kapat — kullanıcı anında lobiye düşer.
  void _optimisticLeaveMatchmakingUi() {
    if (_disposed) return;
    if (phase != HilalDuelPhase.matchmaking &&
        phase != HilalDuelPhase.cancelRetry) {
      return;
    }
    busy = true;
    phase = HilalDuelPhase.lobby;
    match = null;
    queuedAtMs = null;
    errorMessage = null;
    _safeNotify();
  }

  /// Lobi/iptal butonu veya retry.
  Future<String?> cancelMatchmaking({bool fromDispose = false}) async {
    if (_disposed && !fromDispose) return null;
    _arms = afterCancelRequested(_arms);
    // İlk mikro görevden önce UI: start/cancel RPC gecikmesi ekranda hissedilmesin.
    if (!fromDispose) {
      _stopTimers();
      _optimisticLeaveMatchmakingUi();
    }
    final settle = await _executeCancel(fromDispose: fromDispose);
    if (settle == HilalDuelLeaveSettle.enteredMatch) {
      return _activeMatchId ?? match?.id;
    }
    return null;
  }

  Future<HilalDuelLeaveSettle> retryCancel() async {
    errorMessage = null;
    _arms = afterCancelRequested(_arms);
    _stopTimers();
    _optimisticLeaveMatchmakingUi();
    return _executeCancel();
  }

  Future<HilalDuelLeaveSettle> _executeCancel({
    bool fromDispose = false,
  }) async {
    // Çift dokunuş: yine de lobiye çek, mevcut cancel Future'ına bağlan.
    if (!fromDispose) {
      _optimisticLeaveMatchmakingUi();
    }
    final inFlight = _cancelFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final run = _runCancel(fromDispose: fromDispose);
    _cancelFuture = run;
    try {
      return await run;
    } finally {
      if (identical(_cancelFuture, run)) {
        _cancelFuture = null;
      }
    }
  }

  Future<HilalDuelLeaveSettle> _runCancel({bool fromDispose = false}) async {
    _stopTimers();
    if (!fromDispose && !_disposed) {
      busy = true;
      // Anlık tepki: arama ekranını hemen kapat, RPC arkada bitsin.
      if (phase == HilalDuelPhase.matchmaking ||
          phase == HilalDuelPhase.cancelRetry) {
        phase = HilalDuelPhase.lobby;
        match = null;
        queuedAtMs = null;
        errorMessage = null;
      }
      _safeNotify();
    }

    // Mevcut startFuture'ı yakala — sonra gelen start ile değiştirilemez
    // (startMatchmaking cancelPending/_startFuture ile gated).
    // Mevcut start bitsin; cancel RPC kuyruk oluşmadan idle dönmesin.
    final pendingStart = _startFuture;
    if (pendingStart != null && !cancelMayIssueRpc(startFuturePending: true)) {
      try {
        await pendingStart;
      } catch (_) {}
    }

    // Start beklerken maça girildiyse kuyruk iadesi yok.
    if (phase == HilalDuelPhase.playing) {
      if (!_disposed) {
        _arms = afterEnteredMatch(_arms);
      }
      _completeLeave(HilalDuelLeaveSettle.enteredMatch);
      if (!fromDispose && !_disposed) {
        busy = false;
        _safeNotify();
      }
      return HilalDuelLeaveSettle.enteredMatch;
    }

    try {
      var outcome = await _repository.cancelMatchmaking();
      if (_disposed && !fromDispose) {
        return HilalDuelLeaveSettle.blockedRetry;
      }

      // Premature idle koruması: start hâlâ uçuyorsa (olmamalı) disarm yok.
      if (_startFuture != null &&
          decideCancelOutcome(
                status: outcome.status,
                matchId: outcome.matchId,
              ) ==
              HilalDuelCancelDecision.goLobby) {
        try {
          await _startFuture;
        } catch (_) {}
        if (!_disposed && phase == HilalDuelPhase.playing) {
          _arms = afterEnteredMatch(_arms);
          _completeLeave(HilalDuelLeaveSettle.enteredMatch);
          return HilalDuelLeaveSettle.enteredMatch;
        }
        outcome = await _repository.cancelMatchmaking();
      }

      final decision = decideCancelOutcome(
        status: outcome.status,
        matchId: outcome.matchId,
      );
      final settle = settleLeaveAfterCancel(
        decision: decision,
        cancelSucceeded: true,
      );

      if (decision == HilalDuelCancelDecision.enterMatch) {
        try {
          if (!_disposed) {
            await _enterMatch(outcome.matchId!);
          }
          _completeLeave(HilalDuelLeaveSettle.enteredMatch);
          return HilalDuelLeaveSettle.enteredMatch;
        } catch (error) {
          // loadMatch patlarsa leave Completer asılı kalmasın.
          if (!fromDispose && !_disposed) {
            phase = HilalDuelPhase.lobby;
            errorMessage = _friendlyError(error);
            _completeLeave(HilalDuelLeaveSettle.poppedToLobby);
            _safeNotify();
          } else {
            _completeLeave(HilalDuelLeaveSettle.blockedRetry);
          }
          return _disposed
              ? HilalDuelLeaveSettle.blockedRetry
              : HilalDuelLeaveSettle.poppedToLobby;
        }
      }

      // idle yalnızca start settle + cancel sonrası disarm.
      if (_startFuture != null) {
        _arms = afterCancelFailure(_arms);
        if (!fromDispose && !_disposed) {
          phase = HilalDuelPhase.cancelRetry;
          errorMessage = 'İptal henüz tamamlanamadı. Tekrar dene.';
          _completeLeave(HilalDuelLeaveSettle.blockedRetry);
          _safeNotify();
        }
        return HilalDuelLeaveSettle.blockedRetry;
      }

      _arms = afterCancelIdleSuccess(_arms);
      if (!fromDispose && !_disposed) {
        phase = HilalDuelPhase.lobby;
        match = null;
        queuedAtMs = null;
        _safeNotify();
        unawaited(refreshProfile());
      }
      _completeLeave(HilalDuelLeaveSettle.poppedToLobby);
      return settle;
    } catch (error) {
      if (!fromDispose && !_disposed) {
        _arms = afterCancelFailure(_arms);
        phase = HilalDuelPhase.cancelRetry;
        errorMessage = _friendlyError(error);
        _completeLeave(HilalDuelLeaveSettle.blockedRetry);
      } else if (!_disposed) {
        _arms = afterCancelFailure(_arms);
      }
      return HilalDuelLeaveSettle.blockedRetry;
    } finally {
      if (!fromDispose && !_disposed) {
        busy = false;
        _safeNotify();
      }
    }
  }

  void _completeLeave(HilalDuelLeaveSettle settle) {
    final completer = _leaveCompleter;
    _leaveCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(settle);
    }
  }

  Future<void> submitChoice(int choice) async {
    final current = match;
    if (current == null ||
        current.isCompleted ||
        current.selfAnswered ||
        selectedChoice != null ||
        revealingResolution ||
        busy ||
        _disposed ||
        choice < 0 ||
        choice > 3) {
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    HilalDuelSfx.instance.playTap();
    busy = true;
    selectedChoice = choice;
    lastSubmittedChoice = choice;
    lastSubmittedRound = current.currentRound;
    awaitingOpponent = true;
    errorMessage = null;
    _safeNotify();
    final submittedRound = current.currentRound;
    var attempt = 0;
    try {
      while (attempt < 2 && !_disposed) {
        attempt += 1;
        final seq = ++_matchRequestSeq;
        try {
          final next = challengeMode
              ? await _repository.submitChallengeAnswer(
                  challengeId: current.id,
                  round: submittedRound,
                  choice: choice,
                )
              : await _repository.submitAnswer(
                  matchId: current.id,
                  round: submittedRound,
                  choice: choice,
                );
          if (_disposed) break;
          if (next.isAwaitingChallengeOpponent) {
            _scheduleChallengeSentAfterReveal(next);
            break;
          }
          _applyMatch(next, seq);
          if (match!.isCompleted) {
            awaitingOpponent = false;
            // selectedChoice reveal bitene kadar kalsın (Sen rozeti).
            _scheduleFinalRevealThenComplete();
          } else if (shouldClearOptimisticChoice(
            submittedRound: submittedRound,
            match: match!,
          )) {
            awaitingOpponent = false;
            _syncRevealFromMatch();
            // Reveal başlamadıysa (nadir) seçim bir sonraki soruyu kilitlemesin.
            if (!revealingResolution) {
              selectedChoice = null;
              if (match!.currentRound != submittedRound) {
                _armMatchPoll(delay: Duration.zero);
              }
            }
          } else {
            // Optimistic seçim kalsın; poll eski lastResolution ile silemesin.
            selectedChoice = choice;
            awaitingOpponent = computeAwaitingOpponent(
              match: match!,
              selectedChoice: selectedChoice,
              revealingResolution: revealingResolution,
            );
            _syncRevealFromMatch();
            // Bot/rakip cevabını beklemeden hemen yokla — sonuç geç düşmesin.
            if (awaitingOpponent && !revealingResolution) {
              _armMatchPoll(delay: Duration.zero);
            }
          }
          break;
        } catch (error) {
          if (_disposed) break;
          final retryable = _isRoundNotStartedError(error) && attempt < 2;
          if (retryable) {
            final startAt = match?.roundStartedAtMs ?? nowMs;
            final waitMs =
                startAt - DateTime.now().millisecondsSinceEpoch;
            await Future<void>.delayed(
              Duration(milliseconds: waitMs.clamp(200, 1200)),
            );
            continue;
          }
          errorMessage = _friendlyError(error);
          // Başarısız gönderimde yeniden seçime izin ver; hayalet "Sen" olmasın.
          selectedChoice = null;
          lastSubmittedChoice = null;
          lastSubmittedRound = null;
          awaitingOpponent = false;
          break;
        }
      }
    } finally {
      busy = false;
      if (!_disposed) _safeNotify();
    }
  }

  bool _isRoundNotStartedError(Object error) {
    if (error is! FirebaseFunctionsException) return false;
    final message = (error.message ?? '').toLowerCase();
    return error.code.toLowerCase() == 'failed-precondition' &&
        (message.contains('başlamadı') || message.contains('not_started'));
  }

  Future<void> watchHeartAd() async {
    if (busy || profile?.premium == true || _disposed) return;
    busy = true;
    errorMessage = null;
    _safeNotify();
    try {
      if (await _hasPendingHeartProof()) {
        errorMessage = 'Önceki canın doğrulanıyor; lütfen kısa süre bekle.';
        unawaited(_recoverPendingHeartReward());
        return;
      }
      final proof = await _repository.beginReward(purpose: 'heart');
      if (proof.proofId.isEmpty || proof.customData.isEmpty) {
        throw StateError('Reklam kanıtı hazırlanamadı.');
      }
      final result = await _adMob.showRewardedDetailed(
        ArinAdUnit.rewardedUnlock,
        serverSideCustomData: proof.customData,
      );
      if (_disposed) return;
      if (result != RewardedAdResult.rewarded) {
        if (result != RewardedAdResult.notRewarded) {
          errorMessage = 'Reklam tamamlanamadı. Lütfen tekrar dene.';
        }
        return;
      }
      unawaited(ProductMetricsService.adWatch(ProductMetricFeatures.hilalDuel));
      await _storePendingHeartProof(proof);
      try {
        await _repository.claimReward(proof.proofId);
        await _clearPendingHeartProof(proof.proofId);
      } catch (_) {
        // AdMob SSV, SDK ödül callback'inden sonra ulaşabilir. Kanıtı diskte
        // tutup süresi dolana kadar arka planda teslim etmeyi sürdür.
        errorMessage = 'Canın doğrulanıyor; kısa süre içinde hesabına eklenecek.';
        unawaited(_recoverPendingHeartReward());
        return;
      }
      await refreshProfile();
      unawaited(ArinAnalytics.hilalDuelRewardHeart());
    } catch (error) {
      if (_disposed) return;
      errorMessage = _friendlyError(error);
    } finally {
      busy = false;
      _safeNotify();
    }
  }

  Future<void> _storePendingHeartProof(HilalDuelRewardProof proof) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingHeartProofKey, proof.proofId);
    await prefs.setInt(_pendingHeartProofExpiryKey, proof.expiresAtMs);
  }

  Future<bool> _hasPendingHeartProof() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_pendingHeartProofKey)?.trim().isNotEmpty ?? false);
  }

  Future<void> _clearPendingHeartProof(String proofId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_pendingHeartProofKey) != proofId) return;
    await prefs.remove(_pendingHeartProofKey);
    await prefs.remove(_pendingHeartProofExpiryKey);
  }

  Future<void> _recoverPendingHeartReward() async {
    if (_heartProofRecoveryInFlight) return;
    _heartProofRecoveryInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final proofId = prefs.getString(_pendingHeartProofKey)?.trim() ?? '';
      final expiresAtMs = prefs.getInt(_pendingHeartProofExpiryKey) ?? 0;
      if (proofId.isEmpty) {
        return;
      }
      if (expiresAtMs <= 0) {
        await _clearPendingHeartProof(proofId);
        return;
      }

      while (DateTime.now().millisecondsSinceEpoch < expiresAtMs) {
        try {
          await _repository.claimReward(proofId);
          await _clearPendingHeartProof(proofId);
          if (!_disposed) errorMessage = null;
          await refreshProfile();
          return;
        } on FirebaseFunctionsException catch (error) {
          if (error.code == 'deadline-exceeded' ||
              error.code == 'not-found') {
            await _clearPendingHeartProof(proofId);
            return;
          }
          if (error.code != 'failed-precondition') return;
        } catch (_) {
          // Ağ/servis geçici olarak yoksa kanıt sonraki açılışta da korunur.
          return;
        }
        final remainingMs =
            expiresAtMs - DateTime.now().millisecondsSinceEpoch;
        if (remainingMs <= 0) break;
        await Future<void>.delayed(
          Duration(milliseconds: remainingMs.clamp(1, 10_000).toInt()),
        );
      }
      // SSV son bekleme aralığında geldiyse ödülü kaçırmamak için bir kez daha
      // sunucuya sor. Yalnız sunucu kesin süre-doldu/yok yanıtı verirse temizle.
      try {
        await _repository.claimReward(proofId);
        await _clearPendingHeartProof(proofId);
        if (!_disposed) errorMessage = null;
        await refreshProfile();
      } on FirebaseFunctionsException catch (error) {
        if (error.code == 'deadline-exceeded' || error.code == 'not-found') {
          await _clearPendingHeartProof(proofId);
        }
      }
    } finally {
      _heartProofRecoveryInFlight = false;
    }
  }

  Future<void> watchDoubleAd() async {
    final current = match;
    if (busy ||
        current == null ||
        !current.isCompleted ||
        doubledThisMatch ||
        current.doubled ||
        profile?.premium == true ||
        _disposed) {
      return;
    }
    busy = true;
    errorMessage = null;
    _safeNotify();
    try {
      final proof = await _repository.beginReward(
        purpose: 'double',
        matchId: current.id,
      );
      if (proof.proofId.isEmpty || proof.customData.isEmpty) {
        throw StateError('Reklam kanıtı hazırlanamadı.');
      }
      final result = await _adMob.showRewardedDetailed(
        ArinAdUnit.rewardedUnlock,
        serverSideCustomData: proof.customData,
      );
      if (_disposed) return;
      if (result != RewardedAdResult.rewarded) {
        if (result != RewardedAdResult.notRewarded) {
          errorMessage = 'Reklam tamamlanamadı. Lütfen tekrar dene.';
        }
        return;
      }
      unawaited(ProductMetricsService.adWatch(ProductMetricFeatures.hilalDuel));
      await _repository.claimReward(proof.proofId);
      doubledThisMatch = true;
      match = HilalDuelMatch(
        id: current.id,
        status: current.status,
        version: current.version + 1,
        currentRound: current.currentRound,
        totalRounds: current.totalRounds,
        roundStartedAtMs: current.roundStartedAtMs,
        deadlineMs: current.deadlineMs,
        self: current.self,
        opponent: current.opponent,
        selfAnswered: current.selfAnswered,
        opponentAnswered: current.opponentAnswered,
        doubled: true,
        question: current.question,
        lastResolution: current.lastResolution,
        result: current.result,
        kind: current.kind,
        canAccept: current.canAccept,
        myTurn: current.myTurn,
        challengeDeadlineMs: current.challengeDeadlineMs,
        selfRoundMarks: current.selfRoundMarks,
        opponentRoundMarks: current.opponentRoundMarks,
      );
      await refreshProfile();
      unawaited(ArinAnalytics.hilalDuelRewardDouble());
    } on FirebaseFunctionsException catch (error) {
      if (_disposed) return;
      if (error.code == 'already-exists') {
        doubledThisMatch = true;
        await refreshProfile();
        return;
      }
      errorMessage = _friendlyError(error);
    } catch (error) {
      if (_disposed) return;
      errorMessage = _friendlyError(error);
    } finally {
      busy = false;
      _safeNotify();
    }
  }

  Future<void> returnToLobby() async {
    _stopTimers();
    if (_disposed) return;
    phase = HilalDuelPhase.lobby;
    match = null;
    challengeMode = false;
    selectedChoice = null;
    lastSubmittedChoice = null;
    lastSubmittedRound = null;
    awaitingOpponent = false;
    revealingResolution = false;
    doubledThisMatch = false;
    _finalRevealScheduled = false;
    _revealForRound = null;
    _revealTimer?.cancel();
    _revealTimer = null;
    _activeMatchId = null;
    _arms = afterQueueConfirmedAbsent(_arms);
    _safeNotify();
    await refreshProfile();
    await refreshChallenges();
  }

  Future<void> rematch() async {
    await returnToLobby();
    await startMatchmaking();
  }

  bool get isChallengeResult =>
      challengeMode || match?.isChallenge == true;

  String? get challengeOpponentId {
    final fromMatch = match?.opponent.id.trim() ?? '';
    if (fromMatch.isNotEmpty) return fromMatch;
    final selfId = match?.self.id;
    for (final player in match?.result?.players ?? const <HilalDuelPlayerResult>[]) {
      final id = player.id.trim();
      if (id.isNotEmpty && id != selfId) return id;
    }
    return null;
  }

  /// Bitmiş meydan okumadan aynı rakibe yeni davet.
  Future<void> challengeAgain({bool autoPlay = false}) async {
    if (busy || _disposed || !isChallengeResult) return;
    final opponentId = challengeOpponentId ?? '';
    if (opponentId.isEmpty) return;
    challengeMode = true;
    final p = profile;
    if (p != null && !p.premium && p.hearts <= 0) {
      errorMessage = needHeartErrorToken;
      _safeNotify();
      return;
    }
    busy = true;
    errorMessage = null;
    _safeNotify();
    try {
      final created = await _repository.createChallenge(
        name: _displayName(),
        opponentOwnerHash: opponentId,
        autoPlay: autoPlay,
      );
      if (_disposed) return;
      await refreshProfile();
      if (autoPlay) {
        await _returnToLobbyAfterChallengeSent(created);
        return;
      }
      await _enterChallenge(created.id, seed: created);
    } catch (error) {
      if (_disposed) return;
      errorMessage = _friendlyError(error);
      _safeNotify();
    } finally {
      busy = false;
      if (!_disposed) _safeNotify();
    }
  }

  /// Maçı yarıda bırak: canlı maçta terk cezası; meydan okumada sadece lobiye dön.
  Future<void> forfeitAndLeave() async {
    final id = _activeMatchId ?? match?.id;
    if (id == null || id.isEmpty) return;
    _stopTimers();
    if (!challengeMode) {
      try {
        await _repository.forfeitMatch(id);
      } catch (_) {
        // Best-effort; bağlantı kopuksa ceza bir sonraki oturumda kaçabilir.
      }
    }
    if (_disposed) return;
    revealingResolution = false;
    _finalRevealScheduled = false;
    _revealTimer?.cancel();
    _revealTimer = null;
    match = null;
    _activeMatchId = null;
    challengeMode = false;
    phase = HilalDuelPhase.lobby;
    await refreshProfile();
    await refreshChallenges();
    _safeNotify();
  }

  Future<HilalDuelWeeklyBoard> loadWeeklyLeaderboard() {
    return _repository.loadWeeklyLeaderboard();
  }

  /// Yönetici: haftalık listeden kaldır (sıra otomatik kayar).
  Future<void> adminRemoveWeeklyEntry(String ownerHash) {
    return _repository.adminRemoveWeeklyEntry(
      ownerHash: ownerHash,
      reason: 'inappropriate_name',
    );
  }

  /// Yönetici: kendi hilal puanını artırır (toplam + haftalık).
  Future<void> adminGrantSelfHilals(int amount) async {
    if (busy || _disposed || amount < 1) return;
    busy = true;
    errorMessage = null;
    _safeNotify();
    try {
      final updated = await _repository.adminGrantSelfHilals(
        name: _displayName(),
        amount: amount,
      );
      if (_disposed) return;
      profile = updated;
      _safeNotify();
    } catch (error) {
      if (_disposed) return;
      errorMessage = _friendlyError(error);
      _safeNotify();
    } finally {
      busy = false;
      if (!_disposed) _safeNotify();
    }
  }

  /// Yönetici: kendi seviyesini ayarlar (toplam hilal = seviye tabanı).
  Future<void> adminSetSelfLevel(int level) async {
    if (busy || _disposed || level < 1 || level > kHilalDuelMaxLevel) return;
    busy = true;
    errorMessage = null;
    _safeNotify();
    try {
      final updated = await _repository.adminSetSelfLevel(
        name: _displayName(),
        level: level,
      );
      if (_disposed) return;
      profile = updated;
      _safeNotify();
    } catch (error) {
      if (_disposed) return;
      errorMessage = _friendlyError(error);
      _safeNotify();
    } finally {
      busy = false;
      if (!_disposed) _safeNotify();
    }
  }

  void _startQueuePolling() {
    _stopTimers();
    _queuePollInFlight = false;
    _botAssignRequested = false;
    _queueTimer = Timer.periodic(_pollInterval, (_) => _pollQueue());
    // İlk tick'i beklemeden bir kez sor — 15sn dolmuş kuyruk hemen botsuz kalmasın.
    unawaited(_pollQueue());
  }

  Future<void> _pollQueue() async {
    if (_disposed ||
        (phase != HilalDuelPhase.matchmaking &&
            phase != HilalDuelPhase.cancelRetry) ||
        _arms.cancelPending ||
        _queuePollInFlight ||
        !_queueConfirmed) {
      return;
    }
    // start RPC sürerken poll yok; start bittikten sonra busy false olur.
    if (busy && _arms.startInFlight) return;

    final elapsedMs = queuedAtMs == null
        ? 0
        : DateTime.now().millisecondsSinceEpoch - queuedAtMs!;
    // İstemci 15sn dolduysa bot atamasını agresif dene (sunucu da kontrol eder).
    if (elapsedMs >= _queueWait.inMilliseconds) {
      _botAssignRequested = true;
    }

    _queuePollInFlight = true;
    try {
      final polled = await _repository.pollMatch();
      if (_disposed || _arms.cancelPending) return;
      if (polled.queuedAtMs != null && polled.queuedAtMs! > 0) {
        _mergeQueuedAtMs(polled.queuedAtMs);
      }
      if (polled.matched &&
          polled.matchId != null &&
          polled.matchId!.isNotEmpty) {
        errorMessage = null;
        await _enterMatch(polled.matchId!);
        return;
      }
      if (polled.status == 'idle') {
        // Kuyruk kayboldu / iade edildi — hayalet aramada kalma.
        _stopTimers();
        _arms = afterQueueConfirmedAbsent(_arms);
        _queueConfirmed = false;
        phase = HilalDuelPhase.lobby;
        queuedAtMs = null;
        errorMessage = _botAssignRequested
            ? 'Eşleşme bulunamadı. Tekrar dene.'
            : null;
        await refreshProfile();
        _safeNotify();
        return;
      }
      // Hâlâ waiting.
      errorMessage = null;
      _safeNotify();
    } catch (error) {
      if (_disposed) return;
      final friendly = _friendlyError(error);
      final lower = friendly.toLowerCase();
      final missingQueue = lower.contains('bulunamadı') ||
          lower.contains('not-found') ||
          (error is FirebaseFunctionsException &&
              error.code.toLowerCase() == 'not-found');
      if (missingQueue) {
        _stopTimers();
        _arms = afterQueueConfirmedAbsent(_arms);
        _queueConfirmed = false;
        phase = HilalDuelPhase.lobby;
        queuedAtMs = null;
        errorMessage = 'Eşleşme bulunamadı. Tekrar dene.';
        await refreshProfile();
        _safeNotify();
        return;
      }
      errorMessage = friendly;
      _safeNotify();
      // 15sn sonrası geçici hata: kısa aralıkla tekrar dene.
      if (_botAssignRequested &&
          phase == HilalDuelPhase.matchmaking &&
          !_arms.cancelPending) {
        _queuePollInFlight = false;
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (!_disposed &&
            phase == HilalDuelPhase.matchmaking &&
            _queueConfirmed) {
          unawaited(_pollQueue());
        }
      }
    } finally {
      _queuePollInFlight = false;
    }
  }

  Future<void> _enterMatch(String matchId) async {
    challengeMode = false;
    await _enterPlaySession(matchId);
  }

  Future<void> _enterChallenge(String challengeId, {HilalDuelMatch? seed}) async {
    challengeMode = true;
    await _enterPlaySession(challengeId, seed: seed);
  }

  /// Son soru doğru/yanlış görünsün; hold bitince lobi + "gönderildi" diyaloğu.
  void _scheduleChallengeSentAfterReveal(HilalDuelMatch finished) {
    if (_disposed) return;
    match = finished;
    challengeMode = true;
    final res = finished.lastResolution;
    if (res == null ||
        !shouldRevealBeforeChallengeSent(
          awaitingOpponent: finished.isAwaitingChallengeOpponent,
          hasLastResolution: true,
        )) {
      unawaited(_returnToLobbyAfterChallengeSent(finished));
      return;
    }
    final alreadyThisRound = _revealForRound == res.round && revealingResolution;
    if (!alreadyThisRound) {
      _revealForRound = res.round;
      revealingResolution = true;
      awaitingOpponent = false;
      _recordResolutionMarks(res);
      _restoreSelectedChoiceForReveal(res);
      _playRevealOutcomeSfx(res);
    }
    // awaiting_opponent'ta roundStartedAtMs=0; waitForRoundStart 1ms yapar.
    _scheduleRevealHold(
      waitForRoundStart: false,
      onDone: () {
        if (_disposed) return;
        revealingResolution = false;
        selectedChoice = null;
        unawaited(_returnToLobbyAfterChallengeSent(finished));
      },
    );
    _safeNotify();
  }

  Future<void> _returnToLobbyAfterChallengeSent(HilalDuelMatch finished) async {
    _stopTimers();
    final opponentName = finished.opponent.name.trim();
    challengeSentNoticeOpponentName =
        opponentName.isEmpty ? 'Rakip' : opponentName;
    match = null;
    _activeMatchId = null;
    challengeMode = false;
    selectedChoice = null;
    lastSubmittedChoice = null;
    lastSubmittedRound = null;
    awaitingOpponent = false;
    revealingResolution = false;
    busy = false;
    phase = HilalDuelPhase.lobby;
    errorMessage = null;
    await refreshChallenges();
    await refreshProfile();
    if (!_disposed) _safeNotify();
  }

  String? consumeChallengeSentNotice() {
    final name = challengeSentNoticeOpponentName;
    challengeSentNoticeOpponentName = null;
    return name;
  }

  Future<void> _enterPlaySession(String sessionId, {HilalDuelMatch? seed}) async {
    if (_disposed) return;
    _stopTimers();
    _activeMatchId = sessionId;
    _arms = afterEnteredMatch(_arms);
    phase = HilalDuelPhase.playing;
    selectedChoice = null;
    lastSubmittedChoice = null;
    lastSubmittedRound = null;
    awaitingOpponent = false;
    revealingResolution = false;
    _finalRevealScheduled = false;
    _revealForRound = null;
    _revealTimer?.cancel();
    _revealTimer = null;
    doubledThisMatch = false;
    _resetRoundMarks();
    unawaited(ArinAnalytics.hilalDuelMatchStart());
    final seq = ++_matchRequestSeq;
    try {
      final loaded = seed ??
          (challengeMode
              ? await _repository.loadChallenge(sessionId)
              : await _repository.loadMatch(sessionId));
      if (_disposed) return;
      if (loaded.isAwaitingChallengeOpponent) {
        await _returnToLobbyAfterChallengeSent(loaded);
        return;
      }
      _applyMatch(loaded, seq);
      doubledThisMatch = loaded.doubled;
      if (loaded.isCompleted) {
        _scheduleFinalRevealThenComplete();
      } else {
        _syncRevealFromMatch();
      }
      _safeNotify();
      _armMatchPoll(delay: Duration.zero);
    } catch (error) {
      if (_disposed) rethrow;
      // playing + null match spinner'da kalma.
      match = null;
      _activeMatchId = null;
      challengeMode = false;
      _stopTimers();
      _arms = const HilalDuelQueueArms();
      _queueConfirmed = false;
      phase = HilalDuelPhase.lobby;
      errorMessage = _friendlyError(error);
      _safeNotify();
      rethrow;
    }
  }

  bool get _isAwaitingOpponentPoll {
    return needsFastMatchPoll(
      match: match,
      selectedChoice: selectedChoice,
      revealingResolution: revealingResolution,
      awaitingOpponent: awaitingOpponent,
    );
  }

  /// Beklerken 350ms, normalde 900ms; cevap sonrası delay:0 ile anında yoklar.
  void _armMatchPoll({Duration? delay}) {
    _pollTimer?.cancel();
    if (_disposed ||
        phase != HilalDuelPhase.playing ||
        _activeMatchId == null) {
      return;
    }
    final interval =
        _isAwaitingOpponentPoll ? _awaitingPollInterval : _pollInterval;
    _pollTimer = Timer(delay ?? interval, () async {
      await _pollMatch();
      if (!_disposed && phase == HilalDuelPhase.playing) {
        _armMatchPoll();
      }
    });
  }

  /// İptal tekrarları başarısızsa: kuyruk iadesi best-effort, UI kilidini aç.
  Future<void> abandonCancelAndLeave() async {
    _stopTimers();
    unawaited(
      _repository.cancelMatchmaking().catchError(
        (_) => const HilalDuelMatchStart(status: 'idle'),
      ),
    );
    _arms = const HilalDuelQueueArms();
    _queueConfirmed = false;
    _botAssignRequested = false;
    match = null;
    _activeMatchId = null;
    queuedAtMs = null;
    selectedChoice = null;
    lastSubmittedChoice = null;
    lastSubmittedRound = null;
    awaitingOpponent = false;
    revealingResolution = false;
    busy = false;
    errorMessage = null;
    phase = HilalDuelPhase.lobby;
    _completeLeave(HilalDuelLeaveSettle.poppedToLobby);
    try {
      await refreshProfile();
    } catch (_) {}
    if (!_disposed) _safeNotify();
  }

  Future<void> _pollMatch() async {
    final id = _activeMatchId;
    // Submit uçuşundayken poll etme: getMatch grace sonunda kendi cevabını
    // timeout'a çevirip turu ilerletebiliyordu; submit cevabı zaten resolve eder.
    if (_disposed ||
        id == null ||
        phase != HilalDuelPhase.playing ||
        busy ||
        _matchPollInFlight) {
      return;
    }
    _matchPollInFlight = true;
    final seq = ++_matchRequestSeq;
    try {
      final previousRound = match?.currentRound;
      final next = challengeMode
          ? await _repository.loadChallenge(id)
          : await _repository.loadMatch(id);
      // Submit busy / reveal sırasında açılmış poll: skor/rozet state'ini ezmesin.
      if (_disposed ||
          phase != HilalDuelPhase.playing ||
          busy ||
          revealingResolution) {
        return;
      }
      if (next.isAwaitingChallengeOpponent) {
        if (!revealingResolution) {
          _scheduleChallengeSentAfterReveal(next);
        }
        return;
      }
      _applyMatch(next, seq);
      if (previousRound != null && match!.currentRound != previousRound) {
        selectedChoice = null;
        awaitingOpponent = false;
      } else if (!match!.isCompleted && !revealingResolution) {
        awaitingOpponent = computeAwaitingOpponent(
          match: match!,
          selectedChoice: selectedChoice,
          revealingResolution: revealingResolution,
        );
      }
      if (match!.doubled) doubledThisMatch = true;
      if (match!.isCompleted) {
        _scheduleFinalRevealThenComplete();
      } else {
        _syncRevealFromMatch();
      }
      // Reveal sync seçimi yanlışlıkla sildiyse (eski lastResolution), geri kur.
      if (!match!.isCompleted &&
          !revealingResolution &&
          selectedChoice == null &&
          match!.selfAnswered &&
          !match!.opponentAnswered) {
        // Seçim indeksi sunucuda yok; beklemeyi en azından koru.
        awaitingOpponent = true;
      }
      // İkiniz cevapladı / çözüm bekleniyor ama reveal açılmadıysa sık yokla.
      // (lastResolution önceki turdan dolu olabileceği için null kontrolü yetmez.)
      if (!match!.isCompleted &&
          !revealingResolution &&
          (match!.selfAnswered || selectedChoice != null) &&
          !shouldStartResolutionReveal(
            match: match!,
            alreadyRevealedRound: _revealForRound,
          )) {
        _armMatchPoll(delay: _awaitingPollInterval);
      }
      _safeNotify();
    } catch (_) {
    } finally {
      _matchPollInFlight = false;
    }
  }

  void _syncRevealFromMatch() {
    final m = match;
    if (m == null || m.isCompleted) return;
    // Önceki turun lastResolution'ı her poll'da selectedChoice'ı silmesin.
    if (!shouldStartResolutionReveal(
      match: m,
      alreadyRevealedRound: _revealForRound,
    )) {
      return;
    }
    awaitingOpponent = false;
    _startInterstitialReveal();
  }

  void _resetRoundMarks({int total = 7}) {
    selfRoundMarks = List<HilalDuelRoundMark>.filled(
      total,
      HilalDuelRoundMark.pending,
    );
    opponentRoundMarks = List<HilalDuelRoundMark>.filled(
      total,
      HilalDuelRoundMark.pending,
    );
  }

  List<String> _roundMarkTokensFor(
    HilalDuelMatch incoming, {
    required bool opponent,
  }) {
    final direct = opponent
        ? incoming.opponentRoundMarks
        : incoming.selfRoundMarks;
    if (direct.isNotEmpty) return direct;
    final playerId = opponent ? incoming.opponent.id : incoming.self.id;
    if (playerId.isEmpty) return const [];
    return incoming.result?.roundMarks[playerId] ?? const [];
  }

  void _applyServerRoundMarks(HilalDuelMatch? incoming) {
    if (incoming == null) return;
    final total = incoming.totalRounds > 0 ? incoming.totalRounds : 7;
    final selfTokens = _roundMarkTokensFor(incoming, opponent: false);
    if (selfTokens.isNotEmpty) {
      final nextSelf = parseRoundMarks(selfTokens, total: total);
      // Oyun içi poll'daki tamamen pending özet, lastResolution ile
      // yazılmış turları geri silmesin. Sonuçta her zaman uygula.
      if (incoming.isCompleted ||
          nextSelf.any((mark) => mark != HilalDuelRoundMark.pending)) {
        selfRoundMarks = nextSelf;
      }
    }
    final oppTokens = _roundMarkTokensFor(incoming, opponent: true);
    if (oppTokens.isNotEmpty) {
      final nextOpp = parseRoundMarks(oppTokens, total: total);
      if (incoming.isCompleted) {
        opponentRoundMarks = nextOpp;
      } else if (nextOpp.any((mark) => mark != HilalDuelRoundMark.pending)) {
        // Oynarken gelecek soruları spoilerlama: yalnız senin
        // çözdüğün turlarda rakip işareti açılsın.
        opponentRoundMarks = _lockstepOpponentMarks(
          self: selfRoundMarks,
          serverOpponent: nextOpp,
          total: total,
        );
      }
    }
  }

  List<HilalDuelRoundMark> _lockstepOpponentMarks({
    required List<HilalDuelRoundMark> self,
    required List<HilalDuelRoundMark> serverOpponent,
    required int total,
  }) {
    final current = opponentRoundMarks.length == total
        ? opponentRoundMarks
        : List<HilalDuelRoundMark>.filled(total, HilalDuelRoundMark.pending);
    return List<HilalDuelRoundMark>.generate(total, (index) {
      final selfMark = index < self.length
          ? self[index]
          : HilalDuelRoundMark.pending;
      final serverMark = index < serverOpponent.length
          ? serverOpponent[index]
          : HilalDuelRoundMark.pending;
      if (selfMark == HilalDuelRoundMark.pending) return current[index];
      if (serverMark != HilalDuelRoundMark.pending) return serverMark;
      return current[index];
    });
  }

  /// Inbox / kabul sonrası sonuç: eski maç işaretleri kalmasın.
  void _hydrateResultRoundMarks(HilalDuelMatch incoming) {
    final total = incoming.totalRounds > 0 ? incoming.totalRounds : 7;
    _resetRoundMarks(total: total);
    _applyServerRoundMarks(incoming);
  }

  void _recordResolutionMarks(HilalDuelResolution res) {
    final m = match;
    if (m == null) return;
    final total = m.totalRounds > 0 ? m.totalRounds : 7;
    if (selfRoundMarks.length != total || opponentRoundMarks.length != total) {
      _resetRoundMarks(total: total);
    }
    if (res.round < 0 || res.round >= total) return;
    final correct = res.question.correctIndex;
    final nextSelf = List<HilalDuelRoundMark>.from(selfRoundMarks);
    final nextOpp = List<HilalDuelRoundMark>.from(opponentRoundMarks);
    nextSelf[res.round] = markFromServerChoice(
      choice: _rawRevealChoice(
        resolution: res,
        playerId: m.self.id,
        preferPerspective: 'self',
      ),
      correctIndex: correct,
    );
    // Challenge solo: rakip choices'ta yok → pending kalsın (missed yazma).
    final oppRaw = _rawRevealChoice(
      resolution: res,
      playerId: m.opponent.id,
      preferPerspective: 'opponent',
    );
    if (oppRaw != null || !challengeMode) {
      nextOpp[res.round] = markFromServerChoice(
        choice: oppRaw,
        correctIndex: correct,
      );
    } else if (res.round < m.opponentRoundMarks.length) {
      final fromSheet = parseRoundMarkToken(m.opponentRoundMarks[res.round]);
      if (fromSheet != HilalDuelRoundMark.pending) {
        nextOpp[res.round] = fromSheet;
      }
    }
    selfRoundMarks = nextSelf;
    opponentRoundMarks = nextOpp;
  }

  void _restoreSelectedChoiceForReveal(HilalDuelResolution res) {
    // Yalnızca sunucunun kabul ettiği seçim "Sen" rozeti taşır.
    final restored = choiceForRevealRound(res.round);
    selectedChoice = restored;
  }

  void _startInterstitialReveal() {
    final res = match?.lastResolution;
    if (_disposed || res == null) return;
    // Aynı tur sonucu için timer'ı yeniden başlatma.
    if (_revealForRound == res.round) return;
    _revealForRound = res.round;
    revealingResolution = true;
    awaitingOpponent = false;
    _recordResolutionMarks(res);
    _restoreSelectedChoiceForReveal(res);
    _playRevealOutcomeSfx(res);
    _scheduleRevealHold(
      waitForRoundStart: true,
      onDone: () {
        if (_disposed) return;
        revealingResolution = false;
        selectedChoice = null;
        _safeNotify();
      },
    );
    _safeNotify();
  }

  /// Reveal sonrası yeni soru, sunucu [roundStartedAtMs] ile aynı anda açılsın;
  /// böylece 20 sn sayacı soru görünür görünmez başlar (ortadan ~17'den değil).
  void _scheduleRevealHold({
    required VoidCallback onDone,
    bool waitForRoundStart = false,
  }) {
    _revealTimer?.cancel();
    final waitMs = computeRevealHoldMs(
      nowMs: DateTime.now().millisecondsSinceEpoch,
      roundStartedAtMs: match?.roundStartedAtMs ?? 0,
      waitForRoundStart: waitForRoundStart,
      matchCompleted: match?.isCompleted == true,
      defaultHoldMs: _revealHold.inMilliseconds,
    );
    _revealTimer = Timer(Duration(milliseconds: waitMs), () {
      if (_disposed) return;
      onDone();
    });
  }

  /// Ham sunucu seçimi: 0..3 veya timeout (-1) veya yok (null).
  int? _rawRevealChoice({
    required HilalDuelResolution resolution,
    required String? playerId,
    required String preferPerspective,
  }) {
    if (preferPerspective == 'self' && resolution.selfChoice != null) {
      return resolution.selfChoice;
    }
    if (preferPerspective == 'opponent' && resolution.opponentChoice != null) {
      return resolution.opponentChoice;
    }
    if (playerId == null) return null;
    final key = playerId.toString();
    if (resolution.choices.containsKey(key)) return resolution.choices[key];
    for (final entry in resolution.choices.entries) {
      if (entry.key.toString() == key) return entry.value;
    }
    return null;
  }

  /// Reveal UI: skora yazılan sunucu seçimi. Timeout (`-1`) → `null`.
  /// Yerel optimistic seçime düşülmez; aksi halde doğru hissi sonuçla çelişir.
  int? choiceForRevealRound(int round) {
    final res = match?.lastResolution;
    if (res != null && res.round == round) {
      final fromSelf = serverChoiceForReveal(
        resolution: res,
        playerId: match?.self.id,
        preferPerspective: 'self',
      );
      if (fromSelf != null) return fromSelf;
      // Perspective/map açıkça timeout (-1) söylediyse optimistic'e düşme.
      final raw = _rawRevealChoice(
        resolution: res,
        playerId: match?.self.id,
        preferPerspective: 'self',
      );
      if (raw != null && raw < 0) return null;
      // Eski CF / map boş: Sen rozeti için yerel submit yedeği.
      if (lastSubmittedRound == round) return lastSubmittedChoice;
      if (selectedChoice != null) return selectedChoice;
      return null;
    }
    if (lastSubmittedRound == round) return lastSubmittedChoice;
    if (selectedChoice != null) return selectedChoice;
    return null;
  }

  /// Reveal sırasında rakibin sunucu seçimi (rozette gösterilir).
  int? opponentChoiceForRevealRound(int round) {
    final res = match?.lastResolution;
    if (res == null || res.round != round) return null;
    return serverChoiceForReveal(
      resolution: res,
      playerId: match?.opponent.id,
      preferPerspective: 'opponent',
    );
  }

  void _scheduleFinalRevealThenComplete() {
    if (_disposed || _finalRevealScheduled) return;
    _finalRevealScheduled = true;
    awaitingOpponent = false;
    final completed = match;
    if (completed == null || !completed.isCompleted) return;
    if (completed.lastResolution == null) {
      revealingResolution = false;
      unawaited(_onMatchCompleted(completed));
      return;
    }
    final res = completed.lastResolution!;
    final resRound = res.round;
    // Ara tur reveal ile aynı yol: 7. soruda da "Sen" kaybolmasın.
    if (_revealForRound != resRound) {
      _revealForRound = resRound;
      revealingResolution = true;
      _recordResolutionMarks(res);
      _restoreSelectedChoiceForReveal(res);
      _playRevealOutcomeSfx(res);
      _safeNotify();
      _scheduleRevealHold(
        onDone: () {
          if (_disposed) return;
          revealingResolution = false;
          selectedChoice = null;
          final latest = match;
          if (latest == null || !latest.isCompleted) return;
          unawaited(_onMatchCompleted(latest));
        },
      );
      return;
    }
    // Reveal zaten bu tur için gösteriliyorsa süre bitince sonuca geç.
    _scheduleRevealHold(
      onDone: () {
        if (_disposed) return;
        revealingResolution = false;
        selectedChoice = null;
        final latest = match;
        if (latest == null || !latest.isCompleted) return;
        unawaited(_onMatchCompleted(latest));
      },
    );
  }

  void _playRevealOutcomeSfx(HilalDuelResolution res) {
    final choice = serverChoiceForReveal(
      resolution: res,
      playerId: match?.self.id,
      preferPerspective: 'self',
    );
    final correct = res.question.correctIndex;
    if (choice != null && correct != null && choice == correct) {
      HilalDuelSfx.instance.playCorrect();
    } else {
      HilalDuelSfx.instance.playWrong();
    }
  }

  void _applyMatch(HilalDuelMatch incoming, int seq) {
    // seq/busy ile düşürme: submit sırasında gelen poll cevabı, submit
    // sonucundaki lastResolution'ı yutabiliyordu. Version taze olanı korur.
    match = selectFresherMatch(match, incoming);
    _applyServerRoundMarks(match);
  }

  bool get _opponentMarksUnresolved {
    if (opponentRoundMarks.isEmpty) return true;
    return opponentRoundMarks.every((mark) => mark == HilalDuelRoundMark.pending);
  }

  Future<void> _refreshChallengeRoundMarks() async {
    if (!challengeMode && match?.isChallenge != true) return;
    final id = (_activeMatchId ?? match?.id)?.trim() ?? '';
    if (id.isEmpty) return;
    try {
      final loaded = await _repository.loadChallenge(id);
      if (_disposed) return;
      match = selectFresherMatch(match, loaded) ?? loaded;
      _applyServerRoundMarks(match);
      _safeNotify();
    } catch (_) {}
  }

  Future<void> _onMatchCompleted(HilalDuelMatch completed) async {
    _stopTimers();
    if (_disposed) return;
    match = completed;
    _applyServerRoundMarks(completed);
    phase = HilalDuelPhase.result;
    if (completed.doubled) doubledThisMatch = true;
    final winnerId = completed.result?.winnerId;
    if (winnerId != null) {
      if (winnerId == completed.self.id) {
        HilalDuelSfx.instance.playWin();
      } else {
        HilalDuelSfx.instance.playLose();
      }
    }
    final selfCorrect =
        completed.result?.players
            .where((p) => p.id == completed.self.id)
            .map((p) => p.correct)
            .firstOrNull ??
        0;
    unawaited(ArinAnalytics.hilalDuelMatchComplete(correct: selfCorrect));
    await refreshProfile();
    if (!_disposed && _opponentMarksUnresolved) {
      await _refreshChallengeRoundMarks();
    }
  }

  double matchmakingProgress() {
    final started = queuedAtMs;
    if (started == null) return 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - started;
    return (elapsed / _queueWait.inMilliseconds).clamp(0, 1);
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _queueTimer?.cancel();
    _queueTimer = null;
    _revealTimer?.cancel();
    _revealTimer = null;
    _matchPollInFlight = false;
  }

  String _friendlyError(Object error) {
    if (error is FirebaseFunctionsException) {
      final code = error.code.toLowerCase();
      final message = (error.message ?? '').trim();
      final lowerMessage = message.toLowerCase();
      // App Check / auth gateway bazen İngilizce "Unauthenticated" döner.
      // Emülatörde release APK veya kayıtsız debug token aynı kodu üretir.
      if (code == 'unauthenticated' ||
          lowerMessage.contains('unauthenticated')) {
        if (kDebugMode) {
          return 'App Check doğrulanamadı. Debug token Console\'a ekli mi? '
              'Release APK emülatörde çalışmaz — flutter run kullan.';
        }
        return 'Güvenli oturum gerekli. Tekrar dene.';
      }
      switch (code) {
        case 'resource-exhausted':
          return message.contains('can') ||
                  message.contains('Oynamak') ||
                  lowerMessage.contains('heart')
              ? needHeartErrorToken
              : 'Çok hızlı işlem yapıldı. Kısa süre sonra tekrar dene.';
        case 'unavailable':
          return 'Bağlantı kurulamadı. Tekrar dene.';
        case 'permission-denied':
          return message.isNotEmpty
              ? message
              : 'Bu işlem için yetki doğrulanamadı. Tekrar dene.';
        default:
          return message.isNotEmpty
              ? message
              : 'Bir hata oluştu. Tekrar dene.';
      }
    }
    return 'Bir hata oluştu. Tekrar dene.';
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimers();
    final leave = _leaveCompleter;
    _leaveCompleter = null;
    if (leave != null && !leave.isCompleted) {
      leave.complete(HilalDuelLeaveSettle.blockedRetry);
    }
    // Maç ortasında kapanırsa terk cezasını best-effort uygula.
    // Meydan okuma quiz_challenges üzerinde; forfeitQuizMatch çağırma.
    final playingId = _activeMatchId;
    if (!challengeMode &&
        phase == HilalDuelPhase.playing &&
        playingId != null &&
        playingId.isNotEmpty) {
      unawaited(_repository.forfeitMatch(playingId));
    }
    // phase==matchmaking şartı yok: startInFlight / queueMayExist / cancelPending.
    // _runCancel mevcut _startFuture'ı bekler; erken idle ile orphan olmaz.
    if (_arms.shouldBestEffortCancelOnDispose && !_disposeCancelScheduled) {
      _disposeCancelScheduled = true;
      _arms = afterCancelRequested(_arms);
      unawaited(_executeCancel(fromDispose: true));
    }
    super.dispose();
  }
}
