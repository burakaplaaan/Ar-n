// Keşfet kayıtlı / beğenilen ID'leri Firestore `users/{uid}` ile senkron.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firebase_bootstrap.dart';

abstract final class InspirationEngagementSyncService {
  static const _kSaved = 'inspire_saved_ids';
  static const _kLiked = 'inspire_liked_ids';
  static const _pushDebounce = Duration(milliseconds: 800);

  static Timer? _debounceTimer;
  static SharedPreferences? _pendingPrefs;
  static Future<void>? _drainFuture;

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
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
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

  static Future<void> pushFromPrefs(
    SharedPreferences prefs, {
    bool immediate = false,
  }) async {
    if (immediate) {
      await _pushNow(prefs);
      return;
    }
    _pendingPrefs = prefs;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_pushDebounce, () {
      final latest = _pendingPrefs;
      _pendingPrefs = null;
      if (latest != null) {
        unawaited(_pushNow(latest));
      }
    });
  }

  static Future<void> flushPendingPush() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final latest = _pendingPrefs;
    _pendingPrefs = null;
    if (latest != null) {
      await _pushNow(latest);
      return;
    }
    final drain = _drainFuture;
    if (drain != null) {
      await drain;
    }
  }

  static Future<void> _pushNow(SharedPreferences prefs) async {
    _pendingPrefs = prefs;
    final currentDrain = _drainFuture;
    if (currentDrain != null) {
      await currentDrain;
      return;
    }
    final drain = _drainPendingWrites();
    _drainFuture = drain;
    try {
      await drain;
    } finally {
      _drainFuture = null;
    }
  }

  static Future<void> _drainPendingWrites() async {
    while (_pendingPrefs != null) {
      final prefs = _pendingPrefs!;
      _pendingPrefs = null;
      await _writeCurrentPrefs(prefs);
    }
  }

  static Future<void> _writeCurrentPrefs(SharedPreferences prefs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !isFirebaseReady) return;
    try {
      final saved = prefs.getStringList(_kSaved) ?? [];
      final liked = prefs.getStringList(_kLiked) ?? [];
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'inspirationSavedIds': saved,
        'inspirationLikedIds': liked,
        'engagementUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('InspirationEngagementSyncService push: $e\n$st');
    }
  }
}
