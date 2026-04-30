// test/prayer_times_model_test.dart
//
// `PrayerTimesModel` için regresyon testleri. Faz 1'de çözülen kritik
// crash-safety iyileştirmelerini koruma altına alıyor:
//   - Aladhan/Diyanet yanıtı bozulursa uygulama çökmüyor, `FormatException`
//     fırlatıyor (çağıran katman yakalar).
//   - Hive cache bozulursa (eski şema / korrupsiyon) yine `FormatException`.
//   - Sıradaki namaz hesabı (fajr ile sunrise arası "Sabah çıkıyor" uyarısı)
//     doğru sonucu veriyor.

import 'package:arin/data/models/prayer_times_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrayerTimesModel.fromJson', () {
    test('Aladhan yanıtını "HH:MM" formatına indirger', () {
      final m = PrayerTimesModel.fromJson(
        {
          'Fajr': '05:14 (+03)',
          'Sunrise': '06:45',
          'Dhuhr': '13:03 (+03)',
          'Asr': '16:41',
          'Maghrib': '19:21',
          'Isha': '20:44',
          'Imsak': '05:04',
        },
        '2026-04-22',
        'Kocaeli',
      );

      expect(m.fajr, '05:14');
      expect(m.imsak, '05:04');
      expect(m.sunrise, '06:45');
      expect(m.dhuhr, '13:03');
      expect(m.asr, '16:41');
      expect(m.maghrib, '19:21');
      expect(m.isha, '20:44');
      expect(m.date, '2026-04-22');
      expect(m.city, 'Kocaeli');
    });

    test('Imsak eksikse fajr değeri kullanılır', () {
      final m = PrayerTimesModel.fromJson(
        {
          'Fajr': '05:14',
          'Sunrise': '06:45',
          'Dhuhr': '13:03',
          'Asr': '16:41',
          'Maghrib': '19:21',
          'Isha': '20:44',
        },
        '2026-04-22',
        'İstanbul',
      );
      expect(m.imsak, equals(m.fajr));
    });

    test('Zorunlu alan eksikse FormatException fırlatır — çökme yok', () {
      expect(
        () => PrayerTimesModel.fromJson(
          {
            // Fajr kasıtlı eksik
            'Sunrise': '06:45',
            'Dhuhr': '13:03',
            'Asr': '16:41',
            'Maghrib': '19:21',
            'Isha': '20:44',
          },
          '2026-04-22',
          'Ankara',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('Alan yanlış tipte gelirse FormatException fırlatır', () {
      expect(
        () => PrayerTimesModel.fromJson(
          {
            'Fajr': 514, // String değil, int
            'Sunrise': '06:45',
            'Dhuhr': '13:03',
            'Asr': '16:41',
            'Maghrib': '19:21',
            'Isha': '20:44',
          },
          '2026-04-22',
          'İzmir',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('Alan boş string ise FormatException fırlatır', () {
      expect(
        () => PrayerTimesModel.fromJson(
          {
            'Fajr': '   ',
            'Sunrise': '06:45',
            'Dhuhr': '13:03',
            'Asr': '16:41',
            'Maghrib': '19:21',
            'Isha': '20:44',
          },
          '2026-04-22',
          'Bursa',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PrayerTimesModel.fromMap (Hive cache)', () {
    test('Geçerli map doğru parse edilir', () {
      final m = PrayerTimesModel.fromMap({
        'fajr': '05:14',
        'imsak': '05:04',
        'sunrise': '06:45',
        'dhuhr': '13:03',
        'asr': '16:41',
        'maghrib': '19:21',
        'isha': '20:44',
        'date': '2026-04-22',
        'city': 'Kocaeli',
      });
      expect(m.fajr, '05:14');
      expect(m.city, 'Kocaeli');
    });

    test('Imsak boşsa fajr ile doldurulur', () {
      final m = PrayerTimesModel.fromMap({
        'fajr': '05:14',
        'imsak': '',
        'sunrise': '06:45',
        'dhuhr': '13:03',
        'asr': '16:41',
        'maghrib': '19:21',
        'isha': '20:44',
        'date': '2026-04-22',
        'city': 'Kocaeli',
      });
      expect(m.imsak, '05:14');
    });

    test('Bozuk cache (eksik alan) FormatException fırlatır', () {
      expect(
        () => PrayerTimesModel.fromMap({
          'fajr': '05:14',
          // sunrise eksik
          'dhuhr': '13:03',
          'asr': '16:41',
          'maghrib': '19:21',
          'isha': '20:44',
          'date': '2026-04-22',
          'city': 'Kocaeli',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PrayerTimesModel.fromDiyanet', () {
    test('Diyanet şemasını doğru alanlara haritalar', () {
      final m = PrayerTimesModel.fromDiyanet(
        {
          'Imsak': '04:04',
          'Gunes': '05:45',
          'Ogle': '12:03',
          'Ikindi': '15:41',
          'Aksam': '18:21',
          'Yatsi': '19:44',
        },
        '2026-04-22',
        'Kocaeli',
      );
      expect(m.imsak, '04:04');
      expect(m.fajr, '04:04'); // Diyanet'te Imsak = Fajr
      expect(m.sunrise, '05:45');
      expect(m.dhuhr, '12:03');
      expect(m.asr, '15:41');
      expect(m.maghrib, '18:21');
      expect(m.isha, '19:44');
    });

    test('Eksik alan "00:00" ile doldurulur (çökmez)', () {
      final m = PrayerTimesModel.fromDiyanet(
        {'Imsak': '04:04'},
        '2026-04-22',
        'X',
      );
      expect(m.imsak, '04:04');
      expect(m.dhuhr, '00:00');
    });
  });

  group('PrayerTimesModel.nextPrayer', () {
    final model = PrayerTimesModel.fromJson(
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

    test('Öğle öncesi "sıradaki: Öğle" döner', () {
      final now = DateTime(2026, 4, 22, 10, 0);
      final next = model.nextPrayer(now);
      expect(next?.name, 'Öğle');
      expect(next?.isUrgentFajr, false);
    });

    test('Sabah ezanı ile güneş arası → "Sabah çıkıyor" uyarısı', () {
      final now = DateTime(2026, 4, 22, 5, 30);
      final next = model.nextPrayer(now);
      expect(next?.name, 'Sabah');
      expect(next?.isUrgentFajr, true);
    });

    test('Yatsı sonrası → ertesi gün Sabah', () {
      final now = DateTime(2026, 4, 22, 23, 0);
      final next = model.nextPrayer(now);
      expect(next?.name, 'Sabah');
      expect(next?.isUrgentFajr, false);
      // Kalan süre bir sonraki güne sarkar — pozitif, < 24 saat.
      expect(next!.remaining.inHours, inInclusiveRange(0, 24));
    });
  });

  group('PrayerTimesModel.shiftAllMinutes', () {
    test('Gün sınırı modüler şekilde sarar', () {
      final m = PrayerTimesModel.fromJson(
        {
          'Fajr': '23:50',
          'Sunrise': '00:10',
          'Dhuhr': '12:00',
          'Asr': '15:00',
          'Maghrib': '18:00',
          'Isha': '20:00',
        },
        '2026-04-22',
        'X',
      );
      final shifted = m.shiftAllMinutes(20);
      expect(shifted.fajr, '00:10'); // 23:50 + 20 dk → 00:10 ertesi gün
      expect(shifted.sunrise, '00:30');
    });

    test('Negatif kaydırma da doğru çalışır', () {
      final m = PrayerTimesModel.fromJson(
        {
          'Fajr': '00:10',
          'Sunrise': '06:00',
          'Dhuhr': '12:00',
          'Asr': '15:00',
          'Maghrib': '18:00',
          'Isha': '20:00',
        },
        '2026-04-22',
        'X',
      );
      final shifted = m.shiftAllMinutes(-20);
      expect(shifted.fajr, '23:50');
    });
  });

  group('PrayerTimesModel.matchesCalendarDay', () {
    test('Aynı gün → true', () {
      final m = PrayerTimesModel.fromMap({
        'fajr': '05:00',
        'sunrise': '06:30',
        'dhuhr': '13:00',
        'asr': '16:30',
        'maghrib': '19:00',
        'isha': '20:30',
        'date': '2026-04-22',
        'city': 'X',
      });
      expect(m.matchesCalendarDay(DateTime(2026, 4, 22)), isTrue);
      expect(m.matchesCalendarDay(DateTime(2026, 4, 23)), isFalse);
    });
  });
}
