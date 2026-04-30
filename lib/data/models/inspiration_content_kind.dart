/// Keşfet içerik türü — ızgara: âyet / özlü söz / hadis (filtreler ayrı).
enum InspirationContentKind {
  verse,
  quote,
  hadith,
}

InspirationContentKind? parseInspirationContentKind(String? raw) {
  if (raw == null) return null;
  switch (raw.trim().toLowerCase()) {
    case 'verse':
    case 'ayet':
    case 'âyet':
      return InspirationContentKind.verse;
    case 'quote':
    case 'söz':
    case 'soz':
      return InspirationContentKind.quote;
    case 'hadith':
    case 'hadis':
      return InspirationContentKind.hadith;
    default:
      return null;
  }
}

extension InspirationContentKindWire on InspirationContentKind {
  String get wireName {
    switch (this) {
      case InspirationContentKind.verse:
        return 'verse';
      case InspirationContentKind.quote:
        return 'quote';
      case InspirationContentKind.hadith:
        return 'hadith';
    }
  }
}
