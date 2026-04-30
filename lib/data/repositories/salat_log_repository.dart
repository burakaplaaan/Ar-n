// Günlük 5 vakit tikleri — Hive String kutusu (örn. "10101").

import 'dart:async';

import 'package:hive/hive.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/utils/hive_boxes.dart';
import 'habit_repository.dart';

class SalatLogRepository {
  Box<String> get _box => Hive.box<String>(HiveBoxes.salatLogs);

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _storageKey(String habitId, String day) => '${habitId}_$day';

  List<bool> getPrayers(String habitId, DateTime day) {
    final raw = _box.get(_storageKey(habitId, dayKey(day)));
    if (raw == null || raw.length != 5) {
      return [false, false, false, false, false];
    }
    return raw.split('').map((c) => c == '1').toList();
  }

  int countDone(String habitId, DateTime day) =>
      getPrayers(habitId, day).where((e) => e).length;

  /// Namaz vakit isimleri — analytics olayında `prayer` alanı için kullanılır.
  static const List<String> _prayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  /// Cuma günü öğle vaktinde kılınan namaz farklı bir ibadet (Cuma namazı).
  /// Analytics'te ayrı event olarak ayrıştırmak: "Haftalık Cuma namazı
  /// kullanımı" ölçülebilir → gelecekte Cuma özel hatırlatıcı / özel sözler
  /// eklemek için temel metrik.
  static String _analyticsPrayerKey(int index, DateTime day) {
    if (index == 1 && day.weekday == DateTime.friday) return 'jumuah';
    return _prayerKeys[index];
  }

  Future<void> setPrayer(
    String habitId,
    DateTime day,
    int index,
    bool done,
    HabitRepository habitRepo,
  ) async {
    assert(index >= 0 && index < 5);
    final list = getPrayers(habitId, day);
    final wasDone = list[index];
    list[index] = done;
    final s = list.map((b) => b ? '1' : '0').join();
    await _box.put(_storageKey(habitId, dayKey(day)), s);

    final all = list.every((e) => e);
    await habitRepo.setCompletedForDay(habitId, dayKey(day), all);
    // Yalnızca "kılındı" ticki sayılır (uncheck'ler data kirletir).
    // Cuma + öğle ise `jumuah` ayrı event; diğerleri standart fajr/…/isha.
    if (done && !wasDone) {
      unawaited(ArinAnalytics.namazTick(_analyticsPrayerKey(index, day)));
    }
  }

  /// Pazartesi günü [monday] ile başlayan haftada her gün 5/5 mi?
  bool isPerfectWeek(String habitId, DateTime monday) {
    for (var i = 0; i < 7; i++) {
      final d = DateTime(monday.year, monday.month, monday.day)
          .add(Duration(days: i));
      if (countDone(habitId, d) < 5) return false;
    }
    return true;
  }

  /// Alışkanlık [habitStartedAt] tarihinden önceki günler sayılmaz (yeni eklenen namaz rutini).
  bool isPerfectWeekForHabit(
    String habitId,
    DateTime weekMonday,
    DateTime habitStartedAt,
  ) {
    final start = DateTime(
      habitStartedAt.year,
      habitStartedAt.month,
      habitStartedAt.day,
    );
    final week0 = DateTime(weekMonday.year, weekMonday.month, weekMonday.day);
    final weekEnd = week0.add(const Duration(days: 6));
    if (start.isAfter(weekEnd)) return false;

    var anyInRange = false;
    for (var i = 0; i < 7; i++) {
      final d = week0.add(Duration(days: i));
      if (d.isBefore(start)) continue;
      anyInRange = true;
      if (countDone(habitId, d) < 5) return false;
    }
    return anyInRange;
  }

  static DateTime mondayOf(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    return x.subtract(Duration(days: x.weekday - DateTime.monday));
  }

  static String weekMondayKey(DateTime anyDayInWeek) {
    final m = mondayOf(anyDayInWeek);
    return '${m.year}${m.month.toString().padLeft(2, '0')}${m.day.toString().padLeft(2, '0')}';
  }
}
