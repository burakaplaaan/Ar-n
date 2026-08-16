import 'package:arin/data/services/app_notification_channel_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('arınma açılınca günlük ve alışkanlık bildirimleri bir kez açılır', () async {
    final prefs = await SharedPreferences.getInstance();
    expect(AppNotificationChannelPrefs.arinmaDailyEnabled(prefs), isFalse);
    expect(AppNotificationChannelPrefs.milestoneEnabled(prefs), isFalse);

    final first =
        await AppNotificationChannelPrefs.enableArinmaNotificationsForQuit(
      prefs,
    );
    expect(first, isTrue);
    expect(AppNotificationChannelPrefs.arinmaDailyEnabled(prefs), isTrue);
    expect(AppNotificationChannelPrefs.milestoneEnabled(prefs), isTrue);

    await AppNotificationChannelPrefs.setArinmaDailyEnabled(prefs, false);
    await AppNotificationChannelPrefs.setMilestoneEnabled(prefs, false);

    final second =
        await AppNotificationChannelPrefs.enableArinmaNotificationsForQuit(
      prefs,
    );
    expect(second, isFalse);
    expect(AppNotificationChannelPrefs.arinmaDailyEnabled(prefs), isFalse);
    expect(AppNotificationChannelPrefs.milestoneEnabled(prefs), isFalse);
  });

  test('yeni sayaç force ile kapalı anahtarları tekrar açar', () async {
    final prefs = await SharedPreferences.getInstance();
    await AppNotificationChannelPrefs.enableArinmaNotificationsForQuit(prefs);
    await AppNotificationChannelPrefs.setArinmaDailyEnabled(prefs, false);
    await AppNotificationChannelPrefs.setMilestoneEnabled(prefs, false);

    final forced =
        await AppNotificationChannelPrefs.enableArinmaNotificationsForQuit(
      prefs,
      force: true,
    );
    expect(forced, isTrue);
    expect(AppNotificationChannelPrefs.arinmaDailyEnabled(prefs), isTrue);
    expect(AppNotificationChannelPrefs.milestoneEnabled(prefs), isTrue);
  });

  test('aktif arınmada eski görev ve günlük motivasyon çakışması kapanır', () {
    expect(
      AppNotificationChannelPrefs.shouldScheduleGenericArinmaMotivation(
        hasActiveQuit: true,
      ),
      isFalse,
    );
    expect(
      AppNotificationChannelPrefs.shouldScheduleGenericArinmaMotivation(
        hasActiveQuit: false,
      ),
      isTrue,
    );
  });

  test('aktif arınmada genel görev hatırlatıcısı planlanmaz', () async {
    final prefs = await SharedPreferences.getInstance();
    await AppNotificationChannelPrefs.setTaskReminderEnabled(prefs, true);
    expect(
      AppNotificationChannelPrefs.shouldScheduleGenericTaskReminder(
        prefs,
        hasActiveQuit: true,
      ),
      isFalse,
    );
    expect(
      AppNotificationChannelPrefs.shouldScheduleGenericTaskReminder(
        prefs,
        hasActiveQuit: false,
      ),
      isTrue,
    );
  });
}
