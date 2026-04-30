// tool/generate_diyanet_districts.dart
//
// Diyanet namaz vakitleri — ezanvakti.emushaf.net mirror'ından Türkiye
// ülke/il/ilçe taksonomisini çekip `assets/diyanet_tr_districts.json`
// olarak üretir. Asset build zamanı statiktir; bu betik yalnız geliştirici
// makinesinde, yılda bir kez çalıştırılır:
//
//   dart run tool/generate_diyanet_districts.dart
//
// Çıkış şeması:
//   [
//     { "id": 9651, "ilce": "GEBZE", "ilId": 551, "il": "KOCAELI" },
//     ...
//   ]
//
// NOTLAR:
//  - ezanvakti servisi Cloudflare arkasında; rate-limit (hata 1015) yenir,
//    bu yüzden her istekten sonra 600 ms bekler + 429/1015 yakalarsa
//    artan backoff ile tekrar dener.
//  - Türkiye'nin resmi 970+ ilçesinin yalnızca ~870'i Diyanet sisteminde
//    ayrı vakit kaydı olarak tutulur (yakın ilçeler merkez ilçeye
//    birleştirilmiştir). Matcher runtime'da "il merkezi fallback" ile
//    eksik ilçeleri doğru vakte yönlendirir.
//  - User-Agent header olmadan Cloudflare'ın bot-filter'ı bazı IP'leri
//    keser; üretim makinesinde manuel çalıştıracağınız için browser
//    benzeri UA gönderiyoruz.

import 'dart:convert';
import 'dart:io';

const _base = 'https://ezanvakti.emushaf.net';
const _ulkeIdTurkiye = '2';
const _assetPath = 'assets/diyanet_tr_districts.json';
const _retryMax = 5;
const _requestSpacingMs = 600;

Future<void> main() async {
  final http = HttpClient()..userAgent = 'Arin-DiyanetAssetBuilder/1.0';

  stdout.writeln('== ezanvakti → assets/diyanet_tr_districts.json ==');
  final sehirler = await _getJsonArray(http, '$_base/sehirler/$_ulkeIdTurkiye');
  stdout.writeln('İl sayısı: ${sehirler.length}');

  final out = <Map<String, Object>>[];

  for (var i = 0; i < sehirler.length; i++) {
    final s = sehirler[i] as Map<String, dynamic>;
    final sehirId = s['SehirID'] as String;
    final sehirAdi = s['SehirAdi'] as String;

    final ilceler = await _getJsonArrayRetry(http, '$_base/ilceler/$sehirId');
    for (final raw in ilceler) {
      final il = raw as Map<String, dynamic>;
      out.add({
        'id': int.parse(il['IlceID'] as String),
        'ilce': il['IlceAdi'] as String,
        'ilId': int.parse(sehirId),
        'il': sehirAdi,
      });
    }
    stdout.writeln(
      '  [${i + 1}/${sehirler.length}] $sehirAdi '
      '+${ilceler.length} (toplam ${out.length})',
    );

    await Future<void>.delayed(
      const Duration(milliseconds: _requestSpacingMs),
    );
  }

  http.close(force: true);

  final file = File(_assetPath);
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(out), flush: true);

  stdout.writeln('');
  stdout.writeln('✓ ${out.length} kayıt yazıldı → $_assetPath');
  stdout.writeln('✓ Boyut: ${(file.lengthSync() / 1024).toStringAsFixed(1)} KB');
}

Future<List<dynamic>> _getJsonArray(HttpClient http, String url) async {
  final req = await http.getUrl(Uri.parse(url));
  req.headers.set('Accept', 'application/json');
  final resp = await req.close();
  if (resp.statusCode != 200) {
    throw HttpException('GET $url → ${resp.statusCode}');
  }
  final body = await resp.transform(utf8.decoder).join();
  return jsonDecode(body) as List<dynamic>;
}

/// Rate-limit (1015/429) yediğinde artan backoff ile tekrar dener.
Future<List<dynamic>> _getJsonArrayRetry(HttpClient http, String url) async {
  Object? lastErr;
  for (var attempt = 1; attempt <= _retryMax; attempt++) {
    try {
      return await _getJsonArray(http, url);
    } catch (e) {
      lastErr = e;
      final msg = e.toString().toLowerCase();
      final isRateLimit = msg.contains('1015') ||
          msg.contains('429') ||
          msg.contains('too many');
      final waitSec = isRateLimit ? 30 * attempt : 5 * attempt;
      stderr.writeln(
        '  ! $url başarısız (deneme $attempt/$_retryMax) — '
        '${waitSec}sn sonra tekrar dene: $e',
      );
      await Future<void>.delayed(Duration(seconds: waitSec));
    }
  }
  throw StateError('Çekilemedi ($_retryMax deneme): $url — son hata: $lastErr');
}
