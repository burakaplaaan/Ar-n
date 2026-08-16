import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../data/services/app_local_notification_scheduler.dart';
import '../../data/services/app_notification_channel_prefs.dart';
import '../../data/services/assistant_alarm_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/prayer_notification_scheduler.dart';
import '../../data/services/prayer_reminder_prefs.dart';
import '../shared/providers/habit_providers.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/quotes_providers.dart';
import '../qibla/qibla_hub_navigator_key.dart';
import '../qibla/qibla_hub_page.dart';
import '../willpower/salat_providers.dart';
import 'assistant_models.dart';

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

  void _openQiblaTool(String route) {
    context.go(AppRoutes.qibla);
    _pushQiblaToolWhenReady(route);
  }

  static void _pushQiblaToolWhenReady(String route, [int attempts = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = qiblaHubNavigatorKey.currentState;
      if (nav == null) {
        if (attempts < 25) {
          Future<void>.delayed(
            const Duration(milliseconds: 120),
            () => _pushQiblaToolWhenReady(route, attempts + 1),
          );
        }
        return;
      }
      nav.popUntil((r) => r.isFirst);
      nav.pushNamed(route);
    });
  }

  String? _openPage(String page) {
    final l10n = AppLocalizations.of(context)!;
    switch (page) {
      case 'home':
        context.go(AppRoutes.home);
      case 'qibla':
        context.go(AppRoutes.qibla);
      case 'zikir':
        _openQiblaTool(QiblaHubRoutes.zikir);
      case 'breathing':
        context.go(AppRoutes.willBreathing());
      case 'healing':
        _openQiblaTool(QiblaHubRoutes.healing);
      case 'prayer_circle':
        context.go(AppRoutes.prayerCircle);
      case 'hilal_duel':
        context.go(AppRoutes.hilalDuel);
      case 'habits':
        context.go(AppRoutes.habits);
      case 'namaz':
        final habit = ref
            .read(habitRepositoryProvider)
            .findActiveByTemplateId(WillpowerTemplates.salatDaily);
        if (habit != null) {
          context.go(AppRoutes.willNamaz(habit.id));
        } else {
          context.go(AppRoutes.habitsGelisimTab);
        }
      case 'kaza':
        context.go(AppRoutes.kazaTracker);
      case 'settings':
        context.go(AppRoutes.settings);
      case 'notifications':
        context.go(AppRoutes.settingsNotifications);
      case 'inspire':
        context.go(AppRoutes.inspire);
      case 'premium':
        context.push(AppRoutes.premium);
      default:
        return l10n.assistantActionUnknownPage;
    }
    return null;
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
      final onDark = !ArinShellBackground.isLight(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: onDark ? AppColors.homeCardSurface : AppColors.creamSurface,
          title: Text(
            l10n.assistantConfirmDisablePrayerTitle,
            style: TextStyle(
              color: onDark ? Colors.white : AppColors.emeraldDark,
            ),
          ),
          content: Text(
            l10n.assistantConfirmDisablePrayerBody,
            style: TextStyle(
              color: onDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.assistantCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.assistantConfirm),
            ),
          ],
        ),
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
