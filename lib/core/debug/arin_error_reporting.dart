// lib/core/debug/arin_error_reporting.dart
// Gri/boş ekran teşhisi: logcat'te "ARIN" ile filtreleyin.

import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logcat / konsol: `adb logcat | findstr ARIN` (Windows)
const String _tag = '══ ARIN ══';

/// Firebase init edildikten sonra [enableCrashlyticsIntegration] ile true olur;
/// bu flag olmadan `FirebaseCrashlytics.instance` çağrısı Firebase henüz hazır
/// değilken hata fırlatırdı.
bool _crashlyticsReady = false;

/// Firebase hazır olduktan sonra (main.dart'ta bootstrapFirebase sonrası)
/// çağrılır. Crashlytics artık global hata kancalarını dinler.
void enableCrashlyticsIntegration() {
  _crashlyticsReady = true;
}

/// Çağrı: [WidgetsFlutterBinding.ensureInitialized] hemen sonrası, `runApp` öncesi.
void setupArinErrorReporting() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('$_tag FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint('$_tag Stack:\n${details.stack}');
    }
    if (_crashlyticsReady) {
      // recordFlutterFatalError: release build'de, collection enabled ise
      // Firebase Console'da "Crash" olarak sayılır. Debug/dev'de biz zaten
      // setCrashlyticsCollectionEnabled(false) yapıyoruz → spam olmaz.
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('$_tag PlatformDispatcher: $error');
    debugPrint('$_tag Stack:\n$stack');
    if (_crashlyticsReady) {
      FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: true);
    }
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    debugPrint('$_tag ErrorWidget: $msg');
    if (details.stack != null) {
      debugPrint('$_tag Stack:\n${details.stack}');
    }
    // Release build: son kullanıcıya teknik hata metni / stack trace
    // göstermek Play/App Store yorum puanını ve ilk izlenimi zedeler;
    // ayrıca bilgi sızıntısı riski taşır. Hata zaten yukarıda Crashlytics'e
    // fatal olarak gönderilmiş durumda — kullanıcıya yalnızca nazik bir
    // mesaj yeterli. Debug build'de geliştiricinin anında görüp kopyalaması
    // için mevcut teknik görünüm korunur.
    if (kReleaseMode) {
      return const _ArinFriendlyErrorScreen();
    }
    return _ArinDebugErrorScreen(message: msg);
  };
}

class _ArinFriendlyErrorScreen extends StatelessWidget {
  const _ArinFriendlyErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFF0D2F32),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 56,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bir şeyler ters gitti',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bu bölüm şu an açılamadı. '
                    'Uygulamayı kapatıp tekrar açmayı deneyebilirsin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArinDebugErrorScreen extends StatelessWidget {
  const _ArinDebugErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFF1A1A1A),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report,
                        color: Colors.red.shade300, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'ARIN — widget hatası (debug)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Debug moddasınız. Aşağıdaki metni kopyalayın.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade800),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        message,
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Riverpod async/sync provider hatalarını loglar.
class ArinProviderObserver extends ProviderObserver {
  const ArinProviderObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();
    debugPrint('$_tag ProviderError [$name]: $error');
    debugPrint('$_tag Stack:\n$stackTrace');
    if (_crashlyticsReady) {
      // Provider hataları non-fatal: uygulama çökmüyor ama bir state akışı
      // bozuldu — Console'da ayrı kategoride görünür.
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Riverpod provider failed: $name',
        fatal: false,
      );
    }
  }
}
