// lib/data/services/arin_local_notifications_plugin.dart
// Tek [FlutterLocalNotificationsPlugin] — iki ayrı örnek + iki kez [initialize]
// zamanlanmış bildirimlerin cihazda sessizce kaybolmasına yol açabiliyor.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

bool _arinLocalNotificationsPluginInitialized = false;

/// Uygulama genelinde paylaşılan plugin; namaz + uygulama içi hatırlatıcılar aynı native
/// kanalı kullanır.
final FlutterLocalNotificationsPlugin arinLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Yerel bildirim tıklamalarında payload'a göre dispatch edilen handler'lar.
/// Servisler `registerLocalNotificationTapHandler` ile kendi payload'larını
/// dinler (ör. FCM foreground notification için `moment_verse`).
final Map<String, void Function(String payload)> _localTapHandlers = {};

/// [payload] eşleşirse [handler] çağrılır. Aynı anahtar üzerine yazılır.
void registerLocalNotificationTapHandler(
  String payload,
  void Function(String payload) handler,
) {
  _localTapHandlers[payload] = handler;
}

void _dispatchLocalNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  final handler =
      _localTapHandlers[payload] ?? _localTapHandlers[payload.split('|').first];
  if (handler == null) {
    debugPrint(
      '══ ARIN LocalNtf ══ payload="$payload" için handler yok; atlanıyor',
    );
    return;
  }
  handler(payload);
}

/// Uygulama tamamen kapalıyken yerel bildirime dokunularak açıldıysa payload'ı
/// bir kez normal handler tablosuna yollar.
Future<void> dispatchInitialLocalNotificationTap() async {
  final details = await arinLocalNotificationsPlugin
      .getNotificationAppLaunchDetails();
  if (details?.didNotificationLaunchApp != true) return;
  final response = details?.notificationResponse;
  if (response != null) _dispatchLocalNotificationTap(response);
}

/// İdempotent: birden fazla çağrıda yalnızca bir kez [initialize] edilir.
Future<void> initializeArinLocalNotificationsPlugin() async {
  if (_arinLocalNotificationsPluginInitialized) return;
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await arinLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
    onDidReceiveNotificationResponse: _dispatchLocalNotificationTap,
  );
  _arinLocalNotificationsPluginInitialized = true;
}
