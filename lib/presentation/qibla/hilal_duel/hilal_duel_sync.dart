import 'hilal_duel_repository.dart';

/// Oyun içi / sonuç doğru-yanlış tahtası için tur durumu.
enum HilalDuelRoundMark {
  /// Henüz oynanmadı.
  pending,

  /// Sunucuda `correct: true`.
  correct,

  /// Cevap var ama yanlış.
  wrong,

  /// Süre doldu / cevap yok (`choice: -1`).
  missed,
}

/// Sunucu `choice` + `correctIndex` → tahta işareti.
HilalDuelRoundMark markFromServerChoice({
  required int? choice,
  required int? correctIndex,
}) {
  if (choice == null || choice < 0) return HilalDuelRoundMark.missed;
  if (correctIndex != null && choice == correctIndex) {
    return HilalDuelRoundMark.correct;
  }
  return HilalDuelRoundMark.wrong;
}

/// Reveal / SFX için sunucu seçimi. `-1` (timeout) → `null`; yerel optimistic
/// seçime düşülmez — aksi halde doğru SFX + yeşil "Sen" skora yazılmadan
/// görünür ve sonuçtaki "Doğru cevap sayısı" çelişir.
///
/// [preferPerspective]: `self` | `opponent` — serialize edilmiş sabit alanlar
/// (map key kaybında bile çalışır). `null` ise yalnız [playerId] map lookup.
int? serverChoiceForReveal({
  required HilalDuelResolution resolution,
  required String? playerId,
  String? preferPerspective,
}) {
  int? fromPerspective;
  if (preferPerspective == 'self') {
    fromPerspective = resolution.selfChoice;
  } else if (preferPerspective == 'opponent') {
    fromPerspective = resolution.opponentChoice;
  }
  if (fromPerspective != null) {
    return fromPerspective < 0 ? null : fromPerspective;
  }

  if (playerId == null) return null;
  // Key tip/normalize farklarına karşı toString ile ara.
  final key = playerId.toString();
  int? choice = resolution.choices[key];
  if (choice == null) {
    for (final entry in resolution.choices.entries) {
      if (entry.key.toString() == key) {
        choice = entry.value;
        break;
      }
    }
  }
  if (choice == null) return null;
  if (choice < 0) return null;
  return choice;
}

/// Sunucu `version` alanına göre eşzamanlı poll/submit yarışını çözer.
/// [incoming] daha eskiyse [current] korunur.
/// Aynı version'da cevaplı / ilerlemiş durum ezilmez.
HilalDuelMatch? selectFresherMatch(
  HilalDuelMatch? current,
  HilalDuelMatch incoming,
) {
  if (current == null) return incoming;
  if (current.id != incoming.id) return incoming;
  if (incoming.version < current.version) return current;
  if (incoming.version > current.version) return incoming;
  // Eşit version: submit cevabını poll'un cevapsız kopyası ezmesin.
  final currentProgress = (current.selfAnswered ? 2 : 0) +
      (current.opponentAnswered ? 1 : 0) +
      current.currentRound * 10;
  final incomingProgress = (incoming.selfAnswered ? 2 : 0) +
      (incoming.opponentAnswered ? 1 : 0) +
      incoming.currentRound * 10;
  if (incomingProgress < currentProgress) return current;
  return incoming;
}

/// Önceki turun lastResolution'ı bir sonraki turun tamamında "gösterilmeli"
/// gibi durur; seçimi silmek için kullanılmamalı. Yalnızca henüz gösterilmemiş
/// çözüm için true.
bool shouldStartResolutionReveal({
  required HilalDuelMatch match,
  required int? alreadyRevealedRound,
}) {
  final res = match.lastResolution;
  if (res == null) return false;
  if (alreadyRevealedRound == res.round) return false;
  if (match.isCompleted) return res.round == match.currentRound;
  return res.round == match.currentRound - 1;
}

/// Submit sonrası optimistic seçim temizlensin mi?
/// Önceki turun lastResolution'ı varken bile aynı turda beklerken seçim kalmalı.
bool shouldClearOptimisticChoice({
  required int submittedRound,
  required HilalDuelMatch match,
}) {
  if (match.currentRound != submittedRound) return true;
  final res = match.lastResolution;
  // Bu turun çözümü geldiyse (rakip de cevapladı / süre bitti) temizle.
  return res != null && res.round == submittedRound;
}

bool computeAwaitingOpponent({
  required HilalDuelMatch match,
  required int? selectedChoice,
  required bool revealingResolution,
}) {
  if (match.isCompleted || revealingResolution || match.opponentAnswered) {
    return false;
  }
  return selectedChoice != null || match.selfAnswered;
}

/// Cevap sonrası reveal gelene kadar sık poll (rakip "Cevapladı" olsa bile).
bool needsFastMatchPoll({
  required HilalDuelMatch? match,
  required int? selectedChoice,
  required bool revealingResolution,
  required bool awaitingOpponent,
}) {
  if (match == null || match.isCompleted || revealingResolution) {
    return false;
  }
  if (awaitingOpponent) return true;
  if (selectedChoice != null || match.selfAnswered) return true;
  return false;
}

/// İptal yanıtı: matched ise maça gir; aksi halde lobi.
enum HilalDuelCancelDecision { enterMatch, goLobby }

HilalDuelCancelDecision decideCancelOutcome({
  required String status,
  String? matchId,
}) {
  if (status == 'matched' && matchId != null && matchId.isNotEmpty) {
    return HilalDuelCancelDecision.enterMatch;
  }
  return HilalDuelCancelDecision.goLobby;
}

/// Kuyruk/can şarjı henüz sunucuda olabilir — pop/dispose iptal gerektirebilir.
class HilalDuelQueueArms {
  const HilalDuelQueueArms({
    this.startInFlight = false,
    this.queueMayExist = false,
    this.cancelPending = false,
  });

  final bool startInFlight;
  final bool queueMayExist;
  final bool cancelPending;

  bool get requiresCancelBeforeLeave =>
      startInFlight || queueMayExist || cancelPending;

  bool get shouldBestEffortCancelOnDispose => requiresCancelBeforeLeave;

  HilalDuelQueueArms copyWith({
    bool? startInFlight,
    bool? queueMayExist,
    bool? cancelPending,
  }) {
    return HilalDuelQueueArms(
      startInFlight: startInFlight ?? this.startInFlight,
      queueMayExist: queueMayExist ?? this.queueMayExist,
      cancelPending: cancelPending ?? this.cancelPending,
    );
  }
}

/// start RPC öncesi: hem in-flight hem olası kuyruk bayrağı.
HilalDuelQueueArms armBeforeStartRpc(HilalDuelQueueArms current) {
  return current.copyWith(startInFlight: true, queueMayExist: true);
}

/// start sonucu waiting → hâlâ armed, in-flight bitti.
HilalDuelQueueArms afterStartWaiting(HilalDuelQueueArms current) {
  return current.copyWith(startInFlight: false, queueMayExist: true);
}

/// start/cancel matched → can maça bağlandı; kuyruk iadesi gerekmez.
HilalDuelQueueArms afterEnteredMatch(HilalDuelQueueArms current) {
  return const HilalDuelQueueArms();
}

/// start idle / kesin kuyruk yok.
HilalDuelQueueArms afterQueueConfirmedAbsent(HilalDuelQueueArms current) {
  return const HilalDuelQueueArms();
}

/// Kullanıcı ayrılmak istedi; iptal henüz bitmedi.
HilalDuelQueueArms afterCancelRequested(HilalDuelQueueArms current) {
  return current.copyWith(cancelPending: true, queueMayExist: true);
}

/// İptal RPC başarısız: pop engelli, kuyruk armed kalır.
HilalDuelQueueArms afterCancelFailure(HilalDuelQueueArms current) {
  return current.copyWith(
    startInFlight: false,
    cancelPending: true,
    queueMayExist: true,
  );
}

/// İptal idle ile tamamlandı.
HilalDuelQueueArms afterCancelIdleSuccess(HilalDuelQueueArms current) {
  return const HilalDuelQueueArms();
}

/// Ayrılma kararı (pure): pop mu, iptal mi, blok mu.
enum HilalDuelLeaveAction { allowPop, requireCancel }

HilalDuelLeaveAction decideLeaveAction(HilalDuelQueueArms arms) {
  if (arms.requiresCancelBeforeLeave) {
    return HilalDuelLeaveAction.requireCancel;
  }
  return HilalDuelLeaveAction.allowPop;
}

/// İptal sonucu sonrası UI yönü.
enum HilalDuelLeaveSettle { poppedToLobby, enteredMatch, blockedRetry }

HilalDuelLeaveSettle settleLeaveAfterCancel({
  required HilalDuelCancelDecision decision,
  required bool cancelSucceeded,
}) {
  if (!cancelSucceeded) return HilalDuelLeaveSettle.blockedRetry;
  if (decision == HilalDuelCancelDecision.enterMatch) {
    return HilalDuelLeaveSettle.enteredMatch;
  }
  return HilalDuelLeaveSettle.poppedToLobby;
}

/// Cancel must not issue RPC while the captured start future is still pending.
bool cancelMayIssueRpc({required bool startFuturePending}) {
  return !startFuturePending;
}

/// Ara tur reveal süresi: yeni soru [roundStartedAtMs] ile açılsın.
/// Gecikmede kısalt/atla — sabit 2600ms sunucu saatinden çalmasın.
int computeRevealHoldMs({
  required int nowMs,
  required int roundStartedAtMs,
  required bool waitForRoundStart,
  required bool matchCompleted,
  int defaultHoldMs = 2600,
  int maxHoldMs = 4500,
}) {
  if (!waitForRoundStart || matchCompleted) {
    return defaultHoldMs.clamp(1, maxHoldMs);
  }
  final untilStart = roundStartedAtMs - nowMs;
  if (untilStart <= 0) return 1;
  return untilStart.clamp(1, maxHoldMs);
}
