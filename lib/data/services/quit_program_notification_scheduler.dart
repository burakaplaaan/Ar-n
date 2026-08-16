import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/willpower_templates.dart';
import '../../core/willpower/quit_notification_copy.dart';
import '../../core/willpower/quit_notification_plan.dart';
import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';
import '../willpower/willpower_content_loader.dart';
import 'app_local_notification_scheduler.dart';
import 'app_notification_channel_prefs.dart';

abstract final class QuitProgramNotificationScheduler {
  static final Map<String, QuitProgramHomeContent> _contentCache = {};

  static List<HabitModel> activeQuitProgramsWithClock() {
    try {
      return HabitRepository().getAll().where((h) {
        if (!WillpowerTemplates.isFullQuitProgram(h.templateId)) return false;
        final iso = h.quitClockStartedAtIso;
        if (iso == null || iso.isEmpty) return false;
        return DateTime.tryParse(iso) != null;
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<int> scheduleForActivePrograms({
    required SharedPreferences prefs,
    required String localeCode,
    required tz.TZDateTime now,
    required AndroidScheduleMode mode,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return 0;
    await cancelAll();
    if (!AppNotificationChannelPrefs.milestoneEnabled(prefs)) return 0;

    final programs = activeQuitProgramsWithClock();
    if (programs.isEmpty) return 0;

    final budget = Platform.isIOS
        ? QuitNotificationBudget.ios
        : QuitNotificationBudget.android;
    final planned = <QuitPlannedNotification>[];
    for (final habit in programs) {
      final start = DateTime.tryParse(habit.quitClockStartedAtIso!);
      if (start == null) continue;
      planned.addAll(
        buildQuitNotificationPlan(
          habitId: habit.id,
          templateId: habit.templateId,
          clockStartedAt: start,
          now: now,
          budget: budget,
        ),
      );
    }
    planned.sort((a, b) => a.fireAt.compareTo(b.fireAt));

    final maxSlots = Platform.isIOS
        ? AppLocalNotificationIds.iosQuitProgramSlotCount
        : AppLocalNotificationIds.quitProgramSlotCount;
    var queued = 0;
    for (var i = 0; i < planned.length && queued < maxSlots; i++) {
      final event = planned[i];
      if (!event.fireAt.isAfter(now)) continue;
      final content = await _contentFor(event.templateId, localeCode);
      final copy = resolveQuitNotificationCopy(
        event: event,
        localeCode: localeCode,
        wisdom: [
          for (final w in content?.wisdom ?? const <QuitWisdomItem>[])
            QuitNotificationWisdomSnippet(
              kind: w.kind,
              body: w.body,
              source: w.source,
            ),
        ],
        tips: [
          for (final t in content?.tips ?? const <QuitHomeTip>[])
            QuitNotificationTipSnippet(title: t.title, body: t.body),
        ],
      );
      final body = AppLocalNotificationScheduler.prepareAppNotificationBody(
        copy.body,
      );
      if (body == null) continue;
      final when = tz.TZDateTime.from(event.fireAt, tz.local);
      final ok = await AppLocalNotificationScheduler.scheduleAppNotification(
        id: AppLocalNotificationIds.quitProgramStart + queued,
        title: copy.title,
        body: body,
        when: when,
        details: AppLocalNotificationScheduler.appDetails(
          channelId: 'arin_ntf_app_milestone',
          channelName: 'Milestone',
          body: body,
        ),
        mode: mode,
        payload: event.payload,
      );
      if (ok) queued++;
    }
    debugPrint('QuitProgramNtf: scheduled $queued/${planned.length}');
    return queued;
  }

  static Future<void> cancelAll() async {
    for (var i = 0; i < AppLocalNotificationIds.quitProgramSlotCount; i++) {
      await AppLocalNotificationScheduler.cancelAppNotification(
        AppLocalNotificationIds.quitProgramStart + i,
      );
    }
  }

  static Future<QuitProgramHomeContent?> _contentFor(
    String templateId,
    String localeCode,
  ) async {
    final key = '$templateId|$localeCode';
    final cached = _contentCache[key];
    if (cached != null) return cached;
    try {
      final loaded = await QuitProgramHomeContent.loadForTemplate(
        templateId,
        localeCode: localeCode,
      );
      _contentCache[key] = loaded;
      return loaded;
    } catch (_) {
      return null;
    }
  }
}
