import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

enum ArinAdUnit { exploreInterstitial, rewardedUnlock }

abstract final class AdMobIds {
  /// Production ad unit ID'leri — Debug/Profile dahil her build'de.
  ///
  /// Mediation (Meta / Unity bidding) yalnızca bu unit'lerin AdMob
  /// mediation grubunda tanımlı; Google örnek unit'leri (`3940…`) o grubu
  /// taşımaz. Test trafiği için cihazı AdMob Test device / Ad Inspector
  /// ile işaretle; örnek App ID / unit kullanma.
  static String? unitId(ArinAdUnit unit) {
    if (kIsWeb) return null;

    return switch (unit) {
      ArinAdUnit.exploreInterstitial =>
        Platform.isAndroid
            ? 'ca-app-pub-1679454938492660/6143113424'
            : Platform.isIOS
            ? 'ca-app-pub-1679454938492660/6105567901'
            : null,
      ArinAdUnit.rewardedUnlock =>
        Platform.isAndroid
            ? 'ca-app-pub-1679454938492660/4189851009'
            : Platform.isIOS
            ? 'ca-app-pub-1679454938492660/3207941824'
            : null,
    };
  }
}
