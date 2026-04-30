// lib/presentation/shared/widgets/prayer_times_nav_icon.dart
// Alt bar — namaz vakitleri sekmesi (ev yerine minimal saat + gün yayımı).

import 'package:flutter/material.dart';

class PrayerTimesNavIcon extends StatelessWidget {
  const PrayerTimesNavIcon({
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
        painter: _PrayerTimesNavPainter(color),
      ),
    );
  }
}

class _PrayerTimesNavPainter extends CustomPainter {
  _PrayerTimesNavPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 0.5;
    final r = size.width * 0.34;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round;

    // Üst yay — günün vakitleri / güneş hattı
    final arcCenter = Offset(cx, cy - r * 0.12);
    final arcRect = Rect.fromCircle(center: arcCenter, radius: r * 0.92);
    canvas.drawArc(arcRect, 3.45, 1.25, false, stroke);

    // Kadran
    canvas.drawCircle(Offset(cx, cy), r, stroke);

    // Tek akrep — saat / vakit
    final hand = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.52, cy - r * 0.3),
      hand,
    );

    canvas.drawCircle(Offset(cx, cy), 1.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PrayerTimesNavPainter oldDelegate) =>
      oldDelegate.color != color;
}
