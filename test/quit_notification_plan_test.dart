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

  test('ilham bildirimi 7 günde bir gelir ve başlangıca çapalıdır', () {
    final now = start.add(const Duration(hours: 1));
    final fireAts = planAt(now: now)
        .where((e) => e.kind == QuitNotificationKind.inspiration)
        .map((e) => e.fireAt)
        .toList();
    expect(fireAts, isNotEmpty);
    for (var i = 1; i < fireAts.length; i++) {
      expect(fireAts[i].difference(fireAts[i - 1]).inDays, 7);
    }
  });

  test('plan her gün yeniden kurulsa da ilham günleri kaymaz', () {
    DateTime? firstUpcoming(DateTime now) {
      final events = planAt(now: now)
          .where((e) => e.kind == QuitNotificationKind.inspiration)
          .toList();
      return events.isEmpty ? null : events.first.fireAt;
    }

    final day2 = firstUpcoming(start.add(const Duration(days: 2, hours: 1)));
    final day3 = firstUpcoming(start.add(const Duration(days: 3, hours: 1)));
    final day4 = firstUpcoming(start.add(const Duration(days: 4, hours: 1)));
    expect(day2, isNotNull);
    // Uygulama her gün açılsa bile aynı 7. gün hedeflenir; her açılışta
    // "yarın yeni bildirim" üretilmez.
    expect(day3, day2);
    expect(day4, day2);
  });

  test('ilham döngü sayacı zamanla ilerler — içerik hep aynı kalmaz', () {
    final now = start.add(const Duration(hours: 1));
    final indexes = planAt(now: now)
        .where((e) => e.kind == QuitNotificationKind.inspiration)
        .map((e) => e.wisdomIndex)
        .toList();
    expect(indexes.toSet().length, indexes.length);
  });

  test('istenen türde içerik yoksa başlık seçilen içeriğin türünü taşır', () {
    const wisdom = [
      QuitNotificationWisdomSnippet(
        kind: 'ayet',
        body: 'Örnek ayet meali',
        source: 'Kur’an-ı Kerim',
      ),
    ];
    final event = QuitPlannedNotification(
      fireAt: DateTime(2026, 2, 1, 16),
      kind: QuitNotificationKind.inspiration,
      habitId: 'h1',
      templateId: WillpowerTemplates.quitZina,
      tab: 'progress',
      wisdomKind: 'tıp',
      wisdomIndex: 3,
    );
    final copy = resolveQuitNotificationCopy(
      event: event,
      localeCode: 'tr',
      wisdom: wisdom,
    );
    expect(copy.title, 'Ayet');
    expect(copy.body, contains('Örnek ayet meali'));
  });

  test('aynı türde birden çok içerik varsa döngü sayacıyla döner', () {
    const wisdom = [
      QuitNotificationWisdomSnippet(kind: 'ayet', body: 'Ayet 1', source: ''),
      QuitNotificationWisdomSnippet(kind: 'ayet', body: 'Ayet 2', source: ''),
      QuitNotificationWisdomSnippet(kind: 'ayet', body: 'Ayet 3', source: ''),
    ];
    QuitNotificationCopy copyAt(int index) {
      return resolveQuitNotificationCopy(
        event: QuitPlannedNotification(
          fireAt: DateTime(2026, 2, 1, 16),
          kind: QuitNotificationKind.inspiration,
          habitId: 'h1',
          templateId: WillpowerTemplates.quitZina,
          tab: 'progress',
          wisdomKind: 'ayet',
          wisdomIndex: index,
        ),
        localeCode: 'tr',
        wisdom: wisdom,
      );
    }

    expect(
      {copyAt(0).body, copyAt(1).body, copyAt(2).body}.length,
      3,
    );
    expect(copyAt(3).body, copyAt(0).body);
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
