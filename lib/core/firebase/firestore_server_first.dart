// lib/core/firebase/firestore_server_first.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Güncel içerik ve yönetim ekranları: önce sunucu, sonra istemci önbelleği.
///
/// [GetOptions] ile [Source.serverAndCache] veya varsayılan kaynak kullanmayın;
/// kalıcı Firestore önbelleğinde eski belge dönmesi (panelde yazdığın metnin
/// görünmemesi) bu yüzden oluşabiliyor.
Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentServerFirst(
  DocumentReference<Map<String, dynamic>> ref, {
  String? debugLabel,
}) async {
  try {
    return await ref.get(const GetOptions(source: Source.server));
  } catch (e, st) {
    final tag = debugLabel ?? 'getDocumentServerFirst';
    debugPrint('$tag: server get failed, using cache: $e');
    debugPrint('$st');
    return ref.get(const GetOptions(source: Source.cache));
  }
}

/// Açılış path'i (warmup, splash, anasayfa) için tasarlanmış cache-first
/// okuma. Önce kalıcı Firestore cache'ine bakar; cache'te belge varsa
/// hemen onu döndürür. Cache boşsa ve [allowServerFallback] true ise
/// sunucuya gider; aksi halde `null` döner.
///
/// Neden ayrı? `getDocumentServerFirst` server'a 10 saniye bekliyor
/// (Firestore SDK default), kötü ağda bu süre boyunca ana isolate
/// kuyruğunda async iş birikiyor → kullanıcı için "kasma" hissi.
/// Cache-first stratejisi açılışta sıfır network bekleyişi sağlar;
/// `ensureSyncedToday` gibi caller'lar arka planda paralel server
/// senkronu tetikleyebilir.
Future<DocumentSnapshot<Map<String, dynamic>>?> getDocumentCacheFirst(
  DocumentReference<Map<String, dynamic>> ref, {
  String? debugLabel,
  bool allowServerFallback = false,
}) async {
  final tag = debugLabel ?? 'getDocumentCacheFirst';
  try {
    final snap = await ref.get(const GetOptions(source: Source.cache));
    if (snap.exists && snap.data() != null) return snap;
  } catch (e) {
    debugPrint('$tag: cache get yok/empty: $e');
  }
  if (!allowServerFallback) return null;
  try {
    return await ref.get(const GetOptions(source: Source.server));
  } catch (e) {
    debugPrint('$tag: server fallback failed: $e');
    return null;
  }
}
