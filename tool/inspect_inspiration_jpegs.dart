// tool/inspect_inspiration_jpegs.dart
// Keşfet görsellerinin boyut dağılımını hızlı özetler.

import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  final files = Directory('assets/inspiration')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final buckets = <String, int>{};
  for (final f in files) {
    try {
      final bytes = f.readAsBytesSync();
      final im = img.decodeJpg(bytes);
      if (im == null) continue;
      final key = '${im.width}x${im.height}';
      buckets[key] = (buckets[key] ?? 0) + 1;
    } catch (_) {}
  }

  final sorted = buckets.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  stdout.writeln('Çözünürlük dağılımı (ilk 10):');
  for (final e in sorted.take(10)) {
    stdout.writeln('  ${e.key}  ×${e.value}');
  }
  stdout.writeln('Toplam farklı çözünürlük : ${sorted.length}');
  stdout.writeln('Dosya sayısı             : ${files.length}');
}
