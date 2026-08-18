import 'package:arin/presentation/shared/widgets/arin_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onay popup tıklanan yerden açılır ve onaylar', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: FilledButton(
                onPressed: () async {
                  result = await showArinConfirm(
                    context: context,
                    title: 'Silinsin mi?',
                    message: 'Geri alınamaz.',
                    cancelLabel: 'İptal',
                    confirmLabel: 'Sil',
                    tone: ArinPopupTone.destructive,
                  );
                },
                child: const Text('Aç'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Silinsin mi?'), findsOneWidget);
    expect(find.text('Geri alınamaz.'), findsOneWidget);
    expect(
      tester.getSize(find.byType(ArinPopupCard)).height,
      lessThan(tester.getSize(find.byType(MaterialApp)).height * 0.7),
    );

    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('iptal false döner', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showArinConfirm(
                  context: context,
                  title: 'Çıkış',
                  cancelLabel: 'Vazgeç',
                  confirmLabel: 'Çık',
                );
              },
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
