String normalizeLocaleCode(String? raw) {
  final normalized = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
  if (normalized.startsWith('en')) return 'en';
  if (normalized.startsWith('ar')) return 'ar';
  return 'tr';
}

String? localizedPoolField(
  Map<String, dynamic> row, {
  required String baseKey,
  required String localeCode,
  List<String> legacyKeys = const <String>[],
}) {
  String? fromMap(String code) {
    final map = row[baseKey];
    if (map is! Map) return null;
    final direct = map[code]?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final lowered = map[code.toLowerCase()]?.toString().trim();
    if (lowered != null && lowered.isNotEmpty) return lowered;
    final upper = map[code.toUpperCase()]?.toString().trim();
    if (upper != null && upper.isNotEmpty) return upper;
    return null;
  }

  String? fromKey(String key) {
    final v = row[key]?.toString().trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  final locale = normalizeLocaleCode(localeCode);

  // Yeni şema: text_en / source_ar ya da text: {en: "...", ar: "..."}
  final direct = fromMap(locale) ?? fromKey('${baseKey}_$locale');
  if (direct != null) return direct;

  // Zorunlu fallback: Türkçe korunur.
  final tr = fromMap('tr') ?? fromKey('${baseKey}_tr');
  if (tr != null) return tr;

  // Legacy şemada Türkçe alan adı korunuyorsa onu diğerlerinden önce dene.
  if (locale != 'tr') {
    final legacyTr = row['turkish']?.toString().trim();
    if (legacyTr != null && legacyTr.isNotEmpty) return legacyTr;
  }

  // Son fallback: eski alan adları.
  for (final key in legacyKeys) {
    if (key == 'turkish' && locale != 'tr') continue;
    final legacy = row[key]?.toString().trim();
    if (legacy != null && legacy.isNotEmpty) return legacy;
  }

  return null;
}
