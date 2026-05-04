part of 'admin_content_page.dart';

/// Keşfet satırı: metin kutuları + tasarım meta (JSON yok).
class _InspireFormRow {
  _InspireFormRow({
    required this.tr,
    required this.ar,
    required this.source,
    required this.verseRef,
    required this.design,
    required this.contentKind,
    required this.showInMainFeed,
    required this.savedFingerprint,
  });

  final TextEditingController tr;
  final TextEditingController ar;
  final TextEditingController source;
  final TextEditingController verseRef;
  Map<String, dynamic> design;
  InspirationContentKind contentKind;
  bool showInMainFeed;
  String savedFingerprint;

  void dispose() {
    tr.dispose();
    ar.dispose();
    source.dispose();
    verseRef.dispose();
  }

  static Map<String, dynamic> _sanitizeDesign(
    Map<String, dynamic> m,
    List<int> imageIndices,
    Random rng,
  ) {
    var imageIndex = (m['imageIndex'] as num?)?.toInt() ?? 0;
    if (imageIndex < 1 ||
        (imageIndices.isNotEmpty && !imageIndices.contains(imageIndex))) {
      imageIndex = imageIndices.isEmpty
          ? 1
          : imageIndices[rng.nextInt(imageIndices.length)];
    }
    final id = m['id']?.toString().trim();
    return <String, dynamic>{
      'id': (id != null && id.isNotEmpty)
          ? id
          : 'inspire_${DateTime.now().millisecondsSinceEpoch}_${rng.nextInt(1 << 20)}',
      'imageIndex': imageIndex,
      'layoutIndex': (m['layoutIndex'] as num?)?.toInt() ?? rng.nextInt(20),
      'reelsStyle': _reelsStyleFrom(m) ?? rng.nextInt(14),
      'emphasisTailLines':
          (m['emphasisTailLines'] as num?)?.toInt() ?? rng.nextInt(5),
      'useLightTextOnImage': m['useLightTextOnImage'] is bool
          ? m['useLightTextOnImage']
          : null,
    };
  }

  static int? _reelsStyleFrom(Map<String, dynamic> m) {
    final r = m['reelsStyle'];
    if (r is num) return r.toInt();
    if (r is bool) return r ? 1 : 0;
    return null;
  }

  factory _InspireFormRow.fromMap(
    Map<String, dynamic> m,
    List<int> imageIndices,
    Random rng,
  ) {
    final kind =
        parseInspirationContentKind(
          (m['contentKind'] ?? m['kind'])?.toString(),
        ) ??
        InspirationContentKind.quote;
    final mainRaw = m['showInMainFeed'] ?? m['featuredInMainFeed'];
    final bool showMain;
    if (mainRaw is bool) {
      showMain = mainRaw;
    } else {
      showMain = kind == InspirationContentKind.quote;
    }
    final row = _InspireFormRow(
      tr: TextEditingController(text: m['tr']?.toString() ?? ''),
      ar: TextEditingController(text: m['ar']?.toString() ?? ''),
      source: TextEditingController(text: m['source']?.toString() ?? ''),
      verseRef: TextEditingController(
        text: m['verseReference']?.toString() ?? '',
      ),
      design: _sanitizeDesign(m, imageIndices, rng),
      contentKind: kind,
      showInMainFeed: showMain,
      savedFingerprint: '',
    );
    row.savedFingerprint = row.fingerprint;
    return row;
  }

  factory _InspireFormRow.empty(List<int> imageIndices, Random rng) {
    final d = _sanitizeDesign(<String, dynamic>{}, imageIndices, rng);
    return _InspireFormRow(
      tr: TextEditingController(),
      ar: TextEditingController(),
      source: TextEditingController(),
      verseRef: TextEditingController(),
      design: d,
      contentKind: InspirationContentKind.quote,
      showInMainFeed: true,
      savedFingerprint: '',
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final trText = tr.text.trim();
    final out = <String, dynamic>{
      'id': design['id'],
      'imageIndex': design['imageIndex'],
      'tr': trText,
      'layoutIndex': design['layoutIndex'],
      'reelsStyle': design['reelsStyle'],
      'emphasisTailLines': design['emphasisTailLines'],
      'useLightTextOnImage': design['useLightTextOnImage'],
    };
    final arT = ar.text.trim();
    final src = source.text.trim();
    final vr = verseRef.text.trim();
    if (arT.isNotEmpty) out['ar'] = arT;
    if (src.isNotEmpty) out['source'] = src;
    if (vr.isNotEmpty) out['verseReference'] = vr;
    out['contentKind'] = contentKind.wireName;
    out['showInMainFeed'] = showInMainFeed;
    return out;
  }

  bool get hasUnsavedChanges => savedFingerprint != fingerprint;

  String get fingerprint => jsonEncode(toFirestoreMap());

  void rerollDesign(Random rng, List<int> imageIndices) {
    design = _sanitizeDesign(<String, dynamic>{}, imageIndices, rng);
  }
}
