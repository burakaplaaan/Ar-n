// Mushaf yüzeyi — Kıble hub bronz + Scheherazade.

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/arin_shell_background.dart';

abstract final class QuranStyle {
  static const String arabicFamily = 'ScheherazadeNew';
  static const double diamondAngle = 0.7853981633974483;

  static bool onDark(BuildContext context) =>
      !ArinShellBackground.isLight(context);

  static Color bronze(bool dark) =>
      dark ? const Color(0xFFC59B6D) : const Color(0xFF8B5E3C);

  static Color bronzeSoft(bool dark) =>
      dark ? const Color(0xFF8A6545) : const Color(0xFFC9A27A);

  static Color title(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.96) : AppColors.emeraldDark;

  static Color subtitle(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.68)
      : AppColors.emeraldDark.withValues(alpha: 0.78);

  static Color muted(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.52)
      : AppColors.textSecondary.withValues(alpha: 0.9);

  static Color cardFill(bool dark) => dark
      ? AppColors.homeCardSurface.withValues(alpha: 0.92)
      : AppColors.creamSurface;

  static Color cardFillDeep(bool dark) => dark
      ? const Color(0xFF0A120E).withValues(alpha: 0.96)
      : AppColors.creamMist.withValues(alpha: 0.98);

  static Color border(bool dark) => Color.lerp(
        AppColors.ornamentGold,
        bronze(dark),
        0.35,
      )!.withValues(alpha: dark ? 0.52 : 0.48);

  static double arabicSize(int fontStep) {
    switch (fontStep.clamp(0, 2)) {
      case 0:
        return 25;
      case 2:
        return 34;
      default:
        return 29;
    }
  }

  static double mealSize(int fontStep) {
    switch (fontStep.clamp(0, 2)) {
      case 0:
        return 13.5;
      case 2:
        return 16.5;
      default:
        return 14.5;
    }
  }
}
