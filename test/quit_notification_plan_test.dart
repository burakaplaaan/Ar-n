import 'package:arin/core/constants/willpower_templates.dart';
import 'package:arin/core/willpower/quit_milestones.dart';
import 'package:arin/core/willpower/quit_notification_copy.dart';
import 'package:arin/core/willpower/quit_notification_plan.dart';
import 'package:arin/core/willpower/recovery_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 1, 1, 15, 30);
  const budget = QuitNotificationBudget(
    horizon: Duration(days: 40),
    maxTimed: 80,
    maxContent: 20,
  );

  List<QuitPlannedNotification> planAt({
    required DateTime now,
    String templateId = WillpowerTemplates.quitAlcohol,
    QuitNotificationBudget planBudget = budget,
  }) {
    return buildQuitNotificationPlan(
      habitId: 'habit-alcohol-1',
      templateId: templateId,
      clockStartedAt: start,
      now: now,
      budget: planBudget,
    );
  }

  test('ilk 5 gün süre cümleleri farklıdır ve başarıyle çakışmaz', () {
    final now = start.add(const Duration(hours: 1));
    final events = planAt(now: now)
        .where((e) => e.kind == QuitNotificationKind.duration)
        .where((e) => (e.day ?? 0) <= 5)
        .toList();
    expect(events.map((e) => e.day), [1, 2, 3, 4, 5]);
    final bodies = events
        .map(
          (e) => resolveQuitNotificationCopy(event: e, localeCode: 'tr').body,
        )
        .toSet();
    expect(bodies.length, 5);
    expect(bodies.any((b) => b.contains('1. günü tamamladın')), isTrue);
    expect(
      resolveQuitNotificationCopy(event: events.first, localeCode: 'tr')
          .title
          .contains('İlk nefes'),
      isTrue,
    );
  });

  test('10. gün süre cümlesi tek bildirimdir', () {
    final now = start.add(const Duration(hours: 1));
    final dayEvents = planAt(now: now).where((e) => e.day == 10).toList();
    expect(dayEvents.where((e) => e.tab == 'progress' && e.metricId == null),
        hasLength(1));
    expect(dayEvents.first.kind, QuitNotificationKind.duration);
  });

  test('geçmiş eşikler planlanmaz — 129 günlük kullanıcı spam yemez', () {
    final now = start.add(const Duration(days: 129, hours: 6));
    final events = planAt(now: now);
    expect(events.any((e) => (e.day ?? 9999) <= 129 && e.metricId == null),
        isFalse);
    expect(
      events.any(
        (e) =>
            e.kind == QuitNotificationKind.duration && e.day == 150,
      ),
      isTrue,
    );
  });

  test('her toparlanma alanı için 6 yüzde eşiği vardır', () {
    for (final templateId in WillpowerTemplates.fullQuitProgramTemplateIds) {
      for (final metric in quitRecoveryMetricsFor(templateId)) {
        final days = <int>{};
        for (final pct in QuitRecoveryNotificationThresholds.percents) {
          final day = RecoveryProgress.firstDayAtOrAbove(
            metric.percentAt,
            pct.toDouble(),
          );
          expect(day, isNotNull, reason: '$templateId.${metric.id} @$pct');
          days.add(day!);
        }
        expect(
          QuitRecoveryNotificationThresholds.percents,
          hasLength(6),
          reason: templateId,
        );
        expect(days, isNotEmpty);
      }
    }
  });

  test('ilerleme yüzdesi bildirimi 5-10-20-50-75-100 sırasını korur', () {
    final now = start.add(const Duration(hours: 1));
    final liver = buildQuitNotificationPlan(
      habitId: 'habit-alcohol-1',
      templateId: WillpowerTemplates.quitAlcohol,
      clockStartedAt: start,
      now: now,
      budget: const QuitNotificationBudget(
        horizon: Duration(days: 800),
        maxTimed: 200,
        maxContent: 0,
      ),
    )
        .where(
          (e) =>
              e.kind == QuitNotificationKind.recovery && e.metricId == 'liver',
        )
        .map((e) => e.percent)
        .toList();
    expect(liver, QuitRecoveryNotificationThresholds.percents);
  });

  test('ipucu bildirimi tips sekmesine, diğerleri progress sekmesine gider', () {
    final now = start.add(const Duration(hours: 1));
    final events = planAt(now: now);
    expect(
      events.where((e) => e.kind == QuitNotificationKind.tips).every(
            (e) => e.tab == 'tips' && e.payload.endsWith('|tips'),
          ),
      isTrue,
    );
    expect(
      events.where((e) => e.kind != QuitNotificationKind.tips).every(
            (e) => e.tab == 'progress',
          ),
      isTrue,
    );
  });

  test('ilham türleri ayet / sünnet / tıp / not arasında döner', () {
    final now = start.add(const Duration(hours: 1));
    final kinds = planAt(now: now)
        .where((e) => e.kind == QuitNotificationKind.inspiration)
        .map((e) => e.wisdomKind)
        .toSet();
    expect(kinds, containsAll(['ayet', 'sünnet', 'tıp', 'not']));
  });

  test('tüm tam arınma şablonları plan üretir', () {
    final now = start.add(const Duration(hours: 1));
    for (final templateId in WillpowerTemplates.fullQuitProgramTemplateIds) {
      final events = planAt(now: now, templateId: templateId);
      expect(events, isNotEmpty, reason: templateId);
      expect(
        events.any((e) => e.kind == QuitNotificationKind.duration),
        isTrue,
        reason: templateId,
      );
      expect(
        events.any((e) => e.kind == QuitNotificationKind.recovery),
        isTrue,
        reason: templateId,
      );
    }
  });

  test('iOS bütçesi zamanlanmış + içerik tavanını aşmaz', () {
    final now = start.add(const Duration(hours: 1));
    final events = planAt(now: now, planBudget: QuitNotificationBudget.ios);
    final timed = events.where(
      (e) =>
          e.kind == QuitNotificationKind.achievement ||
          e.kind == QuitNotificationKind.duration ||
          e.kind == QuitNotificationKind.recovery,
    );
    final content = events.where(
      (e) =>
          e.kind == QuitNotificationKind.inspiration ||
          e.kind == QuitNotificationKind.tips,
    );
    expect(timed.length, lessThanOrEqualTo(QuitNotificationBudget.ios.maxTimed));
    expect(
      content.length,
      lessThanOrEqualTo(QuitNotificationBudget.ios.maxContent),
    );
  });

  test('payload yalnızca güvenli habit id kabul eder', () {
    expect(
      parseQuitNotificationPayload('quit_program|abc-123|progress'),
      (habitId: 'abc-123', tab: 'progress'),
    );
    expect(
      parseQuitNotificationPayload('quit_program|abc-123|tips'),
      (habitId: 'abc-123', tab: 'tips'),
    );
    expect(parseQuitNotificationPayload('quit_program|../etc|tips'), isNull);
    expect(parseQuitNotificationPayload('other|abc|tips'), isNull);
  });

  test('gece saati 09:00 bandına çekilir', () {
    expect(
      clampQuitNotificationHour(DateTime(2026, 1, 2, 3, 15)).hour,
      9,
    );
    expect(
      clampQuitNotificationHour(DateTime(2026, 1, 2, 23, 10)).hour,
      9,
    );
    expect(
      clampQuitNotificationHour(DateTime(2026, 1, 2, 15, 30)).hour,
      15,
    );
  });

  test('aylık süre bildirimi 60 günden sonra 30 günde bir gelir', () {
    expect(QuitDurationMilestones.allDays().contains(60), isTrue);
    expect(QuitDurationMilestones.allDays().contains(90), isTrue);
    expect(QuitDurationMilestones.allDays().contains(150), isTrue);
    expect(QuitAchievementMilestones.days.contains(7), isTrue);
  });
}
