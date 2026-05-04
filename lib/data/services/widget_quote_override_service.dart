import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import 'arin_widget_sync.dart';

class WidgetQuoteOverrideResult {
  const WidgetQuoteOverrideResult({
    required this.fetched,
    required this.activeApplied,
    required this.shouldResumeNormal,
  });

  final bool fetched;
  final bool activeApplied;
  final bool shouldResumeNormal;
}

abstract final class WidgetQuoteOverrideService {
  static const collection = 'app_public';
  static const documentId = 'widget_override';

  static const _lastFetchMsKey = 'arin_widget_override_last_fetch_ms';
  static const _localActiveKey = 'arin_widget_override_local_active';
  static const _minFetchGap = Duration(minutes: 5);

  static Future<WidgetQuoteOverrideResult> applyIfDue(
    SharedPreferences prefs, {
    bool force = false,
  }) async {
    if (!isFirebaseReady) {
      return const WidgetQuoteOverrideResult(
        fetched: false,
        activeApplied: false,
        shouldResumeNormal: false,
      );
    }

    final now = DateTime.now();
    final lastMs = prefs.getInt(_lastFetchMsKey);
    if (!force && lastMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (now.difference(last) < _minFetchGap) {
        return WidgetQuoteOverrideResult(
          fetched: false,
          activeApplied: prefs.getBool(_localActiveKey) == true,
          shouldResumeNormal: false,
        );
      }
    }

    try {
      final doc = FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId);
      DocumentSnapshot<Map<String, dynamic>> snap;
      try {
        snap = await doc.get(const GetOptions(source: Source.server));
      } catch (_) {
        snap = await doc.get(const GetOptions(source: Source.cache));
      }

      await prefs.setInt(_lastFetchMsKey, now.millisecondsSinceEpoch);
      final data = snap.data();
      final wasActive = prefs.getBool(_localActiveKey) == true;
      final active = _isActive(data, now);

      if (!active) {
        await prefs.setBool(_localActiveKey, false);
        return WidgetQuoteOverrideResult(
          fetched: true,
          activeApplied: false,
          shouldResumeNormal: wasActive,
        );
      }

      final text = data?['text']?.toString().trim() ?? '';
      final source = data?['source']?.toString().trim() ?? '';
      await ArinWidgetSync.pushQuoteOverride(text: text, source: source);
      await prefs.setBool(_localActiveKey, true);
      return const WidgetQuoteOverrideResult(
        fetched: true,
        activeApplied: true,
        shouldResumeNormal: false,
      );
    } catch (e, st) {
      debugPrint('WidgetQuoteOverrideService: $e\n$st');
      return WidgetQuoteOverrideResult(
        fetched: false,
        activeApplied: prefs.getBool(_localActiveKey) == true,
        shouldResumeNormal: false,
      );
    }
  }

  static bool _isActive(Map<String, dynamic>? data, DateTime now) {
    if (data == null || data['active'] != true) return false;
    final text = data['text']?.toString().trim() ?? '';
    if (text.isEmpty) return false;
    final expiresAt = _dateFromValue(data['expiresAt']);
    if (expiresAt != null && !expiresAt.isAfter(now)) return false;
    return true;
  }

  static DateTime? _dateFromValue(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
