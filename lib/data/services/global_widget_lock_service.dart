import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firebase_bootstrap.dart';

class GlobalWidgetLockResult {
  const GlobalWidgetLockResult({required this.fetched, required this.locked});

  final bool fetched;
  final bool locked;
}

abstract final class GlobalWidgetLockService {
  static const collection = 'app_public';
  static const documentId = 'widget_global_lock';

  static const _lastFetchMsKey = 'arin_global_widget_lock_last_fetch_ms';
  static const _localLockedKey = 'arin_global_widget_lock_locked';
  static const _localNoteKey = 'arin_global_widget_lock_note';
  static const _minFetchGap = Duration(minutes: 5);

  /// Yerel önbellekten anlık kilit durumunu okur — ağ çağrısı yapmaz.
  static bool isGloballyLocked(SharedPreferences prefs) =>
      prefs.getBool(_localLockedKey) == true;

  /// Yerel önbellekten kilit notunu okur. Boş string döner.
  static String lockedNote(SharedPreferences prefs) =>
      prefs.getString(_localNoteKey) ?? '';

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
      await prefs.setBool(_localLockedKey, locked);
      await prefs.setString(_localNoteKey, note);
      return GlobalWidgetLockResult(fetched: true, locked: locked);
    } catch (e, st) {
      debugPrint('GlobalWidgetLockService: $e\n$st');
      return GlobalWidgetLockResult(
        fetched: false,
        locked: isGloballyLocked(prefs),
      );
    }
  }
}
