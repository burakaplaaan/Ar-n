import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationDiagnosticsEntry {
  NotificationDiagnosticsEntry({
    required this.atIso,
    required this.source,
    required this.action,
    required this.outcome,
    required this.details,
  });

  final String atIso;
  final String source;
  final String action;
  final String outcome;
  final Map<String, dynamic> details;

  DateTime get at =>
      DateTime.tryParse(atIso) ?? DateTime.fromMillisecondsSinceEpoch(0);

  String detailsText() {
    if (details.isEmpty) return '-';
    return details.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'at': atIso,
    'source': source,
    'action': action,
    'outcome': outcome,
    'details': details,
  };

  static NotificationDiagnosticsEntry? fromJsonLine(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) return null;
      final m = Map<String, dynamic>.from(decoded);
      final detailsRaw = m['details'];
      return NotificationDiagnosticsEntry(
        atIso: m['at']?.toString() ?? DateTime.now().toIso8601String(),
        source: m['source']?.toString() ?? 'unknown',
        action: m['action']?.toString() ?? 'unknown',
        outcome: m['outcome']?.toString() ?? 'unknown',
        details: detailsRaw is Map
            ? Map<String, dynamic>.from(detailsRaw)
            : <String, dynamic>{},
      );
    } catch (_) {
      return null;
    }
  }
}

abstract final class AdminNotificationDiagnosticsLog {
  static const _key = 'admin_notification_diagnostics_log_v1';
  static const int _maxEntries = 250;

  static Future<void> append(
    SharedPreferences prefs, {
    required String source,
    required String action,
    required String outcome,
    Map<String, Object?> details = const <String, Object?>{},
  }) async {
    final raw = prefs.getStringList(_key) ?? <String>[];
    final entry = NotificationDiagnosticsEntry(
      atIso: DateTime.now().toIso8601String(),
      source: source,
      action: action,
      outcome: outcome,
      details: Map<String, dynamic>.from(details),
    );
    raw.insert(0, jsonEncode(entry.toMap()));
    if (raw.length > _maxEntries) {
      raw.removeRange(_maxEntries, raw.length);
    }
    await prefs.setStringList(_key, raw);
  }

  static List<NotificationDiagnosticsEntry> readAll(SharedPreferences prefs) {
    final raw = prefs.getStringList(_key) ?? <String>[];
    return raw
        .map(NotificationDiagnosticsEntry.fromJsonLine)
        .whereType<NotificationDiagnosticsEntry>()
        .toList();
  }

  static Future<void> clear(SharedPreferences prefs) => prefs.remove(_key);

  static String exportPrettyJson(SharedPreferences prefs) {
    final all = readAll(prefs).map((e) => e.toMap()).toList();
    const enc = JsonEncoder.withIndent('  ');
    return enc.convert(all);
  }
}
