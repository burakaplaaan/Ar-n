// Keşfet kartı: `imageIndex` → `assets/inspiration/{imageIndex}.jpg`
// Metin rengi: `useLightTextOnImage == null` ise görsel merkez parlaklığından otomatik.

import 'inspiration_content_kind.dart';
import '../../core/constants/inspiration_assets.dart';

class InspirationCardModel {
  const InspirationCardModel({
    required this.id,
    required this.imageIndex,
    required this.tr,
    this.ar,
    this.source,
    this.verseReference,
    this.layoutIndex = 0,
    this.reelsStyle = 0,
    this.emphasisTailLines = 0,
    this.useLightTextOnImage,
    this.contentKind = InspirationContentKind.quote,
    this.searchTags = const [],
    this.showInMainFeed = true,
  }) : assert(imageIndex >= 1);

  final String id;
  final int imageIndex;
  final String tr;
  final String? ar;
  final String? source;
  /// Kur’an âyeti kartlarında: sure / âyet bilgisi (yalnızca bu alan doluysa gösterilir).
  final String? verseReference;
  final int layoutIndex;
  /// 0–13: Reels katmanında font / hizalama varyantı.
  final int reelsStyle;
  /// Son kaç satır vurgu rengi (altın ton).
  final int emphasisTailLines;
  /// null → merkez parlaklığına göre otomatik açık/koyu yazı.
  final bool? useLightTextOnImage;

  /// Âyet / özlü söz / hadis-i şerif — filtre ve paylaşım metni için.
  final InspirationContentKind contentKind;

  /// Keşfet araması için ek anahtar kelimeler (JSON: `tags` veya `keywords`).
  final List<String> searchTags;

  /// Ana akış (Karma) filtresinde gösterilsin mi — âyet/hadis için varsayılan false;
  /// özlü söz için yerel korpus/Firestore varsayımları genelde true.
  final bool showInMainFeed;

  int get safeLayoutIndex => layoutIndex.clamp(0, 19);

  int get safeReelsStyle => reelsStyle.clamp(0, 13);

  int get safeEmphasisTailLines => emphasisTailLines.clamp(0, 12);

  /// Her zaman `N.jpg` kuralı (sınırsız N; keşif aralıksız tarar).
  String get resolvedImageAssetPath =>
      InspirationAssets.pathForIndex(imageIndex);

  /// Eski kod uyumu: asset yolu.
  String? get imageAsset => resolvedImageAssetPath;

  InspirationCardModel copyWith({
    String? id,
    int? imageIndex,
    String? tr,
    String? ar,
    String? source,
    String? verseReference,
    int? layoutIndex,
    int? reelsStyle,
    int? emphasisTailLines,
    bool? useLightTextOnImage,
    InspirationContentKind? contentKind,
    List<String>? searchTags,
    bool? showInMainFeed,
    bool clearAr = false,
    bool clearSource = false,
    bool clearVerseReference = false,
    bool clearUseLightTextOnImage = false,
    bool clearSearchTags = false,
  }) {
    return InspirationCardModel(
      id: id ?? this.id,
      imageIndex: imageIndex ?? this.imageIndex,
      tr: tr ?? this.tr,
      ar: clearAr ? null : (ar ?? this.ar),
      source: clearSource ? null : (source ?? this.source),
      verseReference:
          clearVerseReference ? null : (verseReference ?? this.verseReference),
      layoutIndex: layoutIndex ?? this.layoutIndex,
      reelsStyle: reelsStyle ?? this.reelsStyle,
      emphasisTailLines: emphasisTailLines ?? this.emphasisTailLines,
      useLightTextOnImage: clearUseLightTextOnImage
          ? null
          : (useLightTextOnImage ?? this.useLightTextOnImage),
      contentKind: contentKind ?? this.contentKind,
      searchTags: clearSearchTags
          ? const []
          : (searchTags ?? this.searchTags),
      showInMainFeed: showInMainFeed ?? this.showInMainFeed,
    );
  }

  static InspirationCardModel? tryFromFirestoreItem(Map<String, dynamic> m) {
    final idx = (m['imageIndex'] as num?)?.toInt();
    if (idx == null || idx < 1) return null;
    final trRaw = m['tr'];
    if (trRaw == null) return null;
    final tr = trRaw.toString().trim();
    if (tr.isEmpty) return null;

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

    final ul = m['useLightTextOnImage'];
    bool? useLight;
    if (ul is bool) {
      useLight = ul;
    }

    final kindRaw = m['contentKind'] ?? m['kind'];
    final kind = parseInspirationContentKind(kindRaw?.toString()) ??
        (verseReference != null
            ? InspirationContentKind.verse
            : InspirationContentKind.quote);

    final tags = parseInspirationSearchTags(m['tags'] ?? m['keywords']);

    final mainRaw = m['showInMainFeed'] ?? m['featuredInMainFeed'];
    final bool showMain;
    if (mainRaw is bool) {
      showMain = mainRaw;
    } else {
      showMain = kind == InspirationContentKind.quote;
    }

    return InspirationCardModel(
      id: m['id']?.toString() ?? 'fs_$idx',
      imageIndex: idx,
      tr: tr,
      ar: ar,
      source: source,
      verseReference: verseReference,
      layoutIndex: (m['layoutIndex'] as num?)?.toInt() ?? 0,
      reelsStyle: (m['reelsStyle'] as num?)?.toInt() ?? 0,
      emphasisTailLines: (m['emphasisTailLines'] as num?)?.toInt() ?? 0,
      useLightTextOnImage: useLight,
      contentKind: kind,
      searchTags: tags,
      showInMainFeed: showMain,
    );
  }

  static List<String> parseInspirationSearchTags(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is String) {
      return raw
          .split(RegExp(r'[,;|]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}
