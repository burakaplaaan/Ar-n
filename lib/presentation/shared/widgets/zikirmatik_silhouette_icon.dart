// lib/presentation/shared/widgets/zikirmatik_silhouette_icon.dart
// Kıble araçları kartı vb.: tasbeeh_counter ile aynı SVG gövde (küçük önizleme).

import 'package:flutter/material.dart';

import 'tasbeeh_zikirmatik_device_frame.dart';

/// Light tema: `primaryLightColor` + `tasbeehCounterColor` ([tasbeeh_counter](https://github.com/n4ff4h/tasbeeh_counter)).
class ZikirmatikSilhouetteIcon extends StatelessWidget {
  const ZikirmatikSilhouetteIcon({
    super.key,
    this.size = 52,
  });

  /// Gövde yüksekliği; genişlik SVG en-boy oranına göre.
  final double size;

  static const Color _outer = Color(0xFF89ABAA);
  static const Color _inner = Color(0xFF4B5E5E);

  @override
  Widget build(BuildContext context) {
    final h = size;
    final w = h * TasbeehZikirmatikLayout.widthOverHeight;
    return SizedBox(
      width: w,
      height: h,
      child: const TasbeehZikirmatikDeviceFrame(
        outerColor: _outer,
        innerColor: _inner,
        child: null,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
