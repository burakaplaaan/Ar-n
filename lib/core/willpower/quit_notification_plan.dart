import 'quit_milestones.dart';
import 'recovery_progress.dart';

enum QuitNotificationKind {
  achievement,
  duration,
  recovery,
  inspiration,
  tips,
}

class QuitPlannedNotification {
  const QuitPlannedNotification({
    required this.fireAt,
    required this.kind,
    required this.habitId,
    required this.templateId,
    required this.tab,
    this.day,
    this.metricId,
    this.percent,
    this.wisdomKind,
    this.wisdomIndex,
    this.tipIndex,
  });

  final DateTime fireAt;
  final QuitNotificationKind kind;
  final String habitId;
  final String templateId;

  /// `progress` veya `tips`.
  final String tab;
  final int? day;
  final String? metricId;
  final int? percent;
  final String? wisdomKind;

  /// Aynı türdeki içerikler arasında dönmek için döngü sayacı.
  final int? wisdomIndex;
  final int? tipIndex;

  String get payload => 'quit_program|$habitId|$tab';
}

final _quitHabitIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,80}$');

({String habitId, String tab})? parseQuitNotificationPayload(String payload) {
  final parts = payload.split('|');
  if (parts.isEmpty || parts.first != 'quit_program' || parts.length < 2) {
    return null;
  }
  final habitId = parts[1].trim();
  if (!_quitHabitIdPattern.hasMatch(habitId)) return null;
  final tab = parts.length > 2 && parts[2].trim() == 'tips' ? 'tips' : 'progress';
  return (habitId: habitId, tab: tab);
}

class QuitNotificationBudget {
  const QuitNotificationBudget({
    required this.horizon,
    required this.maxTimed,
    required this.maxContent,
  });

  final Duration horizon;
  final int maxTimed;
  final int maxContent;

  static const android = QuitNotificationBudget(
    horizon: Duration(days: 21),
    maxTimed: 16,
    maxContent: 4,
  );

  static const ios = QuitNotificationBudget(
    horizon: Duration(days: 8),
    maxTimed: 6,
    maxContent: 2,
  );
}

/// Gece saatlerini 09:00–21:00 bandına çeker.
DateTime clampQuitNotificationHour(DateTime raw) {
  final h = raw.hour;
  if (h >= 8 && h < 22) return raw;
  if (h < 8) {
    return DateTime(raw.year, raw.month, raw.day, 9, raw.minute);
  }
  final next = raw.add(const Duration(days: 1));
  return DateTime(next.year, next.month, next.day, 9, 0);
}

int _stableSalt(String value) {
  var hash = 0;
  for (final u in value.codeUnits) {
    hash = 0x1fffffff & (hash + u);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= hash >> 6;
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash ^= hash >> 11;
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

/// Aktif arınma sayacı için yaklaşan bildirimleri üretir.
/// Geçmiş eşikler atlanır — 4 aydır açık bir program spam etmez.
List<QuitPlannedNotification> buildQuitNotificationPlan({
  required String habitId,
  required String templateId,
  required DateTime clockStartedAt,
  required DateTime now,
  required QuitNotificationBudget budget,
}) {
  final start = clockStartedAt.toLocal();
  final horizonEnd = now.add(budget.horizon);
  final timed = <QuitPlannedNotification>[
    ..._dayEvents(
      habitId: habitId,
      templateId: templateId,
      clockStartedAt: start,
      now: now,
      horizonEnd: horizonEnd,
    ),
    ..._recoveryEvents(
      habitId: habitId,
      templateId: templateId,
      clockStartedAt: start,
      now: now,
      horizonEnd: horizonEnd,
    ),
  ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));

  final content = _contentEvents(
    habitId: habitId,
    templateId: templateId,
    clockStartedAt: start,
    now: now,
    horizonEnd: horizonEnd,
  )..sort((a, b) => a.fireAt.compareTo(b.fireAt));

  final selected = <QuitPlannedNotification>[
    ...timed.take(budget.maxTimed),
    ...content.take(budget.maxContent),
  ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return selected;
}

List<QuitPlannedNotification> _dayEvents({
  required String habitId,
  required String templateId,
  required DateTime clockStartedAt,
  required DateTime now,
  required DateTime horizonEnd,
}) {
  final achievement = QuitAchievementMilestones.days.toSet();
  final duration = QuitDurationMilestones.allDays().toSet();
  final days = {...achievement, ...duration}.toList()..sort();
  final out = <QuitPlannedNotification>[];
  for (final day in days) {
    if (day <= 0) continue;
    final fireAt = clampQuitNotificationHour(
      clockStartedAt.add(Duration(days: day)),
    );
    if (!fireAt.isAfter(now) || fireAt.isAfter(horizonEnd)) continue;
    final isDuration = duration.contains(day);
    // Aynı günde tek bildirim. Süre eşikleri (1–5, 10, 20, 30, aylık)
    // kullanıcının istediği cümleleri taşır; diğer görev günleri başarı kartı.
    final kind = isDuration
        ? QuitNotificationKind.duration
        : QuitNotificationKind.achievement;
    out.add(
      QuitPlannedNotification(
        fireAt: fireAt,
        kind: kind,
        habitId: habitId,
        templateId: templateId,
        tab: 'progress',
        day: day,
      ),
    );
  }
  return out;
}

List<QuitPlannedNotification> _recoveryEvents({
  required String habitId,
  required String templateId,
  required DateTime clockStartedAt,
  required DateTime now,
  required DateTime horizonEnd,
}) {
  final out = <QuitPlannedNotification>[];
  for (final metric in quitRecoveryMetricsFor(templateId)) {
    final byDay = <int, List<int>>{};
    for (final pct in QuitRecoveryNotificationThresholds.percents) {
      final day = RecoveryProgress.firstDayAtOrAbove(metric.percentAt, pct.toDouble());
      if (day == null || day <= 0) continue;
      byDay.putIfAbsent(day, () => []).add(pct);
    }
    for (final entry in byDay.entries) {
      final day = entry.key;
      final percents = entry.value..sort();
      for (var i = 0; i < percents.length; i++) {
        final fireAt = clampQuitNotificationHour(
          clockStartedAt
              .add(Duration(days: day))
              .add(Duration(hours: 2, minutes: i * 90)),
        );
        if (!fireAt.isAfter(now) || fireAt.isAfter(horizonEnd)) continue;
        out.add(
          QuitPlannedNotification(
            fireAt: fireAt,
            kind: QuitNotificationKind.recovery,
            habitId: habitId,
            templateId: templateId,
            tab: 'progress',
            day: day,
            metricId: metric.id,
            percent: percents[i],
          ),
        );
      }
    }
  }
  return out;
}

const _wisdomKinds = ['ayet', 'sünnet', 'tıp', 'not'];
const _inspirationEveryDays = 7;
const _tipsEveryDays = 9;

/// İçerik bildirimleri arınma başlangıcına çapalıdır: plan her uygulama
/// açılışında yeniden kurulsa bile ateşleme günleri kaymaz. Böylece ilham
/// gerçekten 7 günde bir gelir ve döngü sayacı zamanla ilerlediği için
/// içerik her seferinde bir sonrakine döner.
List<QuitPlannedNotification> _contentEvents({
  required String habitId,
  required String templateId,
  required DateTime clockStartedAt,
  required DateTime now,
  required DateTime horizonEnd,
}) {
  final salt = _stableSalt(habitId);
  final anchor = DateTime(
    clockStartedAt.year,
    clockStartedAt.month,
    clockStartedAt.day,
  );
  final out = <QuitPlannedNotification>[];

  final daysSinceStart = now.difference(anchor).inDays;

  // Bir önceki döngüden başla; geçmişte kalanlar isAfter(now) ile elenir.
  // Böylece ateşleme gününün sabahında kurulan plan o günü atlamaz.
  var cycle = daysSinceStart <= 0
      ? 1
      : (daysSinceStart ~/ _inspirationEveryDays).clamp(1, 1 << 30);
  while (true) {
    final fireDay = anchor.add(Duration(days: cycle * _inspirationEveryDays));
    final fireAt = DateTime(fireDay.year, fireDay.month, fireDay.day, 16, 0);
    if (fireAt.isAfter(horizonEnd)) break;
    if (fireAt.isAfter(now)) {
      out.add(
        QuitPlannedNotification(
          fireAt: fireAt,
          kind: QuitNotificationKind.inspiration,
          habitId: habitId,
          templateId: templateId,
          tab: 'progress',
          wisdomKind: _wisdomKinds[(salt + cycle) % _wisdomKinds.length],
          wisdomIndex: salt + cycle,
        ),
      );
    }
    cycle++;
  }

  var tipCycle = daysSinceStart <= 0
      ? 1
      : (daysSinceStart ~/ _tipsEveryDays).clamp(1, 1 << 30);
  while (true) {
    final fireDay = anchor.add(Duration(days: tipCycle * _tipsEveryDays));
    final fireAt = DateTime(fireDay.year, fireDay.month, fireDay.day, 18, 30);
    if (fireAt.isAfter(horizonEnd)) break;
    if (fireAt.isAfter(now)) {
      out.add(
        QuitPlannedNotification(
          fireAt: fireAt,
          kind: QuitNotificationKind.tips,
          habitId: habitId,
          templateId: templateId,
          tab: 'tips',
          tipIndex: salt + tipCycle,
        ),
      );
    }
    tipCycle++;
  }
  return out;
}
