// lib/presentation/shared/providers/connectivity_provider.dart
// Cihazın ağ bağlantısı akışı — ArinShell üstündeki "çevrimdışı" şeridi
// ve ihtiyaç halinde FutureProvider'larda kısa devre kararları için.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global `Connectivity()` singleton'ı — plugin kendi içinde stream'i
/// paylaşıyor; her watcher aynı akışı alır. Test için override edilebilir.
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// Ağ bağlantısı durumu (canlı). Başlangıçta `none` olarak döner, native
/// sorgulama tamamlanınca gerçek değerle güncellenir.
///
/// Not: `onConnectivityChanged` artık `List<ConnectivityResult>` yayınlıyor
/// (cihazda aynı anda mobile+vpn olabilir). "bağlı" kararı: listedeki herhangi
/// bir eleman `none` dışında ise.
final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final conn = ref.watch(connectivityProvider);
  try {
    final initial = await conn.checkConnectivity();
    yield _isConnected(initial);
  } catch (e) {
    debugPrint('connectivityProvider: initial check failed: $e');
    // Defansif: hata durumunda "bağlı" varsay — kullanıcıya yanlış banner
    // göstermek, gerçekten çevrimdışı olduğunu gizlemekten daha kötü.
    yield true;
  }
  await for (final list in conn.onConnectivityChanged) {
    yield _isConnected(list);
  }
});

bool _isConnected(List<ConnectivityResult> list) {
  if (list.isEmpty) return true;
  return list.any((e) => e != ConnectivityResult.none);
}
