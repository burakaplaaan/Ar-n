import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:arin/l10n/app_localizations.dart';

import 'assistant_destinations.dart';

class RamadanCountdown {
  const RamadanCountdown({
    required this.start,
    required this.daysUntil,
    required this.isOngoing,
    required this.dayOfRamadan,
  });

  final DateTime start;
  final int daysUntil;
  final bool isOngoing;
  final int dayOfRamadan;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Umm al-Qura takvimi; hilal 1 gün kaydırabilir.
RamadanCountdown ramadanCountdown(DateTime now) {
  final today = _dateOnly(now);
  final hijri = HijriCalendar.fromDate(today);
  if (hijri.hMonth == 9) {
    final g = HijriCalendar().hijriToGregorian(hijri.hYear, 9, 1);
    return RamadanCountdown(
      start: _dateOnly(g),
      daysUntil: 0,
      isOngoing: true,
      dayOfRamadan: hijri.hDay,
    );
  }
  final year = hijri.hMonth > 9 ? hijri.hYear + 1 : hijri.hYear;
  final g = HijriCalendar().hijriToGregorian(year, 9, 1);
  final start = _dateOnly(g);
  return RamadanCountdown(
    start: start,
    daysUntil: start.difference(today).inDays,
    isOngoing: false,
    dayOfRamadan: 0,
  );
}

bool isRamadanCountdownAsk(String raw) {
  final t = foldAssistantText(raw);
  final ramadan = t.contains('ramazan') ||
      t.contains('ramadan') ||
      t.contains('رمضان');
  if (!ramadan) return false;
  return t.contains('kac gun') ||
      t.contains('kacgun') ||
      t.contains('gun var') ||
      t.contains('gun kal') ||
      t.contains('how many day') ||
      t.contains('days until') ||
      t.contains('days left') ||
      t.contains('ne zaman') ||
      t.contains('when is') ||
      t.contains('when does') ||
      t.contains('كم يوم') ||
      t.contains('كم يوما');
}

String formatRamadanAssistantReply({
  required AppLocalizations l10n,
  required String locale,
  required DateTime now,
}) {
  final c = ramadanCountdown(now);
  final today = DateFormat.yMMMMd(locale).format(_dateOnly(now));
  final date = DateFormat.yMMMMd(locale).format(c.start);
  if (c.isOngoing) {
    return l10n.assistantRamadanOngoing(today, c.dayOfRamadan);
  }
  if (c.daysUntil <= 0) {
    return l10n.assistantRamadanToday(today);
  }
  if (c.daysUntil == 1) {
    return l10n.assistantRamadanTomorrow(today, date);
  }
  return l10n.assistantRamadanDays(today, c.daysUntil, date);
}
