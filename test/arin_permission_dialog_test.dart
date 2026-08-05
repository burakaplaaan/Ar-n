import 'package:arin/presentation/shared/widgets/arin_permission_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required ValueChanged<bool> onResult,
    String body = 'Konum açıklaması',
    bool barrierDismissible = true,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: Directionality(textDirection: textDirection, child: child!),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                final result = await showArinPermissionDialog(
                  context: context,
                  title: 'Konum İzni',
                  body: body,
                  icon: Icons.location_on_rounded,
                  cancelLabel: 'Şimdi Değil',
                  confirmLabel: 'Devam Et',
                  barrierDismissible: barrierDismissible,
                );
                onResult(result);
              },
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
  }

  testWidgets('returns true from the primary action', (tester) async {
    bool? result;
    await pumpDialog(tester, onResult: (value) => result = value);

    expect(find.text('Konum İzni'), findsOneWidget);
    expect(find.text('Konum açıklaması'), findsOneWidget);

    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('returns false from the secondary action', (tester) async {
    bool? result;
    await pumpDialog(tester, onResult: (value) => result = value);

    await tester.tap(find.text('Şimdi Değil'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('keeps actions accessible on a small high-scale display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool? result;
    await pumpDialog(
      tester,
      onResult: (value) => result = value,
      textScaler: const TextScaler.linear(2),
      textDirection: TextDirection.rtl,
      brightness: Brightness.dark,
      body: List.filled(12, 'Uzun yerelleştirilmiş izin açıklaması.').join(' '),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('honors a non-dismissible barrier', (tester) async {
    bool? result;
    await pumpDialog(
      tester,
      onResult: (value) => result = value,
      barrierDismissible: false,
    );

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Konum İzni'), findsOneWidget);
    expect(result, isNull);
  });
}
