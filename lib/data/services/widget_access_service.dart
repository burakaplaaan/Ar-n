import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_gate_service.dart';
import 'arin_widget_sync.dart';

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
    final adGate = AdGateService(_prefs);
    final states = <ArinWidgetAccessKind, WidgetGateState>{};
    for (final kind in ArinWidgetAccessKind.values) {
      final state = await adGate.widgetStateFor(
        kind.placement,
        isPremium: isPremium,
      );
      states[kind] = state;
    }
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
    );
    return states;
  }

  Future<WidgetGateState> stateFor(
    ArinWidgetAccessKind kind, {
    required bool isPremium,
  }) {
    return AdGateService(
      _prefs,
    ).widgetStateFor(kind.placement, isPremium: isPremium);
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
}
