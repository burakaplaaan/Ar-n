import 'package:shared_preferences/shared_preferences.dart';

import 'global_widget_lock_service.dart';

enum AdGatePlacement {
  lockScreenWidget,
  widgetQuote,
  widgetPrayer,
  widgetCombo,
  widgetTracking,
  widgetZikir,
  exploreSwipe,
  prayerSecondAlarm,
  zikirSession,
  healingSession,
  qiblaSession,
}

extension AdGatePlacementKeys on AdGatePlacement {
  String get key {
    switch (this) {
      case AdGatePlacement.lockScreenWidget:
        return 'lock_widget';
      case AdGatePlacement.widgetQuote:
        return 'widget_quote';
      case AdGatePlacement.widgetPrayer:
        return 'widget_prayer';
      case AdGatePlacement.widgetCombo:
        return 'widget_combo';
      case AdGatePlacement.widgetTracking:
        return 'widget_tracking';
      case AdGatePlacement.widgetZikir:
        return 'widget_zikir';
      case AdGatePlacement.exploreSwipe:
        return 'explore_swipe';
      case AdGatePlacement.prayerSecondAlarm:
        return 'prayer_second_alarm';
      case AdGatePlacement.zikirSession:
        return 'zikir_session';
      case AdGatePlacement.healingSession:
        return 'healing_session';
      case AdGatePlacement.qiblaSession:
        return 'qibla_session';
    }
  }
}

class AdGateDecision {
  const AdGateDecision({
    required this.allowed,
    required this.requiresRewardedAd,
    this.reason,
  });

  final bool allowed;
  final bool requiresRewardedAd;
  final String? reason;

  static const allowedFree = AdGateDecision(
    allowed: true,
    requiresRewardedAd: false,
  );

  static const needsAd = AdGateDecision(
    allowed: false,
    requiresRewardedAd: true,
  );
}

class WidgetGateState {
  const WidgetGateState({
    required this.allowed,
    required this.inTrial,
    required this.unlockUntil,
    required this.trialUntil,
  });

  final bool allowed;
  final bool inTrial;
  final DateTime? unlockUntil;
  final DateTime? trialUntil;
}

class AdGateService {
  AdGateService(this._prefs);

  final SharedPreferences _prefs;

  static const int exploreSwipeFreeCount = 12;
  static const Duration widgetTrialDuration = Duration(hours: 24);
  static const Duration _legacyWidgetUnlockDuration = Duration(
    hours: GlobalWidgetLockService.legacyUnlockHours,
  );
  static const Duration secondAlarmUnlockDuration = Duration(days: 7);
  static const Duration sessionAdCooldown = Duration(hours: 12);
  static const Duration exploreInterstitialCooldown = Duration(minutes: 6);
  static const String _exploreViewCountKey = 'ad_gate_explore_swipe_view_count';

  AdGateDecision decisionFor(
    AdGatePlacement placement, {
    required bool isPremium,
  }) {
    if (isPremium) return AdGateDecision.allowedFree;
    switch (placement) {
      case AdGatePlacement.lockScreenWidget:
      case AdGatePlacement.widgetQuote:
      case AdGatePlacement.widgetPrayer:
      case AdGatePlacement.widgetCombo:
      case AdGatePlacement.widgetTracking:
      case AdGatePlacement.widgetZikir:
      case AdGatePlacement.prayerSecondAlarm:
        return _isUnlocked(placement)
            ? AdGateDecision.allowedFree
            : AdGateDecision.needsAd;
      case AdGatePlacement.exploreSwipe:
      case AdGatePlacement.zikirSession:
      case AdGatePlacement.healingSession:
      case AdGatePlacement.qiblaSession:
        return _cooldownActive(placement)
            ? AdGateDecision.allowedFree
            : AdGateDecision.needsAd;
    }
  }

  /// Bir widget'ın trial/unlock durumunu döndürür.
  ///
  /// `firstSeen` parametresi, ilgili widget'ın **home ekrana eklendiği**
  /// (yani native provider'ın ilk kez render ettiği) andır. App Group / shared
  /// SharedPreferences'tan native taraf okunarak [WidgetAccessService]
  /// tarafından sağlanır. Null gelirse widget henüz home ekrana eklenmemiş
  /// demektir; bu durumda trial başlatılmaz ve erişime izin verilir — böylece
  /// kullanıcı eklemediği widget'ların trial'ı boşa yanmaz.
  Future<WidgetGateState> widgetStateFor(
    AdGatePlacement placement, {
    required bool isPremium,
    DateTime? firstSeen,
  }) async {
    assert(_isWidgetPlacement(placement));
    await reconcileWidgetUnlockDeadline(placement);
    if (isPremium) {
      return const WidgetGateState(
        allowed: true,
        inTrial: false,
        unlockUntil: null,
        trialUntil: null,
      );
    }
    if (firstSeen == null) {
      // Widget henüz native tarafça render edilmemiş; trial sayacı başlamasın.
      return const WidgetGateState(
        allowed: true,
        inTrial: false,
        unlockUntil: null,
        trialUntil: null,
      );
    }
    final trialUntil = firstSeen.add(widgetTrialDuration);
    final now = DateTime.now();
    final unlock = unlockUntil(placement);
    final inTrial = trialUntil.isAfter(now);
    final unlocked = unlock != null && unlock.isAfter(now);
    return WidgetGateState(
      allowed: inTrial || unlocked,
      inTrial: inTrial,
      unlockUntil: unlock,
      trialUntil: trialUntil,
    );
  }

  Future<void> recordWidgetRewardedUnlock(AdGatePlacement placement) {
    assert(_isWidgetPlacement(placement));
    return recordRewardedUnlock(placement);
  }

  /// Geçerli uzaktan süreyi hâlen aktif olan turun kalıcı bitişine uygular.
  /// Bir kez dolmuş tur değiştirilmez; böylece sonraki süre artışı eski bir
  /// reklam hakkını yeniden canlandıramaz.
  Future<void> reconcileWidgetUnlockDeadline(AdGatePlacement placement) async {
    assert(_isWidgetPlacement(placement));
    final raw = _prefs.getString(_unlockKey(placement));
    final storedUntil = raw == null ? null : DateTime.tryParse(raw);
    if (storedUntil == null || !storedUntil.isAfter(DateTime.now())) return;

    final startedAt = unlockStartedAt(placement);
    if (startedAt == null) return;
    final effectiveUntil = startedAt.add(
      Duration(hours: GlobalWidgetLockService.unlockHours(_prefs)),
    );
    if (effectiveUntil == storedUntil) return;
    await _prefs.setString(
      _unlockKey(placement),
      effectiveUntil.toIso8601String(),
    );
  }

  /// Background FCM isolate'ının native/App Group deposunda kesinleştirdiği
  /// tur başlangıç/bitişlerini foreground SharedPreferences'a taşır.
  Future<void> reconcileWidgetUnlockSnapshot({
    required Map<String, int> startedAtMsByKind,
    required Map<String, int> untilMsByKind,
  }) async {
    for (final entry in const <String, AdGatePlacement>{
      'quote': AdGatePlacement.widgetQuote,
      'prayer': AdGatePlacement.widgetPrayer,
      'combo': AdGatePlacement.widgetCombo,
      'tracking': AdGatePlacement.widgetTracking,
      'zikir': AdGatePlacement.widgetZikir,
    }.entries) {
      final nativeStartedAtMs = startedAtMsByKind[entry.key] ?? 0;
      final nativeUntilMs = untilMsByKind[entry.key] ?? 0;
      if (nativeStartedAtMs <= 0 || nativeUntilMs <= 0) continue;

      final localStartedAt = unlockStartedAt(entry.value);
      final nativeStartedAt = DateTime.fromMillisecondsSinceEpoch(
        nativeStartedAtMs,
      );
      // Foreground'da daha sonra izlenmiş yeni reklam turunu eski background
      // snapshot'ıyla geri alma.
      if (localStartedAt != null &&
          localStartedAt.millisecondsSinceEpoch > nativeStartedAtMs) {
        continue;
      }
      await _prefs.setString(
        _unlockStartedAtKey(entry.value),
        nativeStartedAt.toIso8601String(),
      );
      await _prefs.setString(
        _unlockKey(entry.value),
        DateTime.fromMillisecondsSinceEpoch(nativeUntilMs).toIso8601String(),
      );
    }
  }

  bool shouldShowExploreAd({
    required bool isPremium,
    required int pagesViewedThisSession,
  }) {
    if (isPremium) return false;
    if (isPending(AdGatePlacement.exploreSwipe)) return true;
    if (pagesViewedThisSession <= 0) return false;
    if (pagesViewedThisSession % exploreSwipeFreeCount != 0) return false;
    return !_cooldownActive(AdGatePlacement.exploreSwipe);
  }

  /// Keşfet geçiş reklamı yalnızca kart sayacına bağlıdır — zaman bazlı bir
  /// soğuma (cooldown) YOKTUR. Kullanıcı her [exploreSwipeFreeCount] kartı
  /// kaydırdığında, kaç dakika önce reklam gösterilmiş olursa olsun, tekrar
  /// reklam tetiklenir.
  Future<bool> recordExploreViewAndShouldShowAd({
    required bool isPremium,
  }) async {
    if (isPremium) return false;
    if (isPending(AdGatePlacement.exploreSwipe)) return true;

    final views = (_prefs.getInt(_exploreViewCountKey) ?? 0) + 1;
    await _prefs.setInt(_exploreViewCountKey, views);
    return views >= exploreSwipeFreeCount;
  }

  Future<void> markPending(AdGatePlacement placement) {
    return _prefs.setBool(_pendingKey(placement), true);
  }

  Future<void> clearPending(AdGatePlacement placement) {
    return _prefs.remove(_pendingKey(placement));
  }

  bool isPending(AdGatePlacement placement) {
    return _prefs.getBool(_pendingKey(placement)) ?? false;
  }

  Future<void> recordRewardedUnlock(AdGatePlacement placement) async {
    await clearPending(placement);
    if (placement == AdGatePlacement.exploreSwipe) {
      // Keşfet geçiş reklamı yalnızca kart sayacına bağlıdır; zaman bazlı
      // bir soğuma yazılmaz — aksi halde ölü/karıştırıcı state kalır.
      await _prefs.remove(_exploreViewCountKey);
      return;
    }
    final now = DateTime.now();
    final duration = switch (placement) {
      AdGatePlacement.lockScreenWidget ||
      AdGatePlacement.widgetQuote ||
      AdGatePlacement.widgetPrayer ||
      AdGatePlacement.widgetCombo ||
      AdGatePlacement.widgetTracking ||
      AdGatePlacement.widgetZikir => Duration(
        hours: GlobalWidgetLockService.unlockHours(_prefs),
      ),
      AdGatePlacement.prayerSecondAlarm => secondAlarmUnlockDuration,
      AdGatePlacement.exploreSwipe => exploreInterstitialCooldown,
      AdGatePlacement.zikirSession ||
      AdGatePlacement.healingSession ||
      AdGatePlacement.qiblaSession => sessionAdCooldown,
    };
    if (_isWidgetPlacement(placement)) {
      await _prefs.setString(
        _unlockStartedAtKey(placement),
        now.toIso8601String(),
      );
    }
    await _prefs.setString(
      _unlockKey(placement),
      now.add(duration).toIso8601String(),
    );
  }

  DateTime? unlockUntil(AdGatePlacement placement) {
    final raw = _prefs.getString(_unlockKey(placement));
    final storedUntil = raw == null || raw.isEmpty
        ? null
        : DateTime.tryParse(raw);
    if (!_isWidgetPlacement(placement)) {
      return storedUntil;
    }
    // Süresi daha önce dolmuş bir tur, admin süreyi daha sonra artırdığında
    // yeniden açılmamalı. Yalnızca hâlen aktif turlar yeniden hesaplanır.
    if (storedUntil != null && !storedUntil.isAfter(DateTime.now())) {
      return storedUntil;
    }
    final startedAt = unlockStartedAt(placement);
    if (startedAt == null) return null;
    return startedAt.add(
      Duration(hours: GlobalWidgetLockService.unlockHours(_prefs)),
    );
  }

  DateTime? unlockStartedAt(AdGatePlacement placement) {
    final rawStart = _prefs.getString(_unlockStartedAtKey(placement));
    final parsedStart = rawStart == null ? null : DateTime.tryParse(rawStart);
    if (parsedStart != null) return parsedStart;

    // Eski sürümler yalnızca 24 saatlik bitiş zamanını saklıyordu. İlk uzaktan
    // süre değişiminde mevcut turun başlangıcını bu eski bitişten güvenli biçimde
    // türet; böylece 24 -> N saat değişikliği mevcut kullanıcılara da uygulanır.
    if (!_isWidgetPlacement(placement)) return null;
    final rawUntil = _prefs.getString(_unlockKey(placement));
    final legacyUntil = rawUntil == null ? null : DateTime.tryParse(rawUntil);
    return legacyUntil?.subtract(_legacyWidgetUnlockDuration);
  }

  bool _isUnlocked(AdGatePlacement placement) {
    final until = unlockUntil(placement);
    return until != null && until.isAfter(DateTime.now());
  }

  bool _cooldownActive(AdGatePlacement placement) => _isUnlocked(placement);

  bool _isWidgetPlacement(AdGatePlacement placement) {
    return placement == AdGatePlacement.widgetQuote ||
        placement == AdGatePlacement.widgetPrayer ||
        placement == AdGatePlacement.widgetCombo ||
        placement == AdGatePlacement.widgetTracking ||
        placement == AdGatePlacement.widgetZikir ||
        placement == AdGatePlacement.lockScreenWidget;
  }

  String _unlockKey(AdGatePlacement placement) =>
      'ad_gate_${placement.key}_unlock_until';

  String _unlockStartedAtKey(AdGatePlacement placement) =>
      'ad_gate_${placement.key}_unlock_started_at';

  String _pendingKey(AdGatePlacement placement) =>
      'ad_gate_${placement.key}_pending';
}
