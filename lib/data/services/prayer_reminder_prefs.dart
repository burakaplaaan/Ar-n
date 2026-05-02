// Namaz ezan / vakit hatırlatıcı tercihleri (SharedPreferences).
// 6 satır: 0=İmsak, 1=Güneş, 2=Öğle…5=Yatsı.

import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_notification_sounds.dart';
import 'prayer_user_notification_sound_store.dart';

abstract final class PrayerReminderPrefs {
  static const _kSoundIndex = 'prayer_reminder_sound_index';
  static const _kOldSoundSabahLegacy = 'prayer_reminder_sound_sabah';
  static const _kOldSoundImsakLegacy = 'prayer_reminder_sound_imsak';
  static const _kUserFajrExt = 'prayer_reminder_user_fajr_ext';
  static const _kUserImsakExt = 'prayer_reminder_user_imsak_ext';
  static const _kUserFajrCh = 'prayer_reminder_user_fajr_ch';
  static const _kUserImsakCh = 'prayer_reminder_user_imsak_ch';
  static const _kPerPrayerNtfSoundMigrated =
      'prayer_reminder_ntf_per_slot_migrated_v1';
  static const _kMigratedNtfUserFiles =
      'prayer_reminder_ntf_migrated_user_files';
  static const _kEnabled = 'prayer_reminder_enabled';
  static const _kMinutesBefore = 'prayer_reminder_minutes_before';
  static const _kMinutesBefore2 = 'prayer_reminder_minutes_before_2';
  static const _kSabahFirstOrderDone = 'prayer_reminder_sabah_first_order_done';
  static const _kSecondExactTimeMigrationDone =
      'prayer_reminder_second_exact_time_migration_v1';

  static const int slotCount = 6;
  static const int _defaultEarlyMinutes = 5;
  static const int _defaultSecondMinutes = 1;
  static const int _sunriseSlotIndex = 1;

  /// 1. uyarı: -1 = kapalı, 0 = tam vakitte, sonra dakika önce.
  static const List<int> pickerEarlyValues = [
    -1,
    0,
    1,
    5,
    10,
    15,
    20,
    25,
    30,
    45,
    60,
  ];

  /// 2. uyarı: -1 = kapalı, 0 = tam vakitte, aksi dakika önce.
  static const List<int> pickerSecondValues = [
    -1,
    0,
    1,
    5,
    10,
    15,
    20,
    25,
    30,
    45,
    60,
  ];

  static String _earlyKey(int i) => 'prayer_reminder_early_$i';
  static String _secondKey(int i) => 'prayer_reminder_second_$i';

  static String _ntfSoundKey(int i) => 'prayer_reminder_ntf_sound_$i';
  static String _userSlotExtKey(int i) => 'prayer_reminder_user_slot_${i}_ext';
  static String _userSlotChKey(int i) => 'prayer_reminder_user_slot_${i}_ch';

  /// Etkinlik kararı:
  /// 1) Kullanıcı anahtarı açıkça set etmişse onu kullan.
  /// 2) Eski sürümden gelen tercih/kanıt anahtarları varsa "açık" varsay.
  /// 3) Yeni kurulumda (hiç sinyal yoksa) varsayılan "kapalı".
  ///
  /// Böylece:
  /// - Yeni kullanıcı bildirimleri bilinçli opt-in ile açar.
  /// - Mevcut kullanıcılar güncellemede sessizce "kapanmış" hissetmez.
  static bool isEnabled(SharedPreferences p) {
    final explicit = p.getBool(_kEnabled);
    if (explicit != null) return explicit;
    return _hasLegacyEnabledSignals(p);
  }

  static bool _hasLegacyEnabledSignals(SharedPreferences p) {
    // Eski global anahtarlar.
    if (p.containsKey(_kMinutesBefore) ||
        p.containsKey(_kMinutesBefore2) ||
        p.containsKey(_kSoundIndex) ||
        p.containsKey(_kOldSoundSabahLegacy) ||
        p.containsKey(_kOldSoundImsakLegacy) ||
        p.containsKey(_kUserFajrExt) ||
        p.containsKey(_kUserImsakExt) ||
        p.containsKey(_kUserFajrCh) ||
        p.containsKey(_kUserImsakCh)) {
      return true;
    }
    // Slot-bazlı yeni anahtarlar.
    for (var i = 0; i < slotCount; i++) {
      if (p.containsKey(_earlyKey(i)) ||
          p.containsKey(_secondKey(i)) ||
          p.containsKey(_ntfSoundKey(i)) ||
          p.containsKey(_userSlotExtKey(i)) ||
          p.containsKey(_userSlotChKey(i))) {
        return true;
      }
    }
    return false;
  }

  static Future<void> setEnabled(SharedPreferences p, bool v) =>
      p.setBool(_kEnabled, v);

  static int _maxSoundIndex() => PrayerNotificationSounds.options.length - 1;

  /// Eski tek “genel” indeks (taşıma öncesi). Yeni kod [notificationSoundIndexForPrayer] kullanır.
  static int notificationSoundIndex(SharedPreferences p) {
    final v = p.getInt(_kSoundIndex);
    if (v == null || v < 0) {
      return PrayerNotificationSounds.defaultCatalogSoundIndex;
    }
    return v.clamp(0, _maxSoundIndex());
  }

  /// [prayerIndex] 0…5 — o vakit için katalog sesi (0 = telefon varsayılanı).
  static int notificationSoundIndexForPrayer(
    SharedPreferences p,
    int prayerIndex,
  ) {
    assert(prayerIndex >= 0 && prayerIndex < slotCount);
    final v = p.getInt(_ntfSoundKey(prayerIndex));
    if (v != null) return v.clamp(0, _maxSoundIndex());
    return notificationSoundIndex(p);
  }

  static Future<void> setNotificationSoundIndexForPrayer(
    SharedPreferences p,
    int prayerIndex,
    int index,
  ) => p.setInt(_ntfSoundKey(prayerIndex), index.clamp(0, _maxSoundIndex()));

  /// Tüm vakitlere aynı katalog sesini yazar (toplu / eski API uyumu).
  static Future<void> setNotificationSoundIndex(
    SharedPreferences p,
    int index,
  ) async {
    final v = index.clamp(0, _maxSoundIndex());
    await p.setInt(_kSoundIndex, v);
    for (var i = 0; i < slotCount; i++) {
      await p.setInt(_ntfSoundKey(i), v);
    }
  }

  static String? userSoundExtForSlot(SharedPreferences p, int slot) =>
      p.getString(_userSlotExtKey(slot));

  static bool hasUserSoundForSlot(SharedPreferences p, int slot) =>
      (userSoundExtForSlot(p, slot) ?? '').isNotEmpty;

  static int userSoundChannelForSlot(SharedPreferences p, int slot) =>
      p.getInt(_userSlotChKey(slot)) ?? 0;

  static Future<void> setUserSoundExtForSlot(
    SharedPreferences p,
    int slot,
    String ext,
  ) => p.setString(_userSlotExtKey(slot), ext);

  static Future<void> bumpUserSoundChannelForSlot(
    SharedPreferences p,
    int slot,
  ) async {
    final v = userSoundChannelForSlot(p, slot) + 1;
    await p.setInt(_userSlotChKey(slot), v);
  }

  static Future<void> clearUserSoundSlot(SharedPreferences p, int slot) async {
    await p.remove(_userSlotExtKey(slot));
  }

  // ── Eski Sabah / İmsak anahtarları (sadece taşıma sırasında okunur) ──

  static String? userSoundFajrExt(SharedPreferences p) =>
      p.getString(_kUserFajrExt);

  static String? userSoundImsakExt(SharedPreferences p) =>
      p.getString(_kUserImsakExt);

  static Future<void> migratePerPrayerNotificationSoundsIfNeeded(
    SharedPreferences p,
  ) async {
    if (p.getBool(_kPerPrayerNtfSoundMigrated) ?? false) return;

    final legacyIdx = p.getInt(_kSoundIndex);
    final v = (legacyIdx == null || legacyIdx < 0)
        ? PrayerNotificationSounds.defaultCatalogSoundIndex
        : legacyIdx.clamp(0, _maxSoundIndex());
    for (var i = 0; i < slotCount; i++) {
      await p.setInt(_ntfSoundKey(i), v);
    }

    final slot0 = p.getString(_userSlotExtKey(0)) ?? '';
    if (slot0.isEmpty) {
      final e0 = p.getString(_kUserFajrExt);
      if (e0 != null && e0.isNotEmpty) {
        await p.setString(_userSlotExtKey(0), e0);
        await p.setInt(_userSlotChKey(0), p.getInt(_kUserFajrCh) ?? 0);
      }
    }

    final slot1 = p.getString(_userSlotExtKey(1)) ?? '';
    if (slot1.isEmpty) {
      final e1 = p.getString(_kUserImsakExt);
      if (e1 != null && e1.isNotEmpty) {
        await p.setString(_userSlotExtKey(1), e1);
        await p.setInt(_userSlotChKey(1), p.getInt(_kUserImsakCh) ?? 0);
      }
    }

    await p.setBool(_kPerPrayerNtfSoundMigrated, true);
  }

  static int _snap(int value, List<int> allowed) {
    if (allowed.contains(value)) return value;
    var best = allowed.first;
    var bestD = 9999;
    for (final x in allowed) {
      final d = (x - value).abs();
      if (d < bestD) {
        bestD = d;
        best = x;
      }
    }
    return best;
  }

  /// İlk kurulum, 5→6 genişletme veya eski “İmsak üstte” sürümünden tek seferlik takas.
  static Future<void> ensurePerPrayerPrefsReady(SharedPreferences p) async {
    final pinFreshInstallDisabled =
        p.getBool(_kEnabled) == null && !_hasLegacyEnabledSignals(p);

    await migratePerPrayerNotificationSoundsIfNeeded(p);
    await PrayerUserNotificationSoundStore.migrateLegacyDiskFilesIfNeeded(p);

    Future<void> finishInit() async {
      if (pinFreshInstallDisabled) {
        await p.setBool(_kEnabled, false);
      }
    }

    if (!(p.getBool(_kMigratedNtfUserFiles) ?? false)) {
      await p.remove(_kOldSoundSabahLegacy);
      await p.remove(_kOldSoundImsakLegacy);
      await p.setBool(_kMigratedNtfUserFiles, true);
    }

    Future<void> migrateSecondZeroToOffIfNeeded() async {
      if (p.getBool(_kSecondExactTimeMigrationDone) ?? false) return;
      for (var i = 0; i < slotCount; i++) {
        if (p.getInt(_secondKey(i)) == 0) {
          await p.setInt(_secondKey(i), -1);
        }
      }
      await p.setBool(_kSecondExactTimeMigrationDone, true);
    }

    if (p.getInt(_earlyKey(5)) != null) {
      if (!(p.getBool(_kSabahFirstOrderDone) ?? false)) {
        final e0 = p.getInt(_earlyKey(0));
        final e1 = p.getInt(_earlyKey(1));
        final s0 = p.getInt(_secondKey(0));
        final s1 = p.getInt(_secondKey(1));
        if (e0 != null && e1 != null) {
          await p.setInt(_earlyKey(0), e1);
          await p.setInt(_earlyKey(1), e0);
        }
        if (s0 != null && s1 != null) {
          await p.setInt(_secondKey(0), s1);
          await p.setInt(_secondKey(1), s0);
        }
        await p.setBool(_kSabahFirstOrderDone, true);
      }
      await migrateSecondZeroToOffIfNeeded();
      await finishInit();
      return;
    }

    if (p.getInt(_earlyKey(0)) != null) {
      // Eski 5 satır (0=Sabah…4=Yatsı): İmsak için 1. sıraya ekle, öğle…yatsı kay.
      for (var i = 4; i >= 1; i--) {
        final e = p.getInt(_earlyKey(i));
        final s = p.getInt(_secondKey(i));
        if (e != null) {
          await p.setInt(_earlyKey(i + 1), _snap(e, pickerEarlyValues));
        }
        if (s != null) {
          await p.setInt(_secondKey(i + 1), _snap(s, pickerSecondValues));
        }
      }
      await p.setInt(_earlyKey(1), _snap(-1, pickerEarlyValues));
      await p.setInt(_secondKey(1), _snap(-1, pickerSecondValues));
      await p.setBool(_kSabahFirstOrderDone, true);
      await migrateSecondZeroToOffIfNeeded();
      await finishInit();
      return;
    }

    final hadLegacy =
        p.containsKey(_kMinutesBefore) || p.containsKey(_kMinutesBefore2);
    final legacyA = p.getInt(_kMinutesBefore);
    final legacyB = p.getInt(_kMinutesBefore2);

    final earlySeed = legacyA ?? _defaultEarlyMinutes;
    final secondSeed = hadLegacy
        ? ((legacyB ?? 0) <= 0 ? -1 : legacyB!)
        : _defaultSecondMinutes;

    final e = _snap(earlySeed, pickerEarlyValues);
    final s = _snap(secondSeed, pickerSecondValues);

    for (var i = 0; i < slotCount; i++) {
      final isSunrise = i == _sunriseSlotIndex;
      await p.setInt(_earlyKey(i), isSunrise ? -1 : e);
      await p.setInt(_secondKey(i), isSunrise ? -1 : s);
    }
    await p.setBool(_kSabahFirstOrderDone, true);
    await migrateSecondZeroToOffIfNeeded();
    await finishInit();
  }

  static int minutesBeforeForPrayer(SharedPreferences p, int prayerIndex) {
    assert(prayerIndex >= 0 && prayerIndex < slotCount);
    final v = p.getInt(_earlyKey(prayerIndex));
    if (v != null) return _snap(v, pickerEarlyValues);
    final legacy = p.getInt(_kMinutesBefore);
    if (legacy != null) return _snap(legacy, pickerEarlyValues);
    if (prayerIndex == _sunriseSlotIndex) return -1;
    return _defaultEarlyMinutes;
  }

  static int minutesBeforeSecondaryForPrayer(
    SharedPreferences p,
    int prayerIndex,
  ) {
    assert(prayerIndex >= 0 && prayerIndex < slotCount);
    final v = p.getInt(_secondKey(prayerIndex));
    if (v != null) return _snap(v, pickerSecondValues);
    final legacy = p.getInt(_kMinutesBefore2);
    if (legacy != null) {
      if (legacy <= 0) return -1;
      return _snap(legacy, pickerSecondValues);
    }
    if (prayerIndex == _sunriseSlotIndex) return -1;
    return _defaultSecondMinutes;
  }

  static Future<void> setMinutesBeforeForPrayer(
    SharedPreferences p,
    int prayerIndex,
    int minutes,
  ) => p.setInt(_earlyKey(prayerIndex), _snap(minutes, pickerEarlyValues));

  static Future<void> setMinutesBeforeSecondaryForPrayer(
    SharedPreferences p,
    int prayerIndex,
    int minutes,
  ) => p.setInt(_secondKey(prayerIndex), _snap(minutes, pickerSecondValues));

  // ── Eski global API (tercih migrasyonu / dışarıdan okuma gerekmiyorsa kullanılmaz) ──

  static int minutesBefore(SharedPreferences p) => minutesBeforeForPrayer(p, 0);

  static int minutesBeforeSecondary(SharedPreferences p) =>
      minutesBeforeSecondaryForPrayer(p, 0);

  static Future<void> setMinutesBefore(SharedPreferences p, int m) async {
    final v = _snap(m, pickerEarlyValues);
    for (var i = 0; i < slotCount; i++) {
      await p.setInt(_earlyKey(i), v);
    }
    await p.setInt(_kMinutesBefore, v);
  }

  static Future<void> setMinutesBeforeSecondary(
    SharedPreferences p,
    int m,
  ) async {
    final v = _snap(m, pickerSecondValues);
    for (var i = 0; i < slotCount; i++) {
      await p.setInt(_secondKey(i), v);
    }
    await p.setInt(_kMinutesBefore2, v);
  }
}
