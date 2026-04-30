// Tamamlanmış hafta için bir kez gösterilen kutlama diyaloğu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/willpower_templates.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/salat_log_repository.dart';
import '../../data/willpower/namaz_weekly_quotes.dart';
import '../shared/providers/habit_providers.dart';
import 'salat_providers.dart';

abstract final class SalatCelebration {
  static const _prefsPrefix = 'salat_week_celebrated_';

  static Future<void> tryShowForPreviousWeek({
    required BuildContext context,
    required WidgetRef ref,
    required HabitModel habit,
  }) async {
    if (habit.templateId != WillpowerTemplates.salatDaily) return;

    final salat = ref.read(salatLogRepositoryProvider);
    final now = DateTime.now();
    final thisMonday = SalatLogRepository.mondayOf(now);
    final prevMonday = thisMonday.subtract(const Duration(days: 7));

    final habitStart = DateTime.tryParse(habit.startedAtIso) ?? now;
    if (!salat.isPerfectWeekForHabit(habit.id, prevMonday, habitStart)) {
      return;
    }

    final weekKey = SalatLogRepository.weekMondayKey(prevMonday);
    final prefs = await SharedPreferences.getInstance();
    final mark = prefs.getString('$_prefsPrefix${habit.id}_$weekKey');
    if (mark == '1') return;

    if (!context.mounted) return;

    final ordinal =
        prevMonday.millisecondsSinceEpoch ~/ (86400000 * 7);
    final text = NamazWeeklyQuotes.forIndex(ordinal);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A221C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            l10n.salatWeekCelebrationTitle,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.creamBase,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkMuted,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentNeonGreen,
              foregroundColor: const Color(0xFF031A0C),
            ),
            child: Text(l10n.salatWeekCelebrationAction),
          ),
        ],
        );
      },
    ).then((_) async {
      await prefs.setString('$_prefsPrefix${habit.id}_$weekKey', '1');
    });

    ref.read(habitSummaryProvider.notifier).refresh();
  }
}
