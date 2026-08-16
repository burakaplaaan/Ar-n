import 'package:arin/presentation/qibla/hilal_duel/hilal_duel_repository.dart';
import 'package:arin/presentation/qibla/hilal_duel/hilal_duel_sync.dart';
import 'package:flutter_test/flutter_test.dart';

HilalDuelMatch _match({
  required String id,
  required int version,
  bool selfAnswered = false,
  bool opponentAnswered = false,
  int currentRound = 0,
  HilalDuelResolution? lastResolution,
  String status = 'playing',
}) {
  return HilalDuelMatch(
    id: id,
    status: status,
    version: version,
    currentRound: currentRound,
    totalRounds: 7,
    roundStartedAtMs: 1,
    deadlineMs: 2,
    selfAnswered: selfAnswered,
    opponentAnswered: opponentAnswered,
    lastResolution: lastResolution,
    self: const HilalDuelPlayer(
      id: 'a',
      name: 'A',
      hilals: 0,
      level: 1,
      isBot: false,
    ),
    opponent: const HilalDuelPlayer(
      id: 'b',
      name: 'B',
      hilals: 0,
      level: 1,
      isBot: true,
    ),
  );
}

HilalDuelResolution _resolution(int round) {
  return HilalDuelResolution(
    round: round,
    question: const HilalDuelQuestion(
      id: 'q',
      category: 'c',
      text: 'Q?',
      options: ['a', 'b', 'c', 'd'],
    ),
    choices: const {'a': 0, 'b': 1},
    elapsedMs: const {'a': 1000, 'b': 1200},
  );
}

void main() {
  group('selectFresherMatch', () {
    test('eski version yeni submit sonucunu ezmez', () {
      final current = _match(id: 'm1', version: 5, selfAnswered: true);
      final stale = _match(id: 'm1', version: 4, selfAnswered: false);
      final selected = selectFresherMatch(current, stale);
      expect(selected, same(current));
      expect(selected!.selfAnswered, isTrue);
      expect(selected.version, 5);
    });

    test('daha yeni version kabul edilir', () {
      final current = _match(id: 'm1', version: 2);
      final newer = _match(id: 'm1', version: 3, selfAnswered: true);
      final selected = selectFresherMatch(current, newer);
      expect(selected!.version, 3);
      expect(selected.selfAnswered, isTrue);
    });

    test('farklı maç id tamamen değiştirir', () {
      final current = _match(id: 'm1', version: 9);
      final other = _match(id: 'm2', version: 1);
      expect(selectFresherMatch(current, other)!.id, 'm2');
    });

    test('eşit versionda selfAnswered poll tarafından ezilmez', () {
      final current = _match(id: 'm1', version: 7, selfAnswered: true);
      final staleTwin = _match(id: 'm1', version: 7, selfAnswered: false);
      final selected = selectFresherMatch(current, staleTwin);
      expect(selected, same(current));
      expect(selected!.selfAnswered, isTrue);
    });
  });

  group('answer waiting / reveal guards', () {
    test('önceki lastResolution seçimi temizlemez', () {
      final match = _match(
        id: 'm1',
        version: 4,
        currentRound: 4,
        selfAnswered: true,
        lastResolution: _resolution(3),
      );
      expect(
        shouldClearOptimisticChoice(submittedRound: 4, match: match),
        isFalse,
      );
      expect(
        shouldStartResolutionReveal(match: match, alreadyRevealedRound: 3),
        isFalse,
      );
    });

    test('yeni çözüm henüz gösterilmediyse reveal başlar', () {
      final match = _match(
        id: 'm1',
        version: 5,
        currentRound: 4,
        lastResolution: _resolution(3),
      );
      expect(
        shouldStartResolutionReveal(match: match, alreadyRevealedRound: null),
        isTrue,
      );
    });

    test('bu tur çözülünce optimistic seçim temizlenir', () {
      final match = _match(
        id: 'm1',
        version: 6,
        currentRound: 4,
        lastResolution: _resolution(4),
      );
      expect(
        shouldClearOptimisticChoice(submittedRound: 4, match: match),
        isTrue,
      );
    });

    test('awaitingOpponent seçim veya selfAnswered ile true kalır', () {
      final match = _match(id: 'm1', version: 1, selfAnswered: true);
      expect(
        computeAwaitingOpponent(
          match: match,
          selectedChoice: null,
          revealingResolution: false,
        ),
        isTrue,
      );
      expect(
        computeAwaitingOpponent(
          match: match,
          selectedChoice: 2,
          revealingResolution: false,
        ),
        isTrue,
      );
      expect(
        computeAwaitingOpponent(
          match: _match(id: 'm1', version: 1, opponentAnswered: true),
          selectedChoice: 1,
          revealingResolution: false,
        ),
        isFalse,
      );
    });
  });

  group('decideCancelOutcome', () {
    test('matched iptal yanıtında maça girer', () {
      expect(
        decideCancelOutcome(status: 'matched', matchId: 'abc'),
        HilalDuelCancelDecision.enterMatch,
      );
    });

    test('idle/waiting iptalde lobiye döner', () {
      expect(
        decideCancelOutcome(status: 'idle', matchId: null),
        HilalDuelCancelDecision.goLobby,
      );
      expect(
        decideCancelOutcome(status: 'matched', matchId: null),
        HilalDuelCancelDecision.goLobby,
      );
    });
  });

  group('queue arms / leave state machine', () {
    test('start in-flight leave requires cancel', () {
      final armed = armBeforeStartRpc(const HilalDuelQueueArms());
      expect(armed.startInFlight, isTrue);
      expect(armed.queueMayExist, isTrue);
      expect(armed.requiresCancelBeforeLeave, isTrue);
      expect(armed.shouldBestEffortCancelOnDispose, isTrue);
      expect(decideLeaveAction(armed), HilalDuelLeaveAction.requireCancel);
    });

    test('cancel failure retains queue armed and blocks pop', () {
      var arms = armBeforeStartRpc(const HilalDuelQueueArms());
      arms = afterStartWaiting(arms);
      arms = afterCancelRequested(arms);
      arms = afterCancelFailure(arms);
      expect(arms.cancelPending, isTrue);
      expect(arms.queueMayExist, isTrue);
      expect(arms.startInFlight, isFalse);
      expect(decideLeaveAction(arms), HilalDuelLeaveAction.requireCancel);
      expect(
        settleLeaveAfterCancel(
          decision: HilalDuelCancelDecision.goLobby,
          cancelSucceeded: false,
        ),
        HilalDuelLeaveSettle.blockedRetry,
      );
    });

    test('matched cancel outcome settles as enter match', () {
      expect(
        settleLeaveAfterCancel(
          decision: HilalDuelCancelDecision.enterMatch,
          cancelSucceeded: true,
        ),
        HilalDuelLeaveSettle.enteredMatch,
      );
      final disarmed = afterEnteredMatch(
        afterCancelRequested(afterStartWaiting(const HilalDuelQueueArms())),
      );
      expect(disarmed.requiresCancelBeforeLeave, isFalse);
      expect(decideLeaveAction(disarmed), HilalDuelLeaveAction.allowPop);
    });

    test('exact queue-disarm transitions', () {
      expect(
        afterQueueConfirmedAbsent(
          armBeforeStartRpc(const HilalDuelQueueArms()),
        ).requiresCancelBeforeLeave,
        isFalse,
      );
      expect(
        afterCancelIdleSuccess(
          afterCancelFailure(
            afterCancelRequested(afterStartWaiting(const HilalDuelQueueArms())),
          ),
        ).requiresCancelBeforeLeave,
        isFalse,
      );
      expect(
        afterEnteredMatch(
          armBeforeStartRpc(const HilalDuelQueueArms()),
        ).requiresCancelBeforeLeave,
        isFalse,
      );
      // idle cancel success → pop allowed
      expect(
        settleLeaveAfterCancel(
          decision: HilalDuelCancelDecision.goLobby,
          cancelSucceeded: true,
        ),
        HilalDuelLeaveSettle.poppedToLobby,
      );
      // lobby (disarmed) leave → allowPop
      expect(
        decideLeaveAction(const HilalDuelQueueArms()),
        HilalDuelLeaveAction.allowPop,
      );
    });

    test('cancelMayIssueRpc blocks while start pending', () {
      expect(cancelMayIssueRpc(startFuturePending: true), isFalse);
      expect(cancelMayIssueRpc(startFuturePending: false), isTrue);
    });
  });

  group('needsFastMatchPoll', () {
    test('kendi cevabından sonra reveal gelene kadar true', () {
      expect(
        needsFastMatchPoll(
          match: _match(id: 'm', version: 1, selfAnswered: true),
          selectedChoice: 1,
          revealingResolution: false,
          awaitingOpponent: false,
        ),
        isTrue,
      );
    });

    test('rakip Cevapladı olsa bile reveal yoksa true', () {
      expect(
        needsFastMatchPoll(
          match: _match(
            id: 'm',
            version: 1,
            selfAnswered: true,
            opponentAnswered: true,
          ),
          selectedChoice: 2,
          revealingResolution: false,
          awaitingOpponent: false,
        ),
        isTrue,
      );
    });

    test('reveal sırasında false', () {
      expect(
        needsFastMatchPoll(
          match: _match(id: 'm', version: 1, selfAnswered: true),
          selectedChoice: 1,
          revealingResolution: true,
          awaitingOpponent: false,
        ),
        isFalse,
      );
    });
  });

  group('computeRevealHoldMs', () {
    test('zamanında: untilStart kadar bekler (~2600)', () {
      expect(
        computeRevealHoldMs(
          nowMs: 10_000,
          roundStartedAtMs: 12_600,
          waitForRoundStart: true,
          matchCompleted: false,
        ),
        2600,
      );
    });

    test('geçikmede kısaltır — sabit 2600 ile sunucu saatini yakmaz', () {
      expect(
        computeRevealHoldMs(
          nowMs: 10_500,
          roundStartedAtMs: 12_600,
          waitForRoundStart: true,
          matchCompleted: false,
        ),
        2100,
      );
    });

    test('roundStartedAtMs geçmişse hemen biter', () {
      expect(
        computeRevealHoldMs(
          nowMs: 13_000,
          roundStartedAtMs: 12_600,
          waitForRoundStart: true,
          matchCompleted: false,
        ),
        1,
      );
    });

    test('aşırı untilStart 4500 ile sınırlanır', () {
      expect(
        computeRevealHoldMs(
          nowMs: 10_000,
          roundStartedAtMs: 20_000,
          waitForRoundStart: true,
          matchCompleted: false,
        ),
        4500,
      );
    });

    test('final reveal / waitForRoundStart false: varsayılan hold', () {
      expect(
        computeRevealHoldMs(
          nowMs: 10_000,
          roundStartedAtMs: 12_600,
          waitForRoundStart: false,
          matchCompleted: false,
        ),
        2600,
      );
      expect(
        computeRevealHoldMs(
          nowMs: 10_000,
          roundStartedAtMs: 12_600,
          waitForRoundStart: true,
          matchCompleted: true,
        ),
        2600,
      );
    });
  });

  group('round marks / server reveal choice', () {
    test('timeout choice (-1) missed sayılır, doğru index olsa bile', () {
      expect(
        markFromServerChoice(choice: -1, correctIndex: 2),
        HilalDuelRoundMark.missed,
      );
      expect(
        markFromServerChoice(choice: null, correctIndex: 2),
        HilalDuelRoundMark.missed,
      );
    });

    test('doğru ve yanlış işaretleri', () {
      expect(
        markFromServerChoice(choice: 1, correctIndex: 1),
        HilalDuelRoundMark.correct,
      );
      expect(
        markFromServerChoice(choice: 0, correctIndex: 1),
        HilalDuelRoundMark.wrong,
      );
    });

    test('serverChoiceForReveal timeout için null döner', () {
      final res = HilalDuelResolution(
        round: 0,
        question: const HilalDuelQuestion(
          id: 'q',
          category: 'c',
          text: 'Q?',
          options: ['a', 'b', 'c', 'd'],
          correctIndex: 2,
        ),
        choices: const {'a': -1, 'b': 2},
        elapsedMs: const {'a': 20000, 'b': 900},
      );
      expect(serverChoiceForReveal(resolution: res, playerId: 'a'), isNull);
      expect(serverChoiceForReveal(resolution: res, playerId: 'b'), 2);
      expect(serverChoiceForReveal(resolution: res, playerId: null), isNull);
    });

    test('perspective selfChoice/opponentChoice map key olmasa da çalışır', () {
      final res = HilalDuelResolution(
        round: 1,
        question: const HilalDuelQuestion(
          id: 'q',
          category: 'c',
          text: 'Q?',
          options: ['a', 'b', 'c', 'd'],
          correctIndex: 0,
        ),
        choices: const {},
        elapsedMs: const {},
        selfChoice: 2,
        opponentChoice: 0,
      );
      expect(
        serverChoiceForReveal(
          resolution: res,
          playerId: 'missing-self',
          preferPerspective: 'self',
        ),
        2,
      );
      expect(
        serverChoiceForReveal(
          resolution: res,
          playerId: 'missing-opp',
          preferPerspective: 'opponent',
        ),
        0,
      );
      expect(
        serverChoiceForReveal(
          resolution: res,
          playerId: 'x',
          preferPerspective: 'opponent',
        ),
        // index 0 geçerli seçim
        0,
      );
    });
  });

  group('shouldRevealBeforeChallengeSent', () {
    test('son tur çözümü varken lobiye hemen dönülmez', () {
      expect(
        shouldRevealBeforeChallengeSent(
          awaitingOpponent: true,
          hasLastResolution: true,
        ),
        isTrue,
      );
      expect(
        shouldRevealBeforeChallengeSent(
          awaitingOpponent: true,
          hasLastResolution: false,
        ),
        isFalse,
      );
      expect(
        shouldRevealBeforeChallengeSent(
          awaitingOpponent: false,
          hasLastResolution: true,
        ),
        isFalse,
      );
    });
  });

  group('parseRoundMarks', () {
    test('sunucu tokenlarını tahta işaretine çevirir', () {
      expect(parseRoundMarkToken('correct'), HilalDuelRoundMark.correct);
      expect(parseRoundMarkToken('wrong'), HilalDuelRoundMark.wrong);
      expect(parseRoundMarkToken('missed'), HilalDuelRoundMark.missed);
      expect(parseRoundMarkToken('pending'), HilalDuelRoundMark.pending);
      expect(parseRoundMarkToken(null), HilalDuelRoundMark.pending);
      expect(
        parseRoundMarks(
          ['correct', 'wrong', 'missed'],
          total: 7,
        ),
        [
          HilalDuelRoundMark.correct,
          HilalDuelRoundMark.wrong,
          HilalDuelRoundMark.missed,
          HilalDuelRoundMark.pending,
          HilalDuelRoundMark.pending,
          HilalDuelRoundMark.pending,
          HilalDuelRoundMark.pending,
        ],
      );
    });
  });

  group('hilalDuelFriendlyFunctionsMessage', () {
    test('hides raw INTERNAL from the lobby', () {
      expect(
        hilalDuelFriendlyFunctionsMessage(
          code: 'internal',
          message: 'INTERNAL',
        ),
        'Eşleşme başlatılamadı. Tekrar dene.',
      );
      expect(
        hilalDuelFriendlyFunctionsMessage(
          code: 'internal',
          message: 'Eşleşme başlatılamadı. Tekrar dene.',
        ),
        'Eşleşme başlatılamadı. Tekrar dene.',
      );
      expect(
        hilalDuelFriendlyFunctionsMessage(
          code: 'unknown',
          message: 'INTERNAL',
        ),
        'Bir hata oluştu. Tekrar dene.',
      );
    });
  });
}
