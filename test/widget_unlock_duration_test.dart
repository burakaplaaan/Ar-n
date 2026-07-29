import 'package:arin/data/services/ad_gate_service.dart';
import 'package:arin/data/services/global_widget_lock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('widget unlock duration', () {
    test('yalnızca 1-72 saat aralığını kabul eder', () {
      expect(GlobalWidgetLockService.isValidUnlockHours(1), isTrue);
      expect(GlobalWidgetLockService.isValidUnlockHours(72), isTrue);
      expect(GlobalWidgetLockService.isValidUnlockHours(0), isFalse);
      expect(GlobalWidgetLockService.isValidUnlockHours(73), isFalse);
    });

    test('eski kurulumlarda varsayılan süre 24 saat kalır', () {
      expect(GlobalWidgetLockService.defaultUnlockHours, 24);
      expect(GlobalWidgetLockService.legacyUnlockHours, 24);
    });

    test('mevcut turu seçilen saate göre yeniden hesaplar', () async {
      final startedAt = DateTime.utc(2026, 7, 29, 12);
      SharedPreferences.setMockInitialValues({
        'arin_widget_unlock_hours': 10,
        'ad_gate_widget_quote_unlock_started_at': startedAt.toIso8601String(),
        'ad_gate_widget_quote_unlock_until': startedAt
            .add(const Duration(hours: 24))
            .toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();

      expect(
        AdGateService(prefs).unlockUntil(AdGatePlacement.widgetQuote),
        startedAt.add(const Duration(hours: 10)),
      );
    });

    test('eski 24 saatlik kayıttan tur başlangıcını türetir', () async {
      final legacyUntil = DateTime.now().add(const Duration(hours: 12));
      SharedPreferences.setMockInitialValues({
        'arin_widget_unlock_hours': 2,
        'ad_gate_widget_quote_unlock_until': legacyUntil.toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();

      expect(
        AdGateService(prefs).unlockUntil(AdGatePlacement.widgetQuote),
        legacyUntil.subtract(const Duration(hours: 22)),
      );
    });

    test('süresi dolmuş eski tur, süre artırılınca yeniden açılmaz', () async {
      final expiredAt = DateTime.now().subtract(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        'arin_widget_unlock_hours': 72,
        'ad_gate_widget_quote_unlock_until': expiredAt.toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();

      expect(
        AdGateService(prefs).unlockUntil(AdGatePlacement.widgetQuote),
        expiredAt,
      );
    });

    test('süre düşürülüp dolduktan sonra artırmak turu canlandırmaz', () async {
      final startedAt = DateTime.now().subtract(const Duration(hours: 3));
      final oldUntil = startedAt.add(const Duration(hours: 24));
      SharedPreferences.setMockInitialValues({
        'arin_widget_unlock_hours': 2,
        'ad_gate_widget_quote_unlock_started_at': startedAt.toIso8601String(),
        'ad_gate_widget_quote_unlock_until': oldUntil.toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = AdGateService(prefs);

      await service.reconcileWidgetUnlockDeadline(AdGatePlacement.widgetQuote);
      final shortenedUntil = service.unlockUntil(AdGatePlacement.widgetQuote);
      expect(shortenedUntil, startedAt.add(const Duration(hours: 2)));

      await prefs.setInt('arin_widget_unlock_hours', 72);
      await service.reconcileWidgetUnlockDeadline(AdGatePlacement.widgetQuote);
      expect(service.unlockUntil(AdGatePlacement.widgetQuote), shortenedUntil);
    });

    test('background native bitişi resume sırasında Fluttera taşır', () async {
      final startedAt = DateTime.now().subtract(const Duration(hours: 3));
      final oldUntil = startedAt.add(const Duration(hours: 24));
      final shortenedUntil = startedAt.add(const Duration(hours: 2));
      SharedPreferences.setMockInitialValues({
        'arin_widget_unlock_hours': 72,
        'ad_gate_widget_quote_unlock_started_at': startedAt.toIso8601String(),
        'ad_gate_widget_quote_unlock_until': oldUntil.toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = AdGateService(prefs);

      await service.reconcileWidgetUnlockSnapshot(
        startedAtMsByKind: {'quote': startedAt.millisecondsSinceEpoch},
        untilMsByKind: {'quote': shortenedUntil.millisecondsSinceEpoch},
      );

      expect(
        service.unlockUntil(AdGatePlacement.widgetQuote),
        DateTime.fromMillisecondsSinceEpoch(
          shortenedUntil.millisecondsSinceEpoch,
        ),
      );
    });
  });
}
