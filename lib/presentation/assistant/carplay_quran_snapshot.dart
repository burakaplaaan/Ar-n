import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_surah_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../qibla/quran/quran_audio_notifier.dart';

/// CarPlay şablonunun tek bakışı. Oynatıcı boşsa kayıtlı ayet gösterilir.
Map<String, Object?> buildCarPlayQuranSnapshot({
  required AppLocalizations l10n,
  required String languageCode,
  required QuranAudioState audio,
  required QuranProgress? saved,
  String? verse,
  bool includeCatalog = false,
}) {
  final rawSurah = audio.surah ?? saved?.surah ?? 1;
  final meta = QuranSurahCatalog.byNumber(rawSurah);
  final rawAyah = audio.ayah ??
      ((saved != null && saved.surah == meta.number) ? saved.ayah : 1);
  final ayah = rawAyah.clamp(1, meta.ayahCount);
  final name = meta.localizedName(languageCode);
  final map = <String, Object?>{
    'surah': meta.number,
    'ayah': ayah,
    'ayahCount': meta.ayahCount,
    'name': name,
    'arabic': meta.arabic,
    'playing': audio.isPlaying,
    'buffering': audio.buffering,
    'error': audio.error != null,
    'title': l10n.quranTitle,
    'listTitle': carPlaySurahListTitle(languageCode),
    'line': l10n.quranNowPlaying(name, ayah),
    'ayahLine': l10n.quranAyahLabel(ayah),
    'countLabel': l10n.quranAyahCount(meta.ayahCount),
    'reciter': l10n.quranReciterName,
    'errorText': l10n.quranAudioError,
    'language': languageCode,
  };
  final shown = verse?.trim();
  if (shown != null && shown.isNotEmpty) {
    map['verse'] = shown;
  }
  if (includeCatalog) {
    map['surahs'] = [
      for (final item in QuranSurahCatalog.all)
        <String, Object?>{
          'n': item.number,
          'name': item.localizedName(languageCode),
          'arabic': item.arabic,
          'count': item.ayahCount,
          'countLabel': l10n.quranAyahCount(item.ayahCount),
        },
    ];
  }
  return map;
}

String carPlaySurahListTitle(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'ar':
      return 'السور';
    case 'en':
      return 'Surahs';
    default:
      return 'Sureler';
  }
}
