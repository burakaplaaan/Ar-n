// Alt kabuk (bottom bar) ile içerik arasında güvenli boşluk — tek kaynak.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// [ArinShell] alt navigasyonu + orta FAB “dudak” + parmak payı.
abstract final class ArinShellLayout {
  /// Orta üçgen FAB’ın üstte taşan kısmı için ekstra boşluk.
  static const double centerFabLip = 12;

  /// İçerik / FAB’ın alt çubuğun üstünde bitmesi için toplam padding.
  ///
  /// [ArinShell] `extendBody: true` kullandığı için iç sayfa [Scaffold]’ları
  /// gövdeyi alt çubuğun altına kadar çizer; [viewPadding] bazı cihazlarda
  /// tek başına yetersiz kalabildiğinden sistem alt boşluğu `padding` ile
  /// birlikte alınır. Ölçüler `_ArinBottomNav` ile uyumlu: Padding(6,8) +
  /// satır ~50 + FAB dudak + parmak payı.
  static double bottomContentPadding(BuildContext context) {
    final mq = MediaQuery.of(context);
    final systemBottom = math.max(mq.viewPadding.bottom, mq.padding.bottom);
    const barPaddingVertical = 6 + 8; // _ArinBottomNav iç dikey padding
    const rowHeight = 50; // orta üçgen (layout yüksekliği)
    const finger = 20;
    return systemBottom +
        barPaddingVertical +
        rowHeight +
        centerFabLip +
        finger;
  }

  /// Yeşil artı FAB’ın alt bar satırının **üst kenarına** yapışık minimal pay (logical px).
  static const double fabGapAboveBottomNav = 2;

  /// FAB alt kenarı ↔ fiziksel ekran altı.
  ///
  /// `_ArinBottomNav`: `SafeArea` + `Padding(…, 6, 8)` — Row’un altındaki **8** satırı ekran
  /// tabanından yukarı iter; üstteki **6** bu hizadan sayılmaz (önceki 6+8 toplamı ~6px fazla boşluk veriyordu).
  static double fabCornerBottomFromScreenBottom(BuildContext context) {
    final mq = MediaQuery.of(context);
    final systemBottom = math.max(mq.viewPadding.bottom, mq.padding.bottom);
    const innerBottomPad = 8; // Row altı (_ArinBottomNav)
    const rowHeight = 50; // _CenterFab / satır
    return systemBottom + innerBottomPad + rowHeight + fabGapAboveBottomNav;
  }

  static const double willpowerHubFabSize = 58;

  /// Willpower hub listesi — alt çubuk + yeşil FAB üst üste binmesin (`bottomContentPadding` ile max).
  /// Üst kabuk `viewInsets`'i yutsa bile klavye açık mı.
  static bool isKeyboardOpen(BuildContext context) {
    final mq = MediaQuery.of(context);
    return keyboardOpenFromMedia(
      viewInsetsBottom: mq.viewInsets.bottom,
      viewPaddingBottom: mq.viewPadding.bottom,
      paddingBottom: mq.padding.bottom,
    );
  }

  @visibleForTesting
  static bool keyboardOpenFromMedia({
    required double viewInsetsBottom,
    required double viewPaddingBottom,
    required double paddingBottom,
  }) {
    return viewInsetsBottom > 0 ||
        viewPaddingBottom > paddingBottom + 0.5;
  }

  /// Asistan yazma çubuğu — alt menünün hemen üstü; klavyede menü payı yok.
  static double assistantComposerBottomPadding(BuildContext context) {
    if (isKeyboardOpen(context)) return 10;
    final mq = MediaQuery.of(context);
    final systemBottom = math.max(mq.viewPadding.bottom, mq.padding.bottom);
    const innerBottomPad = 8;
    const rowHeight = 50;
    const gapAboveBar = 8;
    const navNudgeDown = 8;
    return systemBottom + innerBottomPad + rowHeight + gapAboveBar - navNudgeDown;
  }

  static double willpowerHubScrollBottomPadding(BuildContext context) {
    const tail = 8.0;
    final base = bottomContentPadding(context);
    final withFab =
        fabCornerBottomFromScreenBottom(context) + willpowerHubFabSize + tail;
    return math.max(base, withFab);
  }
}
