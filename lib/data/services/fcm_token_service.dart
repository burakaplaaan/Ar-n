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
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/router/app_router.dart';
import 'arin_local_notifications_plugin.dart';

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
      // Android 8.0+'da FCM bildirimleri channelId'si tanımlı bir kanala
      // ihtiyaç duyar; kanal yoksa bildirim sessizce düşer.
      await _ensureAndroidBroadcastChannel();

      // Foreground'da manuel olarak gösterdiğimiz local notification'a
      // (payload: "moment_verse") tıklanınca uygulama içi navigate edilsin.
      // Background/closed durumunda zaten FCM `onMessageOpenedApp` ve
      // `getInitialMessage` üzerinden yönlendirme yapılıyor.
      registerLocalNotificationTapHandler('moment_verse', (_) {
        _navigate(AppRoutes.momentVerse);
      });

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

      // Tüm kullanıcıların aldığı yayın topic'i. (Kaldırıldı: Explicit opt-in ile yapılacak)
      // await FirebaseMessaging.instance.subscribeToTopic('broadcast_all');
      
      // Uygulama ön plandayken Android sistem bildirimi otomatik göstermez;
      // manuel olarak `arin_ntf_broadcast` kanalına yerel bildirim atıyoruz.
      // iOS tarafı `setForegroundNotificationPresentationOptions` ile zaten
      // banner gösteriyor, burada Android'i hizalıyoruz.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final ntf = message.notification;
        debugPrint(
          '══ ARIN FCM ══ ön plan mesajı: ${ntf?.title} / data=${message.data}',
        );
        if (ntf == null) return;
        if (defaultTargetPlatform != TargetPlatform.android) return;
        try {
          await arinLocalNotificationsPlugin.show(
            DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
            ntf.title,
            ntf.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'arin_ntf_broadcast',
                'Ayet Bildirimleri',
                channelDescription: 'Günlük ayet ve anlık bildirimler',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
              ),
            ),
            payload: message.data['type']?.toString(),
          );
        } catch (e) {
          debugPrint('══ ARIN FCM ══ foreground show hatası: $e');
        }
      });
    } catch (e) {
      // FCM başlatma başarısız olsa da uygulama çalışmaya devam etmeli.
      debugPrint('══ ARIN FCM ══ başlatma başarısız (sessiz): $e');
    }
  }

  /// Android 8.0+'da FCM push'larının düşmemesi için `arin_ntf_broadcast`
  /// kanalını oluşturur. İdempotent: kanal zaten varsa Android sessizce geçer.
  static Future<void> _ensureAndroidBroadcastChannel() async {
    try {
      // Plugin initialize edilmemiş olabilir; burada güvenli şekilde başlat.
      await initializeArinLocalNotificationsPlugin();
      final android = arinLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'arin_ntf_broadcast',
          'Ayet Bildirimleri',
          description: 'Günlük ayet ve anlık bildirimler',
          importance: Importance.high,
          playSound: true,
        ),
      );
      debugPrint('══ ARIN FCM ══ arin_ntf_broadcast kanalı hazır');
    } on PlatformException catch (e) {
      debugPrint('══ ARIN FCM ══ broadcast kanalı oluşturulamadı: $e');
    }
  }

  /// Kullanıcı Anın Ayeti / Yayın bildirimlerini açıkça kabul ettiğinde çağrılır.
  static Future<bool> requestBroadcastPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await FirebaseMessaging.instance.subscribeToTopic('broadcast_all');
        debugPrint('══ ARIN FCM ══ broadcast_all topic\'ine kayıt tamam');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('══ ARIN FCM ══ permission request failed: $e');
      return false;
    }
  }

  /// Kullanıcı abonelikten çıkmak istediğinde veya veri silindiğinde çağrılır.
  static Future<void> unsubscribeFromBroadcasts() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('broadcast_all');
    } catch (e) {
      debugPrint('══ ARIN FCM ══ unsubscribeFromTopic failed: $e');
    }
  }
}
