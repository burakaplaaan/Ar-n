// tool/optimize_widget_guide_pngs.dart
//
// Widget kurulum rehberi screenshot'larını yerinde küçültür.
//   - Genişlik > 1080 px ise 1080'e indirir (ekran rehberi için yeterli)
//   - PNG olarak yeniden kodlar (path/uzantı değişmez → kod dokunulmaz)
//   - Yeniden kodlama büyürse dosyaya dokunmaz
//
// Kullanım:
//   dart run tool/optimize_widget_guide_pngs.dart           # dry-run
//   dart run tool/optimize_widget_guide_pngs.dart --apply   # uygula
//
// Yedek: `--apply` öncesi `tool/_backups/widget_guide_pngs/`

import 'dart:io';

import 'package:image/image.dart' as img;

const _targetDir = 'assets/images/widget_guide';
const _backupDir = 'tool/_backups/widget_guide_pngs';
const _maxWidth = 1080;

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');
  final dir = Directory(_targetDir);
  if (!dir.existsSync()) {
    stderr.writeln('Hata: $_targetDir bulunamadı.');
    exit(2);
  }

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stdout.writeln('$_targetDir altında .png yok.');
    return;
  }

  if (apply) {
    Directory(_backupDir).createSync(recursive: true);
  }

  var totalOriginal = 0;
  var totalOptimized = 0;
  var optimizedCount = 0;
  var skippedCount = 0;
  var failedCount = 0;

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final original = file.lengthSync();
    totalOriginal += original;

    try {
      final bytes = file.readAsBytesSync();
      final image = img.decodePng(bytes);
      if (image == null) {
        stderr.writeln('  ✗ decode edilemedi: $name');
        failedCount++;
        totalOptimized += original;
        continue;
      }

      img.Image working = image;
      var resized = false;
      if (image.width > _maxWidth) {
        final newHeight =
            (image.height * (_maxWidth / image.width)).round();
        working = img.copyResize(
          image,
          width: _maxWidth,
          height: newHeight,
          interpolation: img.Interpolation.average,
        );
        resized = true;
      }

      // level 6: iyi sıkıştırma / makul süre dengesi (0–9).
      final encoded = img.encodePng(working, level: 6);

      if (encoded.length >= original) {
        stdout.writeln(
          '  ~ atla (zaten iyi): $name '
          '(${(original / 1024).toStringAsFixed(0)} KB, ${image.width}x${image.height})',
        );
        skippedCount++;
        totalOptimized += original;
        continue;
      }

      if (apply) {
        File('$_backupDir/$name').writeAsBytesSync(bytes);
        file.writeAsBytesSync(encoded, flush: true);
      }

      totalOptimized += encoded.length;
      optimizedCount++;
      final deltaPct =
          (100 * (original - encoded.length) / original).toStringAsFixed(0);
      stdout.writeln(
        '  ✓ ${resized ? "resize+" : ""}opt: $name '
        '${image.width}x${image.height} → ${working.width}x${working.height}  '
        '${(original / 1024).toStringAsFixed(0)} → '
        '${(encoded.length / 1024).toStringAsFixed(0)} KB '
        '(-$deltaPct%)',
      );
    } catch (e) {
      stderr.writeln('  ✗ hata: $name — $e');
      failedCount++;
      totalOptimized += original;
    }
  }

  final totalMb = (totalOriginal / 1024 / 1024).toStringAsFixed(1);
  final newMb = (totalOptimized / 1024 / 1024).toStringAsFixed(1);
  final savedMb =
      ((totalOriginal - totalOptimized) / 1024 / 1024).toStringAsFixed(1);
  final savedPct = totalOriginal == 0
      ? '0'
      : (100 * (totalOriginal - totalOptimized) / totalOriginal)
          .toStringAsFixed(0);

  stdout
    ..writeln('')
    ..writeln('── Özet ──')
    ..writeln('Dosya  : ${files.length} (optimize $optimizedCount, '
        'atlandı $skippedCount, başarısız $failedCount)')
    ..writeln('Boyut  : $totalMb MB → $newMb MB  (-$savedMb MB, %-$savedPct)')
    ..writeln(apply
        ? '\nOrijinaller $_backupDir altına yedeklendi.'
        : '\nDry-run. Uygulamak için: '
            'dart run tool/optimize_widget_guide_pngs.dart --apply');
}
