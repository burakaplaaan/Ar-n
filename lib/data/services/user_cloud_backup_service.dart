// Giriş yapmış kullanıcı için düşük maliyetli cihaz verisi yedekleme.
// Hızlı değişen/cache verileri yazmaz; küçük, kullanıcı kaynaklı tercihleri
// az sayıda Firestore dokümanında tutar.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/willpower_templates.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/utils/hive_boxes.dart';
import '../repositories/habit_repository.dart';
import '../models/kaza_tracking_state.dart';
import '../models/zikir_matik_record.dart';
import '../models/zikir_matik_tur_log.dart';
import '../repositories/kaza_tracking_repository.dart';
import '../repositories/zikir_matik_repository.dart';
import 'app_notification_channel_prefs.dart';
import 'location_service.dart';
import 'prayer_reminder_prefs.dart';

abstract final class UserCloudBackupService {
  static const _prefsLastPushMs = 'arin_user_cloud_backup_last_push_ms';
  static const _throttle = Duration(hours: 2);

  static const _maxZikirRecords = 300;
  static const _maxZikirTurLogs = 300;
  static const _maxSalatLogEntries = 2000;

  static DocumentReference<Map<String, dynamic>> _zikirRef(
    FirebaseFirestore fs,
    String uid,
  ) => fs.collection('users').doc(uid).collection('zikir_matik').doc('state');

  static DocumentReference<Map<String, dynamic>> _backupRef(
    FirebaseFirestore fs,
    String uid,
  ) => fs.collection('users').doc(uid).collection('user_backup').doc('state');

  static Future<void> syncAfterSignIn({
    required String uid,
    required SharedPreferences prefs,
  }) async {
    final pulled = await pullToLocal(uid: uid, prefs: prefs);
    if (!pulled) return;
    await pushFromLocal(uid: uid, prefs: prefs, force: true);
  }

  static Future<bool> pullToLocal({
    required String uid,
    required SharedPreferences prefs,
  }) async {
    if (!isFirebaseReady || uid.isEmpty) return false;
    try {
      final fs = FirebaseFirestore.instance;
      await _pullZikir(fs: fs, uid: uid, prefs: prefs);
      await _pullUserBackup(fs: fs, uid: uid, prefs: prefs);
      return true;
    } catch (e, st) {
      debugPrint('UserCloudBackupService pull: $e\n$st');
      return false;
    }
  }

  static Future<void> pushFromLocal({
    required String uid,
    required SharedPreferences prefs,
    bool force = false,
  }) async {
    if (!isFirebaseReady || uid.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force) {
      final last = prefs.getInt(_prefsLastPushMs) ?? 0;
      if (nowMs - last < _throttle.inMilliseconds) return;
    }

    try {
      final fs = FirebaseFirestore.instance;
      await _pushZikir(fs: fs, uid: uid, prefs: prefs, nowMs: nowMs);
      await _pushUserBackup(fs: fs, uid: uid, prefs: prefs, nowMs: nowMs);
      await prefs.setInt(_prefsLastPushMs, nowMs);
    } catch (e, st) {
      debugPrint('UserCloudBackupService push: $e\n$st');
    }
  }

  static Future<void> _pushZikir({
    required FirebaseFirestore fs,
    required String uid,
    required SharedPreferences prefs,
    required int nowMs,
  }) async {
    final repo = ZikirMatikRepository(prefs);
    final session = repo.loadSession();
    await _zikirRef(fs, uid).set({
      'schemaVersion': 1,
      'updatedAtMs': nowMs,
      'syncedAt': FieldValue.serverTimestamp(),
      'session': {
        'total': session.total,
        'round': session.round,
        'tur': session.tur,
        'phrase': session.phrase,
        'target': session.target,
      },
      'customPhrases': repo.loadCustomPhrases(),
      'records': repo
          .loadRecords()
          .take(_maxZikirRecords)
          .map((e) => e.toJson())
          .toList(growable: false),
      'turLogs': repo
          .loadTurLogs()
          .take(_maxZikirTurLogs)
          .map((e) => e.toJson())
          .toList(growable: false),
      'settings': {
        'soundTick': repo.soundTickEnabled,
        'vibrateTarget': repo.vibrateOnTargetEnabled,
      },
    }, SetOptions(merge: true));
  }

  static Future<void> _pullZikir({
    required FirebaseFirestore fs,
    required String uid,
    required SharedPreferences prefs,
  }) async {
    final snap = await _zikirRef(fs, uid).get();
    final data = snap.data();
    if (data == null || data.isEmpty) return;

    final repo = ZikirMatikRepository(prefs);
    final cloudSession = _asMap(data['session']);
    final localSession = repo.loadSession();
    if (_isEmptyZikirSession(localSession) && cloudSession.isNotEmpty) {
      await repo.saveSession(
        total: _asInt(cloudSession['total']),
        round: _asInt(cloudSession['round']),
        tur: _asInt(cloudSession['tur'], fallback: 1),
        phrase: (cloudSession['phrase'] as String?)?.trim() ?? '',
        target: _asInt(cloudSession['target'], fallback: 33).clamp(3, 999999),
      );
    }

    final records = _mergeZikirRecords(
      cloud: _zikirRecordsFrom(data['records']),
      local: repo.loadRecords(),
    );
    await repo.replaceRecords(records.take(_maxZikirRecords).toList());

    final phrases = _mergeStrings(
      cloud: _stringsFrom(data['customPhrases']),
      local: repo.loadCustomPhrases(),
    );
    await repo.replaceCustomPhrases(phrases);

    final turLogs = _mergeZikirTurLogs(
      cloud: _zikirTurLogsFrom(data['turLogs']),
      local: repo.loadTurLogs(),
    );
    await repo.replaceTurLogs(turLogs.take(_maxZikirTurLogs).toList());

    final settings = _asMap(data['settings']);
    if (!prefs.containsKey(ZikirMatikPrefsKeys.soundTick) &&
        settings['soundTick'] is bool) {
      await repo.setSoundTick(settings['soundTick'] as bool);
    }
    if (!prefs.containsKey(ZikirMatikPrefsKeys.vibrateTarget) &&
        settings['vibrateTarget'] is bool) {
      await repo.setVibrateOnTarget(settings['vibrateTarget'] as bool);
    }
  }

  static Future<void> _pushUserBackup({
    required FirebaseFirestore fs,
    required String uid,
    required SharedPreferences prefs,
    required int nowMs,
  }) async {
    await _backupRef(fs, uid).set({
      'schemaVersion': 1,
      'updatedAtMs': nowMs,
      'syncedAt': FieldValue.serverTimestamp(),
      'salatLogs': _exportSalatLogs(),
      'location': LocationService().exportBackupJson(),
      'notifications': _exportNotificationPrefs(prefs),
      'appPrefs': _exportAppPrefs(prefs),
      'kaza': _exportKaza(prefs),
    }, SetOptions(merge: true));
  }

  static Future<void> _pullUserBackup({
    required FirebaseFirestore fs,
    required String uid,
    required SharedPreferences prefs,
  }) async {
    final snap = await _backupRef(fs, uid).get();
    final data = snap.data();
    if (data == null || data.isEmpty) return;

    await _importSalatLogs(_asMap(data['salatLogs']));

    final location = _asMap(data['location']);
    if (location.isNotEmpty) {
      await LocationService().importBackupJson(location);
    }

    await _importNotificationPrefs(prefs, _asMap(data['notifications']));
    await _importAppPrefs(prefs, _asMap(data['appPrefs']));
    await _importKaza(prefs, _asMap(data['kaza']));
  }

  static Map<String, String> _exportSalatLogs() {
    final box = Hive.box<String>(HiveBoxes.salatLogs);
    final entries = <MapEntry<String, String>>[];
    for (final entry in box.toMap().entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (!_isValidSalatStorageEntry(key, value)) continue;
      entries.add(MapEntry(key, value));
    }
    entries.sort(
      (a, b) => _salatDateSuffix(b.key).compareTo(_salatDateSuffix(a.key)),
    );
    return Map<String, String>.fromEntries(entries.take(_maxSalatLogEntries));
  }

  static Future<void> _importSalatLogs(Map<String, dynamic> raw) async {
    if (raw.isEmpty) return;
    final box = Hive.box<String>(HiveBoxes.salatLogs);
    for (final entry in raw.entries) {
      final key = entry.key.trim();
      final value = entry.value as String?;
      if (!_isValidSalatStorageEntry(key, value)) continue;
      final local = box.get(key);
      await box.put(key, _mergeSalatBits(local, value!));
    }
  }

  static Map<String, dynamic> _exportNotificationPrefs(
    SharedPreferences prefs,
  ) {
    return {
      'prayerEnabled': PrayerReminderPrefs.isEnabled(prefs),
      'prayerSlots': [
        for (var i = 0; i < PrayerReminderPrefs.slotCount; i++)
          {
            'early': PrayerReminderPrefs.minutesBeforeForPrayer(prefs, i),
            'second': PrayerReminderPrefs.minutesBeforeSecondaryForPrayer(
              prefs,
              i,
            ),
            'soundIndex': PrayerReminderPrefs.notificationSoundIndexForPrayer(
              prefs,
              i,
            ),
          },
      ],
      'arinmaDaily': AppNotificationChannelPrefs.arinmaDailyEnabled(prefs),
      'milestone': AppNotificationChannelPrefs.milestoneEnabled(prefs),
      'taskReminder': AppNotificationChannelPrefs.taskReminderEnabled(prefs),
      'zikirQuote': AppNotificationChannelPrefs.zikirQuoteEnabled(prefs),
      'zikirQuoteMinutes':
          AppNotificationChannelPrefs.zikirQuoteMinutesFromMidnight(prefs),
    };
  }

  static Future<void> _importNotificationPrefs(
    SharedPreferences prefs,
    Map<String, dynamic> raw,
  ) async {
    if (raw.isEmpty) return;
    final prayerEnabled = raw['prayerEnabled'];
    if (prayerEnabled is bool) {
      await PrayerReminderPrefs.setEnabled(prefs, prayerEnabled);
    }

    final slots = raw['prayerSlots'];
    if (slots is List) {
      for (
        var i = 0;
        i < PrayerReminderPrefs.slotCount && i < slots.length;
        i++
      ) {
        final slot = _asMap(slots[i]);
        if (slot['early'] is num) {
          await PrayerReminderPrefs.setMinutesBeforeForPrayer(
            prefs,
            i,
            (slot['early'] as num).toInt(),
          );
        }
        if (slot['second'] is num) {
          await PrayerReminderPrefs.setMinutesBeforeSecondaryForPrayer(
            prefs,
            i,
            (slot['second'] as num).toInt(),
          );
        }
        if (slot['soundIndex'] is num) {
          await PrayerReminderPrefs.setNotificationSoundIndexForPrayer(
            prefs,
            i,
            (slot['soundIndex'] as num).toInt(),
          );
        }
      }
    }

    if (raw['arinmaDaily'] is bool) {
      await AppNotificationChannelPrefs.setArinmaDailyEnabled(
        prefs,
        raw['arinmaDaily'] as bool,
      );
    }
    if (raw['milestone'] is bool) {
      await AppNotificationChannelPrefs.setMilestoneEnabled(
        prefs,
        raw['milestone'] as bool,
      );
    }
    if (raw['taskReminder'] is bool) {
      await AppNotificationChannelPrefs.setTaskReminderEnabled(
        prefs,
        raw['taskReminder'] as bool,
      );
    }
    if (raw['zikirQuote'] is bool) {
      await AppNotificationChannelPrefs.setZikirQuoteEnabled(
        prefs,
        raw['zikirQuote'] as bool,
      );
    }
    if (raw['zikirQuoteMinutes'] is num) {
      await AppNotificationChannelPrefs.setZikirQuoteMinutesFromMidnight(
        prefs,
        (raw['zikirQuoteMinutes'] as num).toInt(),
      );
    }
  }

  static Map<String, dynamic> _exportAppPrefs(SharedPreferences prefs) => {
    if (prefs.getString('arin_app_locale') != null)
      'locale': prefs.getString('arin_app_locale'),
    'salatTrackingVisibleOnHome':
        prefs.getBool(WillpowerTemplates.salatVisibleOnHomePrefKey) ?? false,
    'salatTrackingPreinstalled':
        prefs.getBool(WillpowerTemplates.salatPreinstalledPrefKey) ?? false,
  };

  static Future<void> _importAppPrefs(
    SharedPreferences prefs,
    Map<String, dynamic> raw,
  ) async {
    final locale = (raw['locale'] as String?)?.trim().toLowerCase();
    if (locale == 'tr' || locale == 'en' || locale == 'ar') {
      await prefs.setString('arin_app_locale', locale!);
    }
    if (raw['salatTrackingVisibleOnHome'] is bool) {
      await HabitRepository.applyImportedSalatHomeVisibility(
        prefs,
        incomingVisible: raw['salatTrackingVisibleOnHome'] as bool,
        backupKnowsPreinstall: raw['salatTrackingPreinstalled'] == true,
      );
    }
    if (raw['salatTrackingPreinstalled'] == true) {
      await prefs.setBool(WillpowerTemplates.salatPreinstalledPrefKey, true);
    }
  }

  static Map<String, dynamic> _exportKaza(SharedPreferences prefs) {
    final s = KazaTrackingRepository(prefs).load();
    return {
      'sabah': s.sabah,
      'ogle': s.ogle,
      'ikindi': s.ikindi,
      'aksam': s.aksam,
      'yatsi': s.yatsi,
      'vitir': s.vitir,
      'isFemale': s.isFemale,
      if (s.birthDate != null)
        'birthMillis': s.birthDate!.millisecondsSinceEpoch,
      'pubertyAge': s.pubertyAge,
      'prayedDays': s.prayedDaysRecorded,
      'hasEverCalculated': s.hasEverCalculated,
      'hubEnabled': s.hubEnabled,
    };
  }

  static Future<void> _importKaza(
    SharedPreferences prefs,
    Map<String, dynamic> raw,
  ) async {
    if (raw.isEmpty) return;
    final hasMeaningfulData =
        _asInt(raw['sabah']) > 0 ||
        _asInt(raw['ogle']) > 0 ||
        _asInt(raw['ikindi']) > 0 ||
        _asInt(raw['aksam']) > 0 ||
        _asInt(raw['yatsi']) > 0 ||
        _asInt(raw['vitir']) > 0 ||
        raw['hasEverCalculated'] == true ||
        raw['hubEnabled'] == true;
    if (!hasMeaningfulData) return;

    final birthMillis = raw['birthMillis'] as num?;
    await KazaTrackingRepository(prefs).save(
      KazaTrackingState(
        sabah: _asInt(raw['sabah']),
        ogle: _asInt(raw['ogle']),
        ikindi: _asInt(raw['ikindi']),
        aksam: _asInt(raw['aksam']),
        yatsi: _asInt(raw['yatsi']),
        vitir: _asInt(raw['vitir']),
        isFemale: raw['isFemale'] as bool? ?? false,
        birthDate: birthMillis == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(birthMillis.toInt()),
        pubertyAge: _asInt(raw['pubertyAge']),
        prayedDaysRecorded: _asInt(raw['prayedDays']),
        hasEverCalculated: raw['hasEverCalculated'] as bool? ?? false,
        hubEnabled: raw['hubEnabled'] as bool? ?? false,
      ),
    );
  }

  static bool _isEmptyZikirSession(
    ({int total, int round, int tur, String phrase, int target}) s,
  ) {
    return s.total == 0 &&
        s.round == 0 &&
        s.tur <= 1 &&
        s.phrase.trim().isEmpty &&
        s.target == 33;
  }

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  static int _asInt(Object? raw, {int fallback = 0}) {
    if (raw is num) return raw.toInt();
    return fallback;
  }

  static List<String> _stringsFrom(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<ZikirMatikRecord> _zikirRecordsFrom(Object? raw) {
    if (raw is! List) return const <ZikirMatikRecord>[];
    return raw
        .map((e) => ZikirMatikRecord.fromJson(_asMap(e)))
        .whereType<ZikirMatikRecord>()
        .toList();
  }

  static List<ZikirMatikTurLog> _zikirTurLogsFrom(Object? raw) {
    if (raw is! List) return const <ZikirMatikTurLog>[];
    return raw
        .map((e) => ZikirMatikTurLog.fromJson(_asMap(e)))
        .whereType<ZikirMatikTurLog>()
        .toList();
  }

  static List<ZikirMatikRecord> _mergeZikirRecords({
    required List<ZikirMatikRecord> cloud,
    required List<ZikirMatikRecord> local,
  }) {
    final byId = <String, ZikirMatikRecord>{};
    for (final r in [...cloud, ...local]) {
      if (r.id.trim().isEmpty) continue;
      final existing = byId[r.id];
      if (existing == null || r.savedAtMillis > existing.savedAtMillis) {
        byId[r.id] = r;
      }
    }
    final out = byId.values.toList()
      ..sort((a, b) => b.savedAtMillis.compareTo(a.savedAtMillis));
    return out;
  }

  static List<ZikirMatikTurLog> _mergeZikirTurLogs({
    required List<ZikirMatikTurLog> cloud,
    required List<ZikirMatikTurLog> local,
  }) {
    final byId = <String, ZikirMatikTurLog>{};
    for (final r in [...cloud, ...local]) {
      if (r.id.trim().isEmpty) continue;
      final existing = byId[r.id];
      if (existing == null || r.recordedAtMillis > existing.recordedAtMillis) {
        byId[r.id] = r;
      }
    }
    final out = byId.values.toList()
      ..sort((a, b) => b.recordedAtMillis.compareTo(a.recordedAtMillis));
    return out;
  }

  static List<String> _mergeStrings({
    required List<String> cloud,
    required List<String> local,
  }) {
    final out = <String>[];
    for (final phrase in [...cloud, ...local]) {
      final t = phrase.trim();
      if (t.isEmpty) continue;
      if (out.any((e) => e.toLowerCase() == t.toLowerCase())) continue;
      out.add(t);
    }
    return out;
  }

  static bool _isValidSalatStorageEntry(String key, String? value) {
    return key.length > 11 &&
        value != null &&
        RegExp(r'^[01]{5}$').hasMatch(value) &&
        RegExp(r'\d{4}-\d{2}-\d{2}$').hasMatch(key);
  }

  static String _mergeSalatBits(String? local, String cloud) {
    if (local == null || !RegExp(r'^[01]{5}$').hasMatch(local)) return cloud;
    final out = StringBuffer();
    for (var i = 0; i < 5; i++) {
      out.write(local[i] == '1' || cloud[i] == '1' ? '1' : '0');
    }
    return out.toString();
  }

  static String _salatDateSuffix(String key) => key.substring(key.length - 10);
}
