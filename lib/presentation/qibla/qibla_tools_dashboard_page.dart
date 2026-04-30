// lib/presentation/qibla/qibla_tools_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/arin_shell_background.dart';
import '../shared/widgets/qibla_nav_icon.dart';
import '../shared/widgets/zikirmatik_silhouette_icon.dart';
import 'qibla_hub_page.dart';

/// Kıble araçları hub kartları — ana uygulama kartlarıyla uyumlu, kompakt ölçüler.
abstract final class _QiblaHubCardStyle {
  static const double radius = 18;
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const double iconCircle = 64;
  static const double gapIconText = 14;
  static const double titleSize = 16;
  static const double subtitleSize = 12.5;
  static const double actionSize = 13;
  static const double arrowSize = 16;
  static const double borderW = 1.1;
}

class QiblaToolsDashboardPage extends StatelessWidget {
  const QiblaToolsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    const accent = AppColors.accentNeonGreen;

    return SizedBox.expand(
      child: ArinShellBackground.buildLayered(
        context,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _QiblaCompassFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pushNamed(
                          QiblaHubRoutes.compass,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _ZikirFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pushNamed(
                          QiblaHubRoutes.zikir,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _BreathingFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pushNamed(
                          QiblaHubRoutes.breathing,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _HealingFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pushNamed(
                          QiblaHubRoutes.healing,
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QiblaCompassFeatureCard extends StatelessWidget {
  const _QiblaCompassFeatureCard({
    required this.onDark,
    required this.accent,
    required this.onTap,
  });

  final bool onDark;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final borderC = accent.withValues(alpha: onDark ? 0.42 : 0.48);
    final titleC =
        onDark ? Colors.white.withValues(alpha: 0.95) : AppColors.emeraldDark;
    final subC = onDark
        ? Colors.white.withValues(alpha: 0.68)
        : AppColors.emeraldDark.withValues(alpha: 0.78);
    final iconColor = onDark ? Colors.white : AppColors.emeraldDark;

    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_QiblaHubCardStyle.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_QiblaHubCardStyle.radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: onDark
                  ? [
                      AppColors.homeCardSurface.withValues(alpha: 0.92),
                      const Color(0xFF0A120E).withValues(alpha: 0.96),
                    ]
                  : [
                      AppColors.creamSurface,
                      AppColors.creamMist.withValues(alpha: 0.98),
                    ],
            ),
            border: Border.all(color: borderC, width: _QiblaHubCardStyle.borderW),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlowGreen.withValues(
                  alpha: onDark ? 0.14 : 0.1,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: _QiblaHubCardStyle.padding,
            child: Row(
              children: [
                Container(
                  width: _QiblaHubCardStyle.iconCircle,
                  height: _QiblaHubCardStyle.iconCircle,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: onDark ? 0.12 : 0.14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: QiblaNavIcon(color: iconColor, size: 32),
                ),
                const SizedBox(width: _QiblaHubCardStyle.gapIconText),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.qiblaHubCompassTitle,
                        style: TextStyle(
                          color: titleC,
                          fontSize: _QiblaHubCardStyle.titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.qiblaHubCompassSubtitle,
                        style: TextStyle(
                          color: subC,
                          fontSize: _QiblaHubCardStyle.subtitleSize,
                          height: 1.32,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            l10n.qiblaHubOpenAction,
                            style: TextStyle(
                              color: accent.withValues(alpha: 0.95),
                              fontSize: _QiblaHubCardStyle.actionSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: _QiblaHubCardStyle.arrowSize,
                            color: accent.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return card;
  }
}

class _ZikirFeatureCard extends StatelessWidget {
  const _ZikirFeatureCard({
    required this.onDark,
    required this.accent,
    required this.onTap,
  });

  final bool onDark;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final borderC = accent.withValues(alpha: onDark ? 0.42 : 0.48);
    final titleC =
        onDark ? Colors.white.withValues(alpha: 0.95) : AppColors.emeraldDark;
    final subC = onDark
        ? Colors.white.withValues(alpha: 0.68)
        : AppColors.emeraldDark.withValues(alpha: 0.78);

    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_QiblaHubCardStyle.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_QiblaHubCardStyle.radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: onDark
                  ? [
                      AppColors.homeCardSurface.withValues(alpha: 0.92),
                      const Color(0xFF0A120E).withValues(alpha: 0.96),
                    ]
                  : [
                      AppColors.creamSurface,
                      AppColors.creamMist.withValues(alpha: 0.98),
                    ],
            ),
            border: Border.all(color: borderC, width: _QiblaHubCardStyle.borderW),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlowGreen.withValues(
                  alpha: onDark ? 0.14 : 0.1,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: _QiblaHubCardStyle.padding,
            child: Row(
              children: [
                Container(
                  width: _QiblaHubCardStyle.iconCircle,
                  height: _QiblaHubCardStyle.iconCircle,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: onDark ? 0.12 : 0.14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const ZikirmatikSilhouetteIcon(size: 36),
                ),
                const SizedBox(width: _QiblaHubCardStyle.gapIconText),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.qiblaHubZikirTitle,
                        style: TextStyle(
                          color: titleC,
                          fontSize: _QiblaHubCardStyle.titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.qiblaHubZikirFeatureSubtitle,
                        style: TextStyle(
                          color: subC,
                          fontSize: _QiblaHubCardStyle.subtitleSize,
                          height: 1.32,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            l10n.qiblaHubOpenAction,
                            style: TextStyle(
                              color: accent.withValues(alpha: 0.95),
                              fontSize: _QiblaHubCardStyle.actionSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: _QiblaHubCardStyle.arrowSize,
                            color: accent.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return card;
  }
}

class _BreathingFeatureCard extends StatelessWidget {
  const _BreathingFeatureCard({
    required this.onDark,
    required this.accent,
    required this.onTap,
  });

  final bool onDark;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final borderC = accent.withValues(alpha: onDark ? 0.42 : 0.48);
    final titleC =
        onDark ? Colors.white.withValues(alpha: 0.95) : AppColors.emeraldDark;
    final subC = onDark
        ? Colors.white.withValues(alpha: 0.68)
        : AppColors.emeraldDark.withValues(alpha: 0.78);
    final iconColor = onDark ? Colors.white : AppColors.emeraldDark;

    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_QiblaHubCardStyle.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_QiblaHubCardStyle.radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: onDark
                  ? [
                      AppColors.homeCardSurface.withValues(alpha: 0.92),
                      const Color(0xFF0A120E).withValues(alpha: 0.96),
                    ]
                  : [
                      AppColors.creamSurface,
                      AppColors.creamMist.withValues(alpha: 0.98),
                    ],
            ),
            border: Border.all(color: borderC, width: _QiblaHubCardStyle.borderW),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlowGreen.withValues(
                  alpha: onDark ? 0.14 : 0.1,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: _QiblaHubCardStyle.padding,
            child: Row(
              children: [
                Container(
                  width: _QiblaHubCardStyle.iconCircle,
                  height: _QiblaHubCardStyle.iconCircle,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: onDark ? 0.12 : 0.14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.air_rounded,
                    size: 32,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: _QiblaHubCardStyle.gapIconText),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.qiblaHubBreathingTitle,
                        style: TextStyle(
                          color: titleC,
                          fontSize: _QiblaHubCardStyle.titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.qiblaHubBreathingSubtitle,
                        style: TextStyle(
                          color: subC,
                          fontSize: _QiblaHubCardStyle.subtitleSize,
                          height: 1.32,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            l10n.qiblaHubOpenAction,
                            style: TextStyle(
                              color: accent.withValues(alpha: 0.95),
                              fontSize: _QiblaHubCardStyle.actionSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: _QiblaHubCardStyle.arrowSize,
                            color: accent.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return card;
  }
}

class _HealingFeatureCard extends StatelessWidget {
  const _HealingFeatureCard({
    required this.onDark,
    required this.accent,
    required this.onTap,
  });

  final bool onDark;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final borderC = accent.withValues(alpha: onDark ? 0.42 : 0.48);
    final titleC =
        onDark ? Colors.white.withValues(alpha: 0.95) : AppColors.emeraldDark;
    final subC = onDark
        ? Colors.white.withValues(alpha: 0.68)
        : AppColors.emeraldDark.withValues(alpha: 0.78);
    final iconColor = onDark ? Colors.white : AppColors.emeraldDark;

    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_QiblaHubCardStyle.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_QiblaHubCardStyle.radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: onDark
                  ? [
                      AppColors.homeCardSurface.withValues(alpha: 0.92),
                      const Color(0xFF0A120E).withValues(alpha: 0.96),
                    ]
                  : [
                      AppColors.creamSurface,
                      AppColors.creamMist.withValues(alpha: 0.98),
                    ],
            ),
            border: Border.all(color: borderC, width: _QiblaHubCardStyle.borderW),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlowGreen.withValues(
                  alpha: onDark ? 0.14 : 0.1,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: _QiblaHubCardStyle.padding,
            child: Row(
              children: [
                Container(
                  width: _QiblaHubCardStyle.iconCircle,
                  height: _QiblaHubCardStyle.iconCircle,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: onDark ? 0.12 : 0.14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    size: 32,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: _QiblaHubCardStyle.gapIconText),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.qiblaHubHealingTitle,
                        style: TextStyle(
                          color: titleC,
                          fontSize: _QiblaHubCardStyle.titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.qiblaHubHealingSubtitle,
                        style: TextStyle(
                          color: subC,
                          fontSize: _QiblaHubCardStyle.subtitleSize,
                          height: 1.32,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            l10n.qiblaHubOpenAction,
                            style: TextStyle(
                              color: accent.withValues(alpha: 0.95),
                              fontSize: _QiblaHubCardStyle.actionSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: _QiblaHubCardStyle.arrowSize,
                            color: accent.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return card;
  }
}
