// home_widget: Android/iOS ortak anahtarlar ve provider güncellemesi.

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/prayer_times_model.dart';
import 'location_service.dart';
import 'prayer_widget_snapshot.dart';

abstract final class ArinWidgetKeys {
  static const quoteText = 'arin_quote_text';
  static const quoteSource = 'arin_quote_source';
  static const localeCode = 'arin_widget_locale';

  static const prayerLocation = 'arin_prayer_location';
  static const prayerNextName = 'arin_prayer_next_name';
  static const prayerCountdown = 'arin_prayer_countdown';
  static const prayerNextEpochMs = 'arin_prayer_next_epoch_ms';
}

abstract final class ArinWidgetSync {
  static const _forcedWidgetLocale = 'tr';
  static final RegExp _arabicChars = RegExp(r'[\u0600-\u06FF]');

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

  static Future<void> refreshPrayer({
    required PrayerTimesModel model,
    required LocationService location,
    String localeCode = 'tr',
  }) async {
    if (kIsWeb) return;
    try {
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
      for (final k in const <String>[
        ArinWidgetKeys.quoteText,
        ArinWidgetKeys.quoteSource,
        ArinWidgetKeys.localeCode,
        ArinWidgetKeys.prayerLocation,
        ArinWidgetKeys.prayerNextName,
        ArinWidgetKeys.prayerCountdown,
        ArinWidgetKeys.prayerNextEpochMs,
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
}
