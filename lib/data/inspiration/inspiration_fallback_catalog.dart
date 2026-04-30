// Yerel yedek: yerel JSON korpusu yokken yalnızca tasarım (tipografi) — metin boş.
// Görseller: assets/inspiration/N.jpg

import '../models/inspiration_card_model.dart';
import '../models/inspiration_content_kind.dart';

/// Tasarım yuvaları: metin içermez; tipografi varyasyonu için reelsStyle / layout.
class _DesignSlot {
  const _DesignSlot({
    this.reelsStyle = 0,
    this.layoutIndex = 0,
    this.emphasisTailLines = 0,
  });

  final int reelsStyle;
  final int layoutIndex;
  final int emphasisTailLines;
}

const List<_DesignSlot> _designOnly = [
  _DesignSlot(reelsStyle: 7, layoutIndex: 0),
  _DesignSlot(reelsStyle: 3, layoutIndex: 2),
  _DesignSlot(reelsStyle: 0, layoutIndex: 1, emphasisTailLines: 2),
  _DesignSlot(reelsStyle: 0, layoutIndex: 4),
  _DesignSlot(reelsStyle: 4, layoutIndex: 8),
  _DesignSlot(reelsStyle: 0, layoutIndex: 10),
  _DesignSlot(reelsStyle: 13, layoutIndex: 3),
  _DesignSlot(reelsStyle: 10, layoutIndex: 5),
  _DesignSlot(reelsStyle: 11, layoutIndex: 6),
  _DesignSlot(reelsStyle: 12, layoutIndex: 7),
  _DesignSlot(reelsStyle: 5, layoutIndex: 9),
  _DesignSlot(reelsStyle: 6, layoutIndex: 11),
  _DesignSlot(reelsStyle: 8, layoutIndex: 12),
];

abstract final class InspirationFallbackCatalog {
  static int get templateCount => _designOnly.length;

  /// Korpusu olmayan indeksler için: görsel + boş metin (içerik `assets/data/inspiration/*.json`).
  static InspirationCardModel cardForImageIndex(int imageIndex) {
    assert(imageIndex >= 1);
    final slot = (imageIndex - 1) % _designOnly.length;
    final d = _designOnly[slot];
    return InspirationCardModel(
      id: 'design_$imageIndex',
      imageIndex: imageIndex,
      tr: ' ',
      ar: null,
      source: null,
      verseReference: null,
      layoutIndex: d.layoutIndex,
      reelsStyle: d.reelsStyle,
      emphasisTailLines: d.emphasisTailLines,
      useLightTextOnImage: true,
      contentKind: InspirationContentKind.quote,
      searchTags: const [],
      showInMainFeed: true,
    );
  }
}
