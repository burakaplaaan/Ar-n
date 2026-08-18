import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../shared/widgets/arin_pressable.dart';

class OnboardingFlowTopBar extends StatelessWidget {
  const OnboardingFlowTopBar({
    required this.progress,
    required this.onBack,
    super.key,
  });

  final double progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          child: ArinPressable(
            onTap: onBack,
            scale: 0.9,
            sink: 1.8,
            child: Material(
              color: Colors.white.withValues(alpha: 0.08),
              shape: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.05, 1),
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              color: AppColors.ornamentGold,
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingCtaButton extends StatelessWidget {
  const OnboardingCtaButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;
    final button = Semantics(
      button: true,
      enabled: active,
      label: label,
      child: ArinPressable(
        enabled: active,
        scale: 0.955,
        sink: 2.4,
        onTap: active ? onPressed : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active
                ? AppColors.emeraldLight
                : AppColors.emeraldDark.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(40),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.emeraldLight.withValues(alpha: 0.32),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            width: expand ? double.infinity : null,
            height: 54,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: expand ? 0 : 28),
              child: Center(
                widthFactor: expand ? null : 1,
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: active ? 1 : 0.42),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
