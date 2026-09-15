import 'social_text.dart';

class SocialCommentPreview {
  const SocialCommentPreview({
    required this.username,
    required this.text,
    this.avatarId = 0,
  });

  final String username;
  final String text;
  final int avatarId;

  factory SocialCommentPreview.fromMap(Map<String, dynamic> raw) {
    return SocialCommentPreview(
      username: raw['username']?.toString() ?? '',
      text: raw['text']?.toString() ?? '',
      avatarId: socialNormalizeAvatarId(raw['avatarId']),
    );
  }
}

class SocialPost {
  const SocialPost({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorUsername,
    required this.authorPremium,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.authorBio = '',
    this.authorAvatarId = 0,
    this.liked = false,
    this.previewComments = const [],
  });

  final String id;
  final String text;
  final String authorUid;
  final String authorUsername;
  final String authorBio;
  final int authorAvatarId;
  final bool authorPremium;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final bool liked;
  final List<SocialCommentPreview> previewComments;

  SocialPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? liked,
    List<SocialCommentPreview>? previewComments,
  }) {
    return SocialPost(
      id: id,
      text: text,
      authorUid: authorUid,
      authorUsername: authorUsername,
      authorBio: authorBio,
      authorAvatarId: authorAvatarId,
      authorPremium: authorPremium,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
      liked: liked ?? this.liked,
      previewComments: previewComments ?? this.previewComments,
    );
  }

  factory SocialPost.fromMap(Map<String, dynamic> raw) {
    final createdAtMs = (raw['createdAtMs'] as num?)?.toInt() ?? 0;
    final previews = raw['lastComments'] ?? raw['previewComments'];
    return SocialPost(
      id: raw['id']?.toString() ?? '',
      text: raw['text']?.toString() ?? '',
      authorUid: raw['authorUid']?.toString() ?? '',
      authorUsername: raw['authorUsername']?.toString() ?? '',
      authorBio: (raw['authorBio']?.toString() ?? '').trim(),
      authorAvatarId: socialNormalizeAvatarId(raw['authorAvatarId']),
      authorPremium: raw['authorPremium'] == true,
      likeCount: (raw['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (raw['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAtMs > 0 ? createdAtMs : DateTime.now().millisecondsSinceEpoch,
      ),
      previewComments: _previewsFrom(previews),
    );
  }

  static List<SocialCommentPreview> _previewsFrom(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((row) => SocialCommentPreview.fromMap(
              Map<String, dynamic>.from(row),
            ))
        .where((row) => row.text.isNotEmpty)
        .take(2)
        .toList(growable: false);
  }
}

class SocialComment {
  const SocialComment({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorUsername,
    required this.authorPremium,
    required this.likeCount,
    required this.createdAt,
    this.authorBio = '',
    this.authorAvatarId = 0,
    this.liked = false,
  });

  final String id;
  final String text;
  final String authorUid;
  final String authorUsername;
  final String authorBio;
  final int authorAvatarId;
  final bool authorPremium;
  final int likeCount;
  final DateTime createdAt;
  final bool liked;

  SocialComment copyWith({int? likeCount, bool? liked}) {
    return SocialComment(
      id: id,
      text: text,
      authorUid: authorUid,
      authorUsername: authorUsername,
      authorBio: authorBio,
      authorAvatarId: authorAvatarId,
      authorPremium: authorPremium,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt,
      liked: liked ?? this.liked,
    );
  }

  factory SocialComment.fromMap(Map<String, dynamic> raw) {
    final createdAtMs = (raw['createdAtMs'] as num?)?.toInt() ?? 0;
    return SocialComment(
      id: raw['id']?.toString() ?? '',
      text: raw['text']?.toString() ?? '',
      authorUid: raw['authorUid']?.toString() ?? '',
      authorUsername: raw['authorUsername']?.toString() ?? '',
      authorBio: (raw['authorBio']?.toString() ?? '').trim(),
      authorAvatarId: socialNormalizeAvatarId(raw['authorAvatarId']),
      authorPremium: raw['authorPremium'] == true,
      likeCount: (raw['likeCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAtMs > 0 ? createdAtMs : DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class SocialProfile {
  const SocialProfile({
    required this.uid,
    this.username,
    this.bio,
    this.avatarId = 0,
    this.premium = false,
    this.admin = false,
    this.banned = false,
    this.banPermanent = false,
    this.bannedUntilMs,
    this.dailyPrompt,
  });

  final String uid;
  final String? username;
  final String? bio;
  final int avatarId;
  final bool premium;
  final bool admin;
  final bool banned;
  final bool banPermanent;
  final int? bannedUntilMs;
  final String? dailyPrompt;

  bool get hasUsername => (username ?? '').trim().isNotEmpty;
  bool get hasBio => (bio ?? '').trim().isNotEmpty;

  SocialProfile copyWith({String? bio, int? avatarId}) {
    return SocialProfile(
      uid: uid,
      username: username,
      bio: bio ?? this.bio,
      avatarId: avatarId ?? this.avatarId,
      premium: premium,
      admin: admin,
      banned: banned,
      banPermanent: banPermanent,
      bannedUntilMs: bannedUntilMs,
      dailyPrompt: dailyPrompt,
    );
  }
}

String socialPeekBio({
  required String authorUid,
  required String stampedBio,
  String? myUid,
  String? myBio,
  Map<String, String> knownBios = const {},
}) {
  if (authorUid.isNotEmpty && authorUid == myUid) {
    return (myBio ?? '').trim();
  }
  final stamped = stampedBio.trim();
  if (stamped.isNotEmpty) return stamped;
  return (knownBios[authorUid] ?? '').trim();
}

int socialPeekAvatar({
  required String authorUid,
  required int stampedAvatarId,
  String? myUid,
  int myAvatarId = 0,
  Map<String, int> knownAvatars = const {},
}) {
  if (authorUid.isNotEmpty && authorUid == myUid) {
    return socialNormalizeAvatarId(myAvatarId);
  }
  final stamped = socialNormalizeAvatarId(stampedAvatarId);
  if (stamped > 0) return stamped;
  return socialNormalizeAvatarId(knownAvatars[authorUid]);
}

class SocialCommentsPage {
  const SocialCommentsPage({
    required this.post,
    required this.items,
    this.nextCursorCreatedAtMs,
    this.nextCursorId,
  });

  final SocialPost post;
  final List<SocialComment> items;
  final int? nextCursorCreatedAtMs;
  final String? nextCursorId;
}

enum SocialFeedSort { latest, popular }
