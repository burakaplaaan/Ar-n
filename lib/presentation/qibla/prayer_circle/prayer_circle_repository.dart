import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../data/services/product_metrics_service.dart';

class PrayerCircleRequest {
  const PrayerCircleRequest({
    required this.id,
    required this.text,
    required this.category,
    required this.prayerCount,
    required this.createdAt,
    required this.expiresAt,
    required this.isMine,
    this.isPrayed = false,
  });

  final String id;
  final String text;
  final String category;
  final int prayerCount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isMine;

  /// Bu cihaz/hesap daha önce bu talebe eşlik etti mi — sunucudan değil,
  /// yerel `_prayedKey` önbelleğinden gelir (bkz. [PrayerCircleRepository]).
  /// Uygulama yeniden başlatıldığında "Dua ettim" butonunun gereksiz yere
  /// tekrar aktif görünmesini engeller.
  final bool isPrayed;

  Duration get remaining => expiresAt.difference(DateTime.now());

  PrayerCircleRequest copyWith({int? prayerCount, bool? isPrayed}) {
    return PrayerCircleRequest(
      id: id,
      text: text,
      category: category,
      prayerCount: prayerCount ?? this.prayerCount,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isMine: isMine,
      isPrayed: isPrayed ?? this.isPrayed,
    );
  }
}

class PrayerActionResult {
  const PrayerActionResult({required this.counted, required this.prayerCount});

  final bool counted;
  final int prayerCount;
}

class PrayerFeedPage {
  const PrayerFeedPage({
    required this.items,
    this.nextCursorExpiresAtMs,
    this.nextCursorRequestId,
  });

  final List<PrayerCircleRequest> items;
  final int? nextCursorExpiresAtMs;
  final String? nextCursorRequestId;
}

class PrayerSubmissionGate {
  const PrayerSubmissionGate({
    required this.premium,
    this.proofId,
    this.serverSideCustomData,
  });

  final bool premium;
  final String? proofId;
  final String? serverSideCustomData;
}

class PrayerCircleRepository {
  PrayerCircleRepository({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
    FirebaseMessaging? messaging,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: _functionsRegion),
       _messaging = messaging ?? FirebaseMessaging.instance;

  static const _functionsRegion = 'europe-west1';
  static const _mineKey = 'arin_prayer_circle_request_ids_v1';
  static const _reportedKey = 'arin_prayer_circle_reported_ids_v1';
  static const _prayedKey = 'arin_prayer_circle_prayed_ids_v1';
  static const _bindingSecretKey = 'arin_prayer_circle_binding_secret_v1';
  static const _policyVersion = 1;

  /// Talepler sunucuda 24 saatte silindiği için yerel "eşlik ettim"
  /// önbelleğini bir süre sonra (tampon payıyla) temizliyoruz; aksi halde
  /// cihazda süresi dolmuş id'ler sonsuza kadar birikir.
  static const _prayedRetention = Duration(hours: 48);

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;
  Future<String>? _bindingSecretFuture;

  Future<PrayerFeedPage> loadActiveRequests({
    int? cursorExpiresAtMs,
    String? cursorRequestId,
    String? focusRequestId,
    bool mineOnly = false,
  }) async {
    final credentials = await _requiredInstallationCredentials();
    final result = await _functions.httpsCallable('listPrayerRequests').call({
      ...credentials,
      if (cursorExpiresAtMs != null) 'cursorExpiresAtMs': cursorExpiresAtMs,
      if (cursorRequestId != null) 'cursorRequestId': cursorRequestId,
      if (focusRequestId != null) 'focusRequestId': focusRequestId,
      if (mineOnly) 'mineOnly': true,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final mine = await _localRequestIds();
    final reported = await _localReportedIds();
    final prayed = await _loadPrayedMap();
    final items = ((data['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw);
          final id = item['id']?.toString() ?? '';
          final createdAtMs = (item['createdAtMs'] as num?)?.toInt() ?? 0;
          final expiresAtMs = (item['expiresAtMs'] as num?)?.toInt() ?? 0;
          return PrayerCircleRequest(
            id: id,
            text: item['text']?.toString().trim() ?? '',
            category: item['category']?.toString() ?? 'general',
            prayerCount: (item['prayerCount'] as num?)?.toInt() ?? 0,
            createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
            expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMs),
            isMine: item['isMine'] == true || mine.contains(id),
            isPrayed: prayed.containsKey(id),
          );
        })
        .where(
          (request) =>
              request.id.isNotEmpty &&
              request.text.isNotEmpty &&
              !reported.contains(request.id),
        )
        .toList(growable: false);
    return PrayerFeedPage(
      items: items,
      nextCursorExpiresAtMs: (data['nextCursorExpiresAtMs'] as num?)?.toInt(),
      nextCursorRequestId: data['nextCursorRequestId']?.toString(),
    );
  }

  Future<PrayerSubmissionGate> beginSubmission({
    required String text,
    required String category,
    required String locale,
    required String clientRequestId,
  }) async {
    final credentials = await _requiredInstallationCredentials();
    final result = await _functions
        .httpsCallable('beginPrayerSubmission')
        .call({
          ...credentials,
          'requestId': clientRequestId,
          'text': text,
          'category': category,
          'locale': locale,
          'policyVersion': _policyVersion,
        });
    final data = Map<String, dynamic>.from(result.data as Map);
    return PrayerSubmissionGate(
      premium: data['premium'] == true,
      proofId: data['proofId']?.toString(),
      serverSideCustomData: data['customData']?.toString(),
    );
  }

  Future<bool> isPremiumForPrayer() async {
    final credentials = await _requiredInstallationCredentials();
    final result = await _functions
        .httpsCallable('checkPrayerPremium')
        .call(credentials);
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['premium'] == true;
  }

  Future<String> createRequest({
    required String text,
    required String category,
    required String locale,
    required String clientRequestId,
    String? proofId,
  }) async {
    final credentials = await _requiredInstallationCredentials();
    HttpsCallableResult<dynamic>? result;
    for (var attempt = 0; attempt < 9; attempt++) {
      try {
        result = await _functions.httpsCallable('createPrayerRequest').call({
          ...credentials,
          'requestId': clientRequestId,
          'text': text,
          'category': category,
          'locale': locale,
          'policyVersion': _policyVersion,
          if (proofId != null) 'proofId': proofId,
        });
        break;
      } on FirebaseFunctionsException catch (error) {
        final rewardMayBePending =
            proofId != null && error.code == 'failed-precondition';
        if (!rewardMayBePending || attempt == 8) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    if (result == null) {
      throw StateError('Dua talebi oluşturulamadı.');
    }
    final data = Map<String, dynamic>.from(result.data as Map);
    final id = data['id']?.toString() ?? '';
    if (id.isEmpty) throw StateError('Dua talebi kimliği alınamadı.');
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_mineKey) ?? const <String>[]).toSet()
      ..add(id);
    await prefs.setStringList(_mineKey, ids.toList(growable: false));
    return id;
  }

  Future<PrayerActionResult> prayFor(String requestId) async {
    final credentials = await _requiredInstallationCredentials();
    final result = await _functions.httpsCallable('prayForRequest').call({
      ...credentials,
      'requestId': requestId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    // `counted: false` da "zaten eşlik ettin" anlamına gelir — her iki
    // durumda da yerelde işaretleyip bir dahaki açılışta butonun doğru
    // (Eşlik ettin) görünmesini sağlıyoruz.
    await _markPrayed(requestId);
    return PrayerActionResult(
      counted: data['counted'] == true,
      prayerCount: (data['prayerCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<bool> reportRequest(String requestId) async {
    final credentials = await _requiredInstallationCredentials();
    final result = await _functions.httpsCallable('reportPrayerRequest').call({
      ...credentials,
      'requestId': requestId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final reported = data['reported'] == true;
    if (reported) {
      final prefs = await SharedPreferences.getInstance();
      final ids =
          (prefs.getStringList(_reportedKey) ?? const <String>[]).toSet()
            ..add(requestId);
      await prefs.setStringList(_reportedKey, ids.toList(growable: false));
    }
    return reported;
  }

  Future<void> deleteRequest(String requestId) async {
    final credentials = await _requiredInstallationCredentials();
    await _functions.httpsCallable('deletePrayerRequest').call({
      ...credentials,
      'requestId': requestId,
    });
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_mineKey) ?? const <String>[]).toSet()
      ..remove(requestId);
    await prefs.setStringList(_mineKey, ids.toList(growable: false));
  }

  /// Yönetici moderasyon silmesi — sahiplik farketmeksizin. Sunucu tarafında
  /// gerçek oturum açmış admin e-postası veya `admin_users` rolü kontrol
  /// edilir; kurulum kimlik bilgisi gerektirmez.
  Future<void> adminDeleteRequest(String requestId) async {
    await _functions.httpsCallable('adminDeletePrayerRequest').call({
      'requestId': requestId,
    });
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_mineKey) ?? const <String>[]).toSet()
      ..remove(requestId);
    await prefs.setStringList(_mineKey, ids.toList(growable: false));
  }

  Future<void> syncNotificationDevice(String locale) async {
    if (!isFirebaseReady) return;
    try {
      final credentials = await _requiredInstallationCredentials();
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return;
      await _registerNotificationToken(
        credentials: credentials,
        token: token,
        locale: locale,
      );
      _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
        (freshToken) => _registerNotificationToken(
          credentials: credentials,
          token: freshToken,
          locale: locale,
        ),
      );
    } catch (error) {
      debugPrint('PrayerCircleRepository device sync deferred: $error');
    }
  }

  Future<void> _registerNotificationToken({
    required Map<String, String> credentials,
    required String token,
    required String locale,
  }) async {
    try {
      await _functions.httpsCallable('registerPrayerDevice').call({
        ...credentials,
        'token': token,
        'locale': locale,
        'platform': switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => 'other',
        },
      });
    } catch (error) {
      debugPrint('PrayerCircleRepository token refresh deferred: $error');
    }
  }

  Future<Set<String>> _localRequestIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_mineKey) ?? const <String>[]).toSet();
  }

  Future<Set<String>> _localReportedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_reportedKey) ?? const <String>[]).toSet();
  }

  /// `{requestId: eşlikEttiğiZamanMs}` haritasını okur; okuma sırasında
  /// [_prayedRetention] süresini aşmış kayıtları eler ve (bir şey silindiyse)
  /// temizlenmiş halini geri yazar. Böylece süresi çoktan dolmuş dua
  /// talepleri cihazda sonsuza kadar birikmez.
  Future<Map<String, int>> _loadPrayedMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prayedKey);
    if (raw == null || raw.isEmpty) return {};
    Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map) return {};
      decoded = Map<String, dynamic>.from(parsed);
    } catch (error) {
      debugPrint('PrayerCircleRepository: prayed cache corrupt: $error');
      return {};
    }
    final cutoffMs = DateTime.now()
        .subtract(_prayedRetention)
        .millisecondsSinceEpoch;
    final pruned = <String, int>{};
    var removedAny = false;
    decoded.forEach((id, value) {
      final ts = (value as num?)?.toInt() ?? 0;
      if (ts >= cutoffMs) {
        pruned[id] = ts;
      } else {
        removedAny = true;
      }
    });
    if (removedAny) {
      await prefs.setString(_prayedKey, jsonEncode(pruned));
    }
    return pruned;
  }

  Future<void> _markPrayed(String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _loadPrayedMap();
    current[requestId] = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(_prayedKey, jsonEncode(current));
  }

  Future<String> _requiredInstallId(String bindingSecret) async {
    if (!isFirebaseReady) {
      throw StateError('Firebase hazır değil.');
    }
    final installId = await ProductMetricsService.getOrCreateInstallId();
    if (installId == null || installId.isEmpty) {
      throw StateError('Kurulum kimliği oluşturulamadı.');
    }
    if (_auth.currentUser == null) {
      final result = await _functions.httpsCallable('createPrayerSession').call(
        {'installId': installId, 'bindingSecret': bindingSecret},
      );
      final data = Map<String, dynamic>.from(result.data as Map);
      final customToken = data['customToken']?.toString() ?? '';
      if (customToken.isEmpty) {
        throw StateError('Güvenli oturum oluşturulamadı.');
      }
      await _auth.signInWithCustomToken(customToken);
    }
    if (_auth.currentUser == null) {
      throw StateError('Güvenli oturum oluşturulamadı.');
    }
    return installId;
  }

  Future<Map<String, String>> _requiredInstallationCredentials() async {
    final bindingSecret = await _requiredBindingSecret();
    final installId = await _requiredInstallId(bindingSecret);
    return {'installId': installId, 'bindingSecret': bindingSecret};
  }

  Future<String> _requiredBindingSecret() {
    return _bindingSecretFuture ??= _loadOrCreateBindingSecret();
  }

  Future<String> _loadOrCreateBindingSecret() async {
    final prefs = await SharedPreferences.getInstance();
    var bindingSecret = prefs.getString(_bindingSecretKey)?.trim() ?? '';
    if (bindingSecret.length < 32) {
      bindingSecret = const Uuid().v4().replaceAll('-', '');
      await prefs.setString(_bindingSecretKey, bindingSecret);
    }
    return bindingSecret;
  }
}
