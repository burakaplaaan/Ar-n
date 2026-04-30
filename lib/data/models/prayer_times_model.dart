// lib/data/models/prayer_times_model.dart
// Aladhan API cevabını Dart nesnesine dönüştüren model.
// Hive ile günlük önbellekleme için de kullanılır.

class PrayerTimesModel {
  /// Orucun başladığı an (API’de yoksa [fajr] ile doldurulur).
  final String imsak;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String date; // "yyyy-MM-dd"
  final String city;

  const PrayerTimesModel({
    required this.imsak,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.city,
  });

  /// Aladhan API timings JSON'undan oluşturur.
  ///
  /// API şeması bozulur veya bir alan eksik/yanlış tip ile gelirse
  /// `FormatException` fırlatılır — çağıran (fetch katmanı) bunu yakalayıp
  /// cache fallback'e düşer. Eskiden doğrudan `as String` cast yapılıyordu,
  /// bu da namaz ekranında tüm uygulamayı çökertiyordu.
  factory PrayerTimesModel.fromJson(
    Map<String, dynamic> timings,
    String date,
    String city,
  ) {
    // Aladhan "05:14 (+03)" formatından sadece "HH:MM" alır; null / boş /
    // format dışı değerler `FormatException` ile bildirilir.
    String req(String key) {
      final v = timings[key];
      if (v is! String) {
        throw FormatException('Aladhan timings "$key" missing or not string');
      }
      final first = v.trim().split(' ').first;
      if (first.isEmpty) {
        throw FormatException('Aladhan timings "$key" empty');
      }
      return first;
    }

    final fajrStr = req('Fajr');
    final imsakRaw = timings['Imsak'];
    final imsakStr = imsakRaw is String && imsakRaw.trim().isNotEmpty
        ? imsakRaw.trim().split(' ').first
        : fajrStr;

    return PrayerTimesModel(
      imsak: imsakStr,
      fajr: fajrStr,
      sunrise: req('Sunrise'),
      dhuhr: req('Dhuhr'),
      asr: req('Asr'),
      maghrib: req('Maghrib'),
      isha: req('Isha'),
      date: date,
      city: city,
    );
  }

  /// Diyanet / ezanvakti.emushaf.net bir-gün kaydından oluşturur.
  ///
  /// Aladhan şeması ile Diyanet şeması farklı alan adları kullanıyor
  /// (`Fajr` → `Imsak`? hayır Diyanet'te `Imsak` var; `Sunrise` → `Gunes`;
  /// `Dhuhr` → `Ogle` vb.). Bu ayrı factory sadece alan eşlemesi yapar;
  /// modelin dahili saat-string formatı değişmez — nextPrayer / salat
  /// hesapları aynı kalır.
  ///
  /// Diyanet'te Aladhan'daki gibi "fajr öncesi imsak" gibi ayrım yok;
  /// `Imsak` doğrudan imsak/fajr ortak olarak kullanılır. UI'da "İmsak"
  /// vakti olarak `fajr` değerini gösterdiğimiz için onu da
  /// `Imsak`'tan türetiyoruz (Türkiye'de ezan imsak değil güneş öncesi
  /// okunmaz; ancak bildirim için "İmsak = Imsak" Diyanet takviminde
  /// tutarlı).
  ///
  /// NOT: ezanvakti `Gunes` (doğuş) = Aladhan `Sunrise`; `Gunes` zaten
  /// stringte dt; `GunesDogus` field'ı da döner ama pratikte `Gunes`
  /// kullanılıyor (15 yıldır stabil).
  factory PrayerTimesModel.fromDiyanet(
    Map<String, dynamic> day,
    String date,
    String city,
  ) {
    String? s(dynamic v) {
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final imsak = s(day['Imsak']) ?? '00:00';
    // Aladhan yolu Fajr/Imsak'ı ayrı tuttuğu için modelde iki ayrı alan var;
    // Diyanet'te tek "Imsak" var, ikisini de ondan doldur. UI kodu çoğu
    // yerde `fajr` okuyor (İmsak vakti).
    final fajr = imsak;
    return PrayerTimesModel(
      imsak: imsak,
      fajr: fajr,
      sunrise: s(day['Gunes']) ?? s(day['GunesDogus']) ?? '00:00',
      dhuhr: s(day['Ogle']) ?? '00:00',
      asr: s(day['Ikindi']) ?? '00:00',
      maghrib: s(day['Aksam']) ?? '00:00',
      isha: s(day['Yatsi']) ?? '00:00',
      date: date,
      city: city,
    );
  }

  /// Hive'a Map olarak kaydedilir (TypeAdapter gerekmez)
  Map<String, dynamic> toMap() => {
    'imsak': imsak,
    'fajr': fajr,
    'sunrise': sunrise,
    'dhuhr': dhuhr,
    'asr': asr,
    'maghrib': maghrib,
    'isha': isha,
    'date': date,
    'city': city,
  };

  /// Hive Map'inden okur. Bozuk/eski format → `FormatException` (çağıran
  /// katman yakalayıp kaydı atlar veya siler). Sessiz cast hatası yerine
  /// açık sözleşme; uygulama bir kaydı okuyamasa bile çökmesin.
  factory PrayerTimesModel.fromMap(Map<dynamic, dynamic> map) {
    String req(String key) {
      final v = map[key];
      if (v is! String || v.isEmpty) {
        throw FormatException('PrayerTimes cache "$key" missing');
      }
      return v;
    }

    final fajr = req('fajr');
    final imsakRaw = map['imsak'];
    final imsak = imsakRaw is String && imsakRaw.isNotEmpty ? imsakRaw : fajr;

    return PrayerTimesModel(
      imsak: imsak,
      fajr: fajr,
      sunrise: req('sunrise'),
      dhuhr: req('dhuhr'),
      asr: req('asr'),
      maghrib: req('maghrib'),
      isha: req('isha'),
      date: req('date'),
      city: req('city'),
    );
  }

  /// Tüm saat alanlarına aynı dakika ekler (negatif = öne çeker). Yalnızca
  /// admin test kaydırması; gün sınırı 24 saat içinde modüler sarılır.
  PrayerTimesModel shiftAllMinutes(int deltaMinutes) {
    if (deltaMinutes == 0) return this;
    String s(String hm) => _shiftHmString(hm, deltaMinutes);
    return PrayerTimesModel(
      imsak: s(imsak),
      fajr: s(fajr),
      sunrise: s(sunrise),
      dhuhr: s(dhuhr),
      asr: s(asr),
      maghrib: s(maghrib),
      isha: s(isha),
      date: date,
      city: city,
    );
  }

  static String _shiftHmString(String hm, int deltaMinutes) {
    final p = hm.split(':');
    var total = int.parse(p[0]) * 60 + int.parse(p[1]) + deltaMinutes;
    total %= 24 * 60;
    if (total < 0) total += 24 * 60;
    final h = total ~/ 60;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Namaz vakitlerini sıralı liste olarak döndürür
  List<({String name, String time})> get orderedPrayers => [
    (name: 'İmsak', time: fajr),
    (name: 'Güneş', time: sunrise),
    (name: 'Öğle', time: dhuhr),
    (name: 'İkindi', time: asr),
    (name: 'Akşam', time: maghrib),
    (name: 'Yatsı', time: isha),
  ];

  /// [day] takvim gününde [index] (0=İmsak…4=Yatsı) vaktinin başlangıç anı.
  DateTime salatSlotStart(int index, DateTime day) {
    assert(index >= 0 && index < 5);
    final hm = [fajr, dhuhr, asr, maghrib, isha][index];
    final p = hm.split(':');
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(p[0]),
      int.parse(p[1]),
    );
  }

  /// Canlı satırda tiklerin bağlanacağı takvim günü: imsaktan önceyse bir önceki gün
  /// (yatsı → imsak arası gece yeni takvim gününe dönmüş olsa da önceki günün yatsısı).
  DateTime salatTickCalendarDay(DateTime now) {
    final cal = DateTime(now.year, now.month, now.day);
    if (!matchesCalendarDay(cal)) return cal;
    final fajrToday = salatSlotStart(0, cal);
    if (now.isBefore(fajrToday)) {
      return cal.subtract(const Duration(days: 1));
    }
    return cal;
  }

  /// [now] anında bu vakte tik atılabilir mi: vakit girmiş, sonraki farz vaktine kadar.
  /// Yatsı (4): yatsı girişinden ertesi imsâke kadar (gece yarısı sonrası dahil).
  ///
  /// UI: yalnızca bu kurala göre tik; yükleme veya günü uyuşmayan önbellekte
  /// tüm vakitlere `true` fallback vermeyin.
  bool isSalatIndexInMarkingWindow(int index, DateTime now, DateTime day) {
    assert(index >= 0 && index < 5);
    final starts = List.generate(5, (i) => salatSlotStart(i, day));
    if (now.isBefore(starts[index])) return false;
    if (index < 4) {
      return now.isBefore(starts[index + 1]);
    }
    final nextFajr = salatSlotStart(0, day.add(const Duration(days: 1)));
    return now.isBefore(nextFajr);
  }

  /// Model bu güne ait mi (önbellek gün kayması önleme).
  bool matchesCalendarDay(DateTime day) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return date == key;
  }

  /// Şu an için sıradaki namaz ismini ve kalan süreyi döndürür.
  ///
  /// Özel durum — "İmsak çıkıyor" uyarısı:
  /// Kullanıcı sabah ezanından SONRA, ancak GÜNEŞ DOĞMADAN önce ekrana
  /// bakarsa, bu sürede farz olan sabah namazını kılması gerekir.
  /// Eski versiyon bu dilimde "Sıradaki: Öğle, 6 saat" gösterirdi → kullanıcı
  /// sabah namazını kaçırırdı. Artık güneşe kadar kalan süre "İmsak"
  /// ismiyle ve [isUrgentFajr]=true ile döndürülür; UI bunu kırmızı/uyarı
  /// tonuyla gösterebilir.
  ({String name, Duration remaining, bool isUrgentFajr})? nextPrayer(
    DateTime now,
  ) {
    // 1) İmsak-çıkıyor kontrolü: fajr ≤ now < sunrise
    final fajrToday = _toTodayDateTime(fajr, now);
    final sunriseToday = _toTodayDateTime(sunrise, now);
    if (fajrToday != null &&
        sunriseToday != null &&
        !now.isBefore(fajrToday) &&
        now.isBefore(sunriseToday)) {
      return (
        name: 'İmsak',
        remaining: sunriseToday.difference(now),
        isUrgentFajr: true,
      );
    }

    // 2) Normal akış — Güneş vakti atlanır, sıradaki farz aranır.
    for (final prayer in orderedPrayers) {
      if (prayer.name == 'Güneş') continue;
      final prayerTime = _toTodayDateTime(prayer.time, now);
      if (prayerTime == null) continue;
      if (prayerTime.isAfter(now)) {
        return (
          name: prayer.name,
          remaining: prayerTime.difference(now),
          isUrgentFajr: false,
        );
      }
    }

    // 3) Gün bitti → ertesi günün İmsak vakti
    final fajrParts = fajr.split(':');
    final tomorrowFajr = DateTime(
      now.year,
      now.month,
      now.day + 1,
      int.parse(fajrParts[0]),
      int.parse(fajrParts[1]),
    );
    return (
      name: 'İmsak',
      remaining: tomorrowFajr.difference(now),
      isUrgentFajr: false,
    );
  }

  /// "HH:MM" → bugünün o saati. Hatalı format → null.
  DateTime? _toTodayDateTime(String hhmm, DateTime now) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(now.year, now.month, now.day, h, m);
  }
}
