// lib/core/services/arin_review_prompter.dart
// Play Store / App Store değerlendirme penceresini **doğru anda** açar.
//
// Native API (InAppReview) uygulamanın içinde küçük bir review sheet açar;
// kullanıcı uygulamadan çıkmadan yıldız verir. Android: Play App Signing'den
// gelen sürümlerde çalışır, debug/side-load'da sessizce no-op olur. iOS:
// SKStoreReviewController — sistem 365 günde 3 kez limitliyor; kod sorun
// değil, OS cap'i.
//
// Kullanıcıyı ilk gününde bölmemek için en az 2 gün ve 3 ayrı kullanım
// oturumu beklenir. Native pencere bir kez istendikten sonra aynı kurulumda
// tekrar istenmez. Store API'si kullanıcının gerçekten puan verip vermediğini
// gizlilik nedeniyle bildirmez; bu yüzden güvenilir sınır "bir kez iste"dir.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class ArinReviewPrompter {
  static const _prefsLegacyLastAskedMs = 'review_last_asked_ms';
  static const _prefsAskDisabled = 'review_disabled_forever';
  static const _prefsLaunchCount = 'review_launch_count';
  static const _prefsLastCountedLaunchMs = 'review_last_counted_launch_ms';
  static const _prefsFirstLaunchMs = 'review_first_launch_ms';

  static const _minSinceFirstLaunch = Duration(days: 2);
  static const _minBetweenLaunchCounts = Duration(hours: 6);
  static const _launchCountThreshold = 3;

  static bool _askInFlight = false;

  /// Uygulamanın ilk açılışında çağrılmalı (main.dart). İlk-launch timestamp'i
  /// yazar (yalnız ilk kez); kullanıcıyı daha açılışın 1. gününde bombalamamak
  /// için 2 gün kural kapısı uygular. Ayrıca toplam açılış sayacını artırır —
  /// 3. sayılan açılışta değerlendirme sheet'ini tetikler.
  ///
  /// 6-saat throttle: Aynı kullanıcının uygulamayı art arda açması sayacı
  /// dakikalar içinde 3'e çıkarırdı. Sayaç yalnız önceki artırmadan 6 saat
  /// sonra yeniden artar — böylece 3 artış ≈ 3 farklı
  /// kullanım oturumu (gerçekten "aktif kullanıcı" sinyali).
  static Future<void> markAppLaunched(SharedPreferences prefs) async {
    // Önceki sürüm review isteğini bu timestamp ile kaydediyordu. Güncelleme
    // sonrasında o kullanıcılara yeniden sormamak için kalıcı bayrağa taşı.
    if (prefs.getInt(_prefsLegacyLastAskedMs) != null) {
      await prefs.setBool(_prefsAskDisabled, true);
    }
    if (prefs.getBool(_prefsAskDisabled) == true) return;

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

    // 3. sayılan açılıştan itibaren yeterli. Sonraki kontroller
    // `_canAsk` tarafından yapılır: ilk 2 gün sessiz ve yalnızca bir kez sor.
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
    // Aynı process içinde üst üste planlanan callback'lerin ikisinin de
    // `_canAsk` kontrolünü geçip iki native istek başlatmasını engelle.
    if (_askInFlight) return;
    _askInFlight = true;
    try {
      if (!await _canAsk(prefs)) return;
      await _askNow(prefs);
    } catch (e) {
      debugPrint('ArinReviewPrompter launch-count: $e');
    } finally {
      _askInFlight = false;
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

    if (!await InAppReview.instance.isAvailable()) return false;
    return true;
  }

  static Future<void> _askNow(SharedPreferences prefs) async {
    await InAppReview.instance.requestReview();
    // Native API çağrısı başarıyla kabul edildi. API gerçek puanlama sonucunu
    // açıklamadığı için bu kurulumda yeniden istememek üzere kalıcı kapat.
    await prefs.setBool(_prefsAskDisabled, true);
    debugPrint('══ ARIN ══ In-app review requested.');
  }
}
