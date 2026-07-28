import 'package:shared_preferences/shared_preferences.dart';

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
  static const Duration widgetUnlockDuration = Duration(hours: 24);
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
      AdGatePlacement.widgetZikir => widgetUnlockDuration,
      AdGatePlacement.prayerSecondAlarm => secondAlarmUnlockDuration,
      AdGatePlacement.exploreSwipe => exploreInterstitialCooldown,
      AdGatePlacement.zikirSession ||
      AdGatePlacement.healingSession ||
      AdGatePlacement.qiblaSession => sessionAdCooldown,
    };
    await _prefs.setString(
      _unlockKey(placement),
      now.add(duration).toIso8601String(),
    );
  }

  DateTime? unlockUntil(AdGatePlacement placement) {
    final raw = _prefs.getString(_unlockKey(placement));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
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

  String _pendingKey(AdGatePlacement placement) =>
      'ad_gate_${placement.key}_pending';
}
