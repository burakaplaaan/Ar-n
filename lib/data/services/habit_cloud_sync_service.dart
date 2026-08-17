// lib/data/services/habit_cloud_sync_service.dart
// Giriş yapılmış kullanıcı: alışkanlık + logları Firestore'a yedekler (namaz vakti yok).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../models/habit_log_model.dart';
import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';
import 'habit_cloud_sync_queue.dart';

/// `users/{uid}/habits/{habitId}` ve `users/{uid}/habit_logs/{logKey}`
abstract final class HabitCloudSyncService {
  static const _batchSize = 400;
  static const _prefsLastPushMs = 'arin_habit_cloud_last_push_ms';
  static const _prefsDeletedHabitIds = HabitCloudSyncQueue.deletedHabitIdsKey;
  static const _prefsLastForcePushMs = 'arin_habit_cloud_last_force_push_ms';
  static const _throttle = Duration(hours: 2);
  static const _forceCooldown = Duration(minutes: 3);

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
    final q = base
        .collection('habit_logs')
        .where('habitId', isEqualTo: habitId);
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
    final resolvedId = (idField != null && idField.isNotEmpty)
        ? idField
        : documentId;
    if (resolvedId.isEmpty) return null;

    final typeStr = raw['type'] as String? ?? 'good';
    final type = typeStr == 'bad' ? HabitType.bad : HabitType.good;

    final title = raw['title'] as String? ?? 'Alışkanlık';
    final emoji = raw['emoji'] as String? ?? '✨';
    final createdAt =
        raw['createdAt'] as String? ?? DateTime.now().toIso8601String();
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
    final customTrackingKind =
        (raw['customTrackingKind'] as num?)?.toInt() ?? 0;
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
  static Future<bool> pullToLocal({
    required String uid,
    required HabitRepository repo,
    SharedPreferences? prefs,
  }) async {
    if (!isFirebaseReady || uid.isEmpty) return false;

    try {
      final fs = FirebaseFirestore.instance;
      final base = fs.collection('users').doc(uid);
      final deletedHabitIds = await _readDeletedHabitIds(prefs);
      final dirtyHabitIds = prefs == null
          ? <String>{}
          : HabitCloudSyncQueue.readDirtyHabitIds(prefs);
      final dirtyLogKeys = prefs == null
          ? <String>{}
          : HabitCloudSyncQueue.readDirtyLogKeys(prefs);
      final deletedLogKeys = prefs == null
          ? <String>{}
          : HabitCloudSyncQueue.readDeletedLogKeys(prefs);

      final habitsSnap = await base.collection('habits').get();
      final cloudHabitIds = <String>{};

      for (final doc in habitsSnap.docs) {
        final data = doc.data();
        final h = _habitFromFirestore(data, doc.id);
        if (h == null) continue;
        if (deletedHabitIds.contains(h.id)) {
          continue;
        }
        if (dirtyHabitIds.contains(h.id)) {
          cloudHabitIds.add(h.id);
          continue;
        }
        await repo.saveFromCloud(h);
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
        final logKey = log.logKey;
        if (deletedHabitIds.contains(log.habitId)) continue;
        if (deletedLogKeys.contains(logKey) || dirtyLogKeys.contains(logKey)) {
          continue;
        }
        await repo.upsertLogFromCloud(log);
      }

      if (cloudHabitIds.isNotEmpty) {
        await repo.dedupeActiveSalatPreferringCloudIds(cloudHabitIds);
      }
      await repo.ensureDefaultSalatHabit();

      for (final deletedId in deletedHabitIds) {
        await deleteHabitCloudData(uid: uid, habitId: deletedId, prefs: prefs);
      }

      if (habitsSnap.docs.isNotEmpty || logsSnap.docs.isNotEmpty) {
        debugPrint(
          'HabitCloudSyncService: pull tamam '
          '(${habitsSnap.docs.length} alışkanlık, ${logsSnap.docs.length} log)',
        );
      }
      return true;
    } catch (e, st) {
      debugPrint('HabitCloudSyncService pull: $e\n$st');
      return false;
    }
  }

  /// Misafir veya Firebase yoksa no-op.
  /// [force]: manuel senkron isteği; kısa cooldown dışında full push yapar.
  static Future<void> pushFromLocal({
    required String uid,
    required HabitRepository repo,
    SharedPreferences? prefs,
    bool force = false,
    bool bypassForceCooldown = false,
  }) async {
    if (!isFirebaseReady || uid.isEmpty) return;

    final resolvedPrefs = await _resolvePrefs(prefs);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (force && !bypassForceCooldown) {
      final lastForce = resolvedPrefs.getInt(_prefsLastForcePushMs) ?? 0;
      if (nowMs - lastForce < _forceCooldown.inMilliseconds) {
        debugPrint('HabitCloudSyncService: force cooldown (3 dk) atlandı');
        return;
      }
    }

    final dirtyHabitIds = HabitCloudSyncQueue.readDirtyHabitIds(resolvedPrefs);
    final dirtyLogKeys = HabitCloudSyncQueue.readDirtyLogKeys(resolvedPrefs);
    final deletedLogKeys = HabitCloudSyncQueue.readDeletedLogKeys(
      resolvedPrefs,
    );
    final deletedHabitIds = await _readDeletedHabitIds(resolvedPrefs);
    final hasQueuedDeltas =
        dirtyHabitIds.isNotEmpty ||
        dirtyLogKeys.isNotEmpty ||
        deletedLogKeys.isNotEmpty ||
        deletedHabitIds.isNotEmpty;
    final hasCompletedPush = resolvedPrefs.getInt(_prefsLastPushMs) != null;
    final shouldFullPush = force || !hasCompletedPush;

    if (!shouldFullPush && !hasQueuedDeltas) {
      final last = resolvedPrefs.getInt(_prefsLastPushMs) ?? 0;
      if (nowMs - last < _throttle.inMilliseconds) {
        debugPrint('HabitCloudSyncService: temiz kuyruk, throttle atlandı');
        return;
      }
      debugPrint('HabitCloudSyncService: temiz kuyruk, push gerekmedi');
      await resolvedPrefs.setInt(_prefsLastPushMs, nowMs);
      return;
    }

    if (shouldFullPush) {
      await _pushFullFromLocal(
        uid: uid,
        repo: repo,
        prefs: resolvedPrefs,
        markForce: force,
      );
      return;
    }

    await _pushQueuedDeltas(uid: uid, repo: repo, prefs: resolvedPrefs);
  }

  static Future<void> _pushFullFromLocal({
    required String uid,
    required HabitRepository repo,
    required SharedPreferences prefs,
    required bool markForce,
  }) async {
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
        await deleteHabitCloudData(uid: uid, habitId: deletedId, prefs: prefs);
      }

      final base = fs.collection('users').doc(uid);
      final deletedLogKeys = HabitCloudSyncQueue.readDeletedLogKeys(prefs);
      for (final key in deletedLogKeys) {
        batch.delete(base.collection('habit_logs').doc(key));
        n++;
        await commitIfNeeded();
      }

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
        final ref = base.collection('habits').doc(h.id);
        batch.set(ref, _habitMap(h), SetOptions(merge: true));
        n++;
        await commitIfNeeded();
      }

      for (final h in habits) {
        for (final log in repo.getLogs(h.id)) {
          final ref = base.collection('habit_logs').doc(log.logKey);
          batch.set(ref, _logMap(log), SetOptions(merge: true));
          n++;
          await commitIfNeeded();
        }
      }

      await commitIfNeeded(force: true);

      await base.set({
        'habitsMeta': {
          'lastPushAt': FieldValue.serverTimestamp(),
          'habitCount': habits.length,
        },
      }, SetOptions(merge: true));

      debugPrint('HabitCloudSyncService: full push tamam uid=$uid');
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_prefsLastPushMs, nowMs);
      if (markForce) {
        await prefs.setInt(_prefsLastForcePushMs, nowMs);
      }
      await HabitCloudSyncQueue.forgetAllHabitDeltas(prefs);
    } catch (e, st) {
      debugPrint('HabitCloudSyncService full: $e\n$st');
    }
  }

  static Future<void> _pushQueuedDeltas({
    required String uid,
    required HabitRepository repo,
    required SharedPreferences prefs,
  }) async {
    final fs = FirebaseFirestore.instance;
    final base = fs.collection('users').doc(uid);
    final dirtyHabitIds = HabitCloudSyncQueue.readDirtyHabitIds(prefs);
    final dirtyLogKeys = HabitCloudSyncQueue.readDirtyLogKeys(prefs);
    final deletedLogKeys = HabitCloudSyncQueue.readDeletedLogKeys(prefs);

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
        await deleteHabitCloudData(uid: uid, habitId: deletedId, prefs: prefs);
      }

      for (final id in dirtyHabitIds) {
        final habit = repo.getById(id);
        if (habit == null) continue;
        batch.set(
          base.collection('habits').doc(id),
          _habitMap(habit),
          SetOptions(merge: true),
        );
        n++;
        await commitIfNeeded();
      }

      for (final key in deletedLogKeys) {
        batch.delete(base.collection('habit_logs').doc(key));
        n++;
        await commitIfNeeded();
      }

      for (final key in dirtyLogKeys) {
        final log = repo.logByKey(key);
        final ref = base.collection('habit_logs').doc(key);
        if (log == null) {
          batch.delete(ref);
        } else {
          batch.set(ref, _logMap(log), SetOptions(merge: true));
        }
        n++;
        await commitIfNeeded();
      }

      if (n > 0) {
        batch.set(base, {
          'habitsMeta': {
            'lastPushAt': FieldValue.serverTimestamp(),
            'habitCount': repo.getAllIncludingArchived().length,
          },
        }, SetOptions(merge: true));
        n++;
      }
      await commitIfNeeded(force: true);

      await HabitCloudSyncQueue.forgetDirtyHabitIds(prefs, dirtyHabitIds);
      await HabitCloudSyncQueue.forgetDirtyLogKeys(prefs, dirtyLogKeys);
      await HabitCloudSyncQueue.forgetDeletedLogKeys(prefs, deletedLogKeys);
      await prefs.setInt(
        _prefsLastPushMs,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint(
        'HabitCloudSyncService: delta push tamam '
        'h=${dirtyHabitIds.length}, l=${dirtyLogKeys.length}, '
        'dl=${deletedLogKeys.length}',
      );
    } catch (e, st) {
      debugPrint('HabitCloudSyncService delta: $e\n$st');
    }
  }

  /// Oturum açıkken çağrılmalı: `users/{uid}` altındaki tüm belgeleri siler.
  /// Auth kullanıcısı silinmeden önce kullanılmalı (kurallar `request.auth.uid` ister).
  static Future<void> deleteAllUserCloudData(String uid, {String? email}) async {
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
    try {
      await userRef.collection('zikir_matik').doc('state').delete();
    } catch (_) {}
    try {
      await userRef.collection('user_backup').doc('state').delete();
    } catch (_) {}
    try {
      await userRef.delete();
    } catch (_) {}
    
    // Hesap silmede premium kayıtları da temizle.
    // Client-side silme yetkisi (firestore.rules) olmadığından fail-safe olarak
    // try/catch içinde çağırıyoruz; asıl temizliği backend (cleanupDeletedUserData) yapacak.
    try {
      await fs.collection('premium_entitlements').doc(uid).delete();
    } catch (e) {
      debugPrint('Client-side premium_entitlements delete skipped (rules): $e');
    }
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      try {
        await fs.collection('premium_invites').doc(normalizedEmail).delete();
      } catch (e) {
        debugPrint('Client-side premium_invites delete skipped (rules): $e');
      }
    }
  }

  /// Hesap silme öncesi, backend tarafında güvenli purge kuyruğuna kayıt açar.
  static Future<void> queueUserCloudDataDeletion({
    required String uid,
    String? email,
  }) async {
    if (!isFirebaseReady || uid.isEmpty) return;
    final fs = FirebaseFirestore.instance;
    await fs.collection('account_deletion_queue').doc(uid).set({
      'uid': uid,
      'email': email?.trim().toLowerCase(),
      'requestedAt': FieldValue.serverTimestamp(),
      'processedAt': null,
      'status': 'pending',
    }, SetOptions(merge: true));
  }

  /// Tek bir alışkanlığı buluttan kalıcı siler (habit dokumanı + bagli loglar).
  static Future<bool> deleteHabitCloudData({
    required String uid,
    required String habitId,
    SharedPreferences? prefs,
  }) async {
    if (!isFirebaseReady || uid.isEmpty || habitId.isEmpty) return false;
    final fs = FirebaseFirestore.instance;
    final habitRef = fs
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habitId);
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
