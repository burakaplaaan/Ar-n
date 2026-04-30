// Android: bildirim kanalı / NotificationDetails sesi için content:// URI.
// file:// uygulama dizini sistem tarafından çalınmıyor → kısa "bzz" / varsayılan ses.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class PrayerNotificationAndroidUri {
  static const MethodChannel _ch = MethodChannel(
    'com.arin.arin/notification_sound_uri',
  );

  /// Sistem bildirim zil sesi (`RingtoneManager.TYPE_NOTIFICATION`).
  /// [soundIndex] 0 iken planlı bildirimde ham `raw` yok; OEM’lerde sessiz kalmaması için kullanılır.
  static Future<String?> defaultNotificationSoundUri() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final u = await _ch.invokeMethod<String>('defaultNotificationSoundUri');
      if (u != null && u.isNotEmpty) return u;
    } catch (e, st) {
      debugPrint(
        'PrayerNotificationAndroidUri.defaultNotificationSoundUri: $e\n$st',
      );
    }
    return null;
  }

  static Future<bool> playDefaultNotificationSound() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _ch.invokeMethod<bool>('playDefaultNotificationSound') ??
          false;
    } catch (e, st) {
      debugPrint(
        'PrayerNotificationAndroidUri.playDefaultNotificationSound: $e\n$st',
      );
    }
    return false;
  }

  /// Kullanıcının aramalar için atadığı zil sesi (`RingtoneManager.TYPE_RINGTONE`).
  /// Ses ayarı önizlemesinde kullanıcı, telefonu çaldığında duyduğu müziği
  /// bildirim shade'ine hiçbir satır düşmeden `audioplayers` üzerinden dinler.
  static Future<String?> defaultRingtoneUri() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final u = await _ch.invokeMethod<String>('defaultRingtoneUri');
      if (u != null && u.isNotEmpty) return u;
    } catch (e, st) {
      debugPrint('PrayerNotificationAndroidUri.defaultRingtoneUri: $e\n$st');
    }
    return null;
  }

  /// [absolutePath] altında dosya varsa FileProvider ile content:// döner.
  static Future<String?> contentUriForNotificationSound(
    String absolutePath,
  ) async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final u = await _ch.invokeMethod<String>(
        'contentUriForFile',
        absolutePath,
      );
      if (u != null && u.isNotEmpty) return u;
    } catch (e, st) {
      debugPrint('PrayerNotificationAndroidUri: $e\n$st');
    }
    return null;
  }
}
