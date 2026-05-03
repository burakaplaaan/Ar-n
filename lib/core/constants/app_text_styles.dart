// lib/core/constants/app_text_styles.dart
// Uygulamanın tüm tipografi sabitlerini tanımlar.
// Ana uygulama fontu lokal bundle edilen "Plus Jakarta Sans" ailesidir.

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ARIN tipografi sistemi.
/// Tüm text stilleri bu sınıf üzerinden erişilmelidir.
abstract final class AppTextStyles {
  // ─── Temel Font Ailesi ──────────────────────────────────────────────
  static const String primaryFontFamily = 'PlusJakartaSans';

  static TextStyle get _base => const TextStyle(
        fontFamily: primaryFontFamily,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      );

  // ─── Başlıklar ──────────────────────────────────────────────────────
  static TextStyle get displayLarge => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get displayMedium => _base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
      );

  static TextStyle get headlineLarge => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
      );

  static TextStyle get headlineMedium => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get headlineSmall => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ─── Alias'lar (titleMedium, titleLarge) ───
  static TextStyle get titleLarge => headlineLarge;
  static TextStyle get titleMedium => headlineMedium;
  static TextStyle get titleSmall => headlineSmall;

  // ─── Gövde Metinleri ────────────────────────────────────────────────
  static TextStyle get bodyLarge => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMedium => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  // ─── Etiket / Yardımcı Metinler ─────────────────────────────────────
  static TextStyle get labelLarge => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      );

  static TextStyle get labelSmall => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textMuted,
      );

  // ─── Özel Stiller ───────────────────────────────────────────────────

  /// Namaz vakti geri sayım — büyük dijital görünüm
  static TextStyle get countdown => _base.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: AppColors.textOnDark,
        height: 1.0,
      );

  /// Ayet/hadis metni — yumuşak italic
  static TextStyle get verseText => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: AppColors.textPrimary,
        height: 1.7,
        letterSpacing: 0.2,
      );

  /// Streak sayısı — vurgulu büyük rakam
  static TextStyle get streakNumber => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.emeraldDark,
        height: 1.0,
      );

  /// Açık renk metin (koyu arka planlarda)
  static TextStyle get onDark => _base.copyWith(
        color: AppColors.textOnDark,
      );

  /// Soluk metin (ipucu, placeholder)
  static TextStyle get muted => _base.copyWith(
        color: AppColors.textMuted,
        fontSize: 13,
      );
}
