// Hazırlık / söz ekranı — zarif giriş tipografisi (Plus Jakarta dışında, okunaklı serif).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Söz metin alanı: günlük / duygusal metin için Literata (okunaklı, sakin serif).
TextStyle commitmentInputTextStyle({
  required Color color,
  double fontSize = 17,
}) {
  return GoogleFonts.literata(
    fontSize: fontSize,
    height: 1.55,
    fontWeight: FontWeight.w400,
    color: color,
    letterSpacing: 0.15,
  );
}

TextStyle commitmentInputHintStyle({
  Color? color,
  double fontSize = 16,
}) {
  return GoogleFonts.literata(
    fontSize: fontSize,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textOnDarkMuted,
    letterSpacing: 0.1,
  );
}
