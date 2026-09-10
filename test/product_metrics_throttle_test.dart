import 'package:arin/data/services/product_metrics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('istanbulMetricDayKey uses year-round UTC+3', () {
    expect(
      istanbulMetricDayKey(DateTime.utc(2026, 9, 8, 21, 0)),
      '2026-09-09',
    );
    expect(
      istanbulMetricDayKey(DateTime.utc(2026, 9, 8, 20, 59)),
      '2026-09-08',
    );
  });

  test('presence sync waits six hours after a successful heartbeat', () {
    final now = DateTime.utc(2026, 9, 9, 12);
    expect(
      shouldSkipInstallPresenceSync(lastSyncedAtMs: null, now: now),
      isFalse,
    );
    expect(
      shouldSkipInstallPresenceSync(lastSyncedAtMs: 0, now: now),
      isFalse,
    );
    expect(
      shouldSkipInstallPresenceSync(
        lastSyncedAtMs: now
            .subtract(kInstallPresenceMinInterval)
            .millisecondsSinceEpoch,
        now: now,
      ),
      isFalse,
    );
    expect(
      shouldSkipInstallPresenceSync(
        lastSyncedAtMs: now
            .subtract(kInstallPresenceMinInterval - const Duration(minutes: 1))
            .millisecondsSinceEpoch,
        now: now,
      ),
      isTrue,
    );
  });

  test('daily metric skip matches the server one-event-per-day rule', () {
    const key = 'content_view|card_1';
    expect(dailyMetricEventKey('content_view', 'card_1'), key);
    expect(
      shouldSkipDailyMetric(
        storedDayKey: '2026-09-09',
        todayKey: '2026-09-09',
        sentKeys: {key},
        eventKey: key,
      ),
      isTrue,
    );
    expect(
      shouldSkipDailyMetric(
        storedDayKey: '2026-09-08',
        todayKey: '2026-09-09',
        sentKeys: {key},
        eventKey: key,
      ),
      isFalse,
    );
    expect(
      shouldSkipDailyMetric(
        storedDayKey: '2026-09-09',
        todayKey: '2026-09-09',
        sentKeys: {'feature_open|qibla'},
        eventKey: key,
      ),
      isFalse,
    );
  });
}
