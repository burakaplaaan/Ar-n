import 'package:flutter/material.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';

class OnboardingInfoCardData {
  const OnboardingInfoCardData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class OnboardingInfoScreen extends StatelessWidget {
  const OnboardingInfoScreen({
    required this.title,
    required this.subtitle,
    required this.cards,
    required this.onBack,
    required this.onContinue,
    this.progress = 0.8,
    this.heroIcon,
    this.featured,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<OnboardingInfoCardData> cards;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final double progress;
  final IconData? heroIcon;
  final OnboardingInfoCardData? featured;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        const OnboardingEntryBackdrop(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
            child: Column(
              children: [
                OnboardingFlowTopBar(
                  progress: progress,
                  onBack: onBack,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        if (heroIcon != null) ...[
                          Container(
                            width: 72,
                            height: 72,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.ornamentGold.withValues(
                                alpha: 0.14,
                              ),
                              border: Border.all(
                                color: AppColors.ornamentGold.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Icon(
                              heroIcon,
                              color: AppColors.ornamentGold,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 28,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.56),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (featured != null) ...[
                          _FeaturedCard(card: featured!),
                          const SizedBox(height: 10),
                        ],
                        for (final card in cards) ...[
                          _InfoRow(card: card),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OnboardingCtaButton(
                  label: '${l10n.onboardingContinue}  →',
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.card});

  final OnboardingInfoCardData card;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.ornamentGold.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ornamentGold.withValues(alpha: 0.16),
              ),
              child: Icon(card.icon, color: AppColors.ornamentGold, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              card.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.card});

  final OnboardingInfoCardData card;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ornamentGold.withValues(alpha: 0.16),
              ),
              child: Icon(card.icon, color: AppColors.ornamentGold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    card.body,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
