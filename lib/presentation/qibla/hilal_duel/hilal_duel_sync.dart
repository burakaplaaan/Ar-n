import 'hilal_duel_repository.dart';

/// Sunucu `version` alanına göre eşzamanlı poll/submit yarışını çözer.
/// [incoming] daha eskiyse [current] korunur.
HilalDuelMatch? selectFresherMatch(
  HilalDuelMatch? current,
  HilalDuelMatch incoming,
) {
  if (current == null) return incoming;
  if (current.id != incoming.id) return incoming;
  if (incoming.version < current.version) return current;
  return incoming;
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
