import 'package:shared_preferences/shared_preferences.dart';

/// Local queue for Firestore habit sync deltas.
///
/// Kept outside Hive models so we can reduce cloud writes without changing
/// adapter schemas or migrating existing local data.
abstract final class HabitCloudSyncQueue {
  static const deletedHabitIdsKey = 'arin_habit_cloud_deleted_habit_ids';
  static const dirtyHabitIdsKey = 'arin_habit_cloud_dirty_habit_ids';
  static const dirtyLogKeysKey = 'arin_habit_cloud_dirty_log_keys';
  static const deletedLogKeysKey = 'arin_habit_cloud_deleted_log_keys';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Set<String> _readSet(SharedPreferences prefs, String key) {
    return (prefs.getStringList(key) ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  static Future<void> _writeSet(
    SharedPreferences prefs,
    String key,
    Set<String> values,
  ) async {
    final sorted = values.toList()..sort();
    await prefs.setStringList(key, sorted);
  }

  static Future<void> markHabitDirty(String habitId) async {
    final normalized = habitId.trim();
    if (normalized.isEmpty) return;
    final prefs = await _prefs();
    final dirtyHabits = _readSet(prefs, dirtyHabitIdsKey)..add(normalized);
    final deletedHabits = _readSet(prefs, deletedHabitIdsKey)
      ..remove(normalized);
    await _writeSet(prefs, dirtyHabitIdsKey, dirtyHabits);
    await _writeSet(prefs, deletedHabitIdsKey, deletedHabits);
  }

  static Future<void> markHabitDeleted(String habitId) async {
    final normalized = habitId.trim();
    if (normalized.isEmpty) return;
    final prefs = await _prefs();
    final dirtyHabits = _readSet(prefs, dirtyHabitIdsKey)..remove(normalized);
    final deletedHabits = _readSet(prefs, deletedHabitIdsKey)..add(normalized);
    await _writeSet(prefs, dirtyHabitIdsKey, dirtyHabits);
    await _writeSet(prefs, deletedHabitIdsKey, deletedHabits);
  }

  static Future<void> markLogDirty(String logKey) async {
    final normalized = logKey.trim();
    if (normalized.isEmpty) return;
    final prefs = await _prefs();
    final dirty = _readSet(prefs, dirtyLogKeysKey)..add(normalized);
    final deleted = _readSet(prefs, deletedLogKeysKey)..remove(normalized);
    await _writeSet(prefs, dirtyLogKeysKey, dirty);
    await _writeSet(prefs, deletedLogKeysKey, deleted);
  }

  static Future<void> markLogDeleted(String logKey) async {
    final normalized = logKey.trim();
    if (normalized.isEmpty) return;
    final prefs = await _prefs();
    final dirty = _readSet(prefs, dirtyLogKeysKey)..remove(normalized);
    final deleted = _readSet(prefs, deletedLogKeysKey)..add(normalized);
    await _writeSet(prefs, dirtyLogKeysKey, dirty);
    await _writeSet(prefs, deletedLogKeysKey, deleted);
  }

  static Set<String> readDirtyHabitIds(SharedPreferences prefs) {
    return _readSet(prefs, dirtyHabitIdsKey);
  }

  static Set<String> readDirtyLogKeys(SharedPreferences prefs) {
    return _readSet(prefs, dirtyLogKeysKey);
  }

  static Set<String> readDeletedLogKeys(SharedPreferences prefs) {
    return _readSet(prefs, deletedLogKeysKey);
  }

  static Future<void> forgetDirtyHabitIds(
    SharedPreferences prefs,
    Iterable<String> ids,
  ) async {
    final values = _readSet(prefs, dirtyHabitIdsKey)..removeAll(ids);
    await _writeSet(prefs, dirtyHabitIdsKey, values);
  }

  static Future<void> forgetDirtyLogKeys(
    SharedPreferences prefs,
    Iterable<String> keys,
  ) async {
    final values = _readSet(prefs, dirtyLogKeysKey)..removeAll(keys);
    await _writeSet(prefs, dirtyLogKeysKey, values);
  }

  static Future<void> forgetDeletedLogKeys(
    SharedPreferences prefs,
    Iterable<String> keys,
  ) async {
    final values = _readSet(prefs, deletedLogKeysKey)..removeAll(keys);
    await _writeSet(prefs, deletedLogKeysKey, values);
  }

  static Future<void> forgetAllHabitDeltas(SharedPreferences prefs) async {
    await _writeSet(prefs, dirtyHabitIdsKey, <String>{});
    await _writeSet(prefs, dirtyLogKeysKey, <String>{});
    await _writeSet(prefs, deletedLogKeysKey, <String>{});
  }
}
