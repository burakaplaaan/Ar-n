// Özel alışkanlık — günlük / haftalık / aylık sayaç (Gelişim yeşil, Arınma kırmızı).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'package:arin/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../data/models/habit_model.dart';
import '../../data/services/habit_cloud_sync_service.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/providers/habit_providers.dart';

const Color _kArinmaAccent = Color(0xFFFF5252);

class CustomHabitDetailPage extends ConsumerStatefulWidget {
  const CustomHabitDetailPage({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<CustomHabitDetailPage> createState() =>
      _CustomHabitDetailPageState();
}

class _CustomHabitDetailPageState extends ConsumerState<CustomHabitDetailPage> {
  Color _accent(HabitModel h) =>
      h.type == HabitType.bad ? _kArinmaAccent : AppColors.accentNeonGreen;

  String _periodHint(BuildContext context, HabitModel h) {
    switch (h.customRepeatCycle.clamp(0, 2)) {
      case 1:
        return AppLocalizations.of(context)!.customHabitThisWeekGoal;
      case 2:
        return AppLocalizations.of(context)!.customHabitThisMonthGoal;
      default:
        return AppLocalizations.of(context)!.customHabitDailyGoal;
    }
  }

  String _motivation(BuildContext context, int current, int target, HabitModel h) {
    if (current >= target) {
      switch (h.customRepeatCycle.clamp(0, 2)) {
        case 1:
          return AppLocalizations.of(context)!.customHabitThisWeekGoalComplete;
        case 2:
          return AppLocalizations.of(context)!.customHabitThisMonthGoalComplete;
        default:
          return AppLocalizations.of(context)!.customHabitTodayGoalComplete;
      }
    }
    if (current <= 0) return AppLocalizations.of(context)!.customHabitLetsStart;
    final r = target > 0 ? current / target : 0.0;
    if (r < 0.35) return AppLocalizations.of(context)!.customHabitDoingWell;
    if (r < 0.7) return AppLocalizations.of(context)!.customHabitAlmostThere;
    return AppLocalizations.of(context)!.customHabitOneLastStep;
  }

  Future<void> _confirmArchive(BuildContext context, String habitId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.anthraciteMid,
        title: Text(
          AppLocalizations.of(context)!.habitsDeleteConfirmTitle,
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.creamBase),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.of(context)!.habitsCancel,
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              AppLocalizations.of(context)!.habitsYesDelete,
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await HabitCloudSyncService.rememberDeletedHabitId(habitId: habitId);
      await ref
          .read(habitSummaryProvider.notifier)
          .deleteHabitPermanently(habitId);
      final uid = ref.read(authUserProvider).asData?.value?.uid;
      if (uid != null && uid.isNotEmpty) {
        await HabitCloudSyncService.deleteHabitCloudData(
          uid: uid,
          habitId: habitId,
        );
      }
      if (context.mounted) popOrGoWillpowerHub(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(habitRepositoryProvider);
    final habit = repo.getById(widget.habitId);
    if (habit == null || !habit.isCustomTracked) {
      return Scaffold(
        backgroundColor: AppColors.anthraciteDark,
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.customHabitRecordNotFound,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.creamBase),
          ),
        ),
      );
    }

    final accent = _accent(habit);
    final summary = ref.watch(habitSummaryProvider);
    var streak = 0;
    var completedToday = false;
    for (final e in summary) {
      if (e.habit.id == habit.id) {
        streak = e.streak;
        completedToday = e.completedToday;
        break;
      }
    }
    final progress = repo.todayProgressValue(habit.id);
    final target = habit.effectiveDailyTarget;
    final frac = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    final unit = habit.customUnit;
    final isPercent = habit.customTrackingKind == 2;
    final streakLabel =
        habit.customRepeatCycle != 0
            ? AppLocalizations.of(context)!.customHabitStreak
            : AppLocalizations.of(context)!.customHabitDayStreak;

    return Scaffold(
      backgroundColor: AppColors.anthraciteDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: AppLocalizations.of(context)!.customHabitBack,
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.creamBase),
          onPressed: () => popOrGoWillpowerHub(context),
        ),
        title: Text(
          habit.title,
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.creamBase),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.customHabitRemove,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.creamBase.withValues(alpha: 0.42),
            ),
            onPressed: () => _confirmArchive(context, habit.id),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.customHabitBackToTracker,
            icon: const Icon(Icons.close_rounded, color: AppColors.creamBase),
            onPressed: () => popOrGoWillpowerHub(context),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            habit.type == HabitType.good
                ? AppLocalizations.of(context)!.habitsGrowth
                : AppLocalizations.of(context)!.habitsPurification,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xFF121814).withValues(alpha: 0.9),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: frac,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          color: accent,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$progress',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.creamBase,
                              fontWeight: FontWeight.w800,
                              fontSize: 40,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isPercent ? '/ $target%' : '/ $target $unit',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textOnDarkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _periodHint(context, habit),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textOnDarkMuted.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _motivation(context, progress, target, habit),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDarkMuted,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundAct(
                      icon: Icons.remove_rounded,
                      color: Colors.white.withValues(alpha: 0.35),
                      onTap: progress <= 0
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(habitSummaryProvider.notifier)
                                  .addProgressToday(habit.id, -1);
                            },
                    ),
                    const SizedBox(width: 28),
                    _RoundAct(
                      icon: Icons.add_rounded,
                      color: accent,
                      filled: true,
                      onTap: progress >= target
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(habitSummaryProvider.notifier)
                                  .addProgressToday(habit.id, 1);
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_outlined,
                  label: streakLabel,
                  value: '$streak',
                  borderColor: const Color(0xFFFFB74D).withValues(alpha: 0.55),
                  iconColor: const Color(0xFFFFB74D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.track_changes_rounded,
                  label: AppLocalizations.of(context)!.customHabitGoal,
                  value: '$target',
                  borderColor: accent.withValues(alpha: 0.45),
                  iconColor: accent,
                ),
              ),
            ],
          ),
          if (completedToday) ...[
            const SizedBox(height: 12),
            Text(
              habit.customRepeatCycle == 0
                  ? AppLocalizations.of(context)!.customHabitCompletedToday
                  : AppLocalizations.of(context)!.customHabitCompletedPeriod,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: accent.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                popOrGoWillpowerHub(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.75), width: 1.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.customHabitFinish,
                style: AppTextStyles.labelLarge.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAct extends StatelessWidget {
  const _RoundAct({
    required this.icon,
    required this.color,
    this.filled = false,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            icon,
            color: onTap == null
                ? color.withValues(alpha: 0.35)
                : (filled ? color : AppColors.creamBase),
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.borderColor,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF121814).withValues(alpha: 0.75),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.creamBase,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
