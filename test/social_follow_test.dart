import 'package:arin/l10n/app_localizations.dart';
import 'package:arin/presentation/settings/social_follow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Instagram önce uygulama şemasını, sonra web profilini dener', () {
    final uris = arinSocialProfileUris(ArinSocialNetwork.instagram);
    expect(uris, hasLength(2));
    expect(
      uris.first,
      Uri.parse('instagram://user?username=arinapptr'),
    );
    expect(
      uris.last,
      Uri.parse('https://www.instagram.com/arinapptr/'),
    );
  });

  test('TikTok resmi web profiline gider', () {
    expect(
      arinSocialProfileUris(ArinSocialNetwork.tiktok),
      [Uri.parse('https://www.tiktok.com/@arinapptr')],
    );
  });

  test('handle etiketi @arinapptr olur', () {
    expect(arinSocialHandleLabel(), '@arinapptr');
  });

  test('openArinSocialProfile ilk başarılı adayda durur', () async {
    final tried = <Uri>[];
    final opened = await openArinSocialProfile(
      ArinSocialNetwork.instagram,
      launch: (uri) async {
        tried.add(uri);
        return true;
      },
    );
    expect(opened, isTrue);
    expect(tried, [Uri.parse('instagram://user?username=arinapptr')]);
  });

  test('openArinSocialProfile ilk aday düşünce web yedeğine geçer', () async {
    final tried = <Uri>[];
    final opened = await openArinSocialProfile(
      ArinSocialNetwork.instagram,
      launch: (uri) async {
        tried.add(uri);
        return uri.scheme == 'https';
      },
    );
    expect(opened, isTrue);
    expect(tried, arinSocialProfileUris(ArinSocialNetwork.instagram));
  });

  test('openArinSocialProfile tüm adaylar düşünce false döner', () async {
    final opened = await openArinSocialProfile(
      ArinSocialNetwork.tiktok,
      launch: (_) async => false,
    );
    expect(opened, isFalse);
  });

  test('openArinSocialProfile uygulama yoksa şemayı atlar', () async {
    final tried = <Uri>[];
    final opened = await openArinSocialProfile(
      ArinSocialNetwork.instagram,
      canLaunch: (uri) async => uri.scheme != 'instagram',
      launch: (uri) async {
        tried.add(uri);
        return true;
      },
    );
    expect(opened, isTrue);
    expect(tried, [Uri.parse('https://www.instagram.com/arinapptr/')]);
  });

  test('openArinSocialProfile fırlatan adayı atlar', () async {
    final opened = await openArinSocialProfile(
      ArinSocialNetwork.instagram,
      launch: (uri) async {
        if (uri.scheme == 'instagram') {
          throw StateError('no app');
        }
        return true;
      },
    );
    expect(opened, isTrue);
  });

  testWidgets('kart Instagram ve TikTok satırlarını gösterir', (tester) async {
    final launched = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SettingsSocialFollowCard(
            onDark: true,
            launch: (uri) async {
              launched.add(uri);
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('@arinapptr'), findsNWidgets(2));

    await tester.tap(find.text('Instagram'));
    await tester.pumpAndSettle();
    expect(launched, [Uri.parse('instagram://user?username=arinapptr')]);

    await tester.tap(find.text('TikTok'));
    await tester.pumpAndSettle();
    expect(
      launched.last,
      Uri.parse('https://www.tiktok.com/@arinapptr'),
    );
  });

  testWidgets('profil açılmazsa kullanıcıya toast gösterir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SettingsSocialFollowCard(
            onDark: true,
            launch: (_) async => false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('TikTok'));
    await tester.pumpAndSettle();
    expect(
      find.text('Profil açılamadı. Daha sonra tekrar dene.'),
      findsOneWidget,
    );
  });
}
