const kSocialPostMin = 12;
const kSocialPostMax = 280;
const kSocialCommentMin = 2;
const kSocialCommentMax = 200;
const kSocialUsernameMin = 3;
const kSocialUsernameMax = 16;
const kSocialBioMin = 8;
const kSocialBioMax = 80;

final _reservedUsernames = <String>{
  'arin',
  'admin',
  'support',
  'destek',
  'moderasyon',
  'moderator',
  'yardim',
  'help',
};

String socialUsernameKey(String raw) {
  return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
}

String socialUsernameAsciiKey(String raw) {
  return raw
      .trim()
      .replaceAll('İ', 'i')
      .replaceAll('I', 'i')
      .replaceAll('ı', 'i')
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '');
}

bool isSocialUsernameValid(String raw) {
  final display = raw.trim();
  if (display.length < kSocialUsernameMin ||
      display.length > kSocialUsernameMax) {
    return false;
  }
  if (!RegExp(r'^[\p{L}\p{N}_]+$', unicode: true).hasMatch(display)) {
    return false;
  }
  if (containsSocialInsult(display)) return false;
  return !_reservedUsernames.contains(socialUsernameKey(display)) &&
      !_reservedUsernames.contains(socialUsernameAsciiKey(display));
}

String normalizeSocialBody(String raw) => raw.replaceAll(RegExp(r'\s+'), ' ').trim();

/// X benzeri gövde: ilk satır / ilk cümle ayrı, kalanı ikinci blok.
({String lead, String? rest}) socialLeadLine(String raw) {
  final text = raw.replaceAll('\r\n', '\n').trim();
  if (text.isEmpty) return (lead: text, rest: null);
  final newline = text.indexOf('\n');
  if (newline > 0 && newline < text.length - 1) {
    final lead = text.substring(0, newline).trim();
    final rest = text.substring(newline + 1).trim();
    if (lead.isNotEmpty && rest.isNotEmpty) {
      return (lead: lead, rest: rest);
    }
  }
  final sentence = RegExp(
    r'^(.{12,90}?[.?!\u2026\u061F])(?:\s+)(.+)$',
    unicode: true,
    dotAll: true,
  ).firstMatch(text);
  if (sentence != null) {
    final rest = sentence.group(2)!.trim();
    if (rest.isNotEmpty) {
      return (lead: sentence.group(1)!, rest: rest);
    }
  }
  return (lead: text, rest: null);
}

final _chipOnly = RegExp(
  r"^(bugün şükür|bir ayet|dua iste|today's thanks|a verse|ask for dua|شكر اليوم|آية|اطلب دعاء)\s*:?\s*$",
  caseSensitive: false,
  unicode: true,
);

bool isSocialChipOnly(String raw) => _chipOnly.hasMatch(normalizeSocialBody(raw));

bool isSocialPostValid(String raw) {
  final value = normalizeSocialBody(raw);
  return value.length >= kSocialPostMin &&
      value.length <= kSocialPostMax &&
      !isSocialChipOnly(value) &&
      !containsSocialInsult(value);
}

bool isSocialCommentValid(String raw) {
  final value = normalizeSocialBody(raw);
  return value.length >= kSocialCommentMin &&
      value.length <= kSocialCommentMax &&
      !containsSocialInsult(value);
}

bool isSocialBioValid(String raw) {
  final value = normalizeSocialBody(raw);
  return value.length >= kSocialBioMin &&
      value.length <= kSocialBioMax &&
      !containsSocialInsult(value);
}

const _insultWords = <String>{
  'orospu',
  'orospucocugu',
  'sikik',
  'sikeyim',
  'siktir',
  'hassiktir',
  'sikerim',
  'sikiyim',
  'aminakoyayim',
  'aminakoyim',
  'amcik',
  'amk',
  'amq',
  'pic',
  'ibne',
  'kahpe',
  'pezevenk',
  'gavat',
  'yavsak',
  'yarrak',
  'yarak',
  'gotveren',
  'serefsiz',
  'gerizekali',
  'pust',
  'sik',
  'aq',
  'oc',
  'ananisikeyim',
  'bacinisikeyim',
  'dangalak',
  'haysiyetsiz',
  'namussuz',
  'kevashe',
  'kevase',
  'gotlek',
  'fuck',
  'bitch',
  'nigger',
  'cunt',
  'whore',
  'faggot',
};

const _insultPhrases = <String>[
  'orospu',
  'orospucocugu',
  'sikeyim',
  'siktir',
  'hassiktir',
  'sikerim',
  'sikiyim',
  'aminakoyayim',
  'aminakoyim',
  'amcik',
  'pezevenk',
  'yarrak',
  'gotveren',
  'serefsiz',
  'gerizekali',
  'ananisikeyim',
  'bacinisikeyim',
  'orospuevladi',
  'kahpe',
  'ibne',
  'yavsak',
];

const _insultExact = <String>{'sik', 'amk', 'amq', 'aq', 'oc', 'pic'};

String _foldSocialInsult(String raw) {
  return raw
      .replaceAll('İ', 'i')
      .replaceAll('I', 'i')
      .replaceAll('ı', 'i')
      .toLowerCase()
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll('@', 'a')
      .replaceAll('4', 'a')
      .replaceAll('0', 'o')
      .replaceAll('1', 'i')
      .replaceAll('!', 'i')
      .replaceAll('|', 'i')
      .replaceAll('3', 'e')
      .replaceAll('\$', 's')
      .replaceAll('5', 's')
      .replaceAll('7', 't');
}

bool containsSocialInsult(String raw) {
  final folded = _foldSocialInsult(raw);
  final spaced = folded.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  final collapsed = folded.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  if (_insultExact.contains(collapsed)) return true;
  for (final token in spaced.split(RegExp(r'\s+'))) {
    if (token.isNotEmpty && _insultWords.contains(token)) return true;
  }
  return _insultPhrases.any(collapsed.contains);
}

String socialRelativeTime(DateTime createdAt, DateTime now) {
  final delta = now.difference(createdAt);
  if (delta.inSeconds < 45) return 'şimdi';
  if (delta.inMinutes < 60) return '${delta.inMinutes} dk';
  if (delta.inHours < 24) return '${delta.inHours} sa';
  if (delta.inDays < 7) return '${delta.inDays} g';
  final weeks = (delta.inDays / 7).floor();
  if (weeks < 5) return '$weeks hf';
  final months = (delta.inDays / 30).floor();
  if (months < 12) return '$months ay';
  return '${(delta.inDays / 365).floor()} y';
}

const kSocialAvatarPaletteSize = 8;
const kSocialAvatarMax = 12;

/// Bundled 3D sticker busts. 0 = letter avatar, 1–10 = these assets.
const kSocialAvatarAssets = <String>[
  'assets/social/avatars/01.png',
  'assets/social/avatars/02.png',
  'assets/social/avatars/03.png',
  'assets/social/avatars/04.png',
  'assets/social/avatars/05.png',
  'assets/social/avatars/06.png',
  'assets/social/avatars/07.png',
  'assets/social/avatars/08.png',
  'assets/social/avatars/09.png',
  'assets/social/avatars/10.png',
];

int socialNormalizeAvatarId(Object? raw) {
  final id = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;
  if (id < 0 || id > kSocialAvatarMax) return 0;
  return id;
}

String? socialAvatarAsset(int avatarId) {
  if (avatarId < 1 || avatarId > kSocialAvatarAssets.length) return null;
  return kSocialAvatarAssets[avatarId - 1];
}

/// Stable 0..7 index from the username so the same person always gets
/// the same avatar color on every device.
int socialAvatarColorIndex(
  String username, [
  int modulo = kSocialAvatarPaletteSize,
]) {
  if (modulo <= 0) return 0;
  var hash = 0;
  for (final unit in socialUsernameKey(username).codeUnits) {
    hash = 0x1fffffff & ((hash * 31) + unit);
  }
  return hash % modulo;
}
