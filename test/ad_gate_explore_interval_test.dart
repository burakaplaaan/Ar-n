import 'package:arin/data/services/ad_gate_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('keşfet reklamı her kartta değil, her 8. kartta açılır', () async {
    SharedPreferences.setMockInitialValues({
      'ad_gate_explore_swipe_view_count': 7,
    });
    final prefs = await SharedPreferences.getInstance();
    final gate = AdGateService(prefs);

    expect(
      await gate.recordExploreViewAndShouldShowAd(isPremium: false),
      isTrue,
    );
    expect(
      await gate.recordExploreViewAndShouldShowAd(isPremium: false),
      isFalse,
    );
    expect(
      await gate.recordExploreViewAndShouldShowAd(isPremium: false),
      isFalse,
    );

    await prefs.setInt('ad_gate_explore_swipe_view_count', 15);
    expect(
      await gate.recordExploreViewAndShouldShowAd(isPremium: false),
      isTrue,
    );
  });

  test('premium kullanıcıda keşfet reklamı açılmaz', () async {
    SharedPreferences.setMockInitialValues({
      'ad_gate_explore_swipe_view_count': 7,
    });
    final prefs = await SharedPreferences.getInstance();
    final gate = AdGateService(prefs);
    expect(
      await gate.recordExploreViewAndShouldShowAd(isPremium: true),
      isFalse,
    );
  });
}
