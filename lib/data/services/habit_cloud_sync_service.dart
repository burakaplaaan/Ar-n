// lib/data/services/habit_cloud_sync_service.dart
// Giriş yapılmış kullanıcı: alışkanlık + logları Firestore'a yedekler (namaz vakti yok).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../models/habit_log_model.dart';
import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';

/// `users/{uid}/habits/{habitId}` ve `users/{uid}/habit_logs/{logKey}`
abstract final class HabitCloudSyncService {
  static const _batchSize = 400;
  static const _prefsLastPushMs = 'arin_habit_cloud_last_push_ms';
  static const _prefsDeletedHabitIds = 'arin_habit_cloud_deleted_habit_ids';
  static const _throttle = Duration(hours: 2);

  static Map<String, dynamic> _habitMap(HabitModel h) => {
        'id': h.id,
        'title': h.title,
        'type': h.type.name,
        'emoji': h.emoji,
        'createdAt': h.createdAt,
        'isArchived': h.isArchived,
        'templateId': h.templateId,
        'startedAtIso': h.startedAtIso,
        'commitmentText': h.commitmentText,
        'quitSubtype': h.quitSubtype,
        'quitMethod': h.quitMethod,
        'onboardingCompleted': h.onboardingCompleted,
        'quitClockStartedAtIso': h.quitClockStartedAtIso,
        'note': h.note,
        'customTarget': h.customTarget,
        'customUnit': h.customUnit,
        'customTrackingKind': h.customTrackingKind,
        'customFlexible': h.customFlexible,
        'customMinTarget': h.customMinTarget,
        'customRepeatCycle': h.customRepeatCycle,
        'syncedAt': FieldValue.serverTimestamp(),
      };

  static Map<String, dynamic> _logMap(HabitLogModel l) => {
        'habitId': l.habitId,
        'date': l.date,
        'isCompleted': l.isCompleted,
        'progressValue': l.progressValue,
        'syncedAt': FieldValue.serverTimestamp(),
      };

  static Future<void> _deleteHabitLogsFromCloud({
    required FirebaseFirestore fs,
    required String uid,
    required String habitId,
  }) async {
    final base = fs.collection('users').doc(uid);
    final q = base.collection('habit_logs').where('habitId', isEqualTo: habitId);
    while (true) {
      final snap = await q.limit(_batchSize).get();
      if (snap.docs.isEmpty) break;
      var batch = fs.batch();
      var n = 0;
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
        n++;
        if (n >= _batchSize) {
          await batch.commit();
          batch = fs.batch();
          n = 0;
        }
      }
      if (n > 0) {
        await batch.commit();
      }
    }
  }

  static Future<SharedPreferences> _resolvePrefs([SharedPreferences? prefs]) {
    if (prefs != null) return Future<SharedPreferences>.value(prefs);
    return SharedPreferences.getInstance();
  }

  static Future<Set<String>> _readDeletedHabitIds([
    SharedPreferences? prefs,
  ]) async {
    final p = await _resolvePrefs(prefs);
    final raw = p.getStringList(_prefsDeletedHabitIds) ?? const <String>[];
    return raw.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  static Future<void> _writeDeletedHabitIds(
    Set<String> ids, [
    SharedPreferences? prefs,
  ]) async {
    final p = await _resolvePrefs(prefs);
    final sorted = ids.toList()..sort();
    await p.setStringList(_prefsDeletedHabitIds, sorted);
  }

  /// Kalici silinen aliskanliklarin bulutta da temizlenmesi icin yerel kuyruga ekler.
  static Future<void> rememberDeletedHabitId({
    required String habitId,
    SharedPreferences? prefs,
  }) async {
    final id = habitId.trim();
    if (id.isEmpty) return;
    final ids = await _readDeletedHabitIds(prefs);
    if (ids.add(id)) {
      await _writeDeletedHabitIds(ids, prefs);
    }
  }

  static Future<void> _forgetDeletedHabitId(
    String habitId, [
    SharedPreferences? prefs,
  ]) async {
    final ids = await _readDeletedHabitIds(prefs);
    if (ids.remove(habitId)) {
      await _writeDeletedHabitIds(ids, prefs);
    }
  }

  static HabitModel? _habitFromFirestore(
    Map<String, dynamic> raw,
    String documentId,
  ) {
    final idField = (raw['id'] as String?)?.trim();
    final resolvedId =
        (idField != null && idField.isNotEmpty) ? idField : documentId;
    if (resolvedId.isEmpty) return null;

    final typeStr = raw['type'] as String? ?? 'good';
    final type = typeStr == 'bad' ? HabitType.bad : HabitType.good;

    final title = raw['title'] as String? ?? 'Alışkanlık';
    final emoji = raw['emoji'] as String? ?? '✨';
    final createdAt = raw['createdAt'] as String? ??
        DateTime.now().toIso8601String();
    final startedAtIso = raw['startedAtIso'] as String? ?? createdAt;
    final isArchived = raw['isArchived'] as bool? ?? false;
    final templateId = raw['templateId'] as String? ?? '';
    final commitmentText = raw['commitmentText'] as String? ?? '';
    final quitSubtype = raw['quitSubtype'] as String?;
    final quitMethod = raw['quitMethod'] as String?;
    final onboardingCompleted = raw['onboardingCompleted'] as bool? ?? true;
    final quitClockStartedAtIso = raw['quitClockStartedAtIso'] as String?;
    final note = raw['note'] as String? ?? '';
    final customTarget = (raw['customTarget'] as num?)?.toInt() ?? 1;
    final customUnit = raw['customUnit'] as String? ?? 'kez';
    final customTrackingKind = (raw['customTrackingKind'] as num?)?.toInt() ?? 0;
    final customFlexible = raw['customFlexible'] as bool? ?? false;
    final customMinTarget = (raw['customMinTarget'] as num?)?.toInt() ?? 0;
    final customRepeatCycle = (raw['customRepeatCycle'] as num?)?.toInt() ?? 0;

    return HabitModel(
      id: resolvedId,
      title: title,
      type: type,
      emoji: emoji,
      createdAt: createdAt,
      isArchived: isArchived,
      templateId: templateId,
      startedAtIso: startedAtIso,
      commitmentText: commitmentText,
      quitSubtype: quitSubtype,
      quitMethod: quitMethod,
      onboardingCompleted: onboardingCompleted,
      quitClockStartedAtIso: quitClockStartedAtIso,
      note: note,
      customTarget: customTarget,
      customUnit: customUnit,
      customTrackingKind: customTrackingKind,
      customFlexible: customFlexible,
      customMinTarget: customMinTarget,
      customRepeatCycle: customRepeatCycle,
    );
  }

  static HabitLogModel? _logFromFirestore(Map<String, dynamic> raw) {
    final habitId = raw['habitId'] as String? ?? '';
    final date = raw['date'] as String? ?? '';
    if (habitId.isEmpty || date.isEmpty) return null;
    final isCompleted = raw['isCompleted'] as bool? ?? false;
    final progressValue = (raw['progressValue'] as num?)?.toInt() ?? 0;
    return HabitLogModel(
      habitId: habitId,
      date: date,
      isCompleted: isCompleted,
      progressValue: progressValue,
    );
  }

  /// Firestore `users/{uid}/habits` + `habit_logs` → Hive. Namaz vakit tikleri dahil değil.
  /// Yerelde aynı id varsa bulut sürümüyle üzerine yazılır.
  static Future<void> pullToLocal({
    required String uid,
    required HabitRepository repo,
    SharedPreferences? prefs,
  }) async {
    if (!isFirebaseReady || uid.isEmpty) return;

    try {
      final fs = FirebaseFirestore.instance;
      final base = fs.collection('users').doc(uid);
      final deletedHabitIds = await _readDeletedHabitIds(prefs);

      final habitsSnap = await base.collection('habits').get();
      final cloudHabitIds = <String>{};

      for (final doc in habitsSnap.docs) {
        final data = doc.data();
        final h = _habitFromFirestore(data, doc.id);
        if (h == null) continue;
        if (deletedHabitIds.contains(h.id)) {
          continue;
        }
        await repo.save(h);
        cloudHabitIds.add(h.id);
      }

      for (final deletedId in deletedHabitIds) {
        await repo.deletePermanently(deletedId);
      }

      final logsSnap = await base.collection('habit_logs').get();
      for (final doc in logsSnap.docs) {
        final data = doc.data();
        final log = _logFromFirestore(data);
        if (log == null) continue;
        if (deletedHabitIds.contains(log.habitId)) continue;
        await repo.upsertLog(log);
      }

      if (cloudHabitIds.isNotEmpty) {
        await repo.dedupeActiveSalatPreferringCloudIds(cloudHabitIds);
      }

      for (final deletedId in deletedHabitIds) {
        await deleteHabitCloudData(
          uid: uid,
          habitId: deletedId,
          prefs: prefs,
        );
      }

      if (habitsSnap.docs.isNotEmpty || logsSnap.docs.isNotEmpty) {
        debugPrint(
          'HabitCloudSyncService: pull tamam '
          '(${habitsSnap.docs.length} alışkanlık, ${logsSnap.docs.length} log)',
        );
      }
    } catch (e, st) {
      debugPrint('HabitCloudSyncService pull: $e\n$st');
    }
  }

  /// Misafir veya Firebase yoksa no-op.
  /// [force]: ayarlardan giriş sonrası; throttle'ı atlar.
  static Future<void> pushFromLocal({
    required String uid,
    required HabitRepository repo,
    SharedPreferences? prefs,
    bool force = false,
  }) async {
    if (!isFirebaseReady || uid.isEmpty) return;

    if (!force && prefs != null) {
      final last = prefs.getInt(_prefsLastPushMs) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - last < _throttle.inMilliseconds) {
        debugPrint('HabitCloudSyncService: throttle (2 saat) atlandı');
        return;
      }
    }

    final fs = FirebaseFirestore.instance;
    final habits = repo.getAllIncludingArchived();

    var batch = fs.batch();
    var n = 0;

    Future<void> commitIfNeeded({bool force = false}) async {
      if (n >= _batchSize || (force && n > 0)) {
        await batch.commit();
        batch = fs.batch();
        n = 0;
      }
    }

    try {
      final deletedHabitIds = await _readDeletedHabitIds(prefs);
      for (final deletedId in deletedHabitIds) {
        await deleteHabitCloudData(
          uid: uid,
          habitId: deletedId,
          prefs: prefs,
        );
      }

      final base = fs.collection('users').doc(uid);
      final localHabitIds = habits.map((h) => h.id).toSet();
      final cloudHabitsSnap = await base.collection('habits').get();
      for (final doc in cloudHabitsSnap.docs) {
        if (localHabitIds.contains(doc.id)) continue;
        batch.delete(doc.reference);
        n++;
        await commitIfNeeded();
        await _deleteHabitLogsFromCloud(fs: fs, uid: uid, habitId: doc.id);
      }

      for (final h in habits) {
        final ref = fs.collection('users').doc(uid).collection('habits').doc(h.id);
        batch.set(ref, _habitMap(h), SetOptions(merge: true));
        n++;
        await commitIfNeeded();
      }

      for (final h in habits) {
        for (final log in repo.getLogs(h.id)) {
          final ref = fs
              .collection('users')
              .doc(uid)
              .collection('habit_logs')
              .doc(log.logKey);
          batch.set(ref, _logMap(log), SetOptions(merge: true));
          n++;
          await commitIfNeeded();
        }
      }

      await commitIfNeeded(force: true);

      await fs.collection('users').doc(uid).set(
        {
          'habitsMeta': {
            'lastPushAt': FieldValue.serverTimestamp(),
            'habitCount': habits.length,
          },
        },
        SetOptions(merge: true),
      );

      debugPrint('HabitCloudSyncService: push tamam uid=$uid');
      if (prefs != null) {
        await prefs.setInt(
          _prefsLastPushMs,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e, st) {
      debugPrint('HabitCloudSyncService: $e\n$st');
    }
  }

  /// Oturum açıkken çağrılmalı: `users/{uid}` altındaki tüm belgeleri siler.
  /// Auth kullanıcısı silinmeden önce kullanılmalı (kurallar `request.auth.uid` ister).
  static Future<void> deleteAllUserCloudData(String uid) async {
    if (!isFirebaseReady || uid.isEmpty) return;

    final fs = FirebaseFirestore.instance;
    final userRef = fs.collection('users').doc(uid);

    Future<void> deleteCollection(Query<Map<String, dynamic>> q) async {
      while (true) {
        final snap = await q.limit(_batchSize).get();
        if (snap.docs.isEmpty) break;
        var batch = fs.batch();
        var n = 0;
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
          n++;
          if (n >= _batchSize) {
            await batch.commit();
            batch = fs.batch();
            n = 0;
          }
        }
        if (n > 0) {
          await batch.commit();
        }
      }
    }

    await deleteCollection(userRef.collection('habits'));
    await deleteCollection(userRef.collection('habit_logs'));
    await userRef.delete();
  }

  /// Tek bir alışkanlığı buluttan kalıcı siler (habit dokumanı + bagli loglar).
  static Future<bool> deleteHabitCloudData({
    required String uid,
    required String habitId,
    SharedPreferences? prefs,
  }) async {
    if (!isFirebaseReady || uid.isEmpty || habitId.isEmpty) return false;
    final fs = FirebaseFirestore.instance;
    final habitRef = fs.collection('users').doc(uid).collection('habits').doc(habitId);
    try {
      await _deleteHabitLogsFromCloud(fs: fs, uid: uid, habitId: habitId);
      await habitRef.delete();
      await _forgetDeletedHabitId(habitId, prefs);
      return true;
    } catch (e, st) {
      debugPrint('HabitCloudSyncService deleteHabitCloudData: $e\n$st');
      return false;
    }
  }

  /// Bekleyen silme kuyruğunu bulutta tekrar dener.
  static Future<void> flushPendingDeletes({
    required String uid,
    SharedPreferences? prefs,
  }) async {
    if (!isFirebaseReady || uid.isEmpty) return;
    final ids = await _readDeletedHabitIds(prefs);
    for (final id in ids) {
      await deleteHabitCloudData(uid: uid, habitId: id, prefs: prefs);
    }
  }
}
