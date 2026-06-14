import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/arin_shell_background.dart';

class ArinBackButton extends StatelessWidget {
  const ArinBackButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_back_ios_new_rounded,
  });

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final dimColor = light
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.55);
    final btnBg = light
        ? AppColors.emeraldFaint.withValues(alpha: 0.50)
        : Colors.white.withValues(alpha: 0.07);
    final btnBorder = light
        ? AppColors.emeraldMid.withValues(alpha: 0.30)
        : Colors.white.withValues(alpha: 0.13);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: btnBg,
          border: Border.all(color: btnBorder),
        ),
        child: Icon(
          icon,
          size: 15,
          color: dimColor,
        ),
      ),
    );
  }
}
