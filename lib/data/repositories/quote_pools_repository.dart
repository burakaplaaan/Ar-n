// Firestore `quote_pools/{poolId}` — Hive önbellek; yenileme aralığı ile okuma sınırı.
// Okuma: önce Source.server (istemci kalıcı önbelleği eski belge döndürmesin), gerekirse cache.

import 'dart:async';
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
  final Map<String, Future<bool>> _refreshInFlight = {};

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
  /// AÇILIŞ STRATEJİSİ — cache-first:
  ///   - Hive'da cache var ve aralık dolmamışsa: hemen döner, hiç bekleme.
  ///   - Cache var ama aralık dolmuşsa: cache ile devam eder, server
  ///     tazelemesini ARKA PLANDA tetikler (caller'ı bloklamaz).
  ///   - Cache yok: ilk açılış senaryosu — server'ı bekler (timeout 10sn
  ///     Firestore SDK default), boş dönerse legacy bundle migration
  ///     denemesi yapılır.
  ///
  /// Bu strateji açılış path'inde server timeout'u ana isolate'i
  /// kasamaz — kötü ağda kullanıcı widget/wisdom için 10 saniye boşa
  /// beklemez. Maliyet: havuz başına sınırlı aralıkta en fazla bir okuma
  /// (widget havuzu için daha kısa aralık).
  Future<void> ensureSyncedToday(String poolId) async {
    final now = DateTime.now();
    final isWidgetPool = poolId == QuotePoolIds.widgetQuote;
    final minGap = isWidgetPool
        ? _minIntervalWidgetQuote
        : _minIntervalBetweenFetches;
    final lastMs = _prefs.getInt(_lastFetchAtKey(poolId));
    final hasHiveData = _box.get(_hiveKey(poolId)) != null;

    // Cache var + aralık DOLMAMIŞ → hemen dön, server'a hiç gitme.
    if (lastMs != null && hasHiveData) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (now.difference(last) < minGap) {
        if (isWidgetPool) {
          await _maybePushWidget();
        }
        return;
      }
    }

    // Cache var ama aralık DOLMUŞ → cache ile devam et, tazelemeyi arka
    // planda tetikle. Caller bloklanmıyor; sonraki açılışta güncel veri
    // geliyor.
    if (hasHiveData) {
      if (isFirebaseReady) {
        unawaited(
          _refreshFromServerDeduped(poolId, now).then((loaded) async {
            if (loaded && isWidgetPool) {
              await _maybePushWidget();
            }
          }),
        );
      }
      if (isWidgetPool) {
        await _maybePushWidget();
      }
      return;
    }

    // Cache YOK → ilk açılış (yeni kurulum). Server'ı bekle çünkü cache
    // ile sunabileceğimiz hiçbir şey yok. Burası kötü ağda yine 10sn
    // bekleyebilir ama bu sadece ilk launch'ta bir kez olur.
    final loaded = isFirebaseReady
        ? await _refreshFromServerDeduped(poolId, now)
        : false;

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

  /// Server'dan tazele, başarılıysa Hive'a yaz + lastFetch markla.
  /// [ensureSyncedToday] hem fg hem arka plan yolundan çağırır.
  Future<bool> _refreshFromServerDeduped(String poolId, DateTime now) {
    final current = _refreshInFlight[poolId];
    if (current != null) return current;
    final future = _refreshFromServer(poolId, now);
    _refreshInFlight[poolId] = future;
    future.whenComplete(() => _refreshInFlight.remove(poolId));
    return future;
  }

  Future<bool> _refreshFromServer(String poolId, DateTime now) async {
    var loaded = false;
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

    if (loaded) {
      await _prefs.setInt(_lastFetchAtKey(poolId), now.millisecondsSinceEpoch);
    }
    return loaded;
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
      final rows = _widgetQuoteRows();
      if (rows.isEmpty) return;
      const localeCode = 'tr';
      final slots = _widgetQuoteSlotStarts(DateTime.now(), days: 30);
      final schedule = <({DateTime startsAt, String text, String source})>[];
      for (final slot in slots) {
        final row = rows[_widgetQuoteSlotIndex(slot) % rows.length];
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
        if (text.trim().isEmpty) continue;
        schedule.add((startsAt: slot, text: text, source: source));
      }
      if (schedule.isEmpty) return;
      await ArinWidgetSync.pushQuoteSchedule(
        entries: schedule,
        localeCode: localeCode,
      );
    } catch (e) {
      debugPrint('QuotePoolsRepository widget: $e');
    }
  }

  List<Map<String, dynamic>> _widgetQuoteRows() {
    final wItems = itemsFromCache(QuotePoolIds.widgetQuote);
    if (wItems.isNotEmpty) return wItems;
    if (kWidgetQuoteDefaults.isNotEmpty) {
      return kWidgetQuoteDefaults
          .map(
            (seeded) => <String, dynamic>{
              'text': seeded['text'] ?? '',
              'source': seeded['source'] ?? '',
            },
          )
          .toList(growable: false);
    }
    return itemsFromCache(QuotePoolIds.personalizedQuotes);
  }

  List<DateTime> _widgetQuoteSlotStarts(DateTime now, {required int days}) {
    const slotHours = <int>[0, 6, 9, 12, 15, 18, 21];
    final today = DateTime(now.year, now.month, now.day);
    var current = DateTime(today.year, today.month, today.day, slotHours.first);
    for (final h in slotHours) {
      final candidate = DateTime(today.year, today.month, today.day, h);
      if (!candidate.isAfter(now)) {
        current = candidate;
      } else {
        break;
      }
    }

    final endExclusive = today.add(Duration(days: days));
    final out = <DateTime>[];
    for (var dayOffset = 0; dayOffset <= days; dayOffset++) {
      final day = today.add(Duration(days: dayOffset));
      for (final h in slotHours) {
        final slot = DateTime(day.year, day.month, day.day, h);
        if (slot.isBefore(current) || !slot.isBefore(endExclusive)) continue;
        out.add(slot);
      }
    }
    return out;
  }

  int _widgetQuoteSlotIndex(DateTime slot) {
    const slotHours = <int>[0, 6, 9, 12, 15, 18, 21];
    final dayOfYear = DateTime(
      slot.year,
      slot.month,
      slot.day,
    ).difference(DateTime(slot.year, 1, 1)).inDays;
    final hourIndex = slotHours.indexOf(slot.hour);
    final safeHourIndex = hourIndex < 0 ? 0 : hourIndex;
    return dayOfYear * slotHours.length + safeHourIndex;
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
