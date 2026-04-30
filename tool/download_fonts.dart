// tool/download_fonts.dart
//
// ARIN — Plus Jakarta Sans + Scheherazade New fontlarını assets/fonts/
// altına indirir. Amaç: uygulamayı runtime'da Google Fonts CDN'ine bağımlı
// olmaktan kurtarmak. Bundled fontlarla:
//   - İlk açılış daha hızlı
//   - Offline kullanıcı da fontu görür
//   - Güncel OFL (SIL Open Font License) lisansıyla yasal
//
// Kullanım:
//   dart run tool/download_fonts.dart
//
// Tek seferlik çalıştır; indirilen .ttf dosyaları git'e commit edilir
// (pubspec.yaml'da `flutter.fonts` altında tanımlılar, APK'ya gömülür).
//
// Kaynak: Google'ın resmi google/fonts GitHub repo'su — direct raw TTF.
// Aynı dosyalar pub.dev/google_fonts paketinin runtime fetch'inde de
// kullanılır; sadece biz onları derleme zamanında alıyoruz.

import 'dart:io';

const _targetDir = 'assets/fonts';

const _fonts = <String, String>{
  // Plus Jakarta Sans — variable font (tüm weight'ler tek dosya).
  'PlusJakartaSans-Variable.ttf':
      'https://github.com/google/fonts/raw/main/ofl/plusjakartasans/PlusJakartaSans%5Bwght%5D.ttf',
  'PlusJakartaSans-Italic-Variable.ttf':
      'https://github.com/google/fonts/raw/main/ofl/plusjakartasans/PlusJakartaSans-Italic%5Bwght%5D.ttf',
  // Scheherazade New (Arapça kaligrafi) — ayrı weight dosyaları
  // (variable versiyonu yok; 4 weight yeterli).
  'ScheherazadeNew-Regular.ttf':
      'https://github.com/google/fonts/raw/main/ofl/scheherazadenew/ScheherazadeNew-Regular.ttf',
  'ScheherazadeNew-Medium.ttf':
      'https://github.com/google/fonts/raw/main/ofl/scheherazadenew/ScheherazadeNew-Medium.ttf',
  'ScheherazadeNew-SemiBold.ttf':
      'https://github.com/google/fonts/raw/main/ofl/scheherazadenew/ScheherazadeNew-SemiBold.ttf',
  'ScheherazadeNew-Bold.ttf':
      'https://github.com/google/fonts/raw/main/ofl/scheherazadenew/ScheherazadeNew-Bold.ttf',
};

Future<void> main() async {
  final dir = Directory(_targetDir);
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }

  final http = HttpClient()
    ..userAgent = 'arin-font-downloader/1.0 (+flutter dev)'
    ..connectionTimeout = const Duration(seconds: 15);

  var ok = 0;
  var fail = 0;

  try {
    for (final entry in _fonts.entries) {
      final fileName = entry.key;
      final url = entry.value;
      final outFile = File('$_targetDir/$fileName');

      // Zaten varsa ve >50KB ise atla — tekrar indirme.
      if (outFile.existsSync() && outFile.lengthSync() > 50 * 1024) {
        stdout.writeln(
          '✓ (atlandı, mevcut) $fileName — ${outFile.lengthSync() ~/ 1024} KB',
        );
        ok++;
        continue;
      }

      stdout.writeln('→ indiriliyor: $fileName');
      try {
        final bytes = await _fetchFollowingRedirects(http, Uri.parse(url));
        await outFile.writeAsBytes(bytes, flush: true);
        stdout.writeln('  ✓ ${outFile.path} (${bytes.length ~/ 1024} KB)');
        ok++;
      } catch (e) {
        stderr.writeln('  ✗ hata: $fileName — $e');
        fail++;
      }
    }
  } finally {
    http.close(force: true);
  }

  stdout.writeln('\n── Özet ──');
  stdout.writeln('indirilen/hazır : $ok');
  stdout.writeln('başarısız       : $fail');
  stdout.writeln('\nSonraki adımlar:');
  stdout.writeln('  1) flutter pub get');
  stdout.writeln('  2) flutter run / flutter build  (fontlar otomatik bundle)');

  if (fail > 0) {
    exit(1);
  }
}

/// 302/301 yönlendirmelerini elle takip ederek ikili (binary) indirme yapar.
/// `HttpClient` default'ta yalnızca 5 redirect'e izin veriyor ve bazı
/// GitHub → objects.githubusercontent.com zincirlerinde `followRedirects`
/// başarısız olabiliyor; güvenli-defansif kendimiz yürütüyoruz.
Future<List<int>> _fetchFollowingRedirects(
  HttpClient client,
  Uri url, {
  int maxRedirects = 8,
}) async {
  var current = url;
  for (var i = 0; i <= maxRedirects; i++) {
    final req = await client.getUrl(current);
    req.followRedirects = false;
    req.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream,*/*');
    final resp = await req.close();
    final status = resp.statusCode;
    if (status == 200) {
      final chunks = <List<int>>[];
      await for (final chunk in resp) {
        chunks.add(chunk);
      }
      return chunks.expand((c) => c).toList(growable: false);
    }
    if (status == 301 || status == 302 || status == 303 || status == 307 || status == 308) {
      final loc = resp.headers.value('location');
      if (loc == null) {
        throw HttpException('redirect $status but no Location header');
      }
      current = Uri.parse(loc).isAbsolute
          ? Uri.parse(loc)
          : current.resolve(loc);
      await resp.drain<void>();
      continue;
    }
    await resp.drain<void>();
    throw HttpException('HTTP $status for $current');
  }
  throw HttpException('too many redirects ($maxRedirects) for $url');
}
