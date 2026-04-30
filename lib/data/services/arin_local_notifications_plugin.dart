// lib/data/services/arin_local_notifications_plugin.dart
// Tek [FlutterLocalNotificationsPlugin] — iki ayrı örnek + iki kez [initialize]
// zamanlanmış bildirimlerin cihazda sessizce kaybolmasına yol açabiliyor.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

bool _arinLocalNotificationsPluginInitialized = false;

/// Uygulama genelinde paylaşılan plugin; namaz + uygulama içi hatırlatıcılar aynı native
/// kanalı kullanır.
final FlutterLocalNotificationsPlugin arinLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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
    const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    ),
  );
  _arinLocalNotificationsPluginInitialized = true;
}
