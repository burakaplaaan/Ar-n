// lib/data/services/auth_service.dart

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../firebase_options.dart';
import 'purchase_service.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get canUseFirebase => isFirebaseReady;

  /// iOS / macOS: Apple ile giriş. Diğer platformlarda false döner.
  bool get appleSignInAvailable {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  static bool _googleInitialized = false;

  Future<void> _ensureGoogleSignIn() async {
    if (_googleInitialized) return;

    final webClientId = DefaultFirebaseOptions.googleOAuthWebClientIdForAndroid;
    final iosClientId = DefaultFirebaseOptions.googleOAuthIosClientId;

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (webClientId.isEmpty) {
        throw StateError(
          'Android Google girişi: Web istemci kimliği yok. '
          'Firebase Console → Authentication → Google → Web client ID değerini '
          'lib/firebase_options.dart dosyasındaki googleOAuthWebClientIdLiteral '
          'sabitine yapıştırın veya derlerken '
          '--dart-define=GOOGLE_OAUTH_WEB_CLIENT_ID=... kullanın.',
        );
      }
      await GoogleSignIn.instance.initialize(serverClientId: webClientId);
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await GoogleSignIn.instance.initialize(
        clientId: iosClientId.isEmpty ? null : iosClientId,
        serverClientId: webClientId.isEmpty ? null : webClientId,
      );
    } else {
      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId.isEmpty ? null : webClientId,
      );
    }
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!canUseFirebase) {
      throw StateError('Firebase yapılandırılmadı.');
    }
    await _ensureGoogleSignIn();
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>['email', 'profile'],
      );
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw StateError('Google kimlik jetonu alınamadı.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw StateError('Google girişi iptal edildi.');
      }
      rethrow;
    }
  }

  Future<UserCredential> signInWithApple() async {
    if (!canUseFirebase) {
      throw StateError('Firebase yapılandırılmadı.');
    }
    if (!appleSignInAvailable) {
      throw UnsupportedError('Apple ile giriş yalnızca Apple platformlarında.');
    }
    final rawNonce = _randomNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw StateError('Apple identity token alınamadı.');
    }
    _debugLogAppleTokenDiagnostics(idToken: idToken, hashedNonce: nonce);
    final oauthCredential = _appleCredential(
      idToken: idToken,
      rawNonce: rawNonce,
      givenName: appleCredential.givenName,
      familyName: appleCredential.familyName,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple ad/soyad bilgisini YALNIZCA ilk girişte döner; Firebase
    // Apple credential bu alanları otomatik `user.displayName`'e yazmaz.
    // Burada bir kez yakalayıp kalıcı olarak kullanıcı profiline yazıyoruz —
    // aksi halde kullanıcı ayarlar/profil ekranında "Merhaba, …" boş görür.
    await _maybeAttachAppleDisplayName(
      userCredential.user,
      given: appleCredential.givenName,
      family: appleCredential.familyName,
    );

    return userCredential;
  }

  Future<void> _maybeAttachAppleDisplayName(
    User? user, {
    String? given,
    String? family,
  }) async {
    if (user == null) return;
    // Zaten bir displayName varsa dokunma: Apple "ikinci kez" null gönderdiğinde
    // mevcut ismi silmemeliyiz.
    if ((user.displayName ?? '').trim().isNotEmpty) return;
    final parts = <String>[
      if ((given ?? '').trim().isNotEmpty) given!.trim(),
      if ((family ?? '').trim().isNotEmpty) family!.trim(),
    ];
    if (parts.isEmpty) return;
    final fullName = parts.join(' ');
    try {
      await user.updateDisplayName(fullName);
      await user.reload();
    } catch (e) {
      // Ağ kesintisi / token süresi — isim bir sonraki girişte yine denenir.
      // Uygulama akışını burada kesmek kullanıcıya hiçbir şey kazandırmaz.
      debugPrint('AuthService: Apple displayName update failed: $e');
    }
  }

  Future<void> signOut() async {
    // RevenueCat oturumunu önce kapat ki auth null emit edildiğinde
    // provider tarafı eski RC kullanıcısının entitlement'ını okumaya devam etmesin.
    await PurchaseService.logoutUser();
    await _auth.signOut();
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
  }

  /// Federated sağlayıcı (Google / Apple) için yeniden doğrulama.
  /// `User.delete()` Firebase güvenlik kuralı gereği son girişin yakın zamanda
  /// olmasını istiyor; Google hesabıyla 30+ gün önce giriş yapmış kullanıcı
  /// aksi halde hesabını silemez (`requires-recent-login`).
  /// İptal durumunda `StateError` fırlatır ki UI kullanıcı iptalini ayırt edebilsin.
  Future<void> reauthenticateCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) {
      throw StateError('Oturum açık değil.');
    }
    final providerIds = u.providerData
        .map((p) => p.providerId)
        .toList(growable: false);

    if (providerIds.contains('google.com')) {
      await _ensureGoogleSignIn();
      try {
        final account = await GoogleSignIn.instance.authenticate(
          scopeHint: const <String>['email', 'profile'],
        );
        final idToken = account.authentication.idToken;
        if (idToken == null) {
          throw StateError('Google kimlik jetonu alınamadı (reauth).');
        }
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await u.reauthenticateWithCredential(credential);
        return;
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          throw StateError('Yeniden doğrulama iptal edildi.');
        }
        rethrow;
      }
    }

    if (providerIds.contains('apple.com') && appleSignInAvailable) {
      final rawNonce = _randomNonce();
      final nonce = _sha256ofString(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw StateError('Apple identity token alınamadı (reauth).');
      }
      _debugLogAppleTokenDiagnostics(idToken: idToken, hashedNonce: nonce);
      final oauthCredential = _appleCredential(
        idToken: idToken,
        rawNonce: rawNonce,
        givenName: appleCredential.givenName,
        familyName: appleCredential.familyName,
      );
      await u.reauthenticateWithCredential(oauthCredential);
      return;
    }

    throw StateError(
      'Yeniden doğrulama için desteklenen sağlayıcı bulunamadı '
      '(${providerIds.join(", ")}).',
    );
  }

  /// Son giriş çok eskiyse [requires-recent-login] hatasında otomatik olarak
  /// [reauthenticateCurrentUser] çağrılır ve silme bir kez daha denenir.
  /// Bu sayede kullanıcı uzun zamandır girmemiş olsa bile akış kesintisiz ilerler.
  Future<void> deleteAccount() async {
    final u = _auth.currentUser;
    if (u == null) {
      throw StateError('Oturum açık değil.');
    }
    try {
      // Firebase user null emit etmeden önce RC'yi anonim profile döndür.
      await PurchaseService.logoutUser();
      await u.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        rethrow;
      }
      await reauthenticateCurrentUser();
      final fresh = _auth.currentUser;
      if (fresh == null) {
        throw StateError(
          'Yeniden doğrulama sonrası oturum bulunamadı; lütfen tekrar deneyin.',
        );
      }
      await PurchaseService.logoutUser();
      await fresh.delete();
    }
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
  }

  static String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static OAuthCredential _appleCredential({
    required String idToken,
    required String rawNonce,
    String? givenName,
    String? familyName,
  }) {
    return AppleAuthProvider.credentialWithIDToken(
      idToken,
      rawNonce,
      AppleFullPersonName(givenName: givenName, familyName: familyName),
    );
  }

  static void _debugLogAppleTokenDiagnostics({
    required String idToken,
    required String hashedNonce,
  }) {
    assert(() {
      try {
        final parts = idToken.split('.');
        if (parts.length < 2) return true;
        final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])),
        );
        final claims = jsonDecode(payload);
        if (claims is! Map<String, dynamic>) return true;
        final audience = claims['aud'];
        final nonceClaim = claims['nonce'];
        debugPrint(
          'AuthService: Apple token aud=$audience, '
          'expectedAud=${DefaultFirebaseOptions.ios.iosBundleId}, '
          'nonceMatch=${nonceClaim == hashedNonce}',
        );
      } catch (e) {
        debugPrint('AuthService: Apple token diagnostics failed: $e');
      }
      return true;
    }());
  }
}
