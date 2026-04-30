import 'package:flutter_test/flutter_test.dart';
import 'package:arin/domain/algorithms/streak_calculator.dart';
import 'package:arin/data/models/habit_log_model.dart';

void main() {
  group('StreakCalculator Tests', () {
    String dateKey(DateTime date) =>
        '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    test('Boş liste için 0 döner', () {
      expect(StreakCalculator.calculate([]), 0);
    });

    test('Sadece bugün tamamlanan kayıt için 1 döner', () {
      final today = DateTime.now();
      final logs = [
        HabitLogModel(
          habitId: '1',
          date: dateKey(today),
          isCompleted: true,
        ),
      ];
      expect(StreakCalculator.calculate(logs), 1);
    });

    test('Dün ve evvelsi gün tamamlanmış (bugün tamamlanmamış) kayıt için 2 döner', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBefore = today.subtract(const Duration(days: 2));

      final logs = [
        HabitLogModel(habitId: '1', date: dateKey(yesterday), isCompleted: true),
        HabitLogModel(habitId: '1', date: dateKey(dayBefore), isCompleted: true),
      ];
      expect(StreakCalculator.calculate(logs), 2);
    });

    test('Seri kırıksa (dün tamamlanmamış) 0 döner', () {
      final today = DateTime.now();
      final dayBefore = today.subtract(const Duration(days: 2));

      final logs = [
         // Dün eksik
        HabitLogModel(habitId: '1', date: dateKey(dayBefore), isCompleted: true),
        HabitLogModel(habitId: '1', date: dateKey(today.subtract(const Duration(days: 3))), isCompleted: true),
      ];
      // Bugün veya dün tamamlanmadığı için mevcut Streak sıfırdır (seri bozulmuş).
      expect(StreakCalculator.calculate(logs), 0);
    });
  });
}
