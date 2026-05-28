// home_widget: Android/iOS ortak anahtarlar ve provider güncellemesi.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/prayer_times_model.dart';
import 'location_service.dart';
import 'prayer_widget_snapshot.dart';

abstract final class ArinWidgetKeys {
  static const quoteText = 'arin_quote_text';
  static const quoteSource = 'arin_quote_source';
  static const quoteScheduleJson = 'arin_quote_schedule_json';
  static const localeCode = 'arin_widget_locale';

  static const prayerLocation = 'arin_prayer_location';
  static const prayerNextName = 'arin_prayer_next_name';
  static const prayerCountdown = 'arin_prayer_countdown';
  static const prayerNextEpochMs = 'arin_prayer_next_epoch_ms';
  static const prayerScheduleJson = 'arin_prayer_schedule_json';

  static const trackingEnabled = 'arin_tracking_enabled';
  static const trackingTitle = 'arin_tracking_title';
  static const trackingValue = 'arin_tracking_value';
  static const trackingNote = 'arin_tracking_note';
  static const trackingQuotesJson = 'arin_tracking_quotes_json';
  static const trackingMode = 'arin_tracking_mode';
  static const trackingStartEpochMs = 'arin_tracking_start_epoch_ms';
  static const trackingDayPrefix = 'arin_tracking_day_prefix';

  static const widgetGateQuoteLocked = 'arin_widget_gate_quote_locked';
  static const widgetGatePrayerLocked = 'arin_widget_gate_prayer_locked';
  static const widgetGateComboLocked = 'arin_widget_gate_combo_locked';
  static const widgetGateTrackingLocked = 'arin_widget_gate_tracking_locked';
  static const widgetGatePremium = 'arin_widget_gate_premium';
  static const widgetGateLockNote = 'arin_widget_gate_lock_note';
}

abstract final class ArinWidgetSync {
  static const _forcedWidgetLocale = 'tr';
  static final RegExp _arabicChars = RegExp(r'[\u0600-\u06FF]');
  static Future<bool>? _appGroupFuture;
  static bool _appGroupReady = false;

  /// Uygulama açılışında (deferred startup) bir kez çağrılır. AppGroup
  /// hazırlığı paralelde başlasın ki widget yazımı sırasında bekletme
  /// olmasın.
  static void primeAppGroup() {
    if (kIsWeb || !Platform.isIOS) return;
    unawaited(_ensureAppGroupReady());
  }

  /// Dışarıdan `HomeWidget.updateWidget` çağıracak başka yerler (hesap sil
  /// sonrası widget purge gibi) kullansın diye public sabitler.
  static const androidQuoteProviderClass =
      'com.arin.arin.ArinQuoteWidgetProvider';
  static const androidPrayerProviderClass =
      'com.arin.arin.ArinPrayerWidgetProvider';
  static const androidComboProviderClass =
      'com.arin.arin.ArinComboWidgetProvider';
  static const androidTrackingProviderClass =
      'com.arin.arin.ArinTrackingWidgetProvider';
  static const iOSQuoteWidgetName = 'ArinQuoteWidget';
  static const iOSPrayerWidgetName = 'ArinPrayerWidget';
  static const iOSComboWidgetName = 'ArinComboWidget';
  static const iOSTrackingWidgetName = 'ArinTrackingWidget';

  static const _androidQuote = androidQuoteProviderClass;
  static const _androidPrayer = androidPrayerProviderClass;
  static const _androidCombo = androidComboProviderClass;
  static const _androidTracking = androidTrackingProviderClass;

  static String _widgetQuotePreferredLineBreaks(String t) => t;

  /// Söz widget verisi + yalnızca söz provider güncellemesi.
  static Future<void> pushQuote({
    required String text,
    required String source,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      var t = _widgetQuotePreferredLineBreaks(text.trim());
      final s = source;
      await HomeWidget.saveWidgetData<String>(ArinWidgetKeys.quoteText, t);
      await HomeWidget.saveWidgetData<String>(ArinWidgetKeys.quoteSource, s);
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.localeCode,
        _forcedWidgetLocale,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQuote,
        iOSName: 'ArinQuoteWidget',
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushQuote: $e\n$st');
    }
  }

  /// Admin override: mevcut zaman çizelgesini geçici olarak devre dışı bırakır
  /// ve widget'a tek bir mesaj basar. Override kapanınca havuz schedule'ı tekrar
  /// yazılmalıdır.
  static Future<void> pushQuoteOverride({
    required String text,
    required String source,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.quoteScheduleJson,
        '',
      );
      await pushQuote(text: text, source: source, localeCode: localeCode);
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushQuoteOverride: $e\n$st');
    }
  }

  /// Söz widget'ı için 3 günlük yerel zaman çizelgesi. Native widget bu JSON'u
  /// okuyup uygulama açılmadan slot değişimlerinde kendini günceller.
  static Future<void> pushQuoteSchedule({
    required List<({DateTime startsAt, String text, String source})> entries,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb || entries.isEmpty) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      final sorted = entries.toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      final now = DateTime.now();
      final current = _currentQuoteEntry(sorted, now) ?? sorted.first;
      final schedule = <String, Object?>{
        'version': 1,
        'generatedAtEpochMs': now.millisecondsSinceEpoch,
        'entries': sorted
            .map(
              (e) => <String, Object?>{
                'epochMs': e.startsAt.millisecondsSinceEpoch,
                'text': _widgetQuotePreferredLineBreaks(e.text.trim()),
                'source': e.source.trim(),
              },
            )
            .toList(growable: false),
      };

      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.quoteScheduleJson,
        jsonEncode(schedule),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.quoteText,
        _widgetQuotePreferredLineBreaks(current.text.trim()),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.quoteSource,
        current.source.trim(),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.localeCode,
        _forcedWidgetLocale,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQuote,
        iOSName: iOSQuoteWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushQuoteSchedule: $e\n$st');
    }
  }

  /// Gelişim/Arınma takip widget'ı: tek seçili takip, kısa sayaç ve motivasyon.
  static Future<void> pushTracking({
    required String title,
    required String value,
    required String note,
    required String quotesJson,
    String mode = 'static',
    int? startEpochMs,
    String dayPrefix = '',
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingEnabled,
        '1',
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingTitle,
        title.trim(),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingValue,
        value.trim(),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingNote,
        note.trim(),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingQuotesJson,
        quotesJson,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingMode,
        mode,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingStartEpochMs,
        startEpochMs == null ? '' : '$startEpochMs',
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.trackingDayPrefix,
        dayPrefix.trim(),
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidTracking,
        iOSName: iOSTrackingWidgetName,
      );
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushTracking: $e\n$st');
    }
  }

  static Future<void> clearTracking() async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      for (final k in const <String>[
        ArinWidgetKeys.trackingEnabled,
        ArinWidgetKeys.trackingTitle,
        ArinWidgetKeys.trackingValue,
        ArinWidgetKeys.trackingNote,
        ArinWidgetKeys.trackingQuotesJson,
        ArinWidgetKeys.trackingMode,
        ArinWidgetKeys.trackingStartEpochMs,
        ArinWidgetKeys.trackingDayPrefix,
      ]) {
        await HomeWidget.saveWidgetData<String>(k, '');
      }
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidTracking,
        iOSName: iOSTrackingWidgetName,
      );
    } catch (e, st) {
      debugPrint('ArinWidgetSync.clearTracking: $e\n$st');
    }
  }

  static Future<void> pushWidgetGateStates({
    required Map<String, bool> lockedByKind,
    required Map<String, DateTime?> trialUntilByKind,
    required Map<String, DateTime?> unlockUntilByKind,
    required bool isPremium,
    String lockNote = '',
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      Future<void> save(String key, String kind) {
        return HomeWidget.saveWidgetData<String>(
          key,
          lockedByKind[kind] == true ? '1' : '0',
        );
      }

      await save(ArinWidgetKeys.widgetGateQuoteLocked, 'quote');
      await save(ArinWidgetKeys.widgetGatePrayerLocked, 'prayer');
      await save(ArinWidgetKeys.widgetGateComboLocked, 'combo');
      await save(ArinWidgetKeys.widgetGateTrackingLocked, 'tracking');
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.widgetGatePremium,
        isPremium ? '1' : '0',
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.widgetGateLockNote,
        lockNote,
      );
      for (final kind in const <String>[
        'quote',
        'prayer',
        'combo',
        'tracking',
      ]) {
        await HomeWidget.saveWidgetData<String>(
          'arin_widget_gate_${kind}_trial_until_ms',
          '${trialUntilByKind[kind]?.millisecondsSinceEpoch ?? 0}',
        );
        await HomeWidget.saveWidgetData<String>(
          'arin_widget_gate_${kind}_unlock_until_ms',
          '${unlockUntilByKind[kind]?.millisecondsSinceEpoch ?? 0}',
        );
      }
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQuote,
        iOSName: iOSQuoteWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidPrayer,
        iOSName: iOSPrayerWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidTracking,
        iOSName: iOSTrackingWidgetName,
      );
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushWidgetGateStates: $e\n$st');
    }
  }

  static ({DateTime startsAt, String text, String source})? _currentQuoteEntry(
    List<({DateTime startsAt, String text, String source})> entries,
    DateTime now,
  ) {
    ({DateTime startsAt, String text, String source})? current;
    for (final e in entries) {
      if (e.startsAt.isAfter(now)) break;
      current = e;
    }
    return current;
  }

  static Future<void> refreshPrayer({
    required PrayerTimesModel model,
    required LocationService location,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      final now = DateTime.now();
      final loc = formatWidgetLocationLabel(
        location.savedCity,
        location.savedCountry,
        localeCode: _forcedWidgetLocale,
      );
      final safeLocationLine = _widgetSafeLocationLine(
        primary: loc,
        fallback: model.city,
      );
      final snap = PrayerWidgetSnapshot.fromModel(
        model: model,
        now: now,
        locationLine: safeLocationLine,
        localeCode: _forcedWidgetLocale,
      );

      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerLocation,
        snap.locationLine,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerScheduleJson,
        '',
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.localeCode,
        _forcedWidgetLocale,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerNextName,
        snap.nextName,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerCountdown,
        snap.countdownLabel,
      );

      final nextEpoch = now.add(snap.remaining).millisecondsSinceEpoch;
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerNextEpochMs,
        '$nextEpoch',
      );

      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidPrayer,
        iOSName: 'ArinPrayerWidget',
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
    } catch (e, st) {
      debugPrint('ArinWidgetSync.refreshPrayer: $e\n$st');
    }
  }

  /// Namaz widget'ı için çok günlük yerel plan. Uygulama kapalıyken native
  /// taraf sıradaki vakti bu listeden seçer; şehir değişiminde bu plan ezilir.
  static Future<void> refreshPrayerSchedule({
    required List<PrayerTimesModel> models,
    required LocationService location,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb || models.isEmpty) return;
    try {
      if (!await _ensureAppGroupReady()) return;
      final now = DateTime.now();
      final loc = formatWidgetLocationLabel(
        location.savedCity,
        location.savedCountry,
        localeCode: _forcedWidgetLocale,
      );
      final safeLocationLine = _widgetSafeLocationLine(
        primary: loc,
        fallback: models.first.city,
      );
      final events = _prayerScheduleEvents(models);
      if (events.isEmpty) {
        await refreshPrayer(
          model: models.first,
          location: location,
          localeCode: localeCode,
        );
        return;
      }

      final next = events.firstWhere(
        (e) => e.at.isAfter(now),
        orElse: () => events.last,
      );
      final remaining = next.at.difference(now);
      final schedule = <String, Object?>{
        'version': 1,
        'generatedAtEpochMs': now.millisecondsSinceEpoch,
        'location': safeLocationLine,
        'city': location.savedCity,
        'country': location.savedCountry,
        'entries': events
            .map(
              (e) => <String, Object?>{
                'epochMs': e.at.millisecondsSinceEpoch,
                'name': e.name,
              },
            )
            .toList(growable: false),
      };

      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerScheduleJson,
        jsonEncode(schedule),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerLocation,
        safeLocationLine,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.localeCode,
        _forcedWidgetLocale,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerNextName,
        next.name,
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerCountdown,
        _formatHms(remaining.isNegative ? Duration.zero : remaining),
      );
      await HomeWidget.saveWidgetData<String>(
        ArinWidgetKeys.prayerNextEpochMs,
        '${next.at.millisecondsSinceEpoch}',
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidPrayer,
        iOSName: iOSPrayerWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
    } catch (e, st) {
      debugPrint('ArinWidgetSync.refreshPrayerSchedule: $e\n$st');
    }
  }

  static List<({String name, DateTime at})> _prayerScheduleEvents(
    List<PrayerTimesModel> models,
  ) {
    final out = <({String name, DateTime at})>[];
    for (final model in models) {
      final day = _parseIsoDate(model.date);
      if (day == null) continue;
      void add(String name, String hhmm) {
        final at = _at(day, hhmm);
        if (at != null) out.add((name: name, at: at));
      }

      add('İmsak', model.fajr);
      // Güneşe kadar kullanıcı hâlâ sabah namazı penceresinde olsun.
      add('İmsak', model.sunrise);
      add('Öğle', model.dhuhr);
      add('İkindi', model.asr);
      add('Akşam', model.maghrib);
      add('Yatsı', model.isha);
    }
    final last = models.isEmpty ? null : models.last;
    final lastDay = last == null ? null : _parseIsoDate(last.date);
    if (last != null && lastDay != null) {
      final nextFajr = _at(lastDay.add(const Duration(days: 1)), last.fajr);
      if (nextFajr != null) out.add((name: 'İmsak', at: nextFajr));
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  static DateTime? _parseIsoDate(String ymd) {
    final p = ymd.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static DateTime? _at(DateTime day, String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  static String _formatHms(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String _widgetSafeLocationLine({
    required String primary,
    required String fallback,
  }) {
    final first = primary.trim();
    if (first.isNotEmpty && !_arabicChars.hasMatch(first)) return first;
    final second = fallback.trim();
    if (second.isNotEmpty && !_arabicChars.hasMatch(second)) return second;
    return '';
  }

  /// Hesap silme / çıkış akışında widget verilerini sıfırlar. home_widget
  /// plugin'i Android'de widget provider başına ayrı bir SharedPreferences
  /// deposu, iOS'ta ise App Group UserDefaults suite'i kullanır — bu yüzden
  /// Flutter tarafındaki [SharedPreferences.clear] bu verileri silmez.
  /// Tüm bilinen anahtarlara boş değer yazıp widget provider'lara refresh
  /// sinyali gönderiyoruz; widget layout'ları "kurulum bekliyor" görünümüne
  /// güvenle düşsün.
  static Future<void> clearAll() async {
    if (kIsWeb) return;
    try {
      // clearAll oturum kapanışı / hesap silme akışından geliyor; burada
      // bir kerelik bekleyebiliriz çünkü ana açılış path'inde değil.
      if (!await _ensureAppGroupReady()) return;
      for (final k in const <String>[
        ArinWidgetKeys.quoteText,
        ArinWidgetKeys.quoteSource,
        ArinWidgetKeys.quoteScheduleJson,
        ArinWidgetKeys.localeCode,
        ArinWidgetKeys.prayerLocation,
        ArinWidgetKeys.prayerNextName,
        ArinWidgetKeys.prayerCountdown,
        ArinWidgetKeys.prayerNextEpochMs,
        ArinWidgetKeys.prayerScheduleJson,
        ArinWidgetKeys.trackingEnabled,
        ArinWidgetKeys.trackingTitle,
        ArinWidgetKeys.trackingValue,
        ArinWidgetKeys.trackingNote,
        ArinWidgetKeys.trackingQuotesJson,
        ArinWidgetKeys.trackingMode,
        ArinWidgetKeys.trackingStartEpochMs,
        ArinWidgetKeys.trackingDayPrefix,
        ArinWidgetKeys.widgetGateQuoteLocked,
        ArinWidgetKeys.widgetGatePrayerLocked,
        ArinWidgetKeys.widgetGateComboLocked,
        ArinWidgetKeys.widgetGateTrackingLocked,
        ArinWidgetKeys.widgetGatePremium,
        ArinWidgetKeys.widgetGateLockNote,
      ]) {
        await HomeWidget.saveWidgetData<String>(k, '');
      }
      for (final kind in const ['quote', 'prayer', 'combo', 'tracking']) {
        await HomeWidget.saveWidgetData<String>('arin_widget_first_use_ms_$kind', '');
        await HomeWidget.saveWidgetData<String>('arin_widget_gate_${kind}_trial_until_ms', '');
        await HomeWidget.saveWidgetData<String>('arin_widget_gate_${kind}_unlock_until_ms', '');
      }
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQuote,
        iOSName: iOSQuoteWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidPrayer,
        iOSName: iOSPrayerWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidCombo,
        iOSName: iOSComboWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidTracking,
        iOSName: iOSTrackingWidgetName,
      );
    } catch (e, st) {
      debugPrint('ArinWidgetSync.clearAll: $e\n$st');
    }
  }

  /// Senkron, bekleme yapmayan kontrol: AppGroup hazırsa true döner ve
  /// widget yazımına izin verir; hazır değilse hazırlama future'ını
  /// arka planda başlatır ama caller'ı bloklamaz (false döner).
  ///
  /// Bu sayede pool sync (ana açılış path'i) AppGroup için 2 saniye
  /// beklemez; widget bir sonraki başarı turunda güncellenir.
  static Future<bool> _ensureAppGroupReady() {
    if (kIsWeb || !Platform.isIOS) return Future<bool>.value(true);
    final existing = _appGroupFuture;
    if (existing != null) return existing;

    final future = HomeWidget.setAppGroupId('group.com.arin.arin')
        .timeout(const Duration(seconds: 4))
        .then((_) {
          _appGroupReady = true;
          return true;
        })
        .catchError((Object e, StackTrace st) {
          debugPrint('ArinWidgetSync.setAppGroupId: $e\n$st');
          return false;
        });
    _appGroupFuture = future;
    future.then((ok) {
      if (!ok) _appGroupFuture = null;
    });
    return future;
  }
}
