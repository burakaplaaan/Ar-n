// Meta App Events — iOS AEM / Android install attribution için.
// Kişisel içerik yollanmaz; yalnızca activate, purchase, registration.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

import '../constants/meta_ads_ids.dart';

/// Meta reklam ölçümü. Firebase Analytics'ten bağımsızdır.
abstract final class MetaAppEvents {
  static final FacebookAppEvents _fb = FacebookAppEvents();
  static bool _ready = false;
  static bool _attRequested = false;

  static bool get isReady => _ready;

  /// Onboarding bittikten sonra, ilk frame'ler geçtikten sonra çağır.
  /// iOS'ta ATT diyaloğunu gösterir; IDFA toplama izne göre ayarlanır.
  static Future<void> initialize() async {
    if (kIsWeb || _ready) return;
    if (!MetaAdsIds.isConfigured) {
      debugPrint(
        '══ ARIN ══ Meta App Events: Client Token eksik — '
        'lib/core/constants/meta_ads_ids.dart + native config\'e yapıştır.',
      );
      return;
    }
    if (!(Platform.isIOS || Platform.isAndroid)) return;

    try {
      var attAllowed = true;
      if (Platform.isIOS) {
        attAllowed = await _requestAttIfNeeded();
      }

      await _fb.setAutoLogAppEventsEnabled(true);
      // iOS'ta IDFA yalnızca ATT authorized ise gelir; yine de flag'i
      // kullanıcı iznine hizala.
      await _fb.setAdvertiserIdCollectionEnabled(
        Platform.isIOS ? attAllowed : true,
      );

      await _fb.activateApp();
      _ready = true;
      debugPrint(
        '══ ARIN ══ Meta App Events: ready'
        '${Platform.isIOS ? ' (ATT ${attAllowed ? "authorized" : "denied/restricted"})' : ''}',
      );
    } catch (e, st) {
      debugPrint('══ ARIN ══ Meta App Events init failed (sessiz): $e');
      debugPrint('$st');
    }
  }

  /// `true` = tracking authorized.
  static Future<bool> _requestAttIfNeeded() async {
    if (_attRequested) {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      return status == TrackingStatus.authorized;
    }
    _attRequested = true;
    try {
      final current =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (current == TrackingStatus.notDetermined) {
        // UI settle olsun diye kısa gecikme (Apple önerisi).
        await Future<void>.delayed(const Duration(milliseconds: 800));
        final result =
            await AppTrackingTransparency.requestTrackingAuthorization();
        return result == TrackingStatus.authorized;
      }
      return current == TrackingStatus.authorized;
    } catch (e) {
      debugPrint('══ ARIN ══ ATT request failed (sessiz): $e');
      return false;
    }
  }

  /// Premium / destek satın alma sonrası.
  static Future<void> logPurchase({
    required double amount,
    required String currency,
    String? orderId,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_ready) return;
    try {
      await _fb.logPurchase(
        amount: amount,
        currency: currency,
        parameters: {
          if (orderId != null && orderId.isNotEmpty) 'fb_order_id': orderId,
          ...?parameters,
        },
      );
    } catch (e) {
      debugPrint('══ ARIN ══ Meta logPurchase failed (sessiz): $e');
    }
  }

  static Future<void> logSubscribe({
    required double price,
    required String currency,
    required String orderId,
  }) async {
    if (!_ready) return;
    try {
      await _fb.logSubscribe(
        price: price,
        currency: currency,
        orderId: orderId,
      );
    } catch (e) {
      debugPrint('══ ARIN ══ Meta logSubscribe failed (sessiz): $e');
    }
  }

  static Future<void> logCompletedRegistration({String? method}) async {
    if (!_ready) return;
    try {
      await _fb.logCompletedRegistration(registrationMethod: method);
    } catch (_) {}
  }
}
