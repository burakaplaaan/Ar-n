// Yalnızca admin paneli — namaz vakitlerini cihazda test kaydırmak (API değişmez).

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_times_model.dart';

abstract final class AdminDevPrefs {
  static const _kPrayerOffset = 'admin_dev_prayer_offset_minutes';

  static const int minOffsetMinutes = -180;
  static const int maxOffsetMinutes = 180;

  static int prayerOffsetMinutes(SharedPreferences p) {
    final v = p.getInt(_kPrayerOffset);
    if (v == null) return 0;
    return v.clamp(minOffsetMinutes, maxOffsetMinutes);
  }

  static Future<void> setPrayerOffsetMinutes(SharedPreferences p, int v) =>
      p.setInt(_kPrayerOffset, v.clamp(minOffsetMinutes, maxOffsetMinutes));

  static PrayerTimesModel applyPrayerOffset(
    SharedPreferences p,
    PrayerTimesModel model,
  ) =>
      model.shiftAllMinutes(prayerOffsetMinutes(p));
}
