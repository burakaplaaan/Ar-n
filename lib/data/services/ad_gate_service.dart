import 'package:shared_preferences/shared_preferences.dart';

enum AdGatePlacement {
  lockScreenWidget,
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

class AdGateService {
  AdGateService(this._prefs);

  final SharedPreferences _prefs;

  static const int exploreSwipeFreeCount = 5;
  static const Duration widgetUnlockDuration = Duration(hours: 24);
  static const Duration secondAlarmUnlockDuration = Duration(days: 7);
  static const Duration sessionAdCooldown = Duration(hours: 12);
  static const Duration exploreInterstitialCooldown = Duration(minutes: 6);

  AdGateDecision decisionFor(
    AdGatePlacement placement, {
    required bool isPremium,
  }) {
    if (isPremium) return AdGateDecision.allowedFree;
    switch (placement) {
      case AdGatePlacement.lockScreenWidget:
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
    final now = DateTime.now();
    final duration = switch (placement) {
      AdGatePlacement.lockScreenWidget => widgetUnlockDuration,
      AdGatePlacement.prayerSecondAlarm => secondAlarmUnlockDuration,
      AdGatePlacement.exploreSwipe => exploreInterstitialCooldown,
      AdGatePlacement.zikirSession ||
      AdGatePlacement.healingSession ||
      AdGatePlacement.qiblaSession =>
        sessionAdCooldown,
    };
    await clearPending(placement);
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

  String _unlockKey(AdGatePlacement placement) =>
      'ad_gate_${placement.key}_unlock_until';

  String _pendingKey(AdGatePlacement placement) =>
      'ad_gate_${placement.key}_pending';
}
