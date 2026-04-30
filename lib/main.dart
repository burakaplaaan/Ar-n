// lib/main.dart
// Uygulamanın giriş noktası.
// Hive başlatma, adapter kayıtları, Riverpod kurulumu.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/analytics/arin_analytics.dart';
import 'core/debug/arin_error_reporting.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/services/arin_review_prompter.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/utils/hive_boxes.dart';
import 'data/models/user_profile_model.dart';
import 'data/models/user_profile_model.g.dart';
import 'data/models/habit_model.dart';
import 'data/models/habit_model.g.dart';
import 'data/models/habit_log_model.dart';
import 'data/models/habit_log_model.g.dart';
import 'data/services/app_local_notification_scheduler.dart';
import 'data/services/app_notification_channel_prefs.dart';
import 'data/services/arin_local_notifications_plugin.dart';
import 'data/services/diyanet_district_matcher.dart';
import 'data/services/prayer_notification_scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';

Future<void> main() async {
  // Keşfet / ilham kartları ve tema birçok Google Font ailesi kullanıyor
  // (Bodoni Moda, Great Vibes, Inter, Lora, …). `allowRuntimeFetching = false`
  // yalnızca *tüm* bu ailelerin `pubspec.yaml` + assets/fonts altında tanımlı
  // olmasıyla güvenli; aksi halde ilk kart açılışında font yükleme hatası ve
  // Crashlytics gürültüsü oluşuyor. Plus Jakarta / Scheherazade yine pubspec
  // üzerinden bundle edilir; diğerleri ilk kullanımda indirilip önbelleğe alınır.
  GoogleFonts.config.allowRuntimeFetching = true;

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      setupArinErrorReporting();
      await _runApp();
    },
    (Object error, StackTrace stack) {
      debugPrint('══ ARIN ══ runZonedGuarded: $error');
      debugPrint('══ ARIN ══ Stack:\n$stack');
      if (isFirebaseReady) {
        // runZonedGuarded yalnızca `_runApp` zamanında oluşan sync/async
        // hataları yakalıyor — Flutter framework dışı kaçakları. Bunları da
        // Crashlytics'e fatal olarak raporla.
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

Future<void> _runApp() async {
  // ── Durum Çubuğu ve Navigasyon ───────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Onboarding açık arka plan — koyu ikonlar
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Hive Başlatma + Adapter Kayıtları ────────────────────────────────
  await Hive.initFlutter();
  _registerAdapters();
  await _openHiveBoxes();

  // ── SharedPreferences ────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();

  // intl tarih adları: TR kaynak korunur, EN/AR locale geçişi için ek preload.
  await initializeDateFormatting('tr_TR');
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('ar_SA');

  if (!kIsWeb) {
    await PrayerNotificationScheduler.init();
    await AppLocalNotificationScheduler.init();
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId('group.com.arin.arin');
    }
  }

  // Diyanet ilçe asset'ini fonda yükle (settings picker + location service
  // anlık erişim bekliyor; uygulama açılırken beklemeyelim).
  unawaited(DiyanetDistrictMatcher.loadOnce());

  // Eski namaz vakti cache'ini BİR KEZ temizle — Aladhan `school=1` (Hanafi)
  // ile kaydedilmiş ve İkindi'yi 1 saat ileri atan bozuk entry'leri kökten
  // attırıyoruz. Yeni Diyanet (ezanvakti) path'i farklı key prefix'i
  // (`diyanet_v1_...`) kullanıyor, eski Aladhan entry'leri
  // (`yyyy-MM-dd_g_...`, `yyyy-MM-dd_c_...`) miras olarak duruyordu.
  // `prayer_cache_migration_v2_done` flag'i bir kereye mahsus çalıştırır.
  await _migratePrayerCacheV2IfNeeded(prefs);

  // Kaldırılan bildirim kanallarını (Günün sözü + Haftalık özet) BİR KEZ
  // temizle: pref flag'lerini false'a çek, pending pending alarm'ları
  // cancel et, Android tarafındaki kanal tanımlarını sil. Bu migration
  // olmadan eski kurulumda toggle false görünmez ve eski planlanmış
  // bildirimler tetiklenmeye devam ederdi.
  if (!kIsWeb) {
    await _migrateNotificationsV1IfNeeded(prefs);
  }

  // Eski "Günlük" (Journal) kutusunu disk'ten sil — özellik artık yok.
  // Bir kerelik çalışır, flag ile kilitlenir.
  await _migrateRemoveLegacyJournalBoxIfNeeded(prefs);

  await bootstrapFirebase();

  // Crashlytics: debug build'de toplama kapalı (geliştirme sırasında spam
  // olmasın). Release build'de otomatik açık; istersen kullanıcı ayarlarından
  // opt-out ekleyebiliriz. isFirebaseReady false ise (Firebase init başarısız)
  // yine de çöküyoruz ama Console'a gitmez — bu normal.
  if (isFirebaseReady) {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      enableCrashlyticsIntegration();
      debugPrint(
        '══ ARIN ══ Crashlytics: collection ${kDebugMode ? "DISABLED (debug)" : "ENABLED (release)"}',
      );
    } catch (e) {
      debugPrint('══ ARIN ══ Crashlytics init failed (sessiz): $e');
    }

    // Analytics — ekran açılışı + özel olaylar (zikir_complete, arinma_*,
    // frekans_*, kesfet_*, namaz_tick). Firebase Console → Analytics /
    // DebugView panelinden izlenir.
    await ArinAnalytics.enable();
  }

  // İlk-launch timestamp (review penceresini ilk 2 gün açmamak için).
  await ArinReviewPrompter.markAppLaunched(prefs);

  runApp(
    ProviderScope(
      observers: const [ArinProviderObserver()],
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ArinApp(),
    ),
  );
  debugPrint('══ ARIN ══ runApp tamam');
}

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserProfileModelAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(HabitTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(HabitModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(HabitLogModelAdapter());
  }
  // TypeId 3 (eski JournalEntryModel) — özellik kaldırıldı; artık adapter
  // kaydı yok. Eski cihazlardaki kutu `_migrateRemoveLegacyJournalBox`
  // tarafından disk'ten siliniyor.
}

/// Aynı kutuya ikinci kez `openBox` (veya paralel yarış) HiveError verir;
/// BlueStacks / hızlı yeniden başlatmada da görülebilir.
Future<void> _openHiveBoxes() async {
  await _openTypedBoxIfNeeded<UserProfileModel>(HiveBoxes.userProfile);
  await _openTypedBoxIfNeeded<HabitModel>(HiveBoxes.habits);
  await _openTypedBoxIfNeeded<HabitLogModel>(HiveBoxes.habitLogs);
  if (!Hive.isBoxOpen(HiveBoxes.prayerTimesCache)) {
    await Hive.openBox(HiveBoxes.prayerTimesCache);
  }
  if (!Hive.isBoxOpen(HiveBoxes.preferences)) {
    await Hive.openBox(HiveBoxes.preferences);
  }
  if (!Hive.isBoxOpen(HiveBoxes.salatLogs)) {
    await Hive.openBox<String>(HiveBoxes.salatLogs);
  }
  if (!Hive.isBoxOpen(HiveBoxes.quotesCache)) {
    await Hive.openBox<String>(HiveBoxes.quotesCache);
  }
}

Future<void> _openTypedBoxIfNeeded<T>(String name) async {
  if (Hive.isBoxOpen(name)) return;
  await Hive.openBox<T>(name);
}

/// v1.2: "Günün sözü (bildirim)" ve "Haftalık özet" kanalları kaldırıldı.
/// Bu migration eski kurulumdaki:
///   1) pref flag'lerini (`ntf_daily_wisdom_enabled`, `ntf_inspire_weekly_enabled`)
///      false'a çeker — yeni kodda okunmuyor ama defans için.
///   2) Pending alarm ID'lerini cancel eder (5000200–5000206, 5000700–5000707).
///   3) Android kanal tanımlarını siler (`arin_ntf_app_daily_wisdom`,
///      `arin_ntf_app_inspire`) — sistem bildirim ayarlarından artık görünmez.
/// Tekrar çalışmaması için `notifications_migration_v1_done` flag'i tutulur.
Future<void> _migrateNotificationsV1IfNeeded(SharedPreferences prefs) async {
  const flag = 'notifications_migration_v1_done';
  if (prefs.getBool(flag) == true) return;
  try {
    await prefs.setBool(
      AppNotificationChannelPrefs.legacyKeyDailyWisdom,
      false,
    );
    await prefs.setBool(
      AppNotificationChannelPrefs.legacyKeyWeeklyInspire,
      false,
    );

    for (var i = 0; i < 7; i++) {
      try {
        await arinLocalNotificationsPlugin.cancel(5000200 + i);
      } catch (_) {}
    }
    for (var i = 0; i < 8; i++) {
      try {
        await arinLocalNotificationsPlugin.cancel(5000700 + i);
      } catch (_) {}
    }
    if (Platform.isAndroid) {
      final android = arinLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      for (final c in const <String>[
        'arin_ntf_app_daily_wisdom',
        'arin_ntf_app_inspire',
      ]) {
        try {
          await android?.deleteNotificationChannel(c);
        } catch (_) {}
      }
    }
    debugPrint(
      'ARIN: notifications migration v1 — wisdom/weekly kapatıldı, '
      'pending alarm\'lar + kanallar silindi.',
    );
  } catch (e) {
    debugPrint('ARIN: notifications migration v1 failed (sessiz): $e');
  }
  await prefs.setBool(flag, true);
}

/// Günlük (Journal) özelliği kaldırıldı. Eski kurulumlardaki kullanıcı
/// cihazlarında `arin_journal_entries` Hive kutusu disk'te kalmış olabilir;
/// adapter kaydı olmadığı için açılırsa crash eder. Biz kutuyu hiç açmadan
/// `deleteBoxFromDisk` ile siliyoruz — güvenli ve idempotent.
Future<void> _migrateRemoveLegacyJournalBoxIfNeeded(
  SharedPreferences prefs,
) async {
  const flag = 'legacy_journal_box_removed_v1';
  if (prefs.getBool(flag) == true) return;
  try {
    if (Hive.isBoxOpen(HiveBoxes.legacyJournalEntries)) {
      await Hive.box(HiveBoxes.legacyJournalEntries).close();
    }
    await Hive.deleteBoxFromDisk(HiveBoxes.legacyJournalEntries);
    debugPrint('ARIN: legacy journal box silindi.');
  } catch (e) {
    debugPrint('ARIN: legacy journal box silinemedi (sessiz): $e');
  }
  await prefs.setBool(flag, true);
}

/// Bozuk Aladhan cache'ini (school=1 Hanafi, ikindi 1 saat ileri) temizler.
/// Yalnızca ilk çalıştırmada tetiklenir; sonraki açılışlar `return` eder.
Future<void> _migratePrayerCacheV2IfNeeded(SharedPreferences prefs) async {
  const flag = 'prayer_cache_migration_v2_done';
  if (prefs.getBool(flag) == true) return;
  try {
    if (!Hive.isBoxOpen(HiveBoxes.prayerTimesCache)) {
      await Hive.openBox(HiveBoxes.prayerTimesCache);
    }
    final box = Hive.box(HiveBoxes.prayerTimesCache);
    // Diyanet migration'ından SONRA eklenen `diyanet_v1_*` anahtarlarına
    // dokunma; yalnız eski Aladhan prefix'lerini hedefle.
    final doomed = box.keys
        .where((k) {
          if (k is! String) return true;
          return !k.startsWith('diyanet_');
        })
        .toList(growable: false);
    if (doomed.isNotEmpty) {
      await box.deleteAll(doomed);
      debugPrint(
        'ARIN: prayer cache migration v2 — ${doomed.length} eski '
        'entry silindi.',
      );
    }
  } catch (e) {
    debugPrint('ARIN: prayer cache migration v2 failed (sessiz): $e');
  }
  await prefs.setBool(flag, true);
}
