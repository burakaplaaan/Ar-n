import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

enum ArinAdUnit { exploreInterstitial, rewardedUnlock }

abstract final class AdMobIds {
  /// Tüm non-release build'lerde test reklam kullanılır.
  /// iOS release'te gerçek reklam göstermek için false olmalı.
  /// Android release için ayrı bir politika anahtarı vardır:
  /// [kForceAndroidReleaseTestAds].
  ///
  /// Ne zaman `false` yapacaksın (iOS release için):
  ///   1. AdMob Console → Apps → Arın → Status: Ready (yeşil tik)
  ///   2. Test cihazında en az 3 reklam başarıyla yüklendi
  ///   3. App Store Connect'e gönderilecek release build alıyorsun
  ///
  /// Test ID'leri her zaman %100 fill rate verir, gelir üretmez ama UX'i
  /// gerçek reklamla aynıdır → kullanıcı hiç fark etmez, log temiz kalır.
  static const bool kForceTestAds = false;
  static const bool kForceAndroidReleaseTestAds = true;

  static String? unitId(ArinAdUnit unit) {
    if (kIsWeb) return null;

    final isReleaseAndroid = kReleaseMode && Platform.isAndroid;
    final useTestIds =
        !kReleaseMode ||
        kForceTestAds ||
        (isReleaseAndroid && kForceAndroidReleaseTestAds);

    if (useTestIds) {
      return switch (unit) {
        ArinAdUnit.exploreInterstitial =>
          Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/1033173712'
              : Platform.isIOS
              ? 'ca-app-pub-3940256099942544/4411468910'
              : null,
        ArinAdUnit.rewardedUnlock =>
          Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/5224354917'
              : Platform.isIOS
              ? 'ca-app-pub-3940256099942544/1712485313'
              : null,
      };
    }

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
