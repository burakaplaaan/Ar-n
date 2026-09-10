import 'package:arin/data/services/ad_gate_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const interval = AdGateService.exploreSwipeFreeCount;

  test('keşfet reklamı her kartta değil, her N. kartta açılır', () async {
    SharedPreferences.setMockInitialValues({
      'ad_gate_explore_swipe_view_count': interval - 1,
    });
    final prefs = await SharedPreferences.getInstance();
    final gate = AdGateService(prefs);

    expect(
      await gate.recordExploreViewAndShouldShowAd(isPremium: false),
      isTrue,
    );
    for (var i = 1; i < interval; i++) {
      expect(
        await gate.recordExploreViewAndShouldShowAd(isPremium: false),
        isFalse,
        reason: 'aralık içindeki $i. kartta reklam açılmamalı',
      );
    }
    expect(
      await gate.recordExploreViewAndShouldShowAd(isPremium: false),
      isTrue,
    );

    await prefs.setInt(
      'ad_gate_explore_swipe_view_count',
      interval * 3 - 1,
    );
    expect(
      await gate.recordExploreViewAndShouldShowAd(isPremium: false),
      isTrue,
    );
  });

  test('premium kullanıcıda keşfet reklamı açılmaz', () async {
    SharedPreferences.setMockInitialValues({
      'ad_gate_explore_swipe_view_count': interval - 1,
    });
    final prefs = await SharedPreferences.getInstance();
    final gate = AdGateService(prefs);
    expect(
      await gate.recordExploreViewAndShouldShowAd(isPremium: true),
      isFalse,
    );
  });
}
