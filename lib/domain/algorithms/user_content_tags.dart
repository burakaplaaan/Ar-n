// lib/domain/algorithms/user_content_tags.dart
// Anketten gelen görünen metinleri, content_pool / Firestore havuzundaki
// küçük harf + ASCII etiketlerine çevirir (ContentMatcher ile örtüşme).

import '../../core/constants/app_strings.dart';

abstract final class UserContentTags {
  static const Map<String, List<String>> _mood = {
    AppStrings.moodHappy: ['mutlu'],
    AppStrings.moodCalm: ['sakin'],
    AppStrings.moodStressed: ['stresli'],
    AppStrings.moodSad: ['uzgun'],
    AppStrings.moodGrateful: ['sukur', 'mutlu'],
    AppStrings.moodAnxious: ['kaygi'],
    AppStrings.moodMotivated: ['motive', 'motivasyon'],
  };

  static const Map<String, List<String>> _rhythm = {
    AppStrings.sectorStudent: ['student', 'ogretim'],
    AppStrings.sectorPrivate: ['isci'],
    AppStrings.sectorPublic: ['memur'],
    AppStrings.sectorBusiness: ['ticaret', 'motivasyon'],
    AppStrings.sectorTrade: ['ticaret', 'rizik', 'bereket'],
    AppStrings.sectorHousehold: ['ev_hayati', 'aile'],
    AppStrings.sectorOther: [],
  };

  static const Map<String, List<String>> _themes = {
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
      set.addAll(_mood[t] ?? _passThrough(t));
    }
    for (final t in sectorTags) {
      set.addAll(_rhythm[t] ?? _passThrough(t));
    }
    for (final t in needTags) {
      set.addAll(_themes[t] ?? _passThrough(t));
    }
    return set.toList();
  }

  static List<String> _passThrough(String raw) {
    final s = raw
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (s.isEmpty) return [];
    return [s];
  }
}
