// Uygulama başlangıcında FCM izni alır ve `broadcast_all` topic'e kaydolur.
// Topic tabanlı mesajlaşma: Cloud Function bu topic'e push atınca tüm
// aboneler bildirimi alır — tek tek token yönetimi gerekmez.
//
// Moment Verse yönlendirmesi:
//   Bildirimde data['type'] == 'moment_verse' gelirse uygulama
//   /moment-verse ekranına yönlendirilir. Yönlendirme callback'i
//   setNavigationCallback() ile dışarıdan enjekte edilir; callback
//   henüz hazır değilse rota _pendingNavigationRoute'da saklanır
//   ve callback set edildiğinde otomatik tetiklenir.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/router/app_router.dart';

/// Uygulama arka planda iken gelen FCM mesajlarını işler.
/// Top-level fonksiyon olması zorunlu (Flutter embedding kuralı).
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // firebase_messaging arka plan handler'ı. Sistem zaten bildirimi gösteriyor;
  // burada yalnızca ek iş yapılacaksa (log, DB yazma vb.) eklenir.
  debugPrint('FCM arka plan mesajı: ${message.messageId}');
}

abstract final class FcmTokenService {
  static bool _initialized = false;

  /// GoRouter.go() referansı — ArinApp.initState() içinde set edilir.
  static void Function(String route)? _navigationCallback;

  /// Callback henüz set edilmemişse buraya park edilir.
  static String? _pendingNavigationRoute;

  /// ArinApp, router hazır olduğunda bu callback'i enjekte eder.
  /// Bekleyen rota varsa anında tetiklenir.
  static void setNavigationCallback(void Function(String route) callback) {
    _navigationCallback = callback;
    final pending = _pendingNavigationRoute;
    if (pending != null) {
      _pendingNavigationRoute = null;
      Future.microtask(() => callback(pending));
    }
  }

  /// Callback hazırsa hemen navigate eder; değilse rota park edilir.
  static void _navigate(String route) {
    final cb = _navigationCallback;
    if (cb != null) {
      cb(route);
    } else {
      _pendingNavigationRoute = route;
    }
  }

  /// Onboarding tamamlandıktan sonra bir kez çağrılır.
  static Future<void> initIfNeeded() async {
    if (_initialized) return;
    _initialized = true;
    try {
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      // ── Uygulama kapalıyken bildirime tıklanmış mı? ──────────────────
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null && initial.data['type'] == 'moment_verse') {
        _navigate(AppRoutes.momentVerse);
      }

      // ── Uygulama arka plandayken bildirime tıklanmış mı? ─────────────
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.data['type'] == 'moment_verse') {
          _navigate(AppRoutes.momentVerse);
        }
      });

      // iOS'ta uygulama ön plandayken bildirimleri sistem banner'ı olarak göster.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      debugPrint(
        '══ ARIN FCM ══ izin durumu: ${settings.authorizationStatus.name}',
      );

      // Tüm kullanıcıların aldığı yayın topic'i.
      await FirebaseMessaging.instance.subscribeToTopic('broadcast_all');
      debugPrint('══ ARIN FCM ══ broadcast_all topic\'ine kayıt tamam');

      // Uygulama açıkken gelen mesajlar (sistem bildirimi göstermez;
      // isteğe bağlı olarak Flutter tarafında snackbar/dialog gösterilebilir).
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '══ ARIN FCM ══ ön plan mesajı: ${message.notification?.title}',
        );
      });
    } catch (e) {
      // FCM başlatma başarısız olsa da uygulama çalışmaya devam etmeli.
      debugPrint('══ ARIN FCM ══ başlatma başarısız (sessiz): $e');
    }
  }
}
