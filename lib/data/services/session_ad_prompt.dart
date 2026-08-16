import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ads/admob_ids.dart';
import '../../presentation/shared/providers/ad_gate_providers.dart';
import '../../presentation/shared/providers/admob_providers.dart';
import '../../presentation/shared/providers/premium_providers.dart';
import 'ad_gate_service.dart';

/// Namaz/ezan dışındaki araç açılışlarında, boğmadan interstitial.
class SessionAdPrompt {
  SessionAdPrompt._();

  static DateTime? _lastShownAt;

  static bool shownRecently({
    Duration window = const Duration(minutes: 3),
  }) {
    final last = _lastShownAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < window;
  }

  static Future<void> maybeShow({
    required WidgetRef ref,
    required AdGatePlacement placement,
  }) async {
    if (ref.read(isPremiumProvider)) return;
    final access = ref.read(premiumAccessStateProvider);
    if (access != PremiumAccessState.free) return;

    final gate = ref.read(adGateServiceProvider);
    final decision = gate.decisionFor(placement, isPremium: false);
    if (!decision.requiresRewardedAd) return;

    final shown = await ref
        .read(adMobServiceProvider)
        .showInterstitial(ArinAdUnit.exploreInterstitial);
    if (shown) {
      _lastShownAt = DateTime.now();
      await gate.recordRewardedUnlock(placement);
    }
  }
}
