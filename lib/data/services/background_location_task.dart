// lib/data/services/background_location_task.dart
//
// Uygulama TAMAMEN KAPALIYKEN bile şehir değişimini yakalayıp namaz
// vakitlerini/widget'ı güncelleyen arka plan görevi.
//
//   Android → WorkManager (periyodik, min. 15 dk; biz 3 saatte bir kuruyoruz)
//   iOS     → BGTaskScheduler (frekans yalnızca öneri; iOS kendi kararını
//             kullanım alışkanlığına göre verir, `ios/Runner/AppDelegate.swift`
//             içinde kayıtlıdır)
//
// Davranış — `LocationService.locationUpdatePref`'e göre:
//   • neverUpdate → görev hemen çıkar, konuma dokunmaz.
//   • ask/alwaysUpdate ama "Her Zaman İzin Ver" verilmemiş → görev hemen
//     çıkar (arka planda izin istemek mümkün değil; kullanıcı Ayarlar'dan
//     "Arka planda otomatik güncelle"yi açtığında izin istenir).
//   • alwaysUpdate + her zaman izni var → konum sessizce güncellenir, namaz
//     vakitleri/widget yeniden çekilir, bilgilendirme bildirimi gösterilir.
//   • ask + her zaman izni var → konum DEĞİŞTİRİLMEZ (kullanıcı onayı
//     gerekiyor); yalnızca dokunulunca uygulamayı açan bir bildirim
//     gösterilir. Uygulama açılınca `LocationChangeListener` her zamanki
//     onay diyaloğunu gösterir.
//
// Bu izolat tam bir headless Flutter engine'de çalışır — Hive, bildirim
// eklentisi ve SharedPreferences burada YENİDEN başlatılmalıdır.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/utils/hive_boxes.dart';
import 'aladhan_service.dart';
import 'arin_local_notifications_plugin.dart';
import 'arin_widget_sync.dart';
import 'diyanet_prayer_service.dart';
import 'location_service.dart';
import 'prayer_notification_scheduler.dart';
import 'prayer_service_resolver.dart';

abstract final class BackgroundLocationTask {
  /// iOS `BGTaskSchedulerPermittedIdentifiers` + AppDelegate.swift ile
  /// birebir aynı olmalı.
  static const String taskId = 'com.arin.arin.locationSync';

  /// Android WorkManager kayıt adı — tek görev, tekrar kayıtta üstüne yazmaz.
  static const String _uniqueName = 'arin_background_location_sync';

  static const Duration _frequency = Duration(hours: 3);

  static bool _workmanagerInitialized = false;

  /// Tek doğruluk kaynağı: mevcut tercih + izin durumuna göre görevi
  /// kaydeder ya da iptal eder. Uygulama açılışında (deferred startup) VE
  /// kullanıcı Ayarlar'dan tercihi her değiştirdiğinde çağrılmalıdır —
  /// böylece gereksiz yere pil/izin ayrılmaz (`neverUpdate` veya izin yoksa
  /// arka planda hiçbir periyodik uyanma olmaz).
  static Future<void> syncSchedule(LocationService location) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final shouldRun =
          location.locationUpdatePref != LocationUpdatePref.neverUpdate &&
          await location.hasAlwaysLocationPermission();
      if (shouldRun) {
        await _register();
      } else {
        await _cancel();
      }
    } catch (e) {
      debugPrint('ARIN BackgroundLocationTask.syncSchedule failed: $e');
    }
  }

  static Future<void> _register() async {
    if (!_workmanagerInitialized) {
      await Workmanager().initialize(callbackDispatcher);
      _workmanagerInitialized = true;
    }
    await Workmanager().registerPeriodicTask(
      _uniqueName,
      taskId,
      frequency: _frequency,
      initialDelay: const Duration(minutes: 20),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  static Future<void> _cancel() async {
    if (!_workmanagerInitialized) {
      // İptal için de plugin'in bir kez initialize edilmesi gerekir
      // (Android WorkManager sorgusu native tarafa gidiyor).
      await Workmanager().initialize(callbackDispatcher);
      _workmanagerInitialized = true;
    }
    await Workmanager().cancelByUniqueName(_uniqueName);
  }
}

/// WorkManager/BGTaskScheduler bu fonksiyonu ayrı bir headless Flutter
/// engine'de çağırır — `main()` ÇALIŞMAZ, hiçbir global state paylaşılmaz.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await _runBackgroundLocationSync();
    } catch (e, st) {
      debugPrint('ARIN BackgroundLocationTask isolate error: $e\n$st');
    }
    // `false` dönmek WorkManager'da otomatik yeniden deneme + backoff
    // tetikler; bir GPS/ağ arızası yüzünden sık sık pil harcanmasın diye
    // hataları burada yutup her zaman başarı bildiriyoruz — bir sonraki
    // periyodik çalıştırmada zaten tekrar denenecek.
    return Future.value(true);
  });
}

Future<void> _runBackgroundLocationSync() async {
  await Hive.initFlutter();
  if (!Hive.isBoxOpen(HiveBoxes.preferences)) {
    await Hive.openBox(HiveBoxes.preferences);
  }
  if (!Hive.isBoxOpen(HiveBoxes.prayerTimesCache)) {
    await Hive.openBox(HiveBoxes.prayerTimesCache);
  }

  final location = LocationService();
  final pref = location.locationUpdatePref;
  if (pref == LocationUpdatePref.neverUpdate) return;
  if (!await location.hasAlwaysLocationPermission()) return;

  final change = await location.detectLocationChangeHeadless();
  if (change == null) return;

  final prefs = await SharedPreferences.getInstance();
  final localeCode = _localeCodeFromPrefs(prefs);

  if (pref == LocationUpdatePref.alwaysUpdate) {
    await location.applyLocationChange(change);
    await _refreshPrayerDataAfterLocationChange(
      location: location,
      prefs: prefs,
      localeCode: localeCode,
    );
    await _showLocationNotification(
      localeCode: localeCode,
      updated: true,
      cityLabel: change.newCity,
    );
    return;
  }

  // `ask`: konumu değiştirmeden, yalnızca kullanıcıyı bilgilendir. Dokununca
  // uygulama açılır ve `LocationChangeListener` her zamanki onay diyaloğunu
  // gösterir (GPS zaten taze olduğu için anında tespit eder).
  await _showLocationNotification(
    localeCode: localeCode,
    updated: false,
    cityLabel: change.newCity,
  );
}

Future<void> _refreshPrayerDataAfterLocationChange({
  required LocationService location,
  required SharedPreferences prefs,
  required String localeCode,
}) async {
  try {
    final resolver = PrayerServiceResolver(
      diyanet: DiyanetPrayerService(),
      aladhan: AladhanService(),
      location: location,
    );
    final upcoming = await resolver.fetchUpcomingDays(days: 14);
    if (upcoming.isNotEmpty) {
      await ArinWidgetSync.refreshPrayerSchedule(
        models: upcoming,
        location: location,
        localeCode: localeCode,
      );
    }
  } catch (e) {
    debugPrint('ARIN BackgroundLocationTask widget refresh failed: $e');
  }

  try {
    await PrayerNotificationScheduler.ensurePrayerNotificationsIfEnabled(
      prefs: prefs,
      aladhan: AladhanService(),
      location: location,
      force: true,
    );
  } catch (e) {
    debugPrint('ARIN BackgroundLocationTask reschedule failed: $e');
  }
}

String _localeCodeFromPrefs(SharedPreferences prefs) {
  final raw = (prefs.getString('arin_app_locale') ?? '').toLowerCase().trim();
  if (raw.startsWith('en')) return 'en';
  if (raw.startsWith('ar')) return 'ar';
  return 'tr';
}

const _kLocationChannelId = 'arin_ntf_location_update';

Future<void> _showLocationNotification({
  required String localeCode,
  required bool updated,
  required String cityLabel,
}) async {
  try {
    await initializeArinLocalNotificationsPlugin();
    final texts = _LocationNotificationTexts.forLocale(localeCode);
    final body = updated
        ? texts.updatedBody(cityLabel)
        : texts.askBody(cityLabel);
    await arinLocalNotificationsPlugin.show(
      // Sabit ID: her yeni tespitte önceki bildirimin üstüne yazılır,
      // bildirim çubuğunu doldurmaz.
      5100100,
      updated ? texts.updatedTitle : texts.askTitle,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kLocationChannelId,
          texts.channelName,
          channelDescription: texts.channelDescription,
          importance: Importance.low,
          priority: Priority.low,
          category: AndroidNotificationCategory.status,
        ),
        iOS: const DarwinNotificationDetails(presentSound: false),
      ),
    );
  } catch (e) {
    debugPrint('ARIN BackgroundLocationTask notification failed: $e');
  }
}

class _LocationNotificationTexts {
  const _LocationNotificationTexts({
    required this.channelName,
    required this.channelDescription,
    required this.updatedTitle,
    required this.askTitle,
    required this.updatedBody,
    required this.askBody,
  });

  final String channelName;
  final String channelDescription;
  final String updatedTitle;
  final String askTitle;
  final String Function(String city) updatedBody;
  final String Function(String city) askBody;

  static _LocationNotificationTexts forLocale(String localeCode) {
    switch (localeCode) {
      case 'en':
        return _LocationNotificationTexts(
          channelName: 'Location updates',
          channelDescription:
              'Notifies when your city changes and prayer times are refreshed automatically.',
          updatedTitle: 'Location updated',
          askTitle: 'Different location detected',
          updatedBody: (city) =>
              'Prayer times were updated automatically for $city.',
          askBody: (city) =>
              'Looks like you are in $city now. Open Arın to update prayer times.',
        );
      case 'ar':
        return _LocationNotificationTexts(
          channelName: 'تحديثات الموقع',
          channelDescription:
              'يُعلمك عند تغيّر مدينتك وتحديث مواقيت الصلاة تلقائيًا.',
          updatedTitle: 'تم تحديث الموقع',
          askTitle: 'تم رصد موقع مختلف',
          updatedBody: (city) => 'تم تحديث مواقيت الصلاة تلقائيًا لمدينة $city.',
          askBody: (city) =>
              'يبدو أنك الآن في $city. افتح Arın لتحديث مواقيت الصلاة.',
        );
      case 'tr':
      default:
        return _LocationNotificationTexts(
          channelName: 'Konum güncellemeleri',
          channelDescription:
              'Şehrin değiştiğinde namaz vakitlerinin otomatik güncellendiğini bildirir.',
          updatedTitle: 'Konumun güncellendi',
          askTitle: 'Farklı bir konumdasın',
          updatedBody: (city) =>
              'Namaz vakitlerin $city için otomatik güncellendi.',
          askBody: (city) =>
              '$city\'de olduğun tespit edildi. Vakitleri güncellemek için Arın\'ı aç.',
        );
    }
  }
}
