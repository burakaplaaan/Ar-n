// lib/presentation/shared/widgets/tasbeeh_zikirmatik_device_frame.dart
// Gövde SVG + dış/iç renk katmanı: [tasbeeh_counter home_body](https://github.com/n4ff4h/tasbeeh_counter/blob/main/lib/screens/home_body.dart)

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Kaynak: `tasbeeh_counter_layout.svg` (aynı repo, `assets/images/`).
abstract final class TasbeehZikirmatikLayout {
  static const String assetPath =
      'assets/images/zikir/tasbeeh_counter_layout.svg';

  /// Kaynak SVG `viewBox`.
  static const double viewBoxWidth = 703.99;
  static const double viewBoxHeight = 919.49;

  static double get widthOverHeight => viewBoxWidth / viewBoxHeight;

  /// `constants.dart`: inner 380 / outer 410.
  static const double innerToOuterScale = 380 / 410;
}

/// İki üst üste [SvgPicture] ile çerçeve + gövde (light temada `primaryLightColor` + `tasbeehCounterColor`).
class TasbeehZikirmatikDeviceFrame extends StatelessWidget {
  const TasbeehZikirmatikDeviceFrame({
    super.key,
    required this.outerColor,
    required this.innerColor,
    this.child,
    this.contentPadding = const EdgeInsets.fromLTRB(18, 22, 18, 18),
  });

  final Color outerColor;
  final Color innerColor;
  final Widget? child;

  /// İçerik alanı; `child == null` ise yalnızca gövde çizilir (ör. silüet ikon).
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        var w = maxW;
        var h = w / TasbeehZikirmatikLayout.widthOverHeight;
        if (h > maxH) {
          h = maxH;
          w = h * TasbeehZikirmatikLayout.widthOverHeight;
        }

        const s = TasbeehZikirmatikLayout.innerToOuterScale;
        final iw = w * s;
        final ih = h * s;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            alignment: Alignment.center,
            // none: SVG alt satırların (ipucu metni) üzerine taşabiliyordu
            clipBehavior: Clip.hardEdge,
            children: [
              SvgPicture.asset(
                TasbeehZikirmatikLayout.assetPath,
                width: w,
                height: h,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(outerColor, BlendMode.srcIn),
              ),
              SvgPicture.asset(
                TasbeehZikirmatikLayout.assetPath,
                width: iw,
                height: ih,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(innerColor, BlendMode.srcIn),
              ),
              if (child != null)
                Positioned.fill(
                  child: Padding(
                    padding: contentPadding,
                    child: child!,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
