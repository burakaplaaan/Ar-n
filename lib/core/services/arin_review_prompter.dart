// lib/core/services/arin_review_prompter.dart
// Play Store / App Store değerlendirme penceresini **doğru anda** açar.
//
// Native API (InAppReview) uygulamanın içinde küçük bir review sheet açar;
// kullanıcı uygulamadan çıkmadan yıldız verir. Android: Play App Signing'den
// gelen sürümlerde çalışır, debug/side-load'da sessizce no-op olur. iOS:
// SKStoreReviewController — sistem 365 günde 3 kez limitliyor; kod sorun
// değil, OS cap'i.
//
// Tetikleyiciler:
//  1) Açılış: en az 1 gün ve 2 ayrı oturum (bkz. `markAppLaunched`).
//  2) Özellik çıkışı: zikir / frekans / keşfet / kıble / namaz ekranında
//     6 sn+ kalınca (bkz. `maybeAskAfterFeatureUse`).
//  3) Olumlu an: namaz işareti veya Keşfet paylaşımı
//     (bkz. `maybeAskAfterPositiveMoment`).
//
// Ortak sınır: günde en fazla 1 kez; toplam `_maxTotalAsks` sonrası susulur.
// Store API'si kullanıcının gerçekten puan verip vermediğini gizlilik
// nedeniyle bildirmez; bu yüzden "sonuçtan bağımsız say" güvenli sınırdır.

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
  static const _prefsTotalAskCount = 'review_total_ask_count';
  static const _prefsLastAskDayEpoch = 'review_last_ask_day_epoch';

  static const _minSinceFirstLaunch = Duration(days: 1);
  static const _minBetweenLaunchCounts = Duration(hours: 3);
  static const _launchCountThreshold = 2;

  /// Toplamda kaç kez sorulabileceğinin üst sınırı. Aşıldığında kalıcı
  /// olarak susulur — mağaza politikalarıyla uyumlu, spam olmaz.
  static const _maxTotalAsks = 8;

  /// Bir özellik ekranında bu süre kadar kalınmadıysa (ör. yanlışlıkla
  /// girip hemen çıkma) o çıkış review isteği tetiklemez.
  static const minFeatureUseDuration = Duration(seconds: 6);

  @visibleForTesting
  static Duration get minSinceFirstLaunch => _minSinceFirstLaunch;

  @visibleForTesting
  static int get launchCountThreshold => _launchCountThreshold;

  @visibleForTesting
  static int get maxTotalAsks => _maxTotalAsks;

  static bool _askInFlight = false;

  /// Uygulamanın ilk açılışında çağrılmalı (main.dart). İlk-launch timestamp'i
  /// yazar (yalnız ilk kez); kullanıcıyı daha açılışın 1. gününde bombalamamak
  /// için 2 gün kural kapısı uygular. Ayrıca toplam açılış sayacını artırır —
  /// 3. sayılan açılışta değerlendirme sheet'ini tetikler.
  ///
  /// 3-saat throttle: art arda açılışlar sayacı şişirmesin. 2. sayılan
  /// oturumda sheet açılabilir; ilk gün açılış yolu sessiz kalır.
  static Future<void> markAppLaunched(SharedPreferences prefs) async {
    await _migrateLegacyAskFlag(prefs);
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

    // 2. sayılan açılıştan itibaren yeterli. `_canAsk` ilk günü bekler.
    if (count >= _launchCountThreshold) {
      // Pencereyi _hemen_ açmak yerine kısa bir gecikme: uygulama
      // tamamen açılıp ana ekran render edildikten sonra sheet belirsin,
      // splash üstüne binmesin.
      Future.delayed(const Duration(seconds: 4), () {
        unawaited(_maybeAsk(prefs, requireMinDaysSinceFirstLaunch: true));
      });
    }
  }

  /// Bir özellik ekranından (zikirmatik, frekans, keşfet, kıble bulucu,
  /// gelişim) çıkarken çağrılmalı. `usedFor`, kullanıcının o ekranda
  /// geçirdiği süredir; `minFeatureUseDuration`'ın altındaysa hiçbir şey
  /// yapmaz (yanlışlıkla girip çıkanları eler).
  ///
  /// Günlük ve toplam sınırlar `markAppLaunched` ile ortaktır: bu yol da
  /// aynı "günde 1 kez / toplam N kez" kotasını paylaşır.
  static Future<void> maybeAskAfterFeatureUse(
    SharedPreferences prefs, {
    required Duration usedFor,
  }) async {
    if (usedFor < minFeatureUseDuration) return;
    await _maybeAsk(prefs, requireMinDaysSinceFirstLaunch: false);
  }

  /// Namaz işareti veya paylaşım gibi kısa olumlu andan sonra sorar.
  /// İlk gün beklenmez; günlük / toplam kota aynıdır.
  static Future<void> maybeAskAfterPositiveMoment(
    SharedPreferences prefs,
  ) async {
    await _maybeAsk(prefs, requireMinDaysSinceFirstLaunch: false);
  }

  static Future<void> _maybeAsk(
    SharedPreferences prefs, {
    required bool requireMinDaysSinceFirstLaunch,
  }) async {
    // Aynı process içinde üst üste planlanan/eş zamanlı çağrıların ikisinin
    // de kontrolleri geçip iki native istek başlatmasını engelle.
    if (_askInFlight) return;
    _askInFlight = true;
    try {
      if (!await _canAsk(
        prefs,
        requireMinDaysSinceFirstLaunch: requireMinDaysSinceFirstLaunch,
      )) {
        return;
      }
      await _askNow(prefs);
    } catch (e) {
      debugPrint('ArinReviewPrompter: $e');
    } finally {
      _askInFlight = false;
    }
  }

  /// Kullanıcı ayarlardan "değerlendirmeyi kapat" dediyse.
  static Future<void> disableForever(SharedPreferences prefs) async {
    await prefs.setBool(_prefsAskDisabled, true);
  }

  /// Önceki sürüm review isteğini `_prefsLegacyLastAskedMs` ile kaydediyordu
  /// ve bir daha hiç sormuyordu. Bu, o kullanıcıların en az bir kez soru
  /// gördüğü anlamına gelir; kalıcı susturmak yerine bunu toplam sayaca
  /// "1" olarak yansıtıp yeni kotaya (toplam `_maxTotalAsks`) tabi tutar.
  static Future<void> _migrateLegacyAskFlag(SharedPreferences prefs) async {
    if (prefs.getInt(_prefsLegacyLastAskedMs) == null) return;
    final currentTotal = prefs.getInt(_prefsTotalAskCount) ?? 0;
    if (currentTotal < 1) {
      await prefs.setInt(_prefsTotalAskCount, 1);
    }
    await prefs.remove(_prefsLegacyLastAskedMs);
  }

  static int _dayEpoch(DateTime time) =>
      DateTime.utc(time.year, time.month, time.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  static Future<bool> _canAsk(
    SharedPreferences prefs, {
    required bool requireMinDaysSinceFirstLaunch,
  }) async {
    if (prefs.getBool(_prefsAskDisabled) == true) return false;

    final totalAsks = prefs.getInt(_prefsTotalAskCount) ?? 0;
    if (totalAsks >= _maxTotalAsks) {
      // Kota bitti; native isteği hiç denemeden kalıcı kapat.
      await prefs.setBool(_prefsAskDisabled, true);
      return false;
    }

    final todayEpoch = _dayEpoch(DateTime.now());
    if (prefs.getInt(_prefsLastAskDayEpoch) == todayEpoch) return false;

    if (requireMinDaysSinceFirstLaunch) {
      final firstLaunch = prefs.getInt(_prefsFirstLaunchMs);
      if (firstLaunch != null) {
        final since = DateTime.now().millisecondsSinceEpoch - firstLaunch;
        if (since < _minSinceFirstLaunch.inMilliseconds) return false;
      }
    }

    if (!await InAppReview.instance.isAvailable()) return false;
    return true;
  }

  static Future<void> _askNow(SharedPreferences prefs) async {
    await InAppReview.instance.requestReview();
    final totalAsks = (prefs.getInt(_prefsTotalAskCount) ?? 0) + 1;
    await prefs.setInt(_prefsTotalAskCount, totalAsks);
    await prefs.setInt(_prefsLastAskDayEpoch, _dayEpoch(DateTime.now()));
    if (totalAsks >= _maxTotalAsks) {
      await prefs.setBool(_prefsAskDisabled, true);
    }
    debugPrint(
      '══ ARIN ══ In-app review requested (total: $totalAsks/$_maxTotalAsks).',
    );
  }
}
