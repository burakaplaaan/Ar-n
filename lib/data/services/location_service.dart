// lib/data/services/location_service.dart
// Şehir/ülke + GPS; namaz vakitleri için Aladhan ile uyumlu.
//
// Türkiye'de ayrıca Diyanet (ezanvakti) ilçe ID'si çözülür: reverse
// geocoding'den gelen `subAdministrativeArea` + `administrativeArea`
// çifti `DiyanetDistrictMatcher` ile `ilceId`'ye eşlenir; sonuç Hive'a
// yazılır ve `prayer_service_resolver` burada okur.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:arin/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import '../../core/utils/hive_boxes.dart';
import '../../core/router/app_router.dart';
import '../../presentation/shared/widgets/arin_permission_dialog.dart';
import 'diyanet_district_matcher.dart';
import 'startup_permission_policy.dart';

/// GPS ile tespit edilen şehir, kaydedilen şehirden farklıysa döner.
/// `applyLocationChange` ile kalıcı hale getirilir.
class LocationChangeResult {
  final String newCity;
  final String newCountry;
  final int? newDistrictId;
  final double lat;
  final double lon;

  const LocationChangeResult({
    required this.newCity,
    required this.newCountry,
    required this.newDistrictId,
    required this.lat,
    required this.lon,
  });
}

/// Elle seçilen il/ilçe GPS ile sessizce ezilmesin.
bool shouldHoldManualPrayerLocation({
  required bool isManual,
  required bool overwriteManual,
}) =>
    isManual && !overwriteManual;

/// Elle seçilen şehirde Aladhan kalan GPS koordinatını kullanmasın.
bool shouldUseAladhanCityName({
  required bool isManual,
  required String city,
}) =>
    isManual && city.trim().isNotEmpty;

/// Konum güncelleme tercihi sabitleri (Hive key: `location_auto_update_pref`).
abstract final class LocationUpdatePref {
  /// Her şehir değişiminde sor (kullanıcı Ayarlar'dan kapatırsa).
  static const String ask = 'ask';

  /// Sessizce güncelle, bir daha sorma (varsayılan — açık gelir).
  static const String alwaysUpdate = 'always_update';

  /// Hiç otomatik güncelleme, sadece manuel.
  static const String neverUpdate = 'never_update';
}

class LocationService {
  static const _cityKey = 'user_city';
  static const _countryKey = 'user_country';
  static const _latKey = 'user_lat';
  static const _lonKey = 'user_lon';
  static const _lastPrayerLocSyncMs = 'prayer_loc_sync_ms';

  /// Diyanet (ezanvakti) ilçe kimliği. TR ve ancak match başarılıysa
  /// dolu olur; değilse `null` kalıp resolver Aladhan'a düşer.
  static const _districtIdKey = 'prayer_district_id';
  static const _manualPrayerLocationKey = 'prayer_location_manual';
  static const _locationUpdatePrefKey = 'location_auto_update_pref';

  /// İlk namaz vakitleri yüklemesinde (oturum başına bir kez) GPS ile güncel şehir.
  bool _sessionAutoGpsPending = true;

  Box<dynamic> get _prefs => Hive.box<dynamic>(HiveBoxes.preferences);

  String get savedCity => (_prefs.get(_cityKey) as String?) ?? '';
  String get savedCountry => (_prefs.get(_countryKey) as String?) ?? '';
  double? get savedLat => _prefs.get(_latKey) as double?;
  double? get savedLon => _prefs.get(_lonKey) as double?;
  int? get savedDistrictId => _prefs.get(_districtIdKey) as int?;

  /// Kullanıcı il/ilçe seçtiyse GPS `alwaysUpdate` bunu geri almasın.
  bool get isManualPrayerLocation =>
      _prefs.get(_manualPrayerLocationKey) == true;

  /// İnternet/GPS fix olmadan (ör. kıble pusulası) son bilinen koordinatı
  /// senkron döndürür. Box açık değilse ya da hiç konum kaydı yoksa `null`.
  /// Namaz vakitleri için daha önce kaydedilmiş GPS koordinatını yeniden kullanır.
  static ({double lat, double lon})? cachedCoordinates() {
    if (!Hive.isBoxOpen(HiveBoxes.preferences)) return null;
    final box = Hive.box<dynamic>(HiveBoxes.preferences);
    // num? → toDouble: yedek/import yoluyla int yazılmış olsa bile TypeError atmaz.
    final lat = (box.get(_latKey) as num?)?.toDouble();
    final lon = (box.get(_lonKey) as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    return (lat: lat, lon: lon);
  }

  /// Konum güncelleme tercihi. Olası değerler: [LocationUpdatePref].
  /// Anahtar yoksa varsayılan: açık ([LocationUpdatePref.alwaysUpdate]).
  String get locationUpdatePref =>
      (_prefs.get(_locationUpdatePrefKey) as String?) ??
      LocationUpdatePref.alwaysUpdate;

  Future<void> setLocationUpdatePref(String pref) async {
    await _prefs.put(_locationUpdatePrefKey, pref);
  }

  DateTime? get lastPrayerSyncAt {
    final ms = _prefs.get(_lastPrayerLocSyncMs) as int?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Map<String, dynamic> exportBackupJson() => {
    'city': savedCity,
    'country': savedCountry,
    if (savedLat != null) 'lat': savedLat,
    if (savedLon != null) 'lon': savedLon,
    if (savedDistrictId != null) 'districtId': savedDistrictId,
    if (isManualPrayerLocation) 'manualPrayerLocation': true,
  };

  Future<void> importBackupJson(Map<String, dynamic> json) async {
    final city = (json['city'] as String?)?.trim();
    final country = (json['country'] as String?)?.trim();
    if (city != null && city.isNotEmpty) {
      await _prefs.put(_cityKey, city);
      await _prefs.put(
        _countryKey,
        country == null || country.isEmpty ? 'Turkey' : country,
      );
    }

    final lat = (json['lat'] as num?)?.toDouble();
    final lon = (json['lon'] as num?)?.toDouble();
    if (lat != null && lon != null) {
      await _prefs.put(_latKey, lat);
      await _prefs.put(_lonKey, lon);
    } else {
      await _prefs.delete(_latKey);
      await _prefs.delete(_lonKey);
    }

    final districtId = (json['districtId'] as num?)?.toInt();
    await saveDistrictId(districtId);
    if (json['manualPrayerLocation'] == true) {
      await _prefs.put(_manualPrayerLocationKey, true);
    } else {
      await _prefs.delete(_manualPrayerLocationKey);
    }
  }

  Future<void> saveCity(String city, String country) async {
    await _prefs.put(_cityKey, city);
    await _prefs.put(_countryKey, country);
  }

  /// Diyanet ilçe kimliğini elle/otomatik kaydet. `null` verilirse
  /// kayıt silinir (resolver Aladhan'a düşer).
  Future<void> saveDistrictId(int? id) async {
    if (id == null) {
      await _prefs.delete(_districtIdKey);
    } else {
      await _prefs.put(_districtIdKey, id);
    }
  }

  /// Elle yazılan şehir: kayıtlı GPS koordinatlarını siler; vakitler şehir adıyla Aladhan'dan gelir.
  Future<void> saveManualCity(String city, String country) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    _syncGeneration++;
    _sessionAutoGpsPending = false;
    await _prefs.delete(_latKey);
    await _prefs.delete(_lonKey);
    await _prefs.delete(_districtIdKey); // ilçe de sıfırlanır
    await _prefs.put(_manualPrayerLocationKey, true);
    await saveCity(trimmed, country);
  }

  /// Elle ilçe seçimi (ana sayfa / ayarlar picker).
  /// GPS koordinatını siler — aksi halde Diyanet düşünce Aladhan Kocaeli
  /// vaktini Ankara etiketiyle gösterebilir. Uçuştaki GPS yazısını nesil
  /// ile iptal eder; `alwaysUpdate` seçimi geri alamaz.
  Future<void> saveManualDistrict(DiyanetDistrict d) async {
    _syncGeneration++;
    _sessionAutoGpsPending = false;
    await _prefs.put(_districtIdKey, d.id);
    await _prefs.put(_cityKey, d.il);
    await _prefs.put(_countryKey, 'Turkey');
    await _prefs.put(_manualPrayerLocationKey, true);
    await _prefs.delete(_latKey);
    await _prefs.delete(_lonKey);
  }

  String _locationKey() {
    final id = savedDistrictId;
    final city = savedCity.trim().toLowerCase();
    return '${id ?? 'nil'}|$city';
  }

  /// Aşağı çekince GPS + ters jeokodun tekrar çalışması için.
  Future<void> clearPrayerLocationThrottle() async {
    await _prefs.delete(_lastPrayerLocSyncMs);
  }

  /// Senkronizasyon işlemi için mutex — ikinci çağrı erken dönmek yerine bekler.
  Future<void>? _syncJob;
  int _syncGeneration = 0;

  Completer<LocationPermission>? _permissionPromptInFlight;
  bool _sessionDeclinedDisclosure = false;

  /// İzin varsa GPS alır; ters jeokod ile il/ülke güncellenir (Türkiye: çoğunlukla il).
  /// [forceRefresh]: true ise süre sınırı yok (yenileme hareketi).
  /// Oturumda ilk çağrıda bir kez GPS denenir (şehir değişimi / uygulamaya yeniden giriş).
  Future<void> syncPrayerLocation({
    bool forceRefresh = false,
    bool promptIfNeeded = false,
    bool overwriteManual = false,
  }) async {
    if (shouldHoldManualPrayerLocation(
      isManual: isManualPrayerLocation,
      overwriteManual: overwriteManual,
    )) {
      _sessionAutoGpsPending = false;
      return;
    }
    final existing = _syncJob;
    if (existing != null) {
      await existing;
      if (!forceRefresh) return;
      if (shouldHoldManualPrayerLocation(
        isManual: isManualPrayerLocation,
        overwriteManual: overwriteManual,
      )) {
        return;
      }
    }
    final job = _syncPrayerLocationBody(
      forceRefresh: forceRefresh,
      promptIfNeeded: promptIfNeeded,
      overwriteManual: overwriteManual,
    );
    _syncJob = job;
    try {
      await job;
    } finally {
      if (identical(_syncJob, job)) _syncJob = null;
    }
  }

  Future<void> _syncPrayerLocationBody({
    required bool forceRefresh,
    required bool promptIfNeeded,
    required bool overwriteManual,
  }) async {
    if (shouldHoldManualPrayerLocation(
      isManual: isManualPrayerLocation,
      overwriteManual: overwriteManual,
    )) {
      _sessionAutoGpsPending = false;
      return;
    }
    final currentGen = ++_syncGeneration;
    try {
      final oldLocationKey = _locationKey();

      // Manuel yenileme (forceRefresh) her zaman çalışır. Otomatik çalışmada:
      //  • neverUpdate → kullanıcı sadece manuel değiştirmek istiyor; GPS'e dokunma.
      //  • ask         → şehir değişimi diyalog akışı (LocationChangeListener) üstlenir;
      //                  burada sessizce kaydetme, sadece koordinatları taze tut.
      if (!forceRefresh) {
        final pref = locationUpdatePref;
        if (pref == LocationUpdatePref.neverUpdate) {
          _sessionAutoGpsPending = false;
          return;
        }
        if (pref == LocationUpdatePref.ask) {
          _sessionAutoGpsPending = false;
          return;
        }
      }

      final sessionFirst = _sessionAutoGpsPending;
      if (_sessionAutoGpsPending) _sessionAutoGpsPending = false;
      final force = forceRefresh || sessionFirst;

      if (!force) {
        final last = _prefs.get(_lastPrayerLocSyncMs) as int?;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (last != null &&
            now - last < const Duration(minutes: 30).inMilliseconds) {
          return;
        }
      }

      final pos = await requestCurrentPosition(
        promptIfNeeded: promptIfNeeded,
        persistCoordinates: false,
      );
      if (pos == null || currentGen != _syncGeneration) return;
      if (shouldHoldManualPrayerLocation(
        isManual: isManualPrayerLocation,
        overwriteManual: overwriteManual,
      )) {
        return;
      }
      await _prefs.put(_latKey, pos.lat);
      await _prefs.put(_lonKey, pos.lon);

      try {
        final marks = await placemarkFromCoordinates(pos.lat, pos.lon);
        if (marks.isEmpty || currentGen != _syncGeneration) return;
        final p = marks.first;

        String? city = _pickCityName(p);
        if (city == null || city.isEmpty) return;

        final country = _countryForAladhan(p);
        if (overwriteManual) {
          await _prefs.delete(_manualPrayerLocationKey);
        }
        await saveCity(city, country);
        if (currentGen != _syncGeneration) return;

        // Türkiye ise Diyanet `ilceId`'yi de çözmeye çalış. Matcher asset
        // zaten `loadOnce()` edilmiş olmalı (main.dart init'te); çağrı
        // idempotent, ek maliyet yok.
        if ((p.isoCountryCode?.toUpperCase() ?? '') == 'TR') {
          await _resolveDistrictIdFromPlacemark(p);
        } else {
          // TR dışına çıkıldıysa eski ilçe ID'si yanıltıcı; sıfırla.
          final oldCountry = (_prefs.get(_countryKey) as String?) ?? '';
          if (oldCountry.toUpperCase() == 'TR' ||
              oldCountry.toUpperCase() == 'TURKEY') {
            await saveDistrictId(null);
          }
        }
        if (currentGen != _syncGeneration) return;
        await _prefs.put(
          _lastPrayerLocSyncMs,
          DateTime.now().millisecondsSinceEpoch,
        );

        final newLocationKey = _locationKey();
        if (oldLocationKey != newLocationKey) {
          _notifySilentLocationChange();
        }
      } catch (_) {
        // Koordinatlar kayıtlı; Aladhan yine doğru vakit döner, şehir etiketi eski kalabilir.
      }
    } catch (_) {
      // GPS/izin hatası üst katmanda cache veya ilçe seçimine düşer.
    }
  }

  void _notifySilentLocationChange() {
    onSilentLocationChanged?.call();
  }

  void Function()? onSilentLocationChanged;

  /// GPS ile güncel konumu alır, kayıtlı şehirden farklıysa [LocationChangeResult]
  /// döndürür. Hiçbir şey kaydetmez — kullanıcı onayından sonra [applyLocationChange]
  /// çağrılmalıdır. İzin yoksa, GPS alınamazsa veya şehir aynıysa `null` döner.
  Future<LocationChangeResult?> detectLocationChange() async {
    // Namaz fetch'inin beklediği sync'i iptal etme — nesil artırmak
    // Android açılışında vakitlerin yarım konumla düşmesine yol açıyordu.
    // Koordinatları Hive'a yazmadan konum al — kayıt yalnızca applyLocationChange'de.
    final pos = await _getCurrentPositionNoSave();
    if (pos == null) return null;

    try {
      final marks = await placemarkFromCoordinates(pos.lat, pos.lon);
      if (marks.isEmpty) return null;
      final p = marks.first;

      final newCity = _pickCityName(p);
      if (newCity == null || newCity.isEmpty) return null;

      if (_isSameCity(newCity, savedCity)) return null;

      final newCountry = _countryForAladhan(p);
      int? newDistrictId;
      if ((p.isoCountryCode?.toUpperCase() ?? '') == 'TR') {
        await DiyanetDistrictMatcher.loadOnce();
        final ilceAdi = p.subAdministrativeArea?.trim().isNotEmpty == true
            ? p.subAdministrativeArea
            : p.locality;
        final match = DiyanetDistrictMatcher.match(
          ilAdi: p.administrativeArea,
          ilceAdi: ilceAdi,
        );
        newDistrictId = match?.id;
      }

      return LocationChangeResult(
        newCity: newCity,
        newCountry: newCountry,
        newDistrictId: newDistrictId,
        lat: pos.lat,
        lon: pos.lon,
      );
    } catch (_) {
      return null;
    }
  }

  /// Yalnızca izin DURUMUNU kontrol eder, asla istemez. WorkManager/BGTaskScheduler
  /// arka plan izolatında Activity/UIViewController olmadığı için izin diyaloğu
  /// gösterilemez — `always` değilse arka plan görevi sessizce hiçbir şey yapmaz.
  Future<bool> hasAlwaysLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// [detectLocationChange] ile aynı işi yapar ama **hiçbir izin istemez** ve
  /// **hiçbir UI göstermez** — yalnızca arka plan (uygulama tamamen kapalı)
  /// görevinden çağrılmalıdır. İzin `always` değilse, konum servisleri kapalıysa
  /// veya herhangi bir adım başarısız olursa sessizce `null` döner.
  Future<LocationChangeResult?> detectLocationChangeHeadless() async {
    _syncGeneration++;
    try {
      if (!await hasAlwaysLocationPermission()) return null;
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );

      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isEmpty) return null;
      final p = marks.first;

      final newCity = _pickCityName(p);
      if (newCity == null || newCity.isEmpty) return null;
      if (_isSameCity(newCity, savedCity)) return null;

      final newCountry = _countryForAladhan(p);
      int? newDistrictId;
      if ((p.isoCountryCode?.toUpperCase() ?? '') == 'TR') {
        await DiyanetDistrictMatcher.loadOnce();
        final ilceAdi = p.subAdministrativeArea?.trim().isNotEmpty == true
            ? p.subAdministrativeArea
            : p.locality;
        final match = DiyanetDistrictMatcher.match(
          ilAdi: p.administrativeArea,
          ilceAdi: ilceAdi,
        );
        newDistrictId = match?.id;
      }

      return LocationChangeResult(
        newCity: newCity,
        newCountry: newCountry,
        newDistrictId: newDistrictId,
        lat: pos.latitude,
        lon: pos.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  /// [detectLocationChange]'in sonucunu Hive'a kalıcı olarak yazar.
  Future<void> applyLocationChange(
    LocationChangeResult result, {
    bool overwriteManual = false,
  }) async {
    if (shouldHoldManualPrayerLocation(
      isManual: isManualPrayerLocation,
      overwriteManual: overwriteManual,
    )) {
      return;
    }
    _syncGeneration++;
    await _prefs.delete(_manualPrayerLocationKey);
    await saveCity(result.newCity, result.newCountry);
    await saveDistrictId(result.newDistrictId);
    await _prefs.put(_latKey, result.lat);
    await _prefs.put(_lonKey, result.lon);
    await _prefs.put(
      _lastPrayerLocSyncMs,
      DateTime.now().millisecondsSinceEpoch,
    );
    _sessionAutoGpsPending = false;
  }

  static bool _isSameCity(String a, String b) {
    String fold(String s) => s
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('İ', 'i')
        .replaceAll('Ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('Ş', 's')
        .replaceAll('Ö', 'o')
        .replaceAll('Ç', 'c');
    return fold(a) == fold(b);
  }

  Future<void> _resolveDistrictIdFromPlacemark(Placemark p) async {
    try {
      await DiyanetDistrictMatcher.loadOnce();
      final ilAdi = p.administrativeArea;
      // Android Geocoder'ın TR'de tipik davranışı:
      //   administrativeArea     = il    ("Kocaeli")
      //   subAdministrativeArea  = ilçe  ("Gebze")
      //   locality               = bazen ilçe, bazen belde
      //   subLocality            = mahalle
      // Matcher fallback sırası: subAdmin → locality → null.
      final ilceAdi = p.subAdministrativeArea?.trim().isNotEmpty == true
          ? p.subAdministrativeArea
          : p.locality;
      final match = DiyanetDistrictMatcher.match(
        ilAdi: ilAdi,
        ilceAdi: ilceAdi,
      );
      if (match != null) {
        await saveDistrictId(match.id);
      }
      // Bulunamadıysa sessiz kal; eski manuel/doğru seçimi ezme.
    } catch (_) {
      // Asset yoksa/okunamadıysa bile uygulama çalışsın; Aladhan fallback var.
    }
  }

  static String? _pickCityName(Placemark p) {
    final admin = p.administrativeArea?.trim();
    if (admin != null && admin.isNotEmpty) return admin;
    final loc = p.locality?.trim();
    if (loc != null && loc.isNotEmpty) return loc;
    final sub = p.subAdministrativeArea?.trim();
    if (sub != null && sub.isNotEmpty) return sub;
    return null;
  }

  static String _countryForAladhan(Placemark p) {
    final cc = p.isoCountryCode?.toUpperCase();
    if (cc == 'TR') return 'Turkey';
    final name = p.country?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Turkey';
  }

  Future<LocationPermission> _requestLocationPermissionWithDisclosure({
    bool promptIfNeeded = true,
    bool showDisclosure = true,
  }) async {
    final inFlight = _permissionPromptInFlight;
    if (inFlight != null) return inFlight.future;

    var permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.denied) return permission;

    if (!promptIfNeeded) return LocationPermission.denied;

    if (showDisclosure &&
        !shouldShowLocationDisclosure(
          permissionDenied: true,
          promptIfNeeded: true,
          sessionDeclined: _sessionDeclinedDisclosure,
        )) {
      return LocationPermission.denied;
    }

    final completer = Completer<LocationPermission>();
    _permissionPromptInFlight = completer;
    try {
      permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.denied) {
        completer.complete(permission);
        return permission;
      }

      if (showDisclosure) {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) {
          completer.complete(LocationPermission.denied);
          return LocationPermission.denied;
        }
        final l10n = AppLocalizations.of(ctx);
        final confirmed = await showArinPermissionDialog(
          context: ctx,
          icon: Icons.location_on_rounded,
          title: l10n?.locationPermissionRequiredTitle ?? 'Konum İzni Gerekli',
          body:
              l10n?.locationPermissionRequiredBody ??
              'Arın, namaz vakitlerini ve kıble yönünü doğru hesaplayabilmek için '
                  'konumunuza erişim izni gerektirir. Konum verileriniz yalnızca '
                  'bu amaçlar için kullanılır ve cihazınızda işlenir.',
          cancelLabel: l10n?.locationPermissionNotNow ?? 'Şimdi Değil',
          confirmLabel: l10n?.locationPermissionContinue ?? 'Devam Et',
        );
        if (!confirmed) {
          _sessionDeclinedDisclosure = true;
          completer.complete(LocationPermission.denied);
          return LocationPermission.denied;
        }
      }

      permission = await Geolocator.requestPermission();
      completer.complete(permission);
      return permission;
    } catch (error, stack) {
      if (!completer.isCompleted) completer.completeError(error, stack);
      rethrow;
    } finally {
      if (identical(_permissionPromptInFlight, completer)) {
        _permissionPromptInFlight = null;
      }
    }
  }

  Future<({double lat, double lon})?> _readGpsPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return (lat: pos.latitude, lon: pos.longitude);
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return null;
        return (lat: last.latitude, lon: last.longitude);
      } catch (_) {
        return null;
      }
    }
  }

  /// Konum iznini kontrol eder ve GPS'ten pozisyon alır — **Hive'a yazmaz**.
  /// Yalnızca [detectLocationChange] tarafından kullanılır; kayıt işlemi
  /// kullanıcı onayından sonra [applyLocationChange] üstlenir.
  ///
  /// Sistem diyaloğu göstermez — ev açılışında ikinci konum popup'ını önler.
  Future<({double lat, double lon})?> _getCurrentPositionNoSave() async {
    final permission = await _requestLocationPermissionWithDisclosure(
      promptIfNeeded: false,
    );
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return _readGpsPosition();
  }

  Future<LocationPermission> requestSystemLocationPermission() {
    return _requestLocationPermissionWithDisclosure(
      promptIfNeeded: true,
      showDisclosure: false,
    );
  }

  Future<({double lat, double lon})?> requestCurrentPosition({
    bool promptIfNeeded = true,
    bool persistCoordinates = true,
    bool showDisclosure = true,
  }) async {
    final permission = await _requestLocationPermissionWithDisclosure(
      promptIfNeeded: promptIfNeeded,
      showDisclosure: showDisclosure,
    );
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await _readGpsPosition();
    if (pos == null) return null;
    if (persistCoordinates &&
        !shouldHoldManualPrayerLocation(
          isManual: isManualPrayerLocation,
          overwriteManual: false,
        )) {
      await _prefs.put(_latKey, pos.lat);
      await _prefs.put(_lonKey, pos.lon);
    }
    return pos;
  }
}

final locationServiceProvider = Provider<LocationService>(
  (_) => LocationService(),
);
