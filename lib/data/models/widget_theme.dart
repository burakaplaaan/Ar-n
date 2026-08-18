import 'package:flutter/material.dart';

class ArinWidgetTheme {
  const ArinWidgetTheme({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.nameAr,
    required this.premiumOnly,
    required this.previewBackground,
    required this.previewForeground,
  });

  final String id;
  final String nameTr;
  final String nameEn;
  final String nameAr;
  final bool premiumOnly;
  final Color previewBackground;
  final Color previewForeground;

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr;
      case 'en':
        return nameEn;
      default:
        return nameTr;
    }
  }

  static const String classicId = 'classic';
  static const String defaultId = classicId;

  static const List<ArinWidgetTheme> all = [
    ArinWidgetTheme(
      id: classicId,
      nameTr: 'Klasik',
      nameEn: 'Classic',
      nameAr: 'كلاسيكي',
      premiumOnly: false,
      previewBackground: Color(0x00000000),
      previewForeground: Color(0xFFF4F1E8),
    ),
    ArinWidgetTheme(
      id: 'emerald',
      nameTr: 'Zümrüt',
      nameEn: 'Emerald',
      nameAr: 'زمردي',
      premiumOnly: true,
      previewBackground: Color(0xFF0F2419),
      previewForeground: Color(0xFFE8D5A3),
    ),
    ArinWidgetTheme(
      id: 'gold',
      nameTr: 'Altın',
      nameEn: 'Gold',
      nameAr: 'ذهبي',
      premiumOnly: true,
      previewBackground: Color(0xFF3D2A12),
      previewForeground: Color(0xFFF0D48A),
    ),
    ArinWidgetTheme(
      id: 'midnight',
      nameTr: 'Gece',
      nameEn: 'Midnight',
      nameAr: 'ليلي',
      premiumOnly: true,
      previewBackground: Color(0xFF0B1220),
      previewForeground: Color(0xFFD5DCE8),
    ),
    ArinWidgetTheme(
      id: 'rose',
      nameTr: 'Gül',
      nameEn: 'Rose',
      nameAr: 'وردي',
      premiumOnly: true,
      previewBackground: Color(0xFF3A1F28),
      previewForeground: Color(0xFFF0C9C0),
    ),
    ArinWidgetTheme(
      id: 'sand',
      nameTr: 'Kum',
      nameEn: 'Sand',
      nameAr: 'رملي',
      premiumOnly: true,
      previewBackground: Color(0xFFF3E6C8),
      previewForeground: Color(0xFF3A2A14),
    ),
    ArinWidgetTheme(
      id: 'ocean',
      nameTr: 'Okyanus',
      nameEn: 'Ocean',
      nameAr: 'بحري',
      premiumOnly: true,
      previewBackground: Color(0xFF0C2A32),
      previewForeground: Color(0xFFB7E4E0),
    ),
  ];

  static ArinWidgetTheme byId(String? id) {
    for (final theme in all) {
      if (theme.id == id) return theme;
    }
    return all.first;
  }

  static String resolveEffectiveId({
    required String requestedId,
    required bool isPremium,
  }) {
    final theme = byId(requestedId);
    if (theme.premiumOnly && !isPremium) return classicId;
    return theme.id;
  }
}

/// Kilit ekranı yazı netliği. Apple rengi siler; yalnızca açıklık kalır.
class WidgetLockTextStyle {
  const WidgetLockTextStyle({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.nameAr,
  });

  final String id;
  final String nameTr;
  final String nameEn;
  final String nameAr;

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr;
      case 'en':
        return nameEn;
      default:
        return nameTr;
    }
  }

  static const String clearId = 'clear';
  static const String softId = 'soft';
  static const String defaultId = clearId;

  static const WidgetLockTextStyle clear = WidgetLockTextStyle(
    id: clearId,
    nameTr: 'Net',
    nameEn: 'Clear',
    nameAr: 'واضح',
  );

  static const WidgetLockTextStyle soft = WidgetLockTextStyle(
    id: softId,
    nameTr: 'Yumuşak',
    nameEn: 'Soft',
    nameAr: 'ناعم',
  );

  static const List<WidgetLockTextStyle> all = [clear, soft];

  static WidgetLockTextStyle byId(String? id) {
    for (final style in all) {
      if (style.id == id) return style;
    }
    return clear;
  }

  static String resolveEffectiveId({
    required String requestedId,
    required bool isPremium,
  }) {
    if (!isPremium) return defaultId;
    return byId(requestedId).id;
  }
}
