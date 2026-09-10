// Alt kabuk (bottom bar) ile içerik arasında güvenli boşluk — tek kaynak.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// [ArinShell] alt navigasyonu + orta FAB “dudak” + parmak payı.
abstract final class ArinShellLayout {
  /// Orta üçgen FAB’ın üstte taşan kısmı için ekstra boşluk.
  static const double centerFabLip = 12;

  static const double _barInnerTop = 6;
  static const double _barInnerBottom = 8;
  static const double _barRowHeight = 50;
  static const double _barFinger = 20;
  static const double _keyboardOpenThreshold = 24;

  /// Alt çubuğun üstünde bitmek için gereken toplam boşluk.
  static double barClearance(double systemBottom) {
    return systemBottom +
        _barInnerTop +
        _barInnerBottom +
        _barRowHeight +
        centerFabLip +
        _barFinger;
  }

  /// Cihazın gerçek alt inset’i. MediaQuery soyulmuş olsa bile [View] kullanılır.
  static double deviceSystemBottom(BuildContext context) {
    final mq = MediaQuery.of(context);
    var system = math.max(mq.viewPadding.bottom, mq.padding.bottom);
    final view = View.maybeOf(context);
    final dpr = view?.devicePixelRatio ?? 0;
    if (view != null && dpr > 0) {
      final fromView =
          math.max(view.padding.bottom, view.viewPadding.bottom) / dpr;
      system = math.max(system, fromView);
    }
    return system;
  }

  static double keyboardInset(BuildContext context) {
    final mq = MediaQuery.viewInsetsOf(context).bottom;
    final view = View.maybeOf(context);
    final dpr = view?.devicePixelRatio ?? 0;
    if (view != null && dpr > 0) {
      return math.max(mq, view.viewInsets.bottom / dpr);
    }
    return mq;
  }

  /// İçerik / FAB’ın alt çubuğun üstünde bitmesi için toplam padding.
  ///
  /// [ArinShell] `extendBody: true` kullandığı için iç sayfa [Scaffold]’ları
  /// gövdeyi alt çubuğun altına kadar çizer; [viewPadding] bazı cihazlarda
  /// tek başına yetersiz kalabildiğinden sistem alt boşluğu `View` +
  /// `padding` ile birlikte alınır. Ölçüler `_ArinBottomNav` ile uyumlu:
  /// Padding(6,8) + satır ~50 + FAB dudak + parmak payı.
  static double bottomContentPadding(BuildContext context) {
    return barClearance(deviceSystemBottom(context));
  }

  /// Yeşil artı FAB’ın alt bar satırının **üst kenarına** yapışık minimal pay (logical px).
  static const double fabGapAboveBottomNav = 2;

  /// FAB alt kenarı ↔ fiziksel ekran altı.
  ///
  /// `_ArinBottomNav`: `SafeArea` + `Padding(…, 6, 8)` — Row’un altındaki **8** satırı ekran
  /// tabanından yukarı iter; üstteki **6** bu hizadan sayılmaz (önceki 6+8 toplamı ~6px fazla boşluk veriyordu).
  static double fabCornerBottomFromScreenBottom(BuildContext context) {
    return deviceSystemBottom(context) +
        _barInnerBottom +
        _barRowHeight +
        fabGapAboveBottomNav;
  }

  static const double willpowerHubFabSize = 58;

  /// Willpower hub listesi — alt çubuk + yeşil FAB üst üste binmesin (`bottomContentPadding` ile max).
  /// Gerçek klavye yüksekliği; MediaQuery soyulmuş olsa bile [View] kullanılır.
  static bool isKeyboardOpen(BuildContext context) {
    return keyboardInset(context) > _keyboardOpenThreshold;
  }

  @visibleForTesting
  static bool keyboardOpenFromMedia({
    required double viewInsetsBottom,
    required double viewPaddingBottom,
    required double paddingBottom,
  }) {
    return viewInsetsBottom > _keyboardOpenThreshold;
  }

  /// Yazma kutusu: klavye açıkken klavyenin üstü, değilse alt barın üstü.
  /// 8px “kısayol” yok — kutu barın altına inemez.
  static double composerBottomPadding(BuildContext context) {
    if (isKeyboardOpen(context)) return 10 + keyboardInset(context);
    return bottomContentPadding(context);
  }

  /// Asistan yazma çubuğu — [composerBottomPadding] ile aynı kural.
  static double assistantComposerBottomPadding(
    BuildContext context, {
    double? bodyHeight,
  }) {
    return composerBottomPadding(context);
  }

  /// Test için: her zaman bar boşluğunun tamamı. Kısa kesmek barın altına sokar.
  @visibleForTesting
  static double assistantComposerBottomPaddingFromMedia({
    required double viewPaddingBottom,
    required double paddingBottom,
    double? screenHeight,
    double? bodyHeight,
  }) {
    return barClearance(math.max(viewPaddingBottom, paddingBottom));
  }

  static double willpowerHubScrollBottomPadding(BuildContext context) {
    const tail = 8.0;
    final base = bottomContentPadding(context);
    final withFab =
        fabCornerBottomFromScreenBottom(context) + willpowerHubFabSize + tail;
    return math.max(base, withFab);
  }
}
