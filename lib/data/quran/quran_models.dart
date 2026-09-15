// Kur'an veri modelleri — sure meta, ayet, okuyucu argümanı.

enum QuranMealLang {
  tr,
  en,
  none;

  static QuranMealLang fromLocaleCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'tr':
        return QuranMealLang.tr;
      case 'en':
        return QuranMealLang.en;
      default:
        return QuranMealLang.none;
    }
  }

  String get cacheKey => name;
}

class QuranSurahMeta {
  const QuranSurahMeta({
    required this.number,
    required this.ayahCount,
    required this.arabic,
    required this.transliteration,
    required this.nameTr,
    required this.nameEn,
    required this.meccan,
  });

  final int number;
  final int ayahCount;
  final String arabic;
  final String transliteration;
  final String nameTr;
  final String nameEn;
  final bool meccan;

  String localizedName(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ar':
        return arabic;
      case 'en':
        return nameEn;
      default:
        return nameTr;
    }
  }
}

class QuranAyah {
  const QuranAyah({
    required this.surah,
    required this.ayah,
    required this.arabic,
    required this.translation,
    required this.globalNumber,
    this.juz,
    this.page,
  });

  final int surah;
  final int ayah;
  final String arabic;
  final String translation;
  final int globalNumber;
  final int? juz;
  final int? page;
}

class QuranSurahContent {
  const QuranSurahContent({
    required this.meta,
    required this.ayahs,
    required this.mealLang,
  });

  final QuranSurahMeta meta;
  final List<QuranAyah> ayahs;
  final QuranMealLang mealLang;
}

class QuranReaderArgs {
  const QuranReaderArgs({
    required this.surah,
    this.ayah,
    this.autoplay = false,
  });

  final int surah;
  final int? ayah;
  final bool autoplay;
}

class QuranProgress {
  const QuranProgress({
    required this.surah,
    required this.ayah,
  });

  final int surah;
  final int ayah;
}
