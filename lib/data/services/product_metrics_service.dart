import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import 'android_oem_settings_service.dart';

/// İstanbul takvim günü (Türkiye sürekli UTC+3) — sunucu `dayKey` ile aynı.
@visibleForTesting
String istanbulMetricDayKey(DateTime now) {
  final istanbul = now.toUtc().add(const Duration(hours: 3));
  final y = istanbul.year.toString().padLeft(4, '0');
  final m = istanbul.month.toString().padLeft(2, '0');
  final d = istanbul.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

@visibleForTesting
const kInstallPresenceMinInterval = Duration(hours: 6);

@visibleForTesting
bool shouldSkipInstallPresenceSync({
  required int? lastSyncedAtMs,
  required DateTime now,
  Duration minInterval = kInstallPresenceMinInterval,
}) {
  final last = lastSyncedAtMs ?? 0;
  if (last <= 0) return false;
  return now.millisecondsSinceEpoch - last < minInterval.inMilliseconds;
}

@visibleForTesting
String dailyMetricEventKey(String event, String entity) => '$event|$entity';

@visibleForTesting
bool shouldSkipDailyMetric({
  required String storedDayKey,
  required String todayKey,
  required Iterable<String> sentKeys,
  required String eventKey,
}) {
  if (storedDayKey.isEmpty || storedDayKey != todayKey) return false;
  return sentKeys.contains(eventKey);
}

/// Admin performans ekranını besleyen anonim, tekilleştirilmiş ürün metrikleri.
///
/// Kurulum kimliği cihazda üretilir; Firebase UID, e-posta, içerik metni veya
/// konum gönderilmez. Sunucu kimliği SHA-256 ile hash'leyerek saklar.
abstract final class ProductMetricsService {
  static const _region = 'europe-west1';
  static const _installIdKey = 'arin_anonymous_install_id_v1';
  static const _pendingAudienceDeactivateKey =
      'arin_pending_audience_deactivate_id_v1';
  static const _presenceAtKey = 'arin_install_presence_synced_at_ms_v1';
  static const _metricDayKey = 'arin_metric_client_day_v1';
  static const _metricSentKey = 'arin_metric_client_sent_v1';

  static int? _presenceSyncedAtMs;
  static String? _metricCacheDay;
  static Set<String>? _metricCacheSent;

  @visibleForTesting
  static void resetClientThrottleCacheForTest() {
    _presenceSyncedAtMs = null;
    _metricCacheDay = null;
    _metricCacheSent = null;
  }

  static Future<String?> _installId({bool createIfMissing = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installIdKey)?.trim();
    if (existing != null && existing.length >= 16) return existing;
    if (!createIfMissing) return null;
    final created = const Uuid().v4().replaceAll('-', '_');
    await prefs.setString(_installIdKey, created);
    return created;
  }

  static Future<String?> currentInstallId() =>
      _installId(createIfMissing: false);

  /// App Check korumalı anonim topluluk özellikleri aynı kurulum kimliğini
  /// kullanır. Kimlik sunucuda SHA-256 ile hash'lenmeden saklanmaz.
  static Future<String?> getOrCreateInstallId() => _installId();

  static Future<void> preservePendingAudienceDeactivation(
    String installId,
  ) async {
    if (installId.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingAudienceDeactivateKey, installId);
  }

  static String get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => 'other',
  };

  static bool _usesDailyClientDedupe(String event) =>
      event == 'content_view' || event == 'feature_open';

  static Future<bool> _alreadySentDailyMetric(
    String event,
    String entity,
  ) async {
    final today = istanbulMetricDayKey(DateTime.now());
    final eventKey = dailyMetricEventKey(event, entity);
    if (_metricCacheDay == today &&
        shouldSkipDailyMetric(
          storedDayKey: _metricCacheDay ?? '',
          todayKey: today,
          sentKeys: _metricCacheSent ?? const {},
          eventKey: eventKey,
        )) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final storedDay = prefs.getString(_metricDayKey) ?? '';
    final sent = storedDay == today
        ? (prefs.getStringList(_metricSentKey) ?? const <String>[])
        : const <String>[];
    _metricCacheDay = today;
    _metricCacheSent = sent.toSet();
    return shouldSkipDailyMetric(
      storedDayKey: storedDay,
      todayKey: today,
      sentKeys: sent,
      eventKey: eventKey,
    );
  }

  static Future<void> _markDailyMetricSent(String event, String entity) async {
    final today = istanbulMetricDayKey(DateTime.now());
    final eventKey = dailyMetricEventKey(event, entity);
    final prefs = await SharedPreferences.getInstance();
    final storedDay = prefs.getString(_metricDayKey) ?? '';
    final sent = storedDay == today
        ? [...?prefs.getStringList(_metricSentKey)]
        : <String>[];
    if (!sent.contains(eventKey)) sent.add(eventKey);
    await prefs.setString(_metricDayKey, today);
    await prefs.setStringList(_metricSentKey, sent);
    _metricCacheDay = today;
    _metricCacheSent = sent.toSet();
  }

  static Future<bool> _shouldSkipPresence() async {
    final now = DateTime.now();
    if (shouldSkipInstallPresenceSync(
      lastSyncedAtMs: _presenceSyncedAtMs,
      now: now,
    )) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_presenceAtKey);
    _presenceSyncedAtMs = last;
    return shouldSkipInstallPresenceSync(lastSyncedAtMs: last, now: now);
  }

  static Future<void> _markPresenceSynced() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _presenceSyncedAtMs = nowMs;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_presenceAtKey, nowMs);
  }

  static Future<bool> _record(
    String event, {
    String? cardId,
    String? kind,
    String? feature,
  }) async {
    if (!isFirebaseReady) return false;
    final entity = (cardId ?? feature ?? '').trim();
    if (_usesDailyClientDedupe(event) && entity.isNotEmpty) {
      if (await _alreadySentDailyMetric(event, entity)) return true;
    }
    try {
      final installId = await _installId();
      if (installId == null) return false;
      final callable = FirebaseFunctions.instanceFor(
        region: _region,
      ).httpsCallable('recordProductMetric');
      final result = await callable.call(<String, Object>{
        'event': event,
        'installId': installId,
        if (cardId != null) 'cardId': cardId,
        if (kind != null) 'kind': kind,
        if (feature != null) 'feature': feature,
      });
      final data = result.data;
      final accepted = data is Map && data['accepted'] == true;
      if (accepted && _usesDailyClientDedupe(event) && entity.isNotEmpty) {
        await _markDailyMetricSent(event, entity);
      }
      return accepted;
    } catch (e) {
      debugPrint('ProductMetricsService.$event başarısız (sessiz): $e');
      return false;
    }
  }

  static Future<bool> contentView(String cardId) =>
      _record('content_view', cardId: cardId);

  static Future<bool> contentLike(String cardId) =>
      _record('content_like', cardId: cardId);

  static Future<bool> contentUnlike(String cardId) =>
      _record('content_unlike', cardId: cardId);

  static Future<bool> contentSave(String cardId) =>
      _record('content_save', cardId: cardId);

  static Future<bool> widgetActive() => _record('widget_active');

  static Future<bool> widgetFirstUse(String kind) =>
      _record('widget_first_use', kind: kind);

  static Future<bool> lockNotifActive() => _record('lock_notif_active');

  static Future<bool> lockNotifFirstUse(String kind) =>
      _record('lock_notif_first_use', kind: kind);

  static Future<bool> widgetChurned() => _record('widget_churned');

  static Future<bool> widgetReturned() => _record('widget_returned');

  static Future<bool> widgetUnlock(String kind) =>
      _record('widget_unlock', kind: kind);

  /// Tamamlanan her reklam gösterimi (günlük tekilleştirme yok — kaç kez).
  static Future<bool> adWatch(String feature) =>
      _record('ad_watch', feature: feature);

  /// Özelliği o gün açan kurulum (install başına günde bir kez).
  static Future<bool> featureOpen(String feature) =>
      _record('feature_open', feature: feature);

  static Future<void> notificationClick(String deliveryId) async {
    if (!isFirebaseReady || deliveryId.trim().isEmpty) return;
    try {
      final installId = await _installId();
      if (installId == null) return;
      final callable = FirebaseFunctions.instanceFor(
        region: _region,
      ).httpsCallable('recordNotificationClick');
      await callable.call(<String, Object>{
        'deliveryId': deliveryId.trim(),
        'installId': installId,
      });
    } catch (e) {
      debugPrint('ProductMetricsService.notificationClick başarısız: $e');
    }
  }

  static Future<bool> _syncAudienceId({
    required String installId,
    required bool active,
  }) async {
    if (!isFirebaseReady) return false;
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: _region,
      ).httpsCallable('syncAnalyticsAudience');
      final result = await callable.call(<String, Object>{
        'installId': installId,
        'active': active,
        'platform': _platform,
      });
      return result.data is Map && result.data['ok'] == true;
    } catch (e) {
      debugPrint('ProductMetricsService.syncAudience başarısız: $e');
      return false;
    }
  }

  static Future<bool> syncNotificationAudience({required bool active}) async {
    if (!isFirebaseReady) return false;
    final prefs = await SharedPreferences.getInstance();

    if (active) {
      final pending = prefs.getString(_pendingAudienceDeactivateKey)?.trim();
      if (pending != null && pending.isNotEmpty) {
        final cleared = await _syncAudienceId(
          installId: pending,
          active: false,
        );
        if (cleared) {
          await prefs.remove(_pendingAudienceDeactivateKey);
        }
      }
    }

    final installId = await _installId(createIfMissing: active);
    if (installId == null) return !active;
    return _syncAudienceId(installId: installId, active: active);
  }

  /// Admin panelindeki kurulum / marka sayacı için cihaz varlığı.
  /// Bildirim izninden bağımsız; uygulamayı açan her kurulum sayılır.
  static Future<bool> syncInstallPresence() async {
    if (!isFirebaseReady || kIsWeb) return false;
    if (await _shouldSkipPresence()) return true;
    try {
      final installId = await _installId();
      if (installId == null) return false;
      var brand = 'Other';
      if (!kIsWeb && Platform.isIOS) {
        brand = 'iPhone';
      } else if (!kIsWeb && Platform.isAndroid) {
        final oem = await AndroidOemSettingsService.getInfo();
        brand = oem?.displayName ?? oem?.manufacturer ?? 'Other';
      }
      final callable = FirebaseFunctions.instanceFor(
        region: _region,
      ).httpsCallable('syncInstallPresence');
      final result = await callable.call(<String, Object>{
        'installId': installId,
        'platform': _platform,
        'brand': brand,
      });
      final ok = result.data is Map && result.data['ok'] == true;
      if (ok) await _markPresenceSynced();
      return ok;
    } catch (e) {
      debugPrint('ProductMetricsService.syncInstallPresence başarısız: $e');
      return false;
    }
  }
}
