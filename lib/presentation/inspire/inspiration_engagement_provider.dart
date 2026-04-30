import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../data/services/inspiration_engagement_sync_service.dart';

const _kSaved = 'inspire_saved_ids';
const _kLiked = 'inspire_liked_ids';

/// Kayıt sırası: en son eklenen başta (Instagram benzeri).
class InspirationSavedNotifier extends StateNotifier<List<String>> {
  InspirationSavedNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static List<String> _read(SharedPreferences p) =>
      List<String>.from(p.getStringList(_kSaved) ?? const []);

  bool isSaved(String id) => state.contains(id);

  void toggle(String id) {
    final next = List<String>.from(state);
    final wasSaved = next.contains(id);
    if (wasSaved) {
      next.remove(id);
    } else {
      next.insert(0, id);
    }
    state = next;
    _prefs.setStringList(_kSaved, next);
    unawaited(InspirationEngagementSyncService.pushFromPrefs(_prefs));
    // Yalnızca kaydetme (yeni) olayını sayıyoruz; kaldırma için ayrı
    // event gerekmiyor — panelde toplam kaydedilen sayısı ayrı metriktir.
    if (!wasSaved) {
      unawaited(ArinAnalytics.kesfetSave());
    }
  }

  void remove(String id) {
    if (!state.contains(id)) return;
    final next = List<String>.from(state)..remove(id);
    state = next;
    _prefs.setStringList(_kSaved, next);
    unawaited(InspirationEngagementSyncService.pushFromPrefs(_prefs));
  }
}

final inspirationSavedIdsProvider =
    StateNotifierProvider<InspirationSavedNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return InspirationSavedNotifier(prefs);
});

class InspirationLikedNotifier extends StateNotifier<Set<String>> {
  InspirationLikedNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static Set<String> _read(SharedPreferences p) =>
      (p.getStringList(_kLiked) ?? const <String>[]).toSet();

  bool isLiked(String id) => state.contains(id);

  void toggle(String id) {
    final next = Set<String>.from(state);
    final wasLiked = next.contains(id);
    if (wasLiked) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    _prefs.setStringList(_kLiked, next.toList());
    unawaited(InspirationEngagementSyncService.pushFromPrefs(_prefs));
    if (!wasLiked) {
      unawaited(ArinAnalytics.kesfetLike());
    }
  }
}

final inspirationLikedIdsProvider =
    StateNotifierProvider<InspirationLikedNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return InspirationLikedNotifier(prefs);
});
