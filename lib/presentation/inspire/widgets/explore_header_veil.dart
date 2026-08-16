import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Keşfet üst çubuğu — güvenli alanın hemen altında, ada ile çakışmadan.
abstract final class ExploreHeaderMetrics {
  static const double toolbarHeight = 34;
  static const double searchRowHeight = 50;
}

/// Gri levha yerine zemine karışan cam + fade. Safe area'yı da kaplar.
class ExploreHeaderVeil extends StatelessWidget {
  const ExploreHeaderVeil({super.key});

  @override
  Widget build(BuildContext context) {
    final onLight = Theme.of(context).brightness == Brightness.light;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: onLight
                  ? [
                      AppColors.creamMist.withValues(alpha: 0.94),
                      AppColors.creamMist.withValues(alpha: 0.78),
                      AppColors.creamMist.withValues(alpha: 0.0),
                    ]
                  : [
                      const Color(0xF2050A07),
                      AppColors.homeGradientTop.withValues(alpha: 0.78),
                      AppColors.homeGradientTop.withValues(alpha: 0.0),
                    ],
              stops: const [0.0, 0.58, 1.0],
            ),
            border: Border(
              bottom: BorderSide(
                color: onLight
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
