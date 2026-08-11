// Xiaomi / Huawei / Honor / Oppo / Vivo / Samsung OEM tespiti + ayar deep-link.
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AndroidOemFamily {
  xiaomi,
  huawei,
  honor,
  oppo,
  vivo,
  samsung,
  other;

  static AndroidOemFamily fromId(String? id) {
    switch (id) {
      case 'xiaomi':
        return AndroidOemFamily.xiaomi;
      case 'huawei':
        return AndroidOemFamily.huawei;
      case 'honor':
        return AndroidOemFamily.honor;
      case 'oppo':
        return AndroidOemFamily.oppo;
      case 'vivo':
        return AndroidOemFamily.vivo;
      case 'samsung':
        return AndroidOemFamily.samsung;
      default:
        return AndroidOemFamily.other;
    }
  }
}

enum AndroidOemOpenResult {
  oem,
  fallback,
  failed;

  static AndroidOemOpenResult fromRaw(Object? raw) {
    if (raw == true) return AndroidOemOpenResult.fallback;
    if (raw == false || raw == null) return AndroidOemOpenResult.failed;
    switch ('$raw') {
      case 'oem':
        return AndroidOemOpenResult.oem;
      case 'fallback':
        return AndroidOemOpenResult.fallback;
      default:
        return AndroidOemOpenResult.failed;
    }
  }

  bool get opened => this != AndroidOemOpenResult.failed;
}

@immutable
class AndroidOemInfo {
  const AndroidOemInfo({
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.family,
    required this.displayName,
    required this.restricted,
    required this.batteryOptimizationsIgnored,
    required this.canOpenAutoStart,
    required this.canOpenOemBattery,
  });

  final String manufacturer;
  final String brand;
  final String model;
  final AndroidOemFamily family;
  final String displayName;
  final bool restricted;
  final bool batteryOptimizationsIgnored;
  final bool canOpenAutoStart;
  final bool canOpenOemBattery;

  /// Markaya özel kısa adımlar (kurulum + Widget Merkezi).
  List<String> get lockScreenSteps {
    final name = displayName;
    switch (family) {
      case AndroidOemFamily.xiaomi:
        return [
          'Güvenlik / Uygulama yönetimi → Otomatik başlat → $name için Arın\'ı aç.',
          'Pil tasarrufu → Arın → "Kısıtlama yok" (veya kısıtlanmasın).',
          'Bildirimlerde kilit ekranı gösterimini aç.',
        ];
      case AndroidOemFamily.huawei:
        return [
          'Uygulama başlatma → Arın → Elle yönet (otomatik + ikincil + arka plan).',
          'Pil → Korunan uygulamalar → Arın\'ı ekle.',
          'Bildirimler → kilit ekranında göster.',
        ];
      case AndroidOemFamily.honor:
        return [
          'Uygulama başlatma / otomatik çalıştır → Arın\'ı elle yönet.',
          'Pil veya korunan uygulamalara Arın\'ı ekle.',
          'Bildirimlerin kilit ekranında görünmesine izin ver.',
        ];
      case AndroidOemFamily.oppo:
        final startup = name == 'OnePlus'
            ? 'Uygulama otomatik başlatma'
            : 'Başlangıç yöneticisi';
        return [
          '$startup → Arın\'a izin ver.',
          'Pil → Arın → arka planı kısıtlama / optimize etme.',
          'Kilit ekranı bildirimlerini aç.',
        ];
      case AndroidOemFamily.vivo:
        return [
          'Yüksek arka plan güç tüketimi / otomatik başlat → Arın\'ı aç.',
          'Beyaz listeye Arın\'ı ekle.',
          'Kilit ekranı bildirimlerine izin ver.',
        ];
      case AndroidOemFamily.samsung:
        return const [
          'Pil → Arın → "Uyku moduna alma"yı kapat.',
          'Kullanılmayan uygulamaları uyut listesinden Arın\'ı çıkar.',
          'Bildirimler → kilit ekranında göster.',
        ];
      case AndroidOemFamily.other:
        return const [
          'Pil optimizasyonundan Arın\'ı muaf tut.',
          'Bildirim izninin ve kilit ekranı gösteriminin açık olduğundan emin ol.',
        ];
    }
  }

  String get autoStartChipLabel {
    switch (family) {
      case AndroidOemFamily.xiaomi:
        return 'Otomatik başlat';
      case AndroidOemFamily.huawei:
      case AndroidOemFamily.honor:
        return 'Uygulama başlatma';
      case AndroidOemFamily.oppo:
        return displayName == 'OnePlus' ? 'Otomatik başlat' : 'Başlangıç';
      case AndroidOemFamily.vivo:
        return 'Arka plan / başlat';
      case AndroidOemFamily.samsung:
      case AndroidOemFamily.other:
        return 'Otomatik başlat';
    }
  }

  String get batteryChipLabel {
    switch (family) {
      case AndroidOemFamily.samsung:
        return 'Pil / uyku';
      case AndroidOemFamily.xiaomi:
        return 'Pil kısıtı yok';
      case AndroidOemFamily.huawei:
      case AndroidOemFamily.honor:
        return 'Korunan uygulamalar';
      case AndroidOemFamily.oppo:
      case AndroidOemFamily.vivo:
        return 'Pil ayarı';
      case AndroidOemFamily.other:
        return 'Pil ayarı';
    }
  }

  factory AndroidOemInfo.fromMap(Map<Object?, Object?> map) {
    return AndroidOemInfo(
      manufacturer: (map['manufacturer'] as String?) ?? '',
      brand: (map['brand'] as String?) ?? '',
      model: (map['model'] as String?) ?? '',
      family: AndroidOemFamily.fromId(map['family'] as String?),
      displayName: (map['displayName'] as String?) ?? 'Android',
      restricted: map['restricted'] == true,
      batteryOptimizationsIgnored:
          map['batteryOptimizationsIgnored'] == true,
      canOpenAutoStart: map['canOpenAutoStart'] == true,
      canOpenOemBattery: map['canOpenOemBattery'] == true,
    );
  }
}

AndroidOemFamily classifyAndroidOemFamily({
  required String manufacturer,
  required String brand,
}) {
  final blob = '${manufacturer.toLowerCase()} ${brand.toLowerCase()}';
  if (blob.contains('honor')) return AndroidOemFamily.honor;
  if (blob.contains('xiaomi') ||
      blob.contains('redmi') ||
      blob.contains('poco') ||
      blob.contains('blackshark')) {
    return AndroidOemFamily.xiaomi;
  }
  if (blob.contains('huawei') || blob.contains('harmony')) {
    return AndroidOemFamily.huawei;
  }
  if (blob.contains('oppo') ||
      blob.contains('realme') ||
      blob.contains('oneplus') ||
      blob.contains('coloros')) {
    return AndroidOemFamily.oppo;
  }
  if (blob.contains('vivo') || blob.contains('iqoo')) {
    return AndroidOemFamily.vivo;
  }
  if (blob.contains('samsung')) return AndroidOemFamily.samsung;
  return AndroidOemFamily.other;
}

abstract final class AndroidOemSettingsService {
  static const _channel = MethodChannel('com.arin.arin/oem_settings');

  static Future<AndroidOemInfo?> getInfo() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>('getInfo');
      if (raw == null) return null;
      return AndroidOemInfo.fromMap(raw);
    } catch (e) {
      debugPrint('AndroidOemSettingsService.getInfo: $e');
      return null;
    }
  }

  static Future<AndroidOemOpenResult> openAutoStart() async {
    if (kIsWeb || !Platform.isAndroid) return AndroidOemOpenResult.failed;
    try {
      final raw = await _channel.invokeMethod<Object>('openAutoStart');
      return AndroidOemOpenResult.fromRaw(raw);
    } catch (e) {
      debugPrint('AndroidOemSettingsService.openAutoStart: $e');
      return AndroidOemOpenResult.failed;
    }
  }

  static Future<AndroidOemOpenResult> openOemBattery() async {
    if (kIsWeb || !Platform.isAndroid) return AndroidOemOpenResult.failed;
    try {
      final raw = await _channel.invokeMethod<Object>('openOemBattery');
      return AndroidOemOpenResult.fromRaw(raw);
    } catch (e) {
      debugPrint('AndroidOemSettingsService.openOemBattery: $e');
      return AndroidOemOpenResult.failed;
    }
  }

  static Future<bool> openAppDetails() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openAppDetails') ?? false;
    } catch (e) {
      debugPrint('AndroidOemSettingsService.openAppDetails: $e');
      return false;
    }
  }

  static Future<bool> openRequestIgnoreBattery() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openRequestIgnoreBattery') ??
          false;
    } catch (e) {
      debugPrint('AndroidOemSettingsService.openRequestIgnoreBattery: $e');
      return false;
    }
  }
}
