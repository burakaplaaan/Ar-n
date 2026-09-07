import 'package:arin/core/services/arin_review_prompter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('yorum isteği eşikleri biraz daha erken açılır', () {
    expect(ArinReviewPrompter.launchCountThreshold, 2);
    expect(ArinReviewPrompter.minSinceFirstLaunch, const Duration(days: 1));
    expect(ArinReviewPrompter.minFeatureUseDuration, const Duration(seconds: 6));
    expect(ArinReviewPrompter.maxTotalAsks, 8);
  });

  test('kısa özellik kullanımı yorum istemez', () async {
    final prefs = await SharedPreferences.getInstance();
    await ArinReviewPrompter.maybeAskAfterFeatureUse(
      prefs,
      usedFor: const Duration(seconds: 2),
    );
    expect(prefs.getInt('review_total_ask_count'), isNull);
  });
}
