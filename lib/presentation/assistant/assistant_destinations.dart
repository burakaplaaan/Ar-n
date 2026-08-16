// Kullanıcı cümlesinden Arın içi hedef ekran. Model araç çağırmasa da
// "gönder / aç" istekleri ve kilit-ekranı ayet sorusu burada çözülür.

class AssistantLocalRoute {
  const AssistantLocalRoute({
    required this.page,
    required this.kind,
  });

  final String page;
  final AssistantLocalKind kind;
}

enum AssistantLocalKind { navigate, lockVerseGuide }

final _explicitNav = RegExp(
  r'(gonder|gotur|yonlendir|gidelim|\bgit\b|\bgec\b|al beni|'
  r'\bac\b|acsana|acar\s+misin|'
  r'take me|send me|go to|open the|'
  r'افتح|أرسلني|خذني)',
  caseSensitive: false,
);

String foldAssistantText(String raw) {
  return raw
      .toLowerCase()
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('ı', 'i')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? matchAssistantPage(String raw) {
  final t = foldAssistantText(raw);
  if (t.isEmpty) return null;

  if (t.contains('zikirmatik') ||
      t.contains('zikirmatig') ||
      t.contains('zikir matik') ||
      t.contains('tesbih')) {
    return 'zikir';
  }
  if (t.contains('widget') ||
      ((t.contains('kilit') || t.contains('lock')) &&
          (t.contains('ayet') || t.contains('verse') || t.contains('ayah')))) {
    return 'widgets';
  }
  if (t.contains('iyilestirici') ||
      t.contains('iyileştirici') ||
      t.contains('frekans') ||
      t.contains('healing')) {
    return 'healing';
  }
  if (t.contains('nefes')) return 'breathing';
  if (t.contains('dua halk') || t.contains('prayer circle')) {
    return 'prayer_circle';
  }
  if (t.contains('duello') ||
      t.contains('düello') ||
      t.contains('hilal')) {
    return 'hilal_duel';
  }
  if (t.contains('kaza')) return 'kaza';
  if (t.contains('namaz program') || t.contains('ibadet')) return 'namaz';
  if (t.contains('kible') ||
      t.contains('kıble') ||
      t.contains('qibla') ||
      t.contains('pusula')) {
    return 'qibla';
  }
  if (t.contains('arinma') || t.contains('arınma') || t.contains('irade')) {
    return 'habits';
  }
  if (t.contains('kesfet') || t.contains('keşfet') || t.contains('inspire')) {
    return 'inspire';
  }
  if (t.contains('bildirim')) return 'notifications';
  if (t.contains('ayar')) return 'settings';
  if (t.contains('premium')) return 'premium';
  if (t.contains('anasayfa') || t.contains('ana sayfa')) return 'home';
  return null;
}

bool isExplicitAssistantNavigation(String raw) =>
    _explicitNav.hasMatch(foldAssistantText(raw));

bool isLockVerseHowTo(String raw) {
  final t = foldAssistantText(raw);
  final lock = t.contains('kilit') || t.contains('lock') || t.contains('قفل');
  final verse = t.contains('ayet') ||
      t.contains('verse') ||
      t.contains('ayah') ||
      t.contains('آية');
  return lock && verse;
}

AssistantLocalRoute? resolveAssistantLocalRoute(String raw) {
  if (isLockVerseHowTo(raw)) {
    return const AssistantLocalRoute(
      page: 'widgets',
      kind: AssistantLocalKind.lockVerseGuide,
    );
  }
  if (!isExplicitAssistantNavigation(raw)) return null;
  final page = matchAssistantPage(raw);
  if (page == null) return null;
  return AssistantLocalRoute(page: page, kind: AssistantLocalKind.navigate);
}
