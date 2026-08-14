import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'android_local_notification_schedule.dart';

/// [full]: zamanlanmış namaz/uygulama bildirimleri için bildirim + tam zamanlı alarm.
/// [notificationOnly]: anında `show()` testi — yalnızca bildirim izni (exact alarm şart değil).
enum LocalNotificationPermissionPolicy {
  full,
  notificationOnly,
}

/// Bildirim merkezi UI’sinin ve scheduler’ların tükettiği tek kaynak.
///
/// Manuel `show()` çalışıp zamanlanmış alarm çalışmadığında fark genelde
/// [exactAlarmsAllowed] veya [batteryOptimizationsIgnored] olur — ikisi de
/// `Permission.notification` tarafından kapsanmaz.
@immutable
class NotificationPermissionSnapshot {
  const NotificationPermissionSnapshot({
    required this.notifications,
    required this.exactAlarmsAllowed,
    required this.batteryOptimizationsIgnored,
  });

  final PermissionStatus notifications;

  /// Android 12+ `SCHEDULE_EXACT_ALARM` veya `USE_EXACT_ALARM` gerçekten tetiklenebilir mi.
  /// iOS/Web’de her zaman `true` sayılır (plugin native tarafta halleder).
  final bool exactAlarmsAllowed;

  /// `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` muafiyet kararı. Android dışı = `true`.
  final bool batteryOptimizationsIgnored;

  bool get notificationsAllowed =>
      notifications == PermissionStatus.granted ||
      notifications == PermissionStatus.limited ||
      notifications == PermissionStatus.provisional;

  /// Zamanlanmış bildirim gerçekten güvenilir biçimde çalar mı?
  bool get fullySchedulable =>
      notificationsAllowed &&
      exactAlarmsAllowed &&
      batteryOptimizationsIgnored;
}

/// Android: önce mevcut durumu oku; sistem kutusunu yalnız bir API ile bir kez aç.
Future<bool> _androidNotificationsAllowed(
  AndroidFlutterLocalNotificationsPlugin? android,
) async {
  var st = await Permission.notification.status;
  if (st.isGranted || st.isLimited || st.isProvisional) return true;
  if (st.isPermanentlyDenied) return false;

  st = await Permission.notification.request();
  if (st.isGranted || st.isLimited || st.isProvisional) return true;
  if (st.isPermanentlyDenied || st.isDenied) return false;

  final fromPlugin = await android?.requestNotificationsPermission();
  return fromPlugin == true;
}

/// Namaz ve uygulama yerel bildirimleri için ortak çalışma zamanı izinleri.
Future<bool> requestLocalNotificationRuntimePermissions(
  FlutterLocalNotificationsPlugin plugin, {
  LocalNotificationPermissionPolicy policy =
      LocalNotificationPermissionPolicy.full,
}) async {
  if (kIsWeb) return false;
  if (Platform.isAndroid) {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (!await _androidNotificationsAllowed(android)) {
      return false;
    }
    if (policy == LocalNotificationPermissionPolicy.notificationOnly) {
      return true;
    }
    final exactStatus = await Permission.scheduleExactAlarm.status;
    if (!exactStatus.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }
    return true;
  }
  if (Platform.isIOS) {
    final ios = plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final ok = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return ok ?? false;
  }
  return false;
}

/// Doze / OEM güç yöneticileri alarmları düşürmesin diye battery-whitelist dialog’unu açar.
/// Kullanıcı reddederse hiçbir şey bozulmaz — scheduler yalnız değerini loglamada
/// kullanır. Android dışı no-op.
Future<bool> requestIgnoreBatteryOptimizations() async {
  if (kIsWeb || !Platform.isAndroid) return true;
  final already = await Permission.ignoreBatteryOptimizations.status;
  if (already.isGranted) return true;
  final res = await Permission.ignoreBatteryOptimizations.request();
  return res.isGranted;
}

/// UI için: çalışma zamanı izinlerini yüklemez, yalnız mevcut durumu okur.
Future<NotificationPermissionSnapshot> readNotificationPermissionSnapshot(
  FlutterLocalNotificationsPlugin plugin,
) async {
  if (kIsWeb) {
    return const NotificationPermissionSnapshot(
      notifications: PermissionStatus.denied,
      exactAlarmsAllowed: false,
      batteryOptimizationsIgnored: false,
    );
  }
  final ntf = await Permission.notification.status;
  var exact = true;
  var battery = true;
  if (Platform.isAndroid) {
    exact = await canScheduleExactLocalNotifications(plugin);
    final ignoring = await Permission.ignoreBatteryOptimizations.status;
    battery = ignoring.isGranted;
  }
  return NotificationPermissionSnapshot(
    notifications: ntf,
    exactAlarmsAllowed: exact,
    batteryOptimizationsIgnored: battery,
  );
}
