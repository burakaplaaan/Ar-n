part of 'breathing_exercise_page.dart';

class _BreathingGlassPanel extends StatelessWidget {
  const _BreathingGlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFFFFF).withValues(alpha: 0.16),
                const Color(0xFFFFFFFF).withValues(alpha: 0.05),
                const Color(0xFF4ADE80).withValues(alpha: 0.04),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _IntroMetaChip extends StatelessWidget {
  const _IntroMetaChip({
    required this.icon,
    required this.label,
    required this.mint,
  });

  final IconData icon;
  final String label;
  final Color mint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: mint.withValues(alpha: 0.88)),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.creamBase.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPhaseHint extends StatelessWidget {
  const _IntroPhaseHint({
    required this.n,
    required this.caption,
    required this.accent,
  });

  final int n;
  final String caption;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Text(
            '$n',
            style: AppTextStyles.displayMedium.copyWith(
              color: accent.withValues(alpha: 0.9),
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.creamBase.withValues(alpha: 0.5),
              height: 1.15,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuroraBreathVisual extends StatelessWidget {
  const _AuroraBreathVisual({
    required this.breathScale,
    required this.rotation,
    required this.pulseT,
    required this.palette,
    required this.isIdle,
  });

  final double breathScale;
  final double rotation;
  final double pulseT;
  final ({Color a, Color b, Color c}) palette;
  final bool isIdle;

  @override
  Widget build(BuildContext context) {
    final s = breathScale.clamp(0.78, 1.88);
    return SizedBox(
      width: 340,
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: const Size(340, 340),
            painter: _SacredGeometryPainter(
              rotation: rotation,
              accent: palette.a,
              secondary: palette.b,
              breathScale: s,
              pulseT: pulseT,
              isIdle: isIdle,
            ),
          ),
          Transform.scale(
            scale: s,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette.a.withValues(alpha: 0.42 + 0.18 * pulseT),
                    blurRadius: 56,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: palette.b.withValues(alpha: 0.28),
                    blurRadius: 80,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          Transform.scale(
            scale: s,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.28),
                    palette.a.withValues(alpha: 0.5),
                    palette.b.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.22, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: s,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22 + 0.14 * pulseT),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SacredGeometryPainter extends CustomPainter {
  _SacredGeometryPainter({
    required this.rotation,
    required this.accent,
    required this.secondary,
    required this.breathScale,
    required this.pulseT,
    required this.isIdle,
  });

  final double rotation;
  final Color accent;
  final Color secondary;
  final double breathScale;
  final double pulseT;
  final bool isIdle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final breathe = 0.94 + 0.12 * (breathScale / 1.65).clamp(0.7, 1.2);
    final r = size.shortestSide * 0.40 * breathe;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    canvas.translate(-c.dx, -c.dy);

    final arcPaintA = Paint()
      ..color = accent.withValues(alpha: isIdle ? 0.14 : 0.18 + 0.06 * pulseT)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final arcPaintB = Paint()
      ..color = secondary.withValues(alpha: isIdle ? 0.12 : 0.22 + 0.1 * pulseT)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 24; i++) {
      final a = i * math.pi * 2 / 24;
      final useA = i % 4 == 0;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 1.06),
        a - 0.12,
        0.24,
        false,
        useA ? arcPaintA : arcPaintB,
      );
    }

    for (var k = 1; k <= 4; k++) {
      canvas.drawCircle(
        c,
        r * (0.32 + k * 0.18),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05 - k * 0.008)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.55,
      );
    }

    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final ang = -math.pi / 2 + i * math.pi / 3;
      final p = c + Offset(math.cos(ang), math.sin(ang)) * r * 0.68;
      if (i == 0) {
        hex.moveTo(p.dx, p.dy);
      } else {
        hex.lineTo(p.dx, p.dy);
      }
    }
    hex.close();
    canvas.drawPath(
      hex,
      Paint()
        ..color = accent.withValues(alpha: 0.14 + 0.06 * pulseT)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05,
    );

    final innerHex = Path();
    for (var i = 0; i < 6; i++) {
      final ang = -math.pi / 2 + math.pi / 6 + i * math.pi / 3;
      final p = c + Offset(math.cos(ang), math.sin(ang)) * r * 0.36;
      if (i == 0) {
        innerHex.moveTo(p.dx, p.dy);
      } else {
        innerHex.lineTo(p.dx, p.dy);
      }
    }
    innerHex.close();
    canvas.drawPath(
      innerHex,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SacredGeometryPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.breathScale != breathScale ||
        oldDelegate.pulseT != pulseT ||
        oldDelegate.isIdle != isIdle;
  }
}
