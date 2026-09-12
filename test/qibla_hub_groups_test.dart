import 'package:arin/l10n/app_localizations_tr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kıble hub asıl adlar duruyor', () {
    final l10n = AppLocalizationsTr();
    expect(l10n.qiblaHubAiTitle, 'İslami Yapay Zeka');
    expect(l10n.qiblaHubPremiumBadge, 'Premium');
    expect(l10n.qiblaHubCompassTitle, 'Kıble yönünü bul');
    expect(l10n.qiblaHubZikirTitle, 'Zikirmatik');
    expect(l10n.qiblaHubHilalDuelTitle, 'Bilgi Düellosu');
    expect(l10n.qiblaHubPrayerCircleTitle, 'Dua Halkası');
    expect(l10n.qiblaHubHealingTitle, 'İyileştirici Frekanslar');
    expect(l10n.qiblaHubBreathingTitle, 'Nefes Egzersizi');
  });
}
