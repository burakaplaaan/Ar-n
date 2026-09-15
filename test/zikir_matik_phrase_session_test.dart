import 'package:arin/data/models/zikir_matik_phrase_session.dart';
import 'package:arin/data/repositories/zikir_matik_repository.dart';
import 'package:arin/data/services/zikir_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ZikirMatikRepository> repoWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return ZikirMatikRepository(prefs);
  }

  test('phrase keys ignore case and surrounding space', () {
    expect(
      ZikirMatikRepository.phraseSessionKey(' ALLAHU EKBER '),
      ZikirMatikRepository.phraseSessionKey('allahu ekber'),
    );
    expect(
      ZikirMatikRepository.phraseSessionKey('ELHAMDÜLİLLAH'),
      isNot(ZikirMatikRepository.phraseSessionKey('ALLAHU EKBER')),
    );
  });

  test('switching phrases keeps each counter independently', () async {
    final repo = await repoWith({});
    await repo.upsertPhraseSession(
      phrase: 'ALLAHU EKBER',
      total: 1000,
      round: 10,
      tur: 31,
      target: 33,
    );
    await repo.upsertPhraseSession(
      phrase: 'ELHAMDÜLİLLAH',
      total: 0,
      round: 0,
      tur: 1,
      target: 33,
    );

    final ekber = repo.loadPhraseSession('allahu ekber');
    final hamd = repo.loadPhraseSession('ELHAMDÜLİLLAH');
    expect(ekber?.total, 1000);
    expect(ekber?.round, 10);
    expect(ekber?.tur, 31);
    expect(hamd?.total, 0);
    expect(hamd?.tur, 1);
  });

  test('saveSession writes both active session and phrase snapshot', () async {
    final repo = await repoWith({});
    await repo.saveSession(
      total: 42,
      round: 9,
      tur: 2,
      phrase: 'HASBÜNALLAH',
      target: 99,
    );
    final session = repo.loadSession();
    expect(session.total, 42);
    expect(session.phrase, 'HASBÜNALLAH');
    expect(session.target, 99);
    expect(repo.loadPhraseSession('hasbünallah')?.total, 42);
  });

  test('legacy session is used until a phrase snapshot exists', () async {
    final repo = await repoWith({
      ZikirMatikPrefsKeys.sessionTotal: 250,
      ZikirMatikPrefsKeys.sessionRound: 19,
      ZikirMatikPrefsKeys.sessionTur: 8,
      ZikirMatikPrefsKeys.sessionPhrase: 'ALLAHU EKBER',
      ZikirMatikPrefsKeys.sessionTarget: 33,
    });
    final session = repo.loadSession();
    expect(session.total, 250);
    expect(session.round, 19);
    expect(session.tur, 8);
    expect(repo.loadPhraseSession('ALLAHU EKBER'), isNull);
  });

  test('phrase snapshot wins over stale legacy session keys', () async {
    final repo = await repoWith({
      ZikirMatikPrefsKeys.sessionTotal: 250,
      ZikirMatikPrefsKeys.sessionRound: 19,
      ZikirMatikPrefsKeys.sessionTur: 8,
      ZikirMatikPrefsKeys.sessionPhrase: 'ALLAHU EKBER',
      ZikirMatikPrefsKeys.sessionTarget: 33,
    });
    await repo.upsertPhraseSession(
      phrase: 'ALLAHU EKBER',
      total: 1000,
      round: 4,
      tur: 31,
      target: 33,
    );
    final session = repo.loadSession();
    expect(session.total, 1000);
    expect(session.round, 4);
    expect(session.tur, 31);
  });

  test('resetting one phrase does not wipe another', () async {
    final repo = await repoWith({});
    await repo.upsertPhraseSession(
      phrase: 'ALLAHU EKBER',
      total: 1000,
      round: 1,
      tur: 31,
      target: 33,
    );
    await repo.upsertPhraseSession(
      phrase: 'ELHAMDÜLİLLAH',
      total: 12,
      round: 12,
      tur: 1,
      target: 33,
    );
    await repo.upsertPhraseSession(
      phrase: 'ELHAMDÜLİLLAH',
      total: 0,
      round: 0,
      tur: 1,
      target: 33,
    );
    expect(repo.loadPhraseSession('ALLAHU EKBER')?.total, 1000);
    expect(repo.loadPhraseSession('ELHAMDÜLİLLAH')?.total, 0);
  });

  test('deleting a custom phrase removes its counter', () async {
    final repo = await repoWith({});
    await repo.saveCustomPhrase('Ya Allah');
    await repo.upsertPhraseSession(
      phrase: 'Ya Allah',
      total: 77,
      round: 11,
      tur: 3,
      target: 33,
    );
    await repo.deleteCustomPhrase('Ya Allah');
    expect(repo.loadCustomPhrases(), isEmpty);
    expect(repo.loadPhraseSession('Ya Allah'), isNull);
  });

  test('widget total is not adopted when phrase differs', () {
    expect(
      ZikirWidgetService.shouldAdoptWidgetTotal(
        sessionPhrase: 'ELHAMDÜLİLLAH',
        widgetPhrase: 'ALLAHU EKBER',
      ),
      isFalse,
    );
    expect(
      ZikirWidgetService.shouldAdoptWidgetTotal(
        sessionPhrase: 'ALLAHU EKBER',
        widgetPhrase: 'allahu ekber',
      ),
      isTrue,
    );
    expect(
      ZikirWidgetService.shouldAdoptWidgetTotal(
        sessionPhrase: 'ALLAHU EKBER',
        widgetPhrase: '',
      ),
      isFalse,
    );
    expect(
      ZikirWidgetService.shouldAdoptWidgetTotal(
        sessionPhrase: '',
        widgetPhrase: '',
      ),
      isTrue,
    );
  });

  test('newer cloud phrase session wins merge', () {
    final local = {
      'allahu ekber': const ZikirMatikPhraseSession(
        total: 10,
        round: 10,
        tur: 1,
        target: 33,
        updatedAtMillis: 1,
      ),
    };
    final cloud = {
      'allahu ekber': const ZikirMatikPhraseSession(
        total: 1000,
        round: 10,
        tur: 31,
        target: 33,
        updatedAtMillis: 9,
      ),
      'elhamdülillah': const ZikirMatikPhraseSession(
        total: 4,
        round: 4,
        tur: 1,
        target: 33,
        updatedAtMillis: 8,
      ),
    };
    final merged = ZikirMatikRepository.mergePhraseSessions(
      cloud: cloud,
      local: local,
    );
    expect(merged['allahu ekber']?.total, 1000);
    expect(merged['elhamdülillah']?.total, 4);
  });

  test('queued phrase writes do not drop a sibling session', () async {
    final repo = await repoWith({});
    await Future.wait([
      repo.upsertPhraseSession(
        phrase: 'ALLAHU EKBER',
        total: 1000,
        round: 1,
        tur: 31,
        target: 33,
      ),
      repo.upsertPhraseSession(
        phrase: 'ELHAMDÜLİLLAH',
        total: 0,
        round: 0,
        tur: 1,
        target: 33,
      ),
    ]);
    expect(repo.loadPhraseSession('ALLAHU EKBER')?.total, 1000);
    expect(repo.loadPhraseSession('ELHAMDÜLİLLAH')?.total, 0);
  });

  test('phrase session json round-trips', () {
    const original = ZikirMatikPhraseSession(
      total: 15,
      round: 15,
      tur: 1,
      target: 33,
      updatedAtMillis: 123,
    );
    final parsed = ZikirMatikPhraseSession.fromJson(original.toJson());
    expect(parsed?.total, 15);
    expect(parsed?.round, 15);
    expect(parsed?.tur, 1);
    expect(parsed?.target, 33);
    expect(parsed?.updatedAtMillis, 123);
  });
}
