import 'package:arin/presentation/qibla/zikir_bilgisi_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily reflection index stays inside the localized list', () {
    expect(zikirDailyReflectionIndex(now: DateTime(2026, 8, 16), length: 0), 0);
    final short = zikirDailyReflectionIndex(
      now: DateTime(2026, 8, 16),
      length: 8,
    );
    final full = zikirDailyReflectionIndex(
      now: DateTime(2026, 8, 16),
      length: 30,
    );
    expect(short, inInclusiveRange(0, 7));
    expect(full, inInclusiveRange(0, 29));
    // Old 8-item ar/en lists crashed on this calendar day (index >= 8).
    expect(full, greaterThanOrEqualTo(8));
    for (var day = 0; day < 400; day++) {
      final now = DateTime(2020, 1, 1).add(Duration(days: day));
      final index = zikirDailyReflectionIndex(now: now, length: 30);
      expect(index, inInclusiveRange(0, 29));
    }
  });
}
