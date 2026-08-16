// Keşfet beğeni sayısı: söz kimliğinden sabit, şişirilmiş taban (201–2000).
// Kullanıcı beğenisi bu tabanın üzerine +1 eklenir; her açılışta aynı kalır.

const int kInspirationSeededLikeMin = 201;
const int kInspirationSeededLikeMax = 2000;

/// Söz kimliğinden belirleyici taban beğeni (aynı id → aynı sayı).
int inspirationSeededLikeCount(String cardId) {
  const span = kInspirationSeededLikeMax - kInspirationSeededLikeMin + 1;
  return kInspirationSeededLikeMin + (_fnv1a32(cardId) % span);
}

/// Gösterilen toplam: taban + ortak gerçek beğeniler + yerel iyimser fark.
int displayedInspirationLikeCount(
  String cardId, {
  required bool likedByUser,
  int remoteExtra = 0,
  bool remoteExtraLoaded = false,
  bool remoteIncludesUser = false,
}) {
  final base = inspirationSeededLikeCount(cardId);
  if (!remoteExtraLoaded) {
    return likedByUser ? base + 1 : base;
  }
  var extra = remoteExtra;
  if (likedByUser && !remoteIncludesUser) extra += 1;
  if (!likedByUser && remoteIncludesUser) extra -= 1;
  if (extra < 0) extra = 0;
  return base + extra;
}

/// 995 → `995`, 1100 → `1.1k`, 1500 → `1.5k`, 2000 → `2k`.
String formatInspirationLikeCount(int count) {
  final n = count < 0 ? 0 : count;
  if (n < 1000) return '$n';

  final tenths = (n / 100).round();
  final whole = tenths ~/ 10;
  final frac = tenths % 10;
  if (frac == 0) return '${whole}k';
  return '$whole.${frac}k';
}

int _fnv1a32(String input) {
  var hash = 0x811C9DC5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
