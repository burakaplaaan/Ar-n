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
  tracking;

  String get id => switch (this) {
    ArinWidgetAccessKind.quote => 'quote',
    ArinWidgetAccessKind.prayer => 'prayer',
    ArinWidgetAccessKind.combo => 'combo',
    ArinWidgetAccessKind.tracking => 'tracking',
  };

  String get title => switch (this) {
    ArinWidgetAccessKind.quote => 'Günlük Söz Widgetı',
    ArinWidgetAccessKind.prayer => 'Namaz Vakti Widgetı',
    ArinWidgetAccessKind.combo => 'Söz + Namaz Widgetı',
    ArinWidgetAccessKind.tracking => 'Takip Widgetı',
  };

  AdGatePlacement get placement => switch (this) {
    ArinWidgetAccessKind.quote => AdGatePlacement.widgetQuote,
    ArinWidgetAccessKind.prayer => AdGatePlacement.widgetPrayer,
    ArinWidgetAccessKind.combo => AdGatePlacement.widgetCombo,
    ArinWidgetAccessKind.tracking => AdGatePlacement.widgetTracking,
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
    final states = <ArinWidgetAccessKind, WidgetGateState>{};
    for (final kind in ArinWidgetAccessKind.values) {
      final firstSeen = await _readWidgetFirstUse(kind);
      final adState = await adGate.widgetStateFor(
        kind.placement,
        isPremium: isPremium,
        firstSeen: firstSeen,
      );
      if (globallyLocked) {
        // Global kilit aktifken reklam unlock'u geçerliyse erişime izin ver.
        // Trial süresi ise global kilide takılır — reklam izlenmeden açılmaz.
        final rewardedStillValid =
            adState.unlockUntil != null &&
            adState.unlockUntil!.isAfter(DateTime.now());
        states[kind] = WidgetGateState(
          allowed: rewardedStillValid,
          inTrial: false,
          unlockUntil: rewardedStillValid ? adState.unlockUntil : null,
          trialUntil: null,
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
        for (final entry in states.entries) entry.key.id: !entry.value.allowed,
      },
      trialUntilByKind: {
        for (final entry in states.entries)
          entry.key.id: entry.value.trialUntil,
      },
      unlockUntilByKind: {
        for (final entry in states.entries)
          entry.key.id: entry.value.unlockUntil,
      },
      isPremium: isPremium,
      lockNote: lockNote,
    );
    return states;
  }

  Future<WidgetGateState> stateFor(
    ArinWidgetAccessKind kind, {
    required bool isPremium,
  }) async {
    final adGate = AdGateService(_prefs);
    final firstSeen = await _readWidgetFirstUse(kind);
    final adState = await adGate.widgetStateFor(
      kind.placement,
      isPremium: isPremium,
      firstSeen: firstSeen,
    );
    // Premium veya normal akış zaten allowed ise global kilidi sorgulamaya gerek yok.
    if (adState.allowed && isPremium) return adState;

    final globallyLocked = GlobalWidgetLockService.isGloballyLocked(_prefs);
    if (!globallyLocked) return adState;

    // Global kilit var: reklam unlock'u geçerliyse erişime izin ver.
    final rewardedStillValid =
        adState.unlockUntil != null &&
        adState.unlockUntil!.isAfter(DateTime.now());
    return WidgetGateState(
      allowed: rewardedStillValid,
      inTrial: false,
      unlockUntil: rewardedStillValid ? adState.unlockUntil : null,
      trialUntil: null,
    );
  }

  Future<void> recordRewardedUnlock(ArinWidgetAccessKind kind) async {
    await AdGateService(_prefs).recordWidgetRewardedUnlock(kind.placement);
  }

  Future<ArinWidgetAccessKind?> consumeLaunchedWidgetKind() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<String>('consumeWidgetLaunch');
      return ArinWidgetAccessKind.fromId(raw);
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
}
