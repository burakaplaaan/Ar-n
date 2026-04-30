import 'dart:math' as math;

import '../../data/models/inspiration_card_model.dart';

/// Keşfet araması: ş→s, ğ→g, ı→i vb. — "karde" / "kardes" → "kardeş" içeren metinler.
String inspirationSearchNormalize(String input) {
  var s = input.trim().toLowerCase();
  s = s.replaceAll('ı', 'i').replaceAll('İ', 'i');
  const fold = <String, String>{
    'ş': 's',
    'ğ': 'g',
    'ü': 'u',
    'ö': 'o',
    'ç': 'c',
    'â': 'a',
    'î': 'i',
    'û': 'u',
    'é': 'e',
    'ê': 'e',
    'à': 'a',
    'ñ': 'n',
  };
  fold.forEach((k, v) => s = s.replaceAll(k, v));
  return s;
}

/// Arama indeksi: metin + kaynak + referans + isteğe bağlı [InspirationCardModel.searchTags].
/// (Eski sürümdeki tür ipuçları kaldırıldı — "soz/hadis" her kartta olduğu için sahte eşleşme yaratıyordu.)
String _cardSearchHaystack(InspirationCardModel card) {
  final b = StringBuffer()
    ..write(inspirationSearchNormalize(card.tr))
    ..write(' ')
    ..write(inspirationSearchNormalize(card.ar ?? ''))
    ..write(' ')
    ..write(inspirationSearchNormalize(card.source ?? ''))
    ..write(' ')
    ..write(inspirationSearchNormalize(card.verseReference ?? ''));
  for (final t in card.searchTags) {
    b.write(' ');
    b.write(inspirationSearchNormalize(t));
  }
  return b.toString();
}

Iterable<String> _tokens(String normalizedHaystack) sync* {
  final split = RegExp(r'[^a-z0-9]+', caseSensitive: false);
  for (final p in normalizedHaystack.split(split)) {
    if (p.isNotEmpty) yield p;
  }
}

int _longestCommonPrefixLen(String a, String b) {
  final m = math.min(a.length, b.length);
  var n = 0;
  while (n < m && a.codeUnitAt(n) == b.codeUnitAt(n)) {
    n++;
  }
  return n;
}

/// Türkçe çekimleri: "mutluluk" ↔ "mutluluğu", "dua" ↔ "duasında" vb.
bool _tokenFuzzyMatches(String term, String token) {
  if (token.isEmpty || term.isEmpty) return false;
  if (token.contains(term)) {
    return term.length >= 2;
  }
  if (term.contains(token) && token.length >= 3) {
    return true;
  }
  if (term.length >= 3 && token.length >= 3) {
    final l = _longestCommonPrefixLen(term, token);
    if (l >= 4) return true;
    final shorter = math.min(term.length, token.length);
    if (shorter >= 5 && l >= shorter * 0.65) return true;
  }
  return false;
}

bool _termMatches(String term, InspirationCardModel card) {
  if (term.isEmpty) return true;
  final h = _cardSearchHaystack(card);
  if (h.contains(term)) return true;

  for (final tag in card.searchTags) {
    final nt = inspirationSearchNormalize(tag);
    if (nt.isEmpty) continue;
    if (nt == term || nt.contains(term) || (term.length >= 3 && term.contains(nt))) {
      return true;
    }
    if (_tokenFuzzyMatches(term, nt)) return true;
  }

  for (final tok in _tokens(h)) {
    if (_tokenFuzzyMatches(term, tok)) return true;
  }
  return false;
}

/// Boş sorgu → tüm kartlar. Kelimelerin hepsi (normalize + Türkçe kök) eşleşmeli.
bool inspirationCardMatchesQuery(InspirationCardModel card, String rawQuery) {
  final q = inspirationSearchNormalize(rawQuery);
  if (q.isEmpty) return true;
  for (final part in q.split(RegExp(r'\s+')).where((p) => p.isNotEmpty)) {
    if (!_termMatches(part, card)) return false;
  }
  return true;
}

/// Arama varken ızgara sıralaması: yüksek skor üstte (yalnızca eşleşen kartlar için).
int inspirationSearchRelevanceScore(
  InspirationCardModel card,
  String rawQuery,
) {
  final q = inspirationSearchNormalize(rawQuery).trim();
  if (q.isEmpty) return 0;

  final terms = q.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final h = _cardSearchHaystack(card);
  var score = 0;

  for (final t in terms) {
    if (t.isEmpty) continue;

    if (h.contains(t)) {
      score += 100;
      continue;
    }

    var best = 0;
    for (final tag in card.searchTags) {
      final nt = inspirationSearchNormalize(tag);
      if (nt.isEmpty) continue;
      if (nt == t) {
        best = math.max(best, 92);
      } else if (nt.contains(t) || (t.length >= 3 && t.contains(nt))) {
        best = math.max(best, 75);
      } else if (_tokenFuzzyMatches(t, nt)) {
        best = math.max(best, 60);
      }
    }

    for (final tok in _tokens(h)) {
      if (tok == t) {
        best = math.max(best, 88);
      } else if (_tokenFuzzyMatches(t, tok)) {
        final bonus = _longestCommonPrefixLen(t, tok);
        best = math.max(best, 42 + bonus);
      }
    }

    score += best;
  }

  return score;
}

/// `context.push(..., extra: …)` ile filtreli Reels desteği.
class InspireViewerDeckExtra {
  const InspireViewerDeckExtra({
    required this.cards,
    required this.initialIndex,
  });

  final List<InspirationCardModel> cards;
  final int initialIndex;
}
