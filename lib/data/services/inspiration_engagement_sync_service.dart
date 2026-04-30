// Keşfet kayıtlı / beğenilen ID'leri Firestore `users/{uid}` ile senkron.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firebase_bootstrap.dart';

abstract final class InspirationEngagementSyncService {
  static const _kSaved = 'inspire_saved_ids';
  static const _kLiked = 'inspire_liked_ids';

  static List<String> _asStringList(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  /// Uzak veriyi çek, yerel ile birleştir (yerel sıra öncelikli).
  ///
  /// Sunucu öncelikli okuma kullanılır (`Source.server`) — kullanıcı
  /// başka bir cihazda kaydettiği/beğendiği öğeyi her koşulda görmeli.
  /// Sunucuya ulaşılamazsa cache fallback'e düşeriz; bu şekilde çevrimdışı
  /// da kısa süre tutarlı bir deneyim var ama "online olduğunda" daima
  /// güncel liste kazanır.
  static Future<void> pullMergeLocal({
    required String uid,
    required SharedPreferences prefs,
  }) async {
    if (!isFirebaseReady) return;
    Map<String, dynamic>? data;
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(uid);
    try {
      final snap = await docRef.get(const GetOptions(source: Source.server));
      data = snap.data();
    } catch (e) {
      // Ağ yok / timeout / güvenlik kuralı geçici hatası — cache'e düş.
      debugPrint(
        'InspirationEngagementSyncService pull: server failed → cache ($e)',
      );
      try {
        final snap = await docRef.get(const GetOptions(source: Source.cache));
        data = snap.data();
      } catch (e2) {
        debugPrint(
          'InspirationEngagementSyncService pull: cache also failed: $e2',
        );
        return;
      }
    }
    if (data == null) return;

    final cloudSaved = _asStringList(data['inspirationSavedIds']);
    final cloudLiked = _asStringList(data['inspirationLikedIds']);
    final localSaved = prefs.getStringList(_kSaved) ?? [];
    final localLiked = prefs.getStringList(_kLiked) ?? [];

    final mergedSaved = _mergeIds(localSaved, cloudSaved);
    final mergedLiked = _mergeIds(localLiked, cloudLiked);

    await prefs.setStringList(_kSaved, mergedSaved);
    await prefs.setStringList(_kLiked, mergedLiked);
  }

  static List<String> _mergeIds(List<String> local, List<String> cloud) {
    final seen = <String>{};
    final out = <String>[];
    for (final id in local) {
      if (seen.add(id)) out.add(id);
    }
    for (final id in cloud) {
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  static Future<void> pushFromPrefs(SharedPreferences prefs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !isFirebaseReady) return;
    try {
      final saved = prefs.getStringList(_kSaved) ?? [];
      final liked = prefs.getStringList(_kLiked) ?? [];
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'inspirationSavedIds': saved,
          'inspirationLikedIds': liked,
          'engagementUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      debugPrint('InspirationEngagementSyncService push: $e\n$st');
    }
  }
}
