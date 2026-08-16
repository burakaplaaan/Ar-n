import 'package:arin/core/willpower/quit_elapsed_format.dart';
import 'package:arin/l10n/app_localizations_tr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsTr();

  test('saniye / dakika / saat kırılımı', () {
    expect(formatQuitElapsed(const Duration(seconds: 9), l10n), '9 sn');
    expect(
      formatQuitElapsed(const Duration(minutes: 3, seconds: 4), l10n),
      '3 dk 4 sn',
    );
    expect(
      formatQuitElapsed(const Duration(hours: 2, minutes: 7, seconds: 8), l10n),
      '2 sa 7 dk 8 sn',
    );
  });

  test('gün / ay / yıl birimleri eklenir', () {
    expect(
      formatQuitElapsed(const Duration(days: 2, hours: 3, minutes: 4, seconds: 5), l10n),
      '2 gün 3 sa 4 dk 5 sn',
    );
    expect(
      formatQuitElapsed(const Duration(days: 40, hours: 1, minutes: 2, seconds: 3), l10n),
      '1 ay 10 gün 1 sa 2 dk 3 sn',
    );
    expect(
      formatQuitElapsed(const Duration(days: 400, hours: 5, minutes: 6, seconds: 7), l10n),
      '1 yıl 1 ay 5 gün 5 sa 6 dk 7 sn',
    );
  });

  test('3138 saat gün ve aya bölünür', () {
    final parts = quitElapsedParts(const Duration(hours: 3138, minutes: 27, seconds: 19));
    expect(parts.years, 0);
    expect(parts.months, 4);
    expect(parts.days, 10);
    expect(parts.hours, 18);
    expect(parts.minutes, 27);
    expect(parts.seconds, 19);
    expect(
      formatQuitElapsed(const Duration(hours: 3138, minutes: 27, seconds: 19), l10n),
      '4 ay 10 gün 18 sa 27 dk 19 sn',
    );
  });
}
