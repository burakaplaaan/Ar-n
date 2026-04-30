// lib/presentation/shared/widgets/qibla_nav_icon.dart
// Alt bar — Kıble sekmesi (minimal pusula + N işareti).

import 'package:flutter/material.dart';

class QiblaNavIcon extends StatelessWidget {
  const QiblaNavIcon({
    super.key,
    required this.color,
    this.size = 26,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _QiblaNavPainter(color),
      ),
    );
  }
}

class _QiblaNavPainter extends CustomPainter {
  _QiblaNavPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(c, r, stroke);

    // N oku (kuzey — kıble pusulasında klasik)
    final nPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final tip = Offset(c.dx, c.dy - r + 1);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 3.2, tip.dy + 6)
      ..lineTo(tip.dx + 3.2, tip.dy + 6)
      ..close();
    canvas.drawPath(path, nPaint);

    // İbre (merkezden doğu yönüne hafif — pusula okuması)
    canvas.drawLine(
      c,
      Offset(c.dx + r * 0.55, c.dy),
      stroke..strokeWidth = 1.8,
    );
    canvas.drawCircle(c, 1.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _QiblaNavPainter oldDelegate) =>
      oldDelegate.color != color;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
}
