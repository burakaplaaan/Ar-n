import 'package:arin/l10n/app_localizations.dart';
import 'package:arin/presentation/qibla/qibla_tool_opening_gate.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('araç açılışında önce yükleme ekranı görünür', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QiblaToolOpeningGate(child: Text('tool-ready')),
        ),
      ),
    );

    expect(find.byType(ArinLoader), findsOneWidget);
    expect(find.text('tool-ready'), findsNothing);

    await tester.pump();
    await tester.pump();

    expect(find.byType(ArinLoader), findsNothing);
    expect(find.text('tool-ready'), findsOneWidget);
  });
}
