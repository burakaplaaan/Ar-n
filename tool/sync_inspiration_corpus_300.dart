// Âyetleri 300 kayda indirir; hadisleri fawazahmed0/hadith-api (jsdelivr) üzerinden
// Türkçe + Arapça eşleştirerek, kısa metin filtresiyle 300 adet üretir.
//
// Kullanım: dart run tool/sync_inspiration_corpus_300.dart
//
// Kaynak: https://github.com/fawazahmed0/hadith-api (CC0)

import 'dart:convert';
import 'dart:io';

const _versesPath = 'assets/data/inspiration/verses.json';
const _hadithsPath = 'assets/data/inspiration/hadiths.json';

const _maxTrChars = 240;
const _maxWords = 32;
const _maxRoughSentences = 3;
const _minTrChars = 14;

const _targetVerses = 300;
const _targetHadiths = 300;

const _base = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

int _wordCount(String s) =>
    s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

int _roughSentenceCount(String s) {
  final parts = s
      .split(RegExp(r'[.!?…]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return parts.isEmpty ? 1 : parts.length;
}

bool _keepTr(String tr) {
  final t = tr.trim();
  if (t.length < _minTrChars) return false;
  if (t.length > _maxTrChars) return false;
  if (_wordCount(t) > _maxWords) return false;
  if (_roughSentenceCount(t) > _maxRoughSentences) return false;
  return true;
}

Future<String> _httpGet(String url) async {
  Object? lastErr;
  for (var attempt = 0; attempt < 4; attempt++) {
    final c = HttpClient();
    try {
      final req = await c.getUrl(Uri.parse(url));
      req.headers.set('User-Agent', 'ArinCorpusSync/1.0');
      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}', uri: Uri.parse(url));
      }
      return await utf8.decoder.bind(res).join();
    } catch (e, st) {
      lastErr = e;
      if (attempt < 3) {
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
        continue;
      }
      Error.throwWithStackTrace(e, st);
    } finally {
      c.close(force: true);
    }
  }
  throw lastErr ?? StateError('http');
}

Future<Map<String, dynamic>> _fetchJson(String path) async {
  final local = File('tool/hadith_api_cache/$path');
  final String s;
  if (await local.exists()) {
    s = await local.readAsString();
  } else {
    s = await _httpGet('$_base/$path');
  }
  return jsonDecode(s) as Map<String, dynamic>;
}

Map<int, String> _arabicByHadithNumber(Map<String, dynamic> root) {
  final list = root['hadiths'] as List<dynamic>? ?? const [];
  final m = <int, String>{};
  for (final e in list) {
    if (e is! Map<String, dynamic>) continue;
    final n = (e['hadithnumber'] as num?)?.toInt();
    final t = e['text'] as String?;
    if (n != null && t != null && t.trim().isNotEmpty) {
      m[n] = t.trim();
    }
  }
  return m;
}

Future<int> _addFromEdition({
  required List<Map<String, dynamic>> out,
  required Set<String> seenTr,
  required String turFile,
  required String araFile,
  required String refPrefix,
  required int cap,
}) async {
  final tur = await _fetchJson(turFile);
  final ara = await _fetchJson(araFile);
  final araMap = _arabicByHadithNumber(ara);
  final list = tur['hadiths'] as List<dynamic>? ?? const [];
  var added = 0;
  for (final e in list) {
    if (out.length >= cap) break;
    if (e is! Map<String, dynamic>) continue;
    final n = (e['hadithnumber'] as num?)?.toInt() ?? 0;
    final tr = (e['text'] as String? ?? '').trim();
    if (!_keepTr(tr)) continue;
    final ar = araMap[n];
    if (ar == null || ar.length > 420) continue;
    final key = tr.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (seenTr.contains(key)) continue;
    seenTr.add(key);
    out.add({
      'id': 'h_${out.length + 1}',
      'kind': 'hadith',
      'tr': tr,
      'ar': ar,
      'source': 'Hadis-i şerif (meal)',
      'verseReference': '$refPrefix, $n',
      'layoutIndex': 8,
      'reelsStyle': 4,
      'emphasisTailLines': 0,
    });
    added++;
  }
  return added;
}

Future<void> main() async {
  final root = Directory.current;
  final versesFile = File.fromUri(root.uri.resolve(_versesPath));
  final hadithsFile = File.fromUri(root.uri.resolve(_hadithsPath));

  if (!versesFile.existsSync()) {
    stderr.writeln('Bulunamadı: ${versesFile.path}');
    exit(1);
  }

  // —— Âyet: sıralı id ile eşit aralıklı 300 örnek ——
  final versesRaw = await versesFile.readAsString();
  final versesIn = (jsonDecode(versesRaw) as List<dynamic>)
      .whereType<Map<String, dynamic>>()
      .toList();

  int idNum(String id) {
    final m = RegExp(r'^v_(\d+)$').firstMatch(id);
    return m != null ? int.parse(m.group(1)!) : 0;
  }

  versesIn.sort((a, b) => idNum(a['id'] as String).compareTo(idNum(b['id'] as String)));
  final n = versesIn.length;
  final picked = <Map<String, dynamic>>[];
  if (n <= _targetVerses) {
    picked.addAll(versesIn.map((e) => Map<String, dynamic>.from(e)));
  } else {
    for (var i = 0; i < _targetVerses; i++) {
      final idx = ((i * (n - 1)) / (_targetVerses - 1)).round();
      picked.add(Map<String, dynamic>.from(versesIn[idx]));
    }
  }

  // —— Hadis: API’den doldur ——
  final outHadith = <Map<String, dynamic>>[];
  final seenTr = <String>{};

  stdout.writeln('Hadis API indiriliyor…');

  await _addFromEdition(
    out: outHadith,
    seenTr: seenTr,
    turFile: 'tur-nawawi.min.json',
    araFile: 'ara-nawawi.min.json',
    refPrefix: 'Nevevi (rivayet no)',
    cap: _targetHadiths,
  );
  stdout.writeln('  Nawawi: ${outHadith.length}');

  if (outHadith.length < _targetHadiths) {
    await _addFromEdition(
      out: outHadith,
      seenTr: seenTr,
      turFile: 'tur-tirmidhi.min.json',
      araFile: 'ara-tirmidhi.min.json',
      refPrefix: 'Tirmizî (rivayet no)',
      cap: _targetHadiths,
    );
    stdout.writeln('  + Tirmizî: toplam ${outHadith.length}');
  }
  if (outHadith.length < _targetHadiths) {
    await _addFromEdition(
      out: outHadith,
      seenTr: seenTr,
      turFile: 'tur-nasai.min.json',
      araFile: 'ara-nasai.min.json',
      refPrefix: 'Nesâî (rivayet no)',
      cap: _targetHadiths,
    );
    stdout.writeln('  + Nesâî: toplam ${outHadith.length}');
  }
  if (outHadith.length < _targetHadiths) {
    await _addFromEdition(
      out: outHadith,
      seenTr: seenTr,
      turFile: 'tur-muslim.min.json',
      araFile: 'ara-muslim.min.json',
      refPrefix: 'Müslim (rivayet no)',
      cap: _targetHadiths,
    );
    stdout.writeln('  + Müslim: toplam ${outHadith.length}');
  }
  if (outHadith.length < _targetHadiths) {
    await _addFromEdition(
      out: outHadith,
      seenTr: seenTr,
      turFile: 'tur-bukhari.min.json',
      araFile: 'ara-bukhari.min.json',
      refPrefix: 'Buhârî (rivayet no)',
      cap: _targetHadiths,
    );
    stdout.writeln('  + Buhârî: toplam ${outHadith.length}');
  }

  if (outHadith.length < _targetHadiths) {
    stderr.writeln(
      'Uyarı: Uzunluk filtresiyle yalnızca ${outHadith.length} hadis toplanabildi. '
      'Eşikleri tool/sync_inspiration_corpus_300.dart içinde gevşetin.',
    );
  }

  for (var i = 0; i < outHadith.length; i++) {
    outHadith[i] = Map<String, dynamic>.from(outHadith[i])..['id'] = 'h_${i + 1}';
  }

  final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
  final backupDir = Directory('tool/_backups/inspiration');
  await backupDir.create(recursive: true);
  await versesFile.copy('${backupDir.path}/verses.json.bak.$ts');
  await hadithsFile.copy('${backupDir.path}/hadiths.json.bak.$ts');

  const enc = JsonEncoder.withIndent('  ');
  await versesFile.writeAsString(enc.convert(picked));
  await hadithsFile.writeAsString(enc.convert(outHadith));

  stdout.writeln('Tamam: âyet ${picked.length}, hadis ${outHadith.length}');
  stdout.writeln('Yedek: ${backupDir.path}/*.bak.$ts');
}
