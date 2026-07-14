import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/firebase/firebase_bootstrap.dart';

/// Admin performans ekranını besleyen anonim, tekilleştirilmiş ürün metrikleri.
///
/// Kurulum kimliği cihazda üretilir; Firebase UID, e-posta, içerik metni veya
/// konum gönderilmez. Sunucu kimliği SHA-256 ile hash'leyerek saklar.
abstract final class ProductMetricsService {
  static const _region = 'europe-west1';
  static const _installIdKey = 'arin_anonymous_install_id_v1';
  static const _pendingAudienceDeactivateKey =
      'arin_pending_audience_deactivate_id_v1';

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

  static Future<bool> _record(
    String event, {
    String? cardId,
    String? kind,
  }) async {
    if (!isFirebaseReady) return false;
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
      });
      final data = result.data;
      return data is Map && data['accepted'] == true;
    } catch (e) {
      debugPrint('ProductMetricsService.$event başarısız (sessiz): $e');
      return false;
    }
  }

  static Future<bool> contentView(String cardId) =>
      _record('content_view', cardId: cardId);

  static Future<bool> contentLike(String cardId) =>
      _record('content_like', cardId: cardId);

  static Future<bool> contentSave(String cardId) =>
      _record('content_save', cardId: cardId);

  static Future<bool> widgetActive() => _record('widget_active');

  static Future<bool> widgetFirstUse(String kind) =>
      _record('widget_first_use', kind: kind);

  static Future<bool> widgetChurned() => _record('widget_churned');

  static Future<bool> widgetReturned() => _record('widget_returned');

  static Future<bool> widgetUnlock(String kind) =>
      _record('widget_unlock', kind: kind);

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
}
