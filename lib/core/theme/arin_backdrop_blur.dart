import 'dart:ui';

import 'package:flutter/material.dart';

/// Cam/blur katmanını ata rebuild'lerinden ayırır; arkadaki içeriği dondurmaz.
///
/// [BackdropFilter] kompozit anında arkasını canlı örnekler. [RepaintBoundary]
/// yalnızca bu widget'ın display listesini izole eder — kayan ızgara üstündeki
/// cam efekti aynı kalır. Blur'ı "fotoğraflayıp" arkayı dondurmayın.
class ArinBackdropBlur extends StatelessWidget {
  const ArinBackdropBlur({
    super.key,
    required this.sigma,
    required this.child,
    this.borderRadius,
  });

  final double sigma;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final filter = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
    final clipped = borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: filter)
        : ClipRect(child: filter);
    return RepaintBoundary(child: clipped);
  }
}
