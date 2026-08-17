import 'package:arin/presentation/inspire/widgets/explore_like_burst.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uçuş başlangıçta dokunulan noktada, sonda hedefte biter', () {
    const start = Offset(40, 520);
    const end = Offset(340, 280);
    expect(
      exploreLikeFlightPoint(start: start, end: end, t: 0),
      start,
    );
    final landed = exploreLikeFlightPoint(start: start, end: end, t: 1);
    expect(landed.dx, closeTo(end.dx, 0.01));
    expect(landed.dy, closeTo(end.dy, 0.01));
  });

  test('pop büyür, hedefe varırken küçülür ve solar', () {
    expect(exploreLikeFlightScale(0), lessThan(0.4));
    expect(exploreLikeFlightScale(0.26), greaterThan(1.0));
    expect(exploreLikeFlightScale(1), lessThan(0.4));
    expect(exploreLikeFlightOpacity(0.4), 1);
    expect(exploreLikeFlightOpacity(1), 0);
  });
}
