// lib/presentation/onboarding/app_tour/app_tour_layout.dart
// Spotlight açıklaması, İlerle ve delik için ayrık yuvalar.

import 'package:flutter/widgets.dart';

enum AppTourTooltipSide { above, below }

class AppTourSlotLayout {
  const AppTourSlotLayout({
    required this.ctaBottom,
    required this.tooltipReservedBottom,
    required this.side,
  });

  final double ctaBottom;
  final double tooltipReservedBottom;
  final AppTourTooltipSide side;
}

abstract final class AppTourLayout {
  static const double holeInflate = 8;
  static const double holeRadius = 16;
  static const double minTooltipSpace = 120;
  static const double ctaBlockHeight = 88;

  static AppTourTooltipSide tooltipSide({
    required Rect hole,
    required Size screen,
    required double reservedBottom,
  }) {
    final padded = hole.inflate(holeInflate);
    final spaceBelow = screen.height - reservedBottom - padded.bottom;
    final spaceAbove = padded.top;
    if (spaceBelow >= minTooltipSpace) return AppTourTooltipSide.below;
    if (spaceAbove >= minTooltipSpace) return AppTourTooltipSide.above;
    return spaceBelow >= spaceAbove
        ? AppTourTooltipSide.below
        : AppTourTooltipSide.above;
  }

  static AppTourSlotLayout slots({
    required Rect? hole,
    required Size screen,
    required double safeBottom,
  }) {
    final holeBlocksCta =
        hole != null &&
        hole.bottom > screen.height - ctaBlockHeight - safeBottom - 8;
    final ctaBottom = holeBlocksCta
        ? (screen.height - hole.top + 16)
        : (12 + safeBottom);
    final reservedForCta = ctaBottom + ctaBlockHeight;
    final side = hole == null
        ? AppTourTooltipSide.below
        : tooltipSide(
            hole: hole,
            screen: screen,
            reservedBottom: reservedForCta,
          );
    return AppTourSlotLayout(
      ctaBottom: ctaBottom,
      tooltipReservedBottom: reservedForCta,
      side: side,
    );
  }
}
