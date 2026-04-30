// Firestore `quote_pools/{poolId}` — Hive önbellek; yenileme aralığı ile okuma sınırı.
// Okuma: önce Source.server (istemci kalıcı önbelleği eski belge döndürmesin), gerekirse cache.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/quote_pool_ids.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firestore_server_first.dart';
import '../../domain/entities/matched_content.dart';
import '../quote_pools/widget_quote_defaults.dart';
import '../services/arin_widget_sync.dart';

/// Belge: `{ "version": int, "items": [ { ... } ] }`
class QuotePoolsRepository {
  QuotePoolsRepository({
    required SharedPreferences prefs,
    required Box<String> cacheBox,
  }) : _prefs = prefs,
       _box = cacheBox;

  final SharedPreferences _prefs;
  final Box<String> _box;

  static const _legacyHiveBundle = 'bundle_json';

  /// Eski (günlük) anahtar — [clearCacheForPool] ile temizlenir.
  String _syncDayKey(String poolId) => 'arin_quote_pool_sync_$poolId';

  /// Son başarılı uzak çekim zamanı (ms) — aralık kontrolü.
  String _lastFetchAtKey(String poolId) => 'arin_quote_pool_fetch_$poolId';

  String _hiveKey(String poolId) => 'pool_$poolId';

  /// Widget dışı havuzlar: sık güncelleme + maliyet dengesi (~4 okuma/gün üst sınır).
  static const Duration _minIntervalBetweenFetches = Duration(hours: 6);

  /// `widget_quote`: her uygulama açılışında çağrılıyor; çok sık okumayı keser.
  static const Duration _minIntervalWidgetQuote = Duration(hours: 1);

  /// Uzak belgeyi (aralık dolmuşsa) çekip Hive'a yazar.
  ///
  /// Günlük tek kilidi kaldırdık: admin gün içinde güncellediğinde kullanıcılar
  /// en geç birkaç saat içinde görür. Maliyet: havuz başına sınırlı aralıkta en fazla
  /// bir okuma (widget havuzu için daha kısa aralık).
  Future<void> ensureSyncedToday(String poolId) async {
    final now = DateTime.now();
    final isWidgetPool = poolId == QuotePoolIds.widgetQuote;
    final minGap = isWidgetPool
        ? _minIntervalWidgetQuote
        : _minIntervalBetweenFetches;
    final lastMs = _prefs.getInt(_lastFetchAtKey(poolId));
    final hasHiveData = _box.get(_hiveKey(poolId)) != null;
    if (lastMs != null && hasHiveData) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (now.difference(last) < minGap) {
        if (isWidgetPool) {
          await _maybePushWidget();
        }
        return;
      }
    }

    var loaded = false;
    if (isFirebaseReady) {
      try {
        var snap = await _fetchPoolDoc(poolId);

        if ((!snap.exists || snap.data() == null) &&
            poolId == QuotePoolIds.personalizedQuotes) {
          final legacy = await getDocumentServerFirst(
            FirebaseFirestore.instance
                .collection('app_public')
                .doc('quotes_bundle'),
            debugLabel: 'QuotePoolsRepository quotes_bundle',
          );
          if (legacy.exists && legacy.data() != null) {
            snap = legacy;
          }
        }

        if (snap.exists && snap.data() != null) {
          final encoded = _encodeForHive(snap.data()!);
          if (encoded != null) {
            await _box.put(_hiveKey(poolId), encoded);
            loaded = true;
          }
        }
      } catch (e, st) {
        debugPrint('QuotePoolsRepository($poolId): $e\n$st');
      }
    }

    if (loaded) {
      await _prefs.setInt(_lastFetchAtKey(poolId), now.millisecondsSinceEpoch);
    }

    if (!loaded &&
        poolId == QuotePoolIds.personalizedQuotes &&
        _box.get(_hiveKey(poolId)) == null) {
      await _migrateLegacyQuotesBundleIfNeeded();
    }

    if (loaded && poolId == QuotePoolIds.personalizedQuotes) {
      await _maybePushWidget();
    }
    if (poolId == QuotePoolIds.widgetQuote) {
      await _maybePushWidget();
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchPoolDoc(
    String poolId,
  ) async {
    final doc = FirebaseFirestore.instance
        .collection('quote_pools')
        .doc(poolId);
    return getDocumentServerFirst(
      doc,
      debugLabel: 'QuotePoolsRepository $poolId',
    );
  }

  Future<void> _migrateLegacyQuotesBundleIfNeeded() async {
    try {
      final legacy = _box.get(_legacyHiveBundle);
      if (legacy == null || legacy.isEmpty) return;
      final map = jsonDecode(legacy) as Map<String, dynamic>;
      await _box.put(
        _hiveKey(QuotePoolIds.personalizedQuotes),
        jsonEncode(map),
      );
    } catch (e) {
      debugPrint('QuotePoolsRepository migrate legacy: $e');
    }
  }

  static String? _encodeForHive(Map<String, dynamic> data) {
    try {
      final items = data['items'];
      if (items is! List) return null;
      final clean = <Map<String, dynamic>>[];
      for (final e in items) {
        if (e is Map) {
          clean.add(Map<String, dynamic>.from(e));
        }
      }
      if (clean.isEmpty) return null;
      return jsonEncode({'version': data['version'], 'items': clean});
    } catch (e) {
      debugPrint('QuotePoolsRepository encode: $e');
      return null;
    }
  }

  Map<String, dynamic>? _cachedPoolMap(String poolId) {
    final raw = _box.get(_hiveKey(poolId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('QuotePoolsRepository parse $poolId: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> itemsFromCache(String poolId) {
    final m = _cachedPoolMap(poolId);
    if (m == null) return [];
    final items = m['items'];
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Kişiselleştirilmiş eşleştirme havuzu (uyumluluk).
  List<MatchedContent>? matchedContentFromPersonalizedCache() {
    final list = itemsFromCache(QuotePoolIds.personalizedQuotes);
    if (list.isEmpty) return null;
    try {
      final out = list.map((e) => MatchedContent.fromJson(e)).toList();
      if (out.length > 30) return out.sublist(0, 30);
      return out;
    } catch (e) {
      debugPrint('QuotePoolsRepository MatchedContent: $e');
      return null;
    }
  }

  Future<void> _maybePushWidget() async {
    if (kIsWeb) return;
    try {
      final wItems = itemsFromCache(QuotePoolIds.widgetQuote);
      Map<String, dynamic>? row;
      if (wItems.isNotEmpty) {
        final now = DateTime.now();
        final dayOfYear = DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(now.year, 1, 1)).inDays;
        final secondHalfOfDay = now.hour >= 12;
        final slotIndex = dayOfYear * 2 + (secondHalfOfDay ? 1 : 0);
        row = wItems[slotIndex % wItems.length];
      } else {
        final now = DateTime.now();
        final dayOfYear = DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(now.year, 1, 1)).inDays;
        final secondHalfOfDay = now.hour >= 12;
        final slotIndex = dayOfYear * 2 + (secondHalfOfDay ? 1 : 0);
        if (kWidgetQuoteDefaults.isNotEmpty) {
          final seeded =
              kWidgetQuoteDefaults[slotIndex % kWidgetQuoteDefaults.length];
          row = <String, dynamic>{
            'text': seeded['text'] ?? '',
            'source': seeded['source'] ?? '',
          };
        } else {
          final pItems = itemsFromCache(QuotePoolIds.personalizedQuotes);
          if (pItems.isNotEmpty) row = pItems.first;
        }
      }
      if (row == null) return;
      const localeCode = 'tr';
      final text =
          _widgetTrOnlyField(
            row,
            baseKey: 'text',
            legacyTrKeys: const <String>['turkish'],
          ) ??
          (kWidgetQuoteDefaults.isNotEmpty
              ? (kWidgetQuoteDefaults.first['text'] ?? '')
              : '');
      final source =
          _widgetTrOnlyField(
            row,
            baseKey: 'source',
            legacyTrKeys: const <String>['source_tr'],
          ) ??
          '';
      await ArinWidgetSync.pushQuote(
        text: text,
        source: source,
        localeCode: localeCode,
      );
    } catch (e) {
      debugPrint('QuotePoolsRepository widget: $e');
    }
  }

  String? _widgetTrOnlyField(
    Map<String, dynamic> row, {
    required String baseKey,
    List<String> legacyTrKeys = const <String>[],
  }) {
    final mapped = row[baseKey];
    final direct = mapped?.toString().trim();
    if (mapped is! Map && direct != null && direct.isNotEmpty) return direct;
    if (mapped is Map) {
      final trValue = mapped['tr']?.toString().trim();
      if (trValue != null && trValue.isNotEmpty) return trValue;
      final trUpper = mapped['TR']?.toString().trim();
      if (trUpper != null && trUpper.isNotEmpty) return trUpper;
    }

    final keyed = row['${baseKey}_tr']?.toString().trim();
    if (keyed != null && keyed.isNotEmpty) return keyed;

    for (final key in legacyTrKeys) {
      final legacy = row[key]?.toString().trim();
      if (legacy != null && legacy.isNotEmpty) return legacy;
    }

    return null;
  }

  /// Admin veya test: önbelleği temizle (bir sonraki sync uzaktan çeker).
  Future<void> clearCacheForPool(String poolId) async {
    await _box.delete(_hiveKey(poolId));
    await _prefs.remove(_syncDayKey(poolId));
    await _prefs.remove(_lastFetchAtKey(poolId));
  }
}
