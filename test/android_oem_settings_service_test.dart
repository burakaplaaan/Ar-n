import 'package:arin/data/services/android_oem_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyAndroidOemFamily', () {
    test('xiaomi ailesini tanır', () {
      expect(
        classifyAndroidOemFamily(manufacturer: 'Xiaomi', brand: 'Redmi'),
        AndroidOemFamily.xiaomi,
      );
      expect(
        classifyAndroidOemFamily(manufacturer: 'POCO', brand: 'poco'),
        AndroidOemFamily.xiaomi,
      );
    });

    test('honor huawei\'den ayrıdır', () {
      expect(
        classifyAndroidOemFamily(manufacturer: 'HUAWEI', brand: 'honor'),
        AndroidOemFamily.honor,
      );
      expect(
        classifyAndroidOemFamily(manufacturer: 'HONOR', brand: 'honor'),
        AndroidOemFamily.honor,
      );
      expect(
        classifyAndroidOemFamily(manufacturer: 'HUAWEI', brand: 'HUAWEI'),
        AndroidOemFamily.huawei,
      );
    });

    test('oppo / vivo / samsung ailesini tanır', () {
      expect(
        classifyAndroidOemFamily(manufacturer: 'OPPO', brand: 'realme'),
        AndroidOemFamily.oppo,
      );
      expect(
        classifyAndroidOemFamily(manufacturer: 'vivo', brand: 'iQOO'),
        AndroidOemFamily.vivo,
      );
      expect(
        classifyAndroidOemFamily(manufacturer: 'samsung', brand: 'samsung'),
        AndroidOemFamily.samsung,
      );
    });

    test('bilinmeyen markayı other yapar', () {
      expect(
        classifyAndroidOemFamily(manufacturer: 'Google', brand: 'google'),
        AndroidOemFamily.other,
      );
    });
  });

  group('AndroidOemInfo', () {
    test('fromMap honor alanlarını okur', () {
      final info = AndroidOemInfo.fromMap({
        'manufacturer': 'HONOR',
        'brand': 'honor',
        'model': 'ANY',
        'family': 'honor',
        'displayName': 'Honor',
        'restricted': true,
        'batteryOptimizationsIgnored': false,
        'canOpenAutoStart': true,
        'canOpenOemBattery': true,
      });
      expect(info.family, AndroidOemFamily.honor);
      expect(info.displayName, 'Honor');
      expect(info.lockScreenSteps, isNotEmpty);
    });

    test('huawei adımları korunan uygulama uyarısı içerir', () {
      final info = AndroidOemInfo.fromMap({
        'manufacturer': 'HUAWEI',
        'brand': 'HUAWEI',
        'model': 'ANY',
        'family': 'huawei',
        'displayName': 'Huawei',
        'restricted': true,
        'batteryOptimizationsIgnored': true,
        'canOpenAutoStart': true,
        'canOpenOemBattery': false,
      });
      expect(
        info.lockScreenSteps.any((s) => s.toLowerCase().contains('korunan')),
        isTrue,
      );
      expect(info.autoStartChipLabel, 'Uygulama başlatma');
      expect(info.batteryChipLabel, 'Korunan uygulamalar');
    });

    test('samsung ve xiaomi chip etiketleri ayrıdır', () {
      final samsung = AndroidOemInfo.fromMap({
        'manufacturer': 'samsung',
        'brand': 'samsung',
        'model': 'A',
        'family': 'samsung',
        'displayName': 'Samsung',
        'restricted': true,
        'batteryOptimizationsIgnored': true,
        'canOpenAutoStart': false,
        'canOpenOemBattery': true,
      });
      expect(samsung.batteryChipLabel, 'Pil / uyku');

      final xiaomi = AndroidOemInfo.fromMap({
        'manufacturer': 'Xiaomi',
        'brand': 'Redmi',
        'model': 'A',
        'family': 'xiaomi',
        'displayName': 'Redmi',
        'restricted': true,
        'batteryOptimizationsIgnored': false,
        'canOpenAutoStart': true,
        'canOpenOemBattery': true,
      });
      expect(xiaomi.autoStartChipLabel, 'Otomatik başlat');
      expect(xiaomi.lockScreenSteps.first, contains('Redmi'));
    });
  });

  group('AndroidOemOpenResult', () {
    test('raw değerleri ayrıştırır', () {
      expect(AndroidOemOpenResult.fromRaw('oem'), AndroidOemOpenResult.oem);
      expect(
        AndroidOemOpenResult.fromRaw('fallback'),
        AndroidOemOpenResult.fallback,
      );
      expect(
        AndroidOemOpenResult.fromRaw('failed'),
        AndroidOemOpenResult.failed,
      );
      expect(AndroidOemOpenResult.fromRaw(true).opened, isTrue);
      expect(AndroidOemOpenResult.fromRaw(false).opened, isFalse);
    });
  });
}
