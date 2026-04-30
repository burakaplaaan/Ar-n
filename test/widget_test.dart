// Temel widget smoke testleri.
//
// Firebase + Hive + SharedPreferences gerektiren tam `ArinApp` boot'u
// unit test ortamında mock edilmeden çalışmaz; onun yerine izole
// widget'ların render aşamasının crash'siz geçtiğini doğruluyoruz.
// Bu, değer katan minimum bar — tam entegrasyon testleri için ayrıca
// `integration_test/` klasörü önerilir (ileriki fazda).

import 'package:arin/core/constants/app_colors.dart';
import 'package:arin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppTheme.dark ve AppTheme.light hata fırlatmadan kurulur', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('AppColors token\'ları renk olarak çözülür', (tester) async {
    // Derleme zamanı değerleri — bir gün boşluk çıkarsa (Color(null) gibi)
    // bu test kırmızıya döner. Hızlı smoke için yeterli.
    expect(AppColors.emeraldDark, isA<Color>());
    expect(AppColors.backgroundNavy, isA<Color>());
    expect(AppColors.creamBase, isA<Color>());
  });

  testWidgets(
    'Basit sayfa render edilir ve dokunma çalışır',
    (tester) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => taps++,
                child: const Text('Dokun'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Dokun'));
      await tester.pump();
      expect(taps, 1);
    },
  );
}
