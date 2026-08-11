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

  /// Eski sürümde namaz/söz varsayılanı açıktı; yeni kurulumda kapalı.
  /// Onboarding'i bitirmiş kullanıcıların anahtarsız tercihi bir kez korunur.
  static const legacyDefaultsMigratedKey =
      'lock_notif_defaults_off_v1_migrated';

  /// Varsayılan: hepsi kapalı. Kullanıcı Widget Merkezi veya onboarding'de
  /// açar. Native `defaultEnabled` ile birebir aynı kalmalıdır.
  static bool defaultEnabled(ArinWidgetAccessKind kind) => false;

  /// Onboarding'i bitirmiş eski kullanıcılar: anahtar yoksa eski varsayılan
  /// (namaz + söz açık) bir kez yazılır. Yeni kurulumda dokunulmaz.
  static Future<void> migrateLegacyDefaultsIfNeeded(
    SharedPreferences prefs,
  ) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (prefs.getBool(legacyDefaultsMigratedKey) == true) return;
    try {
      final onboarded = prefs.getBool('onboarding_completed') == true;
      if (onboarded) {
        for (final kind in const [
          ArinWidgetAccessKind.prayer,
          ArinWidgetAccessKind.quote,
        ]) {
          final raw = await HomeWidget.getWidgetData<String>(_key(kind));
          if (raw == null) {
            await HomeWidget.saveWidgetData<String>(_key(kind), '1');
          }
        }
        await syncAll();
      }
    } catch (e) {
      debugPrint('ArinLockNotificationService.migrateLegacyDefaults: $e');
    } finally {
      await prefs.setBool(legacyDefaultsMigratedKey, true);
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
