import 'package:arin/presentation/qibla/hilal_duel/hilal_duel_level.dart';
import 'package:arin/presentation/qibla/hilal_duel/hilal_duel_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('levelForHilals', () {
    test('erken seviyeler erişilebilir kalır', () {
      expect(levelForHilals(0).level, 1);
      expect(levelForHilals(0).nextLevelHilals, 40);
      expect(levelForHilals(39).level, 1);
      expect(levelForHilals(40).level, 2);
      expect(levelForHilals(94).level, 2);
      expect(levelForHilals(95).level, 3);
      expect(levelForHilals(250).level, 5);
    });

    test('maksimum seviye 10', () {
      expect(levelForHilals(900).level, 10);
      expect(levelForHilals(900).maxLevel, isTrue);
      expect(levelForHilals(900).progress, 1);
      expect(levelForHilals(50_000).level, 10);
      expect(nextRewardAfterLevel(4)?.level, 5);
      expect(titleForLevel(5), 'Talebe');
      expect(titleForLevel(10), 'İlim Dostu');
    });

    test('ilerleme çubuğu 0-1 aralığında kalır', () {
      final mid = levelForHilals(20);
      expect(mid.progress, greaterThan(0));
      expect(mid.progress, lessThan(1));
      expect(levelForHilals(40).progress, 0);
    });

    test('hilalsFloorForLevel seviye tabanını verir', () {
      expect(hilalsFloorForLevel(1), 0);
      expect(hilalsFloorForLevel(2), 40);
      expect(hilalsFloorForLevel(3), 95);
      expect(levelForHilals(hilalsFloorForLevel(5)).level, 5);
      expect(levelForHilals(hilalsFloorForLevel(10)).level, 10);
    });
  });

  group('hilalAward', () {
    test('tek ilerleme birimi kullanır', () {
      expect(hilalAward(correct: 2, won: false), 4);
      expect(hilalAward(correct: 2, won: true), 9);
      expect(hilalAward(correct: 7, won: true), 22);
      expect(hilalAward(correct: 2, won: false, draw: true), 6);
    });
  });

  group('HilalDuelProfile/Match parsing', () {
    test('profil haritasını güvenli parse eder', () {
      final profile = HilalDuelProfile.fromMap({
        'name': 'Ayşe',
        'hilals': 40,
        'level': 2,
        'levelFloorHilals': 40,
        'nextLevelHilals': 95,
        'hearts': 1,
        'premium': false,
      });
      expect(profile.name, 'Ayşe');
      expect(profile.level, 2);
      expect(profile.levelProgress, 0);
    });

    test('soru zorluğunu parse eder', () {
      final easy = HilalDuelQuestion.fromMap({
        'id': 'iq_001',
        'category': 'Kur\'an bilgisi',
        'question': 'Kur\'an kaç suredir?',
        'options': ['114', '120', '99', '110'],
        'difficulty': 1,
      });
      expect(easy.difficulty, 1);
      final fallback = HilalDuelQuestion.fromMap({
        'id': 'iq_002',
        'question': 'Test sorusu burada',
        'options': ['a', 'b', 'c', 'd'],
      });
      expect(fallback.difficulty, 2);
    });

    test('maç sonucunu parse eder', () {
      final match = HilalDuelMatch.fromMap({
        'id': 'abc',
        'status': 'completed',
        'version': 12,
        'doubled': true,
        'currentRound': 6,
        'totalRounds': 7,
        'roundStartedAtMs': 1,
        'deadlineMs': 2,
        'selfAnswered': true,
        'opponentAnswered': true,
        'self': {
          'id': 'a',
          'name': 'A',
          'hilals': 10,
          'level': 1,
          'isBot': false,
        },
        'opponent': {
          'id': 'b',
          'name': 'B',
          'hilals': 12,
          'level': 1,
          'isBot': true,
          'badge': 'Hızlı Rakip',
        },
        'result': {
          'winnerId': 'a',
          'players': [
            {'id': 'a', 'correct': 5, 'elapsedMs': 40000, 'hilalsAwarded': 15},
            {'id': 'b', 'correct': 4, 'elapsedMs': 50000, 'hilalsAwarded': 8},
          ],
        },
      });
      expect(match.isCompleted, isTrue);
      expect(match.version, 12);
      expect(match.doubled, isTrue);
      expect(match.opponent.isBot, isTrue);
      expect(match.result?.winnerId, 'a');
      expect(match.result?.players.first.hilalsAwarded, 15);
    });
  });

  group('HilalDuelChallengeSummary inbox', () {
    test('bitmiş meydan okuma 48s görünür kalır', () {
      final completed = HilalDuelChallengeSummary.fromMap({
        'id': 'c1',
        'status': 'completed',
        'role': 'challenger',
        'opponentName': 'Ayşe',
        'opponentLevel': 3,
        'challengeDeadlineMs': 1,
        'outcome': 'won',
      });
      expect(completed.isOpen, isFalse);
      expect(completed.isInboxVisible, isTrue);
      expect(completed.outcome, 'won');
    });

    test('süresi dolmuş açık davet inbox’tan düşer', () {
      final expiredOpen = HilalDuelChallengeSummary.fromMap({
        'id': 'c2',
        'status': 'awaiting_opponent',
        'role': 'challenged',
        'opponentName': 'Ali',
        'opponentLevel': 2,
        'challengeDeadlineMs': 1,
        'canAccept': true,
      });
      expect(expiredOpen.isOpen, isFalse);
      expect(expiredOpen.isInboxVisible, isFalse);
    });
  });

  group('HilalDuelWeeklyLastWinner', () {
    test('grantDays 0 ise ödül metni yok sayılır', () {
      final skipped = HilalDuelWeeklyLastWinner.fromMap({
        'rank': 1,
        'name': 'Ali',
        'grantDays': 0,
        'champion': true,
      });
      expect(skipped.grantDays, 0);
      expect(skipped.champion, isTrue);
      final granted = HilalDuelWeeklyLastWinner.fromMap({
        'rank': 2,
        'name': 'Ece',
        'grantDays': 7,
      });
      expect(granted.grantDays, 7);
    });
  });
}
