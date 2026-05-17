// Firestore `quote_pools` — tüm havuzları tek seferde yerleşik verilerle yazar (admin).

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../../core/constants/quote_pool_ids.dart';
import '../willpower/insight_quote_pools.dart';
import 'quote_pool_defaults.dart';

class QuotePoolSeedPreview {
  const QuotePoolSeedPreview({
    required this.poolCount,
    required this.changedPoolCount,
    required this.currentItemCount,
    required this.targetItemCount,
    required this.addedItemCount,
  });

  final int poolCount;
  final int changedPoolCount;
  final int currentItemCount;
  final int targetItemCount;
  final int addedItemCount;
}

abstract final class QuotePoolBulkSeeder {
  /// [FirebaseFirestore.instance] ile çağır. Mevcut belgelerin üzerine yazar.
  ///
  /// [mergeOnly] true ise Firestore'daki mevcut item'lar KORUNUR; yalnızca
  /// yerleşikte olup Firestore'da eksik olanlar eklenir. Admin manuel
  /// düzenlemeleri silinmemiş olur. false (varsayılan) ise eski davranış →
  /// tamamen üzerine yazar.
  static Future<void> seedAllPools(
    FirebaseFirestore fs, {
    bool mergeOnly = false,
  }) async {
    final defaultsByPool = await _defaultsByPool();

    // Merge modunda Firestore'daki mevcut belgeleri önce okuruz, sonra
    // defaultsiz eksikleri ekleriz. Item kimliği için önce `id`, yoksa
    // `text` veya başlık karşılaştırılır.
    Future<void> writePool(
      String id,
      List<Map<String, dynamic>> defaults,
    ) async {
      if (defaults.isEmpty) return;
      final docRef = fs.collection('quote_pools').doc(id);

      if (mergeOnly) {
        final snap = await docRef.get(const GetOptions(source: Source.server));
        final current = (snap.data()?['items'] as List?) ?? const [];
        final existingKeys = <String>{};
        for (final e in current) {
          if (e is Map) {
            existingKeys.add(_itemKey(Map<String, dynamic>.from(e)));
          }
        }
        final merged = <Map<String, dynamic>>[
          for (final e in current)
            if (e is Map) Map<String, dynamic>.from(e),
        ];
        var added = 0;
        for (final d in defaults) {
          final k = _itemKey(d);
          if (existingKeys.contains(k)) continue;
          merged.add(d);
          existingKeys.add(k);
          added++;
        }
        if (added == 0 && current.isNotEmpty) return; // değişiklik yok
        final currentVersion = (snap.data()?['version'] as num?)?.toInt() ?? 0;
        await docRef.set({
          'version': currentVersion + 1,
          'items': merged,
          'updatedAt': FieldValue.serverTimestamp(),
          'seededFrom': 'merge_seed',
        }, SetOptions(merge: false));
        return;
      }

      final snap = await docRef.get(const GetOptions(source: Source.server));
      final currentVersion = (snap.data()?['version'] as num?)?.toInt() ?? 0;
      await docRef.set({
        'version': currentVersion + 1,
        'items': defaults,
        'updatedAt': FieldValue.serverTimestamp(),
        'seededFrom': 'bulk_seed',
      }, SetOptions(merge: false));
    }

    for (final entry in defaultsByPool.entries) {
      await writePool(entry.key, entry.value);
    }
  }

  static Future<QuotePoolSeedPreview> previewSeedAllPools(
    FirebaseFirestore fs, {
    bool mergeOnly = false,
  }) async {
    final defaultsByPool = await _defaultsByPool();
    var changedPoolCount = 0;
    var currentItemCount = 0;
    var targetItemCount = 0;
    var addedItemCount = 0;

    for (final entry in defaultsByPool.entries) {
      final defaults = entry.value;
      if (defaults.isEmpty) continue;

      final snap = await fs
          .collection('quote_pools')
          .doc(entry.key)
          .get(const GetOptions(source: Source.server));
      final currentRaw = (snap.data()?['items'] as List?) ?? const [];
      final current = <Map<String, dynamic>>[
        for (final e in currentRaw)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
      currentItemCount += current.length;

      if (!mergeOnly) {
        targetItemCount += defaults.length;
        if (!_sameItems(current, defaults)) {
          changedPoolCount++;
        }
        continue;
      }

      final existingKeys = <String>{};
      for (final e in current) {
        existingKeys.add(_itemKey(e));
      }
      var added = 0;
      for (final d in defaults) {
        if (existingKeys.add(_itemKey(d))) {
          added++;
        }
      }
      addedItemCount += added;
      targetItemCount += current.length + added;
      if (added > 0 || current.isEmpty) {
        changedPoolCount++;
      }
    }

    return QuotePoolSeedPreview(
      poolCount: defaultsByPool.length,
      changedPoolCount: changedPoolCount,
      currentItemCount: currentItemCount,
      targetItemCount: targetItemCount,
      addedItemCount: addedItemCount,
    );
  }

  static Future<Map<String, List<Map<String, dynamic>>>>
  _defaultsByPool() async {
    final personalized = await _personalizedFromAsset();
    final hub = _hubMapsFromEmbedded();
    return <String, List<Map<String, dynamic>>>{
      QuotePoolIds.homeNamazWisdom: QuotePoolDefaults.homeNamazWisdom(),
      QuotePoolIds.notificationNamazWisdom:
          QuotePoolDefaults.notificationNamazWisdom(),
      QuotePoolIds.notificationArinmaBodies:
          QuotePoolDefaults.notificationArinmaBodies(),
      QuotePoolIds.notificationDailyNamazReminder:
          QuotePoolDefaults.notificationDailyNamazReminder(),
      QuotePoolIds.zikirDailyReflections:
          QuotePoolDefaults.zikirDailyReflections(),
      QuotePoolIds.healingComfort: QuotePoolDefaults.healingComfort(),
      QuotePoolIds.hubGelisimIslamic: hub.islamic,
      QuotePoolIds.hubGelisimMedical: hub.medical,
      QuotePoolIds.hubArinmaIslamic: hub.islamic,
      QuotePoolIds.hubArinmaMedical: hub.medical,
      QuotePoolIds.personalizedQuotes: personalized,
    };
  }

  /// Merge duplicate tespit anahtarı — id → text → title sırasına göre
  /// ilk dolu değer. İki item'in aynı "konu"yu göstermesi için yeterli
  /// hasarsız heuristik.
  static String _itemKey(Map<String, dynamic> m) {
    final id = m['id']?.toString().trim();
    if (id != null && id.isNotEmpty) return 'id:$id';
    final text = m['text']?.toString().trim();
    if (text != null && text.isNotEmpty) return 'text:$text';
    final title = m['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return 'title:$title';
    return 'raw:${m.toString()}';
  }

  static bool _sameItems(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (jsonEncode(a[i]) != jsonEncode(b[i])) return false;
    }
    return true;
  }

  static Future<List<Map<String, dynamic>>> _personalizedFromAsset() async {
    final raw = await rootBundle.loadString('assets/data/content_pool.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final entries = j['entries'];
    if (entries is! List) return [];
    return entries
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static ({
    List<Map<String, dynamic>> islamic,
    List<Map<String, dynamic>> medical,
  })
  _hubMapsFromEmbedded() {
    final j = jsonDecode(kInsightHubEmbeddedJson) as Map<String, dynamic>;
    List<Map<String, dynamic>> parse(String key) {
      final raw = j[key];
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return (islamic: parse('islamic'), medical: parse('medical'));
  }
}
