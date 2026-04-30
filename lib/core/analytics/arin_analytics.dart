// lib/core/analytics/arin_analytics.dart
// Tek elden olay raporlama (Firebase Analytics). Hiçbir kişisel içerik
// (ayet metni, zikir içeriği, kullanıcı mesajı vb.) yollanmaz — yalnızca
// "bu ekran açıldı", "bu aksiyon yapıldı" gibi sayısal/kategorik olaylar.
//
// KVKK / GDPR NOTU:
//  - E-posta, isim, konum koordinatı burada LOGLANMAZ.
//  - `setUserId` çağrılmaz (Firebase UID bile yok); UX metriği yeterli.
//  - `setAnalyticsCollectionEnabled` Firebase'in default'u; ileride ayarlar
//    ekranından opt-out toggle'ı eklenirse buradan kapatılır.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_bootstrap.dart';

/// Merkezi analytics yardımcısı. Flutter → Firebase arası tek yol.
///
/// Kullanım:
///   ArinAnalytics.logScreen('zikir_matik');
///   ArinAnalytics.log('zikir_complete', {'target': 33});
abstract final class ArinAnalytics {
  static FirebaseAnalytics? _instance;
  static FirebaseAnalyticsObserver? _observer;

  /// Firebase init edildikten sonra [enable] ile ayakta tutulur. [enable]
  /// çağrılmazsa tüm [log*] metotları no-op olur — Firebase yokken çağrı
  /// hatası vermez.
  static bool _enabled = false;

  /// Router observer (go_router'a geçilecek). Firebase hazır değilse null
  /// döner → app.dart içinde [observer] null ise observer listesine eklenmez.
  static FirebaseAnalyticsObserver? get observer => _observer;

  /// [bootstrapFirebase] başarıyla tamamlandıktan sonra çağrılır.
  static Future<void> enable() async {
    if (!isFirebaseReady) {
      debugPrint('══ ARIN ══ Analytics: Firebase hazır değil, skip.');
      return;
    }
    try {
      _instance = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _instance!);
      _enabled = true;
      debugPrint('══ ARIN ══ Analytics: enabled.');
    } catch (e) {
      debugPrint('══ ARIN ══ Analytics init failed (sessiz): $e');
    }
  }

  /// Kullanıcı çıkış yapınca / hesabını silince çağrılır — user-scoped
  /// analytics varsa temizler. Şu an setUserId kullanmıyoruz ama ileride
  /// eklersek buradan temizlenmeli.
  static Future<void> resetUser() async {
    if (!_enabled) return;
    try {
      await _instance?.setUserId(id: null);
    } catch (_) {}
  }

  /// Ekran açılışı — go_router observer da otomatik yazıyor, ama ek manuel
  /// logger (örn: sekme geçişleri) için kullanılabilir.
  static Future<void> logScreen(String name, {Map<String, Object>? params}) async {
    if (!_enabled) return;
    try {
      await _instance?.logScreenView(
        screenName: name,
        parameters: params,
      );
    } catch (_) {}
  }

  /// Özel aksiyon olayları.
  ///
  /// Firebase olay adı kuralları: harf/rakam/alt çizgi, max 40 karakter.
  /// Parametre değerleri: String veya num (List/Map yollamıyoruz — filtre
  /// ihtiyacı olmadıkça basit tutuyoruz).
  static Future<void> log(String name, [Map<String, Object>? params]) async {
    if (!_enabled) return;
    try {
      await _instance?.logEvent(name: name, parameters: params);
    } catch (_) {}
  }

  // ── Kısa yollar (typo'suz) ────────────────────────────────────────────
  // Bu ekrana bakınca hangi olayların loglandığı hemen görülür; yeni olay
  // eklenince buraya bir satır ekleyip sonra çağırmak tavsiye edilir.

  /// Zikir turu tamamlandı (33/99/vb.).
  static Future<void> zikirComplete(int target) =>
      log('zikir_complete', {'target': target});

  /// Arınma programı başlatıldı. [subtype] = sigara, alkol, vs.
  static Future<void> arinmaStart(String subtype) =>
      log('arinma_start', {'subtype': subtype});

  /// Arınma sayacı sıfırlandı.
  static Future<void> arinmaReset(String subtype) =>
      log('arinma_reset', {'subtype': subtype});

  /// Arınma dönüm noktası (7g / 30g / 90g / 365g).
  static Future<void> arinmaMilestone(int days) =>
      log('arinma_milestone', {'days': days});

  /// İyileştirici frekans oynatımı başladı.
  static Future<void> frekansPlay(String toneId) =>
      log('frekans_play', {'tone_id': toneId});

  static Future<void> frekansPause() => log('frekans_pause');

  /// Keşfet'te söz kaydedildi (bookmark).
  static Future<void> kesfetSave() => log('kesfet_save');

  /// Keşfet'te kart beğenildi.
  static Future<void> kesfetLike() => log('kesfet_like');

  /// Keşfet arka plan müziği açıldı/kapandı.
  static Future<void> kesfetBgmToggle(bool enabled) =>
      log('kesfet_bgm_toggle', {'enabled': enabled ? 1 : 0});

  /// Pusula kalibrasyonu (cihazı 8 çizildi).
  static Future<void> pusulaCalibrate() => log('pusula_calibrate');

  /// Namaz vakti tikleme (kılındı işaretlendi).
  static Future<void> namazTick(String prayerKey) =>
      log('namaz_tick', {'prayer': prayerKey});

  /// Nefes egzersizi başladı.
  static Future<void> nefesStart(String mode) =>
      log('nefes_start', {'mode': mode});

  /// Google / Apple ile giriş başarılı.
  static Future<void> loginSuccess(String provider) =>
      log('login_success', {'provider': provider});

  /// Kullanıcı hesabını sildi.
  static Future<void> accountDelete() => log('account_delete');
}
