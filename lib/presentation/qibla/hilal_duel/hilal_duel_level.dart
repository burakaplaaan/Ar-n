// Bilgi Düellosu seviye / ödül yardımcıları — sunucu quiz.js ile aynı kurallar.

const int kHilalDuelMaxLevel = 10;
const int kHilalDuelForfeitPenalty = 5;

class HilalDuelLevelProgress {
  const HilalDuelLevelProgress({
    required this.level,
    required this.levelFloorHilals,
    required this.nextLevelHilals,
    required this.hilals,
    required this.maxLevel,
  });

  final int level;
  final int levelFloorHilals;
  final int nextLevelHilals;
  final int hilals;
  final bool maxLevel;

  int get hilalsInLevel => hilals - levelFloorHilals;

  double get progress {
    if (maxLevel) return 1;
    final span = nextLevelHilals - levelFloorHilals;
    if (span <= 0) return 1;
    return ((hilals - levelFloorHilals) / span).clamp(0, 1);
  }
}

/// Seviye ödülleri — satılmaz, otomatik açılır. LV 1–2 hediyesiz.
enum HilalDuelRewardKind {
  frame,
  frameSilver,
  titleTalebe,
  avatarGlow,
  nameAccentSoft,
  specialHilal,
  titleMuderris,
  titleIlimDostu,
}

enum HilalDuelNameAccent { none, soft, full }

class HilalDuelLevelReward {
  const HilalDuelLevelReward({
    required this.level,
    required this.kind,
  });

  final int level;
  final HilalDuelRewardKind kind;
}

class HilalDuelCosmetics {
  const HilalDuelCosmetics({
    required this.frameTier,
    required this.avatarGlow,
    required this.nameAccent,
    required this.specialHilalIcon,
    required this.title,
  });

  static const none = HilalDuelCosmetics(
    frameTier: 0,
    avatarGlow: false,
    nameAccent: HilalDuelNameAccent.none,
    specialHilalIcon: false,
    title: null,
  );

  /// 0 yok, 1 bronz çerçeve (LV3), 2 gümüş çift halka (LV4+).
  final int frameTier;
  final bool avatarGlow;
  final HilalDuelNameAccent nameAccent;
  final bool specialHilalIcon;
  final String? title;

  bool get avatarFrame => frameTier >= 1;
  bool get nameAccentFull => nameAccent == HilalDuelNameAccent.full;
  bool get nameAccentSoft => nameAccent == HilalDuelNameAccent.soft;

  @override
  bool operator ==(Object other) =>
      other is HilalDuelCosmetics &&
      frameTier == other.frameTier &&
      avatarGlow == other.avatarGlow &&
      nameAccent == other.nameAccent &&
      specialHilalIcon == other.specialHilalIcon &&
      title == other.title;

  @override
  int get hashCode => Object.hash(
        frameTier,
        avatarGlow,
        nameAccent,
        specialHilalIcon,
        title,
      );
}

const List<HilalDuelLevelReward> kHilalDuelRewards = [
  HilalDuelLevelReward(level: 3, kind: HilalDuelRewardKind.frame),
  HilalDuelLevelReward(level: 4, kind: HilalDuelRewardKind.frameSilver),
  HilalDuelLevelReward(level: 5, kind: HilalDuelRewardKind.titleTalebe),
  HilalDuelLevelReward(level: 6, kind: HilalDuelRewardKind.avatarGlow),
  HilalDuelLevelReward(level: 7, kind: HilalDuelRewardKind.nameAccentSoft),
  HilalDuelLevelReward(level: 8, kind: HilalDuelRewardKind.specialHilal),
  HilalDuelLevelReward(level: 9, kind: HilalDuelRewardKind.titleMuderris),
  HilalDuelLevelReward(level: 10, kind: HilalDuelRewardKind.titleIlimDostu),
];

/// [hilals] toplam hilal (eksi olabilir); seviye hesabı 0 tabanlıdır.
HilalDuelLevelProgress levelForHilals(int rawHilals) {
  final hilals = rawHilals < 0 ? 0 : rawHilals;
  var level = 1;
  var floor = 0;
  var nextCost = 40;
  while (hilals >= floor + nextCost && level < kHilalDuelMaxLevel) {
    floor += nextCost;
    level += 1;
    nextCost = 40 + (level - 1) * 15;
  }
  final maxed = level >= kHilalDuelMaxLevel;
  return HilalDuelLevelProgress(
    level: maxed ? kHilalDuelMaxLevel : level,
    levelFloorHilals: floor,
    nextLevelHilals: maxed ? floor : floor + nextCost,
    hilals: hilals,
    maxLevel: maxed,
  );
}

/// Hedef seviyenin taban hilali (admin seviye ayarı; sunucu ile aynı).
int hilalsFloorForLevel(int rawLevel) {
  final target = rawLevel < 1
      ? 1
      : (rawLevel > kHilalDuelMaxLevel ? kHilalDuelMaxLevel : rawLevel);
  var level = 1;
  var floor = 0;
  var nextCost = 40;
  while (level < target) {
    floor += nextCost;
    level += 1;
    nextCost = 40 + (level - 1) * 15;
  }
  return floor;
}

/// Maç hilal ödülü — sunucu `hilalAward` ile aynı.
int hilalAward({
  required int correct,
  required bool won,
  bool draw = false,
  int roundCount = 7,
}) {
  final safeCorrect = correct < 0 ? 0 : correct;
  return safeCorrect * 2 +
      (won ? 5 : 0) +
      (draw ? 2 : 0) +
      (safeCorrect == roundCount ? 3 : 0);
}

int _clampedLevel(int rawLevel) {
  if (rawLevel < 1) return 1;
  if (rawLevel > kHilalDuelMaxLevel) return kHilalDuelMaxLevel;
  return rawLevel;
}

/// Görsel kozmetikler seviyedendir; eski sunucu alanı olmasa da çalışır.
/// Haftalık listedeki botlar kozmetik almaz (`isBot: true`).
HilalDuelCosmetics cosmeticsForLevel(int rawLevel, {bool isBot = false}) {
  if (isBot) return HilalDuelCosmetics.none;
  final level = _clampedLevel(rawLevel);
  final HilalDuelNameAccent accent;
  if (level >= 10) {
    accent = HilalDuelNameAccent.full;
  } else if (level >= 7) {
    accent = HilalDuelNameAccent.soft;
  } else {
    accent = HilalDuelNameAccent.none;
  }
  return HilalDuelCosmetics(
    frameTier: level >= 4 ? 2 : (level >= 3 ? 1 : 0),
    avatarGlow: level >= 6,
    nameAccent: accent,
    specialHilalIcon: level >= 8,
    title: titleForLevel(level),
  );
}

String? titleForLevel(int level) {
  if (level >= 10) return 'İlim Dostu';
  if (level >= 9) return 'Müderris';
  if (level >= 5) return 'Talebe';
  return null;
}

bool hasAvatarFrame(int level) => cosmeticsForLevel(level).avatarFrame;
bool hasSpecialHilalIcon(int level) =>
    cosmeticsForLevel(level).specialHilalIcon;
bool hasNameAccent(int level) => cosmeticsForLevel(level).nameAccentFull;
bool hasAvatarGlow(int level) => cosmeticsForLevel(level).avatarGlow;

/// Bir sonraki kilitli ödül; yoksa null (maks seviye).
HilalDuelLevelReward? nextRewardAfterLevel(int level) {
  for (final reward in kHilalDuelRewards) {
    if (level < reward.level) return reward;
  }
  return null;
}
