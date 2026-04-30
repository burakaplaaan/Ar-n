// lib/core/constants/app_spacing.dart
//
// Uygulama genelinde kullanılan boşluk (margin/padding) token'ları.
// Amaç: `EdgeInsets.all(16)` gibi "sihirli sayılar"ın yerine isimli
// sabitler kullanmak — tasarım revizyonu tek yerden yapılır.
//
// Ölçek tabanı 4 px. Material 3 ve Apple HIG'in 4/8 grid'i ile uyumlu.
//
// Kullanım:
//   const EdgeInsets.all(AppSpacing.md)
//   const SizedBox(height: AppSpacing.lg)
//   padding: AppSpacing.pageHorizontal
//
// YENİ ekranlarda / refactor edilen ekranlarda tercih edilir. Mevcut
// "sihirli sayılar" aşamalı olarak değiştirilir; zorunlu değil.

import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  // ── Ham adımlar (4 px tabanı) ────────────────────────────────────────
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 56;

  // ── Tipik sayfa paddingleri ──────────────────────────────────────────
  static const EdgeInsets pageHorizontal =
      EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pagePadding =
      EdgeInsets.fromLTRB(lg, lg, lg, xxl);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets bottomSheetPadding =
      EdgeInsets.fromLTRB(lg, xl, lg, xxl);
}
