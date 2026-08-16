// lib/presentation/qibla/qibla_tools_dashboard_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../data/services/ad_gate_service.dart';
import '../../data/services/paywall_prompt_service.dart';
import '../../data/services/session_ad_prompt.dart';
import '../shared/providers/premium_providers.dart';
import '../shared/widgets/arin_shell_layout.dart';
import '../shared/widgets/zikirmatik_silhouette_icon.dart';
import 'qibla_hub_page.dart';

/// Kıble araçları hub kartları — ana uygulama kartlarıyla uyumlu, kompakt ölçüler.
abstract final class _QiblaHubCardStyle {
  static const double radius = 18;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );
  static const double iconCircle = 52;
  static const double gapIconText = 12;
  static const double titleSize = 14.5;
  static const double subtitleSize = 11.5;
  static const double formerActionSlotHeight = 0;
  static const double borderW = 1.1;
}

const double _kDiamondAngle = 0.7853981633974483;

enum _QiblaActionMotif { compass, tasbeeh, breath, prayer, frequency, hilal, ai }

/// Yeşil paleti bozmadan sıcaklık katan bronz/kahverengi tonlar.
/// Koyu temada açık bronz, açık temada koyu kahve — kontrast korunur.
abstract final class _QiblaWarm {
  static Color bronze(bool onDark) =>
      onDark ? const Color(0xFFC59B6D) : const Color(0xFF8B5E3C);
  static Color bronzeSoft(bool onDark) =>
      onDark ? const Color(0xFF8A6545) : const Color(0xFFC9A27A);
}

class QiblaToolsDashboardPage extends ConsumerWidget {
  const QiblaToolsDashboardPage({super.key});

  Future<void> _openTool(
    BuildContext context,
    WidgetRef ref, {
    required String route,
    AdGatePlacement? adPlacement,
  }) async {
    HapticFeedback.lightImpact();
    if (adPlacement != null) {
      await SessionAdPrompt.maybeShow(ref: ref, placement: adPlacement);
      if (!context.mounted) return;
    }
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onDark = !ArinShellBackground.isLight(context);
    final l10n = AppLocalizations.of(context)!;
    const accent = AppColors.accentNeonGreen;
    final isPremium = ref.watch(isPremiumProvider);

    // extendBody alt çubuğu gövdenin üstüne bindirdiği için son kart
    // (Bilgi Düellosu) sistem nav + shell bar yüksekliği kadar yukarıda bitmeli.
    final bottomPad = ArinShellLayout.bottomContentPadding(context);

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
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SpiritualHeader(onDark: onDark),
                    const SizedBox(height: 16),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      title: l10n.qiblaHubAiTitle,
                      subtitle: l10n.qiblaHubAiSubtitle,
                      motif: _QiblaActionMotif.ai,
                      locked: !isPremium,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        if (!isPremium) {
                          await PaywallPromptService.showForLockedFeature(
                            context,
                          );
                          return;
                        }
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamed(
                          QiblaHubRoutes.islamicAi,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      title: l10n.qiblaHubCompassTitle,
                      subtitle: l10n.qiblaHubCompassSubtitle,
                      motif: _QiblaActionMotif.compass,
                      onTap: () => _openTool(
                        context,
                        ref,
                        route: QiblaHubRoutes.compass,
                        adPlacement: AdGatePlacement.qiblaSession,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      title: l10n.qiblaHubZikirTitle,
                      subtitle: l10n.qiblaHubZikirFeatureSubtitle,
                      motif: _QiblaActionMotif.tasbeeh,
                      onTap: () => _openTool(
                        context,
                        ref,
                        route: QiblaHubRoutes.zikir,
                        adPlacement: AdGatePlacement.zikirSession,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      title: l10n.qiblaHubHilalDuelTitle,
                      subtitle: l10n.qiblaHubHilalDuelSubtitle,
                      motif: _QiblaActionMotif.hilal,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(
                          context,
                        ).pushNamed(QiblaHubRoutes.hilalDuel);
                      },
                    ),
                    const SizedBox(height: 10),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      title: l10n.qiblaHubPrayerCircleTitle,
                      subtitle: l10n.qiblaHubPrayerCircleSubtitle,
                      motif: _QiblaActionMotif.prayer,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(
                          context,
                        ).pushNamed(QiblaHubRoutes.prayerCircle);
                      },
                    ),
                    const SizedBox(height: 10),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      title: l10n.qiblaHubHealingTitle,
                      subtitle: l10n.qiblaHubHealingSubtitle,
                      motif: _QiblaActionMotif.frequency,
                      onTap: () => _openTool(
                        context,
                        ref,
                        route: QiblaHubRoutes.healing,
                        adPlacement: AdGatePlacement.healingSession,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _QiblaFeatureCard(
                      onDark: onDark,
                      accent: accent,
                      title: l10n.qiblaHubBreathingTitle,
                      subtitle: l10n.qiblaHubBreathingSubtitle,
                      motif: _QiblaActionMotif.breath,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(
                          context,
                        ).pushNamed(QiblaHubRoutes.breathing);
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

    Widget diamond({
      required double size,
      required double alpha,
      bool glow = false,
    }) {
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
    required this.title,
    required this.subtitle,
    required this.motif,
    required this.onTap,
    this.locked = false,
  });

  final bool onDark;
  final Color accent;
  final String title;
  final String subtitle;
  final _QiblaActionMotif motif;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final bronze = _QiblaWarm.bronze(onDark);
    final bronzeSoft = _QiblaWarm.bronzeSoft(onDark);
    final titleC = onDark
        ? Colors.white.withValues(alpha: 0.95)
        : AppColors.emeraldDark;
    final subC = onDark
        ? Colors.white.withValues(alpha: 0.68)
        : AppColors.emeraldDark.withValues(alpha: 0.78);
    // Sınır artık saf yeşil değil; bronza doğru hafifçe harmanlanıyor.
    final borderC = Color.lerp(
      accent,
      bronze,
      0.3,
    )!.withValues(alpha: onDark ? 0.5 : 0.55);

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
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
                border: Border.all(
                  color: borderC,
                  width: _QiblaHubCardStyle.borderW,
                ),
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
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CardMotifPatternPainter(
                          motif: motif,
                          green: accent,
                          bronze: bronze,
                          onDark: onDark,
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
                          child: _QiblaToolGlyph(
                            motif: motif,
                            onDark: onDark,
                            bronze: bronze,
                          ),
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
                                        borderRadius: BorderRadius.circular(
                                          1.5,
                                        ),
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
                                  if (locked) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 15,
                                      color: AppColors.goldAccent.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ],
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
                              // İç aksiyon kapsülü kaldırıldı. Bu boşluk yalnızca
                              // kartların önceki dış yüksekliğini korur.
                              const SizedBox(
                                height:
                                    _QiblaHubCardStyle.formerActionSlotHeight,
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
        ),
      ),
    );
  }
}

class _QiblaToolGlyph extends StatelessWidget {
  const _QiblaToolGlyph({
    required this.motif,
    required this.onDark,
    required this.bronze,
  });

  final _QiblaActionMotif motif;
  final bool onDark;
  final Color bronze;

  @override
  Widget build(BuildContext context) {
    if (motif == _QiblaActionMotif.tasbeeh) {
      return const ZikirmatikSilhouetteIcon(size: 30);
    }
    if (motif == _QiblaActionMotif.ai) {
      return Icon(
        Icons.auto_awesome_rounded,
        size: 28,
        color: onDark ? Colors.white : AppColors.emeraldDark,
      );
    }

    return CustomPaint(
      size: const Size.square(36),
      painter: _QiblaToolGlyphPainter(
        motif: motif,
        primary: onDark ? Colors.white : AppColors.emeraldDark,
        bronze: bronze,
      ),
    );
  }
}

class _QiblaToolGlyphPainter extends CustomPainter {
  const _QiblaToolGlyphPainter({
    required this.motif,
    required this.primary,
    required this.bronze,
  });

  final _QiblaActionMotif motif;
  final Color primary;
  final Color bronze;

  @override
  void paint(Canvas canvas, Size size) {
    final primaryStroke = Paint()
      ..color = primary.withValues(alpha: 0.94)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bronzeStroke = Paint()
      ..color = bronze.withValues(alpha: 0.96)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final primaryFill = Paint()
      ..color = primary.withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;
    final bronzeFill = Paint()
      ..color = bronze.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;

    switch (motif) {
      case _QiblaActionMotif.compass:
        const center = Offset(18, 18);
        canvas.drawCircle(center, 11, primaryStroke);
        for (final tick in const [
          (Offset(18, 5), Offset(18, 8)),
          (Offset(18, 28), Offset(18, 31)),
          (Offset(5, 18), Offset(8, 18)),
          (Offset(28, 18), Offset(31, 18)),
        ]) {
          canvas.drawLine(tick.$1, tick.$2, bronzeStroke);
        }
        final northNeedle = Path()
          ..moveTo(18, 8.7)
          ..lineTo(21.2, 18.8)
          ..lineTo(18, 17)
          ..lineTo(14.8, 18.8)
          ..close();
        final southNeedle = Path()
          ..moveTo(18, 27.3)
          ..lineTo(14.8, 17.2)
          ..lineTo(18, 19)
          ..lineTo(21.2, 17.2)
          ..close();
        canvas.drawPath(northNeedle, bronzeFill);
        canvas.drawPath(southNeedle, primaryFill);
        canvas.drawCircle(center, 1.45, bronzeFill);

      case _QiblaActionMotif.tasbeeh:
        return;

      case _QiblaActionMotif.breath:
        final upper = Path()
          ..moveTo(5.5, 11)
          ..cubicTo(10, 7.5, 15, 8.8, 19.3, 11)
          ..cubicTo(23.2, 13, 28.6, 12.8, 30.2, 9.8)
          ..cubicTo(31.8, 6.9, 28.2, 5.2, 26, 7);
        final middle = Path()
          ..moveTo(4.5, 18)
          ..cubicTo(10.2, 14.7, 15.2, 16.3, 19.6, 18)
          ..cubicTo(24, 19.7, 28.2, 19.6, 30.8, 17.2);
        final lower = Path()
          ..moveTo(7, 25)
          ..cubicTo(11.6, 22.2, 16.5, 23.1, 20.2, 25)
          ..cubicTo(23.4, 26.7, 27.8, 27.2, 29.5, 24.4)
          ..cubicTo(31.2, 21.7, 27.8, 20.2, 25.8, 22);
        canvas.drawPath(upper, primaryStroke);
        canvas.drawPath(middle, bronzeStroke);
        canvas.drawPath(lower, primaryStroke);
        canvas.drawCircle(const Offset(5.1, 18), 1.35, bronzeFill);

      case _QiblaActionMotif.prayer:
        final leftHand = Path()
          ..moveTo(6.5, 22.5)
          ..cubicTo(9.5, 27.5, 14.4, 29, 17.8, 23.2)
          ..lineTo(17.8, 13.2)
          ..cubicTo(17.8, 10.8, 15.2, 10.4, 14.5, 12.8)
          ..lineTo(12.7, 19.2);
        final rightHand = Path()
          ..moveTo(29.5, 22.5)
          ..cubicTo(26.5, 27.5, 21.6, 29, 18.2, 23.2)
          ..lineTo(18.2, 13.2)
          ..cubicTo(18.2, 10.8, 20.8, 10.4, 21.5, 12.8)
          ..lineTo(23.3, 19.2);
        canvas.drawPath(leftHand, primaryStroke);
        canvas.drawPath(rightHand, primaryStroke);
        final heart = Path()
          ..moveTo(18, 10.7)
          ..cubicTo(14.7, 7.1, 10.7, 11.8, 18, 17.4)
          ..cubicTo(25.3, 11.8, 21.3, 7.1, 18, 10.7)
          ..close();
        canvas.drawPath(heart, bronzeStroke);

      case _QiblaActionMotif.frequency:
        const bars = [
          (8.0, 13.0, 23.0),
          (13.0, 9.0, 27.0),
          (18.0, 5.0, 31.0),
          (23.0, 10.0, 26.0),
          (28.0, 13.0, 23.0),
        ];
        for (var i = 0; i < bars.length; i++) {
          final bar = bars[i];
          canvas.drawLine(
            Offset(bar.$1, bar.$2),
            Offset(bar.$1, bar.$3),
            i == 1 || i == 3 ? bronzeStroke : primaryStroke,
          );
        }
        canvas.drawCircle(const Offset(18, 18), 2.1, bronzeFill);

      case _QiblaActionMotif.hilal:
        final outer = Path()..addOval(const Rect.fromLTWH(8, 6, 20, 24));
        canvas.drawPath(outer, bronzeStroke);
        final innerCut = Path()..addOval(const Rect.fromLTWH(14.5, 8, 16, 20));
        canvas.drawPath(innerCut, primaryStroke);
        canvas.drawCircle(const Offset(24.5, 11.5), 1.6, bronzeFill);

      case _QiblaActionMotif.ai:
        return;
    }
  }

  @override
  bool shouldRepaint(covariant _QiblaToolGlyphPainter oldDelegate) {
    return oldDelegate.motif != motif ||
        oldDelegate.primary != primary ||
        oldDelegate.bronze != bronze;
  }
}

/// Kartın tamamına düşük opaklıklı, rahatsız etmeyen tematik izler serpiştirir.
class _CardMotifPatternPainter extends CustomPainter {
  const _CardMotifPatternPainter({
    required this.motif,
    required this.green,
    required this.bronze,
    required this.onDark,
  });

  final _QiblaActionMotif motif;
  final Color green;
  final Color bronze;
  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final placements = <(Offset, double)>[
      (Offset(size.width * 0.08, size.height * 0.2), 0.52),
      (Offset(size.width * 0.92, size.height * 0.2), 0.52),
      (Offset(size.width * 0.23, size.height * 0.7), 0.68),
      (Offset(size.width * 0.77, size.height * 0.7), 0.68),
      (Offset(size.width * 0.39, size.height * 0.18), 0.58),
      (Offset(size.width * 0.61, size.height * 0.18), 0.58),
      (Offset(size.width * 0.5, size.height * 0.72), 0.76),
    ];

    for (final placement in placements) {
      canvas.save();
      canvas.translate(placement.$1.dx, placement.$1.dy);
      canvas.scale(placement.$2);
      canvas.translate(-13.5, -8);
      _paintMotif(canvas, const Size(27, 16));
      canvas.restore();
    }
  }

  void _paintMotif(Canvas canvas, Size size) {
    final greenPaint = Paint()
      ..color = green.withValues(alpha: onDark ? 0.1 : 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bronzePaint = Paint()
      ..color = bronze.withValues(alpha: onDark ? 0.13 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (motif) {
      case _QiblaActionMotif.compass:
        final center = Offset(size.width / 2, size.height / 2);
        canvas.drawCircle(center, 6.2, greenPaint);
        final needle = Path()
          ..moveTo(center.dx + 1.4, center.dy - 4.7)
          ..lineTo(center.dx - 0.7, center.dy + 1.2)
          ..lineTo(center.dx - 3.9, center.dy + 3.4);
        canvas.drawPath(needle, bronzePaint);
        canvas.drawCircle(
          center,
          1.15,
          Paint()..color = bronze.withValues(alpha: onDark ? 0.14 : 0.11),
        );

      case _QiblaActionMotif.tasbeeh:
        final thread = Path()
          ..moveTo(3.5, 9.5)
          ..cubicTo(7, 2.2, 19.5, 2.2, 23.2, 9.2)
          ..cubicTo(21.5, 13.2, 17.2, 14.1, 13.5, 14);
        canvas.drawPath(thread, greenPaint);
        final beadPaint = Paint()
          ..color = bronze.withValues(alpha: onDark ? 0.14 : 0.11);
        for (final bead in const [
          Offset(6.2, 6.4),
          Offset(10.5, 4.2),
          Offset(15.3, 4.1),
          Offset(19.7, 6.2),
        ]) {
          canvas.drawCircle(bead, 1.55, beadPaint);
        }
        canvas.drawLine(
          const Offset(13.5, 13.2),
          const Offset(13.5, 15.3),
          bronzePaint,
        );

      case _QiblaActionMotif.breath:
        for (var i = 0; i < 3; i++) {
          final y = 4.5 + i * 3.5;
          final wave = Path()
            ..moveTo(2.5, y)
            ..cubicTo(7, y - 2.8, 9.8, y + 2.8, 14, y)
            ..cubicTo(18, y - 2.5, 21.2, y + 1.8, 24.5, y);
          canvas.drawPath(wave, i == 1 ? bronzePaint : greenPaint);
        }

      case _QiblaActionMotif.prayer:
        final left = Path()
          ..moveTo(3.5, 10.8)
          ..cubicTo(7.2, 15.1, 11.4, 15.4, 13.3, 10.1)
          ..lineTo(13.3, 4.2);
        final right = Path()
          ..moveTo(23.5, 10.8)
          ..cubicTo(19.8, 15.1, 15.6, 15.4, 13.7, 10.1)
          ..lineTo(13.7, 4.2);
        canvas.drawPath(left, greenPaint);
        canvas.drawPath(right, greenPaint);
        final heart = Path()
          ..moveTo(13.5, 5.8)
          ..cubicTo(10.8, 2.7, 8.2, 6.4, 13.5, 10.2)
          ..cubicTo(18.8, 6.4, 16.2, 2.7, 13.5, 5.8);
        canvas.drawPath(heart, bronzePaint);

      case _QiblaActionMotif.frequency:
        const heights = [5.0, 10.0, 14.0, 8.0, 12.0, 6.0];
        for (var i = 0; i < heights.length; i++) {
          final x = 3.5 + i * 4;
          final half = heights[i] / 2;
          canvas.drawLine(
            Offset(x, size.height / 2 - half),
            Offset(x, size.height / 2 + half),
            i.isEven ? greenPaint : bronzePaint,
          );
        }

      case _QiblaActionMotif.hilal:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.48, size.height * 0.5),
            width: 12,
            height: 14,
          ),
          bronzePaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.58, size.height * 0.45),
            width: 10,
            height: 12,
          ),
          greenPaint,
        );

      case _QiblaActionMotif.ai:
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.45),
          3.2,
          bronzePaint,
        );
        canvas.drawCircle(
          Offset(size.width * 0.72, size.height * 0.28),
          1.6,
          greenPaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CardMotifPatternPainter oldDelegate) {
    return oldDelegate.motif != motif ||
        oldDelegate.green != green ||
        oldDelegate.bronze != bronze ||
        oldDelegate.onDark != onDark;
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: bronze.withValues(alpha: onDark ? 0.16 : 0.13),
                width: 0.8,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
