import 'package:flutter/services.dart';

import '../../core/constants/inspiration_assets.dart';

/// Keşfet görselleri: `assets/inspiration/1.jpg`, `2.jpg`, …
class InspirationAssetDiscovery {
  InspirationAssetDiscovery._();

  static const _maxProbe = 4096;

  static final RegExp _indexedJpeg = RegExp(
    r'^assets/inspiration/(\d+)\.jpg$',
  );

  /// Derleme manifestinden tüm `N.jpg` indekslerini toplar (boşluk toleranslı).
  /// Manifest okunamazsa 1’den başlayarak aralıksız yüklemeyi dener (ilk eksikte durur).
  static Future<List<int>> discoverConsecutiveJpeg() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final indices = <int>[];
      for (final key in manifest.listAssets()) {
        final m = _indexedJpeg.firstMatch(key);
        if (m != null) {
          indices.add(int.parse(m.group(1)!));
        }
      }
      indices.sort();
      if (indices.isNotEmpty) return indices;
    } catch (_) {
      // Aşağıdaki yedek keşfe düş.
    }
    return _discoverBySequentialProbe();
  }

  static Future<List<int>> _discoverBySequentialProbe() async {
    final out = <int>[];
    for (var i = 1; i <= _maxProbe; i++) {
      final path = InspirationAssets.pathForIndex(i);
      try {
        await rootBundle.load(path);
        out.add(i);
      } catch (_) {
        break;
      }
    }
    return out;
  }
}
