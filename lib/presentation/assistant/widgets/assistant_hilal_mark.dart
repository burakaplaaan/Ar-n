import 'package:flutter/material.dart';

/// Hilal — yeni ay. Yapay zekâ ikonu değil; sade bir ibadet işareti.
class AssistantHilalMark extends StatelessWidget {
  const AssistantHilalMark({
    super.key,
    this.size = 22,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HilalPainter(color: color),
      ),
    );
  }
}

class _HilalPainter extends CustomPainter {
  const _HilalPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final outer = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(w * 0.50, h * 0.52),
          radius: w * 0.36,
        ),
      );
    final cut = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(w * 0.68, h * 0.42),
          radius: w * 0.30,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, cut),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _HilalPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
