import 'dart:io';

import 'package:arin/core/utils/hive_boxes.dart';
import 'package:arin/data/services/diyanet_district_matcher.dart';
import 'package:arin/data/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('elle seçilen konum GPS ile sessizce ezilmez', () {
    expect(
      shouldHoldManualPrayerLocation(
        isManual: true,
        overwriteManual: false,
      ),
      isTrue,
    );
    expect(
      shouldHoldManualPrayerLocation(
        isManual: true,
        overwriteManual: true,
      ),
      isFalse,
    );
    expect(
      shouldHoldManualPrayerLocation(
        isManual: false,
        overwriteManual: false,
      ),
      isFalse,
    );
  });

  test('elle seçimde Aladhan şehir adını kullanır', () {
    expect(
      shouldUseAladhanCityName(isManual: true, city: 'Ankara'),
      isTrue,
    );
    expect(
      shouldUseAladhanCityName(isManual: true, city: '  '),
      isFalse,
    );
    expect(
      shouldUseAladhanCityName(isManual: false, city: 'Ankara'),
      isFalse,
    );
  });

  group('Hive manuel konum', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('arin_manual_loc_');
      Hive.init(tempDir.path);
      await Hive.openBox<dynamic>(HiveBoxes.preferences);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('saveManualDistrict bayrağı koyar, GPS apply ezmez', () async {
      final loc = LocationService();
      final box = Hive.box<dynamic>(HiveBoxes.preferences);
      await loc.saveCity('Kocaeli', 'Turkey');
      await loc.saveDistrictId(9654);
      await box.put('user_lat', 40.76);
      await box.put('user_lon', 29.94);

      const ankara = DiyanetDistrict(
        id: 9206,
        ilce: 'ANKARA',
        ilId: 506,
        il: 'ANKARA',
      );
      await loc.saveManualDistrict(ankara);

      expect(loc.isManualPrayerLocation, isTrue);
      expect(loc.savedCity, 'ANKARA');
      expect(loc.savedDistrictId, 9206);
      expect(loc.savedLat, isNull);
      expect(loc.savedLon, isNull);

      await loc.syncPrayerLocation();
      expect(loc.savedCity, 'ANKARA');
      expect(loc.savedDistrictId, 9206);
      expect(loc.isManualPrayerLocation, isTrue);

      await loc.applyLocationChange(
        const LocationChangeResult(
          newCity: 'Kocaeli',
          newCountry: 'Turkey',
          newDistrictId: 9654,
          lat: 40.76,
          lon: 29.94,
        ),
      );
      expect(loc.savedCity, 'ANKARA');
      expect(loc.savedDistrictId, 9206);
      expect(loc.isManualPrayerLocation, isTrue);
      expect(loc.savedLat, isNull);

      await loc.applyLocationChange(
        const LocationChangeResult(
          newCity: 'Kocaeli',
          newCountry: 'Turkey',
          newDistrictId: 9654,
          lat: 40.76,
          lon: 29.94,
        ),
        overwriteManual: true,
      );
      expect(loc.savedCity, 'Kocaeli');
      expect(loc.savedDistrictId, 9654);
      expect(loc.isManualPrayerLocation, isFalse);
      expect(loc.savedLat, 40.76);
    });
  });
}
