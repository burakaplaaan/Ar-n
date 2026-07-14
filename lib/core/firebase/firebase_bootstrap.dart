// lib/core/firebase/firebase_bootstrap.dart

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// main() içinde bir kez çağrılır. Başarısızsa [isFirebaseReady] false kalır.
bool isFirebaseReady = false;

Future<void> bootstrapFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseReady = true;
    if (!kIsWeb) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      } catch (e) {
        // App Check yalnız analitik callable'ları fail-closed bırakır; temel
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
