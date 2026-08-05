import 'dart:io' show Platform;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/admob_ids.dart';

class AdMobService {
  static const Duration _loadTimeout = Duration(seconds: 12);
  static const String _androidTestDeviceIdsDefine =
      'ARIN_ANDROID_TEST_DEVICE_IDS';

  /// Consent (UMP) akışının init'i süresiz kilitlememesi için üst sınır.
  /// Bu süre aşılırsa consent "fail-open" kabul edilir: SDK yine başlatılır
  /// ve reklam istenmeye devam eder. Kullanıcıların büyük çoğunluğu EEA
  /// dışındadır ve orada consent zaten gerekmez; tek bir ağ takılmasının
  /// tüm reklamları oturum boyunca kapatması kabul edilemez bir gerileme.
  static const Duration _consentTimeout = Duration(seconds: 6);
  static const Duration _iosStartupDelay = Duration(seconds: 6);

  /// Belirli ad unit için kısa-devre soğuma süresi. Yalnızca GERÇEK load
  /// hatasından (no-fill/şebeke/timeout) sonra uygulanır; art arda istek
  /// göndermenin anlamı yok. Eski 10 dk değeri tek bir geçici no-fill'de
  /// keşfet reklamlarını çok uzun süre susturuyordu — 1 dk yeterli.
  static const Duration _failureCooldown = Duration(minutes: 1);

  /// Cooldown haritası: ad unit ID → cooldown'ın bittiği epoch ms.
  static final Map<String, int> _cooldownUntil = <String, int>{};

  static Future<void>? _initializeFuture;
  static bool _sdkInitialized = false;

  /// Reklam istenebilir mi? Varsayılan `true` (fail-open): yalnızca UMP
  /// AÇIKÇA "consent gerekli ama alınmadı" derse `false` olur. Böylece
  /// consent akışındaki geçici bir hata reklamları yanlışlıkla kapatmaz.
  static bool _canRequestAds = true;

  static bool get _isSupportedMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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
        // Eksik yapılandırma kalıcı bir hata değil; sonraki çağrı yeniden
        // denesin diye cache'lenmiş future'ı temizle.
        _initializeFuture = null;
        return;
      }

      // SDK'yı consent sonucundan BAĞIMSIZ olarak başlat. Consent akışı
      // hata verse/asılsa bile reklam motoru hazır olsun; aksi halde tek
      // bir consent hıçkırığı tüm reklamları topyekûn öldürüyordu.
      if (!_sdkInitialized) {
        await MobileAds.instance.initialize();
        _sdkInitialized = true;
      }

      // Consent EN İYİ ÇABA ile yürütülür; sonuç [_canRequestAds]'i belirler.
      await _runConsentFlowBestEffort();
      _flushIosRewardedStartupPreload();

      // NOT: Preload burada KOŞULSUZ tetiklenmez. Premium kullanıcılar reklam
      // görmediği için onlara reklam yüklemek hem boşa istek hem de AdMob
      // "gösterim oranı"nı düşürür. Preload yalnızca premium OLMAYAN
      // kullanıcıların reklam gördüğü yüzeylerden ([preloadAds]) ve her
      // gösterimden sonra (bir sonraki için) tetiklenir.

      debugPrint(
        '══ ARIN ══ AdMob initialized (canRequestAds=$_canRequestAds)',
      );
    } catch (e) {
      debugPrint('══ ARIN ══ AdMob init failed (sessiz): $e');
      // Geçici hata: kalıcı kilitlenme olmasın, sonraki istek yeniden denesin.
      _initializeFuture = null;
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
    debugPrint(
      '══ ARIN ══ AdMob Android test devices configured: ${ids.length}',
    );
    return true;
  }

  /// UMP consent akışını en iyi çaba ile yürütür ve init'i asla süresiz
  /// bloke etmez.
  ///
  /// - Akış başarılıysa [_canRequestAds] UMP'nin gerçek kararını yansıtır
  ///   (EEA'da consent yoksa `false` → reklam istenmez; bu DOĞRU davranış).
  /// - Akış hata verir veya [_consentTimeout] aşılırsa fail-open davranılır
  ///   ([_canRequestAds] = `true`). Böylece geçici ağ/SDK sorunları tüm
  ///   reklamları susturmaz; EEA kullanıcısına consent formu bir sonraki
  ///   oturumda yeniden gösterilebilir.
  static Future<void> _runConsentFlowBestEffort() async {
    try {
      await _updateConsentStatus().timeout(_consentTimeout);
    } catch (e) {
      debugPrint('══ ARIN ══ AdMob consent best-effort fallback (sessiz): $e');
      _canRequestAds = true;
    }
  }

  static Future<void> _updateConsentStatus() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
          _canRequestAds = await ConsentInformation.instance.canRequestAds();
        } catch (e) {
          debugPrint('══ ARIN ══ AdMob consent form failed (sessiz): $e');
          // Form gösterilemese bile reklam isteğini engelleme (fail-open).
          _canRequestAds = true;
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (error) {
        debugPrint(
          '══ ARIN ══ AdMob consent info update failed (sessiz): $error',
        );
        // Güncelleme hatası geçicidir; reklamları kapatma (fail-open).
        _canRequestAds = true;
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
    _cooldownUntil[adUnitId] = DateTime.now()
        .add(_failureCooldown)
        .millisecondsSinceEpoch;
  }

  // ───────────────────────────────────────────────────────────────────────
  // PRELOAD KATMANI
  //
  // Reklamlar kullanıcı istediği AN yüklenmek yerine arka planda önceden
  // yüklenip hazırda tutulur. "İzle"ye basınca reklam ANINDA açılır; no-fill /
  // şebeke hatası kullanıcıya değil, sessiz arka plan retry'ına yansır. Bir
  // reklam gösterilince hemen yenisi yüklenir. Bu, "haftada bir hata" gibi
  // nadir geçici hataları kullanıcı için görünmez kılar.
  // ───────────────────────────────────────────────────────────────────────

  /// AdMob reklamları yüklendikten ~1 saat sonra geçersiz olur; biraz erken
  /// (55 dk) bayatlamış sayarız. Yenileme, yalnızca sonraki yüksek niyetli
  /// yüzey tekrar preload istediğinde yapılır.
  static const Duration _adCacheTtl = Duration(minutes: 55);
  static const Duration _preloadJoinTimeout = Duration(milliseconds: 800);

  /// Arka plan preload yüklemesi için watchdog süresi. SDK callback'i (çok
  /// nadir de olsa) hiç dönmezse `_loading` bayrağı sonsuza kadar takılı
  /// kalmasın; bu süre sonunda durum sıfırlanıp retry zamanlanır.
  static const Duration _preloadLoadTimeout = Duration(seconds: 20);

  /// Arka plan preload yeniden-deneme aralıkları (no-fill/şebeke sonrası).
  static const List<Duration> _preloadBackoff = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 20),
    Duration(seconds: 60),
    Duration(minutes: 3),
    Duration(minutes: 10),
  ];

  static Duration _backoffDelay(int retry) =>
      _preloadBackoff[retry.clamp(0, _preloadBackoff.length - 1)];

  // Ödüllü reklam preload durumu.
  static RewardedAd? _rewardedAd;
  static DateTime? _rewardedLoadedAt;
  static bool _rewardedLoading = false;
  static bool _rewardedShowing = false;
  static Completer<void>? _rewardedPreloadSettled;
  static Timer? _iosRewardedStartupTimer;
  static bool _rewardedPreloadEligible = false;
  static bool _rewardedEligibilityConfirmed = false;
  static bool _rewardedPreloadForeground = true;
  static int _rewardedLoadGeneration = 0;

  // Geçiş reklamı preload durumu.
  static InterstitialAd? _interstitialAd;
  static DateTime? _interstitialLoadedAt;
  static bool _interstitialLoading = false;
  static bool _interstitialShowing = false;
  static int _interstitialPreloadRetry = 0;
  static Timer? _interstitialPreloadTimer;

  static bool get _rewardedReady =>
      _rewardedAd != null &&
      _rewardedLoadedAt != null &&
      DateTime.now().difference(_rewardedLoadedAt!) < _adCacheTtl;

  static bool get _rewardedRequestAllowed =>
      _rewardedPreloadEligible &&
      _rewardedEligibilityConfirmed &&
      _rewardedPreloadForeground;

  static bool get _interstitialReady =>
      _interstitialAd != null &&
      _interstitialLoadedAt != null &&
      DateTime.now().difference(_interstitialLoadedAt!) < _adCacheTtl;

  /// Hem ödüllü hem geçiş reklamını arka planda önceden yüklemeyi başlatır.
  ///
  /// SADECE premium OLMAYAN kullanıcıların reklam gördüğü yüzeylerden
  /// çağrılmalıdır; premium kullanıcılar için boşa istek üretmemek için
  /// burada premium kontrolü YAPILMAZ — bu, çağıranın sorumluluğundadır.
  ///
  /// SDK henüz hazır değilse önce başlatılır; consent reddi durumunda
  /// ([_canRequestAds] = false) hiç yükleme yapılmaz.
  static void preloadAds() {
    if (!_isSupportedMobilePlatform) return;
    _runWhenReady(() {
      unawaited(_preloadRewarded());
      unawaited(_preloadInterstitial());
    });
  }

  /// Yalnızca ödüllü reklamı önceden yükler (örn. widget kilidi / 2. alarm gibi
  /// geçiş reklamı GÖSTERMEYEN yüzeyler için — gereksiz interstitial isteği
  /// üretmez). Premium kontrolü çağıranın sorumluluğundadır.
  static void preloadRewarded() {
    if (!_isSupportedMobilePlatform || !_rewardedRequestAllowed) {
      return;
    }
    // iOS'ta ATT ve ilk frame işlerini öne almak için var olan başlangıç
    // bariyerini bütün çağrı yollarında merkezi olarak uygula. Böylece resume,
    // provider listener veya widget sayfası bu sırayı yanlışlıkla bypass edemez.
    if (Platform.isIOS && !_sdkInitialized) {
      _iosRewardedStartupTimer ??= Timer(_iosStartupDelay, () {
        _iosRewardedStartupTimer = null;
        if (_rewardedPreloadEligible &&
            _rewardedEligibilityConfirmed &&
            _rewardedPreloadForeground) {
          _runWhenReady(() => unawaited(_preloadRewarded()));
        }
      });
      return;
    }
    _runWhenReady(() => unawaited(_preloadRewarded()));
  }

  /// Kullanıcı reklam izleme niyeti gösterdiğinde hazır cache'i kullanır veya
  /// tek bir preload başlatıp en fazla [timeout] kadar sonucunu bekler.
  ///
  /// Timeout reklamı sonradan otomatik göstermez; geç gelen başarılı sonuç
  /// cache'te kalır ve kullanıcının bir sonraki denemesinde kullanılabilir.
  bool get isRewardedReady => _rewardedReady && _rewardedRequestAllowed;

  Future<bool> prepareRewarded({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_isSupportedMobilePlatform) return false;
    try {
      return await _prepareRewarded().timeout(timeout, onTimeout: () => false);
    } catch (error) {
      debugPrint('AdMob rewarded preparation failed: $error');
      return false;
    }
  }

  Future<bool> _prepareRewarded() async {
    if (!_rewardedRequestAllowed) return false;
    if (_rewardedReady) return true;
    await initialize();
    if (!_sdkInitialized || !_canRequestAds || !_rewardedRequestAllowed) {
      return false;
    }
    if (_rewardedReady) return true;

    // Açık kullanıcı niyeti, uygulama başlangıcındaki iOS gecikmesinden daha
    // güçlüdür; bekleyen timer yerine yüklemeyi şimdi başlat.
    _iosRewardedStartupTimer?.cancel();
    _iosRewardedStartupTimer = null;
    unawaited(_preloadRewarded());
    final settled = _rewardedPreloadSettled;
    if (settled != null && !settled.isCompleted) {
      await settled.future;
    }
    return _rewardedReady && _rewardedRequestAllowed;
  }

  /// `main.dart` tarafından gecikmeli başlatılan iOS SDK hazır olduğunda,
  /// ilk preload isteğinin kendi fallback timer'ını beklemeden devam eder.
  static void _flushIosRewardedStartupPreload() {
    if (!Platform.isIOS || _iosRewardedStartupTimer == null) return;
    _iosRewardedStartupTimer?.cancel();
    _iosRewardedStartupTimer = null;
    if (_rewardedPreloadEligible &&
        _rewardedEligibilityConfirmed &&
        _rewardedPreloadForeground &&
        _canRequestAds) {
      unawaited(_preloadRewarded());
    }
  }

  /// Premium değişiminde preload durumunu servis seviyesinde günceller.
  ///
  /// Eligibility kapanınca cache dispose edilir ve tamamlanması geciken SDK
  /// callback'leri generation ile geçersiz kılınır. Böylece free iken başlayan
  /// istek premium olduktan sonra cache'e reklam koyamaz.
  static void setRewardedPreloadEligible(bool eligible) {
    final wasConfirmed = _rewardedEligibilityConfirmed;
    _rewardedEligibilityConfirmed = true;
    if (wasConfirmed && _rewardedPreloadEligible == eligible) return;
    _rewardedPreloadEligible = eligible;
    if (eligible) return;

    _rewardedLoadGeneration++;
    _iosRewardedStartupTimer?.cancel();
    _iosRewardedStartupTimer = null;
    _rewardedLoading = false;
    final signal = _rewardedPreloadSettled;
    if (signal != null) _completePreloadSignal(signal);
    _rewardedPreloadSettled = null;
    final cached = _rewardedAd;
    _rewardedAd = null;
    _rewardedLoadedAt = null;
    if (cached != null) unawaited(cached.dispose());
  }

  /// Resume sırasında entitlement yenilenene kadar yeni reklam isteğini ve
  /// gösterimini durdurur; hazır cache'i ise sonuç free gelirse kullanılmak
  /// üzere korur. Eski in-flight callback generation ile geçersizleşir.
  static void markRewardedEligibilityPending() {
    _rewardedEligibilityConfirmed = false;
    _rewardedLoadGeneration++;
    _iosRewardedStartupTimer?.cancel();
    _iosRewardedStartupTimer = null;
    _rewardedLoading = false;
    final signal = _rewardedPreloadSettled;
    if (signal != null) _completePreloadSignal(signal);
    _rewardedPreloadSettled = null;
  }

  /// Yeni preload isteklerinin yalnızca uygulama foreground'dayken
  /// çalışmasını sağlar. Var olan cache korunur.
  static void setRewardedPreloadForeground(bool foreground) {
    if (_rewardedPreloadForeground == foreground) return;
    _rewardedPreloadForeground = foreground;
    if (foreground) return;
    _rewardedLoadGeneration++;
    _rewardedLoading = false;
    final signal = _rewardedPreloadSettled;
    if (signal != null) _completePreloadSignal(signal);
    _rewardedPreloadSettled = null;
    _iosRewardedStartupTimer?.cancel();
    _iosRewardedStartupTimer = null;
  }

  /// Yalnızca geçiş (interstitial) reklamını önceden yükler.
  /// Premium kontrolü çağıranın sorumluluğundadır.
  static void preloadInterstitial() {
    if (!_isSupportedMobilePlatform) return;
    _runWhenReady(() => unawaited(_preloadInterstitial()));
  }

  static void _runWhenReady(void Function() action) {
    unawaited(
      initialize().then((_) {
        if (!_sdkInitialized || !_canRequestAds) return;
        action();
      }),
    );
  }

  static Future<void> _preloadRewarded() async {
    if (kIsWeb ||
        !_canRequestAds ||
        !_rewardedPreloadEligible ||
        !_rewardedEligibilityConfirmed ||
        !_rewardedPreloadForeground ||
        _rewardedLoading ||
        _rewardedShowing) {
      return;
    }
    if (_rewardedReady) return;
    final adUnitId = AdMobIds.unitId(ArinAdUnit.rewardedUnlock);
    if (adUnitId == null) return;
    _rewardedLoading = true;
    final generation = _rewardedLoadGeneration;
    final preloadSettled = Completer<void>();
    _rewardedPreloadSettled = preloadSettled;

    final stale = _rewardedAd;
    if (stale != null) {
      _rewardedAd = null;
      _rewardedLoadedAt = null;
      await stale.dispose();
    }
    var settled = false;
    Timer? watchdog;
    watchdog = Timer(_preloadLoadTimeout, () {
      if (settled) return;
      settled = true;
      if (generation != _rewardedLoadGeneration || !_rewardedRequestAllowed) {
        _completePreloadSignal(preloadSettled);
        return;
      }
      _rewardedLoading = false;
      debugPrint('AdMob rewarded preload watchdog timeout');
      _completePreloadSignal(preloadSettled);
    });
    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (settled ||
                generation != _rewardedLoadGeneration ||
                !_rewardedRequestAllowed) {
              if (!settled) {
                settled = true;
                watchdog?.cancel();
                _completePreloadSignal(preloadSettled);
              }
              ad.dispose();
              return;
            }
            settled = true;
            watchdog?.cancel();
            final previous = _rewardedAd;
            _rewardedAd = ad;
            _rewardedLoadedAt = DateTime.now();
            _rewardedLoading = false;
            _completePreloadSignal(preloadSettled);
            if (previous != null && !identical(previous, ad)) {
              unawaited(previous.dispose());
            }
            debugPrint('══ ARIN ══ AdMob rewarded preloaded');
          },
          onAdFailedToLoad: (error) {
            if (settled) return;
            settled = true;
            watchdog?.cancel();
            if (generation != _rewardedLoadGeneration ||
                !_rewardedRequestAllowed) {
              _completePreloadSignal(preloadSettled);
              return;
            }
            _rewardedLoading = false;
            debugPrint('AdMob rewarded preload failed: $error');
            _completePreloadSignal(preloadSettled);
          },
        ),
      );
    } catch (e) {
      if (!settled) {
        settled = true;
        watchdog.cancel();
        if (generation != _rewardedLoadGeneration || !_rewardedRequestAllowed) {
          _completePreloadSignal(preloadSettled);
          return;
        }
        _rewardedLoading = false;
        debugPrint('AdMob rewarded preload threw: $e');
        _completePreloadSignal(preloadSettled);
      }
    }
  }

  static void _completePreloadSignal(Completer<void> signal) {
    if (!signal.isCompleted) signal.complete();
  }

  static Future<void> _preloadInterstitial() async {
    if (kIsWeb ||
        !_canRequestAds ||
        _interstitialLoading ||
        _interstitialReady) {
      return;
    }
    final adUnitId = AdMobIds.unitId(ArinAdUnit.exploreInterstitial);
    if (adUnitId == null) return;
    if (_isInCooldown(adUnitId)) return;
    _interstitialLoading = true;
    final stale = _interstitialAd;
    if (stale != null) {
      _interstitialAd = null;
      _interstitialLoadedAt = null;
      await stale.dispose();
    }
    var settled = false;
    Timer? watchdog;
    watchdog = Timer(_preloadLoadTimeout, () {
      if (settled) return;
      settled = true;
      _interstitialLoading = false;
      debugPrint('AdMob interstitial preload watchdog timeout');
      _scheduleInterstitialPreloadRetry();
    });
    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (settled) {
              ad.dispose();
              return;
            }
            settled = true;
            watchdog?.cancel();
            _interstitialAd = ad;
            _interstitialLoadedAt = DateTime.now();
            _interstitialLoading = false;
            _interstitialPreloadRetry = 0;
            debugPrint('══ ARIN ══ AdMob interstitial preloaded');
          },
          onAdFailedToLoad: (error) {
            if (settled) return;
            settled = true;
            watchdog?.cancel();
            _interstitialLoading = false;
            debugPrint('AdMob interstitial preload failed: $error');
            _scheduleInterstitialPreloadRetry();
          },
        ),
      );
    } catch (e) {
      if (!settled) {
        settled = true;
        watchdog.cancel();
        _interstitialLoading = false;
        debugPrint('AdMob interstitial preload threw: $e');
        _scheduleInterstitialPreloadRetry();
      }
    }
  }

  static void _scheduleInterstitialPreloadRetry() {
    _interstitialPreloadTimer?.cancel();
    final delay = _backoffDelay(_interstitialPreloadRetry);
    _interstitialPreloadRetry++;
    _interstitialPreloadTimer = Timer(
      delay,
      () => unawaited(_preloadInterstitial()),
    );
  }

  /// Önceden yüklenmiş ödüllü reklamı gösterir. Hazır değilse `null` döner
  /// (çağıran on-demand yola düşer).
  Future<RewardedAdResult?> _showPreloadedRewarded({
    String? serverSideCustomData,
  }) async {
    if (!_rewardedReady || !_rewardedRequestAllowed || _rewardedShowing) {
      return null;
    }
    final generation = _rewardedLoadGeneration;
    final ad = _rewardedAd!;
    _rewardedAd = null;
    _rewardedLoadedAt = null;
    _rewardedShowing = true;
    final completer = Completer<RewardedAdResult>();
    var earned = false;
    if (serverSideCustomData != null) {
      try {
        await ad.setServerSideOptions(
          ServerSideVerificationOptions(customData: serverSideCustomData),
        );
      } catch (error) {
        debugPrint('AdMob rewarded SSV options failed: $error');
        await ad.dispose();
        _rewardedShowing = false;
        return RewardedAdResult.showFailed;
      }
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedShowing = false;
        _completeOnceOutcome(
          completer,
          earned ? RewardedAdResult.rewarded : RewardedAdResult.notRewarded,
        );
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob preloaded rewarded show failed: $error');
        ad.dispose();
        _rewardedShowing = false;
        _completeOnceOutcome(completer, RewardedAdResult.showFailed);
      },
    );
    if (generation != _rewardedLoadGeneration || !_rewardedRequestAllowed) {
      await ad.dispose();
      _rewardedShowing = false;
      return RewardedAdResult.showFailed;
    }
    try {
      await ad.show(onUserEarnedReward: (_, __) => earned = true);
    } catch (e) {
      debugPrint('AdMob preloaded rewarded show threw: $e');
      ad.dispose();
      _rewardedShowing = false;
      _completeOnceOutcome(completer, RewardedAdResult.showFailed);
    }
    return completer.future;
  }

  /// Önceden yüklenmiş geçiş reklamını gösterir. Hazır değilse `null` döner.
  Future<bool?> _showPreloadedInterstitial() async {
    if (!_interstitialReady || _interstitialShowing) return null;
    final ad = _interstitialAd!;
    _interstitialAd = null;
    _interstitialLoadedAt = null;
    _interstitialShowing = true;
    final completer = Completer<bool>();
    var shown = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => shown = true,
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialShowing = false;
        _completeOnce(completer, shown);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob preloaded interstitial show failed: $error');
        ad.dispose();
        _interstitialShowing = false;
        _completeOnce(completer, false);
      },
    );
    try {
      await ad.show();
    } catch (e) {
      debugPrint('AdMob preloaded interstitial show threw: $e');
      ad.dispose();
      _interstitialShowing = false;
      _completeOnce(completer, false);
    }
    return completer.future;
  }

  Future<bool> showInterstitial(ArinAdUnit unit) async {
    final adUnitId = AdMobIds.unitId(unit);
    if (adUnitId == null) return false;
    await initialize();
    if (!_canRequestAds) return false;

    // 1) Hazır (preloaded) reklam varsa anında göster, sonra yenisini hazırla.
    if (unit == ArinAdUnit.exploreInterstitial) {
      final shown = await _showPreloadedInterstitial();
      if (shown != null) {
        unawaited(_preloadInterstitial());
        return shown;
      }
    }

    // 2) Hazır reklam yok → on-demand yükle (cooldown'a saygı), sonra preload.
    if (_isInCooldown(adUnitId)) {
      debugPrint('AdMob interstitial: cooldown aktif, istek atlanıyor');
      unawaited(_preloadInterstitial());
      return false;
    }
    final shown = await _loadAndShowInterstitial(adUnitId);
    unawaited(_preloadInterstitial());
    return shown;
  }

  Future<bool> _loadAndShowInterstitial(String adUnitId) async {
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
  Future<RewardedAdResult> showRewardedDetailed(
    ArinAdUnit unit, {
    String? serverSideCustomData,
  }) async {
    final adUnitId = AdMobIds.unitId(unit);
    if (adUnitId == null) return RewardedAdResult.loadFailed;
    await initialize();
    if (!_canRequestAds) return RewardedAdResult.loadFailed;
    final isUnlockAd = unit == ArinAdUnit.rewardedUnlock;
    final requestGeneration = _rewardedLoadGeneration;
    if (isUnlockAd && !_rewardedRequestAllowed) {
      return RewardedAdResult.loadFailed;
    }

    // 1) Hazır (preloaded) reklam varsa anında göster.
    if (isUnlockAd) {
      final preloaded = await _showPreloadedRewarded(
        serverSideCustomData: serverSideCustomData,
      );
      if (preloaded != null) {
        return preloaded;
      }

      // İlgili reklam yüzeyinde başlatılan preload hâlâ devam ediyorsa ayrı bir
      // ikinci reklam isteği açmak yerine kısa süre aynı isteğin sonucunu bekle.
      // Başarılı olursa reklam hemen gösterilir; takılırsa on-demand fallback
      // mevcut davranışıyla devam eder.
      final preloadSettled = _rewardedPreloadSettled;
      if (_rewardedLoading && preloadSettled != null) {
        await preloadSettled.future.timeout(
          _preloadJoinTimeout,
          onTimeout: () {},
        );
        final warmed = await _showPreloadedRewarded(
          serverSideCustomData: serverSideCustomData,
        );
        if (warmed != null) {
          return warmed;
        }
      }
    }

    // 2) Hazır reklam yok → on-demand yükle (geçici hatalarda retry'lı).
    for (var attempt = 0; attempt < _rewardedMaxAttempts; attempt++) {
      if (isUnlockAd &&
          (requestGeneration != _rewardedLoadGeneration ||
              !_rewardedRequestAllowed)) {
        return RewardedAdResult.loadFailed;
      }
      final outcome = await _loadAndShowRewarded(
        adUnitId,
        serverSideCustomData: serverSideCustomData,
        canShow: isUnlockAd
            ? () =>
                  requestGeneration == _rewardedLoadGeneration &&
                  _rewardedRequestAllowed
            : null,
      );
      if (outcome != RewardedAdResult.loadFailed) {
        return outcome;
      }
      if (attempt < _rewardedMaxAttempts - 1) {
        await Future<void>.delayed(_rewardedRetryDelay);
      }
    }
    return RewardedAdResult.loadFailed;
  }

  Future<RewardedAdResult> _loadAndShowRewarded(
    String adUnitId, {
    String? serverSideCustomData,
    bool Function()? canShow,
  }) async {
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
          onAdLoaded: (ad) async {
            if (!active || (canShow != null && !canShow())) {
              waitingForLoad = false;
              loadTimer?.cancel();
              ad.dispose();
              _completeOnceOutcome(completer, RewardedAdResult.loadFailed);
              return;
            }
            waitingForLoad = false;
            loadTimer?.cancel();
            if (serverSideCustomData != null) {
              try {
                await ad.setServerSideOptions(
                  ServerSideVerificationOptions(
                    customData: serverSideCustomData,
                  ),
                );
              } catch (error) {
                debugPrint('AdMob rewarded SSV options failed: $error');
                ad.dispose();
                _completeOnceOutcome(completer, RewardedAdResult.showFailed);
                return;
              }
            }
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
            if (canShow != null && !canShow()) {
              ad.dispose();
              _completeOnceOutcome(completer, RewardedAdResult.loadFailed);
              return;
            }
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
