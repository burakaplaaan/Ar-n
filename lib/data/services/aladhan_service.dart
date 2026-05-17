// lib/data/services/aladhan_service.dart
// Aladhan API + Hive önbellek (konum kapsamına göre anahtar).

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/prayer_times_model.dart';
import '../../core/utils/hive_boxes.dart';

class AladhanService {
  static const _baseUrl = 'https://api.aladhan.com/v1';
  // Türkiye — Diyanet metodu (Aladhan `method=13` = TURKIYE DIYANET).
  static const _method = 13;

  /// Aladhan `school` parametresi — İKİNDİ (Asr) hesap yöntemi:
  ///   0 = Standard/Shafi (gölge = nesne boyu)
  ///   1 = Hanafi         (gölge = 2 × nesne boyu, ~1 saat sonra)
  ///
  /// Türkiye Diyanet, Hanefi fıkhı uygulayan bir kurum olmasına rağmen
  /// RESMÎ namaz vakti tablolarını Standard/Shafi Asr ile yayınlar
  /// (Kocaeli, İstanbul, Ankara vb. ölçüldü). Bu yüzden `method=13` ile
  /// `school=1` birleştirilirse ikindi Diyanet ezanından ~1 saat sonraya
  /// düşer → kullanıcı "1 saat ileri" diye raporluyordu. `method=13` ile
  /// DOĞRU eşleşme `school=0`. Bu değer burada tek noktadan zorlanır.
  static const _defaultSchool = 0;

  final Dio _dio;

  AladhanService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  Box<dynamic> get _cache => Hive.box<dynamic>(HiveBoxes.prayerTimesCache);

  static String _dateKey() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Aynı gün + farklı şehir/koordinat için çakışmayı önler.
  ///
  /// Scope'a `m{method}_s{school}` imzası eklenir — böylece method veya
  /// Asr ekolü değiştiğinde eski (hatalı) cache otomatik görünmez olur
  /// (yeni anahtarda miss yaşanır, API yeniden çağrılır). Eski key'ler
  /// Hive box'ta kalsa da artık okunmaz; gün dönünce `_dateKey` doğal
  /// olarak onları da çöpe atar.
  static String _paramsTag({required int method, required int school}) =>
      'm${method}_s$school';

  static String cacheScopeCity(
    String city,
    String country, {
    int method = _method,
    int school = _defaultSchool,
  }) =>
      'c_${_paramsTag(method: method, school: school)}_'
      '${city.toLowerCase()}_${country.toLowerCase()}';

  static String cacheScopeCoords(
    double lat,
    double lon, {
    int method = _method,
    int school = _defaultSchool,
  }) =>
      'g_${_paramsTag(method: method, school: school)}_'
      '${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}';

  String _hiveKey(String scope) => '${_dateKey()}_$scope';

  PrayerTimesModel? _loadFromCache(String scope) {
    final key = _hiveKey(scope);
    final raw = _cache.get(key);
    if (raw is! Map) return null;
    try {
      return PrayerTimesModel.fromMap(raw);
    } catch (e) {
      // Bozuk cache kaydı (eski şema / Hive korrupsiyonu). Sessizce null
      // dön — çağıran fetch katmanı API'den yeniden alır. Entry'i
      // silmek yerine bırakıyoruz; gün dönünce _dateKey değişecek ve
      // zaten doğal olarak terk edilecek.
      debugPrint('AladhanService: cache parse skip key=$key err=$e');
      return null;
    }
  }

  /// Ağ olmadan bildirim yeniden planlamak için: bugünün Hive kaydı (yoksa null).
  PrayerTimesModel? tryLoadTodayCached({
    required String city,
    required String country,
    double? lat,
    double? lon,
  }) {
    final scope = lat != null && lon != null
        ? cacheScopeCoords(lat, lon)
        : cacheScopeCity(city, country);
    return _loadFromCache(scope);
  }

  /// Şehir/koordinat kapsamı uyuşmazsa veya ağ kesildiyse: bugünün **herhangi bir**
  /// önbellek kaydı (ilk geçerli girdi). Bildirim planlamasının tamamen düşmemesini sağlar.
  ///
  /// KRİTİK: yalnızca güncel `_method`/`_defaultSchool` imzasını taşıyan
  /// key'leri kabul eder. Aksi halde `school=1` (Hanafi) ile yapılmış eski
  /// bozuk kayıtlar bildirim zamanlayıcısı tarafından "offline fallback"
  /// olarak okunup ikindi'yi 1 saat ileri atıyordu.
  ///
  /// Eski günlük key'leri (bugüne ait olmayan) otomatik temizler; böylece
  /// Hive box sınırsız büyümez ve bu döngünün O(n) maliyeti kontrol altında
  /// kalır.
  PrayerTimesModel? tryLoadTodayCachedAnyScope() {
    final todayPrefix = '${_dateKey()}_';
    final requiredTag =
        '_${_paramsTag(method: _method, school: _defaultSchool)}_';

    // Günlük key'ler `{yyyy-MM-dd}_...` formatındadır. Aylık takvim key'leri
    // `{yyyy-MM}_calm...` formatındadır — tarih regex'i ile ayırt edilir.
    final dailyKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}_');

    // Silinecek eski günlük key'leri topla (silme işlemi döngü içinde değil).
    final toDelete = <dynamic>[];

    PrayerTimesModel? found;
    for (final key in _cache.keys) {
      if (key is! String) continue;

      // Eski günlük key temizliği: bugüne ait değil + aylık key değil.
      if (dailyKeyPattern.hasMatch(key) && !key.startsWith(todayPrefix)) {
        toDelete.add(key);
        continue;
      }

      if (!key.startsWith(todayPrefix)) continue;
      if (!key.contains(requiredTag)) continue;

      if (found != null) continue; // ilk geçerli sonuç yeterli

      final raw = _cache.get(key);
      if (raw is Map) {
        try {
          found = PrayerTimesModel.fromMap(raw);
        } catch (e) {
          debugPrint('AladhanService: cache parse skip key=$key err=$e');
        }
      }
    }

    // Eski key'leri toplu sil — Hive box büyümesini önler.
    if (toDelete.isNotEmpty) {
      unawaited(_cache.deleteAll(toDelete));
    }

    return found;
  }

  Future<void> _saveToCache(PrayerTimesModel model, String scope) async {
    await _cache.put(_hiveKey(scope), model.toMap());
  }

  Future<PrayerTimesModel> fetchByCity({
    required String city,
    required String country,
    int school = _defaultSchool,
  }) async {
    final scope = cacheScopeCity(city, country, school: school);
    final cached = _loadFromCache(scope);
    if (cached != null && cached.city == city) return cached;

    final today = DateTime.now();
    try {
      final response = await _dio.get(
        '/timingsByCity',
        queryParameters: {
          'city': city,
          'country': country,
          'method': _method,
          'school': school,
          'day': today.day,
          'month': today.month,
          'year': today.year,
        },
      );
      final model = _parseTimingsResponse(response.data, city);
      await _saveToCache(model, scope);
      return model;
    } on DioException catch (e) {
      final cached = _loadFromCache(scope);
      if (cached != null) return cached;
      throw Exception('Namaz vakitleri alınamadı: ${e.message}');
    } on FormatException catch (e) {
      // API yapısı bozulmuş veya eksik alan — cache varsa ona düş, yoksa
      // kullanıcıya "alınamadı" mesajı ver (throw). Uygulama çökmez.
      debugPrint('AladhanService: fetchByCity parse failed: $e');
      final cached = _loadFromCache(scope);
      if (cached != null) return cached;
      throw Exception('Namaz vakitleri alınamadı: beklenmeyen yanıt.');
    }
  }

  Future<PrayerTimesModel> fetchByCoordinates({
    required double latitude,
    required double longitude,
    required String cityLabel,
    int school = _defaultSchool,
  }) async {
    final scope = cacheScopeCoords(latitude, longitude, school: school);
    final cached = _loadFromCache(scope);
    if (cached != null) return cached;

    final today = DateTime.now();
    try {
      final response = await _dio.get(
        '/timings/${today.millisecondsSinceEpoch ~/ 1000}',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'method': _method,
          'school': school,
        },
      );
      final model = _parseTimingsResponse(response.data, cityLabel);
      await _saveToCache(model, scope);
      return model;
    } on DioException catch (e) {
      final cached = _loadFromCache(scope);
      if (cached != null) return cached;
      throw Exception('Namaz vakitleri alınamadı: ${e.message}');
    } on FormatException catch (e) {
      debugPrint('AladhanService: fetchByCoordinates parse failed: $e');
      final cached = _loadFromCache(scope);
      if (cached != null) return cached;
      throw Exception('Namaz vakitleri alınamadı: beklenmeyen yanıt.');
    }
  }

  /// Aladhan yanıtındaki `data.timings` bloğunu güvenli şekilde çıkarır.
  /// Eski kodda `as Map<String, dynamic>` cast'leri vardı — API bir alanı
  /// null veya farklı tipte döndürürse `TypeError` fırlatıyor ve çağıran
  /// `on DioException` onu yakalamıyordu. Artık `FormatException` olarak
  /// normalize ediliyor.
  PrayerTimesModel _parseTimingsResponse(Object? body, String cityLabel) {
    if (body is! Map) {
      throw const FormatException('Aladhan response body is not a Map');
    }
    final data = body['data'];
    if (data is! Map) {
      throw const FormatException('Aladhan response.data missing');
    }
    final timings = data['timings'];
    if (timings is! Map) {
      throw const FormatException('Aladhan response.data.timings missing');
    }
    final timingsTyped = timings.map(
      (k, v) => MapEntry(k.toString(), v),
    );
    return PrayerTimesModel.fromJson(timingsTyped, _dateKey(), cityLabel);
  }

  // ─────────────────────────── Çok günlük fetch ───────────────────────────
  //
  // Namaz bildirimlerinin kullanıcı uygulamayı açmadan günlerce doğru
  // şekilde gelmesi için scheduler'a bugünden itibaren birden fazla günün
  // tam vakit tablosunu vermemiz gerekiyor. Aladhan'ın `/calendarByCity`
  // ve `/calendar` endpoint'leri tek istekte o ayın tamamını (28-31 gün)
  // döndürüyor — 7 günlük pencere için genelde 1 istek yetiyor, ay sonuna
  // yakınsak 2 ay çekilir.
  //
  // Cache: `{yyyy-MM}_calm{method}s{school}_scope` anahtarıyla Hive'a
  // yazılır (tek gün cache'lerinden tamamen ayrı namespace). Ay bazlı
  // payload ayda bir kez çekilmiş olur.

  String _monthCacheKey({
    required int year,
    required int month,
    required String scopeTag,
    int method = _method,
    int school = _defaultSchool,
  }) =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}_'
      'calm${method}s$school'
      '_$scopeTag';

  /// Bugünden itibaren [days] gün için `PrayerTimesModel` listesi.
  /// Çıkan liste sıralıdır ve `model.date == yyyy-MM-dd` formatındadır.
  /// Her gün üretilememişse (ay kayması + ağ düştüyse) liste daha kısa
  /// olabilir — bu durumda çağıran scheduler mevcut günleri planlar ve
  /// eksik kalan son günler uygulamanın bir sonraki açılışında tamamlanır.
  Future<List<PrayerTimesModel>> fetchUpcomingByCity({
    required String city,
    required String country,
    int days = 7,
    int school = _defaultSchool,
  }) async {
    final scopeTag =
        'city_${city.toLowerCase()}_${country.toLowerCase()}';
    return _fetchUpcoming(
      days: days,
      cityLabel: city,
      scopeTag: scopeTag,
      school: school,
      fetchMonth: (year, month) => _fetchCalendarByCity(
        city: city,
        country: country,
        year: year,
        month: month,
        school: school,
      ),
    );
  }

  /// Bugünden itibaren [days] gün için koordinat tabanlı çağrı.
  Future<List<PrayerTimesModel>> fetchUpcomingByCoordinates({
    required double latitude,
    required double longitude,
    required String cityLabel,
    int days = 7,
    int school = _defaultSchool,
  }) async {
    final scopeTag =
        'gps_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
    return _fetchUpcoming(
      days: days,
      cityLabel: cityLabel,
      scopeTag: scopeTag,
      school: school,
      fetchMonth: (year, month) => _fetchCalendarByCoordinates(
        latitude: latitude,
        longitude: longitude,
        cityLabel: cityLabel,
        year: year,
        month: month,
        school: school,
      ),
    );
  }

  Future<List<PrayerTimesModel>> _fetchUpcoming({
    required int days,
    required String cityLabel,
    required String scopeTag,
    required int school,
    required Future<List<PrayerTimesModel>> Function(int year, int month)
        fetchMonth,
  }) async {
    if (days <= 0) return const <PrayerTimesModel>[];
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    // Gerekli ay(lar)ı belirle: bugün ve +days günü farklı aylara düşerse
    // iki ay çekilir.
    final monthsNeeded = <(int year, int month)>{(start.year, start.month)};
    final last = start.add(Duration(days: days - 1));
    monthsNeeded.add((last.year, last.month));

    final allDays = <String, PrayerTimesModel>{};
    for (final (year, month) in monthsNeeded) {
      try {
        final entries = await _fetchOrLoadMonth(
          year: year,
          month: month,
          scopeTag: scopeTag,
          cityLabel: cityLabel,
          school: school,
          fetchMonth: fetchMonth,
        );
        for (final m in entries) {
          allDays[m.date] = m;
        }
      } catch (e) {
        debugPrint(
          'AladhanService: fetchUpcoming month $year-$month failed: $e',
        );
      }
    }

    final result = <PrayerTimesModel>[];
    for (var i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key =
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      final model = allDays[key];
      if (model != null) result.add(model);
    }
    return result;
  }

  Future<List<PrayerTimesModel>> _fetchOrLoadMonth({
    required int year,
    required int month,
    required String scopeTag,
    required String cityLabel,
    required int school,
    required Future<List<PrayerTimesModel>> Function(int year, int month)
        fetchMonth,
  }) async {
    final key = _monthCacheKey(
      year: year,
      month: month,
      scopeTag: scopeTag,
      school: school,
    );
    final raw = _cache.get(key);
    if (raw is Map) {
      final daysRaw = raw['days'];
      if (daysRaw is List) {
        final parsed = <PrayerTimesModel>[];
        for (final d in daysRaw) {
          if (d is Map) {
            try {
              parsed.add(PrayerTimesModel.fromMap(d));
            } catch (e) {
              debugPrint('AladhanService: month cache parse skip: $e');
            }
          }
        }
        if (parsed.isNotEmpty) return parsed;
      }
    }
    final fetched = await fetchMonth(year, month);
    if (fetched.isNotEmpty) {
      await _cache.put(key, {
        'fetchedAt': DateTime.now().millisecondsSinceEpoch,
        'cityLabel': cityLabel,
        'days': fetched.map((m) => m.toMap()).toList(growable: false),
      });
    }
    return fetched;
  }

  Future<List<PrayerTimesModel>> _fetchCalendarByCity({
    required String city,
    required String country,
    required int year,
    required int month,
    required int school,
  }) async {
    try {
      final response = await _dio.get(
        '/calendarByCity/$year/$month',
        queryParameters: {
          'city': city,
          'country': country,
          'method': _method,
          'school': school,
        },
      );
      return _parseCalendarResponse(response.data, city);
    } on DioException catch (e) {
      debugPrint('AladhanService: calendarByCity $year-$month $e');
      return const <PrayerTimesModel>[];
    } on FormatException catch (e) {
      debugPrint('AladhanService: calendarByCity parse $year-$month $e');
      return const <PrayerTimesModel>[];
    }
  }

  Future<List<PrayerTimesModel>> _fetchCalendarByCoordinates({
    required double latitude,
    required double longitude,
    required String cityLabel,
    required int year,
    required int month,
    required int school,
  }) async {
    try {
      final response = await _dio.get(
        '/calendar/$year/$month',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'method': _method,
          'school': school,
        },
      );
      return _parseCalendarResponse(response.data, cityLabel);
    } on DioException catch (e) {
      debugPrint('AladhanService: calendar(coords) $year-$month $e');
      return const <PrayerTimesModel>[];
    } on FormatException catch (e) {
      debugPrint('AladhanService: calendar(coords) parse $year-$month $e');
      return const <PrayerTimesModel>[];
    }
  }

  /// Aladhan calendar yanıtı: `{ data: [ { timings: {...},
  /// date: { gregorian: { date: "22-04-2026", ... }}}, ... ] }`.
  /// Her günü `PrayerTimesModel`'a çevirir; bozuk/eksik günler atlanır.
  List<PrayerTimesModel> _parseCalendarResponse(
    Object? body,
    String cityLabel,
  ) {
    if (body is! Map) {
      throw const FormatException('Aladhan calendar body is not a Map');
    }
    final data = body['data'];
    if (data is! List) {
      throw const FormatException('Aladhan calendar data missing');
    }
    final out = <PrayerTimesModel>[];
    for (final entry in data) {
      if (entry is! Map) continue;
      final timings = entry['timings'];
      final dateBlock = entry['date'];
      if (timings is! Map || dateBlock is! Map) continue;
      final greg = dateBlock['gregorian'];
      if (greg is! Map) continue;
      final rawDate = greg['date'];
      if (rawDate is! String) continue;
      // "22-04-2026" → "2026-04-22"
      final parts = rawDate.split('-');
      if (parts.length != 3) continue;
      final iso = '${parts[2]}-${parts[1].padLeft(2, '0')}-'
          '${parts[0].padLeft(2, '0')}';
      try {
        final timingsTyped = timings.map(
          (k, v) => MapEntry(k.toString(), v),
        );
        out.add(PrayerTimesModel.fromJson(timingsTyped, iso, cityLabel));
      } catch (e) {
        debugPrint('AladhanService: calendar day parse skip ($iso): $e');
      }
    }
    return out;
  }
}
