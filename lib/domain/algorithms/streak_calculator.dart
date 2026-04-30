// lib/domain/algorithms/streak_calculator.dart
// Ardışık gün (streak) hesaplama algoritması.
// Bugünden geriye doğru bitişik tamamlanmış günleri sayar.

import '../../data/models/habit_log_model.dart';

class StreakCalculator {
  /// [logs]: Belirli bir alışkanlığa ait tüm tamamlama kayıtları.
  /// Bugün dahil, geriye doğru ardışık tamamlanan gün sayısını döndürür.
  static int calculate(List<HabitLogModel> logs) {
    if (logs.isEmpty) return 0;

    // Tamamlanan günleri kümeye al
    final completedDates = logs
        .where((l) => l.isCompleted)
        .map((l) => l.date)
        .toSet();

    if (completedDates.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();

    // Bugün tamamlanmamışsa seri kırılmış
    final todayKey = _dateKey(today);
    if (!completedDates.contains(todayKey)) {
      // Dün tamamlandıysa seri dün başlıyor (dünü sayan streak)
      final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));
      if (!completedDates.contains(yesterdayKey)) return 0;
      // Dünden geriye doğru say
      DateTime cursor = today.subtract(const Duration(days: 1));
      while (completedDates.contains(_dateKey(cursor))) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return streak;
    }

    // Bugünden geriye doğru say
    DateTime cursor = today;
    while (completedDates.contains(_dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Bugün tamamlandı mı?
  static bool isCompletedToday(List<HabitLogModel> logs) {
    final key = _dateKey(DateTime.now());
    return logs.any((l) => l.date == key && l.isCompleted);
  }

  /// "yyyy-MM-dd" tarih anahtarı
  static String _dateKey(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
