import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firebase_bootstrap.dart';

class GlobalWidgetLockResult {
  const GlobalWidgetLockResult({
    required this.fetched,
    required this.locked,
    required this.revision,
  });

  final bool fetched;
  final bool locked;
  final int revision;
}

abstract final class GlobalWidgetLockService {
  static const collection = 'app_public';
  static const documentId = 'widget_global_lock';

  static const _lastFetchMsKey = 'arin_global_widget_lock_last_fetch_ms';
  static const _localLockedKey = 'arin_global_widget_lock_locked';
  static const _localNoteKey = 'arin_global_widget_lock_note';
  static const _localRevisionKey = 'arin_global_widget_lock_revision';
  static const _minFetchGap = Duration(minutes: 5);
  static Future<void> _mutationTail = Future<void>.value();

  /// Foreground FCM ve lifecycle Firestore fetch'i aynı anda tamamlanabilir.
  /// Revision kontrolü ile üç preference yazımını tek isolate içinde sıralar.
  static Future<T> _serializedMutation<T>(Future<T> Function() action) async {
    final previous = _mutationTail;
    final release = Completer<void>();
    _mutationTail = release.future;
    await previous;
    try {
      return await action();
    } finally {
      release.complete();
    }
  }

  /// Yerel önbellekten anlık kilit durumunu okur — ağ çağrısı yapmaz.
  static bool isGloballyLocked(SharedPreferences prefs) =>
      prefs.getBool(_localLockedKey) == true;

  /// Yerel önbellekten kilit notunu okur. Boş string döner.
  static String lockedNote(SharedPreferences prefs) =>
      prefs.getString(_localNoteKey) ?? '';

  static int revision(SharedPreferences prefs) =>
      prefs.getInt(_localRevisionKey) ?? 0;

  static bool shouldApplyRevision({
    required int current,
    required int incoming,
  }) {
    if (incoming < 0) return false;
    if (current > 0 && incoming == 0) return false;
    return incoming >= current;
  }

  /// Sessiz push ile gelen durumu Flutter'ın yerel önbelleğine de uygular.
  /// Eş revision idempotent retry olarak kabul edilir; yalnızca eski mesaj
  /// reddedilir.
  static Future<bool> applyRemoteOverride(
    SharedPreferences prefs, {
    required bool locked,
    required int revision,
    required String note,
  }) async {
    return _serializedMutation(() async {
      if (revision <= 0 ||
          !shouldApplyRevision(
            current: GlobalWidgetLockService.revision(prefs),
            incoming: revision,
          )) {
        return false;
      }
      await prefs.setBool(_localLockedKey, locked);
      await prefs.setString(_localNoteKey, note.trim());
      await prefs.setInt(_localRevisionKey, revision);
      return true;
    });
  }

  /// Firestore'dan kilit durumunu getirir ve yerel önbelleğe yazar.
  /// [force] = true ise son çekim süresini yok sayar.
  static Future<GlobalWidgetLockResult> applyIfDue(
    SharedPreferences prefs, {
    bool force = false,
  }) async {
    if (!isFirebaseReady) {
      return GlobalWidgetLockResult(
        fetched: false,
        locked: isGloballyLocked(prefs),
        revision: revision(prefs),
      );
    }

    final now = DateTime.now();
    final lastMs = prefs.getInt(_lastFetchMsKey);
    if (!force && lastMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (now.difference(last) < _minFetchGap) {
        return GlobalWidgetLockResult(
          fetched: false,
          locked: isGloballyLocked(prefs),
          revision: revision(prefs),
        );
      }
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId);
      DocumentSnapshot<Map<String, dynamic>> snap;
      try {
        snap = await docRef.get(const GetOptions(source: Source.server));
      } catch (_) {
        snap = await docRef.get(const GetOptions(source: Source.cache));
      }

      await prefs.setInt(_lastFetchMsKey, now.millisecondsSinceEpoch);
      final data = snap.data();
      final locked = data?['locked'] == true;
      final note = data?['note']?.toString().trim() ?? '';
      final revisionValue = data?['revision'];
      final remoteRevision = revisionValue is num && revisionValue > 0
          ? revisionValue.toInt()
          : 0;
      return _serializedMutation(() async {
        // Queue'da beklerken daha yeni FCM uygulanmış olabilir; revision bu
        // critical section içinde yeniden okunmalıdır.
        final localRevision = revision(prefs);
        if (!shouldApplyRevision(
          current: localRevision,
          incoming: remoteRevision,
        )) {
          return GlobalWidgetLockResult(
            fetched: true,
            locked: isGloballyLocked(prefs),
            revision: localRevision,
          );
        }
        await prefs.setBool(_localLockedKey, locked);
        await prefs.setString(_localNoteKey, note);
        await prefs.setInt(_localRevisionKey, remoteRevision);
        return GlobalWidgetLockResult(
          fetched: true,
          locked: locked,
          revision: remoteRevision,
        );
      });
    } catch (e, st) {
      debugPrint('GlobalWidgetLockService: $e\n$st');
      return GlobalWidgetLockResult(
        fetched: false,
        locked: isGloballyLocked(prefs),
        revision: revision(prefs),
      );
    }
  }
}
