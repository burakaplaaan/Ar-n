import 'package:arin/l10n/app_localizations.dart';
import 'package:arin/presentation/qibla/qibla_tools_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHub(
    WidgetTester tester, {
    required Locale locale,
    required double textScale,
    required Size size,
  }) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(body: QiblaToolsDashboardPage()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('TR yatay liste dar ekranda taşmaz', (tester) async {
    await pumpHub(
      tester,
      locale: const Locale('tr'),
      textScale: 1.0,
      size: const Size(360, 1600),
    );
    expect(find.text('İslami Yapay Zeka'), findsOneWidget);
    expect(find.text('Sosyal'), findsOneWidget);
    expect(find.text('Kıble yönünü bul'), findsOneWidget);
    expect(find.text('Zikirmatik'), findsOneWidget);
    expect(find.text('Kur\'an'), findsOneWidget);
    expect(find.text('Bilgi Düellosu'), findsOneWidget);
    expect(find.text('Dua Halkası'), findsOneWidget);
    expect(find.text('İyileştirici Frekanslar'), findsOneWidget);
    expect(find.text('Nefes Egzersizi'), findsOneWidget);
    expect(find.text('Yön ve ibadet'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TR yatay liste 1.3 yazı ölçeğinde taşmaz', (tester) async {
    await pumpHub(
      tester,
      locale: const Locale('tr'),
      textScale: 1.3,
      size: const Size(320, 1600),
    );
    expect(find.text('İslami Yapay Zeka'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AR yatay liste 1.3 yazı ölçeğinde taşmaz', (tester) async {
    await pumpHub(
      tester,
      locale: const Locale('ar'),
      textScale: 1.3,
      size: const Size(320, 1600),
    );
    expect(find.text('القرآن'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
