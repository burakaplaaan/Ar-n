import 'dart:async';

import 'package:arin/data/models/prayer_times_model.dart';
import 'package:arin/data/services/aladhan_service.dart';
import 'package:arin/data/services/diyanet_prayer_service.dart';
import 'package:arin/data/services/location_service.dart';
import 'package:arin/data/services/prayer_service_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

const _today = PrayerTimesModel(
  imsak: '05:00',
  fajr: '05:00',
  sunrise: '06:25',
  dhuhr: '13:00',
  asr: '16:30',
  maghrib: '19:20',
  isha: '20:40',
  date: '2026-10-03',
  city: 'Kocaeli',
);

class _FakeLocationService extends LocationService {
  String city = '';
  String country = '';
  int? districtId;
  double? lat;
  double? lon;
  bool manual = false;
  int syncCalls = 0;
  Future<void> Function()? syncHandler;

  @override
  String get savedCity => city;

  @override
  String get savedCountry => country;

  @override
  int? get savedDistrictId => districtId;

  @override
  double? get savedLat => lat;

  @override
  double? get savedLon => lon;

  @override
  bool get isManualPrayerLocation => manual;

  @override
  Future<void> syncPrayerLocation({
    bool forceRefresh = false,
    bool promptIfNeeded = false,
    bool overwriteManual = false,
  }) async {
    syncCalls += 1;
    await syncHandler?.call();
  }
}

class _FakeDiyanetService extends DiyanetPrayerService {
  PrayerTimesModel? cached;
  PrayerTimesModel? fetched;
  int fetchCalls = 0;

  @override
  PrayerTimesModel? tryLoadTodayCached({
    required int ilceId,
    required String cityLabel,
  }) {
    return cached;
  }

  @override
  Future<PrayerTimesModel?> fetchToday({
    required int ilceId,
    required String cityLabel,
  }) async {
    fetchCalls += 1;
    return fetched;
  }
}

class _FakeAladhanService extends AladhanService {
  @override
  PrayerTimesModel? tryLoadTodayCached({
    required String city,
    required String country,
    double? lat,
    double? lon,
  }) {
    return null;
  }
}

void main() {
  test('disk cache GPS tamamlanmasını beklemeden döner', () async {
    final location = _FakeLocationService()
      ..city = 'Kocaeli'
      ..country = 'Turkey'
      ..districtId = 9654;
    final syncGate = Completer<void>();
    location.syncHandler = () => syncGate.future;
    final diyanet = _FakeDiyanetService()..cached = _today;
    final resolver = PrayerServiceResolver(
      diyanet: diyanet,
      aladhan: _FakeAladhanService(),
      location: location,
    );

    final result = await resolver.fetchToday().timeout(
      const Duration(milliseconds: 200),
    );

    expect(result.model, same(_today));
    expect(result.source, PrayerSource.cacheOnly);
    expect(location.syncCalls, 1);
    expect(diyanet.fetchCalls, 0);
    syncGate.complete();
  });

  test('ilk kurulumda konum sync tamamlanmadan ağ fetch başlamaz', () async {
    final location = _FakeLocationService();
    final diyanet = _FakeDiyanetService()..fetched = _today;
    location.syncHandler = () async {
      location
        ..city = 'Kocaeli'
        ..country = 'Turkey'
        ..districtId = 9654;
    };
    final resolver = PrayerServiceResolver(
      diyanet: diyanet,
      aladhan: _FakeAladhanService(),
      location: location,
    );

    final result = await resolver.fetchToday();

    expect(result.model, same(_today));
    expect(result.source, PrayerSource.diyanet);
    expect(location.syncCalls, 1);
    expect(diyanet.fetchCalls, 1);
  });
}
