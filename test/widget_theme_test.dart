import 'package:arin/data/models/widget_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('klasik tema ücretsizdir, diğerleri premium', () {
    expect(ArinWidgetTheme.byId('classic').premiumOnly, isFalse);
    final premiumThemes = ArinWidgetTheme.all.where((t) => t.premiumOnly);
    expect(premiumThemes.length, 6);
  });

  test('premium olmayan kullanıcı premium temayı klasike düşürür', () {
    expect(
      ArinWidgetTheme.resolveEffectiveId(
        requestedId: 'emerald',
        isPremium: false,
      ),
      ArinWidgetTheme.classicId,
    );
    expect(
      ArinWidgetTheme.resolveEffectiveId(
        requestedId: 'emerald',
        isPremium: true,
      ),
      'emerald',
    );
  });

  test('bilinmeyen tema klasike düşer', () {
    expect(ArinWidgetTheme.byId('missing').id, ArinWidgetTheme.classicId);
  });
}
