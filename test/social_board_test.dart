import 'package:arin/core/errors/user_facing_error.dart';
import 'package:arin/presentation/qibla/social/social_models.dart';
import 'package:arin/presentation/qibla/social/social_repository.dart';
import 'package:arin/presentation/qibla/social/social_text.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('username rules match the cheap unique-handle gate', () {
    expect(isSocialUsernameValid('Kardes_1'), isTrue);
    expect(isSocialUsernameValid('ab'), isFalse);
    expect(isSocialUsernameValid('admin'), isFalse);
    expect(isSocialUsernameValid('ADMIN'), isFalse);
    expect(isSocialUsernameValid('ARIN'), isFalse);
    expect(isSocialUsernameValid('bad name'), isFalse);
    expect(socialUsernameKey('Arin_User'), 'arin_user');
  });

  test('Turkish insults are blocked without flagging normal words', () {
    expect(containsSocialInsult('Sabaha kadar sabretmek güzeldir.'), isFalse);
    expect(containsSocialInsult('klasik bir dua'), isFalse);
    expect(containsSocialInsult('siktir git'), isTrue);
    expect(containsSocialInsult('o.r.o.s.p.u'), isTrue);
    expect(isSocialPostValid('Bu kadar siktir yeter.'), isFalse);
    expect(isSocialUsernameValid('orospu'), isFalse);
  });

  test('post and comment limits stay tight', () {
    expect(isSocialPostValid('çok kısa'), isFalse);
    expect(isSocialPostValid('Sabaha kadar sabretmek güzeldir.'), isTrue);
    expect(isSocialPostValid('Bugün şükür:'), isFalse);
    expect(isSocialCommentValid('a'), isFalse);
    expect(isSocialCommentValid('amin'), isTrue);
  });

  test('bio is optional and stays short when written', () {
    expect(isSocialBioValid(''), isFalse);
    expect(isSocialOptionalBioValid(''), isTrue);
    expect(isSocialOptionalBioValid('kısa'), isFalse);
    expect(isSocialBioValid('kısa'), isFalse);
    expect(isSocialBioValid('Namazı kaçırmamaya çalışan biriyim.'), isTrue);
    expect(
      isSocialOptionalBioValid('Namazı kaçırmamaya çalışan biriyim.'),
      isTrue,
    );
    expect(isSocialBioValid('Bu kadar siktir yeter kardeşim'), isFalse);
    expect(isSocialOptionalBioValid('Bu kadar siktir yeter kardeşim'), isFalse);
  });

  test('profile peek prefers own bio then stamped then cache', () {
    expect(
      socialPeekBio(
        authorUid: 'me',
        stampedBio: '',
        myUid: 'me',
        myBio: 'Kendi yazım',
      ),
      'Kendi yazım',
    );
    expect(
      socialPeekBio(
        authorUid: 'u2',
        stampedBio: 'Damgalı',
        knownBios: const {'u2': 'Cache'},
      ),
      'Damgalı',
    );
    expect(
      socialPeekBio(
        authorUid: 'u2',
        stampedBio: '',
        knownBios: const {'u2': 'Cache'},
      ),
      'Cache',
    );
    expect(
      socialPeekBio(
        authorUid: 'me',
        stampedBio: 'Damgalı',
        myUid: 'me',
        myBio: '',
        knownBios: const {'me': 'Cache'},
      ),
      '',
    );
  });

  test('lead line splits first sentence or newline', () {
    expect(socialLeadLine('').lead, '');
    expect(socialLeadLine('').rest, isNull);
    final lined = socialLeadLine('İlk satır büyük dursun.\nKalan metin sakin.');
    expect(lined.lead, 'İlk satır büyük dursun.');
    expect(lined.rest, 'Kalan metin sakin.');
    final sentence = socialLeadLine(
      'Sabaha kadar sabretmek güzeldir. Sonra şükrederiz.',
    );
    expect(sentence.lead, 'Sabaha kadar sabretmek güzeldir.');
    expect(sentence.rest, 'Sonra şükrederiz.');
    expect(socialLeadLine('Tek parça kısa not.').rest, isNull);
  });

  test('relative time stays compact like X', () {
    final now = DateTime(2026, 9, 8, 12);
    expect(
      socialRelativeTime(now.subtract(const Duration(seconds: 10)), now),
      'şimdi',
    );
    expect(
      socialRelativeTime(now.subtract(const Duration(minutes: 4)), now),
      '4 dk',
    );
    expect(
      socialRelativeTime(now.subtract(const Duration(hours: 3)), now),
      '3 sa',
    );
  });

  test('post map keeps premium tick and comment count', () {
    final post = SocialPost.fromMap({
      'id': 'p1',
      'text': 'Merhaba',
      'authorUid': 'u1',
      'authorUsername': 'ali',
      'authorBio': 'Sabırlı bir kardeş.',
      'authorAvatarId': 3,
      'authorPremium': true,
      'likeCount': 4,
      'commentCount': 2,
      'createdAtMs': 1,
      'lastComments': [
        {'username': 'ayse', 'text': 'amin'},
      ],
    });
    expect(post.authorPremium, isTrue);
    expect(post.authorBio, 'Sabırlı bir kardeş.');
    expect(post.authorAvatarId, 3);
    expect(post.commentCount, 2);
    expect(post.previewComments.single.text, 'amin');
    expect(post.copyWith(liked: true).liked, isTrue);
  });

  test('profile peek prefers own avatar then stamped then cache', () {
    expect(
      socialPeekAvatar(
        authorUid: 'me',
        stampedAvatarId: 2,
        myUid: 'me',
        myAvatarId: 7,
      ),
      7,
    );
    expect(
      socialPeekAvatar(
        authorUid: 'me',
        stampedAvatarId: 2,
        myUid: 'me',
        myAvatarId: 0,
      ),
      0,
    );
    expect(
      socialPeekAvatar(
        authorUid: 'u2',
        stampedAvatarId: 4,
        knownAvatars: const <String, int>{'u2': 9},
      ),
      4,
    );
    expect(
      socialPeekAvatar(
        authorUid: 'u2',
        stampedAvatarId: 0,
        knownAvatars: const <String, int>{'u2': 9},
      ),
      9,
    );
  });

  test('islamic sticker avatar set stays local and optional', () {
    expect(kSocialAvatarAssets.length, 10);
    expect(kSocialAvatarAssets.length, lessThanOrEqualTo(kSocialAvatarMax));
    expect(socialAvatarAsset(0), isNull);
    expect(socialAvatarAsset(1), 'assets/social/avatars/01.png');
    expect(socialAvatarAsset(10), 'assets/social/avatars/10.png');
    expect(socialAvatarAsset(11), isNull);
    expect(socialNormalizeAvatarId(99), 0);
    expect(socialNormalizeAvatarId('5'), 5);
  });

  test('avatar color stays stable for the same username', () {
    expect(socialAvatarColorIndex('Kardes_1'), socialAvatarColorIndex('kardes_1'));
    expect(socialAvatarColorIndex('ali', 8), inInclusiveRange(0, 7));
    expect(socialAvatarColorIndex('ali', 1), 0);
  });

  test('callable details never reach the user', () {
    final missing = FirebaseFunctionsException(
      code: 'not-found',
      message: 'NOT_FOUND',
    );
    expect(socialFriendlyMessage(missing), kUserGenericErrorFallback);
    expect(socialFriendlyMessage(missing), isNot(contains('NOT_FOUND')));

    final leaked = FirebaseFunctionsException(
      code: 'internal',
      message: 'Firestore rules denied socialPosts/xyz',
    );
    expect(socialFriendlyMessage(leaked), kUserGenericErrorFallback);
    expect(socialFriendlyMessage(leaked), isNot(contains('Firestore')));
    expect(
      socialFriendlyMessage(
        FirebaseFunctionsException(
          code: 'already-exists',
          message: 'username_taken_internal_id_42',
        ),
      ),
      'Bu ad alınmış.',
    );
    expect(
      socialFriendlyMessage(
        FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'Önce hakkında yaz.',
          details: {'reason': 'bio_required'},
        ),
      ),
      'Önce hakkında yaz.',
    );
    expect(
      socialFriendlyMessage(
        FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'Önce bir kullanıcı adı seç.',
        ),
      ),
      'Önce kullanıcı adını seç.',
    );
  });
}
