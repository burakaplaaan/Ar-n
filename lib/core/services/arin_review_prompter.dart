// lib/core/services/arin_review_prompter.dart
// Play Store / App Store değerlendirme penceresini **doğru anda** açar.
//
// Native API (InAppReview) uygulamanın içinde küçük bir review sheet açar;
// kullanıcı uygulamadan çıkmadan yıldız verir. Android: Play App Signing'den
// gelen sürümlerde çalışır, debug/side-load'da sessizce no-op olur. iOS:
// SKStoreReviewController — sistem 365 günde 3 kez limitliyor; kod sorun
// değil, OS cap'i.
//
// Kural: review'u sadece POZİTİF bir anda iste. Arın'da en pozitif anlar:
//   - 3. zikir turu tamamlandığında (seri + başarı duygusu)
//   - İlk Arınma milestone'unda (sevinç anı)
// Ayrıca aynı cihazda 45 günden erken tekrar sorma, user reddedip "bir daha
// sormayın" dediyse kapat.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class ArinReviewPrompter {
  static const _prefsLastAskedMs = 'review_last_asked_ms';
  static const _prefsAskDisabled = 'review_disabled_forever';
  static const _prefsLaunchCount = 'review_launch_count';
  static const _prefsLastCountedLaunchMs = 'review_last_counted_launch_ms';
  static const _prefsFirstLaunchMs = 'review_first_launch_ms';

  static const _minIntervalBetweenAsks = Duration(days: 45);
  static const _minSinceFirstLaunch = Duration(days: 2);
  static const _minBetweenLaunchCounts = Duration(hours: 6);
  static const _launchCountThreshold = 5;

  /// Uygulamanın ilk açılışında çağrılmalı (main.dart). İlk-launch timestamp'i
  /// yazar (yalnız ilk kez); kullanıcıyı daha açılışın 1. gününde bombalamamak
  /// için 2 gün kural kapısı uygular. Ayrıca toplam açılış sayacını artırır —
  /// 5. açılışta değerlendirme sheet'ini tetikler.
  ///
  /// 6-saat throttle: Aynı kullanıcının bir günde uygulamayı 5 kez açması sayacı
  /// dakikalar içinde 5'e çıkarırdı → review sheet spam olurdu. Sayaç yalnız
  /// önceki artırmadan 6 saat sonra yeniden artar — böylece 5 artış ≈ 5 farklı
  /// kullanım oturumu (gerçekten "aktif kullanıcı" sinyali).
  static Future<void> markAppLaunched(SharedPreferences prefs) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // İlk launch timestamp yalnızca ilk kez yazılır.
    if (prefs.getInt(_prefsFirstLaunchMs) == null) {
      await prefs.setInt(_prefsFirstLaunchMs, nowMs);
    }

    // Son sayılan launch'tan en az 6 saat geçtiyse sayacı artır.
    final lastCountedMs = prefs.getInt(_prefsLastCountedLaunchMs);
    final shouldIncrement = lastCountedMs == null ||
        (nowMs - lastCountedMs) >= _minBetweenLaunchCounts.inMilliseconds;

    int count = prefs.getInt(_prefsLaunchCount) ?? 0;
    if (shouldIncrement) {
      count = count + 1;
      await prefs.setInt(_prefsLaunchCount, count);
      await prefs.setInt(_prefsLastCountedLaunchMs, nowMs);
    }

    // 5. açılıştan itibaren yeterli — daha fazla bekletmenin ikna
    // gücüne katkısı yok, yıldız şansı azalır. Sonraki kontroller
    // `_canAsk` tarafından yapılır: 45 gün cooldown, ilk 2 gün sessiz.
    if (count >= _launchCountThreshold) {
      // Pencereyi _hemen_ açmak yerine kısa bir gecikme: uygulama
      // tamamen açılıp ana ekran render edildikten sonra sheet belirsin,
      // splash üstüne binmesin.
      Future.delayed(const Duration(seconds: 4), () {
        unawaited(_maybeAskAfterLaunchCount(prefs));
      });
    }
  }

  static Future<void> _maybeAskAfterLaunchCount(
    SharedPreferences prefs,
  ) async {
    try {
      if (!await _canAsk(prefs)) return;
      await _askNow(prefs);
    } catch (e) {
      debugPrint('ArinReviewPrompter launch-count: $e');
    }
  }

  /// Kullanıcı ayarlardan "değerlendirmeyi kapat" dediyse.
  static Future<void> disableForever(SharedPreferences prefs) async {
    await prefs.setBool(_prefsAskDisabled, true);
  }

  static Future<bool> _canAsk(SharedPreferences prefs) async {
    if (prefs.getBool(_prefsAskDisabled) == true) return false;

    final firstLaunch = prefs.getInt(_prefsFirstLaunchMs);
    if (firstLaunch != null) {
      final since = DateTime.now().millisecondsSinceEpoch - firstLaunch;
      if (since < _minSinceFirstLaunch.inMilliseconds) return false;
    }

    final lastAsked = prefs.getInt(_prefsLastAskedMs);
    if (lastAsked != null) {
      final since = DateTime.now().millisecondsSinceEpoch - lastAsked;
      if (since < _minIntervalBetweenAsks.inMilliseconds) return false;
    }

    if (!await InAppReview.instance.isAvailable()) return false;
    return true;
  }

  static Future<void> _askNow(SharedPreferences prefs) async {
    await prefs.setInt(
      _prefsLastAskedMs,
      DateTime.now().millisecondsSinceEpoch,
    );
    await InAppReview.instance.requestReview();
    debugPrint('══ ARIN ══ In-app review requested.');
  }
}
