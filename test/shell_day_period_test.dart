import 'package:arin/core/theme/shell_day_period.dart';
import 'package:arin/data/models/prayer_times_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final times = PrayerTimesModel.fromJson(
    {
      'Fajr': '05:00',
      'Sunrise': '06:30',
      'Dhuhr': '13:00',
      'Asr': '16:30',
      'Maghrib': '19:00',
      'Isha': '20:30',
    },
    '2026-04-22',
    'Test',
  );

  group('ShellDayPeriod.fromClock', () {
    test('saat dilimlerini vakte çevirir', () {
      expect(ShellDayPeriod.fromClock(DateTime(2026, 4, 22, 3)), ShellDayPeriod.isha);
      expect(ShellDayPeriod.fromClock(DateTime(2026, 4, 22, 8)), ShellDayPeriod.fajr);
      expect(ShellDayPeriod.fromClock(DateTime(2026, 4, 22, 13)), ShellDayPeriod.dhuhr);
      expect(ShellDayPeriod.fromClock(DateTime(2026, 4, 22, 16)), ShellDayPeriod.asr);
      expect(ShellDayPeriod.fromClock(DateTime(2026, 4, 22, 19)), ShellDayPeriod.maghrib);
      expect(ShellDayPeriod.fromClock(DateTime(2026, 4, 22, 22)), ShellDayPeriod.isha);
    });
  });

  group('ShellDayPeriod.resolve', () {
    test('vakit penceresini namaz saatinden okur', () {
      expect(
        ShellDayPeriod.resolve(DateTime(2026, 4, 22, 5, 30), times),
        ShellDayPeriod.fajr,
      );
      expect(
        ShellDayPeriod.resolve(DateTime(2026, 4, 22, 14, 0), times),
        ShellDayPeriod.dhuhr,
      );
      expect(
        ShellDayPeriod.resolve(DateTime(2026, 4, 22, 17, 0), times),
        ShellDayPeriod.asr,
      );
      expect(
        ShellDayPeriod.resolve(DateTime(2026, 4, 22, 19, 20), times),
        ShellDayPeriod.maghrib,
      );
      expect(
        ShellDayPeriod.resolve(DateTime(2026, 4, 22, 23, 0), times),
        ShellDayPeriod.isha,
      );
    });

    test('imsaktan önce yatsı penceresidir', () {
      expect(
        ShellDayPeriod.resolve(DateTime(2026, 4, 22, 4, 0), times),
        ShellDayPeriod.isha,
      );
    });

    test('vakit yoksa saate düşer', () {
      expect(
        ShellDayPeriod.resolve(DateTime(2026, 4, 22, 8), null),
        ShellDayPeriod.fajr,
      );
    });
  });
}
