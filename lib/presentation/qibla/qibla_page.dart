// lib/presentation/qibla/qibla_page.dart
//
// Tasarım: app visual language'ına entegre koyu kokpit estetiği.
//   • ArinShellBackground ile tüm uygulama ile tutarlı zemin.
//   • AppColors ile tema adaptasyonu (açık / koyu).
//
// Performans mimarisi:
//   • Hiçbir sensör güncellemesi setState çağırmaz.
//   • ValueNotifier + ValueListenableBuilder — minimal subtree rebuild.
//   • RepaintBoundary DIŞARIDA, Transform.rotate içeride → GPU compositing.
//   • CustomPainter yalnızca qiblaBearing değişince repaint eder.
//   • Painter'da blur / gradient / MaskFilter yok — düz renkler.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../data/services/qibla_compass_controller.dart';
import '../shared/widgets/arin_back_button.dart';

import 'package:arin/l10n/app_localizations.dart';

// ─── Painter renk sabitleri (dark canvas için) ───────────────────────────────
const _tickNorth  = Color(0xFFF87171);         // kuzey kırmızı
const _tickDim    = Color(0x59FFFFFF);          // beyaz %35
const _textDim    = Color(0x8CFFFFFF);          // beyaz %55

// ─── Hizalanma eşikleri (hysteresis) ────────────────────────────────────────
const _alignInDeg  = 5.0;
const _alignOutDeg = 9.0;

// ────────────────────────────────────────────────────────────────────────────

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key, this.exitToHomeOnBack = false});

  final bool exitToHomeOnBack;

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  final _dialAngle = ValueNotifier<double>(0);
  final _qiblaDeg  = ValueNotifier<double>(0);
  final _deltaDeg  = ValueNotifier<double>(0);
  final _aligned   = ValueNotifier<bool>(false);
  final _hasData   = ValueNotifier<bool>(false);
  final _hasError  = ValueNotifier<bool>(false);
  final _stable    = ValueNotifier<bool>(true);
  final _guidance  = ValueNotifier<QiblaGuidance>(QiblaGuidance.good);

  double? _contAngle;
  double? _smoothAngle;
  bool    _prevAligned = false;

  QiblaCompassController?                  _compass;
  StreamSubscription<QiblaSensorReading>?  _sub;

  @override
  void initState() {
    super.initState();
    _launch();
  }

  void _launch() {
    final c = QiblaCompassController();
    _compass = c;
    c.start().then((ok) {
      if (!mounted || _compass != c) return;
      if (ok) {
        _sub = c.stream.listen(
          _onReading,
          onError: (_) { if (mounted) _hasError.value = true; },
        );
      } else {
        if (mounted) _hasError.value = true;
      }
    });
  }

  void _restart() {
    _sub?.cancel();
    _sub = null;
    _compass?.dispose();
    _compass        = null;
    _contAngle      = null;
    _smoothAngle    = null;
    _prevAligned    = false;
    _hasData.value  = false;
    _hasError.value = false;
    _stable.value   = true;
    _guidance.value = QiblaGuidance.good;
    _aligned.value  = false;
    _deltaDeg.value = 0;
    _launch();
  }

  // ── Hot path — setState YOK ──────────────────────────────────────────────

  void _onReading(QiblaSensorReading r) {
    if (!mounted) return;

    final h = r.heading        % 360;
    final q = r.qiblaFromNorth % 360;

    // Sürekli açı — 0/360 sıçramasını önler.
    final rad = h * math.pi / 180;
    if (_contAngle == null) {
      _contAngle = rad;
    } else {
      var d = rad - _contAngle! % (2 * math.pi);
      if (d >  math.pi) d -= 2 * math.pi;
      if (d < -math.pi) d += 2 * math.pi;
      _contAngle = _contAngle! + d;
    }

    // Adaptive EMA — küçük titremede ağır filtre, hızlı dönüşte hızlı takip.
    if (_smoothAngle == null) {
      _smoothAngle = _contAngle!;
    } else {
      final stepDeg = _angleDeltaDeg(
        _contAngle! * 180 / math.pi,
        _smoothAngle! * 180 / math.pi,
      );
      final alpha = stepDeg > 28
          ? 0.56
          : (stepDeg > 10 ? 0.34 : 0.10);
      _smoothAngle = alpha * _contAngle! + (1 - alpha) * _smoothAngle!;
    }

    final smoothHeadingDeg = _normalizeDeg(_smoothAngle! * 180 / math.pi);
    final delta = _angleDeltaDeg(q, smoothHeadingDeg);
    final canAlign = r.stable && r.guidance == QiblaGuidance.good;
    final nowAligned = canAlign && (_prevAligned
        ? delta <= _alignOutDeg
        : delta <= _alignInDeg);

    if (nowAligned && nowAligned != _prevAligned) {
      HapticFeedback.selectionClick();
    }
    _prevAligned = nowAligned;

    _dialAngle.value = _smoothAngle!;
    _qiblaDeg.value  = q;
    _deltaDeg.value  = delta;
    _aligned.value   = nowAligned;
    _stable.value    = r.stable;
    _guidance.value  = r.guidance;
    if (!_hasData.value) _hasData.value = true;
  }

  double _angleDeltaDeg(double a, double b) {
    final raw = (a - b).abs();
    return raw > 180 ? 360 - raw : raw;
  }

  double _normalizeDeg(double value) {
    final normalized = value % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _compass?.dispose();
    _dialAngle.dispose();
    _qiblaDeg.dispose();
    _deltaDeg.dispose();
    _aligned.dispose();
    _hasData.dispose();
    _hasError.dispose();
    _stable.dispose();
    _guidance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArinShellBackground.buildLayered(
        context,
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                qiblaDeg:         _qiblaDeg,
                hasData:          _hasData,
                exitToHomeOnBack: widget.exitToHomeOnBack,
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder<bool>(
      valueListenable: _hasError,
      builder: (_, hasError, __) {
        if (hasError) return _ErrorView(onRetry: _restart);
        return ValueListenableBuilder<bool>(
          valueListenable: _hasData,
          builder: (_, hasData, __) {
            if (!hasData) return const _LoadingView();
            return _CompassView(
              dialAngle: _dialAngle,
              qiblaDeg:  _qiblaDeg,
              deltaDeg:  _deltaDeg,
              aligned:   _aligned,
              stable:    _stable,
              guidance:  _guidance,
            );
          },
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Üst bar
// ────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.qiblaDeg,
    required this.hasData,
    required this.exitToHomeOnBack,
  });

  final ValueNotifier<double> qiblaDeg;
  final ValueNotifier<bool>   hasData;
  final bool                  exitToHomeOnBack;

  @override
  Widget build(BuildContext context) {
    final canGoBack = context.canPop() || exitToHomeOnBack;
    final light     = ArinShellBackground.isLight(context);

    final dimColor = light
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.55);
    final btnBg = light
        ? AppColors.emeraldFaint.withValues(alpha: 0.50)
        : Colors.white.withValues(alpha: 0.07);
    final btnBorder = light
        ? AppColors.emeraldMid.withValues(alpha: 0.30)
        : Colors.white.withValues(alpha: 0.13);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          if (canGoBack)
            ArinBackButton(
              onPressed: () {
                if (exitToHomeOnBack) {
                  context.go(AppRoutes.home);
                } else {
                  context.pop();
                }
              },
            )
          else
            const SizedBox(width: 38),

          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: hasData,
              builder: (_, got, __) => ValueListenableBuilder<double>(
                valueListenable: qiblaDeg,
                builder: (_, deg, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.qiblaCompassTitle,
                      style: TextStyle(
                        color: light
                            ? AppColors.emeraldDark
                            : Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (got) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${AppLocalizations.of(context)!.qiblaCompassQibla}: ${deg.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          color: AppColors.accentNeonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Yüklenme
// ────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              color: AppColors.accentNeonGreen,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppLocalizations.of(context)!.qiblaCompassGettingLocation,
            style: TextStyle(
              color: light
                  ? AppColors.textSecondary
                  : Colors.white.withValues(alpha: 0.40),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Hata
// ────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final textColor = light
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.60);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gps_off_rounded,
              size: 44,
              color: light
                  ? AppColors.textMuted
                  : Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.qiblaCompassInitError,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onRetry();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.qiblaCompassRetry,
                  style: TextStyle(
                    color: AppColors.accentNeonGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Pusula + hizalanma badge
// ────────────────────────────────────────────────────────────────────────────

class _CompassView extends StatelessWidget {
  const _CompassView({
    required this.dialAngle,
    required this.qiblaDeg,
    required this.deltaDeg,
    required this.aligned,
    required this.stable,
    required this.guidance,
  });

  final ValueNotifier<double> dialAngle;
  final ValueNotifier<double> qiblaDeg;
  final ValueNotifier<double> deltaDeg;
  final ValueNotifier<bool>   aligned;
  final ValueNotifier<bool>   stable;
  final ValueNotifier<QiblaGuidance> guidance;

  @override
  Widget build(BuildContext context) {
    final light     = ArinShellBackground.isLight(context);
    final ringColor = light
        ? AppColors.emeraldMid.withValues(alpha: 0.60)
        : const Color(0xFF1A3028);

    return Column(
      children: [
        const Spacer(),

        // ── Pusula kadranı ────────────────────────────────────────────────
        Expanded(
          flex: 8,
          child: Center(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final size = constraints.biggest.shortestSide * 0.88;

                // RepaintBoundary DIŞARIDA — GPU layer oluşturulur.
                // Transform.rotate yalnızca matrix değiştirir; repaint olmaz.
                return RepaintBoundary(
                  child: ValueListenableBuilder<double>(
                    valueListenable: dialAngle,
                    builder: (_, angle, child) => Transform.rotate(
                      angle: -angle,
                      child: child,
                    ),
                    child: ValueListenableBuilder<double>(
                      valueListenable: qiblaDeg,
                      builder: (_, deg, __) => CustomPaint(
                        size: Size(size, size),
                        painter: _CompassPainter(
                          qiblaBearingDeg: deg,
                          ringColor:       ringColor,
                          light:           light,
                          context:         context,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
          child: ListenableBuilder(
            listenable: Listenable.merge([stable, guidance]),
            builder: (_, __) => _GuidanceCard(
              stable: stable.value,
              guidance: guidance.value,
            ),
          ),
        ),

        // ── Hizalanma badge ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 36),
          child: ListenableBuilder(
            listenable: Listenable.merge([aligned, deltaDeg, stable, guidance]),
            builder: (_, __) {
              final isAligned = aligned.value;
              final delta     = deltaDeg.value;
              final isStable  = stable.value &&
                  guidance.value == QiblaGuidance.good;

              final bgAligned  = AppColors.accentNeonGreen.withValues(alpha: light ? 0.14 : 0.10);
              final bgDefault  = light
                  ? AppColors.emeraldFaint.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.04);
              final bdrAligned = AppColors.accentNeonGreen.withValues(alpha: 0.50);
              final bdrDefault = light
                  ? AppColors.emeraldMid.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.10);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color:         isAligned ? bgAligned : bgDefault,
                  borderRadius:  BorderRadius.circular(28),
                  border:        Border.all(
                    color: isAligned ? bdrAligned : bdrDefault,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAligned) ...[
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.accentNeonGreen,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isAligned
                          ? AppLocalizations.of(context)!.qiblaCompassAligned
                          : (isStable
                              ? '${delta.toStringAsFixed(1)}° ${AppLocalizations.of(context)!.qiblaCompassDeviation}'
                              : AppLocalizations.of(context)!.qiblaCompassStabilizing),
                      style: TextStyle(
                        color: isAligned
                            ? AppColors.accentNeonGreen
                            : (light
                                ? AppColors.textSecondary
                                : Colors.white.withValues(alpha: 0.50)),
                        fontSize: 14,
                        fontWeight:
                            isAligned ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.stable,
    required this.guidance,
  });

  final bool stable;
  final QiblaGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    final config = _configFor(context, guidance);
    final isGood = stable && guidance == QiblaGuidance.good;
    final accent = isGood ? AppColors.accentNeonGreen : config.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: light
            ? accent.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: isGood ? 0.035 : 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config.icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config.title,
                  style: TextStyle(
                    color: light
                        ? AppColors.emeraldDark
                        : Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  config.body,
                  style: TextStyle(
                    color: light
                        ? AppColors.textSecondary
                        : Colors.white.withValues(alpha: 0.58),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _GuidanceConfig _configFor(BuildContext context, QiblaGuidance guidance) {
    final l10n = AppLocalizations.of(context)!;
    return switch (guidance) {
      QiblaGuidance.tilt => _GuidanceConfig(
          icon: Icons.screen_rotation_alt_rounded,
          color: AppColors.warning,
          title: l10n.qiblaCompassGuidanceTiltTitle,
          body: l10n.qiblaCompassGuidanceTiltBody,
        ),
      QiblaGuidance.calibrate => _GuidanceConfig(
          icon: Icons.explore_off_rounded,
          color: AppColors.warning,
          title: l10n.qiblaCompassGuidanceCalibrateTitle,
          body: l10n.qiblaCompassGuidanceCalibrateBody,
        ),
      QiblaGuidance.unstable => _GuidanceConfig(
          icon: Icons.sensors_off_rounded,
          color: AppColors.warning,
          title: l10n.qiblaCompassGuidanceUnstableTitle,
          body: l10n.qiblaCompassGuidanceUnstableBody,
        ),
      QiblaGuidance.good => _GuidanceConfig(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.accentNeonGreen,
          title: l10n.qiblaCompassGuidanceGoodTitle,
          body: l10n.qiblaCompassGuidanceGoodBody,
        ),
    };
  }
}

class _GuidanceConfig {
  const _GuidanceConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

// ────────────────────────────────────────────────────────────────────────────
// CustomPainter — pusula kadranı
//
// shouldRepaint: yalnızca qiblaBearingDeg veya ringColor değişince.
// Transform.rotate GPU katmanında; painter nadiren çağrılır.
// ────────────────────────────────────────────────────────────────────────────

class _CompassPainter extends CustomPainter {
  const _CompassPainter({
    required this.qiblaBearingDeg,
    required this.ringColor,
    required this.light,
    required this.context,
  });

  final double qiblaBearingDeg;
  final Color  ringColor;
  final bool   light;
  final BuildContext context;

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.qiblaBearingDeg != qiblaBearingDeg ||
      old.ringColor       != ringColor        ||
      old.light           != light ||
      old.context         != context;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    _drawRing(canvas, c, r);
    _drawTicks(canvas, c, r);
    _drawQiblaArrow(canvas, c, r);
    _drawCenter(canvas, c);
  }

  void _drawRing(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..color       = ringColor
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawTicks(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 72; i++) {
      final deg    = i * 5.0;
      final rad    = deg * math.pi / 180;
      final isNorth = i == 0;
      final isCard  = i % 18 == 0;
      final isMajor = i % 6 == 0;

      final outer = r - 3.0;
      final len   = isCard ? 16.0 : (isMajor ? 11.0 : 5.5);
      final sw    = isCard ? 2.0  : (isMajor ? 1.2  : 0.9);

      final tickColor = isNorth
          ? _tickNorth
          : (light
              ? AppColors.emeraldMid.withValues(alpha: 0.55)
              : _tickDim);

      final sinA = math.sin(rad);
      final cosA = math.cos(rad);

      canvas.drawLine(
        Offset(c.dx + outer         * sinA, c.dy - outer         * cosA),
        Offset(c.dx + (outer - len) * sinA, c.dy - (outer - len) * cosA),
        Paint()
          ..color       = tickColor
          ..strokeWidth = sw
          ..strokeCap   = StrokeCap.round,
      );

      if (isCard) {
        final label = switch (i) {
          0  => AppLocalizations.of(context)!.qiblaCompassNorth,
          18 => AppLocalizations.of(context)!.qiblaCompassEast,
          36 => AppLocalizations.of(context)!.qiblaCompassSouth,
          54 => AppLocalizations.of(context)!.qiblaCompassWest,
          _  => '',
        };
        final lr = outer - len - 13.0;
        _text(
          canvas,
          label,
          Offset(c.dx + lr * sinA, c.dy - lr * cosA),
          color: isNorth
              ? _tickNorth
              : (light ? AppColors.emeraldDark : _textDim),
          size: 11,
        );
      }
    }
  }

  void _drawQiblaArrow(Canvas canvas, Offset c, double r) {
    final rad  = qiblaBearingDeg * math.pi / 180;
    final sinA = math.sin(rad);
    final cosA = math.cos(rad);

    final tipR  = r - 20.0;
    final baseR = r * 0.28;

    final tip  = Offset(c.dx + tipR  * sinA, c.dy - tipR  * cosA);
    final base = Offset(c.dx + baseR * sinA, c.dy - baseR * cosA);

    const hw    = 7.0;
    final left  = Offset(base.dx - hw * cosA, base.dy + hw * sinA);
    final right = Offset(base.dx + hw * cosA, base.dy - hw * sinA);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx,  left.dy)
      ..lineTo(base.dx,  base.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    final arrowColor = light
        ? AppColors.emeraldBase
        : AppColors.accentNeonGreen;

    canvas.drawPath(path, Paint()..color = arrowColor);

    final lbR = tipR - 15.0;
    _text(
      canvas,
      AppLocalizations.of(context)!.qiblaCompassQiblaText,
      Offset(c.dx + lbR * sinA, c.dy - lbR * cosA),
      color: arrowColor,
      size: 8.5,
    );
  }

  void _drawCenter(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c,
      5.0,
      Paint()..color = light
          ? AppColors.emeraldDark.withValues(alpha: 0.90)
          : Colors.white.withValues(alpha: 0.88),
    );
    canvas.drawCircle(
      c,
      2.5,
      Paint()..color = light
          ? const Color(0xFFDAD4C9)
          : const Color(0xFF050A07),
    );
  }

  void _text(
    Canvas canvas,
    String label,
    Offset center, {
    required Color  color,
    required double size,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color:         color,
          fontSize:      size,
          fontWeight:    FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
