import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arin_widget_sync.dart';
import 'ad_gate_service.dart';
import 'global_widget_lock_service.dart';

/// Sunucudan gelen sessiz widget-kilit mesajının doğrulanmış karşılığı.
@immutable
class WidgetGlobalLockPushPayload {
  const WidgetGlobalLockPushPayload({
    required this.locked,
    required this.revision,
    required this.note,
    required this.unlockHours,
  });

  static const messageType = 'widget_global_lock';

  final bool locked;
  final int revision;
  final String note;
  final int unlockHours;

  static WidgetGlobalLockPushPayload? tryParse(Map<String, dynamic> data) {
    if (data['type']?.toString() != messageType) return null;

    final lockedRaw = data['locked']?.toString();
    if (lockedRaw != '1' && lockedRaw != '0') return null;

    final revision = int.tryParse(data['revision']?.toString() ?? '');
    if (revision == null || revision <= 0) return null;
    final unlockHoursRaw = data['unlockHours'];
    final unlockHours = unlockHoursRaw == null
        ? GlobalWidgetLockService.defaultUnlockHours
        : int.tryParse(unlockHoursRaw.toString());
    if (!GlobalWidgetLockService.isValidUnlockHours(unlockHours)) return null;

    return WidgetGlobalLockPushPayload(
      locked: lockedRaw == '1',
      revision: revision,
      note: data['note']?.toString() ?? '',
      unlockHours: unlockHours!,
    );
  }

  bool isOlderThan(int appliedRevision) => revision < appliedRevision;
}

/// FCM data mesajını App Group/HomeWidget deposuna uygular ve tüm widget
/// provider'larını yeniden çizer. Mesaj görünür bildirim üretmez.
abstract final class WidgetGlobalLockPushService {
  static Future<bool> applyMessageData(
    Map<String, dynamic> data, {
    required bool persistFlutterState,
  }) async {
    final payload = WidgetGlobalLockPushPayload.tryParse(data);
    if (payload == null) return false;

    try {
      if (persistFlutterState) {
        final prefs = await SharedPreferences.getInstance();
        final applied = await GlobalWidgetLockService.applyRemoteOverride(
          prefs,
          locked: payload.locked,
          revision: payload.revision,
          note: payload.note,
          unlockHours: payload.unlockHours,
        );
        if (!applied) {
          // Eski foreground mesaj native cache'i de geri almamalı. Mevcut
          // Flutter otoritesini native tarafa tekrar basarak partial failure'ı
          // da iyileştir.
          await ArinWidgetSync.applyGlobalLockOverride(
            locked: GlobalWidgetLockService.isGloballyLocked(prefs),
            revision: GlobalWidgetLockService.revision(prefs),
            lockNote: GlobalWidgetLockService.lockedNote(prefs),
            unlockHours: GlobalWidgetLockService.unlockHours(prefs),
          );
          return true;
        }
      }
      await ArinWidgetSync.applyGlobalLockOverride(
        locked: payload.locked,
        revision: payload.revision,
        lockNote: payload.note,
        unlockHours: payload.unlockHours,
      );
    } catch (e, st) {
      debugPrint('WidgetGlobalLockPushService: $e\n$st');
    }
    return true;
  }

  /// Background isolate SharedPreferences'a yazmaz; böylece foreground fetch
  /// ile cross-isolate read-check-write yarışı oluşmaz. Resume sırasında
  /// native/App Group snapshot'ı tek foreground kuyruğuna alınır.
  static Future<void> reconcileFromWidgetCache(SharedPreferences prefs) async {
    try {
      final snapshot = await ArinWidgetSync.readGlobalLockOverride();
      if (snapshot == null) return;
      final applied = await GlobalWidgetLockService.applyRemoteOverride(
        prefs,
        locked: snapshot.locked,
        revision: snapshot.revision,
        note: snapshot.note,
        unlockHours: snapshot.unlockHours,
      );
      if (!applied) return;
      await AdGateService(prefs).reconcileWidgetUnlockSnapshot(
        startedAtMsByKind: snapshot.unlockStartedAtMsByKind,
        untilMsByKind: snapshot.unlockUntilMsByKind,
      );
    } catch (e, st) {
      debugPrint('WidgetGlobalLockPushService.reconcile: $e\n$st');
    }
  }
}
