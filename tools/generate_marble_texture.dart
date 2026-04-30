// Prosedürel mermer doku — assets/images/zikir/marble_bead_texture.png üretir.
// Çalıştır: dart run tools/generate_marble_texture.dart

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const w = 256;
  const h = 256;
  final image = img.Image(width: w, height: h);
  final rnd = math.Random(42);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var v = 248.0 +
          math.sin(x * 0.045 + y * 0.032) * 7 +
          rnd.nextDouble() * 3;
      final vein =
          math.sin(x * 0.14 + y * 0.21) * math.cos(x * 0.09 - y * 0.12);
      if (vein.abs() > 0.78) {
        v -= 42 * vein.abs();
      }
      v = v.clamp(210.0, 255.0);
      final c = v.round();
      final g = (c - 3).clamp(0, 255);
      final b = (c - 5).clamp(0, 255);
      image.setPixelRgb(x, y, c, g, b);
    }
  }

  final dir = Directory('assets/images/zikir');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final out = File('assets/images/zikir/marble_bead_texture.png');
  out.writeAsBytesSync(img.encodePng(image));
  // ignore: avoid_print
  print('Wrote ${out.path}');
}
