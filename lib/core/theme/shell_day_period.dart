import 'package:flutter/material.dart';

import '../../data/models/prayer_times_model.dart';
import '../constants/app_colors.dart';

/// Günün vaktine göre ev zemininin ışığını kaydırır.
/// Eski sabit v3 zemine dönüş: `false`.
const bool kShellDayAtmosphere = true;

enum ShellDayPeriod {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha;

  static ShellDayPeriod fromClock(DateTime now) {
    final hour = now.hour;
    if (hour < 6) return isha;
    if (hour < 12) return fajr;
    if (hour < 15) return dhuhr;
    if (hour < 18) return asr;
    if (hour < 20) return maghrib;
    return isha;
  }

  static ShellDayPeriod resolve(DateTime now, PrayerTimesModel? times) {
    if (times != null) {
      final index = times.currentSalatIndex(now);
      if (index != null && index >= 0 && index < values.length) {
        return values[index];
      }
    }
    return fromClock(now);
  }

  List<Color> gradientColors({required bool light}) {
    if (light) {
      return [
        Color.lerp(AppColors.creamMist, _lightTint, _lightAmount)!,
        Color.lerp(AppColors.creamBase, _lightTint, _lightAmount * 0.85)!,
        Color.lerp(AppColors.creamShellDeep, _lightTint, _lightAmount * 0.7)!,
      ];
    }
    return [
      Color.lerp(AppColors.homeGradientTop, _darkTint, _darkAmount)!,
      Color.lerp(AppColors.homeGradientMid, _darkTint, _darkAmount * 0.9)!,
      Color.lerp(AppColors.homeGradientBottom, _darkTint, _darkAmount * 0.75)!,
    ];
  }

  Color bubbleColor({required bool light}) {
    if (light) {
      return Color.lerp(
        AppColors.emeraldFaint.withValues(alpha: 0.34),
        _lightTint.withValues(alpha: 0.40),
        _lightAmount,
      )!;
    }
    return Color.lerp(
      AppColors.emeraldMid.withValues(alpha: 0.07),
      _darkTint.withValues(alpha: 0.14),
      _darkAmount,
    )!;
  }

  Color get _darkTint {
    switch (this) {
      case fajr:
        return const Color(0xFF143044);
      case dhuhr:
        return const Color(0xFF1F4A32);
      case asr:
        return const Color(0xFF3D3414);
      case maghrib:
        return const Color(0xFF4A2410);
      case isha:
        return const Color(0xFF020806);
    }
  }

  Color get _lightTint {
    switch (this) {
      case fajr:
        return const Color(0xFFD2DCE0);
      case dhuhr:
        return const Color(0xFFD8E0D4);
      case asr:
        return const Color(0xFFE8D8B8);
      case maghrib:
        return const Color(0xFFE8C8A8);
      case isha:
        return const Color(0xFFC8C2B6);
    }
  }

  double get _darkAmount {
    switch (this) {
      case fajr:
        return 0.20;
      case dhuhr:
        return 0.10;
      case asr:
        return 0.16;
      case maghrib:
        return 0.18;
      case isha:
        return 0.06;
    }
  }

  double get _lightAmount {
    switch (this) {
      case fajr:
        return 0.22;
      case dhuhr:
        return 0.10;
      case asr:
        return 0.18;
      case maghrib:
        return 0.20;
      case isha:
        return 0.16;
    }
  }
}
