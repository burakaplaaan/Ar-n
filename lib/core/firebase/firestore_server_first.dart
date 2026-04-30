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
