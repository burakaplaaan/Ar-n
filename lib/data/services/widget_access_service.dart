import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_gate_service.dart';
import 'arin_widget_sync.dart';
import 'global_widget_lock_service.dart';

enum ArinWidgetAccessKind {
  quote,
  prayer,
  combo,
  tracking,
  zikir;

  String get id => switch (this) {
    ArinWidgetAccessKind.quote => 'quote',
    ArinWidgetAccessKind.prayer => 'prayer',
    ArinWidgetAccessKind.combo => 'combo',
    ArinWidgetAccessKind.tracking => 'tracking',
    ArinWidgetAccessKind.zikir => 'zikir',
  };

  AdGatePlacement get placement => switch (this) {
    ArinWidgetAccessKind.quote => AdGatePlacement.widgetQuote,
    ArinWidgetAccessKind.prayer => AdGatePlacement.widgetPrayer,
    ArinWidgetAccessKind.combo => AdGatePlacement.widgetCombo,
    ArinWidgetAccessKind.tracking => AdGatePlacement.widgetTracking,
    ArinWidgetAccessKind.zikir => AdGatePlacement.widgetZikir,
  };

  static ArinWidgetAccessKind? fromId(String? id) {
    final normalized = id?.trim().toLowerCase();
    for (final kind in values) {
      if (kind.id == normalized) return kind;
    }
    return null;
  }
}

class WidgetAccessService {
  WidgetAccessService(this._prefs);

  final SharedPreferences _prefs;

  static const _channel = MethodChannel('com.arin.arin/widget_launch');

  Future<Map<ArinWidgetAccessKind, WidgetGateState>> syncAll({
    required bool isPremium,
  }) async {
    final globallyLocked =
        !isPremium && GlobalWidgetLockService.isGloballyLocked(_prefs);

    final adGate = AdGateService(_prefs);
    final normalStates = <ArinWidgetAccessKind, WidgetGateState>{};
    final states = <ArinWidgetAccessKind, WidgetGateState>{};
    for (final kind in ArinWidgetAccessKind.values) {
      final firstSeen = await _readWidgetFirstUse(kind);

      // firstSeen henüz yazılmamış ama native gate daha önce "kilitli" olarak
      // işaretlenmişse (önceki syncAll'dan kalan "1" değeri), widget'ı yanlışlıkla
      // açmamak için mevcut kilit durumunu koru.
      final effectiveFirstSeen =
          (firstSeen == null && !isPremium && await _readNativeGateLocked(kind))
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : firstSeen;

      final adState = await adGate.widgetStateFor(
        kind.placement,
        isPremium: isPremium,
        firstSeen: effectiveFirstSeen,
      );
      normalStates[kind] = adState;
      if (globallyLocked) {
        // Acil global override: premium olmayan tüm widget'ları trial veya
        // reklamla açılmış unlock hakkına bakmadan anında kilitle.
        // Süreler silinmez; override kalkınca normal durum yeniden hesaplanır.
        states[kind] = WidgetGateState(
          allowed: false,
          inTrial: false,
          unlockUntil: adState.unlockUntil,
          trialUntil: adState.trialUntil,
        );
      } else {
        states[kind] = adState;
      }
    }
    final lockNote = globallyLocked
        ? GlobalWidgetLockService.lockedNote(_prefs)
        : '';
    await ArinWidgetSync.pushWidgetGateStates(
      lockedByKind: {
        // Global override ayrı native anahtarda tutulur. Buraya normal erişim
        // yazılır ki uzaktan unlock yalnızca override'ı kaldırarak trial veya
        // reklam hakkının o anki doğal sonucuna geri dönebilsin.
        for (final entry in normalStates.entries)
          entry.key.id: !entry.value.allowed,
      },
      trialUntilByKind: {
        for (final entry in normalStates.entries)
          entry.key.id: entry.value.trialUntil,
      },
      unlockUntilByKind: {
        for (final entry in normalStates.entries)
          entry.key.id: entry.value.unlockUntil,
      },
      unlockStartedAtByKind: {
        for (final kind in ArinWidgetAccessKind.values)
          kind.id: adGate.unlockStartedAt(kind.placement),
      },
      isPremium: isPremium,
      globalLocked: globallyLocked,
      globalLockRevision: GlobalWidgetLockService.revision(_prefs),
      unlockHours: GlobalWidgetLockService.unlockHours(_prefs),
      lockNote: lockNote,
    );
    return states;
  }

  Future<WidgetGateState> stateFor(
    ArinWidgetAccessKind kind, {
    required bool isPremium,
  }) async {
    final adGate = AdGateService(_prefs);
    await adGate.reconcileWidgetUnlockDeadline(kind.placement);
    final firstSeen = await _readWidgetFirstUse(kind);

    // firstSeen henüz yazılmamışsa widget'ın home ekrana yeni eklendiği varsayılır
    // ve trial başlatılmaz (erişime izin verilir). Ancak native gate daha önce
    // "kilitli" olarak işaretlendiyse (önceki syncAll'ın yazdığı "1" değeri)
    // bu bypass'ı uygulamamalıyız; sadece rewarded unlock'u kontrol ederiz.
    if (firstSeen == null && !isPremium) {
      final nativeLocked = await _readNativeGateLocked(kind);
      if (nativeLocked) {
        final unlock = adGate.unlockUntil(kind.placement);
        final unlocked = unlock != null && unlock.isAfter(DateTime.now());
        final globallyLocked = GlobalWidgetLockService.isGloballyLocked(_prefs);
        if (globallyLocked) {
          return WidgetGateState(
            allowed: false,
            inTrial: false,
            unlockUntil: unlock,
            trialUntil: null,
          );
        }
        return WidgetGateState(
          allowed: unlocked,
          inTrial: false,
          unlockUntil: unlocked ? unlock : null,
          trialUntil: null,
        );
      }
    }

    final adState = await adGate.widgetStateFor(
      kind.placement,
      isPremium: isPremium,
      firstSeen: firstSeen,
    );
    // Premium veya normal akış zaten allowed ise global kilidi sorgulamaya gerek yok.
    if (adState.allowed && isPremium) return adState;

    final globallyLocked = GlobalWidgetLockService.isGloballyLocked(_prefs);
    if (!globallyLocked) return adState;

    // Acil global override: premium olmayan kullanıcı için hiçbir geçici hak
    // override'ı aşamaz. Hakların süreleri arka planda işlemeye devam eder.
    return WidgetGateState(
      allowed: false,
      inTrial: false,
      unlockUntil: adState.unlockUntil,
      trialUntil: adState.trialUntil,
    );
  }

  Future<void> recordRewardedUnlock(ArinWidgetAccessKind kind) async {
    await AdGateService(_prefs).recordWidgetRewardedUnlock(kind.placement);
  }

  /// Native widget'ın ilk kez gerçekten çizildiği zamanı analytics/retention
  /// katmanına güvenli, salt-okunur şekilde açar.
  Future<DateTime?> firstUseFor(ArinWidgetAccessKind kind) =>
      _readWidgetFirstUse(kind);

  /// Native provider'ın en son gerçek render/update heartbeat'i.
  Future<DateTime?> lastRenderFor(ArinWidgetAccessKind kind) async {
    if (kIsWeb) return null;
    try {
      final raw = await HomeWidget.getWidgetData<String>(
        'arin_widget_last_render_ms_${kind.id}',
      );
      if (raw == null || raw.isEmpty) return null;
      final ms = int.tryParse(raw) ?? double.tryParse(raw)?.toInt();
      if (ms == null || ms <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (e) {
      debugPrint('WidgetAccessService.lastRenderFor(${kind.id}): $e');
      return null;
    }
  }

  Future<String?> consumeLaunchedWidgetKind() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<String>('consumeWidgetLaunch');
      return raw;
    } catch (e) {
      debugPrint('WidgetAccessService.consumeLaunchedWidgetKind: $e');
      return null;
    }
  }

  /// Native widget provider'ın (iOS `getTimeline`, Android `onUpdate`) ilk
  /// render'da App Group'a / `HomeWidgetPreferences`'a yazdığı ilk-kullanım
  /// zaman damgasını okur. Anahtar her iki platformda da
  /// `arin_widget_first_use_ms_<kind>` (epoch ms, String). Yoksa `null`.
  ///
  /// Bu kanal, trial sayacının yalnızca widget gerçekten home ekrana
  /// eklendiğinde başlamasını sağlar; uygulamanın açılışında otomatik trial
  /// başlatma davranışı (eski sürüm) kaldırıldı.
  Future<DateTime?> _readWidgetFirstUse(ArinWidgetAccessKind kind) async {
    if (kIsWeb) return null;
    try {
      final raw = await HomeWidget.getWidgetData<String>(
        'arin_widget_first_use_ms_${kind.id}',
      );
      if (raw == null || raw.isEmpty) return null;
      final ms = int.tryParse(raw) ?? double.tryParse(raw)?.toInt();
      if (ms == null || ms <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (e) {
      debugPrint('WidgetAccessService._readWidgetFirstUse(${kind.id}): $e');
      return null;
    }
  }

  /// Native gate anahtarını (`arin_widget_gate_<kind>_locked`) okuyarak
  /// Flutter'ın daha önce bu widget'ı "kilitli" olarak işaretleyip
  /// işaretlemediğini döndürür. "1" ise `true`, aksi halde `false`.
  ///
  /// Bu, `firstSeen` henüz yazılmamışken (race condition veya ilk kurulum)
  /// kilit kapısının yanlışlıkla atlanmasını önler.
  Future<bool> _readNativeGateLocked(ArinWidgetAccessKind kind) async {
    if (kIsWeb) return false;
    try {
      final raw = await HomeWidget.getWidgetData<String>(
        'arin_widget_gate_${kind.id}_locked',
      );
      return raw == '1';
    } catch (e) {
      debugPrint('WidgetAccessService._readNativeGateLocked(${kind.id}): $e');
      return false;
    }
  }
}
