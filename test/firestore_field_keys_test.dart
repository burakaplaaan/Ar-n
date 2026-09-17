import 'package:arin/core/firebase/firestore_field_keys.dart';
import 'package:arin/data/models/zikir_matik_phrase_session.dart';
import 'package:arin/data/repositories/zikir_matik_repository.dart';
import 'package:arin/data/services/user_cloud_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('boş ve __*__ anahtarlarını siler, gömülü map’i temizler', () {
    final cleaned = sanitizeFirestoreMap({
      'ok': 1,
      '': {'nested': true},
      '__name__': 'nope',
      '__foo__': 'nope',
      '__': 'nope',
      'phraseSessions': {
        '': {'total': 12},
        '__foo__': {'total': 1},
        'allahu ekber': {'total': 3},
      },
      'records': [
        {'id': 'a', '': 'bad'},
      ],
    });

    expect(cleaned.containsKey(''), isFalse);
    expect(cleaned.containsKey('__name__'), isFalse);
    expect(cleaned.containsKey('__foo__'), isFalse);
    expect(cleaned.containsKey('__'), isFalse);
    expect(cleaned['ok'], 1);
    expect(cleaned['phraseSessions'], {
      'allahu ekber': {'total': 3},
    });
    expect(cleaned['records'], [
      {'id': 'a'},
    ]);
  });

  test('sentinel değerleri top-level ve listede olduğu gibi bırakır', () {
    const sentinel = Object();
    final cleaned = sanitizeFirestoreMap({
      'syncedAt': sentinel,
      'items': [
        sentinel,
        {'ok': 1, '': 2},
      ],
    });
    expect(identical(cleaned['syncedAt'], sentinel), isTrue);
    expect(identical((cleaned['items'] as List).first, sentinel), isTrue);
    expect(cleaned['items'], [
      sentinel,
      {'ok': 1},
    ]);
  });

  test('boş zikir cümlesi phraseSessions anahtarı yazmaz', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ZikirMatikRepository(prefs);
    await repo.saveSession(
      total: 40,
      round: 7,
      tur: 2,
      phrase: '   ',
      target: 33,
    );

    expect(repo.loadSession().total, 40);
    expect(repo.loadPhraseSessions(), isEmpty);
    expect(repo.loadPhraseSession(''), isNull);
  });

  test('__foo__ zikir cümlesi phraseSessions anahtarı yazmaz', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ZikirMatikRepository(prefs);
    await repo.saveSession(
      total: 11,
      round: 2,
      tur: 1,
      phrase: '__foo__',
      target: 33,
    );

    expect(repo.loadSession().phrase, '__foo__');
    expect(repo.loadPhraseSessions(), isEmpty);
  });

  test('kayıtlı boş phraseSession anahtarını yüklerken atar', () async {
    SharedPreferences.setMockInitialValues({
      ZikirMatikPrefsKeys.phraseSessionsJson:
          '{"":{"total":9,"round":1,"tur":1,"target":33,"updatedAtMillis":1}}',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = ZikirMatikRepository(prefs);
    expect(repo.loadPhraseSessions(), isEmpty);
  });

  test('merge boş ve __*__ anahtarlarını düşürür', () {
    const session = ZikirMatikPhraseSession(
      total: 4,
      round: 4,
      tur: 1,
      target: 33,
      updatedAtMillis: 2,
    );
    final merged = ZikirMatikRepository.mergePhraseSessions(
      cloud: {
        '': session,
        '__name__': session,
        '__foo__': session,
        '__': session,
        'subhanallah': session,
      },
      local: {'': session},
    );
    expect(merged.keys, ['subhanallah']);
  });

  test('cloud yedek boş/reserved phrase ile phraseSessions sentezlemez', () {
    final fromCloud = UserCloudBackupService.phraseSessionsFromForTest(
      {
        '': const ZikirMatikPhraseSession(
          total: 8,
          round: 1,
          tur: 1,
          target: 33,
        ).toJson(),
      },
      fallbackSession: {
        'total': 80,
        'round': 2,
        'tur': 3,
        'phrase': '',
        'target': 33,
      },
      fallbackUpdatedAtMs: 99,
    );
    expect(fromCloud, isEmpty);

    final named = UserCloudBackupService.phraseSessionsFromForTest(
      {},
      fallbackSession: {
        'total': 80,
        'round': 2,
        'tur': 3,
        'phrase': 'ALLAHU EKBER',
        'target': 33,
      },
      fallbackUpdatedAtMs: 99,
    );
    expect(named['allahu ekber']?.total, 80);

    final reserved = UserCloudBackupService.phraseSessionsFromForTest(
      {},
      fallbackSession: {
        'total': 80,
        'round': 2,
        'tur': 3,
        'phrase': '__foo__',
        'target': 33,
      },
      fallbackUpdatedAtMs: 99,
    );
    expect(reserved, isEmpty);
  });

  test('yedek json boş phrase anahtarını yazmaz', () {
    const session = ZikirMatikPhraseSession(
      total: 8,
      round: 1,
      tur: 1,
      target: 33,
      updatedAtMillis: 1,
    );
    final json = UserCloudBackupService.phraseSessionsToJsonForTest({
      '': session,
      '__foo__': session,
      'elhamdülillah': session,
    });
    expect(json.keys, ['elhamdülillah']);
  });
}
