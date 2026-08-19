import 'package:arin/data/services/arin_lock_notification_service.dart';
import 'package:arin/data/services/widget_access_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lock notification defaults are off for all kinds', () {
    for (final kind in ArinWidgetAccessKind.values) {
      expect(
        ArinLockNotificationService.defaultEnabled(kind),
        isFalse,
        reason: '${kind.id} must default off',
      );
    }
  });

  test('android namaz ve soz kilit bildirimi opt-in migration anahtari vardir', () {
    expect(
      ArinLockNotificationService.prayerQuoteOptInMigratedKey,
      'lock_notif_prayer_quote_opt_in_v2_migrated',
    );
  });
}
