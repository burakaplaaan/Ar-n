import 'package:arin/core/theme/app_theme.dart';
import 'package:arin/core/theme/arin_backdrop_blur.dart';
import 'package:arin/presentation/inspire/widgets/explore_header_veil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('blur katmanı RepaintBoundary içinde kalır, BackdropFilter durur', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArinBackdropBlur(
            sigma: 12,
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ArinBackdropBlur),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ArinBackdropBlur),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
  });

  testWidgets('cam kutu ve keşfet tülü aynı izolasyonu kullanır', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Column(
            children: [
              Expanded(child: ExploreHeaderVeil()),
              GlassContainer(child: Text('cam')),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(ArinBackdropBlur), findsNWidgets(2));
    expect(find.byType(BackdropFilter), findsNWidgets(2));
    expect(find.text('cam'), findsOneWidget);
  });
}
