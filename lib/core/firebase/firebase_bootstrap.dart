// lib/core/firebase/firebase_bootstrap.dart

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// main() içinde bir kez çağrılır. Başarısızsa [isFirebaseReady] false kalır.
bool isFirebaseReady = false;

/// Yalnızca [kDebugMode] build'lerde kullanılır. Firebase Console → App Check →
/// Manage debug tokens listesine eklenmiş olmalıdır. Release/profile asla
/// bu değeri kullanmaz (Play Integrity / App Attest).
///
/// Override: `--dart-define=ARIN_APP_CHECK_DEBUG_TOKEN=<uuid>`.
const String _kDefaultAppCheckDebugToken =
    '8f3c2a91-6e4b-4d7a-9c1e-5b8a0f2d6e73';

Future<void> bootstrapFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseReady = true;
    if (!kIsWeb) {
      // Release/profile: gerçek attestation. Emülatörde release APK →
      // Play Integrity fail → callable'lar Unauthenticated döner.
      const useDebugProvider = kDebugMode;
      const debugToken = String.fromEnvironment(
        'ARIN_APP_CHECK_DEBUG_TOKEN',
        defaultValue: _kDefaultAppCheckDebugToken,
      );
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: useDebugProvider
              ? const AndroidDebugProvider(debugToken: debugToken)
              : const AndroidPlayIntegrityProvider(),
          providerApple: useDebugProvider
              ? const AppleDebugProvider(debugToken: debugToken)
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
        if (useDebugProvider) {
          debugPrint(
            'ARIN: App Check DEBUG provider aktif. Token Console\'da kayıtlı olmalı: $debugToken',
          );
          try {
            final token = await FirebaseAppCheck.instance.getToken(true);
            debugPrint(
              'ARIN: App Check token alındı (len=${token?.length ?? 0}).',
            );
          } catch (e) {
            debugPrint(
              'ARIN: App Check token alınamadı — debug token Console\'a eklenmemiş olabilir: $e',
            );
          }
        }
      } catch (e) {
        // App Check yalnız korumalı callable'ları fail-closed bırakır; temel
        // Firebase oturum/veri akışını devre dışı bırakmaz.
        debugPrint('ARIN: Firebase App Check etkinleştirilemedi: $e');
      }
    }
    debugPrint('ARIN: Firebase hazır.');
  } catch (e, st) {
    isFirebaseReady = false;
    debugPrint(
      'ARIN: Firebase başlatılamadı (flutterfire configure / google-services): $e',
    );
    debugPrint('$st');
  }
}
