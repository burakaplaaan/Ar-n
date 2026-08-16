/// İlerleme sekmesindeki “Görevler” eşikleri — UI ve bildirim planı ortak.
abstract final class QuitAchievementMilestones {
  static const List<int> days = [
    1,
    2,
    3,
    5,
    7,
    10,
    14,
    21,
    30,
    45,
    60,
    66,
    90,
    120,
    180,
    270,
    365,
    500,
    730,
    1000,
  ];
}

/// Sayaç günü motivasyon eşikleri: ilk 5 gün, 10 / 20 / 30, sonra her 30 gün.
abstract final class QuitDurationMilestones {
  static const List<int> earlyDays = [1, 2, 3, 4, 5];
  static const List<int> midDays = [10, 20, 30];
  static const int monthlyStepDays = 30;
  static const int monthlyStartDays = 60;
  static const int monthlyCapDays = 3650;

  static List<int> allDays({int capDays = monthlyCapDays}) {
    final out = <int>[...earlyDays, ...midDays];
    for (var d = monthlyStartDays; d <= capDays; d += monthlyStepDays) {
      out.add(d);
    }
    return out;
  }
}

/// Toparlanma çubukları için bildirim yüzdeleri (alan başı 6 adet).
abstract final class QuitRecoveryNotificationThresholds {
  static const List<int> percents = [5, 10, 20, 50, 75, 100];
}
