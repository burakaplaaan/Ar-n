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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/shared/providers/prayer_time_providers.dart';

import '../models/prayer_times_model.dart';
import 'aladhan_service.dart';
import 'diyanet_prayer_service.dart';
import 'location_service.dart';

/// Hangi kaynağın vakitleri ürettiğini açıkça belirtmek için. UI'da
/// "Kaynak: Diyanet" rozeti için; ayrıca log & telemetri için.
enum PrayerSource { diyanet, aladhan, cacheOnly, unavailable }

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
  })  : _diyanet = diyanet,
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

  String _locationKey() {
    final id = _location.savedDistrictId;
    final city = _location.savedCity.trim().toLowerCase();
    return '${id ?? 'nil'}|$city';
  }

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

    // İlk açılışta şehir/koordinat boşsa bir kez konum senkronu bekle;
    // aksi halde Aladhan'a boş şehirle gidip sürekli hata döngüsüne girer.
    if (_location.savedCity.trim().isEmpty ||
        _location.savedCountry.trim().isEmpty ||
        (_location.savedLat == null || _location.savedLon == null)) {
      await _location.syncPrayerLocation(forceRefresh: true);
    }

    // 1) Bellek içi önbellek kontrolü — aynı takvim günü + aynı konum +
    //    30 dk içinde ise anında dön; arka planda konumu tazele (GPS bloklamaz).
    final cached = _memCache;
    final cachedAt = _memCacheAt;
    if (cached != null && cached.hasData && cachedAt != null) {
      final sameDay = cachedAt.year == now.year &&
          cachedAt.month == now.month &&
          cachedAt.day == now.day;
      final sameLocation = _memCacheLocationKey == _locationKey();
      if (sameDay && sameLocation && now.difference(cachedAt) < _memCacheTtl) {
        // Konum senkronizasyonu arka planda; bu çağrıyı bloklamaz.
        unawaited(_location.syncPrayerLocation());
        return cached;
      }
    }

    // 2) Konumu önce senkronize et; böylece şehir/ilçe değişikliği sonrası
    //    yanlış konumdan çekim yapılıp cache'e yazılmaz.
    await _location.syncPrayerLocation();
    final fetchLocationKey = _locationKey();

    final isTR = _isTurkey(_location.savedCountry);
    final ilceId = _location.savedDistrictId;

    if (isTR && ilceId != null) {
      final m = await _diyanet.fetchToday(
        ilceId: ilceId,
        cityLabel: _location.savedCity,
      );
      if (m != null) {
        final result = PrayerFetchResult(m, PrayerSource.diyanet);
        _memCache = result;
        _memCacheAt = now;
        _memCacheLocationKey = fetchLocationKey;
        return result;
      }
    }

    final lat = _location.savedLat;
    final lon = _location.savedLon;
    try {
      final m = lat != null && lon != null
          ? await _aladhan.fetchByCoordinates(
              latitude: lat,
              longitude: lon,
              cityLabel: _location.savedCity,
            )
          : await _aladhan.fetchByCity(
              city: _location.savedCity,
              country: _location.savedCountry,
            );
      final result = PrayerFetchResult(m, PrayerSource.aladhan);
      _memCache = result;
      _memCacheAt = now;
      _memCacheLocationKey = fetchLocationKey;
      return result;
    } catch (_) {
      // Ağ düştü → cache zincirine bak.
    }

    // Cache zinciri — önce Diyanet (daha doğru), sonra Aladhan.
    if (isTR && ilceId != null) {
      final m = _diyanet.tryLoadTodayCached(
        ilceId: ilceId,
        cityLabel: _location.savedCity,
      );
      if (m != null) {
        final result = PrayerFetchResult(m, PrayerSource.cacheOnly);
        _memCache = result;
        _memCacheAt = now;
        _memCacheLocationKey = fetchLocationKey;
        return result;
      }
    }
    final anyScope = _aladhan.tryLoadTodayCachedAnyScope();
    if (anyScope != null) {
      final result = PrayerFetchResult(anyScope, PrayerSource.cacheOnly);
      _memCache = result;
      _memCacheAt = now;
      _memCacheLocationKey = fetchLocationKey;
      return result;
    }

    return const PrayerFetchResult(null, PrayerSource.unavailable);
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
    try {
      final list = lat != null && lon != null
          ? await _aladhan.fetchUpcomingByCoordinates(
              latitude: lat,
              longitude: lon,
              cityLabel: _location.savedCity,
              days: days,
            )
          : await _aladhan.fetchUpcomingByCity(
              city: _location.savedCity,
              country: _location.savedCountry,
              days: days,
            );
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Tek gün fallback'ine düş.
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

  static bool _isTurkey(String country) {
    final c = country.trim().toLowerCase();
    return c == 'turkey' ||
        c == 'türkiye' ||
        c == 'turkiye' ||
        c == 'tr';
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
    // Cache'i invalidate edip doğrudan dışarıya provider invalidate çağrısı fırlatarak 
    // dinleyicileri uyaralım.
    Future.microtask(() => ref.invalidate(prayerTimesProvider));
  };
  return resolver;
});

/// `aladhanServiceProvider` `prayer_time_providers.dart`'ta da tanımlı;
/// dairesel import'tan kaçınmak için burada küçük bir forward-provider
/// tutup üst katman yeniden kullanır.
final _aladhanServiceForResolverProvider = Provider<AladhanService>(
  (_) => AladhanService(),
);
