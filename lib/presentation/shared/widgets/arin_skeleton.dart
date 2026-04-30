// lib/presentation/shared/widgets/arin_skeleton.dart
//
// Shimmer skeleton yer tutucu — `CircularProgressIndicator` yerine içerik
// yüklenirken daha "premium" his veren, kartın kendi şekline uyumlu
// parıldayan gri/koyu yüzey. Shimmer paketine bağımlılık yok; saf Flutter
// `AnimationController` + `ShaderMask` ile üretiliyor.
//
// Kullanım örnekleri:
//   ArinSkeleton(height: 16, width: 220)           // tek satır (metin)
//   ArinSkeleton(height: 120, borderRadius: 16)    // kart
//   ArinSkeletonCircle(diameter: 56)               // avatar / simge
//   ArinSkeletonList(itemHeight: 64, count: 5)     // liste satırları
//
// Renkler tema-duyarlı: koyu modda koyu gri yüzey + hafif beyaz parıltı;
// açık modda açık krem yüzey + koyu parıltı.

import 'package:flutter/material.dart';

import '../../../core/constants/app_radii.dart';

/// Tek bir kutu/satır yer tutucu.
class ArinSkeleton extends StatefulWidget {
  const ArinSkeleton({
    super.key,
    this.height = 14,
    this.width,
    this.borderRadius = AppRadii.xs,
    this.margin,
  });

  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  State<ArinSkeleton> createState() => _ArinSkeletonState();
}

class _ArinSkeletonState extends State<ArinSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final base = onDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final highlight = onDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.14);

    return Container(
      height: widget.height,
      width: widget.width,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              // -1.0 → 2.0 aralığında kayan diagonal parıltı bandı.
              final t = _ctrl.value;
              return LinearGradient(
                begin: Alignment(-1.0 + t * 3.0, -0.3),
                end: Alignment(0.0 + t * 3.0, 0.3),
                colors: [base, highlight, base],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(rect);
            },
            child: Container(color: base),
          );
        },
      ),
    );
  }
}

/// Yuvarlak (avatar / ikon) yer tutucu.
class ArinSkeletonCircle extends StatelessWidget {
  const ArinSkeletonCircle({super.key, required this.diameter, this.margin});

  final double diameter;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return ArinSkeleton(
      height: diameter,
      width: diameter,
      borderRadius: diameter / 2,
      margin: margin,
    );
  }
}

/// Liste tipi içerik için hazır satır şablonu. `count` kadar satır çizer;
/// her satır solda yuvarlak ikon + sağda iki metin çizgisi içerir.
class ArinSkeletonList extends StatelessWidget {
  const ArinSkeletonList({
    super.key,
    this.count = 4,
    this.itemHeight = 64,
    this.spacing = 12,
    this.leadingCircle = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final int count;
  final double itemHeight;
  final double spacing;
  final bool leadingCircle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++) ...[
            SizedBox(
              height: itemHeight,
              child: Row(
                children: [
                  if (leadingCircle) ...[
                    ArinSkeletonCircle(diameter: itemHeight * 0.72),
                    const SizedBox(width: 14),
                  ],
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ArinSkeleton(height: 14, width: double.infinity),
                        SizedBox(height: 8),
                        ArinSkeleton(height: 12, width: 140),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < count - 1) SizedBox(height: spacing),
          ],
        ],
      ),
    );
  }
}

/// Kart şablonu — küçük detay tutarlılığı için.
class ArinSkeletonCard extends StatelessWidget {
  const ArinSkeletonCard({
    super.key,
    this.height = 140,
    this.borderRadius = AppRadii.md,
    this.padding = const EdgeInsets.all(14),
  });

  final double height;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ArinSkeleton(
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }
}
