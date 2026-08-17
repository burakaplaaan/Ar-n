// lib/main.dart
// Uygulamanın giriş noktası.
// Hive başlatma, adapter kayıtları, Riverpod kurulumu.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
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
import 'core/analytics/meta_app_events.dart';
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
import 'data/repositories/habit_repository.dart';
import 'data/services/app_notification_channel_prefs.dart';
import 'data/services/arin_local_notifications_plugin.dart';
import 'data/services/admob_service.dart';
import 'data/services/arin_lock_notification_service.dart';
import 'data/services/arin_widget_sync.dart';
import 'data/services/background_location_task.dart';
import 'data/services/location_service.dart';
import 'data/services/product_metrics_service.dart';
import 'data/services/purchase_service.dart';
import 'data/services/diyanet_district_matcher.dart';
import 'data/services/fcm_token_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';

Future<void> main() async {
  // Runtime fetch AÇIK: pubspec'te yalnızca Variable font bundle edilmiş.
  // Paket farklı weight dosyaları (Bold, ExtraBold, vb.) bekliyor — bunlar
  // bundle'da yok. Runtime fetch açıkken paket ilk açılışta CDN'den indirip
  // cache'liyor; sonraki açılışlarda cache'den okuyor. Bu çağrı async,
  // ilk frame'i bloklamıyor. Crashlytics urgent-mode spam'ı da bu nedenle
  // gerçekleşiyordu (her TextStyle çağrısında exception fırlıyordu).
  GoogleFonts.config.allowRuntimeFetching = true;

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Data-only FCM mesajlarının uygulama kapalıyken de işlenebilmesi için
      // callback runApp'ten önce kaydedilmelidir.
      FcmTokenService.registerBackgroundHandler();
      setupArinErrorReporting();
      await _runApp();
    },
    (Object error, StackTrace stack) {
      debugPrint('══ ARIN ══ runZonedGuarded: $error');
      debugPrint('══ ARIN ══ Stack:\n$stack');
      if (!isFirebaseReady) return;
      // Bilinen sıkıntısız ağ/asset hatalarını fatal raporlamayalım:
      // GoogleFonts CDN fetch fail, ClientException timeout vb. kullanıcıya
      // semptom göstermiyor (sistem font fallback'i devreye giriyor) ama
      // Crashlytics'te "Crash-Free Users" metriğini düşürür ve gerçek
      // crash'leri arasında gürültü olur. Bunlar non-fatal olarak gitsin.
      final msg = error.toString();
      final isTransient =
          msg.contains('google_fonts') ||
          msg.contains('Failed to load font') ||
          msg.contains('ClientException') ||
          msg.contains('SocketException') ||
          msg.contains('TimeoutException') ||
          msg.contains('Connection closed');
      try {
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: !isTransient,
        );
      } catch (_) {}
    },
  );
}

Future<void> _runApp() async {
  runApp(const _BootstrapApp());
  debugPrint('══ ARIN ══ first Flutter frame requested');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_configureSystemUiAfterFirstFrame());
  });
}

Future<void> _configureSystemUiAfterFirstFrame() async {
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
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e, st) {
    debugPrint('══ ARIN ══ system UI config failed (sessiz): $e');
    debugPrint('$st');
  }
}

class _BootstrapPayload {
  const _BootstrapPayload({required this.prefs});

  final SharedPreferences prefs;
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<_BootstrapPayload> _bootstrapFuture = _bootstrapApp();
  bool _deferredStartupScheduled = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapPayload>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        final payload = snapshot.data;
        if (payload != null) {
          if (!_deferredStartupScheduled) {
            _deferredStartupScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(_runDeferredStartup(payload.prefs));
            });
          }
          return ProviderScope(
            observers: const [ArinProviderObserver()],
            overrides: [
              sharedPreferencesProvider.overrideWithValue(payload.prefs),
            ],
            child: const ArinApp(),
          );
        }

        if (snapshot.hasError) {
          return _BootstrapSplash(
            message: 'Arın hazırlanamadı. Uygulamayı kapatıp tekrar aç.',
            detail: '${snapshot.error}',
          );
        }

        return const _BootstrapSplash(message: 'Arın hazırlanıyor...');
      },
    );
  }
}

bool deferredStartupDone = false;

class _BootstrapSplash extends StatelessWidget {
  const _BootstrapSplash({required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1F4F3F), Color(0xFF071815)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF9BE7C3).withValues(alpha: 0.12),
                        border: Border.all(
                          color: const Color(
                            0xFF9BE7C3,
                          ).withValues(alpha: 0.45),
                          width: 1.4,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'A',
                        style: TextStyle(
                          color: Color(0xFFB7F0D2),
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Arın',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: ArinLoader(
                        strokeWidth: 2.2,
                        color: Color(0xFF9BE7C3),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        detail!,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<_BootstrapPayload> _bootstrapApp() async {
  try {
    // ── Hive Başlatma + Adapter Kayıtları ──────────────────────────────
    await Hive.initFlutter();
    _registerAdapters();
    await _openHiveBoxes();

    // ── SharedPreferences ──────────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    await HabitRepository.seedDefaultSalatTracking(prefs);

    // intl tarih adları splash kritik yolunda beklemesin. İlk kurulumda
    // onboarding ekranlarının tarih formatına ihtiyacı yok; gerekli ekranlar
    // açılana kadar arka planda hazır olur.
    unawaited(_preloadDateFormatting());

    // Diyanet ilçe asset'ini fonda yükle (settings picker + location service
    // anlık erişim bekliyor; uygulama açılırken beklemeyelim).
    unawaited(DiyanetDistrictMatcher.loadOnce());

    final onboardingCompleted = _isOnboardingCompletedForStartup(prefs);
    if (onboardingCompleted) {
      await bootstrapFirebase();

      if (isFirebaseReady && !kDebugMode) {
        unawaited(_configureFirebaseServicesAfterBootstrap());
      } else if (isFirebaseReady) {
        debugPrint(
          '══ ARIN ══ Crashlytics + Analytics: debug build, network init '
          'atlandı (TLS retry gürültüsü olmasın diye).',
        );
      }
    } else {
      debugPrint(
        '══ ARIN ══ Firebase bootstrap: onboarding bitmemiş, ertelendi',
      );
    }

    debugPrint('══ ARIN ══ bootstrap tamam');
    return _BootstrapPayload(prefs: prefs);
  } catch (e, st) {
    debugPrint('══ ARIN ══ bootstrap failed: $e');
    debugPrint('$st');
    if (isFirebaseReady) {
      try {
        await FirebaseCrashlytics.instance.recordError(e, st, fatal: true);
      } catch (_) {}
    }
    Error.throwWithStackTrace(e, st);
  }
}

Future<void> _preloadDateFormatting() async {
  try {
    await initializeDateFormatting('tr_TR');
    await initializeDateFormatting('en_US');
    await initializeDateFormatting('ar_SA');
  } catch (e) {
    debugPrint('══ ARIN ══ date formatting preload failed (sessiz): $e');
  }
}

Future<void> _configureFirebaseServicesAfterBootstrap() async {
  // Crashlytics: debug build'de toplama kapalı (geliştirme sırasında spam
  // olmasın). Release build'de otomatik açık; istersen kullanıcı ayarlarından
  // opt-out ekleyebiliriz.
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
  try {
    await ArinAnalytics.enable();
  } catch (e) {
    debugPrint('══ ARIN ══ Analytics init failed (sessiz): $e');
  }
}

Future<void> _runDeferredStartup(SharedPreferences prefs) async {
  if (deferredStartupDone) return;
  final onboardingCompleted = _isOnboardingCompletedForStartup(prefs);

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // Kurulum attribution'ı onboarding tamamlanmasına bağlama. Bu fonksiyon
    // ilk görünür frame'den sonra kimliksiz Meta ölçümünü başlatır; ATT sistemi
    // burada gösterilmez. Eşzamanlı çağrı koruması tekrarları önler.
    unawaited(MetaAppEvents.initialize());
    if (onboardingCompleted && Platform.isIOS) {
      // ATT akışı eklenmeden önce onboarding'i tamamlamış mevcut kullanıcılar
      // `notDetermined` durumunda kalmasın. Sistem diyaloğu yalnızca bu durumda
      // bir kez görünür; kararı olan kullanıcılarda sadece SDK durumu hizalanır.
      unawaited(MetaAppEvents.requestTrackingAuthorization());
    }
  }

  // İlk kurulum/onboarding sırasında WebKit (AdMob), notification migration
  // ve legacy cleanup işleri çalışmasın. Kullanıcı daha ismini yazarken
  // WebContent/Networking process 10+ sn spawn oluyordu; bu da ilk kurulum
  // kasmasının ana kaynaklarından biri. Onboarding tamamlandıktan sonraki
  // girişlerde bu işler normal çalışır.
  if (!onboardingCompleted) {
    debugPrint(
      '══ ARIN ══ deferred startup: onboarding bitmemiş, ağır işler atlandı',
    );
    return;
  }

  if (!kIsWeb) {
    if (Platform.isAndroid || Platform.isIOS) {
      if (Platform.isAndroid) {
        // Android widget kilidi ödüllü reklamı uygulama açılır açılmaz
        // isteyebilir. SDK'yı geciktirmeden hazırlayarak ilk gösterimi iOS'taki
        // hazır reklam davranışına yaklaştır; iOS başlangıç sırasına dokunma.
        unawaited(AdMobService.initialize());
      } else {
        unawaited(
          Future<void>.delayed(
            const Duration(seconds: 6),
            AdMobService.initialize,
          ),
        );
      }

      // RevenueCat: abonelik SDK'sını Firebase UID ile başlat.
      // Gecikme olmadan başlatılır; satın alma ekranı açılmadan önce hazır olsun.
      unawaited(() async {
        final uid = isFirebaseReady
            ? FirebaseAuth.instance.currentUser?.uid
            : null;
        return PurchaseService.initialize(firebaseUid: uid);
      }());

      // Uygulama kapalıyken şehir değişimi kontrolü (WorkManager/BGTaskScheduler).
      // Yalnızca kullanıcı "arka planda otomatik güncelle"yi açıp "Her Zaman
      // İzin Ver" verdiyse fiilen bir şey yapar; aksi halde no-op'tur — bu
      // yüzden her açılışta senkronize etmek güvenlidir.
      unawaited(BackgroundLocationTask.syncSchedule(LocationService()));

      // Admin kurulum sayacı: marka + platform (manuel tahmin değil).
      unawaited(ProductMetricsService.syncInstallPresence());
    }
  }

  // iOS App Group hazırlığını paralelde başlat: pool sync veya widget
  // refresh sırasında bekleme yapmasın diye.
  ArinWidgetSync.primeAppGroup();

  // FCM dinleyicilerini ve mevcut izinlere ait topic kayıtlarını hazırla.
  if (isFirebaseReady) {
    unawaited(FcmTokenService.initIfNeeded());
  }

  await Future<void>.delayed(const Duration(seconds: 4));

  // Onboarding'i geçmiş mevcut kullanıcılarda bildirim izni hiç
  // kararlaştırılmadıysa Android 13+ / iOS sistem diyaloğunu uygulama tamamen
  // açıldıktan sonra bir kez göster. İzinli kullanıcıların topic kaydı da
  // idempotent olarak onarılır; reddedilmiş izin yeniden sorulmaz.
  if (isFirebaseReady) {
    unawaited(FcmTokenService.requestBroadcastPermissionIfNeeded());
  }

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
    await ArinLockNotificationService.migrateLegacyDefaultsIfNeeded(prefs);
  }

  // Eski "Günlük" (Journal) kutusunu disk'ten sil — özellik artık yok.
  // Bir kerelik çalışır, flag ile kilitlenir.
  await _migrateRemoveLegacyJournalBoxIfNeeded(prefs);

  // İlk-launch timestamp (review penceresini ilk 2 gün açmamak için).
  await ArinReviewPrompter.markAppLaunched(prefs);
  deferredStartupDone = true;
}

Future<void> runDeferredStartupIfNeeded(SharedPreferences prefs) {
  return _runDeferredStartup(prefs);
}

bool _isOnboardingCompletedForStartup(SharedPreferences prefs) {
  final flag = prefs.getBool('onboarding_completed');
  if (flag == false) return false;
  if (flag == true) return true;
  try {
    final profile = Hive.box<UserProfileModel>(
      HiveBoxes.userProfile,
    ).get('profile');
    return profile?.onboardingCompleted == true;
  } catch (_) {
    return false;
  }
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
