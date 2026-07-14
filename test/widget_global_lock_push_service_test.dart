import 'package:arin/data/services/widget_global_lock_push_service.dart';
import 'package:arin/data/services/global_widget_lock_service.dart';
import 'package:arin/data/services/widget_access_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (_) async => null,
      );

  group('WidgetGlobalLockPushPayload', () {
    test('geçerli kilitleme mesajını ayrıştırır', () {
      final payload = WidgetGlobalLockPushPayload.tryParse({
        'type': 'widget_global_lock',
        'locked': '1',
        'revision': '12',
        'note': 'Bakım',
      });

      expect(payload, isNotNull);
      expect(payload!.locked, isTrue);
      expect(payload.revision, 12);
      expect(payload.note, 'Bakım');
    });

    test('geçerli kilit kaldırma mesajını ayrıştırır', () {
      final payload = WidgetGlobalLockPushPayload.tryParse({
        'type': 'widget_global_lock',
        'locked': '0',
        'revision': 13,
      });

      expect(payload, isNotNull);
      expect(payload!.locked, isFalse);
    });

    test('bozuk veya başka tipte mesajları reddeder', () {
      expect(
        WidgetGlobalLockPushPayload.tryParse({
          'type': 'moment_verse',
          'locked': '1',
          'revision': '12',
        }),
        isNull,
      );
      expect(
        WidgetGlobalLockPushPayload.tryParse({
          'type': 'widget_global_lock',
          'locked': 'true',
          'revision': '12',
        }),
        isNull,
      );
      expect(
        WidgetGlobalLockPushPayload.tryParse({
          'type': 'widget_global_lock',
          'locked': '1',
          'revision': '0',
        }),
        isNull,
      );
    });

    test('eski mesajı reddeder, eş revision retry yapılabilir', () {
      const payload = WidgetGlobalLockPushPayload(
        locked: true,
        revision: 200,
        note: '',
      );

      expect(payload.isOlderThan(201), isTrue);
      expect(payload.isOlderThan(200), isFalse);
      expect(payload.isOlderThan(199), isFalse);
    });
  });

  group('GlobalWidgetLockService remote override', () {
    test('Firestore ve push revision sırası monotoniktir', () {
      expect(
        GlobalWidgetLockService.shouldApplyRevision(current: 10, incoming: 8),
        isFalse,
      );
      expect(
        GlobalWidgetLockService.shouldApplyRevision(current: 10, incoming: 0),
        isFalse,
      );
      expect(
        GlobalWidgetLockService.shouldApplyRevision(current: 10, incoming: 10),
        isTrue,
      );
      expect(
        GlobalWidgetLockService.shouldApplyRevision(current: 10, incoming: 11),
        isTrue,
      );
      expect(
        GlobalWidgetLockService.shouldApplyRevision(current: 0, incoming: 0),
        isTrue,
      );
    });

    test('yeni revision uygulanır, eski revision reddedilir', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      expect(
        await GlobalWidgetLockService.applyRemoteOverride(
          prefs,
          locked: true,
          revision: 3,
          note: 'Bakım',
        ),
        isTrue,
      );
      expect(GlobalWidgetLockService.isGloballyLocked(prefs), isTrue);
      expect(GlobalWidgetLockService.revision(prefs), 3);
      expect(GlobalWidgetLockService.lockedNote(prefs), 'Bakım');

      expect(
        await GlobalWidgetLockService.applyRemoteOverride(
          prefs,
          locked: false,
          revision: 2,
          note: '',
        ),
        isFalse,
      );
      expect(GlobalWidgetLockService.isGloballyLocked(prefs), isTrue);

      expect(
        await GlobalWidgetLockService.applyRemoteOverride(
          prefs,
          locked: false,
          revision: 4,
          note: '',
        ),
        isTrue,
      );
      expect(GlobalWidgetLockService.isGloballyLocked(prefs), isFalse);
    });

    test('eşzamanlı mutation yeni revisionı eskiye döndürmez', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        GlobalWidgetLockService.applyRemoteOverride(
          prefs,
          locked: true,
          revision: 11,
          note: 'Yeni',
        ),
        GlobalWidgetLockService.applyRemoteOverride(
          prefs,
          locked: false,
          revision: 10,
          note: 'Eski',
        ),
      ]);

      expect(GlobalWidgetLockService.revision(prefs), 11);
      expect(GlobalWidgetLockService.isGloballyLocked(prefs), isTrue);
      expect(GlobalWidgetLockService.lockedNote(prefs), 'Yeni');
    });

    test(
      'global override rewarded/trial yolunu kapatır, premiumu kapatmaz',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await GlobalWidgetLockService.applyRemoteOverride(
          prefs,
          locked: true,
          revision: 1,
          note: '',
        );
        final service = WidgetAccessService(prefs);

        final freeState = await service.stateFor(
          ArinWidgetAccessKind.quote,
          isPremium: false,
        );
        final premiumState = await service.stateFor(
          ArinWidgetAccessKind.quote,
          isPremium: true,
        );

        expect(freeState.allowed, isFalse);
        expect(premiumState.allowed, isTrue);
      },
    );
  });
}
