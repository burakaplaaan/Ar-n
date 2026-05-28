// lib/domain/algorithms/user_content_tags.dart
// Anketten gelen görünen metinleri, content_pool / Firestore havuzundaki
// küçük harf + ASCII etiketlerine çevirir (ContentMatcher ile örtüşme).

import '../../core/constants/app_strings.dart';

abstract final class UserContentTags {
  static const Map<String, String> _legacyToStableMood = {
    'happy': 'mood_happy',
    'calm': 'mood_calm',
    'stressed': 'mood_stressed',
    'sad': 'mood_sad',
    'grateful': 'mood_grateful',
    'anxious': 'mood_anxious',
    'motivated': 'mood_motivated',
    'mutlu': 'mood_happy',
    'sakin': 'mood_calm',
    'stresli': 'mood_stressed',
    'uzgun': 'mood_sad',
    'sukrediyorum': 'mood_grateful',
    'kaygili': 'mood_anxious',
    'motive': 'mood_motivated',
  };

  static const Map<String, String> _legacyToStableSector = {
    'highschooluniversityprep': 'sector_student',
    'students': 'sector_student',
    'student': 'sector_student',
    'ozelsektor': 'sector_private',
    'privatesector': 'sector_private',
    'kamupersoneli': 'sector_public',
    'publicsector': 'sector_public',
    'kendiisimserbest': 'sector_business',
    'ownbusinessfreelance': 'sector_business',
    'ticaret': 'sector_trade',
    'trade': 'sector_trade',
    'evhanimieverkegi': 'sector_household',
    'homemaker': 'sector_household',
    'diger': 'sector_other',
    'other': 'sector_other',
  };

  static const Map<String, String> _legacyToStableNeed = {
    'motivation': 'need_motivation',
    'motivasyon': 'need_motivation',
    'patience': 'need_sabr',
    'sabr': 'need_sabr',
    'gratitude': 'need_shukr',
    'sukur': 'need_shukr',
    'trustingod': 'need_tawakkul',
    'trust': 'need_tawakkul',
    'tevekkul': 'need_tawakkul',
    'focus': 'need_focus',
    'odaklanma': 'need_focus',
    'healing': 'need_healing',
    'sifa': 'need_healing',
    'provisionblessing': 'need_rizq',
    'rizikbereket': 'need_rizq',
  };

  static const Map<String, List<String>> _mood = {
    'mood_happy': ['mutlu'],
    'mood_calm': ['sakin'],
    'mood_stressed': ['stresli'],
    'mood_sad': ['uzgun'],
    'mood_grateful': ['sukur', 'mutlu'],
    'mood_anxious': ['kaygi'],
    'mood_motivated': ['motive', 'motivasyon'],
    AppStrings.moodHappy: ['mutlu'],
    AppStrings.moodCalm: ['sakin'],
    AppStrings.moodStressed: ['stresli'],
    AppStrings.moodSad: ['uzgun'],
    AppStrings.moodGrateful: ['sukur', 'mutlu'],
    AppStrings.moodAnxious: ['kaygi'],
    AppStrings.moodMotivated: ['motive', 'motivasyon'],
  };

  static const Map<String, List<String>> _rhythm = {
    'sector_student': ['student', 'ogretim'],
    'sector_private': ['isci'],
    'sector_public': ['memur'],
    'sector_business': ['ticaret', 'motivasyon'],
    'sector_trade': ['ticaret', 'rizik', 'bereket'],
    'sector_household': ['ev_hayati', 'aile'],
    'sector_other': [],
    AppStrings.sectorStudent: ['student', 'ogretim'],
    AppStrings.sectorPrivate: ['isci'],
    AppStrings.sectorPublic: ['memur'],
    AppStrings.sectorBusiness: ['ticaret', 'motivasyon'],
    AppStrings.sectorTrade: ['ticaret', 'rizik', 'bereket'],
    AppStrings.sectorHousehold: ['ev_hayati', 'aile'],
    AppStrings.sectorOther: [],
  };

  static const Map<String, List<String>> _themes = {
    'need_motivation': ['motivasyon'],
    'need_sabr': ['sabr'],
    'need_shukr': ['sukur'],
    'need_tawakkul': ['tevekkul'],
    'need_focus': ['odaklanma'],
    'need_healing': ['sifa'],
    'need_rizq': ['rizik', 'bereket'],
    AppStrings.needMotivation: ['motivasyon'],
    AppStrings.needSabr: ['sabr'],
    AppStrings.needShukr: ['sukur'],
    AppStrings.needTawakkul: ['tevekkul'],
    AppStrings.needFocus: ['odaklanma'],
    AppStrings.needHealing: ['sifa'],
    AppStrings.needRizq: ['rizik', 'bereket'],
  };

  /// [moodTags], [sectorTags], [needTags] — Hive’daki ham seçim metinleri.
  static List<String> fromSelections({
    required List<String> moodTags,
    required List<String> sectorTags,
    required List<String> needTags,
  }) {
    final set = <String>{};
    for (final t in moodTags) {
      final stable = _normalizeMoodTag(t);
      set.addAll(_mood[stable] ?? _passThrough(stable));
    }
    for (final t in sectorTags) {
      final stable = _normalizeSectorTag(t);
      set.addAll(_rhythm[stable] ?? _passThrough(stable));
    }
    for (final t in needTags) {
      final stable = _normalizeNeedTag(t);
      set.addAll(_themes[stable] ?? _passThrough(stable));
    }
    return set.toList();
  }

  static String _normalizeMoodTag(String raw) {
    if (_mood.containsKey(raw)) return raw;
    final normalized = _normalizeLoose(raw);
    return _legacyToStableMood[normalized] ?? raw;
  }

  static String _normalizeSectorTag(String raw) {
    if (_rhythm.containsKey(raw)) return raw;
    final normalized = _normalizeLoose(raw);
    return _legacyToStableSector[normalized] ?? raw;
  }

  static String _normalizeNeedTag(String raw) {
    if (_themes.containsKey(raw)) return raw;
    final normalized = _normalizeLoose(raw);
    return _legacyToStableNeed[normalized] ?? raw;
  }

  static String _normalizeLoose(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  static List<String> _passThrough(String raw) {
    final s = _normalizeLoose(raw);
    if (s.isEmpty) return [];
    return [s];
  }
}
