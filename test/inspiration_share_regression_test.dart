import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'inspiration share service avoids debug-only paint getter calls',
    () {
      final file = File(
        'lib/presentation/inspire/inspiration_share_service.dart',
      );
      expect(file.existsSync(), isTrue);

      final source = file.readAsStringSync();

      // Regression guard:
      // `.debugNeedsPaint` release modunda LateInitializationError atabiliyor.
      expect(source.contains('.debugNeedsPaint'), isFalse);
    },
  );
}
