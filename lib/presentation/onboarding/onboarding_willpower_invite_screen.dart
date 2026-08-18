import 'package:flutter/material.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../shared/widgets/arin_pressable.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';

class OnboardingWillpowerInviteScreen extends StatelessWidget {
  const OnboardingWillpowerInviteScreen({
    required this.onBack,
    required this.onChooseArinma,
    required this.onChooseGelisim,
    required this.onLater,
    this.progress = 0.93,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onChooseArinma;
  final VoidCallback onChooseGelisim;
  final VoidCallback onLater;
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
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OnboardingFlowTopBar(progress: progress, onBack: onBack),
                const SizedBox(height: 28),
                Text(
                  l10n.onboardingFirstStepTitle,
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
                  l10n.onboardingFirstStepSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.56),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _InviteCard(
                        icon: Icons.local_fire_department_rounded,
                        title: l10n.onboardingFirstStepArinmaTitle,
                        body: l10n.onboardingFirstStepArinmaBody,
                        onTap: onChooseArinma,
                      ),
                      const SizedBox(height: 12),
                      _InviteCard(
                        icon: Icons.eco_rounded,
                        title: l10n.onboardingFirstStepGelisimTitle,
                        body: l10n.onboardingFirstStepGelisimBody,
                        onTap: onChooseGelisim,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onLater,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.72),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    l10n.onboardingFirstStepLater,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
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

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ArinPressable(
      onTap: onTap,
      scale: 0.975,
      sink: 1.6,
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.emeraldMid.withValues(alpha: 0.36),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.58),
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
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
