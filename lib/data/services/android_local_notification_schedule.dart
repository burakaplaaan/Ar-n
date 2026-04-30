import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android 12+ [SCHEDULE_EXACT_ALARM] yoksa `exactAllowWhileIdle` native tarafta
/// exception fırlatır ve hiç bildirim planlanmaz. İzin varsa tam zamanlı, yoksa
/// yaklaşık (idle uyumlu) mod döner.
///
/// “Yumuşak” içerik kanalları (günlük arınma / günün sözü / haftalık ilham)
/// için yeterli.
///
/// ⚠️ Samsung OneUI 8 / Android 16’da `canScheduleExactAlarms()` platform
/// tarafı USE_EXACT_ALARM granted olmasına rağmen `false` dönebiliyor (OEM
/// override). Bu nedenle **optimistik** deneriz: manifest’te izin varsa
/// doğrudan `exactAllowWhileIdle` kullan — gerçek başarısızlık olursa çağıran
/// katmandaki `_safeZonedSchedule` yakalar ve inexact’e düşer.
Future<AndroidScheduleMode> androidScheduleModePreferExact(
  FlutterLocalNotificationsPlugin plugin,
) async {
  if (!Platform.isAndroid) {
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }
  return AndroidScheduleMode.exactAllowWhileIdle;
}

/// Kullanıcıya doğrudan görünen alarmlar (namaz vakti, günün sabit saati) için
/// `AlarmManager.setAlarmClock()` → [AndroidScheduleMode.alarmClock].
///
/// • Doze / App Standby muafiyeti var (her zaman tetiklenir).
/// • Xiaomi / Huawei / Oppo / Vivo / Samsung gibi OEM güç yöneticilerinde bile
///   uygulama arka plandayken ya da force-stop sonrası (cihaz yeniden başlatana
///   kadar) çalışır.
/// • Status bar’da “sonraki alarm” ikonu görünebilir — namaz / ibadet uygulaması
///   için kabul edilebilir bir trade-off; daha önemlisi ZAMANINDA ÇALMASIDIR.
///
/// ⚠️ OEM override’larına karşı **optimistik**: manifest’te `USE_EXACT_ALARM`
/// olduğu halde `canScheduleExactAlarms()` false döndüğünde bile `alarmClock`
/// deneriz; gerçekten reddedilirse `_safeZonedSchedule` önce
/// `exactAllowWhileIdle`’a, o da olmazsa `inexactAllowWhileIdle`’a düşer.
///
/// Samsung Galaxy A34 (OneUI 8) üzerinde ölçüldü: `canScheduleExact` `false`
/// dönüyor ama `setAlarmClock()` native çağrısı sorunsuz işliyor — bu yüzden
/// platform check’ine kör güvenmek zamanlamanın ±1h kaymasına yol açıyor.
Future<AndroidScheduleMode> androidScheduleModePreferAlarmClock(
  FlutterLocalNotificationsPlugin plugin,
) async {
  if (!Platform.isAndroid) {
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }
  return AndroidScheduleMode.alarmClock;
}

/// `canScheduleExactNotifications` plugin tarafında null dönebilir; bool’a sıkıştır.
///
/// Not: Bu sorgu artık zamanlama modunu seçmek için KULLANILMIYOR (OEM
/// override riski). Yalnızca UI bilgilendirmesi / izin ekranı tetikleri için.
Future<bool> canScheduleExactLocalNotifications(
  FlutterLocalNotificationsPlugin plugin,
) async {
  if (!Platform.isAndroid) return true;
  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  final can = await android?.canScheduleExactNotifications();
  return can == true;
}
