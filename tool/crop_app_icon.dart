// Ortalanmış kare kırpma + 1024 master ikon (flutter_launcher_icons için).
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:image/image.dart' as img;

/// Logoya yakınlaşmak için [min(w,h)] üzerinden oran (0.45–0.65 arası iyi).
const double _tightness = 0.56;

/// Logoyu ikon kutusunda biraz aşağı almak için kırpımı yukarı kaydırır
/// (pozitif: üstten biraz daha fazla alan, logo görsel olarak aşağı iner).
const double _shiftLogoDownFractionOfH = 0.07;

void main() {
  const srcPath = 'assets/branding/app_icon_source.png';
  const outPath = 'assets/branding/app_icon_1024.png';

  final bytes = File(srcPath).readAsBytesSync();
  final source = img.decodeImage(bytes);
  if (source == null) {
    stderr.writeln('decode failed: $srcPath');
    exit(1);
  }

  final w = source.width;
  final h = source.height;
  final m = w < h ? w : h;
  final side = (m * _tightness).round();
  final left = ((w - side) / 2).round();
  final centerTop = ((h - side) / 2).round();
  final top = (centerTop - (h * _shiftLogoDownFractionOfH).round())
      .clamp(0, h - side);

  final cropped = img.copyCrop(
    source,
    x: left,
    y: top,
    width: side,
    height: side,
  );

  final master = img.copyResize(
    cropped,
    width: 1024,
    height: 1024,
    interpolation: img.Interpolation.cubic,
  );

  File(outPath).writeAsBytesSync(img.encodePng(master));
  print('Wrote $outPath (${master.width}x${master.height}) from ${w}x$h crop $side');
}
