// Kilit ekranı bildirim widget'ları (Android'e özel): namaz vakti, söz, karma,
// zikirmatik ve takip widget'larının kalıcı bir bildirim olarak kilit
// ekranında gösterilip gösterilmeyeceğini yönetir.
//
// Native taraf (`ArinLockNotifications.kt`) her bir tür için aynı
// `HomeWidgetPreferences` deposunu okur (ana ekran widget'larıyla aynı veri
// kaynağı) — bu sınıf yalnızca açma/kapama anahtarını yazar ve native'e
// "verileri yeniden oku, bildirimleri güncelle" sinyalini gönderir.
//
// NOT: Bu özellik yalnızca Android'de anlamlıdır (iOS'ta kilit ekranı
// widget'ları WidgetKit/Live Activity üzerinden resmi olarak destekleniyor).
// iOS'ta tüm metotlar sessizce no-op'tur.
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arin_local_notifications_plugin.dart';
import 'local_notification_permission_gate.dart';
import 'widget_access_service.dart';

abstract final class ArinLockNotificationService {
  static const _channel = MethodChannel('com.arin.arin/lock_notifications');

  /// Eski sürümde namaz/söz varsayılanı açıktı. v1 bu bayrağı yazar;
  /// artık kimseyi otomatik açmaz.
  static const legacyDefaultsMigratedKey =
      'lock_notif_defaults_off_v1_migrated';

  /// v1'in otomatik açtığı namaz/söz kilit bildirimlerini bir kez kapatır.
  /// Kullanıcı Widget Merkezi'nden yeniden işaretler.
  static const prayerQuoteOptInMigratedKey =
      'lock_notif_prayer_quote_opt_in_v2_migrated';

  /// Varsayılan: hepsi kapalı. Kullanıcı Widget Merkezi veya onboarding'de
  /// açar. Native `defaultEnabled` ile birebir aynı kalmalıdır.
  static bool defaultEnabled(ArinWidgetAccessKind kind) => false;

  /// Android: namaz ve söz kilit bildirimi işaretli gelmez. v1 artık
  /// onları açmaz; v2 daha önce otomatik açılmış olanları bir kez kapatır.
  static Future<void> migrateLegacyDefaultsIfNeeded(
    SharedPreferences prefs,
  ) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (prefs.getBool(legacyDefaultsMigratedKey) != true) {
      await prefs.setBool(legacyDefaultsMigratedKey, true);
    }
    if (prefs.getBool(prayerQuoteOptInMigratedKey) == true) return;
    try {
      for (final kind in const [
        ArinWidgetAccessKind.prayer,
        ArinWidgetAccessKind.quote,
      ]) {
        await HomeWidget.saveWidgetData<String>(_key(kind), '0');
      }
      await syncAll();
    } catch (e) {
      debugPrint('ArinLockNotificationService.migrateLegacyDefaults: $e');
    } finally {
      await prefs.setBool(prayerQuoteOptInMigratedKey, true);
    }
  }

  static String _key(ArinWidgetAccessKind kind) =>
      'arin_lock_notif_enabled_${kind.id}';

  /// Kullanıcının bu widget türü için kilit ekranı bildirimini açıp
  /// açmadığını döndürür. Hiç ayarlanmamışsa [defaultEnabled] uygulanır.
  static Future<bool> isEnabled(ArinWidgetAccessKind kind) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final raw = await HomeWidget.getWidgetData<String>(_key(kind));
      switch (raw) {
        case '1':
          return true;
        case '0':
          return false;
        default:
          return defaultEnabled(kind);
      }
    } catch (e) {
      debugPrint('ArinLockNotificationService.isEnabled(${kind.id}): $e');
      return defaultEnabled(kind);
    }
  }

  /// Tüm türler için mevcut açık/kapalı durumunu tek seferde okur.
  static Future<Map<ArinWidgetAccessKind, bool>> readAll() async {
    final result = <ArinWidgetAccessKind, bool>{};
    for (final kind in ArinWidgetAccessKind.values) {
      result[kind] = await isEnabled(kind);
    }
    return result;
  }

  /// Anahtarı açar/kapatır. Açarken bildirim izni istenir (Android 13+);
  /// kullanıcı reddederse anahtar yazılmaz ve `false` döner ki UI eski
  /// duruma geri alabilsin.
  static Future<bool> setEnabled(
    ArinWidgetAccessKind kind,
    bool value,
  ) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      if (value) {
        final granted = await requestLocalNotificationRuntimePermissions(
          arinLocalNotificationsPlugin,
          policy: LocalNotificationPermissionPolicy.notificationOnly,
        );
        if (!granted) return false;
      }
      await HomeWidget.saveWidgetData<String>(_key(kind), value ? '1' : '0');
      await syncAll();
      return true;
    } catch (e) {
      debugPrint('ArinLockNotificationService.setEnabled(${kind.id}): $e');
      return false;
    }
  }

  /// Native tarafa "verileri yeniden oku, bildirimleri güncelle" sinyali
  /// gönderir. `ArinWidgetSync` her veri push'undan sonra bunu zaten çağırır;
  /// toggle değişince de burada tekrar çağrılır.
  static Future<void> syncAll() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('syncAll');
    } catch (e) {
      debugPrint('ArinLockNotificationService.syncAll: $e');
    }
  }
}
