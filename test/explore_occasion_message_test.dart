import 'package:arin/core/utils/explore_occasion_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isFridaySharePromptDay', () {
    test('cuma günü paylaşım vurgusu açılır', () {
      expect(
        isFridaySharePromptDay(DateTime(2026, 9, 4)),
        isTrue,
      );
    });

    test('cuma dışı günlerde paylaşım vurgusu kapalıdır', () {
      expect(
        isFridaySharePromptDay(DateTime(2026, 9, 7)),
        isFalse,
      );
      expect(
        isFridaySharePromptDay(DateTime(2026, 9, 5)),
        isFalse,
      );
    });
  });

  group('exploreOccasionMessage', () {
    test('cuma günü Hayırlı Cumalar yazar', () {
      expect(
        exploreOccasionMessage(DateTime(2026, 9, 4)),
        'Hayırlı Cumalar',
      );
    });
  });
}
