import 'dart:math';

import '../models/inspiration_card_model.dart';
import '../models/inspiration_content_kind.dart';

/// Söz, tipografi ve arka planı birbirinden bağımsız eşler.
///
/// Tipografi tamamen rastgele seçilmez: uzun ve Arapça içeren metinler
/// okunaklı tasarımlarla, kısa sözler ise daha geniş bir tasarım havuzuyla
/// eşleştirilir.
abstract final class InspirationContentMixer {
  static List<InspirationCardModel> mix({
    required List<InspirationCardModel> cards,
    required List<int> imageIndices,
    Random? random,
  }) {
    if (cards.isEmpty) return const [];

    final rng = random ?? Random();
    final backgrounds =
        imageIndices.where((index) => index >= 1).toSet().toList()
          ..shuffle(rng);
    final fallbackBackgrounds =
        cards
            .map((card) => card.imageIndex)
            .where((index) => index >= 1)
            .toSet()
            .toList()
          ..shuffle(rng);
    final backgroundPool = backgrounds.isNotEmpty
        ? backgrounds
        : fallbackBackgrounds;

    var previousStyle = -1;
    var previousLayout = -1;

    return List<InspirationCardModel>.generate(cards.length, (index) {
      final card = cards[index];
      final stylePool = _reelsStylePool(card);
      final layoutPool = _layoutPool(card);
      final style = _pickDifferent(stylePool, previousStyle, rng);
      final layout = _pickDifferent(layoutPool, previousLayout, rng);
      previousStyle = style;
      previousLayout = layout;

      final lineCount = card.tr
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .length;
      final emphasis =
          card.contentKind == InspirationContentKind.quote && lineCount >= 3
          ? rng.nextInt(min(2, lineCount - 1) + 1)
          : 0;
      final background = backgroundPool.isEmpty
          ? card.imageIndex
          : backgroundPool[index % backgroundPool.length];

      return card.copyWith(
        imageIndex: background,
        reelsStyle: style,
        layoutIndex: layout,
        emphasisTailLines: emphasis,
        clearUseLightTextOnImage: true,
      );
    }, growable: false);
  }

  static List<int> _reelsStylePool(InspirationCardModel card) {
    final length = card.tr.runes.length + (card.ar?.runes.length ?? 0);
    final hasArabic = card.ar?.trim().isNotEmpty ?? false;

    if (hasArabic || length >= 220) {
      return const [0, 1, 2, 5, 6, 7, 8];
    }
    if (length >= 120) {
      return const [0, 1, 2, 5, 6, 7, 8, 13];
    }
    return const [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13];
  }

  static List<int> _layoutPool(InspirationCardModel card) {
    final length = card.tr.runes.length + (card.ar?.runes.length ?? 0);
    final hasArabic = card.ar?.trim().isNotEmpty ?? false;

    if (hasArabic || length >= 220) {
      return const [0, 2, 3, 6, 8, 11];
    }
    if (length >= 120) {
      return const [0, 2, 3, 5, 6, 7, 8, 11, 15];
    }
    return List<int>.generate(20, (index) => index, growable: false);
  }

  static int _pickDifferent(List<int> pool, int previous, Random rng) {
    if (pool.length == 1) return pool.single;
    final candidates = pool.where((value) => value != previous).toList();
    return candidates[rng.nextInt(candidates.length)];
  }
}
