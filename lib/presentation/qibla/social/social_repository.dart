import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../data/services/product_metrics_service.dart';
import 'social_models.dart';
import 'social_text.dart';

class SocialRepository {
  SocialRepository({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: _functionsRegion);

  static const _functionsRegion = 'europe-west1';
  static const _bindingSecretKey = 'arin_prayer_circle_binding_secret_v1';
  static const _likedKey = 'arin_social_liked_v1';
  static const _draftKey = 'arin_social_draft_v3';
  static const _sortKey = 'arin_social_sort_v2';
  static const _firstPostToastKey = 'arin_social_first_post_toast_v1';
  static const _cacheTtl = Duration(minutes: 8);
  static const _callTimeout = Duration(seconds: 20);
  static const _fcmTimeout = Duration(seconds: 3);

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  Future<String>? _bindingSecretFuture;

  final Map<SocialFeedSort, _CachedFeed> _feedCache = {};

  String? get currentUid => _auth.currentUser?.uid;

  Future<SocialProfile> loadProfile() async {
    final token = await _fcmToken();
    final data = await _call('getSocialProfile', {
      if (token != null) 'fcmToken': token,
      'locale': _localeCode(),
    });
    return _profileFrom(data);
  }

  Future<SocialProfile> claimUsername(
    String username,
    String bio, {
    int avatarId = 0,
  }) async {
    final token = await _fcmToken();
    final data = await _call('claimSocialUsername', {
      'username': username,
      'bio': bio,
      'avatarId': socialNormalizeAvatarId(avatarId),
      if (token != null) 'fcmToken': token,
      'locale': _localeCode(),
    });
    return _profileFrom(data);
  }

  Future<SocialProfile> setBio(String bio, {int? avatarId}) async {
    final data = await _call('setSocialBio', {
      'bio': bio,
      if (avatarId != null) 'avatarId': socialNormalizeAvatarId(avatarId),
    });
    return _profileFrom(data);
  }

  Future<SocialProfile> setAvatar(int avatarId) async {
    final data = await _call('setSocialAvatar', {
      'avatarId': socialNormalizeAvatarId(avatarId),
    });
    return _profileFrom(data);
  }

  SocialProfile _profileFrom(Map<String, dynamic> data) {
    final prompt = data['prompt']?.toString().trim();
    final bio = (data['bio']?.toString() ?? '').trim();
    return SocialProfile(
      uid: data['uid']?.toString() ?? currentUid ?? '',
      username: data['username']?.toString(),
      bio: bio.isEmpty ? null : bio,
      avatarId: socialNormalizeAvatarId(data['avatarId']),
      premium: data['premium'] == true,
      admin: data['admin'] == true,
      banned: data['banned'] == true,
      banPermanent: data['banPermanent'] == true,
      bannedUntilMs: (data['bannedUntilMs'] as num?)?.toInt(),
      dailyPrompt: (prompt == null || prompt.isEmpty) ? null : prompt,
    );
  }

  String _localeCode() {
    final code = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    if (code == 'en' || code == 'ar' || code == 'tr') return code;
    return 'tr';
  }

  Future<String?> _fcmToken() async {
    try {
      final token = await FirebaseMessaging.instance
          .getToken()
          .timeout(_fcmTimeout);
      final value = token?.trim() ?? '';
      if (value.length < 20 || value.length > 4096) return null;
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<List<SocialPost>> loadFeed({
    required SocialFeedSort sort,
    bool force = false,
  }) async {
    final cached = _feedCache[sort];
    final now = DateTime.now();
    if (!force &&
        cached != null &&
        now.difference(cached.at) < _cacheTtl) {
      return _withLocalLikes(cached.items);
    }
    final data = await _call('listSocialFeed', {
      'sort': sort == SocialFeedSort.popular ? 'popular' : 'latest',
    });
    final raw = (data['items'] as List?) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((row) => SocialPost.fromMap(Map<String, dynamic>.from(row)))
        .where((post) => post.id.isNotEmpty)
        .toList(growable: false);
    _feedCache[sort] = _CachedFeed(items: items, at: now);
    return _withLocalLikes(items);
  }

  void rememberFeed(SocialFeedSort sort, List<SocialPost> items) {
    final previous = _feedCache[sort];
    _feedCache[sort] = _CachedFeed(
      items: items,
      at: previous?.at ?? DateTime.now(),
    );
  }

  Future<SocialCommentsPage> loadComments({
    required String postId,
    int? cursorCreatedAtMs,
    String? cursorId,
  }) async {
    final data = await _call('listSocialComments', {
      'postId': postId,
      if (cursorCreatedAtMs != null) 'cursorCreatedAtMs': cursorCreatedAtMs,
      if (cursorId != null) 'cursorId': cursorId,
    });
    final postMap = Map<String, dynamic>.from(data['post'] as Map? ?? {});
    final raw = (data['items'] as List?) ?? const [];
    final comments = raw
        .whereType<Map>()
        .map((row) => SocialComment.fromMap(Map<String, dynamic>.from(row)))
        .where((comment) => comment.id.isNotEmpty)
        .toList(growable: false);
    return SocialCommentsPage(
      post: SocialPost.fromMap(postMap),
      items: await _withLocalCommentLikes(comments),
      nextCursorCreatedAtMs: (data['nextCursorCreatedAtMs'] as num?)?.toInt(),
      nextCursorId: data['nextCursorId']?.toString(),
    );
  }

  Future<SocialPost> createPost(String text) async {
    final data = await _call('createSocialPost', {'text': text});
    _feedCache.clear();
    return SocialPost.fromMap(Map<String, dynamic>.from(data['post'] as Map));
  }

  Future<void> deletePost(String postId) async {
    await _call('deleteSocialPost', {'postId': postId});
    _feedCache.clear();
  }

  Future<({SocialComment comment, SocialPost? post})> addComment({
    required String postId,
    required String text,
  }) async {
    final data = await _call('addSocialComment', {
      'postId': postId,
      'text': text,
    });
    final comment = SocialComment.fromMap(
      Map<String, dynamic>.from(data['comment'] as Map),
    );
    final postRaw = data['post'];
    return (
      comment: comment,
      post: postRaw is Map
          ? SocialPost.fromMap(Map<String, dynamic>.from(postRaw))
          : null,
    );
  }

  Future<SocialPost?> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final data = await _call('deleteSocialComment', {
      'postId': postId,
      'commentId': commentId,
    });
    final postRaw = data['post'];
    return postRaw is Map
        ? SocialPost.fromMap(Map<String, dynamic>.from(postRaw))
        : null;
  }

  Future<({bool liked, int likeCount, SocialPost? post})> like({
    required String targetId,
    required bool liked,
    String targetType = 'post',
    String? postId,
  }) async {
    await _setLikedLocal('$targetType:$targetId', liked);
    try {
      final data = await _call('likeSocial', {
        'targetType': targetType,
        'targetId': targetId,
        'liked': liked,
        if (postId != null) 'postId': postId,
      });
      final postRaw = data['post'];
      return (
        liked: data['liked'] == true,
        likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
        post: postRaw is Map
            ? SocialPost.fromMap(Map<String, dynamic>.from(postRaw))
            : null,
      );
    } catch (error) {
      await _setLikedLocal('$targetType:$targetId', !liked);
      rethrow;
    }
  }

  Future<void> banUser({
    required String targetUid,
    required int durationHours,
  }) async {
    await _call('banSocialUser', {
      'targetUid': targetUid,
      'durationHours': durationHours,
    });
    _feedCache.clear();
  }

  Future<({bool reported, bool hidden})> reportPost(String postId) async {
    final data = await _call('reportSocialPost', {'postId': postId});
    final hidden = data['hidden'] == true;
    if (hidden) _feedCache.clear();
    return (reported: data['reported'] == true, hidden: hidden);
  }

  Future<String?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_draftKey);
  }

  Future<void> saveDraft(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (text.trim().isEmpty) {
      await prefs.remove(_draftKey);
      return;
    }
    await prefs.setString(_draftKey, text);
  }

  Future<SocialFeedSort> loadSort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sortKey) == 'latest'
        ? SocialFeedSort.latest
        : SocialFeedSort.popular;
  }

  Future<void> saveSort(SocialFeedSort sort) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sortKey,
      sort == SocialFeedSort.popular ? 'popular' : 'latest',
    );
  }

  Future<bool> shouldShowFirstPostToast() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstPostToastKey) != true;
  }

  Future<void> markFirstPostToastShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstPostToastKey, true);
  }

  Future<List<SocialPost>> _withLocalLikes(List<SocialPost> items) async {
    final liked = await _likedIds();
    return items
        .map(
          (post) => post.copyWith(liked: liked.contains('post:${post.id}')),
        )
        .toList(growable: false);
  }

  Future<List<SocialComment>> _withLocalCommentLikes(
    List<SocialComment> items,
  ) async {
    final liked = await _likedIds();
    return items
        .map(
          (comment) =>
              comment.copyWith(liked: liked.contains('comment:${comment.id}')),
        )
        .toList(growable: false);
  }

  Future<Set<String>> _likedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_likedKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _setLikedLocal(String key, bool liked) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _likedIds();
    if (liked) {
      current.add(key);
    } else {
      current.remove(key);
    }
    await prefs.setString(_likedKey, jsonEncode(current.toList()));
  }

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, dynamic> extra = const {},
  ]) async {
    try {
      final credentials = await _requiredInstallationCredentials()
          .timeout(_callTimeout);
      final result = await _functions.httpsCallable(name).call({
        ...credentials,
        ...extra,
      }).timeout(_callTimeout);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      throw SocialException(socialFriendlyMessage(error));
    } on TimeoutException {
      throw const SocialException(kUserGenericErrorFallback);
    }
  }

  Future<Map<String, String>> _requiredInstallationCredentials() async {
    final bindingSecret = await _requiredBindingSecret();
    final installId = await _requiredInstallId(bindingSecret);
    return {'installId': installId, 'bindingSecret': bindingSecret};
  }

  Future<String> _requiredInstallId(String bindingSecret) async {
    if (!isFirebaseReady) {
      throw const SocialException(kUserGenericErrorFallback);
    }
    final installId = await ProductMetricsService.getOrCreateInstallId();
    if (installId == null || installId.isEmpty) {
      throw const SocialException(kUserGenericErrorFallback);
    }
    if (_auth.currentUser == null) {
      try {
        final result = await _functions
            .httpsCallable('createPrayerSession')
            .call({
              'installId': installId,
              'bindingSecret': bindingSecret,
            })
            .timeout(_callTimeout);
        final data = Map<String, dynamic>.from(result.data as Map);
        final customToken = data['customToken']?.toString() ?? '';
        if (customToken.isEmpty) {
          throw const SocialException(kUserGenericErrorFallback);
        }
        await _auth.signInWithCustomToken(customToken);
      } on FirebaseFunctionsException catch (error) {
        throw SocialException(socialFriendlyMessage(error));
      }
    }
    if (_auth.currentUser == null) {
      throw const SocialException(kUserGenericErrorFallback);
    }
    return installId;
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

class SocialException implements Exception {
  const SocialException(this.message);
  final String message;

  @override
  String toString() => message;
}

String socialUserError(Object error, [String? generic]) {
  if (error is SocialException) return error.message;
  return generic ?? kUserGenericErrorFallback;
}

String socialFriendlyMessage(FirebaseFunctionsException error) {
  final code = error.code.trim().toLowerCase().replaceAll('_', '-');
  return switch (code) {
    'resource-exhausted' => 'Biraz yavaş, hemen ardından dene.',
    'already-exists' => 'Bu ad alınmış.',
    'failed-precondition' => _failedPreconditionMessage(error),
    _ => kUserGenericErrorFallback,
  };
}

String _failedPreconditionMessage(FirebaseFunctionsException error) {
  final details = error.details;
  if (details is Map && details['reason']?.toString() == 'bio_required') {
    return 'Önce hakkında yaz.';
  }
  return 'Önce kullanıcı adını seç.';
}

@immutable
class _CachedFeed {
  const _CachedFeed({required this.items, required this.at});
  final List<SocialPost> items;
  final DateTime at;
}
