// test/diyanet_district_matcher_test.dart
//
// DiyanetDistrictMatcher doğruluk ve dayanıklılık testleri. Asset'e
// girmeden `debugSetFixtures` ile temsilcisel 20 kayıt enjekte eder,
// şu senaryoları kapsar:
//   1. Birebir eşleşme (KOCAELI/GEBZE)
//   2. Türkçe karakter varyantları (KOCAELİ / kocaeli / Kocaeli / KOCAELI)
//   3. Android Geocoder'ın virgüllü bileşik çıktısı ("İzmit/Kocaeli")
//   4. Eşleşme yok → il merkezine fallback
//   5. İl adı tamamen yanlış → null
//   6. İl boş/null → null

import 'package:arin/data/services/diyanet_district_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixtures = <DiyanetDistrict>[
  DiyanetDistrict(id: 9648, ilce: 'ÇAYIROVA',  ilId: 551, il: 'KOCAELİ'),
  DiyanetDistrict(id: 9649, ilce: 'DARICA',    ilId: 551, il: 'KOCAELİ'),
  DiyanetDistrict(id: 9650, ilce: 'DİLOVASI',  ilId: 551, il: 'KOCAELİ'),
  DiyanetDistrict(id: 9651, ilce: 'GEBZE',     ilId: 551, il: 'KOCAELİ'),
  DiyanetDistrict(id: 9652, ilce: 'KANDIRA',   ilId: 551, il: 'KOCAELİ'),
  DiyanetDistrict(id: 9653, ilce: 'KARAMÜRSEL', ilId: 551, il: 'KOCAELİ'),
  DiyanetDistrict(id: 17902, ilce: 'KARTEPE',  ilId: 551, il: 'KOCAELİ'),
  DiyanetDistrict(id: 9654, ilce: 'KOCAELİ',   ilId: 551, il: 'KOCAELİ'),
  DiyanetDistrict(id: 9655, ilce: 'KÖRFEZ',    ilId: 551, il: 'KOCAELİ'),
  DiyanetDistrict(id: 9541, ilce: 'İSTANBUL',  ilId: 539, il: 'İSTANBUL'),
  DiyanetDistrict(id: 9536, ilce: 'BEYLİKDÜZÜ', ilId: 539, il: 'İSTANBUL'),
  DiyanetDistrict(id: 9535, ilce: 'ARNAVUTKÖY', ilId: 539, il: 'İSTANBUL'),
];

void main() {
  setUp(() {
    DiyanetDistrictMatcher.debugSetFixtures(_fixtures);
  });

  group('birebir eşleşme', () {
    test('KOCAELİ / GEBZE → id=9651', () {
      final d = DiyanetDistrictMatcher.match(
        ilAdi: 'KOCAELİ',
        ilceAdi: 'GEBZE',
      );
      expect(d?.id, 9651);
    });

    test('İSTANBUL / BEYLİKDÜZÜ → id=9536', () {
      final d = DiyanetDistrictMatcher.match(
        ilAdi: 'İSTANBUL',
        ilceAdi: 'BEYLİKDÜZÜ',
      );
      expect(d?.id, 9536);
    });
  });

  group('Türkçe karakter / case varyantları', () {
    test('kocaeli / gebze (küçük harf)', () {
      expect(
        DiyanetDistrictMatcher.match(ilAdi: 'kocaeli', ilceAdi: 'gebze')?.id,
        9651,
      );
    });

    test('Kocaeli / Gebze (title)', () {
      expect(
        DiyanetDistrictMatcher.match(ilAdi: 'Kocaeli', ilceAdi: 'Gebze')?.id,
        9651,
      );
    });

    test('KOCAELI (noktasız I) / KÖRFEZ', () {
      expect(
        DiyanetDistrictMatcher.match(ilAdi: 'KOCAELI', ilceAdi: 'KÖRFEZ')?.id,
        9655,
      );
    });

    test('Korfez (türkçesiz) → KÖRFEZ', () {
      expect(
        DiyanetDistrictMatcher.match(ilAdi: 'Kocaeli', ilceAdi: 'Korfez')?.id,
        9655,
      );
    });

    test('Dilovasi → DİLOVASI', () {
      expect(
        DiyanetDistrictMatcher.match(ilAdi: 'Kocaeli', ilceAdi: 'Dilovasi')
            ?.id,
        9650,
      );
    });

    test('Cayirova → ÇAYIROVA', () {
      expect(
        DiyanetDistrictMatcher.match(ilAdi: 'Kocaeli', ilceAdi: 'Cayirova')
            ?.id,
        9648,
      );
    });

    test('Karamursel → KARAMÜRSEL', () {
      expect(
        DiyanetDistrictMatcher.match(
          ilAdi: 'Kocaeli',
          ilceAdi: 'Karamursel',
        )?.id,
        9653,
      );
    });

    test('Arnavutkoy → ARNAVUTKÖY', () {
      expect(
        DiyanetDistrictMatcher.match(
          ilAdi: 'Istanbul',
          ilceAdi: 'Arnavutkoy',
        )?.id,
        9535,
      );
    });
  });

  group('geocoder bileşik çıktıları', () {
    test('"Gebze/Kocaeli" gibi slash birleşimi', () {
      expect(
        DiyanetDistrictMatcher.match(
          ilAdi: 'Kocaeli',
          ilceAdi: 'Gebze/Kocaeli',
        )?.id,
        9651,
      );
    });

    test('"Beylikdüzü, İstanbul" gibi virgüllü', () {
      expect(
        DiyanetDistrictMatcher.match(
          ilAdi: 'İstanbul',
          ilceAdi: 'Beylikdüzü, İstanbul',
        )?.id,
        9536,
      );
    });

    test('başında/sonunda boşluk', () {
      expect(
        DiyanetDistrictMatcher.match(
          ilAdi: '  Kocaeli  ',
          ilceAdi: '  Gebze  ',
        )?.id,
        9651,
      );
    });
  });

  group('fallback: il merkezi', () {
    test('Kocaeli + bilinmeyen ilçe → il merkezi (id=9654)', () {
      final d = DiyanetDistrictMatcher.match(
        ilAdi: 'Kocaeli',
        ilceAdi: 'Olmayan-Mahal',
      );
      expect(d?.id, 9654); // KOCAELİ merkez
    });

    test('İstanbul + Beyoğlu (asset\'te yok) → merkez (id=9541)', () {
      final d = DiyanetDistrictMatcher.match(
        ilAdi: 'İstanbul',
        ilceAdi: 'Beyoğlu',
      );
      expect(d?.id, 9541); // İSTANBUL merkez
    });

    test('ilçe null / boş → il merkezi', () {
      expect(
        DiyanetDistrictMatcher.match(ilAdi: 'Kocaeli', ilceAdi: null)?.id,
        9654,
      );
      expect(
        DiyanetDistrictMatcher.match(ilAdi: 'Kocaeli', ilceAdi: '')?.id,
        9654,
      );
    });
  });

  group('başarısızlık durumları', () {
    test('il adı tamamen yanlış → null', () {
      expect(
        DiyanetDistrictMatcher.match(
          ilAdi: 'Bilinmeyen-Il',
          ilceAdi: 'Gebze',
        ),
        isNull,
      );
    });

    test('il null → null', () {
      expect(
        DiyanetDistrictMatcher.match(ilAdi: null, ilceAdi: 'Gebze'),
        isNull,
      );
    });

    test('il boş string → null', () {
      expect(
        DiyanetDistrictMatcher.match(ilAdi: '   ', ilceAdi: 'Gebze'),
        isNull,
      );
    });
  });

  group('byId', () {
    test('mevcut id → kayıt', () {
      final d = DiyanetDistrictMatcher.byId(9651);
      expect(d?.ilce, 'GEBZE');
      expect(d?.il, 'KOCAELİ');
    });

    test('olmayan id → null', () {
      expect(DiyanetDistrictMatcher.byId(0), isNull);
    });
  });

  group('displayLabel', () {
    test('normal ilçe → "İlçe / İl" biçiminde ayrık', () {
      final d = DiyanetDistrictMatcher.byId(9651); // GEBZE / KOCAELİ
      expect(d?.displayLabel.contains(' / '), isTrue);
      expect(d?.displayLabel.toLowerCase(), contains('gebze'));
    });

    test('il merkezi (ilçe=il) → ayracsız tek etiket', () {
      final d = DiyanetDistrictMatcher.byId(9654); // KOCAELİ merkez
      expect(d?.displayLabel.contains(' / '), isFalse);
    });
  });
}
