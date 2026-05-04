import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firestore_server_first.dart';
import '../models/inspiration_card_model.dart';

class InspirationFirestoreCatalog {
  const InspirationFirestoreCatalog({
    required this.cards,
    required this.bundledSeedVersion,
  });

  final List<InspirationCardModel> cards;
  final int bundledSeedVersion;
}

/// Firestore: `app_public/inspiration_cards` tek belge.
///
/// ```json
/// {
///   "version": 1,
///   "items": [
///     {
///       "imageIndex": 1,
///       "tr": "Çok satırlı\nmetin",
///       "ar": null,
///       "source": "Kaynak",
///       "verseReference": "Bakara suresi, 2. âyet",
///       "layoutIndex": 0,
///       "reelsStyle": 0,
///       // 0–13: 0–8 klasik set; 9 Cabin Sketch; 10 Bodoni+Montserrat CAPS;
///       // 11 Great Vibes+Lora (sola); 12 Satisfy+Lora+Playfair italic;
///       // 13 Playfair italic + metinde {{g:kelime}} altın vurgu
///       "emphasisTailLines": 2,
///       "useLightTextOnImage": null,
///       "contentKind": "quote | verse | hadith",
///       "showInMainFeed": false
///     }
///   ]
/// }
/// ```
///
/// `useLightTextOnImage`: null → uygulama görsel merkezinden otomatik seçer.
/// `showInMainFeed`: true ise Karma (ana) akışta da gösterilir; âyet/hadis için
/// genelde false, yönetim panelinden tiklenerek true yapılabilir.
class InspirationFirestoreRepository {
  InspirationFirestoreRepository._();

  /// Son başarılı sunucu çekim zamanı (ms). Kısa aralıkta yeniden server'a
  /// gitmemek için throttle'da kullanılır.
  static const String _kLastServerFetchPrefsKey =
      'inspiration_cards_last_server_fetch_ms';

  /// Katalog nadiren değişir (admin düzenlediğinde). Server'a en fazla bu
  /// aralıkta gideriz; arada kullanıcı Firestore istemci önbelleğinden okur
  /// → okuma kotası ve açılış gecikmesi düşer.
  static const Duration _minIntervalBetweenServerFetches = Duration(hours: 16);

  /// Keşfet "çek-yenile" vb. akışlarda throttle'ı manuel sıfırlamak için.
  static Future<void> resetFetchThrottle(SharedPreferences? prefs) async {
    if (prefs == null) return;
    await prefs.remove(_kLastServerFetchPrefsKey);
  }

  /// Tüm kartlar — aynı [imageIndex] için birden fazla satır olabilir.
  ///
  /// [prefs] verilirse 16 saatlik throttle uygulanır: son çekim bu aralıktan
  /// yeniyse istemci önbelleğinden okunur, daha eskiyse sunucuya gider ve
  /// yeni timestamp yazılır. [prefs] null olursa eski (her seferinde sunucu)
  /// davranışa düşer — geriye uyum için.
  static Future<List<InspirationCardModel>> fetchAllCards({
    SharedPreferences? prefs,
  }) async {
    final catalog = await fetchCatalog(prefs: prefs);
    return catalog.cards;
  }

  static Future<InspirationFirestoreCatalog> fetchCatalog({
    SharedPreferences? prefs,
  }) async {
    final out = <InspirationCardModel>[];
    if (!isFirebaseReady) {
      return const InspirationFirestoreCatalog(
        cards: [],
        bundledSeedVersion: 0,
      );
    }

    final docRef = FirebaseFirestore.instance
        .collection('app_public')
        .doc('inspiration_cards');

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastMs = prefs?.getInt(_kLastServerFetchPrefsKey);
    final useCache =
        lastMs != null &&
        (now - lastMs) < _minIntervalBetweenServerFetches.inMilliseconds;

    try {
      DocumentSnapshot<Map<String, dynamic>> snap;
      if (useCache) {
        try {
          snap = await docRef.get(const GetOptions(source: Source.cache));
          if (!snap.exists) {
            snap = await getDocumentServerFirst(
              docRef,
              debugLabel: 'InspirationFirestoreRepository inspiration_cards',
            );
            if (snap.exists) {
              await prefs?.setInt(_kLastServerFetchPrefsKey, now);
            }
          }
        } catch (_) {
          snap = await getDocumentServerFirst(
            docRef,
            debugLabel: 'InspirationFirestoreRepository inspiration_cards',
          );
          if (snap.exists) {
            await prefs?.setInt(_kLastServerFetchPrefsKey, now);
          }
        }
      } else {
        snap = await getDocumentServerFirst(
          docRef,
          debugLabel: 'InspirationFirestoreRepository inspiration_cards',
        );
        if (snap.exists) {
          await prefs?.setInt(_kLastServerFetchPrefsKey, now);
        }
      }

      if (!snap.exists || snap.data() == null) {
        return const InspirationFirestoreCatalog(
          cards: [],
          bundledSeedVersion: 0,
        );
      }

      final data = snap.data()!;
      final bundledSeedVersion =
          (data['bundledSeedVersion'] as num?)?.toInt() ?? 0;
      final raw = data['items'];
      if (raw is! List) {
        return InspirationFirestoreCatalog(
          cards: out,
          bundledSeedVersion: bundledSeedVersion,
        );
      }

      for (final e in raw) {
        if (e is! Map) continue;
        try {
          final m = Map<String, dynamic>.from(e);
          final card = InspirationCardModel.tryFromFirestoreItem(m);
          if (card != null) out.add(card);
        } catch (e2, st2) {
          debugPrint(
            'InspirationFirestoreRepository: skip bad item: $e2\n$st2',
          );
        }
      }
      return InspirationFirestoreCatalog(
        cards: out,
        bundledSeedVersion: bundledSeedVersion,
      );
    } catch (e, st) {
      debugPrint('InspirationFirestoreRepository: $e\n$st');
    }
    return InspirationFirestoreCatalog(cards: out, bundledSeedVersion: 0);
  }
}
