// lib/presentation/qibla/qibla_hub_page.dart
// Kıble sekmesi kökü: araç paneli + iç Navigator ile pusula ekranı.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../data/services/audio_session_coordinator.dart';
import '../../data/services/paywall_prompt_service.dart';
import 'islamic_ai/islamic_ai_page.dart';
import 'qibla_hub_navigator_key.dart';
import 'qibla_page.dart';
import 'qibla_tools_dashboard_page.dart';
import 'qibla_nested_swipe_back.dart';
import 'qibla_shell_swipe_provider.dart';
import 'prayer_circle/prayer_circle_page.dart';
import 'hilal_duel/hilal_duel_page.dart';
import 'zikir_matik_page.dart';
import 'healing_frequencies/healing_frequencies_page.dart';
import '../willpower/breathing_exercise_page.dart';

abstract final class QiblaHubRoutes {
  static const String dashboard = '/';
  static const String compass = '/compass';
  static const String zikir = '/zikir';
  static const String breathing = '/breathing';
  static const String healing = '/healing';
  static const String prayerCircle = '/prayer-circle';
  static const String hilalDuel = '/hilal-duel';
  static const String islamicAi = '/islamic-ai';
}

/// [Navigator] gözlemcisi: araç paneli dışına çıkıldığında shell kaydırmayı kilitler.
class _QiblaHubShellSwipeObserver extends NavigatorObserver {
  _QiblaHubShellSwipeObserver(this._ref);

  final WidgetRef _ref;

  void _applyForTop(Route<dynamic>? top) {
    final name = top?.settings.name;
    final atDashboard = name == QiblaHubRoutes.dashboard;
    _ref.read(qiblaHubBlocksShellSwipeProvider.notifier).state = !atDashboard;
  }

  void _pauseHealingIfLeaving(Route<dynamic>? from, Route<dynamic>? to) {
    final fromHealing = from?.settings.name == QiblaHubRoutes.healing;
    final toHealing = to?.settings.name == QiblaHubRoutes.healing;
    if (fromHealing && !toHealing) {
      unawaited(AudioSessionCoordinator.pauseOwner(AudioSessionOwner.healing));
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pauseHealingIfLeaving(previousRoute, route);
    _applyForTop(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pauseHealingIfLeaving(route, previousRoute);
    _applyForTop(previousRoute);
    if (previousRoute?.settings.name == QiblaHubRoutes.dashboard &&
        route.settings.name != QiblaHubRoutes.islamicAi) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = qiblaHubNavigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        unawaited(
          PaywallPromptService.maybeShowAfterFeatureUse(
            context: ctx,
            ref: _ref,
          ),
        );
      });
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _pauseHealingIfLeaving(oldRoute, newRoute);
    if (newRoute != null) _applyForTop(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pauseHealingIfLeaving(route, previousRoute);
    _applyForTop(previousRoute);
  }
}

/// Shell ve `/qibla` rotası bu widget’ı kullanır; alt rota yığını hub içinde kalır.
class QiblaHubPage extends ConsumerStatefulWidget {
  const QiblaHubPage({super.key});

  @override
  ConsumerState<QiblaHubPage> createState() => _QiblaHubPageState();
}

class _QiblaHubPageState extends ConsumerState<QiblaHubPage> {
  _QiblaHubShellSwipeObserver? _shellSwipeObserver;

  _QiblaHubShellSwipeObserver get _observer =>
      _shellSwipeObserver ??= _QiblaHubShellSwipeObserver(ref);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(qiblaHubBlocksShellSwipeProvider.notifier).state = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellSwipeObserver ??= _QiblaHubShellSwipeObserver(ref);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: qiblaHubNavigatorKey,
      observers: [_observer],
      initialRoute: QiblaHubRoutes.dashboard,
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case QiblaHubRoutes.compass:
            final args = settings.arguments is Map
                ? settings.arguments as Map
                : const {};
            final fromHome = args['fromHomeShortcut'] == true;
            return _toolRoute(
              settings: settings,
              builder: (context) => QiblaNestedSwipeBack(
                onBack: fromHome ? () => context.go(AppRoutes.home) : null,
                child: QiblaPage(exitToHomeOnBack: fromHome),
              ),
            );
          case QiblaHubRoutes.zikir:
            return _toolRoute(
              settings: settings,
              builder: (_) =>
                  const QiblaNestedSwipeBack(child: ZikirMatikPage()),
            );
          case QiblaHubRoutes.breathing:
            return _toolRoute(
              settings: settings,
              builder: (_) =>
                  const QiblaNestedSwipeBack(child: BreathingExercisePage()),
            );
          case QiblaHubRoutes.healing:
            return _toolRoute(
              settings: settings,
              builder: (_) =>
                  const QiblaNestedSwipeBack(child: HealingFrequenciesPage()),
            );
          case QiblaHubRoutes.prayerCircle:
            return _toolRoute(
              settings: settings,
              builder: (_) =>
                  const QiblaNestedSwipeBack(child: PrayerCirclePage()),
            );
          case QiblaHubRoutes.hilalDuel:
            // NestedSwipeBack zorla pop eder; eşleşme iptali/iade HilalDuelPage içinde.
            return _toolRoute(
              settings: settings,
              builder: (_) => const HilalDuelPage(),
            );
          case QiblaHubRoutes.islamicAi:
            return _toolRoute(
              settings: settings,
              builder: (_) =>
                  const QiblaNestedSwipeBack(child: IslamicAiPage()),
            );
          case QiblaHubRoutes.dashboard:
          default:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const QiblaToolsDashboardPage(),
            );
        }
      },
    );
  }

  PageRoute<void> _toolRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    // opaque:false — fade sırasında altındaki dashboard görünsün (siyah flash yok).
    return PageRouteBuilder<void>(
      settings: settings,
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
