import 'package:arin/core/providers/shared_preferences_provider.dart';
import 'package:arin/l10n/app_localizations.dart';
import 'package:arin/l10n/app_localizations_tr.dart';
import 'package:arin/presentation/onboarding/onboarding_heart_screen.dart';
import 'package:arin/presentation/onboarding/onboarding_page.dart';
import 'package:arin/presentation/onboarding/onboarding_struggle_copy.dart';
import 'package:arin/presentation/onboarding/onboarding_choice_screen.dart';
import 'package:arin/presentation/onboarding/onboarding_dua_screen.dart';
import 'package:arin/presentation/onboarding/onboarding_info_screen.dart';
import 'package:arin/presentation/onboarding/onboarding_prepare_screen.dart';
import 'package:arin/presentation/onboarding/onboarding_struggle_note_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ilk ekranda Arın, Başla ve ayet görünür', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Arın'), findsOneWidget);
    expect(find.textContaining('Başla'), findsOneWidget);
    expect(find.textContaining('Şems 9'), findsOneWidget);

    await tester.tap(find.textContaining('Başla'));
    await tester.pumpAndSettle();

    expect(find.text('Hoş geldin.'), findsOneWidget);
    expect(find.textContaining('Başlayalım'), findsOneWidget);

    await tester.tap(find.textContaining('Başlayalım'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Devam'), findsNothing);

    await tester.tap(find.byKey(const Key('onboarding_story_typewriter')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.textContaining('Devam'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  test('kalp yüzdesi etiketleri aralıklara göre değişir', () {
    final l10n = AppLocalizationsTr();
    expect(onboardingHeartLabelForPercent(l10n, 10), l10n.onboardingHeartLabelFar);
    expect(
      onboardingHeartLabelForPercent(l10n, 58),
      l10n.onboardingHeartLabelHolding,
    );
    expect(
      onboardingHeartLabelForPercent(l10n, 90),
      l10n.onboardingHeartLabelFull,
    );
  });

  test('his notu kopyası seçilen yüke göre değişir', () {
    final l10n = AppLocalizationsTr();
    final anxiety = OnboardingStruggleNoteCopy.resolve(
      l10n: l10n,
      name: 'Melih',
      struggleId: 'anxiety',
    );
    expect(anxiety.title, contains('kaygını'));
    expect(anxiety.hint, contains('uykumu'));
    expect(anxiety.suggestion, contains('Allah'));

    final delay = OnboardingStruggleNoteCopy.resolve(
      l10n: l10n,
      name: 'Melih',
      struggleId: 'delay',
    );
    expect(delay.title, contains('ertelemede'));
    expect(delay.suggestion, isNot(anxiety.suggestion));
  });

  test('ton seviyesi etiketleri 1-5 aralığında kalır', () {
    final l10n = AppLocalizationsTr();
    expect(onboardingToneOptionForLevel(l10n, 1).label, l10n.onboardingToneCalm);
    expect(
      onboardingToneOptionForLevel(l10n, 5).label,
      l10n.onboardingToneVeryHeavy,
    );
    expect(onboardingToneOptionForLevel(l10n, 0).level, 1);
    expect(onboardingToneOptionForLevel(l10n, 9).level, 5);
  });

  testWidgets('öneri alanı doldurur, devamda ayet çıkar, sonra ilerler', (
    tester,
  ) async {
    var continued = false;
    final l10n = AppLocalizationsTr();
    final copy = OnboardingStruggleNoteCopy.resolve(
      l10n: l10n,
      name: 'Melih',
      struggleId: 'anxiety',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OnboardingStruggleNoteScreen(
            copy: copy,
            heardHold: const Duration(milliseconds: 300),
            onBack: () {},
            onContinue: (_) => continued = true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.textContaining('Kaygımı Allah'));
    await tester.pump();
    expect(find.text(copy.suggestion), findsWidgets);

    await tester.tap(find.textContaining('Devam'));
    await tester.pump();
    expect(find.text('Seni duyduk.'), findsOneWidget);
    expect(find.textContaining('İnşirah'), findsOneWidget);
    expect(continued, isFalse);

    await tester.pump(const Duration(milliseconds: 300));
    expect(continued, isTrue);
  });

  testWidgets('şık seçilince Devam olmadan sonraki adıma geçer', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OnboardingChoiceScreen(
            title: 'Soru',
            subtitle: 'Alt',
            autoAdvance: true,
            centered: true,
            options: const [
              OnboardingChoiceOption(
                id: 'always',
                label: 'Her daralmada O\'na dönerim',
                icon: Icons.favorite_rounded,
              ),
            ],
            onBack: () {},
            onContinue: (id) => chosen = id,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Devam'), findsNothing);
    await tester.tap(find.textContaining('Her daralmada'));
    await tester.pump();
    expect(chosen, isNull);
    await tester.pump(OnboardingChoiceScreen.autoAdvanceDelay);
    expect(chosen, 'always');
  });

  testWidgets('ritim bilgi ekranı İrade kopyası değil', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OnboardingInfoScreen(
            title: 'Arın, günün içine sessizce yerleşir',
            subtitle: 'kısa bir hatırlatma',
            cards: const [
              OnboardingInfoCardData(
                icon: Icons.favorite_rounded,
                title: 'Kısa duruş',
                body: 'Ayetler gün içinde sakin görünür.',
              ),
            ],
            onBack: () {},
            onContinue: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('İrade'), findsNothing);
    expect(find.textContaining('Arın'), findsOneWidget);
    expect(find.textContaining('Devam'), findsOneWidget);
  });

  testWidgets('hazırlık bitince Devam ve 100 görünür', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OnboardingPrepareScreen(
            name: 'Melih',
            startAsReady: true,
            onRequestAtt: () async {},
            onAnswer: (_, __) {},
            onContinue: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Deneyimin hazır'), findsOneWidget);
    expect(find.text('100%'), findsNWidgets(4));
    expect(find.textContaining('Devam'), findsOneWidget);
  });

  testWidgets('dua yazımı tıklayınca hızlanmaz, Amin sonra çıkar', (
    tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OnboardingDuaScreen(
            name: 'Melih',
            tick: const Duration(milliseconds: 1),
            onFinished: () => finished = true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Basılı tut'), findsNothing);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Basılı tut'), findsNothing);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.textContaining('Basılı tut'), findsOneWidget);
    expect(finished, isFalse);
  });

  test('yol ayeti İnşirah tekrarı değil', () {
    final l10n = AppLocalizationsTr();
    expect(l10n.onboardingPathVerseSource, contains('Talâk'));
    expect(l10n.onboardingHeardSource, contains('İnşirah'));
    expect(l10n.onboardingPathVerseTranslation, isNot(l10n.onboardingHeardVerse));
    expect(l10n.onboardingStoryBody, contains('karşılayacak'));
    expect(l10n.onboardingGreetingBody, startsWith('Bugün bu uygulamayı indirmen tesadüf değil.'));
    expect(l10n.onboardingNoteSubtitle, contains('sadece sen görebilirsin'));
    expect(l10n.onboardingToneSubtitle, 'Dök içini.');
    expect(l10n.onboardingRhythmSubtitle, contains('bildirim iznini'));
    expect(l10n.onboardingLocationTitle, contains('konum'));
  });
}
