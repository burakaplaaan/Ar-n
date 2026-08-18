// Kaza namazı — vakit bazlı sayaç takibi.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../shared/widgets/arin_popup.dart';
import '../shared/providers/willpower_hub_nav_provider.dart';
import 'kaza_tracking_provider.dart';
import 'kaza_widgets.dart';

  List<String> _getPrayerLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.kazaPrayerFajr,
      l10n.kazaPrayerDhuhr,
      l10n.kazaPrayerAsr,
      l10n.kazaPrayerMaghrib,
      l10n.kazaPrayerIsha,
      l10n.kazaPrayerWitr,
    ];
  }

const Color _kDebtPlusColor = Color(0xFFFF6B6B);

class KazaTrackerPage extends ConsumerWidget {
  const KazaTrackerPage({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showArinConfirm(
      context: context,
      title: l10n.kazaReset,
      message: l10n.kazaResetConfirmDesc,
      cancelLabel: l10n.kazaCancel,
      confirmLabel: l10n.kazaReset,
      tone: ArinPopupTone.destructive,
      icon: Icons.restart_alt_rounded,
    );
    if (ok == true) {
      await ref.read(kazaTrackingProvider.notifier).resetAllCounts();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(kazaTrackingProvider);
    final counts = s.counts;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KazaPageBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.creamBase.withValues(alpha: 0.9),
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.kazaTrackerTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.creamBase,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(willpowerHubReturnToArinmaProvider.notifier)
                            .state = false;
                        context.go(AppRoutes.habits);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(48, 48),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.kazaClose,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.accentNeonGreen.withValues(
                            alpha: 0.95,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    KazaSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.kazaTrackerSubtitle,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.creamBase,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.kazaTrackerDesc,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textOnDarkMuted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 360.ms),
                    const SizedBox(height: 18),
                    ...List.generate(6, (i) {
                      final n = counts[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _KazaPrayerRow(
                          label: _getPrayerLabels(context)[i],
                          count: n,
                          onAdd: () => ref
                              .read(kazaTrackingProvider.notifier)
                              .addToSlot(i, 1),
                          onRemove: n > 0
                              ? () => ref
                                  .read(kazaTrackingProvider.notifier)
                                  .addToSlot(i, -1)
                              : null,
                        ),
                      )
                          .animate()
                          .fadeIn(
                            duration: 380.ms,
                            delay: (60 * i).ms,
                            curve: Curves.easeOutCubic,
                          )
                          .slideX(
                            begin: 0.04,
                            duration: 400.ms,
                            delay: (60 * i).ms,
                            curve: Curves.easeOutCubic,
                          );
                    }),
                    const SizedBox(height: 8),
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _confirmReset(context, ref),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.kazaReset,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.creamBase.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 420.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KazaPrayerRow extends StatelessWidget {
  const _KazaPrayerRow({
    required this.label,
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KazaIconCircleButton(
          icon: Icons.add_rounded,
          color: _kDebtPlusColor,
          onPressed: onAdd,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColors.anthraciteDark.withValues(alpha: 0.85),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.creamBase,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    return ScaleTransition(scale: anim, child: child);
                  },
                  child: Text(
                    '$count',
                    key: ValueKey<int>(count),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.accentNeonGreen.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        KazaIconCircleButton(
          icon: Icons.remove_rounded,
          color: AppColors.accentNeonGreen,
          onPressed: onRemove,
        ),
      ],
    );
  }
}
