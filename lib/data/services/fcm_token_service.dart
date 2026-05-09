// Uygulama başlangıcında FCM izni alır ve `broadcast_all` topic'e kaydolur.
// Topic tabanlı mesajlaşma: Cloud Function bu topic'e push atınca tüm
// aboneler bildirimi alır — tek tek token yönetimi gerekmez.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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

  /// Onboarding tamamlandıktan sonra bir kez çağrılır.
  static Future<void> initIfNeeded() async {
    if (_initialized) return;
    _initialized = true;
    try {
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

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
