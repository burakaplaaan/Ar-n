// Kur'an metni: alquran.cloud → quran-json CDN. Firebase yok.
// Bellek + küçük dosya önbelleği; sure listesi yerelde anında.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'quran_models.dart';
import 'quran_surah_catalog.dart';

const _kMemCap = 8;
const _kDiskCap = 12;
const _kCacheVersion = 'v1';

final _htmlTag = RegExp(r'<[^>]+>');

class QuranRepository {
  QuranRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 12),
                headers: const {
                  'User-Agent': 'Arin-Quran/1.0 (com.arin.arin)',
                  'Accept': 'application/json',
                },
              ),
            );

  final Dio _dio;
  final LinkedHashMap<String, QuranSurahContent> _memory =
      LinkedHashMap<String, QuranSurahContent>();
  final Map<String, Future<QuranSurahContent>> _inflight =
      <String, Future<QuranSurahContent>>{};
  Future<Directory?>? _diskFuture;

  String _memKey(int surah, QuranMealLang lang) =>
      '${lang.cacheKey}:$surah';

  Future<QuranSurahContent> loadSurah({
    required int surah,
    required QuranMealLang lang,
  }) {
    final n = surah.clamp(1, 114);
    final key = _memKey(n, lang);
    final cached = _memory.remove(key);
    if (cached != null) {
      _memory[key] = cached;
      return Future<QuranSurahContent>.value(cached);
    }
    return _inflight.putIfAbsent(key, () async {
      try {
        final fromDisk = await _readDisk(n, lang);
        if (fromDisk != null) {
          _putMemory(key, fromDisk);
          return fromDisk;
        }
        final fetched = await _fetch(n, lang);
        _putMemory(key, fetched);
        unawaited(_writeDisk(n, lang, fetched));
        return fetched;
      } finally {
        _inflight.remove(key);
      }
    });
  }

  void prefetch({required int surah, required QuranMealLang lang}) {
    unawaited(loadSurah(surah: surah, lang: lang).then((_) {}, onError: (_) {}));
  }

  Future<QuranSurahContent> _fetch(int surah, QuranMealLang lang) async {
    try {
      return await _fetchAlquranCloud(surah, lang);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('QuranRepository alquran.cloud: $e\n$st');
      }
      return _fetchQuranJsonCdn(surah, lang);
    }
  }

  Future<QuranSurahContent> _fetchAlquranCloud(
    int surah,
    QuranMealLang lang,
  ) async {
    final editions = switch (lang) {
      QuranMealLang.tr => 'quran-uthmani,tr.diyanet',
      QuranMealLang.en => 'quran-uthmani,en.sahih',
      QuranMealLang.none => 'quran-uthmani',
    };
    final res = await _dio.get<dynamic>(
      'https://api.alquran.cloud/v1/surah/$surah/editions/$editions',
    );
    final root = res.data;
    if (root is! Map) {
      throw const FormatException('alquran.cloud: beklenmeyen gövde');
    }
    if (root['code'] != 200) {
      throw FormatException('alquran.cloud: ${root['code']}');
    }
    return _parseAlquran(surah, lang, root['data']);
  }

  QuranSurahContent _parseAlquran(
    int surah,
    QuranMealLang lang,
    Object? data,
  ) {
    Map<String, dynamic>? arabicBlock;
    Map<String, dynamic>? mealBlock;
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['edition'] is Map)
            ? (map['edition'] as Map)['identifier']?.toString()
            : null;
        if (id == 'quran-uthmani' || arabicBlock == null) {
          arabicBlock = map;
        }
        if (id == 'tr.diyanet' || id == 'en.sahih') {
          mealBlock = map;
        }
      }
    } else if (data is Map) {
      arabicBlock = Map<String, dynamic>.from(data);
    }
    if (arabicBlock == null) {
      throw const FormatException('alquran.cloud: Arapça blok yok');
    }
    final arabicAyahs = arabicBlock['ayahs'];
    if (arabicAyahs is! List || arabicAyahs.isEmpty) {
      throw const FormatException('alquran.cloud: ayet yok');
    }
    final mealAyahs = mealBlock?['ayahs'];
    final mealList = mealAyahs is List ? mealAyahs : const <dynamic>[];
    final meta = QuranSurahCatalog.byNumber(surah);
    final out = <QuranAyah>[];
    for (var i = 0; i < arabicAyahs.length; i++) {
      final a = arabicAyahs[i];
      if (a is! Map) continue;
      final ayahNo = (a['numberInSurah'] as num?)?.toInt() ?? (i + 1);
      final arabic = _clean(a['text']?.toString() ?? '');
      if (arabic.isEmpty) continue;
      var translation = '';
      if (i < mealList.length && mealList[i] is Map) {
        translation = _clean((mealList[i] as Map)['text']?.toString() ?? '');
      }
      out.add(
        QuranAyah(
          surah: surah,
          ayah: ayahNo,
          arabic: arabic,
          translation: translation,
          globalNumber: (a['number'] as num?)?.toInt() ??
              QuranSurahCatalog.globalAyahNumber(surah, ayahNo),
          juz: (a['juz'] as num?)?.toInt(),
          page: (a['page'] as num?)?.toInt(),
        ),
      );
    }
    return QuranSurahContent(
      meta: meta,
      ayahs: _normalizeAyahs(meta: meta, raw: out),
      mealLang: lang,
    );
  }

  Future<QuranSurahContent> _fetchQuranJsonCdn(
    int surah,
    QuranMealLang lang,
  ) async {
    final folder = switch (lang) {
      QuranMealLang.tr => 'tr',
      QuranMealLang.en => 'en',
      QuranMealLang.none => 'ar',
    };
    final res = await _dio.get<dynamic>(
      'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/chapters/$folder/$surah.json',
    );
    final root = res.data;
    final map = root is Map
        ? Map<String, dynamic>.from(root)
        : jsonDecode(root is String ? root : '') as Map<String, dynamic>;
    final verses = map['verses'];
    if (verses is! List || verses.isEmpty) {
      throw const FormatException('quran-json: ayet yok');
    }
    final meta = QuranSurahCatalog.byNumber(surah);
    final out = <QuranAyah>[];
    for (final v in verses) {
      if (v is! Map) continue;
      final ayahNo = (v['id'] as num?)?.toInt() ?? (out.length + 1);
      final arabic = _clean(v['text']?.toString() ?? '');
      if (arabic.isEmpty) continue;
      out.add(
        QuranAyah(
          surah: surah,
          ayah: ayahNo,
          arabic: arabic,
          translation: lang == QuranMealLang.none
              ? ''
              : _clean(v['translation']?.toString() ?? ''),
          globalNumber: QuranSurahCatalog.globalAyahNumber(surah, ayahNo),
        ),
      );
    }
    return QuranSurahContent(
      meta: meta,
      ayahs: _normalizeAyahs(meta: meta, raw: out),
      mealLang: lang,
    );
  }

  static bool _looksLikeBismillah(String arabic) {
    final compact = arabic.replaceAll(RegExp(r'\s+'), '');
    return compact.contains('بسم') &&
        compact.contains('الله') &&
        compact.length < 48;
  }

  static List<QuranAyah> _normalizeAyahs({
    required QuranSurahMeta meta,
    required List<QuranAyah> raw,
  }) {
    var list = List<QuranAyah>.from(raw);
    if (list.length == meta.ayahCount + 1 &&
        meta.number != 1 &&
        _looksLikeBismillah(list.first.arabic)) {
      list = list.sublist(1);
    }
    if (list.length != meta.ayahCount) {
      throw FormatException(
        'sure ${meta.number}: ${list.length} ayet, beklenen ${meta.ayahCount}',
      );
    }
    final out = <QuranAyah>[];
    for (var i = 0; i < list.length; i++) {
      final ayahNo = i + 1;
      final src = list[i];
      out.add(
        QuranAyah(
          surah: meta.number,
          ayah: ayahNo,
          arabic: src.arabic,
          translation: src.translation,
          globalNumber: QuranSurahCatalog.globalAyahNumber(meta.number, ayahNo),
          juz: src.juz,
          page: src.page,
        ),
      );
    }
    return out;
  }

  void _putMemory(String key, QuranSurahContent content) {
    _memory.remove(key);
    _memory[key] = content;
    while (_memory.length > _kMemCap) {
      _memory.remove(_memory.keys.first);
    }
  }

  Future<Directory?> _ensureDisk() {
    return _diskFuture ??= () async {
      if (kIsWeb) return null;
      try {
        final root = await getApplicationSupportDirectory();
        final dir = Directory('${root.path}/quran_cache');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        return dir;
      } catch (_) {
        return null;
      }
    }();
  }

  File? _diskFile(Directory dir, int surah, QuranMealLang lang) {
    return File('${dir.path}/${_kCacheVersion}_${lang.cacheKey}_$surah.json');
  }

  Future<QuranSurahContent?> _readDisk(int surah, QuranMealLang lang) async {
    final dir = await _ensureDisk();
    if (dir == null) return null;
    try {
      final file = _diskFile(dir, surah, lang);
      if (file == null || !file.existsSync()) return null;
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return _fromDiskMap(surah, lang, map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDisk(
    int surah,
    QuranMealLang lang,
    QuranSurahContent content,
  ) async {
    final dir = await _ensureDisk();
    if (dir == null) return;
    try {
      final file = _diskFile(dir, surah, lang);
      if (file == null) return;
      file.writeAsStringSync(jsonEncode(_toDiskMap(content)));
      await _evictDisk(dir);
    } catch (_) {}
  }

  Future<void> _evictDisk(Directory dir) async {
    try {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort(
          (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
        );
      while (files.length > _kDiskCap) {
        final oldest = files.removeAt(0);
        try {
          oldest.deleteSync();
        } catch (_) {}
      }
    } catch (_) {}
  }

  Map<String, Object?> _toDiskMap(QuranSurahContent content) {
    return {
      'surah': content.meta.number,
      'lang': content.mealLang.cacheKey,
      'ayahs': [
        for (final a in content.ayahs)
          {
            'ayah': a.ayah,
            'ar': a.arabic,
            'tr': a.translation,
            'g': a.globalNumber,
            'juz': a.juz,
            'page': a.page,
          },
      ],
    };
  }

  QuranSurahContent _fromDiskMap(
    int surah,
    QuranMealLang lang,
    Map<String, dynamic> map,
  ) {
    final raw = map['ayahs'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('disk cache boş');
    }
    final ayahs = <QuranAyah>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final ayahNo = (item['ayah'] as num?)?.toInt() ?? (ayahs.length + 1);
      final arabic = item['ar']?.toString() ?? '';
      if (arabic.isEmpty) continue;
      ayahs.add(
        QuranAyah(
          surah: surah,
          ayah: ayahNo,
          arabic: arabic,
          translation: item['tr']?.toString() ?? '',
          globalNumber: (item['g'] as num?)?.toInt() ??
              QuranSurahCatalog.globalAyahNumber(surah, ayahNo),
          juz: (item['juz'] as num?)?.toInt(),
          page: (item['page'] as num?)?.toInt(),
        ),
      );
    }
    final meta = QuranSurahCatalog.byNumber(surah);
    return QuranSurahContent(
      meta: meta,
      ayahs: _normalizeAyahs(meta: meta, raw: ayahs),
      mealLang: lang,
    );
  }

  static String _clean(String raw) {
    return raw.replaceAll(_htmlTag, '').replaceAll('&nbsp;', ' ').trim();
  }

  void dispose() {
    _dio.close(force: true);
    _memory.clear();
    _inflight.clear();
  }
}

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  final repo = QuranRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
