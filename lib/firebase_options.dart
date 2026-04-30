// lib/firebase_options.dart
// Firebase Console + google-services.json / GoogleService-Info.plist ile uyumlu.
// Güncellemek için: `dart pub global run flutterfire_cli:flutterfire configure`
// veya bu dosyayı indirilen yapılandırma dosyalarındaki değerlerle eşleştir.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('ARIN: Web için Firebase tanımlı değil.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'ARIN: Bu platform için Firebase tanımlı değil.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUIzm17DZm8kdzOF3btvuHGtMai9frEf8',
    appId: '1:746942620456:android:bed9ebb88ccd4ebcef661d',
    messagingSenderId: '746942620456',
    projectId: 'arinapp-7b136',
    storageBucket: 'arinapp-7b136.firebasestorage.app',
  );

  /// Android’de Google ile giriş için **Web** OAuth istemci kimliği (…apps.googleusercontent.com).
  /// Firebase Console → Authentication → Sign-in method → **Google** → *Web client ID*.
  /// Boş bırakılırsa: `flutter run --dart-define=GOOGLE_OAUTH_WEB_CLIENT_ID=...` veya aşağıdaki sabite yapıştırın.
  /// Proje ayarlarında Android için SHA-1 ekleyip `google-services.json` yenilerseniz bazen bu kimlik dosyaya da gelir.
  static const String googleOAuthWebClientIdLiteral =
      '746942620456-lm0rg914v26s3u2io9pif08vu24jfor0.apps.googleusercontent.com';

  static const String _googleOAuthWebClientIdFromEnv = String.fromEnvironment(
    'GOOGLE_OAUTH_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// `dart-define` veya [googleOAuthWebClientIdLiteral]; ikisi de boşsa Android’de Google girişi yapılandırılmamış demektir.
  static String get googleOAuthWebClientIdForAndroid {
    if (_googleOAuthWebClientIdFromEnv.isNotEmpty) {
      return _googleOAuthWebClientIdFromEnv;
    }
    return googleOAuthWebClientIdLiteral;
  }

  /// iOS Google Sign-In için iOS OAuth istemci kimliği.
  ///
  /// Firebase Console'dan indirilen `GoogleService-Info.plist` içindeki
  /// `CLIENT_ID`. `--dart-define=GOOGLE_IOS_CLIENT_ID=...` ile override
  /// edilebilir.
  static const String googleOAuthIosClientIdLiteral =
      '746942620456-0u7n7mp8ue37dbnr5asv05c5ngo11qap.apps.googleusercontent.com';

  static const String _googleOAuthIosClientIdFromEnv = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  static String get googleOAuthIosClientId {
    if (_googleOAuthIosClientIdFromEnv.isNotEmpty) {
      return _googleOAuthIosClientIdFromEnv;
    }
    return googleOAuthIosClientIdLiteral;
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCOghTYrk36SfKr6OgBemyfvmMSWVfMCsQ',
    appId: '1:746942620456:ios:7ad326ad7171403fef661d',
    messagingSenderId: '746942620456',
    projectId: 'arinapp-7b136',
    storageBucket: 'arinapp-7b136.firebasestorage.app',
    iosBundleId: 'com.arin.arin',
  );
}
