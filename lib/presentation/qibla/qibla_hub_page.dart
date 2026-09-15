// lib/presentation/qibla/qibla_hub_page.dart
// Kıble sekmesi kökü: araç paneli + iç Navigator ile pusula ekranı.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../data/services/ad_gate_service.dart';
import '../../data/services/audio_session_coordinator.dart';
import '../../data/services/paywall_prompt_service.dart';
import 'islamic_ai/islamic_ai_page.dart';
import 'qibla_hub_navigator_key.dart';
import 'qibla_hub_open.dart';
import 'qibla_page.dart';
import 'qibla_tool_opening_gate.dart';
import 'qibla_tool_page_route.dart';
import 'qibla_tools_dashboard_page.dart';
import 'qibla_nested_swipe_back.dart';
import 'qibla_shell_swipe_provider.dart';
import 'prayer_circle/prayer_circle_page.dart';
import 'hilal_duel/hilal_duel_page.dart';
import 'social/social_page.dart';
import 'zikir_matik_page.dart';
import 'healing_frequencies/healing_frequencies_page.dart';
import 'quran/quran_library_page.dart';
import 'quran/quran_reader_page.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_surah_catalog.dart';
import '../willpower/breathing_exercise_page.dart';

abstract final class QiblaHubRoutes {
  static const String dashboard = '/';
  static const String compass = '/compass';
  static const String zikir = '/zikir';
  static const String breathing = '/breathing';
  static const String healing = '/healing';
  static const String prayerCircle = '/prayer-circle';
  static const String hilalDuel = '/hilal-duel';
  static const String social = '/social';
  static const String islamicAi = '/islamic-ai';
  static const String quran = '/quran';
  static const String quranReader = '/quran/read';
}

/// [Navigator] gözlemcisi: araç paneli dışına çıkıldığında shell kaydırmayı kilitler.
class _QiblaHubShellSwipeObserver extends NavigatorObserver {
  _QiblaHubShellSwipeObserver(this._ref);

  final WidgetRef _ref;

  void _applyForTop(Route<dynamic>? top) {
    final name = top?.settings.name;
    final atDashboard = name == QiblaHubRoutes.dashboard;
    _ref.read(qiblaHubBlocksShellSwipeProvider.notifier).state = !atDashboard;
    final duel = name == QiblaHubRoutes.hilalDuel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ref.read(hilalDuelActiveProvider) == duel) return;
      _ref.read(hilalDuelActiveProvider.notifier).state = duel;
    });
  }

  static bool _isQuranRoute(String? name) {
    return name == QiblaHubRoutes.quran || name == QiblaHubRoutes.quranReader;
  }

  void _pauseLongAudioIfLeaving(Route<dynamic>? from, Route<dynamic>? to) {
    final fromHealing = from?.settings.name == QiblaHubRoutes.healing;
    final toHealing = to?.settings.name == QiblaHubRoutes.healing;
    if (fromHealing && !toHealing) {
      unawaited(AudioSessionCoordinator.pauseOwner(AudioSessionOwner.healing));
    }
    final fromQuran = _isQuranRoute(from?.settings.name);
    final toQuran = _isQuranRoute(to?.settings.name);
    if (fromQuran && !toQuran) {
      unawaited(AudioSessionCoordinator.pauseOwner(AudioSessionOwner.quran));
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pauseLongAudioIfLeaving(previousRoute, route);
    _applyForTop(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pauseLongAudioIfLeaving(route, previousRoute);
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
    _pauseLongAudioIfLeaving(oldRoute, newRoute);
    if (newRoute != null) _applyForTop(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pauseLongAudioIfLeaving(route, previousRoute);
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
  String? _consumedOpenQuery;

  _QiblaHubShellSwipeObserver get _observer =>
      _shellSwipeObserver ??= _QiblaHubShellSwipeObserver(ref);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(qiblaHubBlocksShellSwipeProvider.notifier).state = false;
      _openFromQuery();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellSwipeObserver ??= _QiblaHubShellSwipeObserver(ref);
    _openFromQuery();
  }

  void _openFromQuery() {
    String? open;
    try {
      open = GoRouterState.of(context).uri.queryParameters['open'];
    } catch (_) {
      return;
    }
    if (open == null || open.isEmpty) {
      _consumedOpenQuery = null;
      return;
    }
    if (open == _consumedOpenQuery) return;
    final route = switch (open) {
      'zikir' => QiblaHubRoutes.zikir,
      'healing' => QiblaHubRoutes.healing,
      'compass' => QiblaHubRoutes.compass,
      'breathing' => QiblaHubRoutes.breathing,
      'prayer-circle' || 'prayer_circle' => QiblaHubRoutes.prayerCircle,
      'hilal-duel' || 'hilal_duel' => QiblaHubRoutes.hilalDuel,
      'social' => QiblaHubRoutes.social,
      'islamic-ai' => QiblaHubRoutes.islamicAi,
      'quran' || 'kuran' || 'mushaf' => QiblaHubRoutes.quran,
      _ => null,
    };
    if (route == null) return;
    _consumedOpenQuery = open;
    unawaited(() async {
      final ok = await pushQiblaHubRoute(route);
      if (!mounted) return;
      if (!ok) {
        _consumedOpenQuery = null;
        return;
      }
      context.go(AppRoutes.qibla);
    }());
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
              builder: (context) => _wrapTool(
                QiblaPage(exitToHomeOnBack: fromHome),
                ad: AdGatePlacement.qiblaSession,
                onBack: fromHome ? () => context.go(AppRoutes.home) : null,
              ),
            );
          case QiblaHubRoutes.zikir:
            return _toolRoute(
              settings: settings,
              builder: (_) => _wrapTool(
                const ZikirMatikPage(),
                ad: AdGatePlacement.zikirSession,
              ),
            );
          case QiblaHubRoutes.breathing:
            return _toolRoute(
              settings: settings,
              builder: (_) => _wrapTool(const BreathingExercisePage()),
            );
          case QiblaHubRoutes.healing:
            return _toolRoute(
              settings: settings,
              builder: (_) => _wrapTool(
                const HealingFrequenciesPage(),
                ad: AdGatePlacement.healingSession,
              ),
            );
          case QiblaHubRoutes.prayerCircle:
            return _toolRoute(
              settings: settings,
              builder: (_) => _wrapTool(const PrayerCirclePage()),
            );
          case QiblaHubRoutes.hilalDuel:
            // NestedSwipeBack zorla pop eder; eşleşme iptali/iade HilalDuelPage içinde.
            return _toolRoute(
              settings: settings,
              builder: (_) =>
                  _wrapTool(const HilalDuelPage(), swipeBack: false),
            );
          case QiblaHubRoutes.social:
            return _toolRoute(
              settings: settings,
              builder: (_) => _wrapTool(const SocialPage()),
            );
          case QiblaHubRoutes.quran:
            return _toolRoute(
              settings: settings,
              builder: (_) => _wrapTool(const QuranLibraryPage()),
            );
          case QiblaHubRoutes.quranReader:
            final raw = settings.arguments;
            var surah = 1;
            int? ayah;
            var autoplay = false;
            if (raw is QuranReaderArgs) {
              surah = raw.surah.clamp(1, 114);
              ayah = raw.ayah;
              autoplay = raw.autoplay;
            } else if (raw is Map) {
              surah = ((raw['surah'] as num?)?.toInt() ?? 1).clamp(1, 114);
              ayah = (raw['ayah'] as num?)?.toInt();
              autoplay = raw['autoplay'] == true;
            }
            if (ayah != null) {
              ayah = ayah.clamp(
                1,
                QuranSurahCatalog.byNumber(surah).ayahCount,
              );
            }
            return _toolRoute(
              settings: settings,
              builder: (_) => _wrapTool(
                QuranReaderPage(
                  surah: surah,
                  initialAyah: ayah,
                  autoplay: autoplay,
                ),
              ),
            );
          case QiblaHubRoutes.islamicAi:
            return _toolRoute(
              settings: settings,
              builder: (_) => _wrapTool(const IslamicAiPage()),
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

  Widget _wrapTool(
    Widget page, {
    AdGatePlacement? ad,
    VoidCallback? onBack,
    bool swipeBack = true,
  }) {
    final gated = QiblaToolOpeningGate(adPlacement: ad, child: page);
    if (!swipeBack) return gated;
    return QiblaNestedSwipeBack(onBack: onBack, child: gated);
  }

  PageRoute<void> _toolRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return qiblaToolPageRoute(settings: settings, builder: builder);
  }
}
