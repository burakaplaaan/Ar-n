// lib/core/router/app_router.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/arin_analytics.dart';
import '../providers/shared_preferences_provider.dart';
import 'app_router_refresh.dart';
import '../../presentation/onboarding/onboarding_page.dart';
import '../../presentation/shared/providers/user_profile_providers.dart';
import '../../presentation/onboarding/onboarding_survey_page.dart';
import '../../presentation/onboarding/app_prepare_page.dart';
import '../../presentation/home/home_page.dart';
import '../../presentation/habits/add_habit_page.dart';
import '../../presentation/habits/custom_habit_detail_page.dart';
import '../../presentation/habits/habit_management_page.dart';
import '../../presentation/willpower/willpower_hub_page.dart';
import '../../presentation/willpower/build_program_setup_page.dart';
import '../../presentation/willpower/build_program_detail_page.dart';
import '../../presentation/willpower/quit_template_picker_page.dart';
import '../../presentation/willpower/quit_onboarding_flow_page.dart';
import '../../presentation/willpower/quit_program_home_page.dart';
import '../../presentation/willpower/breathing_exercise_page.dart';
import '../../presentation/willpower/namaz_program_page.dart';
import '../../presentation/habits/habit_calendar_page.dart';
import '../../presentation/kaza/kaza_calculator_page.dart';
import '../../presentation/kaza/kaza_tracker_page.dart';
import '../../presentation/qibla/qibla_hub_page.dart';
import '../../presentation/qibla/prayer_circle/prayer_circle_page.dart';
import '../../presentation/qibla/hilal_duel/hilal_duel_page.dart';
import '../../presentation/settings/admin_content_page.dart';
import '../../presentation/settings/admin_notifications_page.dart';
import '../../presentation/settings/admin_performance_page.dart';
import '../../presentation/settings/settings_page.dart';
import '../../presentation/settings/widget_unlock_page.dart';
import '../../data/services/widget_access_service.dart';
import '../../presentation/settings/language_settings_page.dart';
import '../../presentation/settings/about_arin_page.dart';
import '../../presentation/settings/contact_support_page.dart';
import '../../presentation/settings/privacy_policy_page.dart';
import '../../presentation/settings/support_arin_page.dart';
import '../../presentation/settings/widget_center_page.dart';
import '../../presentation/settings/notifications_settings_page.dart';
import '../../presentation/settings/prayer_notifications_detail_page.dart';
import '../../presentation/inspire/saved_inspiration_page.dart';
import '../../presentation/inspire/inspire_explore_page.dart';
import '../../presentation/inspire/inspiration_search.dart';
import '../../presentation/inspire/inspire_viewer_page.dart';
import '../../presentation/inspire/inspire_viewer_session_provider.dart';
import '../../presentation/moment_verse/moment_verse_page.dart';
import '../../presentation/assistant/assistant_page.dart';
import '../../presentation/assistant/assistant_return_pop_guard.dart';
import '../../presentation/premium/premium_page.dart';
import '../../presentation/shared/providers/auth_providers.dart';
import '../../presentation/shared/providers/willpower_hub_nav_provider.dart';
import '../../presentation/assistant/widgets/assistant_fab_host.dart';
import '../../presentation/shared/widgets/arin_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String onboardingSurvey = '/onboarding/survey';
  static const String appPrepare = '/app-prepare';
  static const String home = '/home';
  static const String premium = '/premium';
  static const String qibla = '/qibla';

  /// Kıble hub içinde iç araç aç (`zikir`, `healing`, `compass`…).
  static String qiblaOpen(String tool) => Uri(
    path: qibla,
    queryParameters: {'open': tool},
  ).toString();
  static const String prayerCircle = '/qibla/prayer-circle';
  static String prayerCircleRequest(String requestId) => Uri(
    path: prayerCircle,
    queryParameters: {'request': requestId},
  ).toString();
  static const String hilalDuel = '/qibla/hilal-duel';
  static const String assistant = '/assistant';
  static const String habits = '/habits';

  /// Irade hub’ında Arınma sekmesini aç (Gelişim’e sıfırlamayı önler).
  static String get habitsArinmaTab => '$habits?tab=arinma';

  /// İrade hub’ında Gelişim sekmesini aç (ör. İbadet ekranından Kapat).
  static String get habitsGelisimTab => '$habits?tab=gelisim';
  static const String addHabit = '/habits/add';
  static const String habitManagement = '/habits/manage';
  static const String habitCalendar = '/habits/calendar';

  static String customHabitDetail(String habitId) => '/habits/custom/$habitId';

  static String willBuildSetup(String templateId) =>
      '/habits/will/build/setup/$templateId';

  static String willBuildDetail(String habitId) =>
      '/habits/will/build/$habitId';

  static const String willQuitTemplates = '/habits/will/quit/templates';

  static String willQuitOnboarding(String habitId) =>
      '/habits/will/quit/$habitId/onboarding';

  static String willQuitHome(String habitId, {String? tab}) {
    if (tab == null || tab.isEmpty) return '/habits/will/quit/$habitId';
    return Uri(
      path: '/habits/will/quit/$habitId',
      queryParameters: {'tab': tab},
    ).toString();
  }

  /// [programId] isteğe bağlı sorgu parametresi.
  static String willBreathing([String? programId]) {
    if (programId == null || programId.isEmpty) {
      return '/habits/will/breathing';
    }
    return '/habits/will/breathing?programId=$programId';
  }

  static String willNamaz(
    String habitId, {
    bool fromGelisimSetup = false,
    String? returnOrigin,
  }) {
    final query = <String, String>{};
    if (fromGelisimSetup) query['from'] = 'gelisim_setup';
    if (returnOrigin != null && returnOrigin.isNotEmpty) {
      query['origin'] = returnOrigin;
    }
    final uri = Uri(
      path: '/habits/will/namaz/$habitId',
      queryParameters: query,
    );
    return uri.toString();
  }

  /// Kaza namazı — hesap ve takip (cihaz içi).
  static const String kazaCalculator = '/habits/kaza';
  static const String kazaTracker = '/habits/kaza/tracker';

  static const String settings = '/settings';

  /// Ayarlar → Kaydedilenler (Keşfet kayıtları).
  static const String settingsSaved = '/settings/saved';

  /// Ayarlar → Hakkında.
  static const String settingsAbout = '/settings/about';

  /// Ayarlar → Widget Merkezi.
  static const String settingsWidgets = '/settings/widgets';

  /// Ayarlar → Gizlilik politikası.
  static const String settingsPrivacyPolicy = '/settings/privacy';

  /// Ayarlar → İçerik yönetimi (yalnızca admin e-postaları).
  static const String settingsAdmin = '/settings/admin';

  /// Admin → Bildirim yönetimi (havuz + otomatik + manuel yayınlar).
  static const String settingsAdminNotifications =
      '/settings/admin/notifications';

  /// Admin → İçerik, bildirim ve widget performansı.
  static const String settingsAdminPerformance = '/settings/admin/performance';

  /// Ayarlar → Bildirimler.
  static const String settingsNotifications = '/settings/notifications';

  /// Ayarlar → Dil ayarları.
  static const String settingsLanguage = '/settings/language';

  /// Ayarlar → Bize ulaşın.
  static const String settingsContact = '/settings/contact';

  /// Ayarlar → Tek seferlik destek paketleri.
  static const String settingsSupport = '/settings/support';

  /// Bildirimler → Namaz vakit ve ses (tek kaynak kart).
  static const String settingsNotificationsPrayer =
      '/settings/notifications/vakit';

  /// Anın Ayeti — FCM bildirim tıklamasından açılan özel tam ekran sayfa.
  /// Shell dışında (alt nav bar yok); 5 dakikalık geçerlilik penceresi.
  static const String momentVerse = '/moment-verse';

  /// Widget kilidi açma sayfası — shell dışında, tam ekran.
  static String widgetUnlock(String kindId) => '/widget-unlock/$kindId';

  /// Keşfet ızgarası — shell içinde; alt bar görünür.
  static const String inspire = '/inspire';

  /// Dikey tam ekran kart görünümü; [index] ızgara indeksi.
  /// [openNonce] her tıklamada benzersiz olmalı — aksi halde aynı URL ile ikinci
  /// açılışta GoRouter sayfayı yenilemeyebilir ve eski deste/null hatası oluşur.
  static String inspireView(int index, {required int openNonce}) =>
      '/inspire/view/$index?o=$openNonce';
}

/// `/habits/...` alt sayfalarından çıkış: stack’te geri varsa `pop`, yoksa irade sekmesi kökü.
/// [willpowerHubReturnToArinmaProvider] true ise kök `/habits?tab=arinma` olur.
void popOrGoWillpowerHub(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final toArinma = container.read(willpowerHubReturnToArinmaProvider);
  if (toArinma) {
    container.read(willpowerHubReturnToArinmaProvider.notifier).state = false;
    context.go(AppRoutes.habitsArinmaTab);
    return;
  }
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(AppRoutes.habits);
}

/// [onboarding_completed] açıkça false ise Hive'a bakılmaz (çıkış sonrası).
bool _onboardingDone(SharedPreferences prefs, Ref ref) {
  final flag = prefs.getBool('onboarding_completed');
  if (flag == false) return false;
  try {
    final hiveDone = ref
        .read(userProfileRepositoryProvider)
        .isOnboardingCompleted;
    if (flag == true) return hiveDone;
    return hiveDone;
  } catch (_) {
    return flag == true;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  final refresh = ref.read(appRouterRefreshProvider);
  ref.listen(isCurrentUserAdminProvider, (_, __) {
    refresh.notifyAuthOrOnboarding();
  });
  ref.listen(authUserProvider, (_, __) {
    refresh.notifyAuthOrOnboarding();
  });

  final onboardingDone = _onboardingDone(prefs, ref);

  // Analytics: Firebase hazırsa her route değişiminde otomatik screen_view
  // yazar. Firebase yoksa observer null → listeye eklenmez, davranış değişmez.
  final analyticsObserver = ArinAnalytics.observerIfAvailable();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: onboardingDone ? AppRoutes.home : AppRoutes.onboarding,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    observers: analyticsObserver == null ? const [] : [analyticsObserver],
    redirect: (BuildContext context, GoRouterState state) {
      final done = _onboardingDone(prefs, ref);
      final path = state.uri.path;
      final adminAsync = ref.read(isCurrentUserAdminProvider);

      if (!done) {
        if (path == AppRoutes.appPrepare) {
          return AppRoutes.onboarding;
        }
        final allowed =
            path == AppRoutes.onboarding || path == AppRoutes.onboardingSurvey;
        if (!allowed) {
          return AppRoutes.onboarding;
        }
        return null;
      }

      if (done &&
          (path == AppRoutes.onboarding ||
              path == AppRoutes.onboardingSurvey)) {
        return AppRoutes.home;
      }
      if (done && (path.isEmpty || path == '/')) {
        return AppRoutes.home;
      }
      if (path.startsWith(AppRoutes.settingsAdmin)) {
        if (adminAsync.isLoading) {
          return null;
        }
        if (adminAsync.asData?.value != true) {
          return AppRoutes.settings;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _page(state, const OnboardingPage()),
      ),
      GoRoute(
        path: AppRoutes.onboardingSurvey,
        pageBuilder: (context, state) =>
            _page(state, const OnboardingSurveyPage()),
      ),
      GoRoute(
        path: AppRoutes.appPrepare,
        pageBuilder: (context, state) => _page(state, const AppPreparePage()),
      ),
      GoRoute(
        path: AppRoutes.premium,
        pageBuilder: (context, state) =>
            _page(state, const AssistantFabHost(child: PremiumPage())),
      ),
      GoRoute(
        path: '/widget-unlock/:kind',
        pageBuilder: (context, state) {
          final kindId = state.pathParameters['kind'] ?? '';
          final kind =
              ArinWidgetAccessKind.fromId(kindId) ?? ArinWidgetAccessKind.quote;
          return _page(
            state,
            AssistantFabHost(child: WidgetUnlockPage(kind: kind)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.momentVerse,
        pageBuilder: (context, state) =>
            _page(state, const AssistantFabHost(child: MomentVersePage())),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => ArinShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _page(state, const HomePage()),
          ),
          GoRoute(
            path: AppRoutes.qibla,
            pageBuilder: (context, state) => _page(state, const QiblaHubPage()),
          ),
          GoRoute(
            path: AppRoutes.prayerCircle,
            pageBuilder: (context, state) => _page(
              state,
              PrayerCirclePage(
                focusRequestId: state.uri.queryParameters['request'],
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.hilalDuel,
            pageBuilder: (context, state) =>
                _page(state, const HilalDuelPage()),
          ),
          GoRoute(
            path: AppRoutes.assistant,
            pageBuilder: (context, state) =>
                _page(state, const AssistantPage()),
          ),
          GoRoute(
            path: AppRoutes.habits,
            pageBuilder: (context, state) =>
                _page(state, const WillpowerHubPage()),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) =>
                    _page(state, const AddHabitPage()),
              ),
              GoRoute(
                path: 'custom/:habitId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['habitId']!;
                  return _page(state, CustomHabitDetailPage(habitId: id));
                },
              ),
              GoRoute(
                path: 'manage',
                pageBuilder: (context, state) =>
                    _page(state, const HabitManagementPage()),
              ),
              GoRoute(
                path: 'calendar',
                pageBuilder: (context, state) =>
                    _page(state, const HabitCalendarPage()),
              ),
              GoRoute(
                path: 'kaza',
                pageBuilder: (context, state) =>
                    _page(state, const KazaCalculatorPage()),
                routes: [
                  GoRoute(
                    path: 'tracker',
                    pageBuilder: (context, state) =>
                        _page(state, const KazaTrackerPage()),
                  ),
                ],
              ),
              GoRoute(
                path: 'will/build/setup/:templateId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['templateId']!;
                  return _page(state, BuildProgramSetupPage(templateId: id));
                },
              ),
              GoRoute(
                path: 'will/build/:habitId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['habitId']!;
                  return _page(state, BuildProgramDetailPage(habitId: id));
                },
              ),
              GoRoute(
                path: 'will/quit/templates',
                pageBuilder: (context, state) =>
                    _page(state, const QuitTemplatePickerPage()),
              ),
              GoRoute(
                path: 'will/quit/:habitId/onboarding',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['habitId']!;
                  return _page(state, QuitOnboardingFlowPage(habitId: id));
                },
              ),
              GoRoute(
                path: 'will/quit/:habitId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['habitId']!;
                  final tab = state.uri.queryParameters['tab'];
                  return _page(
                    state,
                    QuitProgramHomePage(habitId: id, initialTab: tab),
                  );
                },
              ),
              GoRoute(
                path: 'will/breathing',
                pageBuilder: (context, state) {
                  final q = state.uri.queryParameters['programId'];
                  return _page(state, BreathingExercisePage(programId: q));
                },
              ),
              GoRoute(
                path: 'will/namaz/:habitId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['habitId']!;
                  final fromGelisimSetup =
                      state.uri.queryParameters['from'] == 'gelisim_setup';
                  final returnOrigin =
                      state.uri.queryParameters['origin'] ?? 'habits';
                  return _page(
                    state,
                    NamazProgramPage(
                      habitId: id,
                      showHomeVisibilityHint: fromGelisimSetup,
                      returnOrigin: returnOrigin,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.inspire,
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              opaque: false,
              barrierColor: Colors.transparent,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) => child,
              child: const InspireExplorePage(),
            ),
            routes: [
              GoRoute(
                path: 'view/:index',
                pageBuilder: (context, state) {
                  final raw = state.pathParameters['index'] ?? '0';
                  final pathIdx = int.tryParse(raw) ?? 0;
                  final extra = state.extra;
                  final fromExtra =
                      extra is InspireViewerDeckExtra && extra.cards.isNotEmpty
                      ? extra
                      : null;
                  final fromSession = ref.read(
                    inspireViewerDeckSessionProvider,
                  );
                  final sessionOk =
                      fromSession != null && fromSession.cards.isNotEmpty;
                  final deck = fromExtra ?? (sessionOk ? fromSession : null);
                  if (deck != null) {
                    final safe = deck.initialIndex.clamp(
                      0,
                      deck.cards.length - 1,
                    );
                    return _inspireViewerPage(
                      state,
                      InspireViewerPage(
                        key: ValueKey<String>('inspire_deck_${state.uri}'),
                        initialIndex: safe,
                        deckOverride: deck.cards,
                        originRect: deck.originRect,
                      ),
                      expandFromOrigin: deck.originRect != null,
                    );
                  }
                  return _inspireViewerPage(
                    state,
                    InspireViewerPage(
                      key: ValueKey<String>('inspire_cat_${state.uri}'),
                      initialIndex: pathIdx < 0 ? 0 : pathIdx,
                      originRect: fromSession?.originRect,
                    ),
                    expandFromOrigin: fromSession?.originRect != null,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => _page(state, const SettingsPage()),
            routes: [
              GoRoute(
                path: 'admin',
                pageBuilder: (context, state) =>
                    _page(state, const AdminContentPage()),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: (context, state) =>
                        _page(state, const AdminNotificationsPage()),
                  ),
                  GoRoute(
                    path: 'performance',
                    pageBuilder: (context, state) =>
                        _page(state, const AdminPerformancePage()),
                  ),
                ],
              ),
              GoRoute(
                path: 'saved',
                pageBuilder: (context, state) =>
                    _page(state, const SavedInspirationPage()),
              ),
              GoRoute(
                path: 'about',
                pageBuilder: (context, state) =>
                    _page(state, const AboutArinPage()),
              ),
              GoRoute(
                path: 'widgets',
                pageBuilder: (context, state) =>
                    _page(state, const WidgetCenterPage()),
              ),
              GoRoute(
                path: 'privacy',
                pageBuilder: (context, state) =>
                    _page(state, const PrivacyPolicyPage()),
              ),
              GoRoute(
                path: 'notifications',
                pageBuilder: (context, state) =>
                    _page(state, const NotificationsSettingsPage()),
                routes: [
                  GoRoute(
                    path: 'vakit',
                    pageBuilder: (context, state) =>
                        _page(state, const PrayerNotificationsDetailPage()),
                  ),
                ],
              ),
              GoRoute(
                path: 'language',
                pageBuilder: (context, state) =>
                    _page(state, const LanguageSettingsPage()),
              ),
              GoRoute(
                path: 'contact',
                pageBuilder: (context, state) =>
                    _page(state, const ContactSupportPage()),
              ),
              GoRoute(
                path: 'support',
                pageBuilder: (context, state) =>
                    _page(state, const SupportArinPage()),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const _ErrorRedirectHome(),
  );
});

Page<void> _page(GoRouterState state, Widget child) => CupertinoPage<void>(
  key: state.pageKey,
  child: AssistantReturnPopGuard(child: child),
);

CustomTransitionPage<void> _inspireViewerPage(
  GoRouterState state,
  Widget child, {
  bool expandFromOrigin = false,
}) => CustomTransitionPage<void>(
  key: state.pageKey,
  opaque: false,
  barrierColor: Colors.transparent,
  transitionDuration: expandFromOrigin
      ? Duration.zero
      : const Duration(milliseconds: 220),
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    if (expandFromOrigin) return child;
    final eased = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(opacity: eased, child: child);
  },
  child: child,
);

/// Bilinmeyen bir rota ile karşılaşıldığında (genellikle widget tıklaması
/// nedeniyle home_widget URI'si GoRouter'a ulaştığında) kullanıcıyı sessizce
/// ana sayfaya yönlendirir. WidgetLaunchGateListener kilidi tespit eder.
class _ErrorRedirectHome extends StatefulWidget {
  const _ErrorRedirectHome();

  @override
  State<_ErrorRedirectHome> createState() => _ErrorRedirectHomeState();
}

class _ErrorRedirectHomeState extends State<_ErrorRedirectHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: Color(0xFF071815));
}
