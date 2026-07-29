import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/inspiration_card_model.dart';
import '../models/inspiration_content_kind.dart';

/// Yerel JSON korpusu: `assets/data/inspiration/{verses,quotes,hadiths}.json`
/// — [InspirationCardModel] listesine çevrilir. Bağımsız arka plan ve tipografi
/// eşlemesi katalog katmanındaki `InspirationContentMixer` tarafından yapılır.
abstract final class InspirationLocalCorpusLoader {
  static const _versesAsset = 'assets/data/inspiration/verses.json';
  static const _quotesAsset = 'assets/data/inspiration/quotes.json';
  static const _hadithsAsset = 'assets/data/inspiration/hadiths.json';

  /// Yerel korpusta âyet / hadis üst sınırı (sözler sınırsız).
  static const int maxVersesInCorpus = 50;
  static const int maxHadithsInCorpus = 50;

  static Future<List<InspirationCardModel>> tryLoadMerged({
    required List<int> indices,
  }) async {
    if (indices.isEmpty) return const [];

    var verseRows = await _tryLoadListAsset(_versesAsset);
    final quoteRows = await _tryLoadListAsset(_quotesAsset);
    var hadithRows = await _tryLoadListAsset(_hadithsAsset);
    if (verseRows.length > maxVersesInCorpus) {
      verseRows = verseRows.sublist(0, maxVersesInCorpus);
    }
    if (hadithRows.length > maxHadithsInCorpus) {
      hadithRows = hadithRows.sublist(0, maxHadithsInCorpus);
    }

    if (verseRows.isEmpty && quoteRows.isEmpty && hadithRows.isEmpty) {
      return const [];
    }

    final out = <InspirationCardModel>[];
    var bg = 0;
    int nextIndex() {
      final v = indices[bg % indices.length];
      bg++;
      return v;
    }

    void addFrom(List<dynamic> rows, InspirationContentKind defaultKind) {
      for (final raw in rows) {
        if (raw is! Map<String, dynamic>) continue;
        final card = _parseRow(raw, nextIndex(), defaultKind);
        if (card != null) out.add(card);
      }
    }

    addFrom(verseRows, InspirationContentKind.verse);
    addFrom(quoteRows, InspirationContentKind.quote);
    addFrom(hadithRows, InspirationContentKind.hadith);

    if (out.isEmpty) return out;

    if (kDebugMode) {
      final v = out
          .where((c) => c.contentKind == InspirationContentKind.verse)
          .length;
      final q = out
          .where((c) => c.contentKind == InspirationContentKind.quote)
          .length;
      final h = out
          .where((c) => c.contentKind == InspirationContentKind.hadith)
          .length;
      debugPrint(
        'InspirationLocalCorpusLoader: ${out.length} kart (âyet: $v, söz: $q, hadis: $h), '
        '${indices.length} arka plan görseli.',
      );
    }

    return out;
  }

  static Future<List<dynamic>> _tryLoadListAsset(String path) async {
    try {
      final s = await rootBundle.loadString(path);
      final decoded = jsonDecode(s);
      if (decoded is List<dynamic>) return decoded;
      if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        return decoded['items']! as List<dynamic>;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('InspirationLocalCorpusLoader: $path yüklenemedi: $e\n$st');
      }
    }
    return const [];
  }

  static InspirationCardModel? _parseRow(
    Map<String, dynamic> m,
    int imageIndex,
    InspirationContentKind defaultKind,
  ) {
    final id = m['id']?.toString().trim();
    final tr = m['tr']?.toString().trim();
    if (id == null || id.isEmpty || tr == null || tr.isEmpty) return null;

    final arRaw = m['ar'];
    final ar = arRaw == null || arRaw.toString().trim().isEmpty
        ? null
        : arRaw.toString().trim();

    final srcRaw = m['source'];
    final source = srcRaw == null || srcRaw.toString().trim().isEmpty
        ? null
        : srcRaw.toString().trim();

    final vrRaw = m['verseReference'];
    final verseReference = vrRaw == null || vrRaw.toString().trim().isEmpty
        ? null
        : vrRaw.toString().trim();

    // Dosya adı türü belirler: yanlış dosyaya konan satırlar filtrelerde karışmasın.
    final kind = defaultKind;

    var layoutIndex = (m['layoutIndex'] as num?)?.toInt() ?? 0;
    var reelsStyle = (m['reelsStyle'] as num?)?.toInt() ?? 0;
    var emphasisTailLines = (m['emphasisTailLines'] as num?)?.toInt() ?? 0;
    // Hadis ve ayetler uygulamada tek tip (Arapçalı) tasarım ile gösterilir.
    if (kind == InspirationContentKind.hadith ||
        kind == InspirationContentKind.verse) {
      layoutIndex = 8;
      reelsStyle = 13;
      emphasisTailLines = 0;
    }

    final ul = m['useLightTextOnImage'];
    bool? useLight;
    if (ul is bool) useLight = ul;

    final idx = (m['imageIndex'] as num?)?.toInt();
    final resolvedImage = (idx != null && idx >= 1) ? idx : imageIndex;

    final tags = InspirationCardModel.parseInspirationSearchTags(
      m['tags'] ?? m['keywords'],
    );

    final mainRaw = m['showInMainFeed'] ?? m['featuredInMainFeed'];
    final bool showMain;
    if (mainRaw is bool) {
      showMain = mainRaw;
    } else {
      showMain = true;
    }

    return InspirationCardModel(
      id: id,
      imageIndex: resolvedImage,
      tr: tr,
      ar: ar,
      source: source,
      verseReference: verseReference,
      layoutIndex: layoutIndex,
      reelsStyle: reelsStyle,
      emphasisTailLines: emphasisTailLines,
      useLightTextOnImage: useLight ?? true,
      contentKind: kind,
      searchTags: tags,
      showInMainFeed: showMain,
    );
  }
}
