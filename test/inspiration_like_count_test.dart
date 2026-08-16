import 'package:arin/presentation/inspire/inspiration_like_count.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inspirationSeededLikeCount', () {
    test('aynı id her zaman aynı tabanı üretir', () {
      expect(
        inspirationSeededLikeCount('verse_araf_55'),
        inspirationSeededLikeCount('verse_araf_55'),
      );
    });

    test('taban 201–2000 aralığında kalır', () {
      const ids = <String>[
        '',
        'a',
        'q_1',
        'verse_araf_55',
        'hadith_long_id_örnek',
        'fs_42',
      ];
      for (final id in ids) {
        final n = inspirationSeededLikeCount(id);
        expect(n, inInclusiveRange(201, 2000), reason: id);
      }
    });

    test('çok sayıda id aralığı ve çeşitliliği korur', () {
      final counts = <int>{};
      var belowThousand = 0;
      var atLeastThousand = 0;
      for (var i = 0; i < 400; i++) {
        final n = inspirationSeededLikeCount('card_$i');
        expect(n, inInclusiveRange(201, 2000));
        counts.add(n);
        if (n < 1000) {
          belowThousand++;
        } else {
          atLeastThousand++;
        }
      }
      expect(counts.length, greaterThan(200));
      expect(belowThousand, greaterThan(0));
      expect(atLeastThousand, greaterThan(0));
    });
  });

  group('displayedInspirationLikeCount', () {
    test('uzak sayı yokken beğeni tabanın üzerine 1 ekler', () {
      const id = 'quote_x';
      final base = inspirationSeededLikeCount(id);
      expect(displayedInspirationLikeCount(id, likedByUser: false), base);
      expect(displayedInspirationLikeCount(id, likedByUser: true), base + 1);
    });

    test('ortak sayıyı herkese yansıtır', () {
      const id = 'quote_x';
      final base = inspirationSeededLikeCount(id);
      expect(
        displayedInspirationLikeCount(
          id,
          likedByUser: false,
          remoteExtra: 12,
          remoteExtraLoaded: true,
        ),
        base + 12,
      );
    });

    test('kullanıcı oyu henüz sunucuya yazılmadıysa +1 iyimser ekler', () {
      const id = 'quote_x';
      final base = inspirationSeededLikeCount(id);
      expect(
        displayedInspirationLikeCount(
          id,
          likedByUser: true,
          remoteExtra: 12,
          remoteExtraLoaded: true,
        ),
        base + 13,
      );
    });

    test('sunucuda sayılmış oy ikinci kez eklenmez', () {
      const id = 'quote_x';
      final base = inspirationSeededLikeCount(id);
      expect(
        displayedInspirationLikeCount(
          id,
          likedByUser: true,
          remoteExtra: 13,
          remoteExtraLoaded: true,
          remoteIncludesUser: true,
        ),
        base + 13,
      );
    });

    test('beğeni geri alınırken henüz düşmemiş sayaç 1 iner', () {
      const id = 'quote_x';
      final base = inspirationSeededLikeCount(id);
      expect(
        displayedInspirationLikeCount(
          id,
          likedByUser: false,
          remoteExtra: 13,
          remoteExtraLoaded: true,
          remoteIncludesUser: true,
        ),
        base + 12,
      );
    });
  });

  group('formatInspirationLikeCount', () {
    test('binin altında ham sayı gösterir', () {
      expect(formatInspirationLikeCount(201), '201');
      expect(formatInspirationLikeCount(600), '600');
      expect(formatInspirationLikeCount(995), '995');
      expect(formatInspirationLikeCount(999), '999');
    });

    test('bin ve üzerini k biçiminde yuvarlar', () {
      expect(formatInspirationLikeCount(1000), '1k');
      expect(formatInspirationLikeCount(1100), '1.1k');
      expect(formatInspirationLikeCount(1500), '1.5k');
      expect(formatInspirationLikeCount(1949), '1.9k');
      expect(formatInspirationLikeCount(1950), '2k');
      expect(formatInspirationLikeCount(2000), '2k');
      expect(formatInspirationLikeCount(2001), '2k');
    });

    test('negatif sayıyı 0 gösterir', () {
      expect(formatInspirationLikeCount(-3), '0');
    });
  });
}
