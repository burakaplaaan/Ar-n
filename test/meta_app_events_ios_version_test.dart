import 'package:arin/core/analytics/meta_app_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS sürüm dizesinden major numarayı okur', () {
    expect(
      MetaAppEvents.iosMajorVersionAtLeast('Version 26.5 (Build 23F77)', 26),
      isTrue,
    );
    expect(
      MetaAppEvents.iosMajorVersionAtLeast('Version 18.6.2 (Build 22G86)', 26),
      isFalse,
    );
    expect(MetaAppEvents.iosMajorVersionAtLeast('', 26), isFalse);
  });
}
