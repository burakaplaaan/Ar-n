// dart run tool/build_inspiration_corpus.dart
// Girdi: tool/quran_tr_sample.json (quran-json@3.x, CC-BY-SA — bkz. paket lisansı)
// Çıktı: assets/data/inspiration/{verses,quotes,hadiths}.json

import 'dart:convert';
import 'dart:io';

/// Diyanet mealine dayalı Türkçe metin kaynağı: quran-json (Tanzil tabanlı).
const _quranAssetPath = 'tool/quran_tr_sample.json';

const _surahTr = <String>[
  'Fâtiha', 'Bakara', 'Âl-i İmrân', 'Nisâ', 'Mâide', 'En\'âm', 'A\'râf', 'Enfâl',
  'Tevbe', 'Yûnus', 'Hûd', 'Yûsuf', 'Ra\'d', 'İbrâhim', 'Hicr', 'Nahl', 'İsrâ',
  'Kehf', 'Meryem', 'Tâhâ', 'Enbiyâ', 'Hac', 'Mü\'minûn', 'Nûr', 'Furkân',
  'Şuarâ', 'Neml', 'Kasas', 'Ankebût', 'Rûm', 'Lokmân', 'Secde', 'Ahzâb',
  'Sebe\'', 'Fâtır', 'Yâsîn', 'Sâffât', 'Sâd', 'Zümer', 'Mü\'min', 'Fussilet',
  'Şûrâ', 'Zuhruf', 'Duhân', 'Câsiye', 'Ahkâf', 'Muhammed', 'Feth', 'Hucurât',
  'Kâf', 'Zâriyât', 'Tûr', 'Necm', 'Kamer', 'Rahmân', 'Vâkıa', 'Hadîd',
  'Mücâdele', 'Haşr', 'Mümtehine', 'Saff', 'Cum\'a', 'Münâfikûn', 'Tegâbün',
  'Talâk', 'Tahrim', 'Mülk', 'Kalem', 'Hâkka', 'Meâric', 'Nûh', 'Cin',
  'Müzzemmil', 'Müddessir', 'Kıyamet', 'İnsan', 'Mürselât', 'Nebe\'', 'Nâziât',
  'Abese', 'Tekvir', 'İnfitâr', 'Mutaffifîn', 'İnşikâk', 'Burûc', 'Târık',
  'A\'lâ', 'Gâşiye', 'Fecr', 'Beled', 'Şems', 'Leyl', 'Duhâ', 'İnşirâh',
  'Tin', 'Alak', 'Kadr', 'Beyyine', 'Zilzâl', 'Âdiyât', 'Kâria', 'Tekâsür',
  'Asr', 'Hümeze', 'Fîl', 'Kureyş', 'Mâ\'ûn', 'Kevser', 'Kâfirûn', 'Nasr',
  'Tebbet', 'İhlâs', 'Felak', 'Nâs',
];

void main() {
  final root = Directory.current.path;
  final quranFile = File('$root/$_quranAssetPath');
  if (!quranFile.existsSync()) {
    stderr.writeln(
      'Eksik: $_quranAssetPath\n'
      'İndirin:\n'
      'curl -L -o tool/quran_tr_sample.json '
      'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran_tr.json',
    );
    exitCode = 1;
    return;
  }

  final surahs =
      jsonDecode(quranFile.readAsStringSync(encoding: utf8)) as List<dynamic>;

  final flat = <_FlatAyah>[];
  for (final s in surahs) {
    final m = s as Map<String, dynamic>;
    final suraId = (m['id'] as num).toInt();
    final verses = m['verses'] as List<dynamic>;
    for (final v in verses) {
      final vm = v as Map<String, dynamic>;
      final ayahNum = (vm['id'] as num).toInt();
      flat.add(
        _FlatAyah(
          surah: suraId,
          ayah: ayahNum,
          ar: vm['text'] as String,
          tr: vm['translation'] as String,
        ),
      );
    }
  }

  final versesOut = _buildVerseCorpus();
  _validateVerseCorpus(versesOut);

  final quotesOut = _buildUserQuotes();

  final hadithOut = _buildHadithCorpus();
  _validateHadithCorpus(hadithOut);

  final outDir = Directory('$root/assets/data/inspiration');
  outDir.createSync(recursive: true);

  File('${outDir.path}/verses.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(versesOut),
    encoding: utf8,
  );
  File('${outDir.path}/quotes.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(quotesOut),
    encoding: utf8,
  );
  File('${outDir.path}/hadiths.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(hadithOut),
    encoding: utf8,
  );

  stdout.writeln(
    'Yazıldı: ${versesOut.length} âyet, ${quotesOut.length} söz, '
    '${hadithOut.length} hadis',
  );
}

class _FlatAyah {
  const _FlatAyah({
    required this.surah,
    required this.ayah,
    required this.ar,
    required this.tr,
  });

  final int surah;
  final int ayah;
  final String ar;
  final String tr;
}

List<Map<String, dynamic>> _buildVerseCorpus() {
  final versesFile = File('assets/data/inspiration/verses.json');
  if (!versesFile.existsSync()) {
    return const <Map<String, dynamic>>[];
  }
  final raw = jsonDecode(versesFile.readAsStringSync(encoding: utf8));
  if (raw is! List) {
    return const <Map<String, dynamic>>[];
  }
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// Kullanıcı sözleri — [reelsStyle] 0–13 tipografi; 13’te [{{g:…}}] altın vurgu.
List<Map<String, dynamic>> _buildUserQuotes() {
  final quotesFile = File('assets/data/inspiration/quotes.json');
  if (!quotesFile.existsSync()) {
    return const <Map<String, dynamic>>[];
  }
  final raw = jsonDecode(quotesFile.readAsStringSync(encoding: utf8));
  if (raw is! List) {
    return const <Map<String, dynamic>>[];
  }
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<Map<String, dynamic>> _buildHadithCorpus() {
  final hadithsFile = File('assets/data/inspiration/hadiths.json');
  if (!hadithsFile.existsSync()) {
    return const <Map<String, dynamic>>[];
  }
  final raw = jsonDecode(hadithsFile.readAsStringSync(encoding: utf8));
  if (raw is! List) {
    return const <Map<String, dynamic>>[];
  }
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

void _validateHadithCorpus(List<Map<String, dynamic>> items) {
  const expectedTexts = <String>[
    'Güçlü kimse, öfke anında kendine hakim olandır.',
    'Sabır, ilk sarsıntı anında gösterilendir.',
    'Allah, yumuşak huylu ve güler yüzlü kimseyi sever.',
    'Şüphesiz her zorlukla beraber bir kolaylık vardır.',
    'Sabır aydınlıktır, sadaka burhandır.',
    'Kalpler ancak Allah’ı anmakla huzur bulur.',
    'İman, sabır ve hoşgörüdür.',
    'Güzel söz sadakadır.',
  ];
  if (items.length != expectedTexts.length) {
    throw StateError(
      'Hadith corpus must contain exactly ${expectedTexts.length} items; got ${items.length}.',
    );
  }
  for (var i = 0; i < items.length; i++) {
    final m = items[i];
    final id = m['id']?.toString();
    final kind = m['kind']?.toString();
    final tr = m['tr']?.toString();
    final expectedId = 'h_${i + 1}';
    if (id != expectedId) {
      throw StateError('Hadith item at index $i must have id $expectedId; got $id.');
    }
    if (kind != 'hadith') {
      throw StateError('Hadith item $expectedId must have kind=hadith; got $kind.');
    }
    if (tr != expectedTexts[i]) {
      throw StateError('Hadith item $expectedId text mismatch.');
    }
  }
}

void _validateVerseCorpus(List<Map<String, dynamic>> items) {
  final quranRef = RegExp(
    r'^[A-Za-zÇĞİÖŞÜâîûçğıöşü\'`\- ]+\s+\d+$',
    caseSensitive: false,
  );
  for (final m in items) {
    final id = m['id']?.toString() ?? '(unknown)';
    final kind = m['kind']?.toString();
    if (kind != 'verse') {
      throw StateError('Verse corpus item $id has invalid kind: $kind');
    }
    final ar = m['ar']?.toString().trim() ?? '';
    if (ar.isEmpty) {
      throw StateError('Verse corpus item $id has empty Arabic text.');
    }
    final ref = m['verseReference']?.toString().trim() ?? '';
    if (!quranRef.hasMatch(ref)) {
      throw StateError('Verse corpus item $id has non-Quran reference: $ref');
    }
  }
}
