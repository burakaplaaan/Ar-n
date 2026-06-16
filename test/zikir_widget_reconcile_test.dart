// test/zikir_widget_reconcile_test.dart
//
// Zikirmatik widget <-> uygulama oturumu senkron mantığının saf çekirdeği:
// [ZikirWidgetService.reconcile]. Widget'taki "+1" tıkları uygulamaya
// taşınırken total/round/tur'un (tur rollover dâhil) doğru hesaplandığını
// koruma altına alır. Cihazda test edilemediği için bu regresyon kritik.

import 'package:arin/data/services/zikir_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZikirWidgetService.reconcile', () {
    test('widget toplamı oturumla eşitse değişmez', () {
      final r = ZikirWidgetService.reconcile(
        sessionTotal: 10,
        sessionRound: 10,
        sessionTur: 1,
        target: 33,
        widgetTotal: 10,
      );
      expect(r.total, 10);
      expect(r.round, 10);
      expect(r.tur, 1);
    });

    test('widget toplamı geride ise (app ileride) oturum korunur', () {
      final r = ZikirWidgetService.reconcile(
        sessionTotal: 20,
        sessionRound: 20,
        sessionTur: 1,
        target: 33,
        widgetTotal: 5,
      );
      expect(r.total, 20);
      expect(r.round, 20);
      expect(r.tur, 1);
    });

    test('tur tamamlamadan ileri taşır', () {
      final r = ZikirWidgetService.reconcile(
        sessionTotal: 10,
        sessionRound: 10,
        sessionTur: 1,
        target: 33,
        widgetTotal: 25,
      );
      expect(r.total, 25);
      expect(r.round, 25);
      expect(r.tur, 1);
    });

    test('tam bir tur tamamlar (round target eşiğine ulaşır)', () {
      // round 30 + 3 = 33 -> tur tamamlanır, round 0, tur 2
      final r = ZikirWidgetService.reconcile(
        sessionTotal: 30,
        sessionRound: 30,
        sessionTur: 1,
        target: 33,
        widgetTotal: 33,
      );
      expect(r.total, 33);
      expect(r.round, 0);
      expect(r.tur, 2);
    });

    test('tek delta ile birden fazla tur atlar', () {
      // round 10 + 70 = 80; 80 ~/ 33 = 2 tur, kalan 80 % 33 = 14
      final r = ZikirWidgetService.reconcile(
        sessionTotal: 100,
        sessionRound: 10,
        sessionTur: 3,
        target: 33,
        widgetTotal: 170,
      );
      expect(r.total, 170);
      expect(r.round, 14);
      expect(r.tur, 5);
    });

    test('target geçersizse (<1) oturum korunur', () {
      final r = ZikirWidgetService.reconcile(
        sessionTotal: 5,
        sessionRound: 5,
        sessionTur: 1,
        target: 0,
        widgetTotal: 50,
      );
      expect(r.total, 5);
      expect(r.round, 5);
      expect(r.tur, 1);
    });

    test('target 1 iken her artış bir tur tamamlar', () {
      // round 0 + 3 = 3; 3 ~/ 1 = 3 tur, kalan 0
      final r = ZikirWidgetService.reconcile(
        sessionTotal: 0,
        sessionRound: 0,
        sessionTur: 1,
        target: 1,
        widgetTotal: 3,
      );
      expect(r.total, 3);
      expect(r.round, 0);
      expect(r.tur, 4);
    });
  });
}
