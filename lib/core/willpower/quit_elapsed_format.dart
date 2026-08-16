// Arınma sayacı: yıl / ay / gün / saat / dakika / saniye.
// Ay = 30 gün, yıl = 365 gün (canlı saniye sayacı için takvim sıçraması yok).

import 'package:arin/l10n/app_localizations.dart';

class QuitElapsedParts {
  const QuitElapsedParts({
    required this.years,
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  final int years;
  final int months;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
}

const int kQuitElapsedSecondsPerDay = 86400;
const int kQuitElapsedSecondsPerMonth = 30 * kQuitElapsedSecondsPerDay;
const int kQuitElapsedSecondsPerYear = 365 * kQuitElapsedSecondsPerDay;

QuitElapsedParts quitElapsedParts(Duration duration) {
  var rem = duration.inSeconds;
  if (rem < 0) rem = 0;
  final years = rem ~/ kQuitElapsedSecondsPerYear;
  rem %= kQuitElapsedSecondsPerYear;
  final months = rem ~/ kQuitElapsedSecondsPerMonth;
  rem %= kQuitElapsedSecondsPerMonth;
  final days = rem ~/ kQuitElapsedSecondsPerDay;
  rem %= kQuitElapsedSecondsPerDay;
  final hours = rem ~/ 3600;
  rem %= 3600;
  final minutes = rem ~/ 60;
  final seconds = rem % 60;
  return QuitElapsedParts(
    years: years,
    months: months,
    days: days,
    hours: hours,
    minutes: minutes,
    seconds: seconds,
  );
}

String formatQuitElapsed(Duration duration, AppLocalizations l10n) {
  final p = quitElapsedParts(duration);
  if (p.years > 0) {
    return l10n.quitProgramElapsedYmdHms(
      p.years,
      p.months,
      p.days,
      p.hours,
      p.minutes,
      p.seconds,
    );
  }
  if (p.months > 0) {
    return l10n.quitProgramElapsedMdHms(
      p.months,
      p.days,
      p.hours,
      p.minutes,
      p.seconds,
    );
  }
  if (p.days > 0) {
    return l10n.quitProgramElapsedDHms(
      p.days,
      p.hours,
      p.minutes,
      p.seconds,
    );
  }
  if (p.hours > 0) {
    return l10n.quitProgramElapsedHms(p.hours, p.minutes, p.seconds);
  }
  if (p.minutes > 0) {
    return l10n.quitProgramElapsedMs(p.minutes, p.seconds);
  }
  return l10n.quitProgramElapsedS(p.seconds);
}
