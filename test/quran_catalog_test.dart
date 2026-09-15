import 'package:arin/data/quran/quran_surah_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('114 sure, 6236 ayet, global numara tutarlı', () {
    expect(QuranSurahCatalog.all.length, 114);
    expect(QuranSurahCatalog.ayahTotal, 6236);

    var sum = 0;
    for (var i = 0; i < QuranSurahCatalog.all.length; i++) {
      final s = QuranSurahCatalog.all[i];
      expect(s.number, i + 1);
      expect(s.ayahCount, greaterThan(0));
      sum += s.ayahCount;
    }
    expect(sum, 6236);

    expect(QuranSurahCatalog.globalAyahNumber(1, 1), 1);
    expect(QuranSurahCatalog.globalAyahNumber(1, 7), 7);
    expect(QuranSurahCatalog.globalAyahNumber(2, 1), 8);
    expect(QuranSurahCatalog.globalAyahNumber(114, 6), 6236);

    for (var g = 1; g <= 6236; g += 137) {
      final pair = QuranSurahCatalog.fromGlobal(g);
      expect(QuranSurahCatalog.globalAyahNumber(pair.$1, pair.$2), g);
    }
    expect(QuranSurahCatalog.fromGlobal(6236), (114, 6));
    expect(QuranSurahCatalog.showsBismillah(1), isFalse);
    expect(QuranSurahCatalog.showsBismillah(9), isFalse);
    expect(QuranSurahCatalog.showsBismillah(2), isTrue);
  });
}
