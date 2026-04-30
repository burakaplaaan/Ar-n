import 'package:arin/data/services/kaza_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('erkek: buluğdan sonra 30 gün, kılınan yok → 30×6 namaz', () {
    final r = KazaCalculator.compute(
      birthDate: DateTime(2000, 1, 1),
      pubertyAgeInput: 12,
      isFemale: false,
      prayedFullDays: 0,
      now: DateTime(2012, 1, 30),
    );
    expect(r.inclusiveCalendarDays, 30);
    expect(r.hayizExemptDays, 0);
    expect(r.effectiveLiableDays, 30);
    expect(r.totalPrayersOwed, 180);
    expect(r.remainingPrayers, 180);
  });

  test('kılınan tam gün borçlu günü aşamaz', () {
    final r = KazaCalculator.compute(
      birthDate: DateTime(2000, 1, 1),
      pubertyAgeInput: 12,
      isFemale: false,
      prayedFullDays: 9999,
      now: DateTime(2012, 1, 10),
    );
    expect(r.effectiveLiableDays, 10);
    expect(r.prayedFullDaysApplied, 10);
    expect(r.remainingPrayers, 0);
  });

  test('kadın: hayız muafiyeti ay sayısı × 6 (toplam günü geçmez)', () {
    final r = KazaCalculator.compute(
      birthDate: DateTime(2000, 1, 1),
      pubertyAgeInput: 12,
      isFemale: true,
      prayedFullDays: 0,
      now: DateTime(2012, 3, 31),
    );
    expect(r.inclusiveCalendarDays, 90);
    expect(r.hayizExemptDays, 18);
    expect(r.effectiveLiableDays, 72);
    expect(r.remainingPrayers, 72 * 6);
  });

  test('buluğ yaşı alt sınıra çekilir', () {
    final r = KazaCalculator.compute(
      birthDate: DateTime(2010, 6, 15),
      pubertyAgeInput: 5,
      isFemale: false,
      prayedFullDays: 0,
      now: DateTime(2022, 6, 15),
    );
    expect(r.pubertyDate, DateTime(2022, 6, 15));
    expect(r.inclusiveCalendarDays, 1);
    expect(r.remainingPrayers, 6);
  });

  test('distributeAcrossSix eşit dağıtır', () {
    expect(KazaCalculator.distributeAcrossSix(7), [2, 1, 1, 1, 1, 1]);
    expect(KazaCalculator.distributeAcrossSix(6), [1, 1, 1, 1, 1, 1]);
  });
}
