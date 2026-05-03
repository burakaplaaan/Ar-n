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
  static const iOSQuoteWidgetName = 'ArinQuoteWidget';
  static const iOSPrayerWidgetName = 'ArinPrayerWidget';

  static const _androidQuote = androidQuoteProviderClass;
  static const _androidPrayer = androidPrayerProviderClass;

  static String _widgetQuotePreferredLineBreaks(String t) => t;

  /// Söz widget verisi + yalnızca söz provider güncellemesi.
  static Future<void> pushQuote({
    required String text,
    required String source,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb) return;
    try {
      if (!_appGroupReadyOrStart()) return;
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
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushQuote: $e\n$st');
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
    } catch (e, st) {
      debugPrint('ArinWidgetSync.pushQuoteSchedule: $e\n$st');
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
      if (!_appGroupReadyOrStart()) return;
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
    return 'Konum';
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
      ]) {
        await HomeWidget.saveWidgetData<String>(k, '');
      }
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQuote,
        iOSName: iOSQuoteWidgetName,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidPrayer,
        iOSName: iOSPrayerWidgetName,
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
  static bool _appGroupReadyOrStart() {
    if (kIsWeb) return false;
    if (!Platform.isIOS) return true;
    if (_appGroupReady) return true;
    if (_appGroupFuture == null) {
      unawaited(_ensureAppGroupReady());
    }
    return false;
  }

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
