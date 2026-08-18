// Özellik kullanımı sırasında izin: kurulumda verilmişse tekrar sorma;
// verilmemişse sistem kutusu veya Ayarlar'a yönlendir.

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'arin_local_notifications_plugin.dart';
import 'fcm_token_service.dart';
import 'local_notification_permission_gate.dart';
import 'location_service.dart';

Future<bool> notificationsAlreadyAllowed() async {
  final snap = await readNotificationPermissionSnapshot(
    arinLocalNotificationsPlugin,
  );
  return snap.notificationsAllowed;
}

/// Ayet / hatırlatma açılırken: izin açıksa true, değilse iste veya Ayarlar.
Future<bool> ensureNotificationPermissionForFeature() async {
  if (await notificationsAlreadyAllowed()) return true;

  final status = await Permission.notification.status;
  if (status.isPermanentlyDenied || status.isRestricted) {
    await openAppSettings();
    return false;
  }

  final ok = await requestLocalNotificationRuntimePermissions(
    arinLocalNotificationsPlugin,
    policy: LocalNotificationPermissionPolicy.notificationOnly,
  );
  await FcmTokenService.markBroadcastPermissionPromptHandled();
  if (ok) {
    await FcmTokenService.resumeBroadcastSubscriptionIfAuthorized();
    return true;
  }
  await openAppSettings();
  return false;
}

bool locationPermissionGranted(LocationPermission permission) {
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}

/// Namaz vakitleri açılırken: izin açıksa tekrar sorma; değilse iste veya Ayarlar.
Future<bool> ensureLocationPermissionForFeature(LocationService location) async {
  final current = await Geolocator.checkPermission();
  if (locationPermissionGranted(current)) {
    if (location.savedLat == null || location.savedLon == null) {
      await location.requestCurrentPosition(showDisclosure: false);
    }
    return true;
  }
  if (current == LocationPermission.deniedForever) {
    await openAppSettings();
    return false;
  }

  final pos = await location.requestCurrentPosition(showDisclosure: false);
  if (pos != null) return true;

  final after = await Geolocator.checkPermission();
  if (after == LocationPermission.deniedForever) {
    await openAppSettings();
  }
  return false;
}
