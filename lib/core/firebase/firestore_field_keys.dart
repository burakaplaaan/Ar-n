// Firestore `set(merge:)` native SDK, geçersiz map anahtarında Dart
// try/catch'e düşmeyen NSException ile SIGABRT atıyor.

/// Native parse kuralı: boş alan adı veya `__.*__` ayrılmış adı.
bool isSafeFirestoreFieldKey(String key) {
  if (key.isEmpty) return false;
  if (key.startsWith('__') && key.endsWith('__')) return false;
  return true;
}

/// [set]/[update] öncesi gömülü map'lerden native abort üreten anahtarları ayıklar.
/// [FieldValue] gibi sentinel değerler olduğu gibi bırakılır.
Map<String, dynamic> sanitizeFirestoreMap(Map<String, dynamic> input) {
  final out = <String, dynamic>{};
  input.forEach((key, value) {
    if (!isSafeFirestoreFieldKey(key)) return;
    out[key] = _sanitizeFirestoreValue(value);
  });
  return out;
}

Object? _sanitizeFirestoreValue(Object? value) {
  if (value is Map) {
    final nested = <String, dynamic>{};
    value.forEach((key, child) {
      nested[key.toString()] = child;
    });
    return sanitizeFirestoreMap(nested);
  }
  if (value is List) {
    return [for (final item in value) _sanitizeFirestoreValue(item)];
  }
  return value;
}
