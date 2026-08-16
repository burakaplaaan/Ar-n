import 'package:arin/l10n/app_localizations.dart';

import '../../data/models/prayer_times_model.dart';
import 'assistant_destinations.dart';

enum AssistantPrayerTarget {
  iftar,
  imsak,
  dhuhr,
  asr,
  maghrib,
  isha,
  next,
}

bool isPrayerCountdownAsk(String raw) {
  return matchAssistantPrayerTarget(raw) != null;
}

AssistantPrayerTarget? matchAssistantPrayerTarget(String raw) {
  final t = foldAssistantText(raw);
  if (t.isEmpty || !_hasCountdownAsk(t)) return null;

  if (t.contains('iftar')) return AssistantPrayerTarget.iftar;
  if (t.contains('sahur') || t.contains('imsak')) {
    return AssistantPrayerTarget.imsak;
  }
  if (t.contains('ogle') || t.contains('dhuhr') || t.contains('zuhr')) {
    return AssistantPrayerTarget.dhuhr;
  }
  if (t.contains('ikindi') || t.contains('asr')) {
    return AssistantPrayerTarget.asr;
  }
  if (t.contains('yatsi') || t.contains('isha')) {
    return AssistantPrayerTarget.isha;
  }
  if (t.contains('aksam') || t.contains('maghrib')) {
    return AssistantPrayerTarget.maghrib;
  }
  if (t.contains('namaz') || t.contains('ezan') || t.contains('prayer')) {
    return AssistantPrayerTarget.next;
  }
  return null;
}

bool _hasCountdownAsk(String t) {
  return t.contains('kac saat') ||
      t.contains('kac dk') ||
      t.contains('kac dakika') ||
      t.contains('saat var') ||
      t.contains('dakika var') ||
      t.contains('ne kadar') ||
      t.contains('ne zaman') ||
      t.contains('how many') ||
      t.contains('how long') ||
      t.contains('hours until') ||
      t.contains('minutes until') ||
      t.contains('when is') ||
      t.contains('كم ساعة') ||
      t.contains('متى');
}

({DateTime at, bool tomorrow})? nextHmOccurrence(String hm, DateTime now) {
  final today = _hmOnDay(hm, now);
  if (today == null) return null;
  if (today.isAfter(now)) return (at: today, tomorrow: false);
  final tomorrow = _hmOnDay(hm, now.add(const Duration(days: 1)));
  if (tomorrow == null) return null;
  return (at: tomorrow, tomorrow: true);
}

DateTime? _hmOnDay(String hm, DateTime day) {
  final parts = hm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return DateTime(day.year, day.month, day.day, h, m);
}

String? formatPrayerCountdownReply({
  required AppLocalizations l10n,
  required PrayerTimesModel? times,
  required DateTime now,
  required AssistantPrayerTarget target,
}) {
  if (times == null) return l10n.assistantPrayerTimesMissing;

  String hm;
  String label;
  switch (target) {
    case AssistantPrayerTarget.iftar:
      hm = times.maghrib;
      label = l10n.assistantPrayerLabelIftar;
    case AssistantPrayerTarget.imsak:
      hm = times.imsak.isNotEmpty ? times.imsak : times.fajr;
      label = l10n.assistantPrayerLabelImsak;
    case AssistantPrayerTarget.dhuhr:
      hm = times.dhuhr;
      label = l10n.assistantPrayerLabelDhuhr;
    case AssistantPrayerTarget.asr:
      hm = times.asr;
      label = l10n.assistantPrayerLabelAsr;
    case AssistantPrayerTarget.maghrib:
      hm = times.maghrib;
      label = l10n.assistantPrayerLabelMaghrib;
    case AssistantPrayerTarget.isha:
      hm = times.isha;
      label = l10n.assistantPrayerLabelIsha;
    case AssistantPrayerTarget.next:
      final next = times.nextPrayer(now);
      if (next == null) return l10n.assistantPrayerTimesMissing;
      label = l10n.assistantPrayerLabelNext(next.name);
      final remaining = next.remaining.isNegative
          ? Duration.zero
          : next.remaining;
      final clock = _clockOf(now.add(remaining));
      return l10n.assistantPrayerCountdown(
        label,
        _formatRemaining(l10n, remaining),
        clock,
      );
  }

  final occ = nextHmOccurrence(hm, now);
  if (occ == null) return l10n.assistantPrayerTimesMissing;
  final remaining = occ.at.difference(now);
  final clock = hm.length >= 5 ? hm.substring(0, 5) : hm;
  final wait = remaining.isNegative ? Duration.zero : remaining;
  if (occ.tomorrow) {
    return l10n.assistantPrayerCountdownTomorrow(
      label,
      _formatRemaining(l10n, wait),
      clock,
    );
  }
  return l10n.assistantPrayerCountdown(
    label,
    _formatRemaining(l10n, wait),
    clock,
  );
}

String _clockOf(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatRemaining(AppLocalizations l10n, Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h <= 0 && m <= 0) return l10n.assistantDurationSoon;
  if (h > 0 && m > 0) return l10n.assistantDurationHm(h, m);
  if (h > 0) return l10n.assistantDurationH(h);
  return l10n.assistantDurationM(m < 1 ? 1 : m);
}
