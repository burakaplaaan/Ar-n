import 'package:arin/presentation/qibla/qibla_hub_assets.dart';
import 'package:arin/presentation/qibla/qibla_tool_opening_gate.dart';
import 'package:arin/presentation/qibla/qibla_tool_page_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hub ikon listesi eksiksiz', () {
    expect(QiblaHubAssets.tilePaths, hasLength(8));
    expect(QiblaHubAssets.socialPreviewPaths, hasLength(3));
    expect(QiblaHubAssets.glyphCacheWidth(2.75), inInclusiveRange(64, 192));
    expect(QiblaHubAssets.socialPreviewCacheWidth(3), inInclusiveRange(26, 80));
  });

  test('Android araç rotası Cupertino parallax kullanmaz', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final route = qiblaToolPageRoute(
      settings: const RouteSettings(name: '/zikir'),
      builder: (_) => const SizedBox(),
    );
    expect(route, isA<MaterialPageRoute<void>>());
    expect(route, isNot(isA<CupertinoPageRoute<void>>()));
    expect(route.transitionDuration, kQiblaToolAndroidTransition);
    expect(route.reverseTransitionDuration, kQiblaToolAndroidReverseTransition);
  });

  test('iOS araç rotası Cupertino kalır', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final route = qiblaToolPageRoute(
      settings: const RouteSettings(name: '/zikir'),
      builder: (_) => const SizedBox(),
    );
    expect(route, isA<CupertinoPageRoute<void>>());
  });

  testWidgets('geçiş bitmeden ağır çocuk mount olmaz', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: _PushHost()),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.text('tool-ready'), findsNothing);

    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('tool-ready'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('tool-ready'), findsOneWidget);
  });

  testWidgets('geçiş sırasında pop ağır çocuğu açmaz', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: _PushHost()),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.text('tool-ready'), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('tool-ready'), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _PushHost extends StatelessWidget {
  const _PushHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            Navigator.of(context).push(
              qiblaToolPageRoute(
                settings: const RouteSettings(name: '/zikir'),
                builder: (_) => const QiblaToolOpeningGate(
                  child: Text('tool-ready'),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}
