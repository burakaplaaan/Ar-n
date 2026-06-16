import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/arin_shell_background.dart';

enum ArinBackButtonVariant { adaptive, overlaySubtle }

class ArinBackButton extends StatelessWidget {
  const ArinBackButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.semanticLabel,
    this.variant = ArinBackButtonVariant.adaptive,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? semanticLabel;
  final ArinBackButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final label = semanticLabel ?? MaterialLocalizations.of(context).backButtonTooltip;
    final (dimColor, btnBg, btnBorder) = switch (variant) {
      ArinBackButtonVariant.overlaySubtle => (
          Colors.white.withValues(alpha: 0.76),
          Colors.black.withValues(alpha: 0.30),
          Colors.white.withValues(alpha: 0.20),
        ),
      ArinBackButtonVariant.adaptive => (
          light
              ? AppColors.textSecondary
              : Colors.white.withValues(alpha: 0.55),
          light
              ? AppColors.emeraldFaint.withValues(alpha: 0.50)
              : Colors.white.withValues(alpha: 0.07),
          light
              ? AppColors.emeraldMid.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.13),
        ),
    };

    return Semantics(
      button: true,
      label: label,
      onTap: onPressed,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: btnBg,
                  border: Border.all(color: btnBorder),
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: 15,
                    color: dimColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
