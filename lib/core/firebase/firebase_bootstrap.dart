// lib/core/firebase/firebase_bootstrap.dart

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
    debugPrint('ARIN: Firebase hazır.');
  } catch (e, st) {
    isFirebaseReady = false;
    debugPrint('ARIN: Firebase başlatılamadı (flutterfire configure / google-services): $e');
    debugPrint('$st');
  }
}
