// lib/core/constants/app_radii.dart
//
// Köşe yuvarlaklık (border radius) token'ları. Tasarım dilinin tutarlı
// kalması için hex renk sabitleri gibi merkezi yerden okunur.
//
// Kullanım:
//   BorderRadius.circular(AppRadii.md)
//   borderRadius: AppRadii.cardBorderRadius
//   shape: AppRadii.cardShape

import 'package:flutter/widgets.dart';

abstract final class AppRadii {
  // ── Ham adımlar ──────────────────────────────────────────────────────
  /// 4 — ufak chip / mini etiket
  static const double xxs = 4;

  /// 8 — standart satır / küçük buton
  static const double xs = 8;

  /// 12 — liste öğesi
  static const double sm = 12;

  /// 16 — kart (varsayılan)
  static const double md = 16;

  /// 20 — büyük kart, öne çıkan yüzey
  static const double lg = 20;

  /// 24 — tam ekran overlay / modal sheet
  static const double xl = 24;

  /// 28 — reels / viewer
  static const double xxl = 28;

  /// 999 — tamamen yuvarlak (pill, avatar)
  static const double pill = 999;

  // ── Hazır BorderRadius ───────────────────────────────────────────────
  static const BorderRadius smBorderRadius =
      BorderRadius.all(Radius.circular(sm));
  static const BorderRadius cardBorderRadius =
      BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorderRadius =
      BorderRadius.all(Radius.circular(lg));
  static const BorderRadius modalTopBorderRadius = BorderRadius.vertical(
    top: Radius.circular(xl),
  );

  // ── Hazır ShapeBorder ────────────────────────────────────────────────
  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: cardBorderRadius,
  );
  static const RoundedRectangleBorder lgShape = RoundedRectangleBorder(
    borderRadius: lgBorderRadius,
  );
  static const RoundedRectangleBorder modalShape = RoundedRectangleBorder(
    borderRadius: modalTopBorderRadius,
  );
}
