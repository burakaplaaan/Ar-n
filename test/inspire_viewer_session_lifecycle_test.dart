import 'package:arin/l10n/app_localizations.dart';
import 'package:arin/data/models/inspiration_card_model.dart';
import 'package:arin/core/providers/shared_preferences_provider.dart';
import 'package:arin/presentation/inspire/inspiration_search.dart';
import 'package:arin/presentation/inspire/inspire_viewer_page.dart';
import 'package:arin/presentation/inspire/inspire_viewer_session_provider.dart';
import 'package:arin/presentation/shared/mixins/review_prompt_on_exit_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('viewer dispose clears its deck session', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cards = <InspirationCardModel>[];
    final deck = InspireViewerDeckExtra(cards: cards, initialIndex: 0);
    container.read(inspireViewerDeckSessionProvider.notifier).state = deck;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InspireViewerPage(initialIndex: 0, deckOverride: deck.cards),
        ),
      ),
    );

    expect(container.read(inspireViewerDeckSessionProvider), same(deck));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(container.read(inspireViewerDeckSessionProvider), isNull);
  });

  testWidgets('review tracking can exit after meaningful use', (tester) async {
    SharedPreferences.setMockInitialValues({'review_disabled_forever': true});
    final preferences = await SharedPreferences.getInstance();
    var now = DateTime(2026, 7, 30);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(home: _TrackedFeature(now: () => now)),
      ),
    );
    now = now.add(const Duration(seconds: 11));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const SizedBox(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed viewer does not clear a newer deck session', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final oldDeck = InspireViewerDeckExtra(
      cards: List<InspirationCardModel>.empty(),
      initialIndex: 0,
    );
    final newDeck = InspireViewerDeckExtra(
      cards: List<InspirationCardModel>.empty(),
      initialIndex: 0,
    );
    container.read(inspireViewerDeckSessionProvider.notifier).state = oldDeck;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InspireViewerPage(initialIndex: 0, deckOverride: oldDeck.cards),
        ),
      ),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    container.read(inspireViewerDeckSessionProvider.notifier).state = newDeck;
    await tester.pump();
    await tester.pump();

    expect(container.read(inspireViewerDeckSessionProvider), same(newDeck));
  });
}

class _TrackedFeature extends ConsumerStatefulWidget {
  const _TrackedFeature({required this.now});

  final DateTime Function() now;

  @override
  ConsumerState<_TrackedFeature> createState() => _TrackedFeatureState();
}

class _TrackedFeatureState extends ConsumerState<_TrackedFeature>
    with ReviewPromptOnExitMixin {
  @override
  DateTime reviewPromptNow() => widget.now();

  @override
  void initState() {
    super.initState();
    startReviewPromptTracking();
  }

  @override
  void dispose() {
    maybeRequestReviewOnExit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
