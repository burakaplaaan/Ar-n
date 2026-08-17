// Günlük namaz programı — alıntı, beş vakit, hatırlatıcı yönlendirmesi, son günler şeridi.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/router/app_router.dart';
import '../../data/models/habit_model.dart';
import '../shared/providers/habit_providers.dart';
import 'namaz_ibadet_onboarding.dart';
import 'salat_celebration.dart';
import 'salat_tracking_visibility_provider.dart';
import 'salat_providers.dart';
import 'widgets/namaz_adhan_reminder_card.dart';
import 'widgets/namaz_insight_card.dart';
import 'widgets/salat_prayer_row.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';

class NamazProgramPage extends ConsumerStatefulWidget {
  const NamazProgramPage({
    super.key,
    required this.habitId,
    this.showHomeVisibilityHint = false,
    this.returnOrigin = 'habits',
  });

  final String habitId;
  final bool showHomeVisibilityHint;
  final String returnOrigin;

  @override
  ConsumerState<NamazProgramPage> createState() => _NamazProgramPageState();
}

class _NamazProgramPageState extends ConsumerState<NamazProgramPage> {
  bool _didShowHomeVisibilityHint = false;
  bool _routeTransitioning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(habitSummaryProvider.notifier).refresh();
      if (mounted) await _celebrateIfNeeded();
    });
  }

  void _showHomeVisibilityHintIfNeeded() {
    if (!mounted) return;
    if (!widget.showHomeVisibilityHint) return;
    if (_didShowHomeVisibilityHint) return;
    _didShowHomeVisibilityHint = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showArinTopToast(context, AppLocalizations.of(context)!.namazProgramHomeHintActive);
    });
  }

  bool _needsIbadetOnboarding(HabitModel h) {
    return h.templateId == WillpowerTemplates.salatDaily &&
        (!h.onboardingCompleted || h.commitmentText.trim().isEmpty);
  }

  void _goToOrigin({bool force = false}) {
    if (!mounted) return;
    if (_routeTransitioning && !force) return;
    _routeTransitioning = true;
    if (widget.returnOrigin == 'home') {
      context.go(AppRoutes.home);
      return;
    }
    context.go(AppRoutes.habitsGelisimTab);
  }

  Future<void> _cancelIncompleteSetup(HabitModel habit) async {
    if (!widget.showHomeVisibilityHint || !_needsIbadetOnboarding(habit)) {
      _goToOrigin();
      return;
    }
    if (_routeTransitioning) return;
    _routeTransitioning = true;
    try {
      await ref.read(habitRepositoryProvider).deletePermanently(habit.id);
    } catch (e) {
      debugPrint('Namaz incomplete setup delete failed: $e');
      _routeTransitioning = false;
      _goToOrigin();
      return;
    }
    ref.read(habitSummaryProvider.notifier).refresh();
    await ref.read(salatTrackingVisibleOnHomeProvider.notifier).disable();
    if (!mounted) return;
    _goToOrigin(force: true);
  }

  Future<void> _celebrateIfNeeded() async {
    final habit = ref.read(habitRepositoryProvider).getById(widget.habitId);
    if (habit == null || !mounted) return;
    if (_needsIbadetOnboarding(habit)) return;
    await SalatCelebration.tryShowForPreviousWeek(
      context: context,
      ref: ref,
      habit: habit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Namaz tikleri Hive’a yazar; özet yenilenince bu sayfa da yeniden çizilsin.
    ref.watch(habitSummaryProvider);
    final habit = ref.watch(habitRepositoryProvider).getById(widget.habitId);
    final salat = ref.watch(salatLogRepositoryProvider);
    final today = DateTime.now();
    final done = habit == null ? 0 : salat.countDone(habit.id, today);
    final pct = ((done / 5) * 100).round();

    if (habit == null) {
      return Scaffold(
        backgroundColor: AppColors.anthraciteDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.creamBase),
            onPressed: _goToOrigin,
          ),
        ),
        body: Center(
          child: Text(
            l10n.willpowerHabitNotFound,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
        ),
      );
    }

    if (_needsIbadetOnboarding(habit)) {
      return NamazIbadetOnboarding(
        habitId: habit.id,
        onClose: () => unawaited(_cancelIncompleteSetup(habit)),
        onCompleted: () async {
          if (!mounted) return;
          _goToOrigin();
        },
      );
    }

    _showHomeVisibilityHintIfNeeded();

    return Scaffold(
      backgroundColor: AppColors.anthraciteDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _goToOrigin,
                        child: Text(
                          l10n.commonClose,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.creamBase.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.namazProgramPageTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.creamBase,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 72),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentNeonGreen.withValues(
                                alpha: 0.35,
                              ),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentNeonGreen.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.nightlight_round,
                            size: 40,
                            color: AppColors.accentNeonGreen.withValues(
                              alpha: 0.95,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l10n.namazProgramVerseQuote,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.creamBase.withValues(alpha: 0.88),
                          height: 1.55,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.willBreathing()),
                          icon: Icon(
                            Icons.air_rounded,
                            size: 20,
                            color: AppColors.accentNeonGreen.withValues(
                              alpha: 0.9,
                            ),
                          ),
                          label: Text(
                            l10n.namazProgramBreathingBreak,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.accentNeonGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.namazProgramTodayPrayersTitle,
                                        style: AppTextStyles.titleSmall
                                            .copyWith(
                                              color: AppColors.creamBase,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.namazProgramTodayProgress(done),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textOnDarkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SalatPrayerRow(habitId: habit.id),
                            const SizedBox(height: 18),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: done / 5,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                color: AppColors.accentNeonGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.namazProgramPercentDone(pct),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textOnDarkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const NamazAdhanReminderCard(),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => openAppSettings(),
                          icon: Icon(
                            Icons.settings_cell_rounded,
                            size: 18,
                            color: AppColors.creamBase.withValues(alpha: 0.55),
                          ),
                          label: Text(
                            l10n.namazProgramSystemNotificationSettings,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.creamBase.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.namazProgramRecentDaysTitle,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.creamBase,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.namazProgramRecentDaysSubtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textOnDarkMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SalatRecentDaysStrip(habitId: habit.id, dayCount: 21),
                      const SizedBox(height: 22),
                      NamazInsightCard(habitId: habit.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}
