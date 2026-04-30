// lib/data/services/local_data_wipe_service.dart
// Çıkış / hesap sil: Hive + SharedPreferences + yerel bildirimler + widget
// temizliği. Apple App Store 5.1.1(v) ve Google Play Data Safety gereklilikleri
// için kullanıcıya ait tüm lokal yan etkilerin sıfırlanmasını garanti ediyoruz.

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/hive_boxes.dart';
import '../models/habit_log_model.dart';
import '../models/habit_model.dart';
import '../models/user_profile_model.dart';
import 'arin_local_notifications_plugin.dart';
import 'arin_widget_sync.dart';

abstract final class LocalDataWipeService {
  /// Tüm kullanıcı verilerini siler; profil kutusuna boş profil yazar.
  ///
  /// Silme sırası önemli:
  /// 1. Planlanmış yerel bildirimleri iptal et — kullanıcı hesabını silmiş
  ///    olsa bile native alarm manager'daki pending alarm'lar ezan / arınma
  ///    bildirimi fırlatmasın (Apple 5.1.1(v) ruhu: hiçbir kullanıcı izi
  ///    kalmamalı).
  /// 2. Ana ekran widget'larındaki veriyi sıfırla — home_widget plugin'i
  ///    SharedPreferences dışında ayrı depo kullanıyor, `prefs.clear()`
  ///    bunları temizlemez.
  /// 3. SharedPreferences'ı sil (flag'lar + user-sourced paths).
  /// 4. Hive kutularını sil (profil, habits, logs, caches).
  /// 5. Onboarding flag'ını false'a çevir ki kullanıcı sıfırdan akışa girsin.
  static Future<void> wipeAll(SharedPreferences prefs) async {
    await _cancelAllLocalNotifications();
    await _clearHomeWidgetData();

    await prefs.clear();

    await Hive.box<UserProfileModel>(HiveBoxes.userProfile)
        .put('profile', UserProfileModel.empty());

    await Hive.box<HabitModel>(HiveBoxes.habits).clear();
    await Hive.box<HabitLogModel>(HiveBoxes.habitLogs).clear();
    await Hive.box<String>(HiveBoxes.salatLogs).clear();
    if (Hive.isBoxOpen(HiveBoxes.quotesCache)) {
      await Hive.box<String>(HiveBoxes.quotesCache).clear();
    }
    if (Hive.isBoxOpen(HiveBoxes.prayerTimesCache)) {
      await Hive.box(HiveBoxes.prayerTimesCache).clear();
    }
    if (Hive.isBoxOpen(HiveBoxes.preferences)) {
      await Hive.box<dynamic>(HiveBoxes.preferences).clear();
    }

    await prefs.setBool('onboarding_completed', false);
  }

  /// Hesabı silinen / çıkış yapan kullanıcıya ezan, arınma, zikir, milestone
  /// gibi hiçbir yerel bildirim gelmemesi için pending alarm'ları sıfırlar.
  /// Plugin henüz initialize edilmediyse sessizce geçer — main.dart'da her
  /// zaman init edilir ama test ortamında güvence altındayız.
  static Future<void> _cancelAllLocalNotifications() async {
    if (kIsWeb) return;
    try {
      await arinLocalNotificationsPlugin.cancelAll();
    } catch (e, st) {
      debugPrint('LocalDataWipeService.cancelAll: $e\n$st');
    }
  }

  static Future<void> _clearHomeWidgetData() async {
    if (kIsWeb) return;
    await ArinWidgetSync.clearAll();
  }
}
