// Bilgi Düellosu seviye / ödül yardımcıları — sunucu quiz.js ile aynı kurallar.

const int kHilalDuelMaxLevel = 20;
const int kHilalDuelForfeitPenalty = 5;
const int kHilalDuelGoldenCrescentWeeks = 10;

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

/// Seviye ödülleri — satılmaz, otomatik açılır.
enum HilalDuelRewardKind {
  frame,
  frameSilver,
  frameGold,
  title,
  avatarGlow,
  nameAccentSoft,
  specialHilal,
  hilalPulse,
  nameAccentGilt,
}

enum HilalDuelNameAccent { none, faint, soft, full, gilt }

class HilalDuelLevelReward {
  const HilalDuelLevelReward({
    required this.level,
    required this.kind,
    this.title,
  });

  final int level;
  final HilalDuelRewardKind kind;
  final String? title;
}

class HilalDuelCosmetics {
  const HilalDuelCosmetics({
    required this.frameTier,
    required this.avatarGlow,
    required this.nameAccent,
    required this.specialHilalIcon,
    required this.hilalPulse,
    required this.title,
  });

  static const none = HilalDuelCosmetics(
    frameTier: 0,
    avatarGlow: false,
    nameAccent: HilalDuelNameAccent.none,
    specialHilalIcon: false,
    hilalPulse: false,
    title: null,
  );

  /// 0 yok, 1 bronz (LV3), 2 gümüş çift halka (LV4), 3 altın çift halka (LV11).
  final int frameTier;
  final bool avatarGlow;
  final HilalDuelNameAccent nameAccent;
  final bool specialHilalIcon;
  final bool hilalPulse;
  final String? title;

  bool get avatarFrame => frameTier >= 1;
  bool get nameAccentFull =>
      nameAccent == HilalDuelNameAccent.full ||
      nameAccent == HilalDuelNameAccent.gilt;
  bool get nameAccentSoft => nameAccent == HilalDuelNameAccent.soft;
  bool get nameAccentFaint => nameAccent == HilalDuelNameAccent.faint;
  bool get nameAccentGilt => nameAccent == HilalDuelNameAccent.gilt;

  @override
  bool operator ==(Object other) =>
      other is HilalDuelCosmetics &&
      frameTier == other.frameTier &&
      avatarGlow == other.avatarGlow &&
      nameAccent == other.nameAccent &&
      specialHilalIcon == other.specialHilalIcon &&
      hilalPulse == other.hilalPulse &&
      title == other.title;

  @override
  int get hashCode => Object.hash(
        frameTier,
        avatarGlow,
        nameAccent,
        specialHilalIcon,
        hilalPulse,
        title,
      );
}

const List<HilalDuelLevelReward> kHilalDuelRewards = [
  HilalDuelLevelReward(level: 2, kind: HilalDuelRewardKind.title, title: 'Talebe'),
  HilalDuelLevelReward(level: 3, kind: HilalDuelRewardKind.title, title: 'Kayyım'),
  HilalDuelLevelReward(level: 3, kind: HilalDuelRewardKind.frame),
  HilalDuelLevelReward(level: 4, kind: HilalDuelRewardKind.title, title: 'Müezzin'),
  HilalDuelLevelReward(level: 4, kind: HilalDuelRewardKind.frameSilver),
  HilalDuelLevelReward(level: 5, kind: HilalDuelRewardKind.title, title: 'Hatip'),
  HilalDuelLevelReward(level: 6, kind: HilalDuelRewardKind.title, title: 'İmam'),
  HilalDuelLevelReward(level: 6, kind: HilalDuelRewardKind.avatarGlow),
  HilalDuelLevelReward(level: 7, kind: HilalDuelRewardKind.title, title: 'Vaiz'),
  HilalDuelLevelReward(level: 7, kind: HilalDuelRewardKind.nameAccentSoft),
  HilalDuelLevelReward(level: 8, kind: HilalDuelRewardKind.title, title: 'Hoca'),
  HilalDuelLevelReward(level: 8, kind: HilalDuelRewardKind.specialHilal),
  HilalDuelLevelReward(
    level: 9,
    kind: HilalDuelRewardKind.title,
    title: 'Müderris',
  ),
  HilalDuelLevelReward(level: 10, kind: HilalDuelRewardKind.title, title: 'Derviş'),
  HilalDuelLevelReward(level: 11, kind: HilalDuelRewardKind.title, title: 'Şeyh'),
  HilalDuelLevelReward(level: 11, kind: HilalDuelRewardKind.frameGold),
  HilalDuelLevelReward(level: 13, kind: HilalDuelRewardKind.title, title: 'Müftü'),
  HilalDuelLevelReward(level: 13, kind: HilalDuelRewardKind.hilalPulse),
  HilalDuelLevelReward(level: 15, kind: HilalDuelRewardKind.title, title: 'Kadı'),
  HilalDuelLevelReward(
    level: 17,
    kind: HilalDuelRewardKind.title,
    title: 'Kazasker',
  ),
  HilalDuelLevelReward(level: 17, kind: HilalDuelRewardKind.nameAccentGilt),
  HilalDuelLevelReward(
    level: 19,
    kind: HilalDuelRewardKind.title,
    title: 'Şeyhülislam',
  ),
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

int clampedHilalLevel(int rawLevel) {
  if (rawLevel < 1) return 1;
  if (rawLevel > kHilalDuelMaxLevel) return kHilalDuelMaxLevel;
  return rawLevel;
}

int _frameTierForLevel(int level) {
  if (level >= 11) return 3;
  if (level >= 4) return 2;
  if (level >= 3) return 1;
  return 0;
}

HilalDuelNameAccent _nameAccentForLevel(int level) {
  if (level >= 17) return HilalDuelNameAccent.gilt;
  if (level >= 10) return HilalDuelNameAccent.full;
  if (level >= 7) return HilalDuelNameAccent.soft;
  if (level >= 6) return HilalDuelNameAccent.faint;
  return HilalDuelNameAccent.none;
}

int championWeeksOf(int rawWeeks) {
  if (rawWeeks < 0) return 0;
  return rawWeeks;
}

bool hasGoldenCrescent(int rawWeeks) =>
    championWeeksOf(rawWeeks) >= kHilalDuelGoldenCrescentWeeks;

/// Görsel kozmetikler seviyedendir; eski sunucu alanı olmasa da çalışır.
/// Haftalık listedeki botlar kozmetik almaz (`isBot: true`).
HilalDuelCosmetics cosmeticsForLevel(int rawLevel, {bool isBot = false}) {
  if (isBot) return HilalDuelCosmetics.none;
  final level = clampedHilalLevel(rawLevel);
  return HilalDuelCosmetics(
    frameTier: _frameTierForLevel(level),
    avatarGlow: level >= 6,
    nameAccent: _nameAccentForLevel(level),
    specialHilalIcon: level >= 8,
    hilalPulse: level >= 13,
    title: titleForLevel(level),
  );
}

/// 15 bilindik rütbe, 20 basamak. LV11–12 / 13–14 / 15–16 / 17–18 / 19–20 çift.
String titleForLevel(int rawLevel) {
  final level = clampedHilalLevel(rawLevel);
  if (level >= 19) return 'Şeyhülislam';
  if (level >= 17) return 'Kazasker';
  if (level >= 15) return 'Kadı';
  if (level >= 13) return 'Müftü';
  if (level >= 11) return 'Şeyh';
  if (level >= 10) return 'Derviş';
  if (level >= 9) return 'Müderris';
  if (level >= 8) return 'Hoca';
  if (level >= 7) return 'Vaiz';
  if (level >= 6) return 'İmam';
  if (level >= 5) return 'Hatip';
  if (level >= 4) return 'Müezzin';
  if (level >= 3) return 'Kayyım';
  if (level >= 2) return 'Talebe';
  return 'Çömez';
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
