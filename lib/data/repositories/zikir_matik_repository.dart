// lib/data/repositories/zikir_matik_repository.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/zikir_matik_record.dart';
import '../models/zikir_matik_tur_log.dart';

abstract final class ZikirMatikPrefsKeys {
  static const recordsJson = 'zikir_matik_records_json';
  static const customPhrasesJson = 'zikir_matik_custom_phrases_json';
  static const turLogsJson = 'zikir_matik_tur_logs_json';
  static const sessionTotal = 'zikir_matik_session_total';
  static const sessionRound = 'zikir_matik_session_round';
  static const sessionTur = 'zikir_matik_session_tur';
  static const sessionPhrase = 'zikir_matik_session_phrase';
  static const sessionTarget = 'zikir_matik_session_target';
  static const soundTick = 'zikir_matik_sound_tick';
  static const vibrateTarget = 'zikir_matik_vibrate_target';
}

class ZikirMatikRepository {
  ZikirMatikRepository(this._prefs);

  final SharedPreferences _prefs;

  static const int _maxCustomPhrases = 24;

  List<ZikirMatikRecord> loadRecords() {
    final raw = _prefs.getString(ZikirMatikPrefsKeys.recordsJson);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = list
          .map((e) => ZikirMatikRecord.fromJson(e as Map<String, dynamic>?))
          .whereType<ZikirMatikRecord>()
          .toList();
      out.sort((a, b) => b.savedAtMillis.compareTo(a.savedAtMillis));
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeRecords(List<ZikirMatikRecord> items) async {
    await _prefs.setString(
      ZikirMatikPrefsKeys.recordsJson,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addRecord(ZikirMatikRecord r) async {
    final all = loadRecords();
    all.insert(0, r);
    await _writeRecords(all);
  }

  Future<void> deleteRecord(String id) async {
    final all = loadRecords().where((e) => e.id != id).toList();
    await _writeRecords(all);
  }

  List<String> loadCustomPhrases() {
    final raw = _prefs.getString(ZikirMatikPrefsKeys.customPhrasesJson);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = <String>[];
      for (final item in list) {
        if (item is! String) continue;
        final phrase = item.trim();
        if (phrase.isEmpty) continue;
        if (out.any((e) => e.toLowerCase() == phrase.toLowerCase())) continue;
        out.add(phrase);
        if (out.length >= _maxCustomPhrases) break;
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeCustomPhrases(List<String> items) async {
    await _prefs.setString(
      ZikirMatikPrefsKeys.customPhrasesJson,
      jsonEncode(items),
    );
  }

  Future<void> saveCustomPhrase(String rawPhrase) async {
    final phrase = rawPhrase.trim();
    if (phrase.isEmpty) return;
    final all = loadCustomPhrases()
        .where((e) => e.toLowerCase() != phrase.toLowerCase())
        .toList();
    all.insert(0, phrase);
    while (all.length > _maxCustomPhrases) {
      all.removeLast();
    }
    await _writeCustomPhrases(all);
  }

  Future<void> deleteCustomPhrase(String rawPhrase) async {
    final phrase = rawPhrase.trim();
    if (phrase.isEmpty) return;
    final all = loadCustomPhrases()
        .where((e) => e.toLowerCase() != phrase.toLowerCase())
        .toList();
    await _writeCustomPhrases(all);
  }

  static const int _maxTurLogs = 800;

  List<ZikirMatikTurLog> loadTurLogs() {
    final raw = _prefs.getString(ZikirMatikPrefsKeys.turLogsJson);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = list
          .map((e) => ZikirMatikTurLog.fromJson(e as Map<String, dynamic>?))
          .whereType<ZikirMatikTurLog>()
          .toList();
      out.sort((a, b) => b.recordedAtMillis.compareTo(a.recordedAtMillis));
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeTurLogs(List<ZikirMatikTurLog> items) async {
    await _prefs.setString(
      ZikirMatikPrefsKeys.turLogsJson,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> appendTurLog(ZikirMatikTurLog log) async {
    final all = loadTurLogs();
    all.insert(0, log);
    while (all.length > _maxTurLogs) {
      all.removeLast();
    }
    await _writeTurLogs(all);
  }

  Future<void> deleteTurLog(String id) async {
    final all = loadTurLogs().where((e) => e.id != id).toList();
    await _writeTurLogs(all);
  }

  ({int total, int round, int tur, String phrase, int target}) loadSession() {
    return (
      total: _prefs.getInt(ZikirMatikPrefsKeys.sessionTotal) ?? 0,
      round: _prefs.getInt(ZikirMatikPrefsKeys.sessionRound) ?? 0,
      tur: _prefs.getInt(ZikirMatikPrefsKeys.sessionTur) ?? 1,
      phrase: _prefs.getString(ZikirMatikPrefsKeys.sessionPhrase) ?? '',
      target: _prefs.getInt(ZikirMatikPrefsKeys.sessionTarget) ?? 33,
    );
  }

  Future<void> saveSession({
    required int total,
    required int round,
    required int tur,
    required String phrase,
    required int target,
  }) async {
    await _prefs.setInt(ZikirMatikPrefsKeys.sessionTotal, total);
    await _prefs.setInt(ZikirMatikPrefsKeys.sessionRound, round);
    await _prefs.setInt(ZikirMatikPrefsKeys.sessionTur, tur);
    await _prefs.setString(ZikirMatikPrefsKeys.sessionPhrase, phrase);
    await _prefs.setInt(ZikirMatikPrefsKeys.sessionTarget, target);
  }

  bool get soundTickEnabled =>
      _prefs.getBool(ZikirMatikPrefsKeys.soundTick) ?? false;

  bool get vibrateOnTargetEnabled =>
      _prefs.getBool(ZikirMatikPrefsKeys.vibrateTarget) ?? true;

  Future<void> setSoundTick(bool v) async {
    await _prefs.setBool(ZikirMatikPrefsKeys.soundTick, v);
  }

  Future<void> setVibrateOnTarget(bool v) async {
    await _prefs.setBool(ZikirMatikPrefsKeys.vibrateTarget, v);
  }
}
