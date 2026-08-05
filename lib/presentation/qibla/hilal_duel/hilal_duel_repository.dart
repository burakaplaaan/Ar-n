import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../data/services/product_metrics_service.dart';
import '../../../data/services/purchase_service.dart';

/// Cached quiz credentials are invalid once Firebase [currentUser] is gone
/// (sign-out / account transition). Recreate session; never implies overwriting
/// an existing Google/Apple user (caller only custom-token signs in when null).
bool shouldRefreshQuizCredentialsCache({
  required bool hasCachedSession,
  required bool hasCurrentUser,
}) {
  return hasCachedSession && !hasCurrentUser;
}

class HilalDuelProfile {
  const HilalDuelProfile({
    required this.name,
    required this.hilals,
    required this.level,
    required this.levelFloorHilals,
    required this.nextLevelHilals,
    required this.hearts,
    required this.premium,
    this.maxLevel = false,
    this.weeklyHilals = 0,
    this.weeklyRank = 0,
    this.title,
    this.avatarFrame = false,
    this.specialHilalIcon = false,
    this.nameAccent = false,
  });

  final String name;
  final int hilals;
  final int level;
  final int levelFloorHilals;
  final int nextLevelHilals;
  final int hearts;
  final bool premium;
  final bool maxLevel;
  final int weeklyHilals;
  final int weeklyRank;
  final String? title;
  final bool avatarFrame;
  final bool specialHilalIcon;
  final bool nameAccent;

  double get levelProgress {
    if (maxLevel || nextLevelHilals <= levelFloorHilals) return 1;
    final span = nextLevelHilals - levelFloorHilals;
    final safeHilals = hilals < 0 ? 0 : hilals;
    return ((safeHilals - levelFloorHilals) / span).clamp(0, 1);
  }

  factory HilalDuelProfile.fromMap(Map<String, dynamic> map) {
    return HilalDuelProfile(
      name: map['name']?.toString() ?? 'Arın Oyuncusu',
      hilals: (map['hilals'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      levelFloorHilals: (map['levelFloorHilals'] as num?)?.toInt() ?? 0,
      nextLevelHilals: (map['nextLevelHilals'] as num?)?.toInt() ?? 40,
      hearts: (map['hearts'] as num?)?.toInt() ?? 0,
      premium: map['premium'] == true,
      maxLevel: map['maxLevel'] == true,
      weeklyHilals: (map['weeklyHilals'] as num?)?.toInt() ?? 0,
      weeklyRank: (map['weeklyRank'] as num?)?.toInt() ?? 0,
      title: map['title']?.toString(),
      avatarFrame: map['avatarFrame'] == true,
      specialHilalIcon: map['specialHilalIcon'] == true,
      nameAccent: map['nameAccent'] == true,
    );
  }
}

class HilalDuelPlayer {
  const HilalDuelPlayer({
    required this.id,
    required this.name,
    required this.hilals,
    required this.level,
    required this.isBot,
    this.badge,
    this.title,
    this.avatarFrame = false,
    this.specialHilalIcon = false,
    this.nameAccent = false,
  });

  final String id;
  final String name;
  final int hilals;
  final int level;
  final bool isBot;
  final String? badge;
  final String? title;
  final bool avatarFrame;
  final bool specialHilalIcon;
  final bool nameAccent;

  factory HilalDuelPlayer.fromMap(Map<String, dynamic> map) {
    return HilalDuelPlayer(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Oyuncu',
      hilals: (map['hilals'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      isBot: map['isBot'] == true,
      badge: map['badge']?.toString(),
      title: map['title']?.toString(),
      avatarFrame: map['avatarFrame'] == true,
      specialHilalIcon: map['specialHilalIcon'] == true,
      nameAccent: map['nameAccent'] == true,
    );
  }
}

class HilalDuelWeeklyEntry {
  const HilalDuelWeeklyEntry({
    required this.rank,
    required this.name,
    required this.weeklyHilals,
    required this.level,
    required this.isSelf,
    this.title,
    this.avatarFrame = false,
    this.specialHilalIcon = false,
    this.nameAccent = false,
  });

  final int rank;
  final String name;
  final int weeklyHilals;
  final int level;
  final bool isSelf;
  final String? title;
  final bool avatarFrame;
  final bool specialHilalIcon;
  final bool nameAccent;

  factory HilalDuelWeeklyEntry.fromMap(Map<String, dynamic> map) {
    return HilalDuelWeeklyEntry(
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? 'Oyuncu',
      weeklyHilals: (map['weeklyHilals'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      isSelf: map['isSelf'] == true,
      title: map['title']?.toString(),
      avatarFrame: map['avatarFrame'] == true,
      specialHilalIcon: map['specialHilalIcon'] == true,
      nameAccent: map['nameAccent'] == true,
    );
  }
}

class HilalDuelWeeklyBoard {
  const HilalDuelWeeklyBoard({
    required this.weekId,
    required this.top,
    required this.selfWeeklyHilals,
    required this.selfRank,
  });

  final String weekId;
  final List<HilalDuelWeeklyEntry> top;
  final int selfWeeklyHilals;
  final int selfRank;

  factory HilalDuelWeeklyBoard.fromMap(Map<String, dynamic> map) {
    return HilalDuelWeeklyBoard(
      weekId: map['weekId']?.toString() ?? '',
      top: ((map['top'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                HilalDuelWeeklyEntry.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      selfWeeklyHilals:
          ((map['self'] as Map?)?['weeklyHilals'] as num?)?.toInt() ?? 0,
      selfRank: ((map['self'] as Map?)?['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

class HilalDuelQuestion {
  const HilalDuelQuestion({
    required this.id,
    required this.category,
    required this.text,
    required this.options,
    this.correctIndex,
    this.explanation,
    this.source,
  });

  final String id;
  final String category;
  final String text;
  final List<String> options;
  final int? correctIndex;
  final String? explanation;
  final String? source;

  factory HilalDuelQuestion.fromMap(Map<String, dynamic> map) {
    return HilalDuelQuestion(
      id: map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? 'İslamiyet',
      text: map['question']?.toString() ?? '',
      options: ((map['options'] as List?) ?? const [])
          .map((option) => option.toString())
          .toList(growable: false),
      correctIndex: (map['correctIndex'] as num?)?.toInt(),
      explanation: map['explanation']?.toString(),
      source: map['source']?.toString(),
    );
  }
}

class HilalDuelResolution {
  const HilalDuelResolution({
    required this.round,
    required this.question,
    required this.choices,
    required this.elapsedMs,
  });

  final int round;
  final HilalDuelQuestion question;
  final Map<String, int> choices;
  final Map<String, int> elapsedMs;

  factory HilalDuelResolution.fromMap(Map<String, dynamic> map) {
    final rawChoices = Map<String, dynamic>.from(
      (map['choices'] as Map?) ?? const {},
    );
    final rawElapsed = Map<String, dynamic>.from(
      (map['elapsedMs'] as Map?) ?? const {},
    );
    return HilalDuelResolution(
      round: (map['round'] as num?)?.toInt() ?? 0,
      question: HilalDuelQuestion.fromMap(
        Map<String, dynamic>.from((map['question'] as Map?) ?? const {}),
      ),
      choices: rawChoices.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? -1),
      ),
      elapsedMs: rawElapsed.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
    );
  }
}

class HilalDuelPlayerResult {
  const HilalDuelPlayerResult({
    required this.id,
    required this.correct,
    required this.elapsedMs,
    required this.hilalsAwarded,
  });

  final String id;
  final int correct;
  final int elapsedMs;
  final int hilalsAwarded;

  factory HilalDuelPlayerResult.fromMap(Map<String, dynamic> map) {
    return HilalDuelPlayerResult(
      id: map['id']?.toString() ?? '',
      correct: (map['correct'] as num?)?.toInt() ?? 0,
      elapsedMs: (map['elapsedMs'] as num?)?.toInt() ?? 0,
      hilalsAwarded: (map['hilalsAwarded'] as num?)?.toInt() ?? 0,
    );
  }
}

class HilalDuelResult {
  const HilalDuelResult({required this.winnerId, required this.players});

  final String? winnerId;
  final List<HilalDuelPlayerResult> players;

  factory HilalDuelResult.fromMap(Map<String, dynamic> map) {
    return HilalDuelResult(
      winnerId: map['winnerId']?.toString(),
      players: ((map['players'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                HilalDuelPlayerResult.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }
}

class HilalDuelMatch {
  const HilalDuelMatch({
    required this.id,
    required this.status,
    required this.version,
    required this.currentRound,
    required this.totalRounds,
    required this.roundStartedAtMs,
    required this.deadlineMs,
    required this.self,
    required this.opponent,
    required this.selfAnswered,
    required this.opponentAnswered,
    this.doubled = false,
    this.question,
    this.lastResolution,
    this.result,
  });

  final String id;
  final String status;
  final int version;
  final int currentRound;
  final int totalRounds;
  final int roundStartedAtMs;
  final int deadlineMs;
  final HilalDuelPlayer self;
  final HilalDuelPlayer opponent;
  final bool selfAnswered;
  final bool opponentAnswered;
  final bool doubled;
  final HilalDuelQuestion? question;
  final HilalDuelResolution? lastResolution;
  final HilalDuelResult? result;

  bool get isCompleted => status == 'completed';

  factory HilalDuelMatch.fromMap(Map<String, dynamic> map) {
    final rawResolution = map['lastResolution'];
    final rawResult = map['result'];
    final rawQuestion = map['question'];
    return HilalDuelMatch(
      id: map['id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'playing',
      version: (map['version'] as num?)?.toInt() ?? 0,
      currentRound: (map['currentRound'] as num?)?.toInt() ?? 0,
      totalRounds: (map['totalRounds'] as num?)?.toInt() ?? 7,
      roundStartedAtMs: (map['roundStartedAtMs'] as num?)?.toInt() ?? 0,
      deadlineMs: (map['deadlineMs'] as num?)?.toInt() ?? 0,
      self: HilalDuelPlayer.fromMap(
        Map<String, dynamic>.from((map['self'] as Map?) ?? const {}),
      ),
      opponent: HilalDuelPlayer.fromMap(
        Map<String, dynamic>.from((map['opponent'] as Map?) ?? const {}),
      ),
      selfAnswered: map['selfAnswered'] == true,
      opponentAnswered: map['opponentAnswered'] == true,
      doubled: map['doubled'] == true,
      question: rawQuestion is Map
          ? HilalDuelQuestion.fromMap(Map<String, dynamic>.from(rawQuestion))
          : null,
      lastResolution: rawResolution is Map
          ? HilalDuelResolution.fromMap(
              Map<String, dynamic>.from(rawResolution),
            )
          : null,
      result: rawResult is Map
          ? HilalDuelResult.fromMap(Map<String, dynamic>.from(rawResult))
          : null,
    );
  }
}

class HilalDuelProfileBundle {
  const HilalDuelProfileBundle({required this.profile, this.queue});

  final HilalDuelProfile profile;
  final HilalDuelMatchStart? queue;
}

class HilalDuelRewardProof {
  const HilalDuelRewardProof({
    required this.proofId,
    required this.customData,
    required this.expiresAtMs,
  });

  final String proofId;
  final String customData;
  final int expiresAtMs;
}

class HilalDuelMatchStart {
  const HilalDuelMatchStart({
    required this.status,
    this.matchId,
    this.queuedAtMs,
    this.refunded = false,
  });

  final String status;
  final String? matchId;
  final int? queuedAtMs;
  final bool refunded;

  bool get matched => status == 'matched' && matchId != null;
  bool get waiting => status == 'waiting';
}

/// Quiz callable API — controller tests inject fakes via this surface.
abstract class HilalDuelRepositoryApi {
  Future<HilalDuelProfileBundle> loadProfile(String name);
  Future<HilalDuelRewardProof> beginReward({
    required String purpose,
    String? matchId,
  });
  Future<void> claimReward(String proofId);
  Future<HilalDuelMatchStart> startMatch(String name);
  Future<HilalDuelMatchStart> cancelMatchmaking();
  Future<HilalDuelMatchStart> pollMatch();
  Future<HilalDuelMatch> loadMatch(String matchId);
  Future<HilalDuelMatch> submitAnswer({
    required String matchId,
    required int round,
    required int choice,
  });
  Future<HilalDuelMatch> forfeitMatch(String matchId);
  Future<HilalDuelWeeklyBoard> loadWeeklyLeaderboard();
  void clearCredentialsCache();
}

class HilalDuelRepository implements HilalDuelRepositoryApi {
  HilalDuelRepository({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: _functionsRegion),
      _auth = auth ?? FirebaseAuth.instance;

  static const _functionsRegion = 'europe-west1';
  static const _bindingSecretKey = 'arin_hilal_duel_binding_secret_v1';

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  Future<Map<String, String>>? _credentialsFuture;
  StreamSubscription<String>? _tokenRefreshSubscription;

  @override
  Future<HilalDuelProfileBundle> loadProfile(String name) async {
    final credentials = await _credentials();
    var result = await _call('getQuizProfile', {
      ...credentials,
      'name': _safeName(name),
    });
    if (HilalDuelProfile.fromMap(
          Map<String, dynamic>.from((result['profile'] as Map?) ?? const {}),
        ).premium ==
        false) {
      result = await _waitForVerifiedPremium(
        result: result,
        credentials: credentials,
        name: name,
      );
    }
    final rawQueue = result['queue'];
    return HilalDuelProfileBundle(
      profile: HilalDuelProfile.fromMap(
        Map<String, dynamic>.from((result['profile'] as Map?) ?? const {}),
      ),
      queue: rawQueue is Map
          ? _startFromMap(Map<String, dynamic>.from(rawQueue))
          : null,
    );
  }

  Future<Map<String, dynamic>> _waitForVerifiedPremium({
    required Map<String, dynamic> result,
    required Map<String, String> credentials,
    required String name,
  }) async {
    try {
      final purchases = PurchaseService();
      final uid = _auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) return result;

      // Anonim RevenueCat satın alımını stabil quiz Firebase UID'sine bağla.
      // Sınırsız hak yalnız RevenueCat webhook'u sunucuda entitlement yazınca
      // açılır; istemciden gelen Premium iddiasına güvenilmez.
      await PurchaseService.initialize(firebaseUid: uid);
      if (!await purchases.isPremiumLocally()) return result;
      final local = await purchases.getLocalPremiumEntitlement(
        expectedFirebaseUid: uid,
      );
      if (local?.isActive != true) return result;

      for (var attempt = 0; attempt < 6; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        final refreshed = await _call('getQuizProfile', {
          ...credentials,
          'name': _safeName(name),
        });
        final profile = HilalDuelProfile.fromMap(
          Map<String, dynamic>.from(
            (refreshed['profile'] as Map?) ?? const {},
          ),
        );
        result = refreshed;
        if (profile.premium) break;
      }
    } catch (_) {
      // RevenueCat/webhook gecikirse ücretsiz akış çalışmaya devam eder;
      // sonraki profil yenilemesi sunucu entitlement'ını tekrar okur.
    }
    return result;
  }

  @override
  Future<HilalDuelRewardProof> beginReward({
    required String purpose,
    String? matchId,
  }) async {
    final result = await _call('beginQuizReward', {
      ...await _credentials(),
      'purpose': purpose,
      if (matchId != null) 'matchId': matchId,
    });
    return HilalDuelRewardProof(
      proofId: result['proofId']?.toString() ?? '',
      customData: result['customData']?.toString() ?? '',
      expiresAtMs: (result['expiresAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> claimReward(String proofId) async {
    FirebaseFunctionsException? latest;
    for (var attempt = 0; attempt < 9; attempt++) {
      try {
        await _call('claimQuizReward', {
          ...await _credentials(),
          'proofId': proofId,
        });
        return;
      } on FirebaseFunctionsException catch (error) {
        latest = error;
        if (error.code != 'failed-precondition' || attempt == 8) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    throw latest ?? StateError('Reklam ödülü doğrulanamadı.');
  }

  @override
  Future<HilalDuelMatchStart> startMatch(String name) async {
    final result = await _call('startQuizMatch', {
      ...await _credentials(),
      'name': _safeName(name),
    });
    return _startFromMap(result);
  }

  @override
  Future<HilalDuelMatchStart> cancelMatchmaking() async {
    return _startFromMap(
      await _call('cancelQuizMatchmaking', {...await _credentials()}),
    );
  }

  @override
  Future<HilalDuelMatchStart> pollMatch() async {
    return _startFromMap(
      await _call('pollQuizMatch', {...await _credentials()}),
    );
  }

  @override
  Future<HilalDuelMatch> loadMatch(String matchId) async {
    final result = await _call('getQuizMatch', {
      ...await _credentials(),
      'matchId': matchId,
    });
    return HilalDuelMatch.fromMap(
      Map<String, dynamic>.from((result['match'] as Map?) ?? const {}),
    );
  }

  @override
  Future<HilalDuelMatch> submitAnswer({
    required String matchId,
    required int round,
    required int choice,
  }) async {
    final result = await _call('submitQuizAnswer', {
      ...await _credentials(),
      'matchId': matchId,
      'round': round,
      'choice': choice,
    });
    return HilalDuelMatch.fromMap(
      Map<String, dynamic>.from((result['match'] as Map?) ?? const {}),
    );
  }

  @override
  Future<HilalDuelMatch> forfeitMatch(String matchId) async {
    final result = await _call('forfeitQuizMatch', {
      ...await _credentials(),
      'matchId': matchId,
    });
    return HilalDuelMatch.fromMap(
      Map<String, dynamic>.from((result['match'] as Map?) ?? const {}),
    );
  }

  @override
  Future<HilalDuelWeeklyBoard> loadWeeklyLeaderboard() async {
    final result = await _call('getQuizWeeklyLeaderboard', {
      ...await _credentials(),
    });
    return HilalDuelWeeklyBoard.fromMap(result);
  }

  /// Engajman push için FCM token kaydı (en az 1 maç sonrası hatırlatmalar).
  Future<void> syncNotificationDevice(String locale) async {
    if (!isFirebaseReady) return;
    try {
      final credentials = await _credentials();
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
      debugPrint('HilalDuelRepository device sync deferred: $error');
    }
  }

  Future<void> _registerNotificationToken({
    required Map<String, String> credentials,
    required String token,
    required String locale,
  }) async {
    try {
      await _functions.httpsCallable('registerQuizDevice').call({
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
      debugPrint('HilalDuelRepository token refresh deferred: $error');
    }
  }

  HilalDuelMatchStart _startFromMap(Map<String, dynamic> result) {
    return HilalDuelMatchStart(
      status: result['status']?.toString() ?? 'waiting',
      matchId: result['matchId']?.toString(),
      queuedAtMs: (result['queuedAtMs'] as num?)?.toInt(),
      refunded: result['refunded'] == true,
    );
  }

  Future<Map<String, dynamic>> _call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(functionName).call(data);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'unauthenticated') {
        clearCredentialsCache();
      }
      rethrow;
    }
  }

  Future<Map<String, String>> _credentials() async {
    try {
      // Cached session is useless if Firebase user vanished (sign-out / transition).
      if (shouldRefreshQuizCredentialsCache(
        hasCachedSession: _credentialsFuture != null,
        hasCurrentUser: _auth.currentUser != null,
      )) {
        clearCredentialsCache();
      }
      final future = _credentialsFuture ??= _createCredentials();
      final creds = await future;
      // Account may have dropped during create; rebuild without clobbering
      // Google/Apple (custom token only when currentUser == null).
      if (_auth.currentUser == null) {
        clearCredentialsCache();
        final retry = _credentialsFuture ??= _createCredentials();
        return await retry;
      }
      return creds;
    } catch (_) {
      clearCredentialsCache();
      rethrow;
    }
  }

  /// Test / retry: zehirlenmiş oturum Future'ını temizler.
  @override
  void clearCredentialsCache() {
    _credentialsFuture = null;
  }

  Future<Map<String, String>> _createCredentials() async {
    if (!isFirebaseReady) {
      throw StateError('Firebase hazır değil.');
    }
    final prefs = await SharedPreferences.getInstance();
    var bindingSecret = prefs.getString(_bindingSecretKey)?.trim() ?? '';
    if (bindingSecret.length < 32) {
      bindingSecret = const Uuid().v4().replaceAll('-', '');
      await prefs.setString(_bindingSecretKey, bindingSecret);
    }
    final installId = await ProductMetricsService.getOrCreateInstallId();
    if (installId == null || installId.isEmpty) {
      throw StateError('Kurulum kimliği oluşturulamadı.');
    }
    // Dua Halkası ile aynı desen: Google/Apple (veya prayer_*) oturumu varken
    // custom token ile ezme. Kurulum kaydı sunucuda ilk quiz çağrısında
    // oluşturulur. Yalnızca tamamen misafir (auth yok) iken quiz oturumu aç.
    if (_auth.currentUser == null) {
      final session = await _functions.httpsCallable('createQuizSession').call({
        'installId': installId,
        'bindingSecret': bindingSecret,
      });
      final data = Map<String, dynamic>.from(session.data as Map);
      final customToken = data['customToken']?.toString() ?? '';
      if (customToken.isEmpty) {
        throw StateError('Güvenli oyun oturumu oluşturulamadı.');
      }
      await _auth.signInWithCustomToken(customToken);
    }
    if (_auth.currentUser == null) {
      throw StateError('Güvenli oyun oturumu oluşturulamadı.');
    }
    return {'installId': installId, 'bindingSecret': bindingSecret};
  }

  String _safeName(String name) {
    final normalized = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length < 2) return 'Arın Oyuncusu';
    return normalized.length > 32
        ? normalized.substring(0, 32).trim()
        : normalized;
  }
}
