// verses.json ve hadiths.json — uzun / mükerrer kayıtları tamamen kaldırır (metni kesmez).
// quotes.json'a dokunulmaz.
//
// Önizleme: dart run tool/prune_inspiration_corpus.dart
// Uygula:   dart run tool/prune_inspiration_corpus.dart --apply

import 'dart:convert';
import 'dart:io';

const _versesPath = 'assets/data/inspiration/verses.json';
const _hadithsPath = 'assets/data/inspiration/hadiths.json';

/// Fotoğraf üstünde okunaklı kalsın: Türkçe meal üst sınırı (karakter).
const int _maxTrChars = 235;

/// Çok paragraflı / idari uzun metinleri çıkarmak için kelime üst sınırı.
const int _maxWords = 32;

/// Kabaca cümle sayısı üst sınırı (. ! ? …)
const int _maxRoughSentences = 3;

/// Anlamsız/bozuk parça (çok kısa).
const int _minTrChars = 14;

/// Âyet ve hadis dosyalarında tutulacak azami kayıt (sözler sınırsız).
const int _maxVersesAndHadithsEach = 50;

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

String _normTr(String s) =>
    s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

bool _keepTr(String tr) {
  final t = tr.trim();
  if (t.length < _minTrChars) return false;
  if (t.length > _maxTrChars) return false;
  if (_wordCount(t) > _maxWords) return false;
  if (_roughSentenceCount(t) > _maxRoughSentences) return false;
  return true;
}

/// Çok yüzeysel/tekrarlı hadis (isteğe bağlı sabit liste).
bool _trivialHadithTr(String tr) {
  const trivial = <String>{
    'iyilik güzeldir; kötülük ise kötüdür.',
  };
  return trivial.contains(tr.trim().toLowerCase());
}

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');

  final root = Directory.current;
  final versesFile = File.fromUri(root.uri.resolve(_versesPath));
  final hadithsFile = File.fromUri(root.uri.resolve(_hadithsPath));

  if (!versesFile.existsSync()) {
    stderr.writeln('Bulunamadı: ${versesFile.path}');
    exit(1);
  }

  final versesIn = (jsonDecode(await versesFile.readAsString()) as List<dynamic>)
      .whereType<Map<String, dynamic>>()
      .toList();

  final hadithsIn = hadithsFile.existsSync()
      ? (jsonDecode(await hadithsFile.readAsString()) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList()
      : <Map<String, dynamic>>[];

  // Âyet: uzunluk + mükerrer tr
  final seenVerseTr = <String>{};
  final keptVerses = <Map<String, dynamic>>[];
  var vDropShort = 0, vDropLong = 0, vDropWords = 0, vDropSent = 0, vDup = 0;

  for (final m in versesIn) {
    final tr = (m['tr'] as String? ?? '').trim();
    if (!_keepTr(tr)) {
      if (tr.length < _minTrChars) {
        vDropShort++;
      } else if (tr.length > _maxTrChars) {
        vDropLong++;
      } else if (_wordCount(tr) > _maxWords) {
        vDropWords++;
      } else {
        vDropSent++;
      }
      continue;
    }
    final key = _normTr(tr);
    if (seenVerseTr.contains(key)) {
      vDup++;
      continue;
    }
    seenVerseTr.add(key);
    keptVerses.add(Map<String, dynamic>.from(m));
  }
  if (keptVerses.length > _maxVersesAndHadithsEach) {
    keptVerses.removeRange(
      _maxVersesAndHadithsEach,
      keptVerses.length,
    );
  }

  // Hadis: aynı kurallar + aynı ar metni tek + yüzeysel satırlar
  final seenHadithAr = <String>{};
  final seenHadithTr = <String>{};
  final keptHadiths = <Map<String, dynamic>>[];
  var hDrop = 0, hDupAr = 0, hDupTr = 0, hTrivial = 0;

  for (final m in hadithsIn) {
    final tr = (m['tr'] as String? ?? '').trim();
    if (_trivialHadithTr(tr)) {
      hTrivial++;
      continue;
    }
    if (!_keepTr(tr)) {
      hDrop++;
      continue;
    }
    final trKey = _normTr(tr);
    if (seenHadithTr.contains(trKey)) {
      hDupTr++;
      continue;
    }
    final ar = (m['ar'] as String? ?? '').trim();
    if (ar.isNotEmpty) {
      if (seenHadithAr.contains(ar)) {
        hDupAr++;
        continue;
      }
      seenHadithAr.add(ar);
    }
    seenHadithTr.add(trKey);
    keptHadiths.add(Map<String, dynamic>.from(m));
  }
  if (keptHadiths.length > _maxVersesAndHadithsEach) {
    keptHadiths.removeRange(
      _maxVersesAndHadithsEach,
      keptHadiths.length,
    );
  }

  stdout.writeln(
    'Âyet: ${versesIn.length} → ${keptVerses.length} '
    '(kısa:$vDropShort uzun:$vDropLong kelime:$vDropWords cümle:$vDropSent mükerrer:$vDup)',
  );
  stdout.writeln(
    'Hadis: ${hadithsIn.length} → ${keptHadiths.length} '
    '(kural:$hDrop mükerrer-ar:$hDupAr mükerrer-tr:$hDupTr yüzeysel:$hTrivial)',
  );

  if (!apply) {
    stdout.writeln(
      '\nÖnizleme. Dosyaları güncellemek için: dart run tool/prune_inspiration_corpus.dart --apply',
    );
    return;
  }

  final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
  final backupDir = Directory('tool/_backups/inspiration');
  await backupDir.create(recursive: true);
  await versesFile.copy('${backupDir.path}/verses.json.bak.$ts');
  if (hadithsFile.existsSync()) {
    await hadithsFile.copy('${backupDir.path}/hadiths.json.bak.$ts');
  }

  const encoder = JsonEncoder.withIndent('  ');
  await versesFile.writeAsString(encoder.convert(keptVerses));
  if (hadithsFile.existsSync()) {
    await hadithsFile.writeAsString(encoder.convert(keptHadiths));
  }
  stdout.writeln('Yazıldı (yedek: ${backupDir.path}/*.bak.$ts).');
}
