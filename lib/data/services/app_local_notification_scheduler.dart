// Arınma / içerik hatırlatıcıları — yerel planlama (Android / iOS). Web’de no-op.
// Namaz bildirimleriyle ID çakışmaması için 5000xxx bandı kullanılır.
// Günlük arınma + günün sözü: gün bazlı rastgele saat, 7 günlük tek seferlik plan.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/localization/locale_text.dart';
import '../../core/constants/quote_pool_ids.dart';
import '../content/arin_ntf_messages.dart';
import '../content/daily_namaz_wisdom.dart';
import '../quote_pools/quote_pool_defaults.dart';
import '../quote_pools/localized_pool_fields.dart';
import '../quote_pools/quote_pool_parsers.dart';
import '../models/prayer_times_model.dart';
import '../repositories/quote_pools_repository.dart';
import '../repositories/zikir_matik_repository.dart';
import 'admin_notification_diagnostics_log.dart';
import 'android_local_notification_schedule.dart';
import 'app_notification_channel_prefs.dart';
import 'arin_local_notifications_plugin.dart';
import 'local_notification_permission_gate.dart';
import 'tz_local_bootstrap.dart';

bool _appInitialized = false;

/// Sabit bildirim kimlikleri (namaz bandı ~9_100_000 ile ayrı).
abstract final class AppLocalNotificationIds {
  /// Eski tek ID (iptal için).
  static const int legacyDailyArinma = 5000001;

  /// Günlük hatırlatıcı — gün başına 2 slot (söz + motivasyon), 7 günlük
  /// pencere: 7×2 = 14 bildirim (5000100–5000113).
  ///
  /// Slot dizilimi: `base + d*2`   → slot 0 (söz, home_namaz_wisdom havuzu)
  ///                `base + d*2+1` → slot 1 (motivasyon, arınma havuzu, 3.5 saat sonra)
  static const int arinmaWeekStart = 5000100;
  static const int arinmaSlotsPerDay = 2;
  static const int arinmaWindowDays = 7;

  /// Kaldırılan kanalların eski ID'leri (v1.2.0 öncesi kurulumlarda
  /// pending olabilir — migration sırasında iptal edilir).
  /// Günün sözü: 5000200–5000206 (7 slot)
  /// Haftalık ilham: 5000700–5000707 (8 slot)
  static const int legacyDailyWisdomWeekStart = 5000200;
  static const int legacyDailyWisdomSlotCount = 7;
  static const int legacyWeeklyInspireRollingStart = 5000700;
  static const int legacyWeeklyInspireSlotCount = 8;

  /// Eski tekil ID’ler ([matchDateTimeComponents] — güncellemede iptal).
  static const int legacyMilestoneWeekly = 5000002;
  static const int legacyTaskDaily = 5000003;
  static const int legacyWeeklyInspire = 5000004;
  static const int legacyZikirQuote = 5000005;

  /// Günlük sabit saat — 30 günlük tek seferlik plan (OEM uyumu).
  static const int taskDailyRollingStart = 5000400;
  static const int zikirQuoteRollingStart = 5000500;
  static const int rollingDailySlotCount = 30;

  /// Haftalık — 8 tekrar.
  static const int milestoneRollingStart = 5000600;
  static const int rollingWeeklySlotCount = 8;

  /// Admin/test bildirimleri için sabit kimlikler.
  static const int testZikirScheduled = 9199981;
}

abstract final class AppLocalNotificationDefaults {
  static const int taskMinutesFromMidnight = 21 * 60;
  static const int milestoneWeekday = DateTime.sunday;
  static const int milestoneMinutesFromMidnight = 10 * 60;

  /// Günlük hatırlatıcı: slot 0 (söz) rastgele penceresi.
  /// 09:00–18:00 arasında — slot 1 (motivasyon) +3.5 saat sonra
  /// en geç 21:30'a kadar gelir, gece rahatsız etmez.
  static const int randomWindowStartMin = 9 * 60;
  static const int randomWindowEndMin = 18 * 60;

  /// Slot 0 ile slot 1 arasındaki sabit aralık (dakika).
  /// Kullanıcı talebi: "diğer söz 3,5 saat sonra".
  static const int arinmaSlotGapMinutes = 3 * 60 + 30;

  /// iOS bekleyen bildirim limiti (~64) için uygulama kanalı bütçesi.
  /// Namaz scheduler kritik olduğu için burada bilinçli düşük tutulur.
  static const int iosArinmaWindowDays = 4; // 4 gün × 2 slot = 8
  static const int iosTaskRollingDays = 3;
  static const int iosZikirRollingDays = 2;
  static const int iosMilestoneRollingWeeks = 2;
}

abstract final class AppLocalNotificationScheduler {
  static Future<void> _rescheduleTail = Future.value();

  /// Resume tabanlı tetiklerin son saniye alarm iptali yapmasını önlemek için
  /// aynı türde (force olmayan) çağrılar bu pencerede birleştirilir.
  static DateTime _lastRescheduleAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _resumeCooldown = Duration(seconds: 30);

  static String _lt(
    String localeCode, {
    required String tr,
    required String en,
    required String ar,
  }) => trEnArByCode(localeCode, tr: tr, en: en, ar: ar);

  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!supported || _appInitialized) return;
    await configureArinLocalTimeZone();
    await initializeArinLocalNotificationsPlugin();
    _appInitialized = true;

    final android = arinLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    const channels = <List<String>>[
      ['arin_ntf_app_daily', 'Günlük hatırlatıcı'],
      ['arin_ntf_app_milestone', 'Milestone'],
      ['arin_ntf_app_task', 'Görev hatırlatıcısı'],
      ['arin_ntf_app_zikir', 'Zikir'],
    ];
    for (final c in channels) {
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          c[0],
          c[1],
          description: 'Daily reminders and content notifications',
          importance: Importance.max,
        ),
      );
    }
  }

  /// [force] true ise soğutma penceresini by-pass eder (ayarlar toggle /
  /// admin aksiyonu). Lifecycle resume’unda `false` bırakılmalı — aksi halde
  /// yaklaşık bir tetik saati varken alarm iptal edilip yeniden kuyruğa alınır
  /// ve geçer.
  static Future<void> rescheduleAll(
    SharedPreferences prefs, {
    QuotePoolsRepository? pools,
    PrayerTimesModel? prayerTimes,
    bool force = false,
  }) {
    final now = DateTime.now();
    if (!force && now.difference(_lastRescheduleAt) < _resumeCooldown) {
      unawaited(
        AdminNotificationDiagnosticsLog.append(
          prefs,
          source: 'app',
          action: 'reschedule',
          outcome: 'cooldown_skip',
          details: <String, Object?>{'force': force},
        ),
      );
      return _rescheduleTail;
    }
    _lastRescheduleAt = now;
    final run = _rescheduleTail.then(
      (_) => _rescheduleBody(
        prefs,
        pools: pools,
        prayerTimes: prayerTimes,
        force: force,
      ),
    );
    _rescheduleTail = run.catchError((Object _, StackTrace __) {});
    return run;
  }

  static Future<void> _rescheduleBody(
    SharedPreferences prefs, {
    QuotePoolsRepository? pools,
    PrayerTimesModel? prayerTimes,
    required bool force,
  }) async {
    if (!supported) return;
    var zikirQueued = 0;
    final localeCode = normalizeLocaleCode(prefs.getString('arin_app_locale'));
    try {
      await init();
      await configureArinLocalTimeZone();

      if (Platform.isAndroid) {
        final android = arinLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await android?.requestNotificationsPermission();
        await Permission.scheduleExactAlarm.request();
        await android?.requestExactAlarmsPermission();
      }

      // Pool sync ağa bağlı — AWAIT edilirse Firestore timeout'una (10–30 sn)
      // kadar zikir/görev/milestone gibi havuzla ilgisi olmayan sabit saatli
      // hatırlatıcılar bile kuyruğa girmiyordu. Toggle / saat seçimi anında
      // etkili olmalı: pool sync arka plana atılır, scheduler cache'te ne varsa
      // onunla içerik doldurur, sonraki cycle (resume veya force) taze pool
      // kullanır. Havuza bağımlı olmayan kanallar (zikir, task, milestone,
      // weekly) ağdan bağımsız ilk turda planlanır.
      if (pools != null) {
        unawaited(_kickoffPoolSync(pools));
      }

      // Resume akışında her seferinde toplu cancel+reschedule yapmak, özellikle
      // tetik saatine çok yakın açılışlarda (ör. 20:59–21:02) görev/milestone
      // alarmlarının kaçmasına yol açabiliyor. Kuyrukta her açık kanal için
      // yeterli rezerv pending varsa force olmayan turu atla.
      if (!force) {
        final pending = await arinLocalNotificationsPlugin
            .pendingNotificationRequests();
        final queueHealthy = _isManagedQueueHealthyForEnabledChannels(
          prefs,
          pending,
        );
        final staleDisabled = _hasPendingForDisabledChannels(prefs, pending);
        if (queueHealthy && !staleDisabled) {
          await AdminNotificationDiagnosticsLog.append(
            prefs,
            source: 'app',
            action: 'reschedule',
            outcome: 'pending_guard_skip',
            details: <String, Object?>{
              'force': force,
              'pending': pending.length,
            },
          );
          return;
        }
      }

      await _cancelOurNotifications();

      // Yumuşak içerik (arınma, günün sözü) için `exactAllowWhileIdle` yeterli.
      // Sabit saatte çalması gereken görev / milestone / haftalık özet / zikir
      // hatırlatıcıları kullanıcıya doğrudan görünen alarmlar; `alarmClock` Doze
      // muafiyeti + OEM güç yöneticilerine karşı dayanıklılık sağlar.
      final contentMode = await androidScheduleModePreferExact(
        arinLocalNotificationsPlugin,
      );
      final fixedTimeMode = await androidScheduleModePreferAlarmClock(
        arinLocalNotificationsPlugin,
      );

      final now = tz.TZDateTime.now(tz.local);
      const start = AppLocalNotificationDefaults.randomWindowStartMin;
      const end = AppLocalNotificationDefaults.randomWindowEndMin;
      const gap = AppLocalNotificationDefaults.arinmaSlotGapMinutes;
      final arinmaWindowDays = Platform.isIOS
          ? AppLocalNotificationDefaults.iosArinmaWindowDays
          : AppLocalNotificationIds.arinmaWindowDays;
      final taskRollingDays = Platform.isIOS
          ? AppLocalNotificationDefaults.iosTaskRollingDays
          : AppLocalNotificationIds.rollingDailySlotCount;
      final zikirRollingDays = Platform.isIOS
          ? AppLocalNotificationDefaults.iosZikirRollingDays
          : AppLocalNotificationIds.rollingDailySlotCount;
      final milestoneRollingWeeks = Platform.isIOS
          ? AppLocalNotificationDefaults.iosMilestoneRollingWeeks
          : AppLocalNotificationIds.rollingWeeklySlotCount;

      // Günlük hatırlatıcı — gün başına 2 slot:
      //   slot 0: home_namaz_wisdom havuzundan namaz sözü/hadisi — öğle vaktinden
      //           15 dakika önce gelir; prayerTimes null ise 09:00–18:00 rastgele.
      //   slot 1: arınma havuzundan kısa motivasyon, +3.5 saat sonra
      // Slot 0 saati 09:00–18:00 bandına clamp'lenir → slot 1 en geç 21:30 olur.
      if (AppNotificationChannelPrefs.arinmaDailyEnabled(prefs)) {
        for (var d = 0; d < arinmaWindowDays; d++) {
          final day = DateTime(
            now.year,
            now.month,
            now.day,
          ).add(Duration(days: d));

          // Slot 0 (namaz sözü) — öğle vakti - 15 dk; offline fallback rastgele.
          final slot0Min = _namazSlot0Minutes(
            prayerTimes: prayerTimes,
            dayLocal: day,
            salt: 11,
            startMin: start,
            endMin: end,
          );
          final slot1Min = slot0Min + gap;
          final when0 = tz.TZDateTime(
            tz.local,
            day.year,
            day.month,
            day.day,
            slot0Min ~/ 60,
            slot0Min % 60,
          );
          final when1 = tz.TZDateTime(
            tz.local,
            day.year,
            day.month,
            day.day,
            slot1Min ~/ 60,
            slot1Min % 60,
          );
          final idBase =
              AppLocalNotificationIds.arinmaWeekStart +
              d * AppLocalNotificationIds.arinmaSlotsPerDay;

          // Slot 0: namaz sözü/hadisi — home_namaz_wisdom havuzundan
          if (when0.isAfter(now)) {
            final noon = DateTime(day.year, day.month, day.day, 12);
            final entry = pools != null
                ? dailyNamazWisdomForNotificationWithPool(
                    pools,
                    noon,
                    localeCode,
                  )
                : dailyNamazWisdomForNotification(noon);
            final title = entry.source != null && entry.source!.isNotEmpty
                ? '${entry.kind} · ${entry.source}'
                : _lt(
                    localeCode,
                    tr: 'Namaz',
                    en: 'Prayer',
                    ar: 'الصلاة',
                  );
            final body = _prepareNotificationBody(
              _dailyWisdomBodyForLocale(entry, localeCode),
            );
            if (body == null) continue;
            await _safeZonedSchedule(
              idBase,
              title,
              body,
              when0,
              _details(
                channelId: 'arin_ntf_app_daily',
                channelName: 'Günlük hatırlatıcı',
                body: body,
              ),
              contentMode,
            );
          }

          // Slot 1: motivasyon (eski arınma metinleri) — 3.5 saat sonra
          if (when1.isAfter(now)) {
            final rawBody = pools != null
                ? arinmaNotificationBodyWithPool(pools, day, localeCode)
                : arinmaNotificationBodyForDay(day);
            final body = _prepareNotificationBody(rawBody);
            if (body == null) continue;
            await _safeZonedSchedule(
              idBase + 1,
              _lt(
                localeCode,
                tr: 'Arınma hatırlatıcısı',
                en: 'Purification reminder',
                ar: 'تذكير التزكية',
              ),
              body,
              when1,
              _details(
                channelId: 'arin_ntf_app_daily',
                channelName: 'Günlük hatırlatıcı',
                body: body,
              ),
              contentMode,
            );
          }
        }
      }

      if (AppNotificationChannelPrefs.milestoneEnabled(prefs)) {
        await _scheduleWeekdayNextOccurrences(
          idBase: AppLocalNotificationIds.milestoneRollingStart,
          maxOccurrences: milestoneRollingWeeks,
          weekday: AppLocalNotificationDefaults.milestoneWeekday,
          minutesFromMidnight:
              AppLocalNotificationDefaults.milestoneMinutesFromMidnight,
          title: _lt(
            localeCode,
            tr: 'Yolculuğun',
            en: 'Your journey',
            ar: 'رحلتك',
          ),
          body: _lt(
            localeCode,
            tr: 'Alışkanlıklarına ve başarılarına göz atmayı unutma.',
            en: 'Do not forget to review your habits and progress.',
            ar: 'لا تنس مراجعة عاداتك وتقدمك.',
          ),
          details: _details(
            channelId: 'arin_ntf_app_milestone',
            channelName: 'Milestone',
          ),
          mode: fixedTimeMode,
        );
      }

      if (AppNotificationChannelPrefs.taskReminderEnabled(prefs)) {
        await _scheduleFixedTimeNextDays(
          idBase: AppLocalNotificationIds.taskDailyRollingStart,
          maxDays: taskRollingDays,
          minutesFromMidnight:
              AppLocalNotificationDefaults.taskMinutesFromMidnight,
          title: _lt(localeCode, tr: 'Görevler', en: 'Tasks', ar: 'المهام'),
          body: _lt(
            localeCode,
            tr: 'Bugünkü adımlarını tamamladın mı?',
            en: 'Did you complete today\'s steps?',
            ar: 'هل أكملت خطوات اليوم؟',
          ),
          details: _details(
            channelId: 'arin_ntf_app_task',
            channelName: 'Görev hatırlatıcısı',
          ),
          mode: fixedTimeMode,
        );
      }

      if (AppNotificationChannelPrefs.zikirQuoteEnabled(prefs)) {
        final m = AppNotificationChannelPrefs.zikirQuoteMinutesFromMidnight(
          prefs,
        );
        final h = m ~/ 60;
        final mi = m % 60;
        final repo = ZikirMatikRepository(prefs);
        final fallbackPhrase = repo.loadSession().phrase.trim();
        var slot = 0;
        var queued = 0;
        for (var d = 0; d < 45 && slot < zikirRollingDays; d++) {
          final cal = DateTime(
            now.year,
            now.month,
            now.day,
          ).add(Duration(days: d));
          final when = tz.TZDateTime(
            tz.local,
            cal.year,
            cal.month,
            cal.day,
            h,
            mi,
          );
          if (!when.isAfter(now)) continue;
          final body = _prepareNotificationBody(
            _zikirBodyForDay(pools, cal, fallbackPhrase, localeCode),
          );
          if (body == null) continue;
          final ok = await _safeZonedSchedule(
            AppLocalNotificationIds.zikirQuoteRollingStart + slot,
            _lt(localeCode, tr: 'Zikir', en: 'Dhikr', ar: 'ذكر'),
            body,
            when,
            _details(
              channelId: 'arin_ntf_app_zikir',
              channelName: 'Zikir',
              body: body,
            ),
            fixedTimeMode,
          );
          if (ok) queued++;
          slot++;
        }
        debugPrint(
          'AppLocalNtf: zikir scheduled days=$queued/$slot mode=${fixedTimeMode.name} '
          'firstAt=${tz.TZDateTime(tz.local, now.year, now.month, now.day, h, mi)}',
        );
        zikirQueued = queued;
      }
      await AdminNotificationDiagnosticsLog.append(
        prefs,
        source: 'app',
        action: 'reschedule',
        outcome: 'ok',
        details: <String, Object?>{
          'force': force,
          'daily_on': AppNotificationChannelPrefs.arinmaDailyEnabled(prefs),
          'milestone_on': AppNotificationChannelPrefs.milestoneEnabled(prefs),
          'task_on': AppNotificationChannelPrefs.taskReminderEnabled(prefs),
          'zikir_on': AppNotificationChannelPrefs.zikirQuoteEnabled(prefs),
          'zikir_queued': zikirQueued,
          'ios_caps': Platform.isIOS
              ? <String, int>{
                  'arinma_days': arinmaWindowDays,
                  'task_days': taskRollingDays,
                  'zikir_days': zikirRollingDays,
                  'milestone_weeks': milestoneRollingWeeks,
                }
              : const <String, int>{},
        },
      );
    } catch (e) {
      await AdminNotificationDiagnosticsLog.append(
        prefs,
        source: 'app',
        action: 'reschedule',
        outcome: 'error',
        details: <String, Object?>{'force': force, 'error': '$e'},
      );
      rethrow;
    }
  }

  /// Zikir bildirimi gövdesi, tercih sırasıyla:
  /// 1) `zikir_daily_reflections` havuzu (kullanıcı talebi: zikir sözleri),
  /// 2) Kullanıcının ZikirMatik oturumunda seçtiği son ifade (kişisel hatırlatma),
  /// 3) Hive cache boşsa varsayılan zikir yansımalarından gün endeksi,
  /// 4) Genel fallback metin.
  ///
  /// Her gün için ayrı çağrı: 30 günlük pencerede her bildirim farklı söz taşır.
  static String _zikirBodyForDay(
    QuotePoolsRepository? pools,
    DateTime dayLocal,
    String fallbackPhrase,
    String localeCode,
  ) {
    if (pools != null) {
      final poolText = zikirReflectionTextForDay(
        pools,
        dayLocal,
        localeCode,
      ).trim();
      if (poolText.isNotEmpty) return poolText;
    }
    final defaults = QuotePoolDefaults.zikirDailyReflections();
    if (defaults.isNotEmpty) {
      final anchor = DateTime(2020, 1, 1);
      final idx = dayLocal.difference(anchor).inDays.abs() % defaults.length;
      final t =
          localizedPoolField(
            defaults[idx],
            baseKey: 'text',
            localeCode: localeCode,
            legacyKeys: const <String>['text', 'body'],
          )?.trim() ??
          '';
      if (t.isNotEmpty) return t;
    }
    if (fallbackPhrase.isNotEmpty) return fallbackPhrase;
    return _lt(
      localeCode,
      tr: 'Zikir etmek için kısa bir mola.',
      en: 'Take a short pause for dhikr.',
      ar: 'خذ وقفة قصيرة للذكر.',
    );
  }

  /// KRİTİK: `zonedSchedule`, exact alarm izni eksikse Android 12+’da
  /// `ArgumentError` fırlatır — bu bir [Error] olduğundan `on Exception`
  /// ONU YAKALAMAZ. Önceki sürümde bu yüzden zikir döngüsü ilk günde
  /// kopuyor, kalan 29 gün hiç planlanmıyor; fakat çağıran üst katman
  /// `try { ... } catch (e) {}` ile hatayı yutuyor; kullanıcı sessizce
  /// "saati kurdum, bildirim gelmiyor" yaşıyordu.
  ///
  /// Artık `catch (e)` (tüm Object'leri) yakalar, `alarmClock`/`exact`
  /// başarısızsa `inexactAllowWhileIdle`'a düşer, o da başarısızsa sessiz
  /// kalmak yerine [bool] `false` döndürür — çağıran istatistik toplar.
  /// 3 kademeli fallback: `alarmClock` → `exactAllowWhileIdle` → `inexactAllowWhileIdle`.
  ///
  /// OEM override örneği (Samsung OneUI 8): `canScheduleExactAlarms()` false
  /// döner ama `setAlarmClock()` çalışır. Bu nedenle önce en güçlü modu
  /// deneriz; reddedilirse kademeli olarak daha zayıf moda düşeriz. Böylece
  /// zamanında ÇOK GÜVENLİ çalma (alarmClock) → ZAMANINDA çalma (exact) →
  /// EN AZINDAN çalma (inexact) sırası korunur.
  static Future<bool> _safeZonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
    NotificationDetails details,
    AndroidScheduleMode mode,
  ) async {
    final attempts = <AndroidScheduleMode>[mode];
    if (Platform.isAndroid) {
      if (mode == AndroidScheduleMode.alarmClock &&
          !attempts.contains(AndroidScheduleMode.exactAllowWhileIdle)) {
        attempts.add(AndroidScheduleMode.exactAllowWhileIdle);
      }
      if (!attempts.contains(AndroidScheduleMode.inexactAllowWhileIdle)) {
        attempts.add(AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
    Object? lastError;
    for (final m in attempts) {
      try {
        await arinLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: m,
        );
        if (m != mode) {
          debugPrint(
            'AppLocalNtf: primary ${mode.name} failed, succeeded with ${m.name} (id=$id)',
          );
        }
        return true;
      } catch (e) {
        lastError = e;
        debugPrint('AppLocalNtf: ${m.name} failed for id=$id ($e)');
      }
    }
    debugPrint(
      'AppLocalNtf: all schedule modes failed for id=$id ($lastError)',
    );
    return false;
  }

  /// `flutter_local_notifications ^17.x` Android tarafında pending alarm
  /// kaydını Gson ile JSON’a serialize ediyor. Android 16 (API 36) + Java 17
  /// reflection davranışı + R8’in signature’ları atma riski bir araya gelince
  /// `cancel()` içinde `TypeToken<List<...>>` deserialize’ı
  /// `IllegalStateException: TypeToken must be created with a type argument`
  /// fırlatabiliyor (ölçüldü: Samsung Galaxy A34 / OneUI 8). Bu durumda
  /// plugin önceden kaydedilen alarmı silemez ama `zonedSchedule` aynı id
  /// ile çağrıldığında üstüne yazdığı için fonksiyonel olarak sorun değil.
  /// Burada hatayı YUTMAK şarttır; aksi hâlde tüm reschedule zinciri kopar.
  static Future<void> _cancelSilently(int id) async {
    try {
      await arinLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('AppLocalNtf: cancel($id) failed silently ($e)');
    }
  }

  static Future<void> _cancelOurNotifications() async {
    await _cancelSilently(AppLocalNotificationIds.legacyDailyArinma);
    // Arınma: 7 gün × 2 slot = 14 ID (5000100–5000113)
    const arinmaTotal =
        AppLocalNotificationIds.arinmaWindowDays *
        AppLocalNotificationIds.arinmaSlotsPerDay;
    for (var i = 0; i < arinmaTotal; i++) {
      await _cancelSilently(AppLocalNotificationIds.arinmaWeekStart + i);
    }
    // Kaldırılan kanallar — pending varsa temizle (yeniden plan yapılmaz).
    for (
      var i = 0;
      i < AppLocalNotificationIds.legacyDailyWisdomSlotCount;
      i++
    ) {
      await _cancelSilently(
        AppLocalNotificationIds.legacyDailyWisdomWeekStart + i,
      );
    }
    for (
      var i = 0;
      i < AppLocalNotificationIds.legacyWeeklyInspireSlotCount;
      i++
    ) {
      await _cancelSilently(
        AppLocalNotificationIds.legacyWeeklyInspireRollingStart + i,
      );
    }
    for (final id in <int>[
      AppLocalNotificationIds.legacyMilestoneWeekly,
      AppLocalNotificationIds.legacyTaskDaily,
      AppLocalNotificationIds.legacyWeeklyInspire,
      AppLocalNotificationIds.legacyZikirQuote,
    ]) {
      await _cancelSilently(id);
    }
    for (var i = 0; i < AppLocalNotificationIds.rollingDailySlotCount; i++) {
      await _cancelSilently(AppLocalNotificationIds.taskDailyRollingStart + i);
      await _cancelSilently(AppLocalNotificationIds.zikirQuoteRollingStart + i);
    }
    for (var i = 0; i < AppLocalNotificationIds.rollingWeeklySlotCount; i++) {
      await _cancelSilently(AppLocalNotificationIds.milestoneRollingStart + i);
    }
  }

  static bool _hasPendingInRange(
    List<PendingNotificationRequest> pending,
    int startId,
    int count,
  ) {
    if (count <= 0) return false;
    final end = startId + count - 1;
    for (final p in pending) {
      final id = p.id;
      if (id >= startId && id <= end) return true;
    }
    return false;
  }

  static int _pendingCountInRange(
    List<PendingNotificationRequest> pending,
    int startId,
    int count,
  ) {
    if (count <= 0) return 0;
    final end = startId + count - 1;
    var total = 0;
    for (final p in pending) {
      final id = p.id;
      if (id >= startId && id <= end) total++;
    }
    return total;
  }

  static int _minReserveFromTarget(int target) {
    if (target <= 1) return 1;
    if (target <= 3) return 2;
    return 3;
  }

  static bool _isManagedQueueHealthyForEnabledChannels(
    SharedPreferences prefs,
    List<PendingNotificationRequest> pending,
  ) {
    final arinmaTarget = Platform.isIOS
        ? AppLocalNotificationDefaults.iosArinmaWindowDays *
              AppLocalNotificationIds.arinmaSlotsPerDay
        : AppLocalNotificationIds.arinmaWindowDays *
              AppLocalNotificationIds.arinmaSlotsPerDay;
    final taskTarget = Platform.isIOS
        ? AppLocalNotificationDefaults.iosTaskRollingDays
        : AppLocalNotificationIds.rollingDailySlotCount;
    final zikirTarget = Platform.isIOS
        ? AppLocalNotificationDefaults.iosZikirRollingDays
        : AppLocalNotificationIds.rollingDailySlotCount;
    final milestoneTarget = Platform.isIOS
        ? AppLocalNotificationDefaults.iosMilestoneRollingWeeks
        : AppLocalNotificationIds.rollingWeeklySlotCount;

    final arinmaQueued = _pendingCountInRange(
      pending,
      AppLocalNotificationIds.arinmaWeekStart,
      AppLocalNotificationIds.arinmaWindowDays *
          AppLocalNotificationIds.arinmaSlotsPerDay,
    );
    final taskQueued = _pendingCountInRange(
      pending,
      AppLocalNotificationIds.taskDailyRollingStart,
      AppLocalNotificationIds.rollingDailySlotCount,
    );
    final milestoneQueued = _pendingCountInRange(
      pending,
      AppLocalNotificationIds.milestoneRollingStart,
      AppLocalNotificationIds.rollingWeeklySlotCount,
    );
    final zikirQueued = _pendingCountInRange(
      pending,
      AppLocalNotificationIds.zikirQuoteRollingStart,
      AppLocalNotificationIds.rollingDailySlotCount,
    );

    if (AppNotificationChannelPrefs.arinmaDailyEnabled(prefs) &&
        arinmaQueued < _minReserveFromTarget(arinmaTarget)) {
      return false;
    }

    if (AppNotificationChannelPrefs.taskReminderEnabled(prefs) &&
        taskQueued < _minReserveFromTarget(taskTarget)) {
      return false;
    }

    if (AppNotificationChannelPrefs.milestoneEnabled(prefs) &&
        milestoneQueued < _minReserveFromTarget(milestoneTarget)) {
      return false;
    }

    if (AppNotificationChannelPrefs.zikirQuoteEnabled(prefs) &&
        zikirQueued < _minReserveFromTarget(zikirTarget)) {
      return false;
    }

    return true;
  }

  static bool _hasPendingForDisabledChannels(
    SharedPreferences prefs,
    List<PendingNotificationRequest> pending,
  ) {
    final hasArinma = _hasPendingInRange(
      pending,
      AppLocalNotificationIds.arinmaWeekStart,
      AppLocalNotificationIds.arinmaWindowDays *
          AppLocalNotificationIds.arinmaSlotsPerDay,
    );
    if (!AppNotificationChannelPrefs.arinmaDailyEnabled(prefs) && hasArinma) {
      return true;
    }

    final hasTask = _hasPendingInRange(
      pending,
      AppLocalNotificationIds.taskDailyRollingStart,
      AppLocalNotificationIds.rollingDailySlotCount,
    );
    if (!AppNotificationChannelPrefs.taskReminderEnabled(prefs) && hasTask) {
      return true;
    }

    final hasMilestone = _hasPendingInRange(
      pending,
      AppLocalNotificationIds.milestoneRollingStart,
      AppLocalNotificationIds.rollingWeeklySlotCount,
    );
    if (!AppNotificationChannelPrefs.milestoneEnabled(prefs) && hasMilestone) {
      return true;
    }

    final hasZikir = _hasPendingInRange(
      pending,
      AppLocalNotificationIds.zikirQuoteRollingStart,
      AppLocalNotificationIds.rollingDailySlotCount,
    );
    if (!AppNotificationChannelPrefs.zikirQuoteEnabled(prefs) && hasZikir) {
      return true;
    }

    return false;
  }

  static NotificationDetails _details({
    required String channelId,
    required String channelName,
    String? body,
  }) {
    final safeBody = body?.trim();
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Daily reminders and content notifications',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: safeBody != null && safeBody.isNotEmpty
            ? BigTextStyleInformation(safeBody, htmlFormatBigText: false)
            : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static String? _prepareNotificationBody(String s) {
    const hardLimit = 600;
    final t = s.trim();
    if (t.isEmpty) return null;
    // Çok uzun metin lock-screen'de görsel olarak kırılıyor, kullanıcı etkisi
    // düşüyor; bu durumda bildirimi göndermemeyi tercih ediyoruz.
    if (t.length > hardLimit) return null;
    return t;
  }

  static String _dailyWisdomBodyForLocale(
    DailyNamazWisdom entry,
    String localeCode,
  ) {
    final code = normalizeLocaleCode(localeCode);
    if (code == 'ar') {
      final ar = entry.arabic.trim();
      if (ar.isNotEmpty) return ar;
      return 'افتح تطبيق آرين لعرض حكمة اليوم.';
    }
    final text = entry.turkish.trim();
    if (code == 'en') {
      return 'Open Arin to view today\'s wisdom.';
    }
    return text;
  }

  /// Slot 0 (namaz sözü) için hedef dakikayı hesaplar.
  ///
  /// [prayerTimes] mevcutsa öğle vakti (dhuhr) - 15 dakikayı kullanır;
  /// böylece bildirim namazdan hemen önce gelir ve hatırlatma etkisi artar.
  /// Hesaplanan değer her zaman [startMin]–[endMin] bandına clamp'lenir
  /// (gece yarısı veya çok erken/geç öğle saatlerine karşı güvenli).
  /// [prayerTimes] null ise (offline, ilk açılış) deterministik rastgele saat.
  static int _namazSlot0Minutes({
    required PrayerTimesModel? prayerTimes,
    required DateTime dayLocal,
    required int salt,
    required int startMin,
    required int endMin,
  }) {
    if (prayerTimes != null) {
      final parts = prayerTimes.dhuhr.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          final target = h * 60 + m - 15;
          return target.clamp(startMin, endMin);
        }
      }
    }
    return randomMinutesInWindow(
      dayLocal: dayLocal,
      salt: salt,
      startMin: startMin,
      endMin: endMin,
    );
  }

  /// [matchDateTimeComponents] yerine: her gün için ayrı tek seferlik alarm (Android OEM uyumu).
  static Future<void> _scheduleFixedTimeNextDays({
    required int idBase,
    required int maxDays,
    required int minutesFromMidnight,
    required String title,
    required String body,
    required NotificationDetails details,
    required AndroidScheduleMode mode,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final h = minutesFromMidnight ~/ 60;
    final mi = minutesFromMidnight % 60;
    var slot = 0;
    for (var d = 0; d < 45 && slot < maxDays; d++) {
      final cal = DateTime(now.year, now.month, now.day).add(Duration(days: d));
      final when = tz.TZDateTime(tz.local, cal.year, cal.month, cal.day, h, mi);
      if (!when.isAfter(now)) continue;
      await _safeZonedSchedule(idBase + slot, title, body, when, details, mode);
      slot++;
    }
  }

  /// Haftanın belirli günü — birkaç hafta ileriye tek seferlik.
  static Future<void> _scheduleWeekdayNextOccurrences({
    required int idBase,
    required int maxOccurrences,
    required int weekday,
    required int minutesFromMidnight,
    required String title,
    required String body,
    required NotificationDetails details,
    required AndroidScheduleMode mode,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final h = minutesFromMidnight ~/ 60;
    final mi = minutesFromMidnight % 60;
    var slot = 0;
    for (var add = 0; add < 120 && slot < maxOccurrences; add++) {
      final cal = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: add));
      final when = tz.TZDateTime(tz.local, cal.year, cal.month, cal.day, h, mi);
      if (when.weekday != weekday) continue;
      if (!when.isAfter(now)) continue;
      await _safeZonedSchedule(idBase + slot, title, body, when, details, mode);
      slot++;
    }
  }

  /// AlarmManager’a gerçekten kaç hatırlatıcı kayıtlı olduğunu döner — ayarlar
  /// sayfasında "Manuel çalışıyor, zamanlanan çalışmıyor" şikayetini anında
  /// doğrulamak için kritik tanı. 0 ise ya izin yok ya da cihaz kurulumu
  /// engelliyor (battery optimization, exact alarm iptali).
  static Future<int> pendingScheduleCount() async {
    if (!supported) return 0;
    try {
      await init();
      final pending = await arinLocalNotificationsPlugin
          .pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      debugPrint('AppLocalNtf: pendingCount error: $e');
      return 0;
    }
  }

  /// Pool senkronunu scheduler turu dışına çıkarır; başarısız da olsa planlama
  /// tur başında içerikleri cache'ten doldurup zincirlemeye devam eder.
  static Future<void> _kickoffPoolSync(QuotePoolsRepository pools) async {
    try {
      await pools.ensureSyncedToday(QuotePoolIds.homeNamazWisdom);
    } catch (e) {
      debugPrint('AppLocalNtf: pool homeNamazWisdom sync failed: $e');
    }
    try {
      await pools.ensureSyncedToday(QuotePoolIds.notificationArinmaBodies);
    } catch (e) {
      debugPrint('AppLocalNtf: pool notificationArinmaBodies sync failed: $e');
    }
    try {
      await pools.ensureSyncedToday(QuotePoolIds.zikirDailyReflections);
    } catch (e) {
      debugPrint('AppLocalNtf: pool zikirDailyReflections sync failed: $e');
    }
  }

  /// Kullanıcı bir gün beklemeden test edebilsin diye: hedef kanal + gerçek
  /// havuz gövdesi + alarmClock modu (izin varsa) ile zikir hatırlatıcısını
  /// `delay` sonrasına zamanlar. Plan başarısız olursa sırasıyla
  /// `exactAllowWhileIdle` → `inexactAllowWhileIdle`'a düşer; hepsi düşerse
  /// sebebi açık mesajla döndürür.
  ///
  /// KRİTİK: Permission-gate ÖN KONTROLÜ YOK. Önceki sürümde plugin'in
  /// `canScheduleExactNotifications()` dönüşü `permission_handler`'ın
  /// `Permission.scheduleExactAlarm.status` dönüşüyle bazı cihazlarda
  /// uyuşmuyordu; kullanıcı gerçekte izin vermiş olsa bile gate "verilmedi"
  /// diyordu. Artık doğrudan deneriz, fiili hatayı `_safeZonedSchedule`
  /// sınıflandırıp fallback eder.
  static Future<String?> scheduleZikirTestIn({
    required SharedPreferences prefs,
    QuotePoolsRepository? pools,
    Duration delay = const Duration(seconds: 60),
  }) async {
    final localeCode = normalizeLocaleCode(prefs.getString('arin_app_locale'));
    if (!supported) {
      return _lt(
        localeCode,
        tr: 'Bu platformda yerel bildirim yok.',
        en: 'Local notifications are not available on this platform.',
        ar: 'الإشعارات المحلية غير متاحة على هذه المنصة.',
      );
    }
    try {
      await init();
      await configureArinLocalTimeZone();
      if (pools != null) {
        try {
          await pools.ensureSyncedToday(QuotePoolIds.zikirDailyReflections);
        } catch (_) {
          /* offline: defaults kullanılır */
        }
      }
      const id = AppLocalNotificationIds.testZikirScheduled;
      await _cancelSilently(id);
      final when = tz.TZDateTime.now(tz.local).add(delay);
      final fallbackPhrase = ZikirMatikRepository(
        prefs,
      ).loadSession().phrase.trim();
      final body = _prepareNotificationBody(
        _zikirBodyForDay(pools, DateTime.now(), fallbackPhrase, localeCode),
      );
      if (body == null) {
        return _lt(
          localeCode,
          tr: 'Zikir metni çok uzun olduğu için test bildirimi gönderilmedi.',
          en: 'Test notification was not sent because the dhikr text is too long.',
          ar: 'لم يتم إرسال إشعار الاختبار لأن نص الذكر طويل جدًا.',
        );
      }
      final mode = await androidScheduleModePreferAlarmClock(
        arinLocalNotificationsPlugin,
      );
      final ok = await _safeZonedSchedule(
        id,
        _lt(localeCode, tr: 'Zikir', en: 'Dhikr', ar: 'ذكر'),
        body,
        when,
        _details(
          channelId: 'arin_ntf_app_zikir',
          channelName: 'Zikir',
          body: body,
        ),
        mode,
      );
      if (!ok) {
        // 3 schedule kademesi de patladı — çoğunlukla plugin 17.x Gson /
        // TypeToken hatası (Android 16 + R8 + generic signature). Kullanıcıya
        // "hata" yerine EN AZINDAN anında bildirim gösterelim ki kanalın
        // çalıştığı doğrulansın.
        try {
          await arinLocalNotificationsPlugin.show(
            id,
            _lt(localeCode, tr: 'Zikir', en: 'Dhikr', ar: 'ذكر'),
            body,
            _details(
              channelId: 'arin_ntf_app_zikir',
              channelName: 'Zikir',
              body: body,
            ),
          );
          return 'Sistem zamanlamayı reddetti (plugin Gson bug’ı). Bildirim '
              'yine de anında gönderildi.';
        } catch (e2) {
          return 'Sistem zamanlı bildirimi reddetti. Pil optimizasyonu '
              'muafiyeti ve tam zamanlayıcı iznini cihaz ayarlarından aç.';
        }
      }
      final pending = await pendingScheduleCount();
      debugPrint(
        'scheduleZikirTestIn: queued id=$id at=$when mode=${mode.name} '
        'pending=$pending',
      );
      return null;
    } catch (e, st) {
      // Plugin 17.x Gson/TypeToken hatalarında bile kullanıcıya bildirim
      // verebilmek için anlık `show()`’a düşeriz — test butonunun hiç
      // çalışmaması “bildirim sistemi kırık” algısı yaratıyor; en azından
      // tek bir bildirim anında gelmeli.
      debugPrint('scheduleZikirTestIn: schedule path failed ($e)\n$st');
      try {
        final fallbackPhrase = ZikirMatikRepository(
          prefs,
        ).loadSession().phrase.trim();
        final body = _prepareNotificationBody(
          _zikirBodyForDay(pools, DateTime.now(), fallbackPhrase, localeCode),
        );
        if (body == null) {
          return _lt(
            localeCode,
            tr: 'Zikir metni çok uzun olduğu için test bildirimi gönderilmedi.',
            en: 'Test notification was not sent because the dhikr text is too long.',
            ar: 'لم يتم إرسال إشعار الاختبار لأن نص الذكر طويل جدًا.',
          );
        }
        await arinLocalNotificationsPlugin.show(
          AppLocalNotificationIds.testZikirScheduled,
          _lt(localeCode, tr: 'Zikir', en: 'Dhikr', ar: 'ذكر'),
          body,
          _details(
            channelId: 'arin_ntf_app_zikir',
            channelName: 'Zikir',
            body: body,
          ),
        );
        return 'Zamanlama kaydedilemedi (plugin hatası); bildirim yine de '
            'anında gönderildi.';
      } catch (e2) {
        return 'Zamanlanmış test başarısız: $e';
      }
    }
  }

  /// Zikir kanalında anında (AlarmManager devreye girmeden) bildirim —
  /// kullanıcıya saatinde gelecek gövdenin AYNISI ile. İzin pre-check yok;
  /// OS bildirim iznini reddederse plugin hata fırlatmaz, sessiz düşer,
  /// bu da UX açısından kötüdür — `_verifyNotificationPermissionQuiet` ile
  /// yalnız durum SORULUR, dialog açılmaz.
  static Future<String?> showImmediateZikirTestNotification({
    required SharedPreferences prefs,
    QuotePoolsRepository? pools,
  }) async {
    final localeCode = normalizeLocaleCode(prefs.getString('arin_app_locale'));
    if (!supported) {
      return _lt(
        localeCode,
        tr: 'Bu platformda yerel bildirim yok.',
        en: 'Local notifications are not available on this platform.',
        ar: 'الإشعارات المحلية غير متاحة على هذه المنصة.',
      );
    }
    try {
      await init();
      if (pools != null) {
        try {
          await pools.ensureSyncedToday(QuotePoolIds.zikirDailyReflections);
        } catch (_) {
          /* offline: defaults kullanılır */
        }
      }
      final fallbackPhrase = ZikirMatikRepository(
        prefs,
      ).loadSession().phrase.trim();
      final body = _prepareNotificationBody(
        _zikirBodyForDay(pools, DateTime.now(), fallbackPhrase, localeCode),
      );
      if (body == null) {
        return _lt(
          localeCode,
          tr: 'Zikir metni çok uzun olduğu için anlık test gönderilmedi.',
          en: 'Immediate test was not sent because the dhikr text is too long.',
          ar: 'لم يتم إرسال الاختبار الفوري لأن نص الذكر طويل جدًا.',
        );
      }
      await arinLocalNotificationsPlugin.show(
        9199990,
        _lt(localeCode, tr: 'Zikir', en: 'Dhikr', ar: 'ذكر'),
        body,
        _details(
          channelId: 'arin_ntf_app_zikir',
          channelName: 'Zikir',
          body: body,
        ),
      );
      return null;
    } catch (e, st) {
      debugPrint('showImmediateZikirTestNotification: $e\n$st');
      return 'Bildirim gösterilemedi: $e';
    }
  }

  /// Admin: günlük arınma kanalında anında test bildirimi.
  /// Başarı: `null`. Hata: kısa kullanıcı mesajı.
  static Future<String?> showImmediateTestAppNotification() async {
    if (!supported) {
      return 'Local notifications are not available on this platform.';
    }
    await init();
    final allowed = await requestLocalNotificationRuntimePermissions(
      arinLocalNotificationsPlugin,
      policy: LocalNotificationPermissionPolicy.notificationOnly,
    );
    if (!allowed) {
      return 'Notification permission required. Enable it from app settings.';
    }
    try {
      await arinLocalNotificationsPlugin.show(
        9199992,
        'Test: App notification',
        'Daily channel — now',
        _details(
          channelId: 'arin_ntf_app_daily',
          channelName: 'Daily reminders',
          body: 'Daily channel — now',
        ),
      );
      return null;
    } catch (e, st) {
      debugPrint('showImmediateTestAppNotification: $e\n$st');
      return 'Bildirim gösterilemedi: $e';
    }
  }
}
