// Meta App Events — iOS AEM / Android install attribution için.
// Kişisel içerik yollanmaz; yalnızca activate, purchase, registration.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/meta_ads_ids.dart';
import '../../data/services/startup_permission_policy.dart';

/// Meta reklam ölçümü. Firebase Analytics'ten bağımsızdır.
abstract final class MetaAppEvents {
  static const _pendingAttPromptKey = 'arin_meta_att_prompt_pending_v1';
  static const _registrationLoggedKey =
      'arin_meta_onboarding_registration_logged_v1';
  static final FacebookAppEvents _fb = FacebookAppEvents();
  static bool _ready = false;
  static Future<void>? _initialization;
  static Future<void>? _attRequest;
  static Future<void>? _onboardingCompletion;
  static bool _retryAttPromptOnResume = false;

  static bool get isReady => _ready;

  /// İlk görünür frame'den sonra kimliksiz ölçümü başlatır.
  ///
  /// ATT henüz kararlaştırılmadıysa IDFA kapalı kalır; buna rağmen Meta'nın
  /// gizlilik korumalı install/activate event'leri onboarding tamamlanmasına
  /// bağlı olmadan gönderilir. Sistem izin penceresi yalnızca kullanıcı
  /// onboarding'i bitirdiğinde [requestTrackingAuthorization] ile açılır.
  static Future<void> initialize() {
    if (kIsWeb || _ready) return Future<void>.value();
    if (!MetaAdsIds.isConfigured) {
      debugPrint(
        '══ ARIN ══ Meta App Events: Client Token eksik — '
        'lib/core/constants/meta_ads_ids.dart + native config\'e yapıştır.',
      );
      return Future<void>.value();
    }
    if (!(Platform.isIOS || Platform.isAndroid)) return Future<void>.value();

    return _initialization ??= _initializeOnce();
  }

  static Future<void> _initializeOnce() async {
    try {
      final attAllowed = Platform.isIOS ? await _isTrackingAuthorized() : true;

      await _fb.setAdvertiserIdCollectionEnabled(
        Platform.isIOS ? attAllowed : true,
      );
      if (Platform.isIOS) {
        // StoreKit install/launch/purchase/subscription olaylarının tek kaynağı
        // native FBSDK auto-log'dur.
        await _fb.setAutoLogAppEventsEnabled(true);
      } else {
        // RevenueCat Android, Billing 8 kullanıyor; FBSDK 18 auto-IAP yalnız
        // Billing 2–7'yi destekliyor. Çift/eksik purchase üretmemek için
        // Android'de auto-log kapalı, activate ve purchase olayları manueldir.
        await _fb.setAutoLogAppEventsEnabled(false);
        await _fb.activateApp();
      }
      _ready = true;
      debugPrint(
        '══ ARIN ══ Meta App Events: ready'
        '${Platform.isIOS ? ' (ATT ${attAllowed ? "authorized" : "denied/restricted"})' : ''}',
      );
    } catch (e, st) {
      debugPrint('══ ARIN ══ Meta App Events init failed (sessiz): $e');
      debugPrint('$st');
    } finally {
      _initialization = null;
    }
  }

  /// Onboarding tamamlandığında ATT kararını alır ve kayıt dönüşümünü yalnızca
  /// bir kez Meta'ya yollar. Native SDK install/launch olaylarını otomatik
  /// toplar; bu event ise reklamdan gelen kullanıcının onboarding'i gerçekten
  /// tamamladığını ölçmek ve kampanya optimizasyonunu güçlendirmek içindir.
  static Future<void> completeOnboardingAttribution() {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) {
      return Future<void>.value();
    }
    return _onboardingCompletion ??= _completeOnboardingAttributionOnce();
  }

  static Future<void> _completeOnboardingAttributionOnce() async {
    try {
      if (Platform.isIOS) {
        await requestTrackingAuthorization();
      }
      if (!_ready) await initialize();
      if (!_ready) return;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_registrationLoggedKey) == true) return;

      // Meta App Events event-id ile deduplication sunmadığı için at-most-once
      // semantiği kullanılır. Marker önce yazılır; native log çağrısı senkron
      // hata verirse geri alınır. Başarılı log'dan sonraki flush yalnızca
      // best-effort'tür; SDK kendi kalıcı kuyruğunu ayrıca gönderir.
      final markerSaved = await prefs.setBool(_registrationLoggedKey, true);
      if (!markerSaved) {
        debugPrint('══ ARIN ══ Meta registration marker kaydedilemedi');
        return;
      }
      try {
        await _fb.logCompletedRegistration(registrationMethod: 'onboarding');
      } catch (_) {
        await prefs.remove(_registrationLoggedKey);
        rethrow;
      }
      try {
        await _fb.flush();
      } catch (e) {
        debugPrint('══ ARIN ══ Meta registration flush deferred: $e');
      }
      debugPrint('══ ARIN ══ Meta App Events: onboarding registered');
    } catch (e) {
      debugPrint('══ ARIN ══ Meta onboarding attribution failed (sessiz): $e');
    } finally {
      _onboardingCompletion = null;
    }
  }

  /// Kullanıcının onboarding'i tamamlayan aksiyonundan sonra ATT iznini ister.
  ///
  /// Uygulama aktif değilse diyaloğu zorlamaz; bir sonraki resume'da tek
  /// seferlik tekrar dener. İzin reddedilse bile kimliksiz Meta event'leri
  /// gönderilmeye devam eder.
  static Future<void> requestTrackingAuthorization() {
    if (kIsWeb || !Platform.isIOS) return Future<void>.value();
    _retryAttPromptOnResume = true;
    return _attRequest ??= _requestTrackingAuthorizationOnce();
  }

  static Future<void> _requestTrackingAuthorizationOnce() async {
    try {
      await _setAttPromptPending(true);
      final prefs = await SharedPreferences.getInstance();
      if (shouldDeferSystemPromptsForAppTour(
        tourPending: prefs.getBool(kAppTourPendingKey) == true,
        tourCompleted: prefs.getBool(kAppTourCompletedKey) == true,
      )) {
        debugPrint('══ ARIN ══ ATT tanıtım bitene kadar ertelendi');
        return;
      }
      if (!_ready) await initialize();
      if (!_ready) return;

      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        if (WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
          return;
        }
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }

      _retryAttPromptOnResume = status == TrackingStatus.notDetermined;
      await _setAttPromptPending(_retryAttPromptOnResume);
      await _fb.setAdvertiserIdCollectionEnabled(
        status == TrackingStatus.authorized,
      );
      debugPrint('══ ARIN ══ Meta App Events: ATT $status');
    } catch (e) {
      debugPrint('══ ARIN ══ ATT request failed (sessiz): $e');
    } finally {
      _attRequest = null;
    }
  }

  /// Kullanıcı etkileşimiyle başlatılmış ancak uygulama kapanması veya
  /// arka plana geçiş nedeniyle gösterilememiş ATT isteğini geri yükler.
  static Future<void> retryPendingTrackingAuthorizationIfNeeded() async {
    if (kIsWeb || !Platform.isIOS) return;
    if (!await _hasPendingAttPrompt()) return;
    _retryAttPromptOnResume = true;
    await requestTrackingAuthorization();
  }

  /// iOS Ayarlar'da takip izni değiştirildiyse Meta SDK'yı güncel sistem
  /// izniyle hizalar. Yalnızca daha önce kullanıcı etkileşimiyle başlatılmış
  /// yarım kalan bir istek varsa ATT diyaloğunu yeniden deneyebilir.
  static Future<void> syncTrackingAuthorization() async {
    if (kIsWeb || !Platform.isIOS) return;
    if (!_ready) await initialize();
    if (!_ready) return;
    if (_retryAttPromptOnResume || await _hasPendingAttPrompt()) {
      await requestTrackingAuthorization();
      return;
    }
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      final allowed = status == TrackingStatus.authorized;
      await _fb.setAdvertiserIdCollectionEnabled(allowed);
      debugPrint(
        '══ ARIN ══ Meta App Events: ATT resynced '
        '(${allowed ? "authorized" : "denied/restricted"})',
      );
    } catch (e) {
      debugPrint('══ ARIN ══ Meta ATT resync failed (sessiz): $e');
    }
  }

  static Future<bool> _hasPendingAttPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pendingAttPromptKey) == true;
    } catch (e) {
      debugPrint('══ ARIN ══ ATT pending state read failed: $e');
      return false;
    }
  }

  static Future<void> _setAttPromptPending(bool pending) async {
    _retryAttPromptOnResume = pending;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (pending) {
        await prefs.setBool(_pendingAttPromptKey, true);
      } else {
        await prefs.remove(_pendingAttPromptKey);
      }
    } catch (e) {
      // Kalıcı kayıt başarısız olsa bile mevcut süreçteki güvenli retry
      // işaretini koru ve ATT akışını bloke etme.
      debugPrint('══ ARIN ══ ATT pending state persist failed: $e');
    }
  }

  static Future<bool> _isTrackingAuthorized() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      return status == TrackingStatus.authorized;
    } catch (e) {
      debugPrint('══ ARIN ══ ATT status read failed (sessiz): $e');
      return false;
    }
  }

  static Future<void> logAndroidSubscribe({
    required double price,
    required String currency,
    required String orderId,
  }) async {
    if (!_ready || !Platform.isAndroid) return;
    try {
      await _fb.logSubscribe(
        price: price,
        currency: currency,
        orderId: orderId,
      );
    } catch (e) {
      debugPrint('══ ARIN ══ Meta Android logSubscribe failed (sessiz): $e');
    }
  }

  /// Android Billing 8 satın almaları FBSDK 18 auto-IAP kapsamı dışında olduğu
  /// için yalnız Android manuel Purchase gönderir. iOS StoreKit eventleri
  /// native auto-log tarafından tek kaynak olarak yönetilir.
  static Future<void> logAndroidPurchase({
    required double amount,
    required String currency,
    required String orderId,
    required String productId,
  }) async {
    if (!_ready || !Platform.isAndroid) return;
    try {
      await _fb.logPurchase(
        amount: amount,
        currency: currency,
        parameters: {'fb_order_id': orderId, 'fb_content_id': productId},
      );
    } catch (e) {
      debugPrint('══ ARIN ══ Meta Android logPurchase failed (sessiz): $e');
    }
  }

  static Future<void> logCompletedRegistration({String? method}) async {
    if (!_ready) return;
    try {
      await _fb.logCompletedRegistration(registrationMethod: method);
    } catch (_) {}
  }
}
