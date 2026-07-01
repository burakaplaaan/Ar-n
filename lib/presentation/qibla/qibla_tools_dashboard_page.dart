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
  static const EdgeInsets actionChipPadding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 6);
}

const double _kDiamondAngle = 0.7853981633974483;

/// Yeşil paleti bozmadan sıcaklık katan bronz/kahverengi tonlar.
/// Koyu temada açık bronz, açık temada koyu kahve — kontrast korunur.
abstract final class _QiblaWarm {
  static Color bronze(bool onDark) =>
      onDark ? const Color(0xFFC59B6D) : const Color(0xFF8B5E3C);
  static Color bronzeSoft(bool onDark) =>
      onDark ? const Color(0xFF8A6545) : const Color(0xFFC9A27A);
}

class QiblaToolsDashboardPage extends StatelessWidget {
  const QiblaToolsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    final l10n = AppLocalizations.of(context)!;
    const accent = AppColors.accentNeonGreen;

    return SizedBox.expand(
      child: ArinShellBackground.buildLayered(
        context,
        child: CustomScrollView(
          key: const PageStorageKey<String>('qiblaToolsScroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SpiritualHeader(onDark: onDark),
                    const SizedBox(height: 16),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      icon: QiblaNavIcon(
                        color: onDark ? Colors.white : AppColors.emeraldDark,
                        size: 32,
                      ),
                      title: l10n.qiblaHubCompassTitle,
                      subtitle: l10n.qiblaHubCompassSubtitle,
                      actionLabel: l10n.qiblaHubOpenAction,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pushNamed(
                          QiblaHubRoutes.compass,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      icon: const ZikirmatikSilhouetteIcon(size: 36),
                      title: l10n.qiblaHubZikirTitle,
                      subtitle: l10n.qiblaHubZikirFeatureSubtitle,
                      actionLabel: l10n.qiblaHubOpenAction,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pushNamed(
                          QiblaHubRoutes.zikir,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      icon: Icon(
                        Icons.air_rounded,
                        size: 32,
                        color: onDark ? Colors.white : AppColors.emeraldDark,
                      ),
                      title: l10n.qiblaHubBreathingTitle,
                      subtitle: l10n.qiblaHubBreathingSubtitle,
                      actionLabel: l10n.qiblaHubOpenAction,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pushNamed(
                          QiblaHubRoutes.breathing,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      icon: Icon(
                        Icons.graphic_eq_rounded,
                        size: 32,
                        color: onDark ? Colors.white : AppColors.emeraldDark,
                      ),
                      title: l10n.qiblaHubHealingTitle,
                      subtitle: l10n.qiblaHubHealingSubtitle,
                      actionLabel: l10n.qiblaHubOpenAction,
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

/// Sayfanın üstünde sade, manevi bir tezhip şeridi: iki yana açılan bronz
/// ince çizgi, ortada üç küçük baklava (geleneksel süsleme hissi). Metin
/// içermez (çok dilli güvenli); sayfaya "sükûnet" tonu verir.
class _SpiritualHeader extends StatelessWidget {
  const _SpiritualHeader({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bronze = _QiblaWarm.bronze(onDark);
    final bronzeSoft = _QiblaWarm.bronzeSoft(onDark);

    Widget ornamentLine({required bool toRight}) {
      return Expanded(
        child: Container(
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: toRight ? Alignment.centerLeft : Alignment.centerRight,
              end: toRight ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                bronze.withValues(alpha: 0.0),
                bronze.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
      );
    }

    Widget diamond({required double size, required double alpha, bool glow = false}) {
      return Transform.rotate(
        angle: _kDiamondAngle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bronze.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(2),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: bronzeSoft.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          ornamentLine(toRight: true),
          const SizedBox(width: 10),
          diamond(size: 5, alpha: 0.5),
          const SizedBox(width: 7),
          diamond(size: 8, alpha: 0.85, glow: true),
          const SizedBox(width: 7),
          diamond(size: 5, alpha: 0.5),
          const SizedBox(width: 10),
          ornamentLine(toRight: false),
        ],
      ),
    );
  }
}

/// Tüm hub kartları için tek estetik gövde. Yeşil temel + bronz manevi
/// detaylar: köşe ışıltısı, yeşil→bronz ikon halkası, başlıkta baklava
/// aksanı, ince bronz alt çizgi ve sıcak gölge.
class _QiblaFeatureCard extends StatelessWidget {
  const _QiblaFeatureCard({
    required this.onDark,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final bool onDark;
  final Color accent;
  final Widget icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bronze = _QiblaWarm.bronze(onDark);
    final bronzeSoft = _QiblaWarm.bronzeSoft(onDark);
    final titleC =
        onDark ? Colors.white.withValues(alpha: 0.95) : AppColors.emeraldDark;
    final subC = onDark
        ? Colors.white.withValues(alpha: 0.68)
        : AppColors.emeraldDark.withValues(alpha: 0.78);
    // Sınır artık saf yeşil değil; bronza doğru hafifçe harmanlanıyor.
    final borderC = Color.lerp(
      accent,
      bronze,
      0.3,
    )!.withValues(alpha: onDark ? 0.5 : 0.55);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_QiblaHubCardStyle.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: bronze.withValues(alpha: 0.06),
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
            border:
                Border.all(color: borderC, width: _QiblaHubCardStyle.borderW),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlowGreen.withValues(
                  alpha: onDark ? 0.14 : 0.1,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              // Sıcak, manevi alt gölge.
              BoxShadow(
                color: bronzeSoft.withValues(alpha: onDark ? 0.12 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Üst-sağ köşede yumuşak bronz ışıltı (kandil hissi).
              Positioned(
                top: -38,
                right: -28,
                child: IgnorePointer(
                  child: Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          bronze.withValues(alpha: onDark ? 0.16 : 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: _QiblaHubCardStyle.padding,
                child: Row(
                  children: [
                    _IconRing(
                      onDark: onDark,
                      accent: accent,
                      bronze: bronze,
                      bronzeSoft: bronzeSoft,
                      child: icon,
                    ),
                    const SizedBox(width: _QiblaHubCardStyle.gapIconText),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Transform.rotate(
                                angle: _kDiamondAngle,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: bronze.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: titleC,
                                    fontSize: _QiblaHubCardStyle.titleSize,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // İnce bronz alt çizgi — başlığı zarifçe taçlandırır.
                          Container(
                            height: 1.5,
                            width: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: [
                                  bronze.withValues(alpha: 0.6),
                                  bronzeSoft.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: subC,
                              fontSize: _QiblaHubCardStyle.subtitleSize,
                              height: 1.32,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 9),
                          _SpiritualActionChip(
                            onDark: onDark,
                            accent: accent,
                            bronze: bronze,
                            bronzeSoft: bronzeSoft,
                            label: actionLabel,
                          ),
                        ],
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

/// "Aç" aksiyonu için manevi/pürüzsüz çip görünümü.
/// Düz yazı satırı yerine küçük bir niş gibi görünür: bronz baklava, sıcak
/// iç ışık, yeşil-bronz ok ve ince iç çizgi.
class _SpiritualActionChip extends StatelessWidget {
  const _SpiritualActionChip({
    required this.onDark,
    required this.accent,
    required this.bronze,
    required this.bronzeSoft,
    required this.label,
  });

  final bool onDark;
  final Color accent;
  final Color bronze;
  final Color bronzeSoft;
  final String label;

  @override
  Widget build(BuildContext context) {
    final baseForeground = onDark
        ? Colors.white.withValues(alpha: 0.93)
        : AppColors.emeraldDark.withValues(alpha: 0.92);
    final textColor = Color.lerp(baseForeground, bronze, onDark ? 0.12 : 0.08)!;
    final arrowColor = Color.lerp(baseForeground, bronze, 0.24)!;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: _QiblaHubCardStyle.actionChipPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: onDark ? 0.12 : 0.1),
              bronzeSoft.withValues(alpha: onDark ? 0.18 : 0.15),
            ],
          ),
          border: Border.all(
            color: Color.lerp(accent, bronze, 0.52)!.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: bronzeSoft.withValues(alpha: onDark ? 0.18 : 0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: _kDiamondAngle,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: bronze.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(1.2),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: _QiblaHubCardStyle.actionSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.05,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: _QiblaHubCardStyle.arrowSize,
              color: arrowColor,
            ),
            const SizedBox(width: 2),
            Container(
              width: 10,
              height: 1.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    bronze.withValues(alpha: 0.55),
                    bronzeSoft.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yeşilden bronza geçen ikon halkası — soğuk yeşili sıcak bir çerçeveyle
/// yumuşatır.
class _IconRing extends StatelessWidget {
  const _IconRing({
    required this.onDark,
    required this.accent,
    required this.bronze,
    required this.bronzeSoft,
    required this.child,
  });

  final bool onDark;
  final Color accent;
  final Color bronze;
  final Color bronzeSoft;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _QiblaHubCardStyle.iconCircle,
      height: _QiblaHubCardStyle.iconCircle,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: onDark ? 0.12 : 0.14),
            bronzeSoft.withValues(alpha: onDark ? 0.18 : 0.2),
          ],
        ),
        border: Border.all(
          color: Color.lerp(accent, bronze, 0.4)!.withValues(alpha: 0.45),
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
