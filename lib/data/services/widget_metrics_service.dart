import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/product_metric_features.dart';
import 'ad_gate_service.dart';
import 'global_widget_lock_service.dart';
import 'product_metrics_service.dart';
import 'widget_access_service.dart';

/// Widget kullanımını platformların izin verdiği sinyallerden tahmin eder.
///
/// Ana ekran widget ile kilit ekranı bildirimi ayrı sayılır:
/// - Ana ekran: `arin_widget_home_last_render_ms_*` (AppWidget / home WidgetKit)
/// - Kilit bildirimi: `arin_lock_notif_*` (Android ongoing notif / iOS accessory)
///
/// Android/iOS kaldırılma olayını güvenilir biçimde vermediği için "bıraktı"
/// şu iş kuralıdır: en az bir ana ekran widget daha önce render edilmiş,
/// kullanıcının tüm ana ekran widget'ları 48 saattir kilitli ve bu sürede
/// reklam/premium açılışı yok.
abstract final class WidgetMetricsService {
  static const _churnThreshold = Duration(hours: 48);
  static const _churnedKey = 'arin_widget_metrics_user_churned_v1';
  static const _lastRenderReportedKey =
      'arin_widget_metrics_home_last_render_reported_v1';
  static const _lockLastShowReportedKey =
      'arin_widget_metrics_lock_last_show_reported_v1';

  static String _firstReportedKey(ArinWidgetAccessKind kind) =>
      'arin_widget_metrics_first_reported_${kind.id}_v1';

  static String _lockFirstReportedKey(ArinWidgetAccessKind kind) =>
      'arin_widget_metrics_lock_first_reported_${kind.id}_v1';

  static String _lockedSinceKey(ArinWidgetAccessKind kind) =>
      'arin_widget_metrics_locked_since_${kind.id}_v1';

  static Future<void> reconcile({
    required SharedPreferences prefs,
    required WidgetAccessService accessService,
    required Map<ArinWidgetAccessKind, WidgetGateState> states,
    required bool isPremium,
  }) async {
    try {
      await _reconcileHomeWidgets(
        prefs: prefs,
        accessService: accessService,
        states: states,
        isPremium: isPremium,
      );
      await _reconcileLockNotifications(
        prefs: prefs,
        accessService: accessService,
      );
    } catch (e) {
      debugPrint('WidgetMetricsService.reconcile başarısız (sessiz): $e');
    }
  }

  static Future<void> _reconcileHomeWidgets({
    required SharedPreferences prefs,
    required WidgetAccessService accessService,
    required Map<ArinWidgetAccessKind, WidgetGateState> states,
    required bool isPremium,
  }) async {
    final now = DateTime.now();
    final installed = <ArinWidgetAccessKind>[];
    var anyAllowed = false;
    var everyInstalledLockedFor48Hours = true;
    DateTime? latestNativeRender;

    for (final kind in ArinWidgetAccessKind.values) {
      // Ana ekran kanıtı: last_render. Kilit bildirimi shared first_use yazar
      // ama last_render yazmaz; böylece iki yüzey karışmaz.
      final lastRender = await accessService.lastRenderFor(kind);
      if (lastRender == null) continue;
      installed.add(kind);
      if (latestNativeRender == null ||
          lastRender.isAfter(latestNativeRender)) {
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
        await ProductMetricsService.featureOpen(ProductMetricFeatures.widget);
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
  }

  static Future<void> _reconcileLockNotifications({
    required SharedPreferences prefs,
    required WidgetAccessService accessService,
  }) async {
    DateTime? latestShow;
    var anyLockSurface = false;

    for (final kind in ArinWidgetAccessKind.values) {
      final firstUse = await accessService.lockNotifFirstUseFor(kind);
      if (firstUse == null) continue;
      anyLockSurface = true;

      if (prefs.getBool(_lockFirstReportedKey(kind)) != true) {
        final reported =
            await ProductMetricsService.lockNotifFirstUse(kind.id);
        if (reported) {
          await prefs.setBool(_lockFirstReportedKey(kind), true);
        }
      }

      final lastShow = await accessService.lockNotifLastShowFor(kind);
      if (lastShow != null &&
          (latestShow == null || lastShow.isAfter(latestShow))) {
        latestShow = lastShow;
      }
    }

    if (!anyLockSurface) return;

    final lastReportedMs = prefs.getInt(_lockLastShowReportedKey) ?? 0;
    final show = latestShow;
    if (show == null || show.millisecondsSinceEpoch <= lastReportedMs) {
      return;
    }
    if (await ProductMetricsService.lockNotifActive()) {
      await ProductMetricsService.featureOpen(
        ProductMetricFeatures.lockWidget,
      );
      await prefs.setInt(
        _lockLastShowReportedKey,
        show.millisecondsSinceEpoch,
      );
    }
  }

  static Future<void> recordRewardedUnlock(ArinWidgetAccessKind kind) =>
      ProductMetricsService.widgetUnlock(kind.id);
}
