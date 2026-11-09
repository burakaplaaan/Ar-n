// Amin sonrası destek kartı. Yıldızlar süs; puanı sistem penceresi sorar.

import 'package:flutter/material.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';

class OnboardingSupportScreen extends StatelessWidget {
  const OnboardingSupportScreen({
    required this.onBack,
    required this.onRate,
    required this.onContinueTour,
    this.progress = 0.96,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onRate;
  final VoidCallback onContinueTour;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        const OnboardingEntryBackdrop(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OnboardingFlowTopBar(progress: progress, onBack: onBack),
                const Spacer(),
                const Center(child: _SupportMark()),
                const SizedBox(height: 28),
                Text(
                  l10n.onboardingSupportTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 32,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.onboardingSupportBody,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                const ExcludeSemantics(child: _OutlineStars()),
                const Spacer(),
                OnboardingCtaButton(
                  label: l10n.onboardingSupportRate,
                  onPressed: onRate,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onContinueTour,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.78),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    l10n.onboardingSupportTour,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportMark extends StatelessWidget {
  const _SupportMark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ornamentGold,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.ornamentGold.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const SizedBox(
        width: 72,
        height: 72,
        child: Icon(Icons.favorite_rounded, color: Color(0xFF1A1408), size: 34),
      ),
    );
  }
}

class _OutlineStars extends StatelessWidget {
  const _OutlineStars();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.star_border_rounded,
            color: AppColors.ornamentGold,
            size: 34,
          ),
        );
      }),
    );
  }
}
