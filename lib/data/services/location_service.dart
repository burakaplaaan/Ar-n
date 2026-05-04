// lib/data/services/location_service.dart
// Şehir/ülke + GPS; namaz vakitleri için Aladhan ile uyumlu.
//
// Türkiye'de ayrıca Diyanet (ezanvakti) ilçe ID'si çözülür: reverse
// geocoding'den gelen `subAdministrativeArea` + `administrativeArea`
// çifti `DiyanetDistrictMatcher` ile `ilceId`'ye eşlenir; sonuç Hive'a
// yazılır ve `prayer_service_resolver` burada okur.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import '../../core/utils/hive_boxes.dart';
import 'diyanet_district_matcher.dart';

class LocationService {
  static const _cityKey = 'user_city';
  static const _countryKey = 'user_country';
  static const _latKey = 'user_lat';
  static const _lonKey = 'user_lon';
  static const _lastPrayerLocSyncMs = 'prayer_loc_sync_ms';

  /// Diyanet (ezanvakti) ilçe kimliği. TR ve ancak match başarılıysa
  /// dolu olur; değilse `null` kalıp resolver Aladhan'a düşer.
  static const _districtIdKey = 'prayer_district_id';

  /// İlk namaz vakitleri yüklemesinde (oturum başına bir kez) GPS ile güncel şehir.
  bool _sessionAutoGpsPending = true;

  Box<dynamic> get _prefs => Hive.box<dynamic>(HiveBoxes.preferences);

  String get savedCity => (_prefs.get(_cityKey) as String?) ?? 'Istanbul';
  String get savedCountry => (_prefs.get(_countryKey) as String?) ?? 'Turkey';
  double? get savedLat => _prefs.get(_latKey) as double?;
  double? get savedLon => _prefs.get(_lonKey) as double?;
  int? get savedDistrictId => _prefs.get(_districtIdKey) as int?;
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
    await _prefs.delete(_latKey);
    await _prefs.delete(_lonKey);
    await _prefs.delete(_districtIdKey); // ilçe de sıfırlanır
    await saveCity(trimmed, country);
  }

  /// Elle ilçe seçimi (settings > "Konum değiştir" sheet'inden).
  /// Saved district + il adı + ülke eşzamanlı yazılır; GPS'i silmez
  /// (kullanıcı "manuel ama GPS'im doğru" diyebilir).
  Future<void> saveManualDistrict(DiyanetDistrict d) async {
    await _prefs.put(_districtIdKey, d.id);
    await _prefs.put(_cityKey, d.il);
    await _prefs.put(_countryKey, 'Turkey');
  }

  /// Aşağı çekince GPS + ters jeokodun tekrar çalışması için.
  Future<void> clearPrayerLocationThrottle() async {
    await _prefs.delete(_lastPrayerLocSyncMs);
  }

  /// İzin varsa GPS alır; ters jeokod ile il/ülke güncellenir (Türkiye: çoğunlukla il).
  /// [forceRefresh]: true ise süre sınırı yok (yenileme hareketi).
  /// Oturumda ilk çağrıda bir kez GPS denenir (şehir değişimi / uygulamaya yeniden giriş).
  Future<void> syncPrayerLocation({bool forceRefresh = false}) async {
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

    final pos = await requestCurrentPosition();
    if (pos == null) return;

    try {
      final marks = await placemarkFromCoordinates(pos.lat, pos.lon);
      if (marks.isEmpty) return;
      final p = marks.first;

      String? city = _pickCityName(p);
      if (city == null || city.isEmpty) return;

      final country = _countryForAladhan(p);
      await saveCity(city, country);

      // Türkiye ise Diyanet `ilceId`'yi de çözmeye çalış. Matcher asset
      // zaten `loadOnce()` edilmiş olmalı (main.dart init'te); çağrı
      // idempotent, ek maliyet yok.
      if ((p.isoCountryCode?.toUpperCase() ?? '') == 'TR') {
        await _resolveDistrictIdFromPlacemark(p);
      } else {
        // TR dışına çıkıldıysa eski ilçe ID'si yanıltıcı; sıfırla.
        await saveDistrictId(null);
      }
      await _prefs.put(
        _lastPrayerLocSyncMs,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Koordinatlar kayıtlı; Aladhan yine doğru vakit döner, şehir etiketi eski kalabilir.
    }
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
      await saveDistrictId(match?.id);
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

  Future<({double lat, double lon})?> requestCurrentPosition() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      await _prefs.put(_latKey, pos.latitude);
      await _prefs.put(_lonKey, pos.longitude);
      return (lat: pos.latitude, lon: pos.longitude);
    } catch (_) {
      return null;
    }
  }
}

final locationServiceProvider = Provider<LocationService>(
  (_) => LocationService(),
);
