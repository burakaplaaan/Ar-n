import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keşfet: [mixed] = ana akış; [soz] = yalnızca özlü sözler; âyet/hadis ayrı.
enum ExploreContentFilter {
  /// Ana akış — tüm sözler + tikli âyet/hadis.
  mixed,
  /// Yalnızca özlü sözler (âyet/hadis yok).
  soz,
  ayet,
  hadis,
}

final exploreContentFilterProvider =
    StateProvider<ExploreContentFilter>((ref) => ExploreContentFilter.mixed);
