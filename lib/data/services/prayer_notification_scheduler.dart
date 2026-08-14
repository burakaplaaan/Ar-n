// Beş vakit için yerel bildirim planlama (Android / iOS). Web’de no-op.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_times_model.dart';
import 'admin_notification_diagnostics_log.dart';
import 'admin_dev_prefs.dart';
import 'aladhan_service.dart';
import 'android_local_notification_schedule.dart';
import 'diyanet_prayer_service.dart';
import 'local_notification_permission_gate.dart';
import 'location_service.dart';
import 'app_local_notification_scheduler.dart';
import 'arin_local_notifications_plugin.dart';
import 'prayer_notification_android_uri.dart';
import 'prayer_notification_sounds.dart';
import 'prayer_reminder_prefs.dart';
import 'prayer_service_resolver.dart';
import 'prayer_user_notification_sound_store.dart';
import 'tz_local_bootstrap.dart';

/// Son planlanan bildirim kimlikleri (iptal için).
final List<int> _scheduledIds = [];

bool _initialized = false;
Future<void>? _initFuture;
String? _initializedLocaleCode;
const Duration _initTimeout = Duration(seconds: 3);
const MethodChannel _nativePrayerNotifications = MethodChannel(
  'com.arin.arin/prayer_notifications',
);

/// Arka arkaya gelen [reschedule] çağrılarını susturur.
/// Yaklaşık bir alarm saatine yakın tekrar-planlama, alarmın kaçırılmasına
/// sebep olabilir (setAlarmClock iptal edip yeniden kuyruğa alır).
DateTime _lastRescheduleAt = DateTime.fromMillisecondsSinceEpoch(0);
const Duration _resumeRescheduleCooldown = Duration(seconds: 30);

abstract final class PrayerNotificationScheduler {
  /// Üst üste gelen [reschedule] çağrılarını sıraya alır (iptal/plan yarışını önler).
  static Future<void> _rescheduleTail = Future.value();

  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String _localeCodeFromPrefs(SharedPreferences prefs) {
    final raw = (prefs.getString('arin_app_locale') ?? '').toLowerCase().trim();
    if (raw.startsWith('en')) return 'en';
    if (raw.startsWith('ar')) return 'ar';
    return 'tr';
  }

  static String _deviceLocaleCode() {
    final raw = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    if (raw.startsWith('en')) return 'en';
    if (raw.startsWith('ar')) return 'ar';
    return 'tr';
  }

  static List<String> _prayerLabels(String localeCode) {
    if (localeCode == 'en') {
      return const <String>[
        'Fajr',
        'Sunrise',
        'Dhuhr',
        'Asr',
        'Maghrib',
        'Isha',
      ];
    }
    if (localeCode == 'ar') {
      return const <String>[
        'الفجر',
        'الشروق',
        'الظهر',
        'العصر',
        'المغرب',
        'العشاء',
      ];
    }
    return const <String>['İmsak', 'Güneş', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'];
  }

  static String _prayerTimeTitle(String localeCode, String label) {
    if (localeCode == 'en') return '$label time';
    if (localeCode == 'ar') return 'وقت $label';
    return '$label vakti';
  }

  static String _prayerTimeBody(
    String localeCode, {
    required int minutesBefore,
    required String label,
  }) {
    if (minutesBefore > 0) {
      if (localeCode == 'en') return '$label starts in $minutesBefore min.';
      if (localeCode == 'ar') return 'سيدخل وقت $label بعد $minutesBefore د.';
      return '$minutesBefore dk sonra $label vakti girecek.';
    }
    if (localeCode == 'en') return '$label time has started.';
    if (localeCode == 'ar') return 'دخل وقت $label.';
    return '$label vakti girdi.';
  }

  static String _channelDescription(String localeCode) {
    if (localeCode == 'en') {
      return 'Prayer reminders and selected notification sounds';
    }
    if (localeCode == 'ar') return 'تذكيرات الصلاة وصوت الإشعار المختار';
    return 'Vakit hatırlatıcıları ve seçilen bildirim sesi';
  }

  static String _testPermissionRequiredMessage(String localeCode) {
    if (localeCode == 'en') {
      return 'Notification permission is required. Open Arin -> Notifications from settings.';
    }
    if (localeCode == 'ar') {
      return 'إذن الإشعارات مطلوب. افتح أرين -> الإشعارات من الإعدادات.';
    }
    return 'Bildirim izni gerekli. Ayarlardan Arın -> Bildirimler’i aç.';
  }

  static String _testUnsupportedMessage(String localeCode) {
    if (localeCode == 'en') {
      return 'Local notifications are unavailable on this platform.';
    }
    if (localeCode == 'ar') {
      return 'الإشعارات المحلية غير متاحة على هذه المنصة.';
    }
    return 'Bu platformda yerel bildirim yok.';
  }

  static String _testTitle(String localeCode) {
    if (localeCode == 'en') return 'Test: Prayer notification';
    if (localeCode == 'ar') return 'اختبار: إشعار الصلاة';
    return 'Test: Namaz bildirimi';
  }

  static String _testBody(String localeCode) {
    if (localeCode == 'en') return 'Sound and channel — now';
    if (localeCode == 'ar') return 'الصوت والقناة — الآن';
    return 'Ses ve kanal — şimdi';
  }

  static String _testShowError(String localeCode, Object e) {
    if (localeCode == 'en') return 'Could not show notification: $e';
    if (localeCode == 'ar') return 'تعذر عرض الإشعار: $e';
    return 'Bildirim gösterilemedi: $e';
  }

  static Future<void> init({SharedPreferences? prefs}) async {
    if (!supported) return;
    final localeCode = prefs != null
        ? _localeCodeFromPrefs(prefs)
        : _deviceLocaleCode();
    if (_initialized && _initializedLocaleCode == localeCode) return;
    final inflight = _initFuture;
    if (inflight != null) return inflight;

    try {
      final run = _initImpl(localeCode: localeCode).timeout(_initTimeout);
      _initFuture = run.whenComplete(() {
        _initFuture = null;
      });
      return _initFuture;
    } on TimeoutException catch (e, st) {
      _initFuture = null;
      debugPrint('Prayer NTF: init timeout ($e)');
      debugPrint('$st');
      rethrow;
    } catch (e, st) {
      _initFuture = null;
      debugPrint('Prayer NTF: init failed ($e)');
      debugPrint('$st');
      rethrow;
    }
  }

  static Future<void> _initImpl({required String localeCode}) async {
    await initializeArinLocalNotificationsPlugin();
    await configureArinLocalTimeZone();

    final android = arinLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (Platform.isAndroid) {
      // Eski sürüm kanalları (v4–v6) silinmezse sistem yanlış/kısa sese kilitlenir.
      const legacyIds = <String>[
        'arin_ntf_s1_v4',
        'arin_ntf_s2_v4',
        'arin_ntf_s3_v4',
        'arin_ntf_s4_v4',
        'arin_ntf_s5_v4',
        'arin_ntf_s1_v5',
        'arin_ntf_s2_v5',
        'arin_ntf_s3_v5',
        'arin_ntf_s4_v5',
        'arin_ntf_s5_v5',
        'arin_ntf_s1_v6',
        'arin_ntf_s2_v6',
        'arin_ntf_s3_v6',
        'arin_ntf_s4_v6',
        'arin_ntf_s5_v6',
      ];
      for (final id in legacyIds) {
        await android?.deleteNotificationChannel(id);
      }
    }
    final channelDesc = _channelDescription(localeCode);
    for (var i = 0; i < PrayerNotificationSounds.options.length; i++) {
      final opt = PrayerNotificationSounds.options[i];
      AndroidNotificationSound? sound;
      if (Platform.isAndroid && i > 0) {
        final base = opt.androidRawBaseName;
        if (base != null && base.isNotEmpty) {
          sound = RawResourceAndroidNotificationSound(base);
        }
      }
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          opt.channelId,
          PrayerNotificationSounds.localizedChannelName(opt, localeCode),
          description: channelDesc,
          importance: Importance.max,
          playSound: true,
          sound: sound,
        ),
      );
    }
    if (Platform.isAndroid) {
      await android?.deleteNotificationChannel('arin_ntf_s0_sysdefault_v2');
    }
    _initializedLocaleCode = localeCode;
    _initialized = true;
  }

  static Future<void> cancelAllPrayerNotifications() async {
    if (!supported) return;
    final idsToCancel = <int>{
      ..._scheduledIds,
      ..._knownPrayerNotificationIdsAround(DateTime.now()),
    };
    if (Platform.isAndroid) {
      try {
        await _nativePrayerNotifications.invokeMethod<void>('cancelAll');
      } catch (e) {
        debugPrint('Prayer NTF: native cancelAll failed silently ($e)');
      }
    }
    try {
      final pending = await arinLocalNotificationsPlugin
          .pendingNotificationRequests();
      for (final req in pending) {
        if (_isPrayerOwnedNotificationId(req.id)) {
          idsToCancel.add(req.id);
        }
      }
    } catch (e) {
      debugPrint('Prayer NTF: pending list read failed ($e)');
    }

    for (final id in idsToCancel) {
      if (Platform.isAndroid) {
        try {
          await _nativePrayerNotifications.invokeMethod<void>('cancel', id);
        } catch (e) {
          debugPrint('Prayer NTF: native cancel($id) failed silently ($e)');
        }
      }
      try {
        await arinLocalNotificationsPlugin.cancel(id);
      } catch (e) {
        // Plugin 17.x Gson/TypeToken (Android 16) riski; sessiz yut — aynı
        // id ile sonraki `zonedSchedule` üstüne yazar.
        debugPrint('Prayer NTF: cancel($id) failed silently ($e)');
      }
    }
    _scheduledIds.clear();
  }

  static Iterable<int> _knownPrayerNotificationIdsAround(DateTime now) sync* {
    final today = DateTime(now.year, now.month, now.day);
    for (var dayOffset = -2; dayOffset <= 35; dayOffset++) {
      final day = today.add(Duration(days: dayOffset));
      for (
        var prayerIndex = 0;
        prayerIndex < PrayerReminderPrefs.slotCount;
        prayerIndex++
      ) {
        final base = _idFor(day, prayerIndex);
        yield base;
        yield base + 250000;
        // Eski tek-gün fallback yolu yarınki imsak/güneş için ek offset'li ID
        // kullanıyordu; migration temizliğinde onları da kapsa.
        yield base + 100;
        yield base + 250100;
        yield base + 1100;
        yield base + 251100;
      }
    }
  }

  static bool _isPrayerOwnedNotificationId(int id) {
    if (id == 9199991) return true; // anlık test bildirimi
    // Namaz scheduler'ın üretim bandı: 9_100_000 + (yyyymmdd*10) + slot/offset.
    // Güncel üretimler ~200M bandına düşer; app kanalı 5_000_xxx kullandığı için
    // bu alt sınır prayer id'lerini güvenle ayırır.
    return id >= 9100000;
  }

  /// [model] tek-gün fallback yolu için bugünün vakitleri.
  ///
  /// [force] true olduğunda soğuma süresini by-pass eder (ayarlar sayfası
  /// veya admin değişikliği için). Foreground tekrarlarında `false` bırakın —
  /// aksi halde `setAlarmClock` son saniye iptali tetikleyebiliyor.
  ///
  /// [upcomingDays] verilirse çok-günlük pencere planlanır.
  /// iOS'ta bekleyen bildirim limiti nedeniyle pencere, aktif offset sayısına
  /// göre dinamik daraltılabilir; ancak planlanan günlerde çift uyarı korunur.
  static Future<void> reschedule({
    required SharedPreferences prefs,
    required PrayerTimesModel model,
    String? tomorrowFajrHm,
    String? tomorrowImsakHm,
    List<PrayerTimesModel>? upcomingDays,
    bool force = false,
  }) {
    final now = DateTime.now();
    if (!force &&
        now.difference(_lastRescheduleAt) < _resumeRescheduleCooldown) {
      unawaited(
        AdminNotificationDiagnosticsLog.append(
          prefs,
          source: 'prayer',
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
        prefs: prefs,
        model: model,
        tomorrowFajrHm: tomorrowFajrHm,
        tomorrowImsakHm: tomorrowImsakHm,
        upcomingDays: upcomingDays,
        force: force,
      ),
    );
    _rescheduleTail = run.catchError((Object _, StackTrace __) {});
    return run;
  }

  /// Önce doğrulamalar; yalnızca yeniden planlayabileceğimizden emin olunca iptal eder
  /// (aksi halde geçerli alarmlar silinip yerine konmama riski oluşuyordu).
  static Future<void> _rescheduleBody({
    required SharedPreferences prefs,
    required PrayerTimesModel model,
    String? tomorrowFajrHm,
    String? tomorrowImsakHm,
    List<PrayerTimesModel>? upcomingDays,
    required bool force,
  }) async {
    if (!supported) return;
    try {
      await init(prefs: prefs);
      await configureArinLocalTimeZone();
      final localeCode = _localeCodeFromPrefs(prefs);

      if (!PrayerReminderPrefs.isEnabled(prefs)) {
        await cancelAllPrayerNotifications();
        await AdminNotificationDiagnosticsLog.append(
          prefs,
          source: 'prayer',
          action: 'reschedule',
          outcome: 'disabled',
        );
        return;
      }

      await PrayerReminderPrefs.ensurePerPrayerPrefsReady(prefs);

      // Namaz vakitleri kullanıcıya doğrudan çalan, günün en kritik alarmları:
      // `setAlarmClock` → Doze muafiyeti + OEM güç yöneticilerine dayanıklılık.
      final androidPrayerMode = await androidScheduleModePreferAlarmClock(
        arinLocalNotificationsPlugin,
      );
      final detailsByPrayer = await _buildPrayerDetailsCache(prefs);

      final now = DateTime.now();

      // Çok-günlük mod: liste verildiyse her gün için 6 vaktin tamamını plan.
      // Bu mod kullanıcı uygulamayı haftalarca açmasa bile bildirimlerin
      // kesintisiz gelmesini sağlar.
      if (upcomingDays != null && upcomingDays.isNotEmpty) {
        final daysForPlan = _limitUpcomingDaysForPlatform(
          prefs: prefs,
          days: upcomingDays,
        );
        if (!_hasAnySchedulableSlotInMultiDay(daysForPlan, prefs: prefs)) {
          await AdminNotificationDiagnosticsLog.append(
            prefs,
            source: 'prayer',
            action: 'reschedule',
            outcome: 'skip_invalid_payload',
            details: <String, Object?>{
              'multi_day': true,
              'days_requested': upcomingDays.length,
            },
          );
          return;
        }
        await cancelAllPrayerNotifications();
        await _scheduleMultiDay(
          prefs: prefs,
          days: daysForPlan,
          now: now,
          androidPrayerMode: androidPrayerMode,
          detailsByPrayer: detailsByPrayer,
          localeCode: localeCode,
        );
        final iosPerDayAlerts = Platform.isIOS ? _iosAlertsPerDay(prefs) : null;
        await AdminNotificationDiagnosticsLog.append(
          prefs,
          source: 'prayer',
          action: 'reschedule',
          outcome: 'ok',
          details: <String, Object?>{
            'scheduled_ids': _scheduledIds.length,
            'days_requested': upcomingDays.length,
            'days_planned': daysForPlan.length,
            'force': force,
            'multi_day': true,
            if (Platform.isIOS) 'ios_alerts_per_day': iosPerDayAlerts,
            if (Platform.isIOS) 'ios_pending_budget': _iosPrayerPendingBudget,
          },
        );
        return;
      }

      // — Eski tek-gün yolu (geriye dönük) —
      final day = DateTime(now.year, now.month, now.day);
      final labels = _prayerLabels(localeCode);
      final times = [
        model.fajr,
        model.sunrise,
        model.dhuhr,
        model.asr,
        model.maghrib,
        model.isha,
      ];
      final nextDay = day.add(const Duration(days: 1));
      if (!_hasAnySchedulableSlotInSingleDay(
        day: day,
        times: times,
        nextDay: nextDay,
        tomorrowFajrHm: tomorrowFajrHm,
        tomorrowImsakHm: tomorrowImsakHm,
      )) {
        await AdminNotificationDiagnosticsLog.append(
          prefs,
          source: 'prayer',
          action: 'reschedule',
          outcome: 'skip_invalid_payload',
          details: const <String, Object?>{'multi_day': false},
        );
        return;
      }
      await cancelAllPrayerNotifications();

      for (var i = 0; i < PrayerReminderPrefs.slotCount; i++) {
        final slotStart = _tryAtClock(day, times[i]);
        if (slotStart == null) {
          debugPrint('Prayer NTF: invalid time for ${labels[i]} (${times[i]})');
          continue;
        }
        final a = PrayerReminderPrefs.minutesBeforeForPrayer(prefs, i);
        final b = PrayerReminderPrefs.minutesBeforeSecondaryForPrayer(prefs, i);
        final details = detailsByPrayer[i];
        await _schedulePrayerOffsets(
          slotStart: slotStart,
          now: now,
          label: labels[i],
          offsetsMinutes: _uniqueOffsets(a, b),
          idBase: _idFor(day, i),
          details: details,
          androidScheduleMode: androidPrayerMode,
          localeCode: localeCode,
        );
      }

      if (tomorrowFajrHm != null) {
        final tomorrowFajr = _tryAtClock(nextDay, tomorrowFajrHm);
        if (tomorrowFajr == null) {
          debugPrint('Prayer NTF: invalid tomorrow fajr ($tomorrowFajrHm)');
        } else {
          final a0 = PrayerReminderPrefs.minutesBeforeForPrayer(prefs, 0);
          final b0 = PrayerReminderPrefs.minutesBeforeSecondaryForPrayer(
            prefs,
            0,
          );
          final d0 = detailsByPrayer[0];
          await _schedulePrayerOffsets(
            slotStart: tomorrowFajr,
            now: now,
            label: labels[0],
            offsetsMinutes: _uniqueOffsets(a0, b0),
            idBase: _idFor(nextDay, 0) + 100,
            details: d0,
            androidScheduleMode: androidPrayerMode,
            localeCode: localeCode,
          );
        }
      }
      if (tomorrowImsakHm != null) {
        final tomorrowSunrise = _tryAtClock(nextDay, tomorrowImsakHm);
        if (tomorrowSunrise == null) {
          debugPrint('Prayer NTF: invalid tomorrow sunrise ($tomorrowImsakHm)');
        } else {
          final a1 = PrayerReminderPrefs.minutesBeforeForPrayer(prefs, 1);
          final b1 = PrayerReminderPrefs.minutesBeforeSecondaryForPrayer(
            prefs,
            1,
          );
          final d1 = detailsByPrayer[1];
          await _schedulePrayerOffsets(
            slotStart: tomorrowSunrise,
            now: now,
            label: labels[1],
            offsetsMinutes: _uniqueOffsets(a1, b1),
            idBase: _idFor(nextDay, 1) + 1100,
            details: d1,
            androidScheduleMode: androidPrayerMode,
            localeCode: localeCode,
          );
        }
      }
      await AdminNotificationDiagnosticsLog.append(
        prefs,
        source: 'prayer',
        action: 'reschedule',
        outcome: 'ok',
        details: <String, Object?>{
          'scheduled_ids': _scheduledIds.length,
          'force': force,
          'multi_day': false,
        },
      );
    } catch (e) {
      await AdminNotificationDiagnosticsLog.append(
        prefs,
        source: 'prayer',
        action: 'reschedule',
        outcome: 'error',
        details: <String, Object?>{'error': '$e'},
      );
      rethrow;
    }
  }

  /// 7 günlük blok planlayıcı. Her [PrayerTimesModel] kaydı, `model.date`
  /// ("yyyy-MM-dd") alanına göre ilgili takvim gününe yerleştirilir.
  ///
  /// iOS bekleyen bildirim limiti için gün sayısı dinamik daraltılabilir;
  /// planlanan pencerede her vakit için çift uyarı (primary + secondary)
  /// korunur.
  static Future<void> _scheduleMultiDay({
    required SharedPreferences prefs,
    required List<PrayerTimesModel> days,
    required DateTime now,
    required AndroidScheduleMode androidPrayerMode,
    required List<NotificationDetails> detailsByPrayer,
    required String localeCode,
  }) async {
    final labels = _prayerLabels(localeCode);
    final today = DateTime(now.year, now.month, now.day);

    for (var dayIdx = 0; dayIdx < days.length; dayIdx++) {
      final model = days[dayIdx];
      final shifted = AdminDevPrefs.applyPrayerOffset(prefs, model);
      final calendarDay = _dayForModel(
        shifted,
        fallbackOffsetFromToday: dayIdx,
        today: today,
      );
      if (calendarDay == null) continue;

      final times = [
        shifted.fajr,
        shifted.sunrise,
        shifted.dhuhr,
        shifted.asr,
        shifted.maghrib,
        shifted.isha,
      ];

      for (var i = 0; i < PrayerReminderPrefs.slotCount; i++) {
        final slotStart = _tryAtClock(calendarDay, times[i]);
        if (slotStart == null) {
          debugPrint(
            'Prayer NTF: invalid multi-day time for ${labels[i]} (${times[i]})',
          );
          continue;
        }
        final a = PrayerReminderPrefs.minutesBeforeForPrayer(prefs, i);
        final b = PrayerReminderPrefs.minutesBeforeSecondaryForPrayer(prefs, i);
        final offsets = _offsetsForDay(a: a, b: b);
        if (offsets.isEmpty) continue;
        final details = detailsByPrayer[i];
        await _schedulePrayerOffsets(
          slotStart: slotStart,
          now: now,
          label: labels[i],
          offsetsMinutes: offsets,
          idBase: _idFor(calendarDay, i),
          details: details,
          androidScheduleMode: androidPrayerMode,
          localeCode: localeCode,
        );
      }
    }
  }

  /// `model.date` ("yyyy-MM-dd") → DateTime; bozuk/eksik tarihte
  /// listedeki sırayla fallback: `today + fallbackOffsetFromToday`.
  static DateTime? _dayForModel(
    PrayerTimesModel model, {
    required DateTime today,
    required int fallbackOffsetFromToday,
  }) {
    final raw = model.date;
    final parts = raw.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        final parsed = DateTime(y, m, d);
        if (parsed.year == y && parsed.month == m && parsed.day == d) {
          return parsed;
        }
      }
    }
    return today.add(Duration(days: fallbackOffsetFromToday));
  }

  static Future<List<NotificationDetails>> _buildPrayerDetailsCache(
    SharedPreferences prefs,
  ) async {
    final out = List<NotificationDetails?>.filled(
      PrayerReminderPrefs.slotCount,
      null,
    );
    for (var i = 0; i < PrayerReminderPrefs.slotCount; i++) {
      out[i] = await _notificationDetailsForPrayer(prefs, i);
    }
    return out.cast<NotificationDetails>();
  }

  /// Gün başına planlanacak dakika-offset'leri.
  static List<int> _offsetsForDay({required int a, required int b}) {
    return _uniqueOffsets(a, b);
  }

  /// iOS app-wide pending limiti (~64) için namaz kanalına ayrılan güvenli bütçe.
  /// Kalan birkaç slot uygulamanın diğer bildirim kanallarına bırakılır.
  static const int _iosPrayerPendingBudget = 60;

  static int _iosAlertsPerDay(SharedPreferences prefs) {
    var total = 0;
    for (var i = 0; i < PrayerReminderPrefs.slotCount; i++) {
      final a = PrayerReminderPrefs.minutesBeforeForPrayer(prefs, i);
      final b = PrayerReminderPrefs.minutesBeforeSecondaryForPrayer(prefs, i);
      total += _uniqueOffsets(a, b).length;
    }
    return total;
  }

  static List<PrayerTimesModel> _limitUpcomingDaysForPlatform({
    required SharedPreferences prefs,
    required List<PrayerTimesModel> days,
  }) {
    if (!Platform.isIOS || days.isEmpty) return days;
    final perDayAlerts = _iosAlertsPerDay(prefs);
    if (perDayAlerts <= 0) return days.take(1).toList();
    var maxDays = _iosPrayerPendingBudget ~/ perDayAlerts;
    if (maxDays < 1) maxDays = 1;
    if (days.length <= maxDays) return days;
    return days.take(maxDays).toList();
  }

  static bool _hasAnySchedulableSlotInSingleDay({
    required DateTime day,
    required List<String> times,
    required DateTime nextDay,
    required String? tomorrowFajrHm,
    required String? tomorrowImsakHm,
  }) {
    for (final hm in times) {
      if (_tryAtClock(day, hm) != null) return true;
    }
    if (tomorrowFajrHm != null &&
        _tryAtClock(nextDay, tomorrowFajrHm) != null) {
      return true;
    }
    if (tomorrowImsakHm != null &&
        _tryAtClock(nextDay, tomorrowImsakHm) != null) {
      return true;
    }
    return false;
  }

  static bool _hasAnySchedulableSlotInMultiDay(
    List<PrayerTimesModel> days, {
    required SharedPreferences prefs,
  }) {
    if (days.isEmpty) return false;
    final today = DateTime.now();
    final baseDay = DateTime(today.year, today.month, today.day);
    for (var dayIdx = 0; dayIdx < days.length; dayIdx++) {
      final shifted = AdminDevPrefs.applyPrayerOffset(prefs, days[dayIdx]);
      final calendarDay = _dayForModel(
        shifted,
        today: baseDay,
        fallbackOffsetFromToday: dayIdx,
      );
      if (calendarDay == null) continue;
      final values = <String>[
        shifted.fajr,
        shifted.sunrise,
        shifted.dhuhr,
        shifted.asr,
        shifted.maghrib,
        shifted.isha,
      ];
      for (final hm in values) {
        if (_tryAtClock(calendarDay, hm) != null) return true;
      }
    }
    return false;
  }

  static Future<NotificationDetails> _notificationDetailsForPrayer(
    SharedPreferences prefs,
    int prayerIndex,
  ) async {
    final localeCode = _localeCodeFromPrefs(prefs);
    if (PrayerReminderPrefs.hasUserSoundForSlot(prefs, prayerIndex)) {
      final path = await PrayerUserNotificationSoundStore.absolutePathForSlot(
        prefs,
        prayerIndex,
      );
      final iosName =
          PrayerUserNotificationSoundStore.iosBundledSoundFileNameForSlot(
            prefs,
            prayerIndex,
          );
      if (path != null && iosName != null && await File(path).exists()) {
        var useUserFile = true;
        if (Platform.isAndroid) {
          final content =
              await PrayerNotificationAndroidUri.contentUriForNotificationSound(
                path,
              );
          if (content == null || content.isEmpty) {
            useUserFile = false;
          }
        }
        if (useUserFile) {
          final labels = _prayerLabels(localeCode);
          final label = prayerIndex >= 0 && prayerIndex < labels.length
              ? labels[prayerIndex]
              : (localeCode == 'en'
                    ? 'Prayer'
                    : (localeCode == 'ar' ? 'الصلاة' : 'Vakit'));
          final ownSoundSuffix = localeCode == 'en'
              ? 'own sound'
              : (localeCode == 'ar' ? 'صوتك الخاص' : 'kendi sesin');
          return _userFileNotificationDetails(
            filePath: path,
            channelVer: PrayerReminderPrefs.userSoundChannelForSlot(
              prefs,
              prayerIndex,
            ),
            channelLabel: '$label — $ownSoundSuffix',
            channelIdSuffix: 's$prayerIndex',
            iosSoundFileName: iosName,
            localeCode: localeCode,
          );
        }
      }
    }
    final catIdx = PrayerReminderPrefs.notificationSoundIndexForPrayer(
      prefs,
      prayerIndex,
    );
    return await _notificationDetailsForSoundIndex(
      catIdx,
      localeCode: localeCode,
    );
  }

  static Future<NotificationDetails> _userFileNotificationDetails({
    required String filePath,
    required int channelVer,
    required String channelLabel,
    required String channelIdSuffix,
    required String iosSoundFileName,
    required String localeCode,
  }) async {
    final channelId = 'arin_ntf_uf_${channelVer}_$channelIdSuffix';
    var uriStr = Uri.file(filePath).toString();
    if (Platform.isAndroid) {
      final content =
          await PrayerNotificationAndroidUri.contentUriForNotificationSound(
            filePath,
          );
      if (content != null && content.isNotEmpty) {
        uriStr = content;
      }
      final android = arinLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          channelId,
          channelLabel,
          description: _channelDescription(localeCode),
          importance: Importance.max,
          playSound: true,
          sound: UriAndroidNotificationSound(uriStr),
        ),
      );
    }
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelLabel,
        channelDescription: _channelDescription(localeCode),
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: UriAndroidNotificationSound(uriStr),
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
        sound: iosSoundFileName,
      ),
    );
  }

  static Future<NotificationDetails> _notificationDetailsForSoundIndex(
    int soundIndex, {
    required String localeCode,
  }) async {
    // Android: indeks 0 = telefonun varsayılan bildirimi. URI alınamazsa yine
    // katalog ezanına düşme; kullanıcı açıkça sistem sesini seçmiş demektir.
    if (soundIndex == 0 && Platform.isAndroid) {
      final defaultUri =
          await PrayerNotificationAndroidUri.defaultNotificationSoundUri();
      if (defaultUri != null && defaultUri.isNotEmpty) {
        const channelId = 'arin_ntf_s0_sysdefault_v2';
        final channelName = localeCode == 'en'
            ? 'Prayer — phone default'
            : (localeCode == 'ar'
                  ? 'الصلاة — افتراضي الهاتف'
                  : 'Namaz — telefon varsayılanı');
        final android = arinLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await android?.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName,
            description: _channelDescription(localeCode),
            importance: Importance.max,
            playSound: true,
            sound: UriAndroidNotificationSound(defaultUri),
          ),
        );
        return NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: _channelDescription(localeCode),
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: UriAndroidNotificationSound(defaultUri),
          ),
          iOS: const DarwinNotificationDetails(presentSound: true),
        );
      }
    }
    final soundOpt = PrayerNotificationSounds.optionForIndex(soundIndex);
    AndroidNotificationSound? androidSound;
    if (Platform.isAndroid && soundIndex > 0) {
      final base = soundOpt.androidRawBaseName;
      if (base != null && base.isNotEmpty) {
        androidSound = RawResourceAndroidNotificationSound(base);
      }
    }
    final androidDetails = AndroidNotificationDetails(
      soundOpt.channelId,
      PrayerNotificationSounds.localizedChannelName(soundOpt, localeCode),
      channelDescription: _channelDescription(localeCode),
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: androidSound,
    );
    final iosDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: soundOpt.iosWavFileName,
    );
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Aynı dakikada iki uyarı oluşmasın. a = -1 → 1. uyarı kapalı.
  static List<int> _uniqueOffsets(int a, int b) {
    final out = <int>[];
    if (a >= 0) out.add(a);
    if (b >= 0 && (a < 0 || b != a)) out.add(b);
    // En erken tetiklenen uyarı (dakika değeri daha büyük) önce planlansın.
    // Android'de alarmClock modu ilk elemana verildiği için bu sıralama önemlidir.
    out.sort((x, y) => y.compareTo(x));
    return out;
  }

  static Future<void> _schedulePrayerOffsets({
    required DateTime slotStart,
    required DateTime now,
    required String label,
    required List<int> offsetsMinutes,
    required int idBase,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
    required String localeCode,
  }) async {
    const pastGrace = Duration(seconds: 5);
    final cutoff = now.subtract(pastGrace);
    for (var k = 0; k < offsetsMinutes.length; k++) {
      final m = offsetsMinutes[k];
      final when = slotStart.subtract(Duration(minutes: m));
      if (when.isBefore(cutoff)) continue;
      final id = idBase + k * 250000;
      final body = _prayerTimeBody(localeCode, minutesBefore: m, label: label);
      final scheduledTime = tz.TZDateTime.from(when, tz.local);
      // Samsung One UI (ve bazı MIUI/HyperOS sürümleri) aynı uygulamadan gelen
      // birden fazla `setAlarmClock()` çağrısında yalnızca en yakın olanı
      // "next alarm" slot'unda tutuyor; 1. tetiklendikten sonra 2.'yi promote
      // etmeden düşürebiliyor (kullanıcı gözlemi: 45 dk önceki uyarı çalıyor,
      // 30 dk önceki ne ses ne shade'e geliyor). Çözüm: yalnızca vakit başına
      // BİR alarmı `alarmClock` slot'unda tut (genelde chronological olarak
      // ilk tetiklenen = offsets sıralamasında daha büyük m), diğer(ler)ini
      // `exactAllowWhileIdle` ile ayrı AlarmManager kuyruğuna gönder. İkinci
      // yol da Doze muafiyetlidir (manifest'te SCHEDULE_EXACT_ALARM +
      // USE_EXACT_ALARM var) ama Samsung'un tek-slot konsolidasyonundan
      // etkilenmez. Status bar alarm ikonu yalnızca 1. uyarıyı gösterir —
      // kabul edilebilir trade-off; kritik olan ses + shade'in çalmasıdır.
      final AndroidScheduleMode preferredMode;
      if (Platform.isAndroid) {
        preferredMode = (k == 0)
            ? androidScheduleMode
            : AndroidScheduleMode.exactAllowWhileIdle;
      } else {
        preferredMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
      final ok = await _tryScheduleWithFallback(
        id: id,
        title: _prayerTimeTitle(localeCode, label),
        body: body,
        when: scheduledTime,
        details: details,
        preferredMode: preferredMode,
        slotStart: slotStart,
        offsetMinutes: m,
      );
      if (!ok) continue;
      _scheduledIds.add(id);
    }
  }

  /// 3 kademeli fallback: `alarmClock` → `exactAllowWhileIdle` →
  /// `inexactAllowWhileIdle`. Samsung OneUI 8 gibi OEM’ler
  /// `canScheduleExactAlarms()` false dönse bile `setAlarmClock()` kabul
  /// edebiliyor; bu yüzden önce en güçlü modu deneyip kademeli düşeriz.
  static Future<bool> _tryScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    required AndroidScheduleMode preferredMode,
    required DateTime slotStart,
    required int offsetMinutes,
  }) async {
    final attempts = <AndroidScheduleMode>[preferredMode];
    if (Platform.isAndroid) {
      if (preferredMode == AndroidScheduleMode.alarmClock &&
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
        if (Platform.isAndroid) {
          await _scheduleNativeAndroidPrayerNotification(
            id: id,
            title: title,
            body: body,
            when: when,
            details: details,
            scheduleMode: m,
            slotStart: slotStart,
            offsetMinutes: offsetMinutes,
          );
        } else {
          await arinLocalNotificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            when,
            details,
            androidScheduleMode: m,
          );
        }
        if (m != preferredMode) {
          debugPrint(
            'Prayer NTF: primary ${preferredMode.name} failed, succeeded with ${m.name} (id=$id)',
          );
        }
        return true;
      } catch (e) {
        lastError = e;
        debugPrint('Prayer NTF: ${m.name} failed for id=$id ($e)');
      }
    }
    debugPrint('Prayer NTF: all schedule modes failed for id=$id ($lastError)');
    return false;
  }

  static DateTime _staleCutoffForPrayerReminder({
    required DateTime scheduledAt,
    required DateTime slotStart,
    required int offsetMinutes,
  }) {
    if (offsetMinutes <= 0) {
      return slotStart.add(const Duration(minutes: 10));
    }
    final reminderGrace = scheduledAt.add(const Duration(minutes: 2));
    return reminderGrace.isBefore(slotStart) ? reminderGrace : slotStart;
  }

  static Future<void> _scheduleNativeAndroidPrayerNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    required AndroidScheduleMode scheduleMode,
    required DateTime slotStart,
    required int offsetMinutes,
  }) async {
    final androidDetails = details.android;
    final channelId = androidDetails?.channelId;
    if (channelId == null || channelId.isEmpty) {
      throw StateError(
        'Android notification channel missing for prayer id=$id',
      );
    }
    final scheduledAt = DateTime.fromMillisecondsSinceEpoch(
      when.millisecondsSinceEpoch,
    );
    final expiresAt = _staleCutoffForPrayerReminder(
      scheduledAt: scheduledAt,
      slotStart: slotStart,
      offsetMinutes: offsetMinutes,
    );
    await _nativePrayerNotifications.invokeMethod<void>('schedule', {
      'id': id,
      'title': title,
      'body': body,
      'channelId': channelId,
      'playSound': androidDetails?.playSound ?? true,
      ..._nativeAndroidSoundPayload(androidDetails?.sound),
      'scheduledAtMs': scheduledAt.millisecondsSinceEpoch,
      'expiresAtMs': expiresAt.millisecondsSinceEpoch,
      'mode': scheduleMode.name,
    });
  }

  static Map<String, Object?> _nativeAndroidSoundPayload(
    AndroidNotificationSound? sound,
  ) {
    if (sound is RawResourceAndroidNotificationSound) {
      return <String, Object?>{'soundType': 'raw', 'sound': sound.sound};
    }
    if (sound is UriAndroidNotificationSound) {
      return <String, Object?>{'soundType': 'uri', 'sound': sound.sound};
    }
    return const <String, Object?>{'soundType': 'default'};
  }

  static DateTime? _tryAtClock(DateTime day, String hm) {
    final p = hm.split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  static int _idFor(DateTime day, int prayerIndex) {
    final yyyymmdd = day.year * 10000 + day.month * 100 + day.day;
    return 9100000 + yyyymmdd * 10 + prayerIndex;
  }

  /// İlk açılışta: Android 13+ bildirim + tam zamanlı alarm izinlerini ister;
  /// iOS bildirim izinlerini ister. Arınma / namaz planlamasından önce çağrılmalı.
  ///
  /// Battery optimization muafiyeti burada istenmez — kullanıcıyı ana girişte
  /// 3 üst üste dialog’a boğmamak için ayrı bir CTA (Bildirimler sayfası) ile
  /// ister. Muafiyet olmadan da `alarmClock` modu çoğu cihazda çalışır.
  static Future<void> promptLocalNotificationPermissions() async {
    if (!supported) return;
    await init();
    await AppLocalNotificationScheduler.init();
  }

  /// Önbellek yoksa ağdan vakitleri alır; namaz hatırlatıcıları açıksa 7
  /// günlük pencere planlar — kullanıcı uygulamayı bir hafta açmasa bile
  /// bildirimler kesintisiz gelir. [promptLocalNotificationPermissions]
  /// ayrıca çağrılmalıdır.
  ///
  /// [force] true ise resume-throttle by-pass edilir (kullanıcı ayar değişikliği
  /// / admin aksiyonu). Foreground tekrarlarında `false` bırakılmalıdır.
  ///
  /// Başarı yolu:
  ///   1. `PrayerServiceResolver.fetchUpcomingDays(days: 7)` ile Diyanet
  ///      (Türkiye) veya Aladhan calendar endpoint'inden 7 gün alınır.
  ///   2. Liste doluysa multi-day plan.
  ///   3. Liste boşsa eski tek-gün davranışına (bugün + ertesi İmsak)
  ///      otomatik düşer — en kötü senaryoda bile bugünün bildirimleri
  ///      planlanır.
  static Future<void> ensurePrayerNotificationsIfEnabled({
    required SharedPreferences prefs,
    required AladhanService aladhan,
    required LocationService location,
    bool force = false,
  }) async {
    if (!supported) return;
    try {
      await init(prefs: prefs);
      if (!PrayerReminderPrefs.isEnabled(prefs)) return;
      await PrayerReminderPrefs.ensurePerPrayerPrefsReady(prefs);

      // Multi-day path: 7 günlük tam pencere. Resolver Türkiye'de Diyanet
      // (tek ağ isteği — 30 gün payload cache'li), dışarıda Aladhan
      // calendar endpoint'ini kullanır.
      final resolver = PrayerServiceResolver(
        diyanet: DiyanetPrayerService(),
        aladhan: aladhan,
        location: location,
      );
      List<PrayerTimesModel> upcoming = const <PrayerTimesModel>[];
      try {
        upcoming = await resolver.fetchUpcomingDays(days: 7);
      } catch (e) {
        debugPrint('ensurePrayerNotificationsIfEnabled upcoming fetch: $e');
      }

      if (upcoming.isNotEmpty) {
        // İlk eleman bugünü temsil eder; tek-gün API'si için gerekli ama
        // multi-day path'ta yalnız imza uyumu için geçiriyoruz.
        final todayModel = upcoming.first;
        await reschedule(
          prefs: prefs,
          model: todayModel,
          upcomingDays: upcoming,
          force: force,
        );
        await AdminNotificationDiagnosticsLog.append(
          prefs,
          source: 'prayer',
          action: 'ensure_enabled',
          outcome: 'ok',
          details: <String, Object?>{
            'city': location.savedCity,
            'days': upcoming.length,
            'force': force,
            'multi_day': true,
          },
        );
        return;
      }

      // Fallback: tek-gün yolu (eski davranış). Ağ + cache birleşik başarısızlık
      // durumunda bile en azından bugünü kurtarır.
      var model = aladhan.tryLoadTodayCached(
        city: location.savedCity,
        country: location.savedCountry,
        lat: location.savedLat,
        lon: location.savedLon,
      );

      if (model == null) {
        try {
          await location.syncPrayerLocation(forceRefresh: false);
          final lat = location.savedLat;
          final lon = location.savedLon;
          if (lat != null && lon != null) {
            model = await aladhan.fetchByCoordinates(
              latitude: lat,
              longitude: lon,
              cityLabel: location.savedCity,
            );
          } else {
            model = await aladhan.fetchByCity(
              city: location.savedCity,
              country: location.savedCountry,
            );
          }
        } catch (e, st) {
          debugPrint('ensurePrayerNotificationsIfEnabled fetch: $e\n$st');
          model = aladhan.tryLoadTodayCachedAnyScope();
          if (model == null) return;
        }
      }

      final shifted = AdminDevPrefs.applyPrayerOffset(prefs, model);
      await reschedule(
        prefs: prefs,
        model: shifted,
        tomorrowFajrHm: shifted.fajr,
        tomorrowImsakHm: shifted.sunrise,
        force: force,
      );
      await AdminNotificationDiagnosticsLog.append(
        prefs,
        source: 'prayer',
        action: 'ensure_enabled',
        outcome: 'ok',
        details: <String, Object?>{
          'city': location.savedCity,
          'force': force,
          'multi_day': false,
        },
      );
    } catch (e, st) {
      debugPrint('ensurePrayerNotificationsIfEnabled: $e\n$st');
      await AdminNotificationDiagnosticsLog.append(
        prefs,
        source: 'prayer',
        action: 'ensure_enabled',
        outcome: 'error',
        details: <String, Object?>{'error': '$e', 'force': force},
      );
    }
  }

  static Future<bool> requestPermissions() async {
    if (!supported) return false;
    await init();
    return requestLocalNotificationRuntimePermissions(
      arinLocalNotificationsPlugin,
    );
  }

  /// Admin: mevcut namaz bildirimi ses/kanal yolunu anında gösterir.
  /// Başarı: `null`. Hata: kısa kullanıcı mesajı.
  static Future<String?> showImmediateTestPrayerNotification(
    SharedPreferences prefs, {
    int prayerIndexForSound = 0,
  }) async {
    final localeCode = _localeCodeFromPrefs(prefs);
    if (!supported) return _testUnsupportedMessage(localeCode);
    await init();
    final allowed = await requestLocalNotificationRuntimePermissions(
      arinLocalNotificationsPlugin,
      policy: LocalNotificationPermissionPolicy.notificationOnly,
    );
    if (!allowed) {
      return _testPermissionRequiredMessage(localeCode);
    }
    try {
      final details = await _notificationDetailsForPrayer(
        prefs,
        prayerIndexForSound,
      );
      await arinLocalNotificationsPlugin.show(
        9199991,
        _testTitle(localeCode),
        _testBody(localeCode),
        details,
      );
      return null;
    } catch (e, st) {
      debugPrint('showImmediateTestPrayerNotification: $e\n$st');
      return _testShowError(localeCode, e);
    }
  }
}
