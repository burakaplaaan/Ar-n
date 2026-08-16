import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'android_local_notification_schedule.dart';
import 'arin_local_notifications_plugin.dart';
import 'local_notification_permission_gate.dart';
import 'tz_local_bootstrap.dart';

/// Asistanın kurduğu tek seferlik hatırlatıcılar — 5100xxx bandı.
abstract final class AssistantAlarmService {
  static const int _idBase = 5100000;
  static const int _slotCount = 8;
  static const _kCursor = 'assistant_alarm_cursor_v1';

  static Future<bool> scheduleOnce({
    required SharedPreferences prefs,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return false;
    await configureArinLocalTimeZone();
    await initializeArinLocalNotificationsPlugin();
    final permitted = await requestLocalNotificationRuntimePermissions(
      arinLocalNotificationsPlugin,
    );
    if (!permitted) return false;

    final cursor = (prefs.getInt(_kCursor) ?? 0) % _slotCount;
    final id = _idBase + cursor;

    var when = tz.TZDateTime(
      tz.local,
      tz.TZDateTime.now(tz.local).year,
      tz.TZDateTime.now(tz.local).month,
      tz.TZDateTime.now(tz.local).day,
      hour,
      minute,
    );
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) {
      when = when.add(const Duration(days: 1));
    }

    try {
      await arinLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('AssistantAlarm: cancel($id) $e');
    }

    const android = AndroidNotificationDetails(
      'arin_assistant_alarm',
      'Arın Asistanı',
      channelDescription: 'Asistanın kurduğu tek seferlik hatırlatıcılar',
      importance: Importance.max,
      priority: Priority.max,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    final mode = await androidScheduleModePreferAlarmClock(
      arinLocalNotificationsPlugin,
    );
    try {
      await arinLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        when,
        const NotificationDetails(android: android, iOS: ios),
        androidScheduleMode: mode,
      );
      await prefs.setInt(_kCursor, cursor + 1);
      return true;
    } catch (e) {
      debugPrint('AssistantAlarm: schedule failed $e');
      try {
        await arinLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          when,
          const NotificationDetails(android: android, iOS: ios),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        await prefs.setInt(_kCursor, cursor + 1);
        return true;
      } catch (e2) {
        debugPrint('AssistantAlarm: fallback failed $e2');
        return false;
      }
    }
  }
}
