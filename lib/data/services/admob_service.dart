import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/admob_ids.dart';

class AdMobService {
  static const Duration _loadTimeout = Duration(seconds: 12);

  /// Belirli ad unit için kısa-devre soğuma süresi. AdMob load'u
  /// "Account not approved" / "no fill" gibi kalıcı bir hata döndüğünde
  /// art arda istek göndermenin anlamı yok — log'u kirletiyor, ana
  /// isolate'i meşgul ediyor, network retry timer'ları CPU yiyor.
  /// Bu cooldown bittikten sonra tekrar bir deneme şansı verilir
  /// (hesap o sırada onaylanmış olabilir).
  static const Duration _failureCooldown = Duration(minutes: 10);

  /// Cooldown haritası: ad unit ID → cooldown'ın bittiği epoch ms.
  static final Map<String, int> _cooldownUntil = <String, int>{};

  static Future<void>? _initializeFuture;
  static bool _consentFlowCompleted = false;
  static bool _canRequestAds = false;

  static Future<void> initialize() {
    return _initializeFuture ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      await _updateConsentStatus();
      if (!_canRequestAds) {
        debugPrint('══ ARIN ══ AdMob init skipped: consent not granted yet');
        return;
      }
      await MobileAds.instance.initialize();
      debugPrint('══ ARIN ══ AdMob initialized');
    } catch (e) {
      _canRequestAds = false;
      debugPrint('══ ARIN ══ AdMob init failed (sessiz): $e');
    }
  }

  static Future<void> _updateConsentStatus() async {
    if (_consentFlowCompleted) return;
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
          _canRequestAds = await ConsentInformation.instance.canRequestAds();
        } catch (e) {
          debugPrint('══ ARIN ══ AdMob consent form failed (sessiz): $e');
          _canRequestAds = false;
        } finally {
          _consentFlowCompleted = true;
          if (!completer.isCompleted) completer.complete();
        }
      },
      (error) {
        debugPrint('══ ARIN ══ AdMob consent info update failed (sessiz): $error');
        _canRequestAds = false;
        _consentFlowCompleted = true;
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
  }

  /// Belirli ad unit için cooldown aktifse true.
  static bool _isInCooldown(String adUnitId) {
    final until = _cooldownUntil[adUnitId];
    if (until == null) return false;
    if (DateTime.now().millisecondsSinceEpoch >= until) {
      _cooldownUntil.remove(adUnitId);
      return false;
    }
    return true;
  }

  /// Kalıcı hata sonrası soğumayı işaretle.
  static void _markCooldown(String adUnitId) {
    _cooldownUntil[adUnitId] =
        DateTime.now().add(_failureCooldown).millisecondsSinceEpoch;
  }

  Future<bool> showInterstitial(ArinAdUnit unit) async {
    final adUnitId = AdMobIds.unitId(unit);
    if (adUnitId == null) return false;
    await initialize();
    if (!_canRequestAds) return false;
    if (_isInCooldown(adUnitId)) {
      debugPrint('AdMob interstitial: cooldown aktif, istek atlanıyor');
      return false;
    }

    final completer = Completer<bool>();
    var active = true;
    var waitingForLoad = true;
    Timer? loadTimer;
    try {
      loadTimer = Timer(_loadTimeout, () {
        if (!waitingForLoad || completer.isCompleted) return;
        active = false;
        debugPrint('AdMob interstitial load timed out');
        _markCooldown(adUnitId);
        _completeOnce(completer, false);
      });
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!active) {
              ad.dispose();
              return;
            }
            waitingForLoad = false;
            loadTimer?.cancel();
            var completed = false;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (_) => completed = true,
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _completeOnce(completer, completed);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('AdMob interstitial show failed: $error');
                ad.dispose();
                _completeOnce(completer, false);
              },
            );
            try {
              unawaited(
                ad.show().catchError((Object e) {
                  debugPrint('AdMob interstitial show future failed: $e');
                  ad.dispose();
                  _completeOnce(completer, false);
                }),
              );
            } catch (e) {
              debugPrint('AdMob interstitial show threw: $e');
              ad.dispose();
              _completeOnce(completer, false);
            }
          },
          onAdFailedToLoad: (error) {
            waitingForLoad = false;
            loadTimer?.cancel();
            debugPrint('AdMob interstitial load failed: $error');
            _markCooldown(adUnitId);
            _completeOnce(completer, false);
          },
        ),
      );
    } catch (e) {
      waitingForLoad = false;
      loadTimer?.cancel();
      debugPrint('AdMob interstitial load threw: $e');
      _markCooldown(adUnitId);
      _completeOnce(completer, false);
    }
    return completer.future;
  }

  Future<bool> showRewarded(ArinAdUnit unit) async {
    final adUnitId = AdMobIds.unitId(unit);
    if (adUnitId == null) return false;
    await initialize();
    if (!_canRequestAds) return false;
    if (_isInCooldown(adUnitId)) {
      debugPrint('AdMob rewarded: cooldown aktif, istek atlanıyor');
      return false;
    }

    final completer = Completer<bool>();
    var active = true;
    var waitingForLoad = true;
    Timer? loadTimer;
    var earnedReward = false;
    try {
      loadTimer = Timer(_loadTimeout, () {
        if (!waitingForLoad || completer.isCompleted) return;
        active = false;
        debugPrint('AdMob rewarded load timed out');
        _markCooldown(adUnitId);
        _completeOnce(completer, false);
      });
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (!active) {
              ad.dispose();
              return;
            }
            waitingForLoad = false;
            loadTimer?.cancel();
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _completeOnce(completer, earnedReward);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('AdMob rewarded show failed: $error');
                ad.dispose();
                _completeOnce(completer, false);
              },
            );
            try {
              unawaited(
                ad
                    .show(
                      onUserEarnedReward: (_, __) {
                        earnedReward = true;
                      },
                    )
                    .catchError((Object e) {
                      debugPrint('AdMob rewarded show future failed: $e');
                      ad.dispose();
                      _completeOnce(completer, false);
                    }),
              );
            } catch (e) {
              debugPrint('AdMob rewarded show threw: $e');
              ad.dispose();
              _completeOnce(completer, false);
            }
          },
          onAdFailedToLoad: (error) {
            waitingForLoad = false;
            loadTimer?.cancel();
            debugPrint('AdMob rewarded load failed: $error');
            _markCooldown(adUnitId);
            _completeOnce(completer, false);
          },
        ),
      );
    } catch (e) {
      waitingForLoad = false;
      loadTimer?.cancel();
      debugPrint('AdMob rewarded load threw: $e');
      _markCooldown(adUnitId);
      _completeOnce(completer, false);
    }
    return completer.future;
  }

  void _completeOnce(Completer<bool> completer, bool value) {
    if (!completer.isCompleted) completer.complete(value);
  }
}
