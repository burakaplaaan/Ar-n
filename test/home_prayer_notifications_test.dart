import 'package:arin/core/providers/shared_preferences_provider.dart';
import 'package:arin/data/models/prayer_times_model.dart';
import 'package:arin/data/services/location_service.dart';
import 'package:arin/l10n/app_localizations.dart';
import 'package:arin/presentation/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationService extends LocationService {
  @override
  int? get savedDistrictId => null;

  @override
  DateTime? get lastPrayerSyncAt => null;
}

const _prayerTimes = PrayerTimesModel(
  imsak: '05:10',
  fajr: '05:10',
  sunrise: '06:35',
  dhuhr: '13:10',
  asr: '16:45',
  maghrib: '19:25',
  isha: '20:50',
  date: '2026-07-14',
  city: 'İstanbul',
);

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget appFor(AsyncValue<PrayerTimesModel> state, {double textScale = 1}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: HomePrayerTimesBlock(
                prayerTimesOverride: state,
                notificationSupportedOverride: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('bildirim kartı tüm vakit verisi durumlarında bir kez görünür', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final states = <AsyncValue<PrayerTimesModel>>[
      const AsyncValue.loading(),
      AsyncValue.error(Exception('test'), StackTrace.current),
      const AsyncValue.data(_prayerTimes),
    ];

    for (final state in states) {
      await tester.pumpWidget(appFor(state));
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const Key('home-prayer-notification-card')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'dar ekranda büyük yazıyla taşmaz ve anahtar dokunma alanı yeterli',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        appFor(const AsyncValue.data(_prayerTimes), textScale: 2),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final toggle = find.byKey(const Key('prayer-notification-toggle'));
      expect(toggle, findsOneWidget);
      expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));
      final semanticToggle = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Vakit bildirimi',
      );
      expect(semanticToggle, findsOneWidget);
      final semanticsWidget = tester.widget<Semantics>(semanticToggle);
      expect(semanticsWidget.properties.toggled, isFalse);
      expect(semanticsWidget.properties.enabled, isTrue);
      expect(semanticsWidget.properties.onTap, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('namaz vakitleri ızgarası kartın içine güvenli alan eklemez', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(appFor(const AsyncValue.data(_prayerTimes)));
    await tester.pump(const Duration(milliseconds: 400));

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.padding, EdgeInsets.zero);
  });
}
