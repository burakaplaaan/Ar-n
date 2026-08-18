import 'package:arin/core/providers/shared_preferences_provider.dart';
import 'package:arin/core/router/app_router.dart';
import 'package:arin/l10n/app_localizations_tr.dart';
import 'package:arin/presentation/onboarding/app_tour/app_tour_anchor.dart';
import 'package:arin/presentation/onboarding/app_tour/app_tour_controller.dart';
import 'package:arin/presentation/onboarding/app_tour/app_tour_keys.dart';
import 'package:arin/presentation/onboarding/app_tour/app_tour_layout.dart';
import 'package:arin/presentation/onboarding/app_tour/app_tour_step.dart';
import 'package:arin/presentation/onboarding/app_tour/post_tour_widget_prompt.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final l10n = AppLocalizationsTr();

  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('katalog tüm hedefleri bir kez kapsar ve finale ile biter', () {
    const steps = AppTourCatalog.steps;
    expect(steps, isNotEmpty);
    expect(steps.last.finale, isTrue);
    expect(steps.last.id, isNull);
    expect(steps.where((s) => s.finale).length, 1);

    final ids = steps.map((s) => s.id).whereType<AppTourTargetId>().toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.toSet(), AppTourTargetId.values.toSet());

    for (final step in steps) {
      expect(step.title(l10n), isNotEmpty);
      expect(step.body(l10n), isNotEmpty);
      expect(
        {
          AppRoutes.home,
          AppRoutes.qibla,
          AppRoutes.habits,
          AppRoutes.inspire,
          AppRoutes.settings,
        },
        contains(step.route),
      );
    }
  });

  test('ekranda kayan veya ucundan görünen dikdörtgen reddedilir', () {
    const screen = Size(390, 844);
    expect(
      AppTourKeys.isSettledOnScreen(
        const Rect.fromLTWH(-382, 80, 390, 120),
        screen,
      ),
      isFalse,
    );
    expect(
      AppTourKeys.isSettledOnScreen(
        const Rect.fromLTWH(8, 80, 374, 120),
        screen,
      ),
      isTrue,
    );
  });

  test('açıklama deliğin altında yer varsa alta, yoksa üste konur', () {
    const screen = Size(390, 844);
    const reserved = 120.0;
    expect(
      AppTourLayout.tooltipSide(
        hole: const Rect.fromLTWH(24, 80, 342, 90),
        screen: screen,
        reservedBottom: reserved,
      ),
      AppTourTooltipSide.below,
    );
    expect(
      AppTourLayout.tooltipSide(
        hole: const Rect.fromLTWH(40, 760, 48, 48),
        screen: screen,
        reservedBottom: reserved,
      ),
      AppTourTooltipSide.above,
    );
  });

  test('alt menü deliğinde İlerle deliğin üstünde, açıklama da CTA üstünde', () {
    const screen = Size(390, 844);
    const hole = Rect.fromLTWH(40, 760, 48, 48);
    final slots = AppTourLayout.slots(
      hole: hole,
      screen: screen,
      safeBottom: 34,
    );
    expect(slots.ctaBottom, greaterThan(screen.height - hole.top));
    expect(slots.tooltipReservedBottom, greaterThan(slots.ctaBottom));
    expect(slots.side, AppTourTooltipSide.above);
    expect(slots.ctaBottom + AppTourLayout.ctaBlockHeight, lessThan(hole.top));
  });

  test('tur yalnızca onboarding + pending iken başlar', () async {
    final container = await containerWith({
      'onboarding_completed': true,
      kAppTourPendingKey: true,
    });
    final controller = container.read(appTourControllerProvider.notifier);
    expect(controller.isCompleted, isFalse);
    controller.maybeStart();
    expect(container.read(appTourControllerProvider).active, isTrue);
    expect(container.read(appTourControllerProvider).stepIndex, 0);
    controller.maybeStart();
    expect(container.read(appTourControllerProvider).stepIndex, 0);
  });

  test('mevcut kurulumda pending yoksa tur başlamaz', () async {
    final container = await containerWith({
      'onboarding_completed': true,
    });
    container.read(appTourControllerProvider.notifier).maybeStart();
    expect(container.read(appTourControllerProvider).active, isFalse);
  });

  test('tamamlanmış tur yeniden başlamaz', () async {
    final container = await containerWith({
      'onboarding_completed': true,
      kAppTourPendingKey: true,
      kAppTourCompletedKey: true,
    });
    container.read(appTourControllerProvider.notifier).maybeStart();
    expect(container.read(appTourControllerProvider).active, isFalse);
  });

  testWidgets('aynı hedef iki kez ağaçta olsa da donmaz', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 390,
          height: 844,
          child: Stack(
            children: [
              AppTourAnchor(
                id: AppTourTargetId.assistantFab,
                child: SizedBox(width: 40, height: 20),
              ),
              AppTourAnchor(
                id: AppTourTargetId.assistantFab,
                child: SizedBox(width: 48, height: 24),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(AppTourKeys.contextOf(AppTourTargetId.assistantFab), isNotNull);
    expect(AppTourKeys.measure(AppTourTargetId.assistantFab), isNotNull);
  });

  test('tur bitince widget daveti bir kez bekler', () async {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    await persistAppTourFinished(prefs);
    expect(prefs.getBool(kAppTourCompletedKey), isTrue);
    expect(prefs.getBool(kAppTourPendingKey), isFalse);
    expect(prefs.getBool(kAppTourWidgetPromptPendingKey), isTrue);
    expect(
      shouldOfferPostTourWidgetPrompt(promptPending: true),
      isTrue,
    );
    expect(
      shouldOfferPostTourWidgetPrompt(promptPending: false),
      isFalse,
    );
  });

  test('onboarding bitmeden tur başlamaz', () async {
    final container = await containerWith({kAppTourPendingKey: true});
    container.read(appTourControllerProvider.notifier).maybeStart();
    expect(container.read(appTourControllerProvider).active, isFalse);
  });

  test('wipe sonrası pending ile tur aynı süreçte yeniden başlar', () async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      kAppTourPendingKey: true,
    });
    TestWidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    container.read(appTourControllerProvider.notifier).maybeStart();
    expect(container.read(appTourControllerProvider).active, isTrue);

    await prefs.setBool(kAppTourCompletedKey, true);
    await prefs.setBool(kAppTourPendingKey, false);
    container.invalidate(appTourControllerProvider);
    expect(container.read(appTourControllerProvider).active, isFalse);

    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool(kAppTourPendingKey, true);
    await prefs.setBool(kAppTourCompletedKey, false);
    container.read(appTourControllerProvider.notifier).maybeStart();
    expect(container.read(appTourControllerProvider).active, isTrue);
    expect(container.read(appTourControllerProvider).stepIndex, 0);
  });
}
