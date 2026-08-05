/// Admin İçerik Performansı — reklam / özellik günlük metrik anahtarları.
///
/// Sunucudaki `_kProductFeatures` ile birebir aynı tutulmalı.
abstract final class ProductMetricFeatures {
  static const explore = 'explore';
  static const zikir = 'zikir';
  static const prayerAlarm = 'prayer_alarm';
  static const widget = 'widget';
  static const hilalDuel = 'hilal_duel';
  static const prayerCircle = 'prayer_circle';
  static const qibla = 'qibla';
  static const healing = 'healing';

  static const all = <String>[
    explore,
    zikir,
    prayerAlarm,
    widget,
    hilalDuel,
    prayerCircle,
    qibla,
    healing,
  ];

  static String labelTr(String feature) => switch (feature) {
    explore => 'Keşfet',
    zikir => 'Zikirmatik',
    prayerAlarm => 'Namaz bildirimi',
    widget => 'Widget',
    hilalDuel => 'Bilgi düellosu',
    prayerCircle => 'Dua halkası',
    qibla => 'Pusula',
    healing => 'Şifa frekansları',
    _ => feature,
  };
}
