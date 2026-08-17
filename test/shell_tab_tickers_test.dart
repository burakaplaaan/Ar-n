import 'package:arin/presentation/shared/widgets/shell_tab_tickers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('görünür sekme ve kaydırma komşusu açık, uzak sekmeler kapalı', () {
    expect(
      shellTabTickersEnabled(index: 0, currentIndex: 0),
      isTrue,
    );
    expect(
      shellTabTickersEnabled(index: 1, currentIndex: 0),
      isTrue,
    );
    expect(
      shellTabTickersEnabled(index: 2, currentIndex: 0),
      isFalse,
    );
    expect(
      shellTabTickersEnabled(index: 4, currentIndex: 0),
      isFalse,
    );

    expect(
      shellTabTickersEnabled(index: 4, currentIndex: 4),
      isTrue,
    );
    expect(
      shellTabTickersEnabled(index: 3, currentIndex: 4),
      isTrue,
    );
    expect(
      shellTabTickersEnabled(index: 2, currentIndex: 4),
      isFalse,
    );

    expect(
      shellTabTickersEnabled(index: 1, currentIndex: 2),
      isTrue,
    );
    expect(
      shellTabTickersEnabled(index: 2, currentIndex: 2),
      isTrue,
    );
    expect(
      shellTabTickersEnabled(index: 3, currentIndex: 2),
      isTrue,
    );
    expect(
      shellTabTickersEnabled(index: 0, currentIndex: 2),
      isFalse,
    );
    expect(
      shellTabTickersEnabled(index: 4, currentIndex: 2),
      isFalse,
    );
  });
}
