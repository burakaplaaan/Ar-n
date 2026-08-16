import 'package:arin/core/router/app_router.dart';
import 'package:arin/data/models/prayer_times_model.dart';
import 'package:arin/l10n/app_localizations_tr.dart';
import 'package:arin/presentation/assistant/assistant_calendar.dart';
import 'package:arin/presentation/assistant/assistant_destinations.dart';
import 'package:arin/presentation/assistant/assistant_prayer_countdown.dart';
import 'package:arin/presentation/assistant/assistant_session.dart';
import 'package:arin/presentation/qibla/qibla_hub_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('zikirmatiğe gönder yönlendirme olarak çözülür', () {
    final route = resolveAssistantLocalRoute('beni zikirmatiğe gönder');
    expect(route?.page, 'zikir');
    expect(route?.kind, AssistantLocalKind.navigate);
  });

  test('kilit ekranı ayet sorusu Widget Merkezi rehberidir', () {
    final route = resolveAssistantLocalRoute(
      'Kilit ekranına ayet nasıl koyulur?',
    );
    expect(route?.page, 'widgets');
    expect(route?.kind, AssistantLocalKind.lockVerseGuide);
  });

  test('açıklama isteği yanlışlıkla sayfa açmaz', () {
    expect(resolveAssistantLocalRoute('İnşirah suresini açıkla.'), isNull);
    expect(resolveAssistantLocalRoute('Ramazana kaç gün var?'), isNull);
  });

  test('git ve geç fiilleri de yönlendirmedir', () {
    expect(resolveAssistantLocalRoute('zikirmatiğe git')?.page, 'zikir');
    expect(resolveAssistantLocalRoute('frekans ekranına geç')?.page, 'healing');
  });

  test('Ramazan kaç gün sorusu oruç sorusundan ayrılır', () {
    expect(isRamadanCountdownAsk('Ramazana kaç gün var?'), isTrue);
    expect(isRamadanCountdownAsk('Ramazan ne zaman?'), isTrue);
    expect(isRamadanCountdownAsk('Ramazanda günde kaç öğün?'), isFalse);
  });

  test('iftar ve imsak geri sayımı cihaz vaktinden hesaplanır', () {
    expect(matchAssistantPrayerTarget('iftara kaç saat var'), AssistantPrayerTarget.iftar);
    expect(matchAssistantPrayerTarget('sahura ne kadar var'), AssistantPrayerTarget.imsak);
    expect(matchAssistantPrayerTarget('iftar duası nasıl okunur'), isNull);

    const times = PrayerTimesModel(
      imsak: '04:10',
      fajr: '04:10',
      sunrise: '06:05',
      dhuhr: '13:10',
      asr: '16:40',
      maghrib: '19:42',
      isha: '21:05',
      date: '2026-08-16',
      city: 'İstanbul',
    );
    final l10n = AppLocalizationsTr();
    final before = formatPrayerCountdownReply(
      l10n: l10n,
      times: times,
      now: DateTime(2026, 8, 16, 18, 0),
      target: AssistantPrayerTarget.iftar,
    );
    expect(before, contains('1 sa 42 dk'));
    expect(before, contains('19:42'));

    final after = formatPrayerCountdownReply(
      l10n: l10n,
      times: times,
      now: DateTime(2026, 8, 16, 20, 0),
      target: AssistantPrayerTarget.iftar,
    );
    expect(after, contains('Yarın'));
    expect(after, contains('19:42'));
  });

  test('Ağustos 2026 için Ramazan gün sayısı hesaplanır', () {
    final c = ramadanCountdown(DateTime(2026, 8, 16));
    expect(c.isOngoing, isFalse);
    expect(c.daysUntil, greaterThan(100));
    expect(c.daysUntil, lessThan(250));
    expect(c.start.year, 2027);
  });

  test('asistandan dönüş yalnızca açık araçtayken geçerlidir', () {
    expect(
      assistantReturnStillOnTool(
        tool: 'zikir',
        path: AppRoutes.qibla,
        qiblaTop: QiblaHubRoutes.zikir,
      ),
      isTrue,
    );
    expect(
      assistantReturnStillOnTool(
        tool: 'zikir',
        path: AppRoutes.qibla,
        qiblaTop: QiblaHubRoutes.dashboard,
      ),
      isFalse,
    );
    expect(
      assistantReturnStillOnTool(
        tool: 'widgets',
        path: AppRoutes.settingsWidgets,
        qiblaTop: null,
      ),
      isTrue,
    );
  });
}
