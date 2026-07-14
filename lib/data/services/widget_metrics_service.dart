import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_gate_service.dart';
import 'global_widget_lock_service.dart';
import 'product_metrics_service.dart';
import 'widget_access_service.dart';

/// Widget kullanımını platformların izin verdiği sinyallerden tahmin eder.
///
/// Android/iOS kaldırılma olayını güvenilir biçimde vermediği için "bıraktı"
/// şu iş kuralıdır: en az bir widget daha önce render edilmiş, kullanıcının
/// tüm widget'ları 48 saattir kilitli ve bu sürede reklam/premium açılışı yok.
abstract final class WidgetMetricsService {
  static const _churnThreshold = Duration(hours: 48);
  static const _churnedKey = 'arin_widget_metrics_user_churned_v1';
  static const _lastRenderReportedKey =
      'arin_widget_metrics_last_render_reported_v1';

  static String _firstReportedKey(ArinWidgetAccessKind kind) =>
      'arin_widget_metrics_first_reported_${kind.id}_v1';

  static String _lockedSinceKey(ArinWidgetAccessKind kind) =>
      'arin_widget_metrics_locked_since_${kind.id}_v1';

  static Future<void> reconcile({
    required SharedPreferences prefs,
    required WidgetAccessService accessService,
    required Map<ArinWidgetAccessKind, WidgetGateState> states,
    required bool isPremium,
  }) async {
    try {
      final now = DateTime.now();
      final installed = <ArinWidgetAccessKind>[];
      var anyAllowed = false;
      var everyInstalledLockedFor48Hours = true;
      DateTime? latestNativeRender;

      for (final kind in ArinWidgetAccessKind.values) {
        final firstUse = await accessService.firstUseFor(kind);
        if (firstUse == null) continue;
        installed.add(kind);
        final lastRender = await accessService.lastRenderFor(kind);
        if (lastRender != null &&
            (latestNativeRender == null ||
                lastRender.isAfter(latestNativeRender))) {
          latestNativeRender = lastRender;
        }

        if (prefs.getBool(_firstReportedKey(kind)) != true) {
          final reported = await ProductMetricsService.widgetFirstUse(kind.id);
          if (reported) {
            await prefs.setBool(_firstReportedKey(kind), true);
          }
        }

        final state = states[kind];
        if (state == null) {
          everyInstalledLockedFor48Hours = false;
          continue;
        }
        if (state.allowed || isPremium) {
          anyAllowed = true;
          await prefs.remove(_lockedSinceKey(kind));
          continue;
        }

        final rawLockedSince = prefs.getInt(_lockedSinceKey(kind));
        final naturalLockStart = [state.trialUntil, state.unlockUntil]
            .whereType<DateTime>()
            .where((date) => !date.isAfter(now))
            .fold<DateTime?>(
              null,
              (latest, date) =>
                  latest == null || date.isAfter(latest) ? date : latest,
            );
        final lockedSince = rawLockedSince == null
            ? (naturalLockStart ?? now)
            : DateTime.fromMillisecondsSinceEpoch(rawLockedSince);
        if (rawLockedSince == null) {
          await prefs.setInt(
            _lockedSinceKey(kind),
            lockedSince.millisecondsSinceEpoch,
          );
        }
        if (now.difference(lockedSince) < _churnThreshold) {
          everyInstalledLockedFor48Hours = false;
        }
      }

      if (installed.isEmpty) return;

      final lastReportedMs = prefs.getInt(_lastRenderReportedKey) ?? 0;
      final nativeRender = latestNativeRender;
      final hasNewNativeRender =
          nativeRender != null &&
          nativeRender.millisecondsSinceEpoch > lastReportedMs;
      Future<void> reportNewNativeRender() async {
        if (!hasNewNativeRender) return;
        if (await ProductMetricsService.widgetActive()) {
          await prefs.setInt(
            _lastRenderReportedKey,
            nativeRender.millisecondsSinceEpoch,
          );
        }
      }

      // Admin'in acil global kilidi kullanıcı tercihi değildir; churn üretmez.
      if (!isPremium && GlobalWidgetLockService.isGloballyLocked(prefs)) {
        await reportNewNativeRender();
        for (final kind in installed) {
          await prefs.setInt(_lockedSinceKey(kind), now.millisecondsSinceEpoch);
        }
        return;
      }

      final wasChurned = prefs.getBool(_churnedKey) == true;
      if (anyAllowed) {
        if (wasChurned && await ProductMetricsService.widgetReturned()) {
          await prefs.setBool(_churnedKey, false);
        }
        await reportNewNativeRender();
        return;
      }

      await reportNewNativeRender();
      if (!wasChurned &&
          everyInstalledLockedFor48Hours &&
          await ProductMetricsService.widgetChurned()) {
        await prefs.setBool(_churnedKey, true);
      }
    } catch (e) {
      debugPrint('WidgetMetricsService.reconcile başarısız (sessiz): $e');
    }
  }

  static Future<void> recordRewardedUnlock(ArinWidgetAccessKind kind) =>
      ProductMetricsService.widgetUnlock(kind.id);
}
