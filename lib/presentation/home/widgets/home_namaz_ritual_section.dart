// Ana sayfa — namaz takip özeti + hatırlatıcı (Gelişim namaz paneli ile aynı veri).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/willpower_templates.dart';
import '../../../core/router/app_router.dart';
import '../../shared/providers/habit_providers.dart';
import '../../shared/providers/prayer_time_providers.dart';
import '../../willpower/salat_tracking_visibility_provider.dart';
import '../../willpower/salat_providers.dart';
import '../../willpower/widgets/namaz_adhan_reminder_card.dart';
import '../../willpower/widgets/salat_prayer_row.dart';

final _homeSalatSetupBusyProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class HomeNamazRitualSection extends ConsumerWidget {
  const HomeNamazRitualSection({super.key});

  Future<void> _openOrCreateSalatSetup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final busy = ref.read(_homeSalatSetupBusyProvider);
    if (busy) return;
    ref.read(_homeSalatSetupBusyProvider.notifier).state = true;
    try {
      final repo = ref.read(habitRepositoryProvider);
      await repo.ensureDefaultSalatHabit();
      await ref
          .read(salatTrackingVisibleOnHomeProvider.notifier)
          .enableFromGelisim();
      ref.read(habitSummaryProvider.notifier).refresh();
      final habit = repo.findActiveByTemplateId(WillpowerTemplates.salatDaily);
      if (!context.mounted) return;
      if (habit != null) {
        context.push(AppRoutes.willNamaz(habit.id, fromGelisimSetup: true));
        return;
      }
      context.go(AppRoutes.habitsGelisimTab);
    } finally {
      ref.read(_homeSalatSetupBusyProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final onLight = Theme.of(context).brightness == Brightness.light;
    final summary = ref.watch(habitSummaryProvider);
    final visibleOnHome = ref.watch(salatTrackingVisibleOnHomeProvider);
    final setupBusy = ref.watch(_homeSalatSetupBusyProvider);
    String? salatId;
    for (final e in summary) {
      if (e.habit.templateId == WillpowerTemplates.salatDaily &&
          !e.habit.isArchived) {
        salatId = e.habit.id;
        break;
      }
    }

    if (!visibleOnHome || salatId == null) {
      return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: setupBusy
                  ? null
                  : () => _openOrCreateSalatSetup(context, ref),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      onLight
                          ? Colors.white.withValues(alpha: 0.93)
                          : AppColors.homeCardSurface.withValues(alpha: 0.75),
                      onLight
                          ? AppColors.creamSurface.withValues(alpha: 0.96)
                          : const Color(0xFF0F1612).withValues(alpha: 0.85),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGlowGreen.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentNeonGreen.withValues(
                          alpha: 0.14,
                        ),
                        border: Border.all(
                          color: AppColors.accentNeonGreen.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.mosque_outlined,
                        color: AppColors.accentNeonGreen.withValues(
                          alpha: 0.95,
                        ),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homeNamazSetupTitle,
                            style: TextStyle(
                              color: onLight
                                  ? AppColors.emeraldDark
                                  : Colors.white.withValues(alpha: 0.95),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.homeNamazSetupSubtitle,
                            style: TextStyle(
                              color: onLight
                                  ? AppColors.textSecondary
                                  : Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: onLight
                          ? AppColors.textSecondary.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ),
          )
          .animate()
          .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
          .slideY(begin: 0.04, duration: 450.ms, curve: Curves.easeOutCubic);
    }

    final salat = ref.read(salatLogRepositoryProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prayerAsync = ref.watch(prayerTimesProvider);
    final storageDay = prayerAsync.maybeWhen(
      data: (pt) => pt.salatTickCalendarDay(now),
      orElse: () => today,
    );
    final done = salat.countDone(salatId, storageDay);

    return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: onLight
                ? Colors.white.withValues(alpha: 0.92)
                : AppColors.homeCardSurface.withValues(alpha: 0.72),
            border: Border.all(
              color: AppColors.accentNeonGreen.withValues(alpha: 0.32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlowGreen.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(AppRoutes.willNamaz(salatId!)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.homeNamazTrackingTitle,
                                    style: TextStyle(
                                      color: onLight
                                          ? AppColors.emeraldDark
                                          : Colors.white.withValues(
                                              alpha: 0.92,
                                            ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    l10n.homeNamazTrackingProgressLine(done),
                                    style: TextStyle(
                                      color: onLight
                                          ? AppColors.textSecondary
                                          : Colors.white.withValues(
                                              alpha: 0.38,
                                            ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: onLight
                                  ? AppColors.textSecondary.withValues(
                                      alpha: 0.7,
                                    )
                                  : Colors.white.withValues(alpha: 0.35),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SalatPrayerRow(habitId: salatId, compact: true),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: onLight
                        ? AppColors.creamSurface.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.22),
                    border: Border.all(
                      color: onLight
                          ? AppColors.creamDark.withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: const NamazAdhanReminderCard(compact: true),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.03, duration: 420.ms, curve: Curves.easeOutCubic);
  }
}
