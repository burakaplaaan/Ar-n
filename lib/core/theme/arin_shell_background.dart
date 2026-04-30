// lib/core/theme/arin_shell_background.dart

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Ana sekmelerde (home, kıble, willpower, inspire, settings…) ortak zemin.
///
/// DARK TEMA TASARIM SÜRÜMÜ:
/// - v3 "Hub Match" aktif. Alışkanlık takibi hub'ının `_HubBackground`'ı
///   ile **bire bir aynı** gradient + baloncuk + yumuşak üçgen watermark.
///   Her sekme aynı görsel dili konuşur.
/// - [enableBubbles] `true` iken katman bindirilir, `false` iken gradient
///   yalın kalır (eskiye dönüş: tek satır).
///
/// Eskiye dönüş:
///   • v2 "Eucalyptus Night"  → aşağıdaki "v3 GRADIENT"i yoruma al,
///     "v2 GRADIENT" bloğunu aç + `app_colors.dart` içinde v2 hex'lerini
///     geri getir.
///   • v1 ilk sürüm            → "v1 GRADIENT" bloğunu aç.
class ArinShellBackground {
  ArinShellBackground._();

  /// Shell zeminine yumuşak zümrüt baloncuk + üçgen watermark ekler.
  /// "Eskiye dön" senaryosu için dokunulması gereken TEK yer burası.
  static const bool enableBubbles = true;

  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static BoxDecoration decoration(BuildContext context) {
    if (isLight(context)) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.creamMist,
            AppColors.creamBase,
            AppColors.creamShellDeep,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      );
    }

    // ─── v3 GRADIENT (aktif) — alışkanlık hub ile aynı ──────────────────
    // Köşegen yönü (topLeft → bottomRight) + koyu zümrüt-siyah 3 durak.
    // app_colors: homeGradientTop #030806, Mid #0A1610, Bottom #050A07.
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.homeGradientTop,    // #030806
          AppColors.homeGradientMid,    // #0A1610
          AppColors.homeGradientBottom, // #050A07
        ],
        stops: [0.0, 0.55, 1.0],
      ),
    );

    // ─── v2 GRADIENT (yedek, Eucalyptus Night) ──────────────────────────
    // return const BoxDecoration(
    //   gradient: LinearGradient(
    //     begin: Alignment.topCenter,
    //     end: Alignment.bottomCenter,
    //     colors: [
    //       AppColors.homeGradientTop,    // v2: #153C2D
    //       AppColors.homeGradientMid,    // v2: #0D271E
    //       AppColors.homeGradientBottom, // v2: #081511
    //     ],
    //     stops: [0.0, 0.55, 1.0],
    //   ),
    // );

    // ─── v1 GRADIENT (yedek, 2 durak) ───────────────────────────────────
    // return const BoxDecoration(
    //   gradient: LinearGradient(
    //     begin: Alignment.topCenter,
    //     end: Alignment.bottomCenter,
    //     colors: [
    //       AppColors.homeGradientTop,    // v1: #0F2419
    //       AppColors.homeGradientBottom, // v1: #030806
    //     ],
    //     stops: [0.0, 0.6],
    //   ),
    // );
  }

  /// Gradient zemininin üstüne yerleştirilen yumuşak aksan katmanı.
  /// - Sağ üst: 280px yumuşak zümrüt daire (emeraldMid @ 7%).
  /// - Sol alt: yumuşak üçgen watermark (accentNeonGreen @ 4%).
  ///
  /// Referans: `willpower_hub_page.dart` → eski `_HubBackground`. Willpower
  /// hub artık doğrudan bu katmanı çağırıyor → shell ile piksel-eş.
  ///
  /// Dokunmatik olayları emmesin diye `IgnorePointer` ile sarılır.
  /// `enableBubbles` false ise [SizedBox.shrink] döner (widget ağacı güvenli).
  static Widget bubbleLayer(BuildContext context) {
    if (!enableBubbles) return const SizedBox.shrink();
    final light = isLight(context);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sağ üst — ana/büyük yumuşak zümrüt daire.
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: light
                    // Açık temada pastel emeraldFaint daha tutarlı.
                    ? AppColors.emeraldFaint.withValues(alpha: 0.34)
                    : AppColors.emeraldMid.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Sol alt — yumuşak üçgen watermark (hub ile aynı forma).
          // Açık temada daireye düşüyoruz (üçgen kalabalık olmasın).
          Positioned(
            bottom: light ? 40 : 80,
            left: light ? -90 : -100,
            child: light
                ? Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentGreenOnLight
                          .withValues(alpha: 0.10),
                    ),
                  )
                : CustomPaint(
                    size: const Size(240, 200),
                    painter: _TriangleWatermarkPainter(
                      color: AppColors.accentNeonGreen
                          .withValues(alpha: 0.04),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// **Sadece** zemin katmanı (gradient + baloncuk) — child ALMAZ.
  /// Mevcut `Stack`'in ilk çocuğu olarak yerleştirilir. Tipik kullanım:
  ///
  /// ```dart
  /// Stack(
  ///   children: [
  ///     Positioned.fill(child: ArinShellBackground.backdropLayer(context)),
  ///     ...kendi içerik widget'ların,
  ///   ],
  /// )
  /// ```
  ///
  /// Willpower hub, `_HubBackground` yerine bunu kullanır → tek kaynak.
  static Widget backdropLayer(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: decoration(context)),
        bubbleLayer(context),
      ],
    );
  }

  /// Gradient + baloncuk + sayfa içeriğini tek seferde saran helper.
  /// Container-based çağrı yerleri (home, kıble, kıble-dashboard) bunu
  /// kullanır.
  static Widget buildLayered(
    BuildContext context, {
    required Widget child,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: decoration(context)),
        bubbleLayer(context),
        child,
      ],
    );
  }
}

/// Sol-alt yumuşak üçgen watermark — hub'ın imzası. Tepe yukarıda
/// (orta-üst), taban aşağıda. Aşırı saydam yeşil ile soluk bir pulse
/// hissi verir; odak noktalarıyla yarışmaz.
class _TriangleWatermarkPainter extends CustomPainter {
  const _TriangleWatermarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _TriangleWatermarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
