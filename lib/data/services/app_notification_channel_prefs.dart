// Arınma / içerik bildirim kanalları — SharedPreferences.
// Zamanlayıcı bağlandığında aynı anahtarlar okunur.

import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppNotificationChannelPrefs {
  static const _kArinmaDaily = 'ntf_arinma_daily_enabled';
  static const _kMilestone = 'ntf_arinma_milestone_enabled';
  static const _kTask = 'ntf_arinma_task_enabled';
  static const _kZikirQuote = 'ntf_zikir_quote_enabled';
  static const _kZikirQuoteMin = 'ntf_zikir_quote_minutes_from_midnight';
  static const _kArinmaAutoEnabledOnQuit = 'ntf_arinma_auto_enabled_on_quit_v1';

  /// Kaldırılan kanallar (v1.2.0 öncesi kurulumlarda set edilmiş olabilir).
  /// Migration'da false'a çevriliyor, bu anahtarlar artık okunmuyor.
  static const legacyKeyDailyWisdom = 'ntf_daily_wisdom_enabled';
  static const legacyKeyWeeklyInspire = 'ntf_inspire_weekly_enabled';

  /// Varsayılan zikir hatırlatıcısı: 09:30
  static const int defaultZikirQuoteMinutesFromMidnight = 9 * 60 + 30;

  static bool arinmaDailyEnabled(SharedPreferences p) =>
      p.getBool(_kArinmaDaily) ?? false;

  static Future<void> setArinmaDailyEnabled(SharedPreferences p, bool v) =>
      p.setBool(_kArinmaDaily, v);

  static bool milestoneEnabled(SharedPreferences p) =>
      p.getBool(_kMilestone) ?? false;

  static Future<void> setMilestoneEnabled(SharedPreferences p, bool v) =>
      p.setBool(_kMilestone, v);

  /// Arınma açılınca günlük + alışkanlık bildirimlerini açar.
  /// [force] sayaç yeni başladığında kullanılır. Aksi halde yalnızca bir kez
  /// çalışır — kullanıcı ayarlardan kapattıysa her açılışta tekrar açılmaz.
  static Future<bool> enableArinmaNotificationsForQuit(
    SharedPreferences p, {
    bool force = false,
  }) async {
    if (!force && (p.getBool(_kArinmaAutoEnabledOnQuit) ?? false)) {
      return false;
    }
    await setArinmaDailyEnabled(p, true);
    await setMilestoneEnabled(p, true);
    await p.setBool(_kArinmaAutoEnabledOnQuit, true);
    return true;
  }

  /// Aktif arınma varken eski genel görev hatırlatıcısı, yeni eşik
  /// bildirimleriyle çakışır.
  static bool shouldScheduleGenericTaskReminder(
    SharedPreferences p, {
    required bool hasActiveQuit,
  }) => taskReminderEnabled(p) && !hasActiveQuit;

  /// Aktif arınma varken eski günlük “arınma hatırlatıcısı” slot’u, yeni
  /// ilham / süre bildirimleriyle çakışır. Namaz sözü (slot 0) durur.
  static bool shouldScheduleGenericArinmaMotivation({
    required bool hasActiveQuit,
  }) => !hasActiveQuit;

  static bool taskReminderEnabled(SharedPreferences p) =>
      p.getBool(_kTask) ?? false;

  static Future<void> setTaskReminderEnabled(SharedPreferences p, bool v) =>
      p.setBool(_kTask, v);

  static bool zikirQuoteEnabled(SharedPreferences p) =>
      p.getBool(_kZikirQuote) ?? false;

  static Future<void> setZikirQuoteEnabled(SharedPreferences p, bool v) =>
      p.setBool(_kZikirQuote, v);

  static int zikirQuoteMinutesFromMidnight(SharedPreferences p) {
    final v = p.getInt(_kZikirQuoteMin);
    if (v == null) return defaultZikirQuoteMinutesFromMidnight;
    return v.clamp(0, 24 * 60 - 1);
  }

  static Future<void> setZikirQuoteMinutesFromMidnight(
    SharedPreferences p,
    int minutes,
  ) => p.setInt(_kZikirQuoteMin, minutes.clamp(0, 24 * 60 - 1));
}
