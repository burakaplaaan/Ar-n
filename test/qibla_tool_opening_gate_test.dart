import 'package:arin/l10n/app_localizations.dart';
import 'package:arin/presentation/qibla/qibla_tool_opening_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('yerleşik rotada çocuk bir kare sonra açılır', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QiblaToolOpeningGate(child: Text('tool-ready')),
        ),
      ),
    );

    expect(find.text('tool-ready'), findsNothing);

    await tester.pump();
    await tester.pump();

    expect(find.text('tool-ready'), findsOneWidget);
  });
}
