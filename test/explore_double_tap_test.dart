import 'package:arin/presentation/inspire/widgets/explore_double_tap.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('yakın iki tık çift tık sayılır', () {
    final tracker = ExploreDoubleTapTracker();
    final t0 = DateTime.utc(2026, 8, 17, 0, 0, 0);
    expect(tracker.registerTap(const Offset(40, 80), t0), isFalse);
    expect(
      tracker.registerTap(
        const Offset(44, 82),
        t0.add(const Duration(milliseconds: 180)),
      ),
      isTrue,
    );
  });

  test('geç veya uzak ikinci tık yeni ilk tık olur', () {
    final tracker = ExploreDoubleTapTracker();
    final t0 = DateTime.utc(2026, 8, 17, 0, 0, 0);
    expect(tracker.registerTap(const Offset(10, 10), t0), isFalse);
    expect(
      tracker.registerTap(
        const Offset(10, 10),
        t0.add(const Duration(milliseconds: 400)),
      ),
      isFalse,
    );
    expect(
      tracker.registerTap(
        const Offset(200, 200),
        t0.add(const Duration(milliseconds: 500)),
      ),
      isFalse,
    );
  });

  test('kaydırma sonrası reset çift tık üretmez', () {
    final tracker = ExploreDoubleTapTracker();
    final t0 = DateTime.utc(2026, 8, 17, 0, 0, 0);
    tracker.registerTap(const Offset(12, 12), t0);
    tracker.reset();
    expect(
      tracker.registerTap(
        const Offset(12, 12),
        t0.add(const Duration(milliseconds: 120)),
      ),
      isFalse,
    );
  });
}
