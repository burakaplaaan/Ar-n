import 'package:hijri/hijri_calendar.dart';

import '../models/prayer_times_model.dart';

/// Ana ekran namaz widget'ının günlük tahtası (5 vakit + tik + hicri).
abstract final class PrayerTodayBoard {
  static String ymd(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  static DateTime? parseIsoDate(String raw) {
    final p = raw.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static DateTime? at(DateTime day, String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  static String formatClock(DateTime at) {
    return '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  }

  static PrayerTimesModel? modelOnDay(
    List<PrayerTimesModel> models,
    DateTime day,
  ) {
    final key = ymd(day);
    for (final model in models) {
      if (model.date == key) return model;
    }
    return null;
  }

  /// Uygulamadaki tik günü: imsaktan önceyse bir önceki takvim günü.
  static DateTime salatBoardDay({
    required List<PrayerTimesModel> models,
    required DateTime now,
  }) {
    final civil = DateTime(now.year, now.month, now.day);
    final todayModel = modelOnDay(models, civil);
    if (todayModel != null && todayModel.matchesCalendarDay(civil)) {
      return todayModel.salatTickCalendarDay(now);
    }
    return civil;
  }

  static DateTime salatBoardDayFromClock({
    required DateTime now,
    required String imsakClock,
  }) {
    final civil = DateTime(now.year, now.month, now.day);
    final fajr = at(civil, imsakClock);
    if (fajr != null && now.isBefore(fajr)) {
      return civil.subtract(const Duration(days: 1));
    }
    return civil;
  }

  static Map<String, Object?> build({
    required List<PrayerTimesModel> models,
    required DateTime now,
    required DateTime nextAt,
    required List<bool> done,
    DateTime? tickDay,
  }) {
    final boardDay = tickDay ?? DateTime(now.year, now.month, now.day);
    final dayModel = modelOnDay(models, boardDay) ??
        modelOnDay(models, DateTime(now.year, now.month, now.day)) ??
        (models.isEmpty ? null : models.first);
    final marks = List<bool>.generate(
      5,
      (i) => i < done.length && done[i],
    );
    final slots = <Map<String, Object?>>[];
    if (dayModel != null) {
      final day = parseIsoDate(dayModel.date) ?? boardDay;
      const names = ['İmsak', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'];
      final times = [
        dayModel.fajr,
        dayModel.dhuhr,
        dayModel.asr,
        dayModel.maghrib,
        dayModel.isha,
      ];
      for (var i = 0; i < 5; i++) {
        final slotAt = at(day, times[i]);
        slots.add({
          'name': names[i],
          'time': slotAt == null ? times[i] : formatClock(slotAt),
          'done': marks[i],
        });
      }
    }
    final hijri = HijriCalendar.fromDate(now);
    const months = [
      'Muharrem',
      'Safer',
      'Rebiülevvel',
      'Rebiülahir',
      'Cemaziyelevvel',
      'Cemaziyelahir',
      'Recep',
      'Şaban',
      'Ramazan',
      'Şevval',
      'Zilkade',
      'Zilhicce',
    ];
    final month = hijri.hMonth >= 1 && hijri.hMonth <= 12
        ? months[hijri.hMonth - 1]
        : '';
    return {
      'day': ymd(boardDay),
      'nextClock': formatClock(nextAt),
      'hijri': '${hijri.hDay} $month ${hijri.hYear}',
      'doneCount': marks.where((e) => e).length,
      'slots': slots,
    };
  }
}
