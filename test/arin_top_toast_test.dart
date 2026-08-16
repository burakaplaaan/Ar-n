import 'package:arin/core/constants/app_colors.dart';
import 'package:arin/core/theme/app_theme.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('üstten toast koyu temada kart yüzeyiyle görünür', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () =>
                    showArinTopToast(context, 'Âmin. Bu duaya gönülden eşlik ettin.'),
                child: const Text('göster'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('göster'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));

    final text = find.text('Âmin. Bu duaya gönülden eşlik ettin.');
    expect(text, findsOneWidget);

    final toastBox = tester.widget<DecoratedBox>(
      find
          .ancestor(of: text, matching: find.byType(DecoratedBox))
          .first,
    );
    final decoration = toastBox.decoration as BoxDecoration;
    expect(decoration.color, AppColors.homeCardSurface);
    expect(decoration.color, isNot(AppColors.creamSurface));

    final toastTop = tester.getTopLeft(text).dy;
    expect(toastTop, lessThan(120));

    ArinTopToastController.hide();
    await tester.pump();
  });

  testWidgets('yeni toast önceki üst bildirimi değiştirir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () => showArinTopToast(context, 'birinci'),
                    child: const Text('bir'),
                  ),
                  TextButton(
                    onPressed: () => showArinTopToast(context, 'ikinci'),
                    child: const Text('iki'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('bir'));
    await tester.pump();
    expect(find.text('birinci'), findsOneWidget);

    await tester.tap(find.text('iki'));
    await tester.pump();
    expect(find.text('birinci'), findsNothing);
    expect(find.text('ikinci'), findsOneWidget);

    ArinTopToastController.hide();
    await tester.pump();
  });

  testWidgets('uzun bildirim üst kartta satır kırar', (tester) async {
    const longMessage =
        'Dua talebin halkaya eklendi. Hayra vesile olsun. Bu duaya daha önce eşlik ettin.';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showArinTopToast(context, longMessage),
                child: const Text('göster'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('göster'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));

    final text = find.text(longMessage);
    expect(text, findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(text).width, lessThan(tester.view.physicalSize.width));

    ArinTopToastController.hide();
    await tester.pump();
  });
}
