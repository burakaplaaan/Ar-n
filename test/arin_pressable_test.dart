import 'package:arin/core/theme/app_theme.dart';
import 'package:arin/presentation/inspire/widgets/explore_header_veil.dart';
import 'package:arin/presentation/shared/widgets/arin_pressable.dart';
import 'package:arin/presentation/shared/widgets/arin_premium_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basılı tutunca göçük kalır, parmak kalkınca açılır', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ArinPressable(
              haptic: false,
              onTap: () => taps++,
              child: const SizedBox(
                width: 120,
                height: 48,
                child: Text('bas'),
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('bas')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final pressed = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(pressed.scale, lessThan(1));

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    final released = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(released.scale, 1);
    expect(taps, 1);
  });

  test('tema Material ripple doldurmasını kapatır', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(theme.splashFactory, NoSplash.splashFactory);
      expect(theme.splashColor, Colors.transparent);
      expect(theme.highlightColor, Colors.transparent);
    }
  });

  testWidgets('premium işareti pırlanta ikonudur', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ArinPremiumMark())),
    );
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.diamond_rounded);
  });

  testWidgets('keşfet tülü gri levha kullanmaz', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: ExploreHeaderVeil()),
      ),
    );

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(ExploreHeaderVeil),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.gradient, isNotNull);
    expect(decoration.color, isNull);
    expect(ExploreHeaderMetrics.toolbarHeight, lessThan(40));
  });
}
