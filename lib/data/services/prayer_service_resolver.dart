// lib/data/services/prayer_service_resolver.dart
//
// Namaz vakti kaynaklarını birleştiren karar katmanı.
//
//   Tier 1 — Diyanet (ezanvakti.emushaf.net) ► yalnız Türkiye'de
//            `ilceId` çözülebiliyorsa. Resmi Diyanet takvimi ile birebir.
//
//   Tier 2 — Aladhan ► Türkiye dışı, GPS yok, ya da Diyanet 7 sn
//            içinde cevap veremiyor. Mevcut `AladhanService` dünya
//            genelinde koordinat/şehir bazlı çalışır.
//
// Kullanım:
//   final resolver = ref.read(prayerServiceResolverProvider);
//   final pt = await resolver.fetchToday();
//
// Provider zinciri `prayerTimesProvider`'a bağlanır; consumer kod
// (UI, scheduler) değişmez — sadece veri kaynağı yeri değişir.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prayer_times_model.dart';
import 'aladhan_service.dart';
import 'diyanet_prayer_service.dart';
import 'location_service.dart';

/// Hangi kaynağın vakitleri ürettiğini açıkça belirtmek için. UI'da
/// "Kaynak: Diyanet" rozeti için; ayrıca log & telemetri için.
enum PrayerSource { diyanet, aladhan, cacheOnly, unavailable }

/// Açılışta GPS'i beklemek yalnız hiç kullanılabilir kayıtlı konum yoksa gerekir.
/// İlçe, koordinat veya şehirden biri yeterliyse mevcut veriyle vakit gösterilir;
/// konum tazeleme arka planda yapılır.
bool shouldWaitForInitialPrayerLocation({
  required bool isManual,
  required String city,
  required int? districtId,
  required double? lat,
  required double? lon,
}) {
  if (isManual) return false;
  final hasDistrict = districtId != null && city.trim().isNotEmpty;
  final hasCoordinates = lat != null && lon != null;
  final hasCity = city.trim().isNotEmpty;
  return !hasDistrict && !hasCoordinates && !hasCity;
}

class _PrayerLocationSnapshot {
  const _PrayerLocationSnapshot({
    required this.city,
    required this.country,
    required this.districtId,
    required this.lat,
    required this.lon,
    required this.isManual,
  });

  final String city;
  final String country;
  final int? districtId;
  final double? lat;
  final double? lon;
  final bool isManual;

  String get key {
    final normalizedCity = city.trim().toLowerCase();
    final normalizedCountry = country.trim().toLowerCase();
    if (isManual) {
      return 'manual|${districtId ?? 'nil'}|$normalizedCountry|$normalizedCity';
    }
    if (_isTurkeyCountry(normalizedCountry) && districtId != null) {
      return 'diyanet|$districtId|$normalizedCity';
    }
    if (lat != null && lon != null) {
      return 'coords|$normalizedCountry|$normalizedCity|'
          '${lat!.toStringAsFixed(3)}|${lon!.toStringAsFixed(3)}';
    }
    return 'city|$normalizedCountry|$normalizedCity';
  }
}

bool _isTurkeyCountry(String country) {
  final c = country.trim().toLowerCase();
  return c == 'turkey' || c == 'türkiye' || c == 'turkiye' || c == 'tr';
}

class PrayerFetchResult {
  final PrayerTimesModel? model;
  final PrayerSource source;

  const PrayerFetchResult(this.model, this.source);

  bool get hasData => model != null;
}

class PrayerServiceResolver {
  final DiyanetPrayerService _diyanet;
  final AladhanService _aladhan;
  final LocationService _location;

  PrayerServiceResolver({
    required DiyanetPrayerService diyanet,
    required AladhanService aladhan,
    required LocationService location,
  }) : _diyanet = diyanet,
       _aladhan = aladhan,
       _location = location;

  // Bellek içi kısa süreli önbellek — aynı günün verisini tekrar tekrar
  // Hive/GPS/ağdan çekmekten kaçınır. PrayerServiceResolver bir Provider
  // singleton'ı olduğu için proses yaşam süresi boyunca canlı kalır.
  PrayerFetchResult? _memCache;
  DateTime? _memCacheAt;

  // Önbellekteki sonucun hangi konum parmak izi ile çekildiği.
  // Format: "{ilceId ?? 'nil'}|{city.lower}" — konum değişince otomatik miss.
  String? _memCacheLocationKey;

  static const _memCacheTtl = Duration(minutes: 30);

  Future<void>? _backgroundLocationRefresh;

  VoidCallback? onCacheInvalidated;

  void notifyCacheInvalidated() => onCacheInvalidated?.call();

  _PrayerLocationSnapshot _locationSnapshot() => _PrayerLocationSnapshot(
    city: _location.savedCity,
    country: _location.savedCountry,
    districtId: _location.savedDistrictId,
    lat: _location.savedLat,
    lon: _location.savedLon,
    isManual: _location.isManualPrayerLocation,
  );

  String _locationKey() => _locationSnapshot().key;

  void invalidateCache() {
    _memCache = null;
    _memCacheAt = null;
    _memCacheLocationKey = null;
  }

  /// Taze (bugünün) namaz vakitlerini getirir. İç sıralama:
  ///   1. Bellek içi önbellek (30 dk, aynı gün) → anında döner
  ///   2. TR + districtId varsa Diyanet → başarıysa bitti
  ///   3. Aladhan (koordinat veya şehir)
  ///   4. Her ikisi de düşerse: Diyanet/Aladhan cache'lerinden eski kayıt
  ///   5. Hiçbiri yoksa `unavailable`
  ///
  /// Konum senkronizasyonu (`syncPrayerLocation`) arka planda çalışır;
  /// mevcut oturumun kayıtlı konum verisi anında kullanılır. Bu sayede
  /// GPS beklenmesinden kaynaklanan ilk yüklenme gecikmesi ortadan kalkar.
  Future<PrayerFetchResult> fetchToday() async {
    final now = DateTime.now();
    var location = _locationSnapshot();

    // 1) Bellek içi önbellek kontrolü — aynı takvim günü + aynı konum +
    //    30 dk içinde ise anında dön.
    final cached = _memCache;
    final cachedAt = _memCacheAt;
    if (cached != null && cached.hasData && cachedAt != null) {
      final sameDay =
          cachedAt.year == now.year &&
          cachedAt.month == now.month &&
          cachedAt.day == now.day;
      final sameLocation = _memCacheLocationKey == _locationKey();
      if (sameDay && sameLocation && now.difference(cachedAt) < _memCacheTtl) {
        _refreshLocationInBackground();
        return cached;
      }
    }

    // 2) Bugünün aynı konuma ait disk cache'i varsa GPS/ağı beklemeden göster.
    //    Diyanet aylık payload'ı ve Aladhan günlük kaydı uygulama kapanınca da
    //    Hive'da kalır. Konum kontrolü arka planda devam eder.
    final diskCached = _tryLoadTodayCachedForLocation(location);
    if (diskCached != null) {
      final result = PrayerFetchResult(diskCached, PrayerSource.cacheOnly);
      _memCache = result;
      _memCacheAt = now;
      _memCacheLocationKey = location.key;
      _refreshLocationInBackground();
      return result;
    }

    // 3) İlk kurulumda hiç konum yoksa bir kez sessiz GPS'i beklemek gerekir.
    //    Kayıtlı şehir/ilçe/koordinat varsa ağ isteğini onunla hemen başlat;
    //    GPS ana sayfadaki namaz kartını bloklamasın.
    final waitForLocation = shouldWaitForInitialPrayerLocation(
      isManual: _location.isManualPrayerLocation,
      city: location.city,
      districtId: location.districtId,
      lat: location.lat,
      lon: location.lon,
    );
    if (waitForLocation) {
      await _location.syncPrayerLocation(
        forceRefresh: true,
        promptIfNeeded: false,
      );
      location = _locationSnapshot();
    } else {
      _refreshLocationInBackground();
    }
    final fetchLocationKey = location.key;

    final isTR = _isTurkey(location.country);
    final ilceId = location.districtId;

    if (isTR && ilceId != null) {
      final m = await _diyanet.fetchToday(
        ilceId: ilceId,
        cityLabel: location.city,
      );
      if (m != null) {
        final result = PrayerFetchResult(m, PrayerSource.diyanet);
        if (_locationKey() != fetchLocationKey) {
          return _resultAfterLocationChanged(now);
        }
        _memCache = result;
        _memCacheAt = now;
        _memCacheLocationKey = fetchLocationKey;
        return result;
      }
    }

    final lat = location.lat;
    final lon = location.lon;
    final city = location.city.trim();
    final country = location.country.trim();
    final canQueryAladhan = (lat != null && lon != null) || city.isNotEmpty;
    if (canQueryAladhan) {
      try {
        final m = await _fetchAladhanToday(
          lat: lat,
          lon: lon,
          city: city,
          country: country,
          preferCity: location.isManual,
        );
        final result = PrayerFetchResult(m, PrayerSource.aladhan);
        if (_locationKey() != fetchLocationKey) {
          return _resultAfterLocationChanged(now);
        }
        _memCache = result;
        _memCacheAt = now;
        _memCacheLocationKey = fetchLocationKey;
        return result;
      } catch (_) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          final m = await _fetchAladhanToday(
            lat: lat,
            lon: lon,
            city: city,
            country: country,
            preferCity: location.isManual,
          );
          final result = PrayerFetchResult(m, PrayerSource.aladhan);
          if (_locationKey() != fetchLocationKey) {
            return _resultAfterLocationChanged(now);
          }
          _memCache = result;
          _memCacheAt = now;
          _memCacheLocationKey = fetchLocationKey;
          return result;
        } catch (_) {
          // Ağ düştü → cache zincirine bak.
        }
      }
    }

    // UI'da yalnız aynı konum kapsamına ait cache kullanılabilir. Başka bir
    // şehrin `AnyScope` kaydı yalnız bildirim scheduler'ının son çaresidir.
    final exactFallback = _tryLoadTodayCachedForLocation(location);
    if (exactFallback != null) {
      final result = PrayerFetchResult(exactFallback, PrayerSource.cacheOnly);
      if (_locationKey() != fetchLocationKey) {
        return _resultAfterLocationChanged(now);
      }
      _memCache = result;
      _memCacheAt = now;
      _memCacheLocationKey = fetchLocationKey;
      return result;
    }

    if (_locationKey() != fetchLocationKey) {
      return _resultAfterLocationChanged(now);
    }
    return const PrayerFetchResult(null, PrayerSource.unavailable);
  }

  PrayerFetchResult _resultAfterLocationChanged(DateTime now) {
    invalidateCache();
    final current = _locationSnapshot();
    final cached = _tryLoadTodayCachedForLocation(current);
    if (cached == null) {
      return const PrayerFetchResult(null, PrayerSource.unavailable);
    }
    final result = PrayerFetchResult(cached, PrayerSource.cacheOnly);
    _memCache = result;
    _memCacheAt = now;
    _memCacheLocationKey = current.key;
    return result;
  }

  PrayerTimesModel? _tryLoadTodayCachedForLocation(
    _PrayerLocationSnapshot location,
  ) {
    final city = location.city.trim();
    final country = location.country.trim();

    if (_isTurkey(country) && location.districtId != null) {
      final diyanet = _diyanet.tryLoadTodayCached(
        ilceId: location.districtId!,
        cityLabel: city,
      );
      if (diyanet != null) return diyanet;
    }
    if ((location.lat != null && location.lon != null) || city.isNotEmpty) {
      return _aladhan.tryLoadTodayCached(
        city: city,
        country: country,
        lat: location.isManual ? null : location.lat,
        lon: location.isManual ? null : location.lon,
      );
    }
    return null;
  }

  void _refreshLocationInBackground() {
    if (_backgroundLocationRefresh != null) return;
    final job = _location.syncPrayerLocation();
    _backgroundLocationRefresh = job;
    unawaited(
      job
          .then<void>((_) {}, onError: (Object _, StackTrace __) {})
          .whenComplete(() {
            if (identical(_backgroundLocationRefresh, job)) {
              _backgroundLocationRefresh = null;
            }
          }),
    );
  }

  /// Scheduler için senkron fallback: offline'da bile bildirim planını
  /// zincire sokabilmek için cache'ten okur.
  PrayerTimesModel? tryLoadTodayCached() {
    final isTR = _isTurkey(_location.savedCountry);
    final ilceId = _location.savedDistrictId;
    if (isTR && ilceId != null) {
      final m = _diyanet.tryLoadTodayCached(
        ilceId: ilceId,
        cityLabel: _location.savedCity,
      );
      if (m != null) return m;
    }
    return _aladhan.tryLoadTodayCachedAnyScope();
  }

  /// Bugünden itibaren [days] gün için namaz vakitleri. Scheduler bunu
  /// alarak 7 günlük bildirim penceresini kapatır — kullanıcı uygulamayı
  /// bir hafta açmasa bile bildirimler kesintisiz gelir.
  ///
  /// Başarı yolu:
  ///   1) Türkiye + ilçeId varsa Diyanet (30 günlük payload cache'ten
  ///      ağ trafiği yok).
  ///   2) Aksi halde Aladhan `/calendar*` ile ay bazlı fetch.
  ///   3) Her ikisi de düşerse en azından "bugünün" tek kaydı (liste
  ///      tek elemanlı döner). Scheduler hiç liste alamazsa eski tek
  ///      gün fallback'ine düşer.
  Future<List<PrayerTimesModel>> fetchUpcomingDays({int days = 7}) async {
    await _location.syncPrayerLocation();

    final isTR = _isTurkey(_location.savedCountry);
    final ilceId = _location.savedDistrictId;

    if (isTR && ilceId != null) {
      try {
        final list = await _diyanet.fetchUpcomingDays(
          ilceId: ilceId,
          cityLabel: _location.savedCity,
          days: days,
        );
        if (list.isNotEmpty) return list;
      } catch (_) {
        // Düş — Aladhan'ı dene.
      }
    }

    final lat = _location.savedLat;
    final lon = _location.savedLon;
    final city = _location.savedCity.trim();
    if ((lat != null && lon != null) || city.isNotEmpty) {
      try {
        final list =
            shouldUseAladhanCityName(
                  isManual: _location.isManualPrayerLocation,
                  city: city,
                ) ||
                lat == null ||
                lon == null
            ? await _aladhan.fetchUpcomingByCity(
                city: city,
                country: _location.savedCountry,
                days: days,
              )
            : await _aladhan.fetchUpcomingByCoordinates(
                latitude: lat,
                longitude: lon,
                cityLabel: _location.savedCity,
                days: days,
              );
        if (list.isNotEmpty) return list;
      } catch (_) {
        // Tek gün fallback'ine düş.
      }
    }

    // Son çare — tek gün (eski davranış). Scheduler bunu tek elemanlı
    // liste olarak alıp klasik "bugün + ertesi imsak/fajr" planına düşer.
    if (isTR && ilceId != null) {
      final m = _diyanet.tryLoadTodayCached(
        ilceId: ilceId,
        cityLabel: _location.savedCity,
      );
      if (m != null) return [m];
    }
    final anyScope = _aladhan.tryLoadTodayCachedAnyScope();
    if (anyScope != null) return [anyScope];
    return const <PrayerTimesModel>[];
  }

  Future<PrayerTimesModel> _fetchAladhanToday({
    required double? lat,
    required double? lon,
    required String city,
    required String country,
    required bool preferCity,
  }) {
    if (shouldUseAladhanCityName(isManual: preferCity, city: city) ||
        lat == null ||
        lon == null) {
      return _aladhan.fetchByCity(city: city, country: country);
    }
    return _aladhan.fetchByCoordinates(
      latitude: lat,
      longitude: lon,
      cityLabel: city,
    );
  }

  static bool _isTurkey(String country) {
    return _isTurkeyCountry(country);
  }
}

final diyanetPrayerServiceProvider = Provider<DiyanetPrayerService>(
  (_) => DiyanetPrayerService(),
);

final prayerServiceResolverProvider = Provider<PrayerServiceResolver>((ref) {
  final resolver = PrayerServiceResolver(
    diyanet: ref.read(diyanetPrayerServiceProvider),
    aladhan: ref.read(_aladhanServiceForResolverProvider),
    location: ref.read(locationServiceProvider),
  );
  ref.read(locationServiceProvider).onSilentLocationChanged = () {
    resolver.invalidateCache();
    // Dinleyicileri uyaralım
    Future.microtask(() => resolver.notifyCacheInvalidated());
  };
  return resolver;
});

/// `aladhanServiceProvider` `prayer_time_providers.dart`'ta da tanımlı;
/// dairesel import'tan kaçınmak için burada küçük bir forward-provider
/// tutup üst katman yeniden kullanır.
final _aladhanServiceForResolverProvider = Provider<AladhanService>(
  (_) => AladhanService(),
);
