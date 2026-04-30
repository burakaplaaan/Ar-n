// Kaza namazı tahmini hesaplama — takip ekranına aktarılabilir tutarlı matematik.
//
// Model (rehber):
// - Borç, buluğ tarihinden bugüne kadar her takvim günü için 6 namaz (5 farz + vitir).
// - Kadın: kesişen her takvim ayı için kabaca 6 gün namazdan muaf (hayız); muaf gün sayısı
//   toplam günü aşamaz.
// - "Kılınan gün": o günün tamamında tüm vakitler kılındı varsayımı → gün × 6 namaz düşülür.
// - Kullanıcının girdiği kılınan gün, hesaplanan borçlu günü geçemez.

/// Hesap ara sonucu (isteğe bağlı özet / hata ayıklama).
class KazaCalculationResult {
  const KazaCalculationResult({
    required this.pubertyDate,
    required this.periodEnd,
    required this.inclusiveCalendarDays,
    required this.hayizExemptDays,
    required this.effectiveLiableDays,
    required this.prayedFullDaysInput,
    required this.prayedFullDaysApplied,
    required this.totalPrayersOwed,
    required this.prayersCredited,
    required this.remainingPrayers,
  });

  final DateTime pubertyDate;
  final DateTime periodEnd;

  /// Buluğ günü ile bitiş günü dahil aradaki takvim günü sayısı.
  final int inclusiveCalendarDays;

  /// Kadın: hayız için düşülen gün (takvim ayı × 6, toplam günü geçmez).
  final int hayizExemptDays;

  /// Namaz borcu hesabına giren gün: takvim günü − muaf gün.
  final int effectiveLiableDays;

  final int prayedFullDaysInput;

  /// Borçlu güne sığdırılmış kılınan gün (min(girdi, effectiveLiableDays)).
  final int prayedFullDaysApplied;

  /// effectiveLiableDays × 6
  final int totalPrayersOwed;

  /// prayedFullDaysApplied × 6
  final int prayersCredited;

  /// max(0, totalPrayersOwed − prayersCredited)
  final int remainingPrayers;
}

abstract final class KazaCalculator {
  static const int prayersPerLiableDay = 6;
  static const int approxHayizExemptDaysPerCalendarMonth = 6;

  static int minPubertyAge({required bool isFemale}) => isFemale ? 9 : 12;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _addYears(DateTime birth, int years) {
    var d = birth;
    for (var i = 0; i < years; i++) {
      try {
        d = DateTime(d.year + 1, d.month, d.day);
      } catch (_) {
        d = DateTime(d.year + 1, d.month, 28);
      }
    }
    return d;
  }

  /// [start] ve [end] dahil; aynı gün → 1.
  static int inclusiveCalendarDayCount(DateTime start, DateTime end) {
    final a = _dateOnly(start);
    final b = _dateOnly(end);
    if (b.isBefore(a)) return 0;
    return b.difference(a).inDays + 1;
  }

  /// [start]–[end] aralığının dokunduğu farklı takvim ayı sayısı (her iki uç dahil).
  static int inclusiveCalendarMonthsSpanned(DateTime start, DateTime end) {
    final a = _dateOnly(start);
    final b = _dateOnly(end);
    if (b.isBefore(a)) return 0;
    return (b.year - a.year) * 12 + b.month - a.month + 1;
  }

  /// Kadınlar için hayızda namaz borcu olmayan günlerin tahmini toplamı.
  static int hayizExemptCalendarDays({
    required bool isFemale,
    required DateTime from,
    required DateTime to,
  }) {
    if (!isFemale) return 0;
    final total = inclusiveCalendarDayCount(from, to);
    if (total <= 0) return 0;
    final months = inclusiveCalendarMonthsSpanned(from, to);
    final raw = months * approxHayizExemptDaysPerCalendarMonth;
    return raw < total ? raw : total;
  }

  static KazaCalculationResult compute({
    required DateTime birthDate,
    required int pubertyAgeInput,
    required bool isFemale,
    required int prayedFullDays,
    DateTime? now,
  }) {
    final minA = minPubertyAge(isFemale: isFemale);
    final ageYears = pubertyAgeInput < minA ? minA : pubertyAgeInput;
    final puberty = _addYears(_dateOnly(birthDate), ageYears);

    final today = now ?? DateTime.now();
    final end = _dateOnly(today);

    if (end.isBefore(puberty)) {
      return KazaCalculationResult(
        pubertyDate: puberty,
        periodEnd: end,
        inclusiveCalendarDays: 0,
        hayizExemptDays: 0,
        effectiveLiableDays: 0,
        prayedFullDaysInput: prayedFullDays,
        prayedFullDaysApplied: 0,
        totalPrayersOwed: 0,
        prayersCredited: 0,
        remainingPrayers: 0,
      );
    }

    final inclusiveDays = inclusiveCalendarDayCount(puberty, end);
    final exempt = hayizExemptCalendarDays(
      isFemale: isFemale,
      from: puberty,
      to: end,
    );
    final effectiveDays = inclusiveDays - exempt;
    final safeEffective = effectiveDays < 0 ? 0 : effectiveDays;

    final prayedIn = prayedFullDays < 0 ? 0 : prayedFullDays;
    final prayedApplied =
        prayedIn > safeEffective ? safeEffective : prayedIn;

    final owed = safeEffective * prayersPerLiableDay;
    final credited = prayedApplied * prayersPerLiableDay;
    var remaining = owed - credited;
    if (remaining < 0) remaining = 0;

    return KazaCalculationResult(
      pubertyDate: puberty,
      periodEnd: end,
      inclusiveCalendarDays: inclusiveDays,
      hayizExemptDays: exempt,
      effectiveLiableDays: safeEffective,
      prayedFullDaysInput: prayedIn,
      prayedFullDaysApplied: prayedApplied,
      totalPrayersOwed: owed,
      prayersCredited: credited,
      remainingPrayers: remaining,
    );
  }

  /// [compute] sonucundaki kalan toplam namaz sayısı.
  static int remainingTotalPrayers({
    required DateTime birthDate,
    required int pubertyAgeInput,
    required bool isFemale,
    required int prayedFullDays,
    DateTime? now,
  }) {
    return compute(
      birthDate: birthDate,
      pubertyAgeInput: pubertyAgeInput,
      isFemale: isFemale,
      prayedFullDays: prayedFullDays,
      now: now,
    ).remainingPrayers;
  }

  /// Toplamı 6 vakte mümkün olduğunca eşit böler (kalan ilk slotlara +1).
  static List<int> distributeAcrossSix(int total) {
    if (total <= 0) {
      return [0, 0, 0, 0, 0, 0];
    }
    final base = total ~/ 6;
    var rest = total - base * 6;
    final out = List<int>.filled(6, base);
    for (var i = 0; i < 6 && rest > 0; i++) {
      out[i]++;
      rest--;
    }
    return out;
  }
}
