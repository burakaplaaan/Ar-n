// Son okunan ayet ve okuyucu tercihleri — yalnızca SharedPreferences.
// Firebase yok.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/shared_preferences_provider.dart';
import 'quran_models.dart';
import 'quran_surah_catalog.dart';

const _kSurah = 'quran_last_surah';
const _kAyah = 'quran_last_ayah';
const _kShowMeal = 'quran_show_translation';
const _kFontStep = 'quran_font_step';

class QuranProgressStore {
  QuranProgressStore(this._prefs);

  final SharedPreferences _prefs;

  QuranProgress? readProgress() {
    final surah = _prefs.getInt(_kSurah);
    final ayah = _prefs.getInt(_kAyah);
    if (surah == null || ayah == null) return null;
    if (surah < 1 || surah > 114) return null;
    final maxAyah = QuranSurahCatalog.byNumber(surah).ayahCount;
    return QuranProgress(
      surah: surah,
      ayah: ayah.clamp(1, maxAyah),
    );
  }

  Future<void> saveProgress({required int surah, required int ayah}) async {
    if (surah < 1 || surah > 114) return;
    final maxAyah = QuranSurahCatalog.byNumber(surah).ayahCount;
    await _prefs.setInt(_kSurah, surah);
    await _prefs.setInt(_kAyah, ayah.clamp(1, maxAyah));
  }

  bool showTranslation({required bool defaultOn}) {
    return _prefs.getBool(_kShowMeal) ?? defaultOn;
  }

  Future<void> setShowTranslation(bool value) =>
      _prefs.setBool(_kShowMeal, value);

  /// 0 küçük, 1 orta, 2 büyük.
  int fontStep() => (_prefs.getInt(_kFontStep) ?? 1).clamp(0, 2);

  Future<void> setFontStep(int step) =>
      _prefs.setInt(_kFontStep, step.clamp(0, 2));
}

final quranProgressStoreProvider = Provider<QuranProgressStore>((ref) {
  return QuranProgressStore(ref.watch(sharedPreferencesProvider));
});
