// lib/data/services/diyanet_prayer_service.dart
//
// Diyanet resmi namaz vakitlerini `ezanvakti.emushaf.net` proxy'si
// üzerinden çeken servis. Türkiye birincil kaynak.
//
// Proxy Diyanet'in kendi verisini mirror'lıyor; `GET /vakitler/{ilceId}`
// tek istekle o ilçenin **sonraki ~30 günü**ni döndürüyor. Bu mimari
// günlük API trafiğini en aza indiriyor: gün başına 1 istek değil, ayda
// 1 istek. Cihaz offline ise cache'teki son 30 gün hâlâ geçerli.
//
// Kırılmaz olmayan 3. parti bir servise bel bağladığımız için:
//   - HTTP timeout 7 sn (prayer UI fetch'i uygulama açılışını bloklamasın)
//   - 5xx veya network-error → `null`, üst katmandaki resolver Aladhan'a düşer
//   - 30 günlük cache payload'ı Hive `prayerTimesCache` box'ında tutulur
//   - Cache key format'ı `diyanet_v1_{ilceId}` — versiyon bump kolay
//     (ileride ezanvakti şeması değişirse v2 ile eski cache invalide olur)

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../../core/utils/hive_boxes.dart';
import '../models/prayer_times_model.dart';

class DiyanetPrayerService {
  static const _baseUrl = 'https://ezanvakti.emushaf.net';
  static const _cacheVersion = 'v1';
  static const _staleThreshold = Duration(days: 25);

  final Dio _dio;

  DiyanetPrayerService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 7),
            receiveTimeout: const Duration(seconds: 7),
            headers: {
              // Cloudflare bot-filter User-Agent'sız istekleri düşürüyor.
              'User-Agent': 'Arin-Prayer/1.0 (com.arin.arin)',
              'Accept': 'application/json',
            },
          ),
        );

  Box<dynamic> get _cache => Hive.box<dynamic>(HiveBoxes.prayerTimesCache);

  String _cacheKey(int ilceId) => 'diyanet_${_cacheVersion}_$ilceId';

  /// "dd.MM.yyyy" → "yyyy-MM-dd" (model formatı).
  static String _isoDateFromDiyanet(String ddmmyyyy) {
    final p = ddmmyyyy.split('.');
    if (p.length != 3) return ddmmyyyy;
    return '${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}';
  }

  static String _isoDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Bugünün vaktini `PrayerTimesModel` olarak döndürür.
  /// Sıra: taze cache → ağ → eski cache → `null`.
  ///
  /// Ağ hatası üst katmanda "Aladhan fallback" tetikleyeceği için
  /// exception fırlatmıyoruz; `null` dönüşünde çağıran resolver devralır.
  Future<PrayerTimesModel?> fetchToday({
    required int ilceId,
    required String cityLabel,
  }) async {
    final todayIso = _isoDateKey(DateTime.now());

    // 1) Taze cache varsa ağı hiç deneme.
    final fresh = _readTodayFromCache(
      ilceId: ilceId,
      cityLabel: cityLabel,
      todayIso: todayIso,
      allowStale: false,
    );
    if (fresh != null) return fresh;

    // 2) Ağ.
    try {
      final resp = await _dio.get<dynamic>('/vakitler/$ilceId');
      final data = resp.data;
      if (data is! List || data.isEmpty) {
        return _readStaleFromCache(
        ilceId: ilceId,
        cityLabel: cityLabel,
        todayIso: todayIso,
      );
      }

      final days = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);

      // Bütün 30 günlük payload'ı cache'le.
      await _cache.put(_cacheKey(ilceId), {
        'fetchedAt': DateTime.now().millisecondsSinceEpoch,
        'cityLabel': cityLabel,
        'days': days.map((m) => Map<String, dynamic>.from(m)).toList(),
      });

      final todayMap = _pickDayByIso(days, todayIso);
      if (todayMap == null) return null;
      return PrayerTimesModel.fromDiyanet(todayMap, todayIso, cityLabel);
    } on DioException {
      return _readStaleFromCache(
        ilceId: ilceId,
        cityLabel: cityLabel,
        todayIso: todayIso,
      );
    } catch (_) {
      return _readStaleFromCache(
        ilceId: ilceId,
        cityLabel: cityLabel,
        todayIso: todayIso,
      );
    }
  }

  /// Scheduler için: ağ olmadan bugünün kaydını cache'ten oku.
  /// Fetch timestamp çok eskiyse (30+ gün) yine de döner — "hiç vakit yok"
  /// durumundan "az ihtimalle 1-2 dk sapma" yeğdir.
  PrayerTimesModel? tryLoadTodayCached({
    required int ilceId,
    required String cityLabel,
  }) {
    final todayIso = _isoDateKey(DateTime.now());
    return _readTodayFromCache(
      ilceId: ilceId,
      cityLabel: cityLabel,
      todayIso: todayIso,
      allowStale: true,
    );
  }

  PrayerTimesModel? _readTodayFromCache({
    required int ilceId,
    required String cityLabel,
    required String todayIso,
    required bool allowStale,
  }) {
    final raw = _cache.get(_cacheKey(ilceId));
    if (raw is! Map) return null;
    final fetchedAt = raw['fetchedAt'];
    if (!allowStale && fetchedAt is int) {
      final age = DateTime.now().millisecondsSinceEpoch - fetchedAt;
      if (age > _staleThreshold.inMilliseconds) return null;
    }
    final days = raw['days'];
    if (days is! List) return null;
    final mapped = days
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final today = _pickDayByIso(mapped, todayIso);
    if (today == null) return null;
    return PrayerTimesModel.fromDiyanet(today, todayIso, cityLabel);
  }

  PrayerTimesModel? _readStaleFromCache({
    required int ilceId,
    required String cityLabel,
    required String todayIso,
  }) =>
      _readTodayFromCache(
        ilceId: ilceId,
        cityLabel: cityLabel,
        todayIso: todayIso,
        allowStale: true,
      );

  /// ezanvakti "dd.MM.yyyy" tarih alanına göre o günü bul.
  static Map<String, dynamic>? _pickDayByIso(
    List<Map<String, dynamic>> days,
    String targetIsoDate,
  ) {
    for (final d in days) {
      final raw = d['MiladiTarihKisa'] ?? d['MiladiTarihKisaIso8601'];
      if (raw is! String || raw.isEmpty) continue;
      if (_isoDateFromDiyanet(raw) == targetIsoDate) return d;
    }
    return null;
  }

  // ─────────────────────────── Çok günlük plan ───────────────────────────

  /// Bugünden itibaren [days] gün için model listesi — scheduler'ın 7 günlük
  /// pencereyi kapatması için. Zaten 30 günlük payload cache'te tutulduğundan
  /// ek ağ trafiği gerekmez; cache yoksa bir kez `fetchToday` çağrısı
  /// tetiklenir (o da 30 günü alır).
  Future<List<PrayerTimesModel>> fetchUpcomingDays({
    required int ilceId,
    required String cityLabel,
    int days = 7,
  }) async {
    // Cache taze değilse tetikle: `fetchToday` hem kontrol eder hem 30 günü
    // yeniler.
    await fetchToday(ilceId: ilceId, cityLabel: cityLabel);
    return tryLoadUpcomingDaysCached(
      ilceId: ilceId,
      cityLabel: cityLabel,
      days: days,
    );
  }

  /// Ağ istemeden cache'teki upcoming gün kayıtlarını döner. `fetchToday`
  /// başarısız olursa bu yine de geçmişte çekilmiş payload'ı kullanır.
  List<PrayerTimesModel> tryLoadUpcomingDaysCached({
    required int ilceId,
    required String cityLabel,
    int days = 7,
  }) {
    if (days <= 0) return const <PrayerTimesModel>[];
    final raw = _cache.get(_cacheKey(ilceId));
    if (raw is! Map) return const <PrayerTimesModel>[];
    final dayList = raw['days'];
    if (dayList is! List) return const <PrayerTimesModel>[];
    final mapped = dayList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final out = <PrayerTimesModel>[];
    for (var i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final iso = _isoDateKey(d);
      final day = _pickDayByIso(mapped, iso);
      if (day == null) break; // sonraki günleri denemek anlamsız (sıralı)
      try {
        out.add(PrayerTimesModel.fromDiyanet(day, iso, cityLabel));
      } catch (e) {
        // Bozuk bir gün kaydı; sırayı bozmamak için atla.
        break;
      }
    }
    return out;
  }
}
