// Kaza namazı — vakit bazlı sayaç takibi.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../shared/providers/willpower_hub_nav_provider.dart';
import 'kaza_tracking_provider.dart';
import 'kaza_widgets.dart';

const List<String> kKazaPrayerLabels = [
  'Sabah namazı',
  'Öğle namazı',
  'İkindi namazı',
  'Akşam namazı',
  'Yatsı namazı',
  'Vitir namazı',
];

const Color _kDebtPlusColor = Color(0xFFFF6B6B);

class KazaTrackerPage extends ConsumerWidget {
  const KazaTrackerPage({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.anthraciteMid,
        title: Text(
          'Sıfırla',
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.creamBase),
        ),
        content: Text(
          'Tüm kaza sayıları sıfırlanacak. Emin misin?',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDarkMuted,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.textOnDarkMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sıfırla',
              style: TextStyle(
                color: _kDebtPlusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
                        'Kaza takibi',
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
                        'Kapat',
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
                            'Kaza namazı takibi',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.creamBase,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kaza namazlarını vakit namazları kılındıktan sonra kılmaya '
                            'özen göster. Eksik (+) ile borç ekleyebilir, kıldığın '
                            'her rekat için (−) ile sayacı azaltabilirsin.',
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
                          label: kKazaPrayerLabels[i],
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
                              'Sıfırla',
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
