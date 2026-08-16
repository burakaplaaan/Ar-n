import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase/firebase_bootstrap.dart';

/// Keşfet ortak beğeni sayacı: `inspiration_like_counts/{cardId}.count`
///
/// Taban (201–2000) cihazda türetilir; bu koleksiyon yalnız gerçek
/// kullanıcı oylarının toplamını tutar.
abstract final class InspirationLikeTotalsService {
  static const collection = 'inspiration_like_counts';

  /// Belge yoksa 0. Okuma hatasında null (yerel tahmine düş).
  static Future<int?> fetchExtra(String cardId) async {
    final id = cardId.trim();
    if (id.isEmpty || !isFirebaseReady) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .get();
      if (!snap.exists) return 0;
      final raw = snap.data()?['count'];
      final n = raw is num ? raw.toInt() : 0;
      return n < 0 ? 0 : n;
    } catch (e) {
      debugPrint('InspirationLikeTotalsService.fetchExtra: $e');
      return null;
    }
  }
}
