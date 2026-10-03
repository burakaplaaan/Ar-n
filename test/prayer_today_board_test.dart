import 'package:arin/data/models/prayer_times_model.dart';
import 'package:arin/data/services/prayer_today_board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const model = PrayerTimesModel(
    imsak: '04:10',
    fajr: '04:12',
    sunrise: '06:00',
    dhuhr: '13:10',
    asr: '16:45',
    maghrib: '19:42',
    isha: '21:05',
    date: '2026-08-18',
    city: 'Istanbul',
  );

  test('günlük namaz tahtası 5 slot ve tik sayısını taşır', () {
    final board = PrayerTodayBoard.build(
      models: const [model],
      now: DateTime(2026, 8, 18, 15, 0),
      nextAt: DateTime(2026, 8, 18, 16, 45),
      done: const [true, true, false, false, false],
      tickDay: DateTime(2026, 8, 18),
    );

    expect(board['nextClock'], '16:45');
    expect(board['doneCount'], 2);
    expect(board['day'], '2026-08-18');
    expect(board['trackingEnabled'], isTrue);
    expect(
      board['validFromEpochMs'],
      DateTime(2026, 8, 18, 4, 12).millisecondsSinceEpoch,
    );
    // Ertesi günün vakti yoksa aynı saat kullanılır.
    expect(
      board['validUntilEpochMs'],
      DateTime(2026, 8, 19, 4, 12).millisecondsSinceEpoch,
    );
    expect(board['hijri'], isA<String>());
    expect((board['hijri'] as String).isNotEmpty, isTrue);

    final slots = board['slots'] as List<Map<String, Object?>>;
    expect(slots, hasLength(5));
    expect(slots.map((e) => e['name']), [
      'İmsak',
      'Öğle',
      'İkindi',
      'Akşam',
      'Yatsı',
    ]);
    expect(slots[0]['done'], isTrue);
    expect(slots[2]['done'], isFalse);
    expect(slots[0]['time'], '04:12');
  });

  test('imsaktan önce tik günü bir önceki takvim günüdür', () {
    final day = PrayerTodayBoard.salatBoardDay(
      models: const [model],
      now: DateTime(2026, 8, 18, 2, 0),
    );
    expect(day, DateTime(2026, 8, 17));
    expect(
      PrayerTodayBoard.salatBoardDayFromClock(
        now: DateTime(2026, 8, 18, 2, 0),
        imsakClock: '04:12',
      ),
      DateTime(2026, 8, 17),
    );
  });

  test('gece yarısından sonra pencere ertesi günün imsakına kadar sürer', () {
    const previous = PrayerTimesModel(
      imsak: '04:05',
      fajr: '04:07',
      sunrise: '05:55',
      dhuhr: '13:10',
      asr: '16:45',
      maghrib: '19:43',
      isha: '21:06',
      date: '2026-08-17',
      city: 'Istanbul',
    );
    final board = PrayerTodayBoard.build(
      models: const [previous, model],
      now: DateTime(2026, 8, 18, 2),
      nextAt: DateTime(2026, 8, 18, 4, 12),
      done: const [false, false, false, false, false],
      tickDay: DateTime(2026, 8, 17),
    );

    expect(board['day'], '2026-08-17');
    expect(
      board['validFromEpochMs'],
      DateTime(2026, 8, 17, 4, 7).millisecondsSinceEpoch,
    );
    expect(
      board['validUntilEpochMs'],
      DateTime(2026, 8, 18, 4, 12).millisecondsSinceEpoch,
    );
    final slots = board['slots'] as List<Map<String, Object?>>;
    expect(slots.first['time'], '04:07');
  });

  test(
    'gece yarısı sonrası dünün modeli yoksa pencere bugünün imsakında biter',
    () {
      final board = PrayerTodayBoard.build(
        models: const [model],
        now: DateTime(2026, 8, 18, 0, 30),
        nextAt: DateTime(2026, 8, 18, 4, 12),
        done: const [false, false, false, false, false],
        tickDay: DateTime(2026, 8, 17),
        trackingEnabled: false,
      );

      expect(board['day'], '2026-08-17');
      expect(
        board['validFromEpochMs'],
        DateTime(2026, 8, 17, 4, 12).millisecondsSinceEpoch,
      );
      expect(
        board['validUntilEpochMs'],
        DateTime(2026, 8, 18, 4, 12).millisecondsSinceEpoch,
      );
      expect(board['trackingEnabled'], isFalse);
    },
  );

  test('hiç vakit modeli yoksa pencere yazılmaz', () {
    final board = PrayerTodayBoard.build(
      models: const [],
      now: DateTime(2026, 8, 18, 10),
      nextAt: DateTime(2026, 8, 18, 13, 10),
      done: const [false, false, false, false, false],
    );

    expect(board['validFromEpochMs'], isNull);
    expect(board['validUntilEpochMs'], isNull);
  });
}
