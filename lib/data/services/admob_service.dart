import 'dart:io' show Platform;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/admob_ids.dart';

class AdMobService {
  static const Duration _loadTimeout = Duration(seconds: 12);
  static const String _androidTestDeviceIdsDefine =
      'ARIN_ANDROID_TEST_DEVICE_IDS';

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
      final internalTrafficSafe = await _configureAndroidInternalTestDevices();
      if (!internalTrafficSafe) {
        _canRequestAds = false;
        debugPrint(
          '══ ARIN ══ AdMob init blocked: Android non-release requires '
          '--dart-define=$_androidTestDeviceIdsDefine=id1,id2',
        );
        return;
      }
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

  static Future<bool> _configureAndroidInternalTestDevices() async {
    if (!Platform.isAndroid || kReleaseMode) return true;
    final raw = const String.fromEnvironment(
      _androidTestDeviceIdsDefine,
      defaultValue: '',
    ).trim();
    if (raw.isEmpty) {
      return false;
    }
    final ids = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (ids.isEmpty) return false;
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ids),
    );
    debugPrint('══ ARIN ══ AdMob Android test devices configured: ${ids.length}');
    return true;
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

  /// Ödüllü reklam denemesinin sonucu. `loadFailed` geçici (no-fill/şebeke)
  /// hatasıdır ve yeniden denenebilir; diğer sonuçlar terminaldir.
  static const _rewardedRetryDelay = Duration(milliseconds: 800);
  static const _rewardedMaxAttempts = 3;

  /// Kullanıcının BİLEREK istediği ödüllü reklam (widget kilidi açma).
  ///
  /// `true` yalnızca kullanıcı ödülü kazandığında döner. Çağıranların yalnızca
  /// "ödül kazanıldı mı?" bilgisine ihtiyacı varsa bunu kullanır. Yükleme
  /// hatası ile kullanıcının reklamı erken kapatmasını ayırt etmek gerekirse
  /// [showRewardedDetailed] tercih edilmeli.
  Future<bool> showRewarded(ArinAdUnit unit) async {
    final result = await showRewardedDetailed(unit);
    return result == RewardedAdResult.rewarded;
  }

  /// [showRewarded]'in ayrıntılı sürümü.
  ///
  /// Interstitial'daki 10 dk soğuma BURADA UYGULANMAZ: tek bir geçici "no fill"
  /// kullanıcıyı 10 dk boyunca "daha sonra tekrar dene"ye kilitliyordu. Bunun
  /// yerine geçici yükleme hatalarında kısa aralıklarla birkaç kez yeniden
  /// denenir; yalnızca tüm denemeler tükenirse [RewardedAdResult.loadFailed]
  /// döner. Kullanıcı reklamı erken kapatırsa [RewardedAdResult.notRewarded]
  /// döner (bu bir hata değildir; "yüklenemedi" mesajı gösterilmemeli).
  Future<RewardedAdResult> showRewardedDetailed(ArinAdUnit unit) async {
    final adUnitId = AdMobIds.unitId(unit);
    if (adUnitId == null) return RewardedAdResult.loadFailed;
    await initialize();
    if (!_canRequestAds) return RewardedAdResult.loadFailed;

    for (var attempt = 0; attempt < _rewardedMaxAttempts; attempt++) {
      final outcome = await _loadAndShowRewarded(adUnitId);
      if (outcome != RewardedAdResult.loadFailed) {
        return outcome;
      }
      if (attempt < _rewardedMaxAttempts - 1) {
        await Future<void>.delayed(_rewardedRetryDelay);
      }
    }
    return RewardedAdResult.loadFailed;
  }

  Future<RewardedAdResult> _loadAndShowRewarded(String adUnitId) async {
    final completer = Completer<RewardedAdResult>();
    var active = true;
    var waitingForLoad = true;
    Timer? loadTimer;
    var earnedReward = false;
    try {
      loadTimer = Timer(_loadTimeout, () {
        if (!waitingForLoad || completer.isCompleted) return;
        active = false;
        debugPrint('AdMob rewarded load timed out');
        _completeOnceOutcome(completer, RewardedAdResult.loadFailed);
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
                _completeOnceOutcome(
                  completer,
                  earnedReward
                      ? RewardedAdResult.rewarded
                      : RewardedAdResult.notRewarded,
                );
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('AdMob rewarded show failed: $error');
                ad.dispose();
                _completeOnceOutcome(completer, RewardedAdResult.showFailed);
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
                      _completeOnceOutcome(
                        completer,
                        RewardedAdResult.showFailed,
                      );
                    }),
              );
            } catch (e) {
              debugPrint('AdMob rewarded show threw: $e');
              ad.dispose();
              _completeOnceOutcome(completer, RewardedAdResult.showFailed);
            }
          },
          onAdFailedToLoad: (error) {
            waitingForLoad = false;
            loadTimer?.cancel();
            debugPrint('AdMob rewarded load failed: $error');
            _completeOnceOutcome(completer, RewardedAdResult.loadFailed);
          },
        ),
      );
    } catch (e) {
      waitingForLoad = false;
      loadTimer?.cancel();
      debugPrint('AdMob rewarded load threw: $e');
      _completeOnceOutcome(completer, RewardedAdResult.loadFailed);
    }
    return completer.future;
  }

  void _completeOnce(Completer<bool> completer, bool value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  void _completeOnceOutcome(
    Completer<RewardedAdResult> completer,
    RewardedAdResult value,
  ) {
    if (!completer.isCompleted) completer.complete(value);
  }
}

/// Ödüllü reklam denemesinin sonucu.
///
/// - [rewarded]: kullanıcı reklamı tamamladı ve ödülü kazandı.
/// - [notRewarded]: reklam gösterildi ama kullanıcı ödülü kazanmadan kapattı.
/// - [loadFailed]: reklam yüklenemedi (no-fill/şebeke/timeout) — tüm denemeler
///   tükendi.
/// - [showFailed]: reklam yüklendi ama gösterilemedi.
enum RewardedAdResult { rewarded, notRewarded, loadFailed, showFailed }
