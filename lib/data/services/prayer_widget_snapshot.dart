// Namaz widget’ı için tek kaynak: konum etiketi + sıradaki vakit adı + geri sayım.
// Tek günlük [PrayerTimesModel] ile çalışır; önceki gün Yatsısı için aynı saat
// (isha) önceki takvim gününe taşınır — dakika günler arası biraz sapabilir.

import '../models/prayer_times_model.dart';
import '../quote_pools/localized_pool_fields.dart';

/// Konum satırı: "İzmit, Türkiye"
String formatWidgetLocationLabel(
  String city,
  String country, {
  String localeCode = 'tr',
}) {
  final c = city.trim();
  final u = _countryDisplay(country, localeCode: localeCode);
  if (c.isEmpty) return u;
  return '$c, $u';
}

String _countryDisplay(String country, {String localeCode = 'tr'}) {
  final t = country.trim();
  if (t.isEmpty) return '';
  final lower = t.toLowerCase();
  if (lower == 'turkey' || lower == 'türkiye') {
    switch (normalizeLocaleCode(localeCode)) {
      case 'en':
        return 'Turkey';
      case 'ar':
        return 'تركيا';
      default:
        return 'Türkiye';
    }
  }
  return t;
}

class PrayerWidgetSnapshot {
  const PrayerWidgetSnapshot({
    required this.valid,
    required this.locationLine,
    required this.nextName,
    required this.remaining,
    required this.countdownLabel,
  });

  final bool valid;
  final String locationLine;
  final String nextName;
  final Duration remaining;

  /// "H:MM:SS"
  final String countdownLabel;

  static PrayerWidgetSnapshot invalid(String message) => PrayerWidgetSnapshot(
    valid: false,
    locationLine: message,
    nextName: '—',
    remaining: Duration.zero,
    countdownLabel: '—',
  );

  /// [now] yerel saat; model bugünün vakitleriyle uyumlu olmalı.
  static PrayerWidgetSnapshot fromModel({
    required PrayerTimesModel model,
    required DateTime now,
    required String locationLine,
    String localeCode = 'tr',
  }) {
    final lc = normalizeLocaleCode(localeCode);
    String name(String tr, String en, String ar) {
      if (lc.startsWith('en')) return en;
      if (lc.startsWith('ar')) return ar;
      return tr;
    }

    final cal = DateTime(now.year, now.month, now.day);
    if (!model.matchesCalendarDay(cal)) {
      return invalid(name('Güncelleniyor…', 'Updating…', 'جاري التحديث…'));
    }

    final base = _parseDate(model.date);
    if (base == null) {
      return invalid('—');
    }

    final events = <({String name, DateTime at})>[];
    final prevDay = base.subtract(const Duration(days: 1));
    final nextDay = base.add(const Duration(days: 1));

    // Önceki gecenin Yatsısı (aynı HH:mm — model tek günlük olduğu için yaklaşık).
    events.add((
      name: name('Yatsı', 'Isha', 'العشاء'),
      at: _at(prevDay, model.isha),
    ));
    events.add((
      name: name('İmsak', 'Fajr', 'الفجر'),
      at: _at(base, model.fajr),
    ));
    events.add((
      name: name('Güneş', 'Sunrise', 'الشروق'),
      at: _at(base, model.sunrise),
    ));
    events.add((
      name: name('Öğle', 'Dhuhr', 'الظهر'),
      at: _at(base, model.dhuhr),
    ));
    events.add((
      name: name('İkindi', 'Asr', 'العصر'),
      at: _at(base, model.asr),
    ));
    events.add((
      name: name('Akşam', 'Maghrib', 'المغرب'),
      at: _at(base, model.maghrib),
    ));
    events.add((
      name: name('Yatsı', 'Isha', 'العشاء'),
      at: _at(base, model.isha),
    ));
    events.add((
      name: name('İmsak', 'Fajr', 'الفجر'),
      at: _at(nextDay, model.fajr),
    ));
    // Uzun süre uygulama açılmazsa sıradaki İmsaklar (sadece sabah eşiği).
    for (var i = 2; i <= 5; i++) {
      events.add((
        name: name('İmsak', 'Fajr', 'الفجر'),
        at: _at(base.add(Duration(days: i)), model.fajr),
      ));
    }

    events.sort((a, b) => a.at.compareTo(b.at));

    ({String name, DateTime at})? next;
    for (final e in events) {
      if (e.at.isAfter(now)) {
        next = e;
        break;
      }
    }

    if (next == null) {
      return invalid('—');
    }

    final remaining = next.at.difference(now);

    return PrayerWidgetSnapshot(
      valid: true,
      locationLine: locationLine,
      nextName: next.name,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      countdownLabel: _formatHms(
        remaining.isNegative ? Duration.zero : remaining,
      ),
    );
  }

  static DateTime? _parseDate(String ymd) {
    final p = ymd.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static DateTime _at(DateTime day, String hm) {
    final p = hm.split(':');
    final h = int.parse(p[0]);
    final min = int.parse(p[1]);
    return DateTime(day.year, day.month, day.day, h, min);
  }

  static String _formatHms(Duration d) {
    final s = d.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
