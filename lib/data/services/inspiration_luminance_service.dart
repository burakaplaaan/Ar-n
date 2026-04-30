import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

/// Görselden Reels metin rengi + dikey konum önerisi (düşük varyans = daha düz zemin).
class InspirationLuminanceService {
  InspirationLuminanceService._();

  static final Map<String, bool> _lightTextCache = {};
  static final Map<String, Alignment> _anchorCache = {};
  static final Map<String, ({bool lightText, Alignment textAnchor})> _fullCache = {};

  /// true: merkez koyu → üstte **açık renk** yazı kullan.
  static Future<bool> recommendLightColoredText(String assetPath) async {
    final r = await analyzeForReels(assetPath);
    return r.lightText;
  }

  /// Tek decode ile parlaklık + en “düz” yatay şeride hizalama.
  static Future<({bool lightText, Alignment textAnchor})> analyzeForReels(
    String assetPath,
  ) async {
    final hit = _fullCache[assetPath];
    if (hit != null) return hit;

    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final image = img.decodeImage(bytes);
      if (image == null) {
        const r = (lightText: true, textAnchor: Alignment.center);
        _fullCache[assetPath] = r;
        _lightTextCache[assetPath] = true;
        _anchorCache[assetPath] = Alignment.center;
        return r;
      }

      final w = image.width;
      final h = image.height;
      if (w < 8 || h < 8) {
        const r = (lightText: true, textAnchor: Alignment.center);
        _fullCache[assetPath] = r;
        return r;
      }

      final luma = _centerRegionLumaFromImage(image);
      final darkCenter = luma < 0.48;
      final anchor = _lowestVarianceBandAlignment(image);

      final r = (lightText: darkCenter, textAnchor: anchor);
      _fullCache[assetPath] = r;
      _lightTextCache[assetPath] = darkCenter;
      _anchorCache[assetPath] = anchor;
      return r;
    } catch (_) {
      const r = (lightText: true, textAnchor: Alignment.center);
      _fullCache[assetPath] = r;
      return r;
    }
  }

  static double _centerRegionLumaFromImage(img.Image image) {
    final w = image.width;
    final h = image.height;
    final cw = (w * 0.32).clamp(4, w).toInt();
    final ch = (h * 0.32).clamp(4, h).toInt();
    final cx = ((w - cw) / 2).floor();
    final cy = ((h - ch) / 2).floor();

    var sum = 0.0;
    var n = 0;
    for (var y = cy; y < cy + ch && y < h; y++) {
      for (var x = cx; x < cx + cw && x < w; x++) {
        final p = image.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();
        sum += (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
        n++;
      }
    }
    if (n == 0) return 0.5;
    return sum / n;
  }

  /// Yatay şeritlerde luma varyansı; en düşük varyanslı şeride metni yaklaştır.
  static Alignment _lowestVarianceBandAlignment(img.Image image) {
    final w = image.width;
    final h = image.height;
    final x0 = (w * 0.2).toInt().clamp(0, w - 1);
    final x1 = (w * 0.8).toInt().clamp(x0 + 1, w);

    const bandCount = 5;
    var bestVar = double.infinity;
    var bestBand = 2;

    for (var b = 0; b < bandCount; b++) {
      final y0 = ((b * h) / bandCount).floor();
      final y1 = (((b + 1) * h) / bandCount).ceil().clamp(y0 + 1, h);
      final v = _regionLumaVariance(image, x0, y0, x1, y1);
      if (v < bestVar) {
        bestVar = v;
        bestBand = b;
      }
    }

    final t = (bestBand + 0.5) / bandCount;
    final ay = ((t - 0.5) * 2.0 * 0.55).clamp(-0.58, 0.58);
    return Alignment(0, ay);
  }

  static double _regionLumaVariance(
    img.Image image,
    int x0,
    int y0,
    int x1,
    int y1,
  ) {
    final lumas = <double>[];
    final stepY = ((y1 - y0) / 28).ceil().clamp(1, 10);
    final stepX = ((x1 - x0) / 20).ceil().clamp(1, 10);
    for (var y = y0; y < y1; y += stepY) {
      for (var x = x0; x < x1; x += stepX) {
        final p = image.getPixel(x, y);
        final l =
            (0.299 * p.r + 0.587 * p.g + 0.114 * p.b) / 255.0;
        lumas.add(l);
      }
    }
    if (lumas.length < 4) return 999;
    final mean = lumas.reduce((a, b) => a + b) / lumas.length;
    var s = 0.0;
    for (final l in lumas) {
      final d = l - mean;
      s += d * d;
    }
    return s / lumas.length;
  }
}
