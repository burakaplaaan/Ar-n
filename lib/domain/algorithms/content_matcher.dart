// lib/domain/algorithms/content_matcher.dart
// Kullanıcı etiketlerini içerik havuzuyla eşleştiren algoritma.
// Ağırlıklı skor hesaplaması: en çok etiket örtüşen içerik seçilir.
// Günlük rastgelelik: aynı etiket kümesi için her gün farklı içerik çıkar.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../entities/matched_content.dart';

class ContentMatcher {
  static List<MatchedContent>? _pool;

  /// Varlık havuzunu yükler (ilk çağrıda)
  static Future<List<MatchedContent>> _loadPool() async {
    if (_pool != null) return _pool!;
    final raw = await rootBundle.loadString('assets/data/content_pool.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    _pool = (data['entries'] as List)
        .map((e) => MatchedContent.fromJson(e as Map<String, dynamic>))
        .toList();
    return _pool!;
  }

  /// Verilen etiket listesiyle en uygun içeriği döndürür.
  /// [dayOffset] — günlük rotasyon için tarih tabanlı sayeed (varsayılan: bugün)
  static Future<MatchedContent> match(
    List<String> userTags, {
    int? dayOffset,
  }) async {
    final pool = await _loadPool();
    return matchFromPool(pool, userTags, dayOffset: dayOffset);
  }

  /// [pool] — Firestore önbelleği veya asset havuzu; boşsa [fallbackLoadPool] kullanılır.
  static Future<MatchedContent> todaysContentHybrid(
    List<String> userTags, {
    List<MatchedContent>? cloudPool,
    int? dayOffset,
  }) async {
    if (cloudPool != null && cloudPool.isNotEmpty) {
      return matchFromPool(cloudPool, userTags, dayOffset: dayOffset);
    }
    return match(userTags, dayOffset: dayOffset);
  }

  /// Aynı eşleştirme mantığı, havuz dışarıdan (hibrit: yerel + bulut önbellek).
  static MatchedContent matchFromPool(
    List<MatchedContent> pool,
    List<String> userTags, {
    int? dayOffset,
  }) {
    if (pool.isEmpty) {
      throw StateError('İçerik havuzu boş');
    }

    final normalizedUserTags = userTags.map((t) => t.toLowerCase()).toSet();

    final scored = pool.map((content) {
      final contentTags = content.tags.map((t) => t.toLowerCase()).toSet();
      final overlap = contentTags.intersection(normalizedUserTags).length;
      return (content: content, score: overlap);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    final maxScore = scored.first.score;
    final topContents = scored.where((s) => s.score == maxScore).toList();

    if (maxScore == 0) {
      final generalPool = pool.where((c) => c.tags.contains('genel')).toList();
      if (generalPool.isEmpty) {
        final seed =
            dayOffset ?? DateTime.now().difference(DateTime(2024)).inDays;
        final rng = Random(seed);
        return pool[rng.nextInt(pool.length)];
      }
      final seed =
          dayOffset ?? DateTime.now().difference(DateTime(2024)).inDays;
      final rng = Random(seed);
      return generalPool[rng.nextInt(generalPool.length)];
    }

    final seed = dayOffset ?? DateTime.now().difference(DateTime(2024)).inDays;
    final rng = Random(seed);
    return topContents[rng.nextInt(topContents.length)].content;
  }

  /// Bugünün içeriğini döndürür (önbelleklenebilir)
  static Future<MatchedContent> todaysContent(List<String> userTags) {
    return match(userTags);
  }

  /// Havuzu sıfırla (test amaçlı)
  static void resetPool() => _pool = null;
}
