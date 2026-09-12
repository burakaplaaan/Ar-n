// lib/core/theme/arin_shell_background.dart

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'shell_day_period.dart';

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
///   • Günün ışığı kapansın → [kShellDayAtmosphere] `false`.
///   • v2 "Eucalyptus Night"  → [kShellDayAtmosphere] kapat, v2 bloğunu aç
///     + `app_colors.dart` içinde v2 hex'lerini geri getir.
///   • v1 ilk sürüm            → "v1 GRADIENT" bloğunu aç.
class ArinShellBackground {
  ArinShellBackground._();

  /// Shell zeminine yumuşak zümrüt baloncuk + üçgen watermark ekler.
  /// "Eskiye dön" senaryosu için dokunulması gereken TEK yer burası.
  static const bool enableBubbles = true;

  static const BoxDecoration _kLightDecoration = BoxDecoration(
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

  static const BoxDecoration _kDarkV3Decoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.homeGradientTop,
        AppColors.homeGradientMid,
        AppColors.homeGradientBottom,
      ],
      stops: [0.0, 0.55, 1.0],
    ),
  );

  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static int _periodHourStamp = -1;
  static ShellDayPeriod _periodCache = ShellDayPeriod.dhuhr;

  static ShellDayPeriod _periodOf() {
    if (!kShellDayAtmosphere) return ShellDayPeriod.dhuhr;
    final now = DateTime.now();
    final stamp =
        now.year * 1000000 + now.month * 10000 + now.day * 100 + now.hour;
    if (stamp == _periodHourStamp) return _periodCache;
    _periodHourStamp = stamp;
    _periodCache = ShellDayPeriod.fromClock(now);
    return _periodCache;
  }

  static BoxDecoration decoration(BuildContext context) {
    final light = isLight(context);
    if (!kShellDayAtmosphere) {
      return light ? _kLightDecoration : _kDarkV3Decoration;
    }
    final period = _periodOf();
    if (light) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: period.gradientColors(light: true),
          stops: const [0.0, 0.45, 1.0],
        ),
      );
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: period.gradientColors(light: false),
        stops: const [0.0, 0.55, 1.0],
      ),
    );
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
    final period = kShellDayAtmosphere ? _periodOf() : null;
    final topBubble = period == null
        ? (light
              ? AppColors.emeraldFaint.withValues(alpha: 0.34)
              : AppColors.emeraldMid.withValues(alpha: 0.07))
        : period.bubbleColor(light: light);
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: topBubble,
                ),
              ),
            ),
            Positioned(
              bottom: light ? 40 : 80,
              left: light ? -90 : -100,
              child: light
                  ? Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentGreenOnLight.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    )
                  : CustomPaint(
                      size: const Size(240, 200),
                      painter: _TriangleWatermarkPainter(
                        color: AppColors.accentNeonGreen.withValues(alpha: 0.04),
                      ),
                    ),
            ),
          ],
        ),
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
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: decoration(context)),
          bubbleLayer(context),
        ],
      ),
    );
  }

  /// Gradient + baloncuk + sayfa içeriğini tek seferde saran helper.
  /// Container-based çağrı yerleri (home, kıble, kıble-dashboard) bunu
  /// kullanır.
  static Widget buildLayered(BuildContext context, {required Widget child}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(decoration: decoration(context)),
              bubbleLayer(context),
            ],
          ),
        ),
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
