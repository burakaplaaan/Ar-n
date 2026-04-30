// tool/optimize_inspiration_jpegs.dart
//
// ARIN — Keşfet görsellerini (assets/inspiration/*.jpg) yerinde optimize eder.
// Boyut ve kaliteyi saf Dart `image` paketiyle yeniden kodlar:
//   - JPG quality 82 (görsel fark hissedilmez, dosya %20-40 küçülür)
//   - Genişlik > 1440 px ise 1440'a indirir (Reels görselleri için yeterli)
//   - Orijinal daha küçükse atlar (zaten optimize)
//
// Kullanım:
//   dart run tool/optimize_inspiration_jpegs.dart           # dry-run (yazmaz)
//   dart run tool/optimize_inspiration_jpegs.dart --apply   # uygula
//
// Yedek: `--apply` öncesi orijinal dosyalar `tool/_backups/inspiration_jpegs/`
// altına kopyalanır. APK'ya bulaşmaz (.gitignore `tool/_backups/` hariç tutar).
//
// NOT: Dart `image` paketi libjpeg-turbo kadar optimal sıkıştırmaz; ffmpeg/
// mozjpeg ~%10 daha iyi yapar. Ama ffmpeg bağımlılığı olmadan ~%25 kazanç
// APK'nın indirme boyutunu hissedilir düşürür.

import 'dart:io';

import 'package:image/image.dart' as img;

const _targetDir = 'assets/inspiration';
const _backupDir = 'tool/_backups/inspiration_jpegs';
const _targetQuality = 82;
const _maxWidth = 1440;

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
      .where((f) => f.path.toLowerCase().endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stdout.writeln('assets/inspiration altında .jpg yok.');
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
      final image = img.decodeJpg(bytes);
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

      final encoded = img.encodeJpg(working, quality: _targetQuality);

      if (encoded.length >= original) {
        // Yeniden kodlama daha büyük olduysa (zaten optimize), dokunma.
        stdout.writeln(
          '  ~ atla (zaten iyi): $name '
          '(${(original / 1024).toStringAsFixed(0)} KB)',
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
        : '\nDry-run. Uygulamak için: dart run $_targetFileFromArgs --apply');
}

const String _targetFileFromArgs = 'tool/optimize_inspiration_jpegs.dart';
