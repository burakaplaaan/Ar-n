import 'dart:math';

import 'package:arin/data/inspiration/inspiration_content_mixer.dart';
import 'package:arin/data/models/inspiration_card_model.dart';
import 'package:arin/data/models/inspiration_content_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InspirationContentMixer', () {
    test('metinleri korur; arka plan ve tasarımı bağımsız karıştırır', () {
      final cards = List<InspirationCardModel>.generate(
        8,
        (index) => InspirationCardModel(
          id: 'q_$index',
          imageIndex: 99,
          tr: 'Korunacak söz $index',
          source: 'Kaynak $index',
          layoutIndex: 19,
          reelsStyle: 9,
          emphasisTailLines: 8,
          useLightTextOnImage: true,
        ),
      );

      final mixed = InspirationContentMixer.mix(
        cards: cards,
        imageIndices: const [1, 2, 3, 4],
        random: Random(7),
      );

      expect(mixed, hasLength(cards.length));
      expect(mixed.map((card) => card.tr), cards.map((card) => card.tr));
      expect(
        mixed.map((card) => card.source),
        cards.map((card) => card.source),
      );
      expect(mixed.map((card) => card.imageIndex).toSet(), {1, 2, 3, 4});
      expect(mixed.every((card) => card.reelsStyle != 9), isTrue);
      expect(mixed.every((card) => card.useLightTextOnImage == null), isTrue);

      for (var index = 1; index < mixed.length; index++) {
        expect(mixed[index].reelsStyle, isNot(mixed[index - 1].reelsStyle));
        expect(mixed[index].layoutIndex, isNot(mixed[index - 1].layoutIndex));
      }
    });

    test('Arapça içeriği okunaklı tasarım havuzunda tutar', () {
      const readableStyles = {0, 1, 2, 5, 6, 7, 8};
      final mixed = InspirationContentMixer.mix(
        cards: const [
          InspirationCardModel(
            id: 'verse_1',
            imageIndex: 1,
            tr: 'Bu ayetin Türkçe mealidir.',
            ar: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
            contentKind: InspirationContentKind.verse,
            reelsStyle: 11,
          ),
        ],
        imageIndices: const [10],
        random: Random(3),
      );

      expect(readableStyles, contains(mixed.single.reelsStyle));
    });

    test('220 karakterden uzun içeriği okunaklı tasarım havuzunda tutar', () {
      const readableStyles = {0, 1, 2, 5, 6, 7, 8};
      final cards = [
        const InspirationCardModel(id: 'short', imageIndex: 1, tr: 'Kısa söz'),
        InspirationCardModel(
          id: 'quote_long',
          imageIndex: 2,
          tr: List.filled(50, 'uzun').join(' '),
          reelsStyle: 12,
        ),
      ];

      final mixed = InspirationContentMixer.mix(
        cards: cards,
        imageIndices: const [10, 11],
        random: Random(3),
      );

      expect(cards.last.tr.runes.length, greaterThanOrEqualTo(220));
      expect(readableStyles, contains(mixed.last.reelsStyle));
    });

    test('boş görsel havuzunda kartların mevcut görsellerini kullanır', () {
      final mixed = InspirationContentMixer.mix(
        cards: const [
          InspirationCardModel(id: 'a', imageIndex: 5, tr: 'Bir'),
          InspirationCardModel(id: 'b', imageIndex: 6, tr: 'İki'),
        ],
        imageIndices: const [],
        random: Random(1),
      );

      expect(mixed.map((card) => card.imageIndex).toSet(), {5, 6});
    });

    test('geçersiz görsel indekslerini yok sayar', () {
      final mixed = InspirationContentMixer.mix(
        cards: const [InspirationCardModel(id: 'a', imageIndex: 7, tr: 'Söz')],
        imageIndices: const [-2, 0],
        random: Random(2),
      );

      expect(mixed.single.imageIndex, 7);
    });
  });
}
