// Ana sayfa kartları için sıcak altın-bronz ("kahve rengi") süsleme katmanı.
//
// Referans tasarımdaki premium his: kartların etrafında çok ince altın
// hairline çerçeve + dört köşede zarif köşe motifleri (L biçimli braket).
// İsteğe bağlı olarak üst-orta noktada küçük bir eşkenar dörtgen (vurgu
// kutuları için) çizilir.
//
// Süsleme tamamen dekoratiftir: `IgnorePointer` ile sarıldığı için altındaki
// `InkWell`/buton dokunuşlarını engellemez. Var olan kart dekorasyonunu
// (gradient, yeşil border, gölge) değiştirmez; üzerine ek bir katman olarak
// biner. Bu sayede her karta tek satırla, davranış riski olmadan uygulanır.

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/arin_shell_background.dart';

class OrnateFrame extends StatelessWidget {
  /// Süslemenin üzerine bineceği kart içeriği. Katman, çocuğun boyutuna göre
  /// (`Stack` non-positioned child) hizalanır.
  final Widget child;

  /// Kartın köşe yarıçapı (kartın kendi `borderRadius` değeriyle aynı olmalı).
  final double borderRadius;

  /// Köşe motiflerinin kenarlardan içeri kaçıklığı.
  final double inset;

  /// Köşe braketlerinin kol uzunluğu.
  final double armLength;

  /// Üst-orta vurgu motifi (küçük eşkenar dörtgen). "Sıradaki vakit" gibi
  /// öne çıkan kutularda kullanılır.
  final bool bottomAccent;

  /// İnce altın hairline çerçeve çizilsin mi (küçük karelerde kapatılır).
  final bool drawBorder;

  /// Süsleme rengini elle vermek için. Boşsa temaya göre seçilir.
  final Color? color;

  const OrnateFrame({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.inset = 7,
    this.armLength = 14,
    this.bottomAccent = false,
    this.drawBorder = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = ArinShellBackground.isLight(context);
    final gold =
        color ?? (isLight ? AppColors.ornamentGoldDeep : AppColors.ornamentGold);
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _OrnateFramePainter(
                radius: borderRadius,
                inset: inset,
                armLength: armLength,
                bottomAccent: bottomAccent,
                drawBorder: drawBorder,
                color: gold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrnateFramePainter extends CustomPainter {
  final double radius;
  final double inset;
  final double armLength;
  final bool bottomAccent;
  final bool drawBorder;
  final Color color;

  _OrnateFramePainter({
    required this.radius,
    required this.inset,
    required this.armLength,
    required this.bottomAccent,
    required this.drawBorder,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Çok küçük kutularda süsleme bindirme yapmasın.
    if (w <= inset * 2 + 4 || h <= inset * 2 + 4) return;

    if (drawBorder) {
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = color.withValues(alpha: 0.30);
      final innerRadius = (radius - inset).clamp(2.0, radius);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
        Radius.circular(innerRadius),
      );
      canvas.drawRRect(rrect, border);
    }

    // En az kenarın yarısını aşmayan kol uzunluğu.
    final a = armLength.clamp(4.0, (w < h ? w : h) / 2 - inset - 2);

    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.85);

    void drawCorner(double x, double y, double dx, double dy) {
      final p = Path()
        ..moveTo(x + dx * a, y)
        ..lineTo(x + dx * (a * 0.3), y)
        ..quadraticBezierTo(x, y, x, y + dy * (a * 0.3))
        ..lineTo(x, y + dy * a);
      canvas.drawPath(p, bracket);
      canvas.drawCircle(Offset(x + dx * a, y), 1.5, Paint()..color = color.withValues(alpha: 0.85));
      canvas.drawCircle(Offset(x, y + dy * a), 1.5, Paint()..color = color.withValues(alpha: 0.85));
    }

    drawCorner(inset, inset, 1, 1); // Üst-sol
    drawCorner(w - inset, inset, -1, 1); // Üst-sağ
    drawCorner(inset, h - inset, 1, -1); // Alt-sol
    drawCorner(w - inset, h - inset, -1, -1); // Alt-sağ

    if (bottomAccent) {
      final cx = w / 2;
      final cy = h - inset;
      const d = 3.2;
      final diamond = Path()
        ..moveTo(cx, cy - d)
        ..lineTo(cx + d, cy)
        ..lineTo(cx, cy + d)
        ..lineTo(cx - d, cy)
        ..close();
      canvas.drawPath(
        diamond,
        Paint()..color = color.withValues(alpha: 0.88),
      );
      final tick = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.5);
      canvas.drawLine(Offset(cx - d - 10, cy), Offset(cx - d - 3, cy), tick);
      canvas.drawLine(Offset(cx + d + 3, cy), Offset(cx + d + 10, cy), tick);
    }
  }

  @override
  bool shouldRepaint(covariant _OrnateFramePainter old) =>
      old.radius != radius ||
      old.inset != inset ||
      old.armLength != armLength ||
      old.bottomAccent != bottomAccent ||
      old.drawBorder != drawBorder ||
      old.color != color;
}
