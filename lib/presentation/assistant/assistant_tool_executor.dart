import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/willpower_templates.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../data/services/app_local_notification_scheduler.dart';
import '../../data/services/app_notification_channel_prefs.dart';
import '../../data/services/arin_widget_sync.dart';
import '../../data/services/assistant_alarm_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/prayer_notification_scheduler.dart';
import '../../data/services/prayer_reminder_prefs.dart';
import '../shared/widgets/arin_popup.dart';
import '../shared/providers/habit_providers.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/quotes_providers.dart';
import '../willpower/salat_providers.dart';
import '../qibla/qibla_hub_open.dart';
import '../qibla/qibla_hub_page.dart';
import 'assistant_models.dart';
import 'assistant_session.dart';

const _prayerIndex = {
  'fajr': 0,
  'dhuhr': 1,
  'asr': 2,
  'maghrib': 3,
  'isha': 4,
};

const _prayerSlotIndex = {
  'prayer_fajr': 0,
  'prayer_sunrise': 1,
  'prayer_dhuhr': 2,
  'prayer_asr': 3,
  'prayer_maghrib': 4,
  'prayer_isha': 5,
};

class AssistantToolExecutor {
  AssistantToolExecutor(this.ref, this.context);

  final WidgetRef ref;
  final BuildContext context;

  Future<String?> run(AssistantAction action) async {
    switch (action.name) {
      case 'open_page':
        return _openPage(action.args['page']?.toString() ?? '');
      case 'mark_prayer':
        return _markPrayer(action);
      case 'create_alarm':
        return _createAlarm(action);
      case 'set_notifications':
        return _setNotifications(action);
      default:
        return null;
    }
  }

  void _go(String location, {String? returnTool}) {
    if (returnTool != null) markAssistantReturnPending(ref, returnTool);
    final ctx = rootNavigatorKey.currentContext ?? context;
    ctx.go(location);
  }

  void _push(String location, {required String returnTool}) {
    markAssistantReturnPending(ref, returnTool);
    final ctx = rootNavigatorKey.currentContext ?? context;
    ctx.push(location);
  }

  Future<String?> _openPage(String page) async {
    final l10n = AppLocalizations.of(context)!;
    switch (page) {
      case 'home':
        _go(AppRoutes.home);
        return null;
      case 'qibla':
        _go(AppRoutes.qibla);
        return null;
      case 'zikir':
        _go(AppRoutes.qibla, returnTool: 'zikir');
        await pushQiblaHubRoute(QiblaHubRoutes.zikir);
        return null;
      case 'breathing':
        _push(AppRoutes.willBreathing(), returnTool: 'breathing');
        return null;
      case 'healing':
        _go(AppRoutes.qibla, returnTool: 'healing');
        await pushQiblaHubRoute(QiblaHubRoutes.healing);
        return null;
      case 'prayer_circle':
        _push(AppRoutes.prayerCircle, returnTool: 'prayer_circle');
        return null;
      case 'hilal_duel':
        _push(AppRoutes.hilalDuel, returnTool: 'hilal_duel');
        return null;
      case 'habits':
        _go(AppRoutes.habits);
        return null;
      case 'namaz':
        final habit = ref
            .read(habitRepositoryProvider)
            .findActiveByTemplateId(WillpowerTemplates.salatDaily);
        if (habit != null) {
          _push(AppRoutes.willNamaz(habit.id), returnTool: 'namaz');
        } else {
          _go(AppRoutes.habitsGelisimTab);
        }
        return null;
      case 'kaza':
        _push(AppRoutes.kazaTracker, returnTool: 'kaza');
        return null;
      case 'settings':
        _go(AppRoutes.settings);
        return null;
      case 'notifications':
        _push(AppRoutes.settingsNotifications, returnTool: 'notifications');
        return null;
      case 'widgets':
        _go(AppRoutes.settingsWidgets, returnTool: 'widgets');
        return null;
      case 'inspire':
        _go(AppRoutes.inspire);
        return null;
      case 'premium':
        _push(AppRoutes.premium, returnTool: 'premium');
        return null;
      default:
        return l10n.assistantActionUnknownPage;
    }
  }

  Future<String?> _markPrayer(AssistantAction action) async {
    final l10n = AppLocalizations.of(context)!;
    final prayer = action.args['prayer']?.toString() ?? '';
    final index = _prayerIndex[prayer];
    if (index == null) return l10n.assistantActionFailed;
    final habit = ref
        .read(habitRepositoryProvider)
        .findActiveByTemplateId(WillpowerTemplates.salatDaily);
    if (habit == null) return l10n.assistantSalatHabitMissing;
    final times = ref.read(prayerTimesProvider).asData?.value;
    final now = DateTime.now();
    final day = times?.salatTickCalendarDay(now) ?? DateTime(now.year, now.month, now.day);
    final done = action.args['done'] != false;
    await ref.read(salatLogRepositoryProvider).setPrayer(
      habit.id,
      day,
      index,
      done,
      ref.read(habitRepositoryProvider),
    );
    ref.read(habitSummaryProvider.notifier).refresh();
    unawaited(ArinWidgetSync.refreshPrayerTodayMarks());
    return done ? l10n.assistantPrayerMarked : l10n.assistantPrayerUnmarked;
  }

  Future<String?> _createAlarm(AssistantAction action) async {
    final l10n = AppLocalizations.of(context)!;
    final hour = (action.args['hour'] as num?)?.toInt();
    final minute = (action.args['minute'] as num?)?.toInt();
    if (hour == null || minute == null) return l10n.assistantActionFailed;
    final title = (action.args['title']?.toString().trim().isNotEmpty == true)
        ? action.args['title'].toString().trim()
        : l10n.assistantAlarmDefaultTitle;
    final ok = await AssistantAlarmService.scheduleOnce(
      prefs: ref.read(sharedPreferencesProvider),
      hour: hour,
      minute: minute,
      title: title,
      body: l10n.assistantAlarmBody,
    );
    if (!ok) return l10n.assistantAlarmPermissionDenied;
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return l10n.assistantAlarmSet('$hh:$mm');
  }

  Future<String?> _setNotifications(AssistantAction action) async {
    final l10n = AppLocalizations.of(context)!;
    final channel = action.args['channel']?.toString() ?? '';
    final enabled = action.args['enabled'] == true;
    final prefs = ref.read(sharedPreferencesProvider);

    if (channel == 'prayer' && !enabled) {
      final confirmed = await showArinConfirm(
        context: context,
        title: l10n.assistantConfirmDisablePrayerTitle,
        message: l10n.assistantConfirmDisablePrayerBody,
        cancelLabel: l10n.assistantCancel,
        confirmLabel: l10n.assistantConfirm,
        tone: ArinPopupTone.warning,
        icon: Icons.notifications_off_outlined,
      );
      if (confirmed != true) return l10n.assistantActionCancelled;
    }

    if (channel == 'prayer' || _prayerSlotIndex.containsKey(channel)) {
      if (channel == 'prayer') {
        await PrayerReminderPrefs.setEnabled(prefs, enabled);
        if (!enabled) {
          await PrayerNotificationScheduler.cancelAllPrayerNotifications();
        }
      } else {
        final slot = _prayerSlotIndex[channel]!;
        final current = PrayerReminderPrefs.minutesBeforeForPrayer(prefs, slot);
        final minutes = enabled
            ? (current >= 0 ? current : 5)
            : -1;
        await PrayerReminderPrefs.setMinutesBeforeForPrayer(prefs, slot, minutes);
        if (!PrayerReminderPrefs.isEnabled(prefs) && enabled) {
          await PrayerReminderPrefs.setEnabled(prefs, true);
        }
      }
      if (enabled || channel != 'prayer') {
        await PrayerNotificationScheduler.ensurePrayerNotificationsIfEnabled(
          prefs: prefs,
          aladhan: ref.read(aladhanServiceProvider),
          location: ref.read(locationServiceProvider),
          force: true,
        );
      }
      return enabled
          ? l10n.assistantNotificationsOn
          : l10n.assistantNotificationsOff;
    }

    switch (channel) {
      case 'arinma':
        await AppNotificationChannelPrefs.setArinmaDailyEnabled(prefs, enabled);
      case 'milestone':
        await AppNotificationChannelPrefs.setMilestoneEnabled(prefs, enabled);
      case 'task':
        await AppNotificationChannelPrefs.setTaskReminderEnabled(prefs, enabled);
      case 'zikir':
        await AppNotificationChannelPrefs.setZikirQuoteEnabled(prefs, enabled);
      default:
        return l10n.assistantActionFailed;
    }
    await AppLocalNotificationScheduler.rescheduleAll(
      prefs,
      pools: ref.read(quotePoolsRepositoryProvider),
      prayerTimes: ref.read(prayerTimesProvider).asData?.value,
      force: true,
    );
    return enabled
        ? l10n.assistantNotificationsOn
        : l10n.assistantNotificationsOff;
  }
}
