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

/// Seviye ödülleri — satılmaz, otomatik açılır.
enum HilalDuelRewardKind { frame, titleTalebe, specialHilal, titleIlimDostu }

class HilalDuelLevelReward {
  const HilalDuelLevelReward({
    required this.level,
    required this.kind,
  });

  final int level;
  final HilalDuelRewardKind kind;
}

const List<HilalDuelLevelReward> kHilalDuelRewards = [
  HilalDuelLevelReward(level: 3, kind: HilalDuelRewardKind.frame),
  HilalDuelLevelReward(level: 5, kind: HilalDuelRewardKind.titleTalebe),
  HilalDuelLevelReward(level: 8, kind: HilalDuelRewardKind.specialHilal),
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

String? titleForLevel(int level) {
  if (level >= 10) return 'İlim Dostu';
  if (level >= 5) return 'Talebe';
  return null;
}

bool hasAvatarFrame(int level) => level >= 3;
bool hasSpecialHilalIcon(int level) => level >= 8;
bool hasNameAccent(int level) => level >= 10;

/// Bir sonraki kilitli ödül; yoksa null (maks seviye).
HilalDuelLevelReward? nextRewardAfterLevel(int level) {
  for (final reward in kHilalDuelRewards) {
    if (level < reward.level) return reward;
  }
  return null;
}
