import 'package:arin/data/services/paywall_prompt_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(PaywallPromptService.resetSessionForTest);

  test('oturum bayrağı başlangıçta kapalıdır', () {
    expect(PaywallPromptService.shownAfterFeatureThisSession, isFalse);
  });
}
