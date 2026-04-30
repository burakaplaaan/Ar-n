// lib/app.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/providers/app_locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/quote_pool_ids.dart';
import 'data/services/audio_session_coordinator.dart';
import 'data/services/app_local_notification_scheduler.dart';
import 'data/services/location_service.dart';
import 'data/services/prayer_notification_scheduler.dart';
import 'data/services/prayer_reminder_prefs.dart';
import 'l10n/app_localizations.dart';
import 'data/services/habit_cloud_sync_service.dart';
import 'data/services/inspiration_engagement_sync_service.dart';
import 'presentation/inspire/explore_bgm_controller.dart';
import 'presentation/inspire/inspiration_engagement_provider.dart';
import 'presentation/shared/providers/auth_providers.dart';
import 'presentation/shared/providers/habit_providers.dart';
import 'presentation/shared/providers/quotes_providers.dart';
import 'presentation/shared/providers/prayer_time_providers.dart';
import 'presentation/shared/widgets/global_edge_swipe_back.dart';
import 'presentation/qibla/qibla_hub_navigator_key.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Bir kerelik widget_quote cache tazeleme anahtarı.
/// Üretimde kapalı. Admin panelinden büyük bir içerik revizyonu sonrası `true`
/// yapıp tek sürüm yayımlanır, yayından sonra tekrar `false`'a çekilir.
const bool kOneTimeWidgetQuoteRefresh = false;

class ArinApp extends ConsumerStatefulWidget {
  const ArinApp({super.key});

  @override
  ConsumerState<ArinApp> createState() => _ArinAppState();
}

class _ArinAppState extends ConsumerState<ArinApp> with WidgetsBindingObserver {
  Future<void> _flushHabitDeleteQueueIfSignedIn() async {
    if (!isFirebaseReady) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await HabitCloudSyncService.flushPendingDeletes(
      uid: user.uid,
      prefs: prefs,
    );
  }

  Future<void> _warmupPoolsAndReschedule() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final pools = ref.read(quotePoolsRepositoryProvider);
    try {
      await pools.ensureSyncedToday(QuotePoolIds.widgetQuote);
    } catch (e) {
      debugPrint('Pool sync widgetQuote failed: $e');
    }
    try {
      await pools.ensureSyncedToday(QuotePoolIds.homeNamazWisdom);
    } catch (e) {
      debugPrint('Pool sync homeNamazWisdom failed: $e');
    }
    try {
      await pools.ensureSyncedToday(QuotePoolIds.notificationArinmaBodies);
    } catch (e) {
      debugPrint('Pool sync notificationArinmaBodies failed: $e');
    }
    await AppLocalNotificationScheduler.rescheduleAll(prefs, pools: pools);
  }

  Future<void> _maybeOneTimeWidgetQuoteRefreshAfterAdminEdit() async {
    if (!kOneTimeWidgetQuoteRefresh) return;
    final prefs = ref.read(sharedPreferencesProvider);
    const flagKey = 'arin_widget_one_time_pull_after_admin_edit_v1';
    if (prefs.getBool(flagKey) == true) return;

    final pools = ref.read(quotePoolsRepositoryProvider);
    await pools.clearCacheForPool(QuotePoolIds.widgetQuote);
    await pools.ensureSyncedToday(QuotePoolIds.widgetQuote);
    await prefs.setBool(flagKey, true);
  }

  Future<void> _bootstrapPrayerNotifications() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final aladhan = ref.read(aladhanServiceProvider);
    final location = ref.read(locationServiceProvider);
    await PrayerNotificationScheduler.ensurePrayerNotificationsIfEnabled(
      prefs: prefs,
      aladhan: aladhan,
      location: location,
    );
  }

  Future<void> _pauseLongAudioForBackground() async {
    await ref
        .read(exploreBgmNotifierProvider.notifier)
        .pauseForVisibilityLoss();
    await AudioSessionCoordinator.pauseActive();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = ref.read(sharedPreferencesProvider);
      if (PrayerReminderPrefs.isEnabled(prefs)) {
        await PrayerNotificationScheduler.promptLocalNotificationPermissions();
      }
      await _maybeOneTimeWidgetQuoteRefreshAfterAdminEdit();
      unawaited(_flushHabitDeleteQueueIfSignedIn());
      unawaited(_warmupPoolsAndReschedule());
      unawaited(_bootstrapPrayerNotifications());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_pauseLongAudioForBackground());
      return;
    }
    if (state == AppLifecycleState.resumed) {
      // Scheduler'lar 30 sn soğutma uygular; kullanıcı dakikalar içinde
      // uygulamayı tekrar tekrar açarsa yaklaşmakta olan bir alarm iptal edilip
      // yeniden kuyruğa alınarak kaçırılmaz. Ayarlar sayfası toggle'ında
      // `force: true` kullanılır.
      unawaited(_flushHabitDeleteQueueIfSignedIn());
      unawaited(_warmupPoolsAndReschedule());
      unawaited(_bootstrapPrayerNotifications());
      ref.invalidate(prayerTimesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(appLocaleProvider);
    ref.watch(exploreBgmNotifierProvider);

    ref.listen<AsyncValue<User?>>(authUserProvider, (previous, next) {
      next.whenData((user) {
        if (user == null || !isFirebaseReady) return;
        final prefs = ref.read(sharedPreferencesProvider);
        unawaited(
          HabitCloudSyncService.flushPendingDeletes(uid: user.uid, prefs: prefs),
        );
        final prev = previous?.asData?.value;
        if (prev != null && prev.uid == user.uid) return;

        final uid = user.uid;
        Future<void> run() async {
          final repo = ref.read(habitRepositoryProvider);
          await HabitCloudSyncService.pullToLocal(
            uid: uid,
            repo: repo,
            prefs: prefs,
          );
          await HabitCloudSyncService.pushFromLocal(
            uid: uid,
            repo: repo,
            prefs: prefs,
          );
          await InspirationEngagementSyncService.pullMergeLocal(
            uid: uid,
            prefs: prefs,
          );
          await InspirationEngagementSyncService.pushFromPrefs(prefs);
          ref.invalidate(inspirationSavedIdsProvider);
          ref.invalidate(inspirationLikedIdsProvider);
          ref.read(habitSummaryProvider.notifier).refresh();
        }

        Future.microtask(run);
      });
    });

    return MaterialApp.router(
      title: 'Arın',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: appLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Kullanıcı OS'ta "Büyük yazı tipi" açtığında reels Arapça dizilimi,
      // zikirmatik LCD'si, hub kartları taşabiliyordu (test: iOS Ayarlar →
      // Erişilebilirlik → Ekran → Daha Büyük Metin %310). 1.3x tavan:
      // görme engelliler için hâlâ %30 büyütme imkânı sunarken layout
      // bozulmasının %95'ini engelliyor. Apple review ekibi large-text
      // screenshot aldığında overflow kalmıyor.
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        return Directionality(
          // Force global layout direction to LTR so Arabic locale does not
          // mirror full-screen structure (bars, rows, navigation flow).
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 1.0,
                maxScaleFactor: 1.3,
              ),
            ),
            child: GlobalEdgeSwipeBack(
              onBackRequested: () async {
                final currentPath =
                    router.routeInformationProvider.value.uri.path;
                final onQiblaStack =
                    currentPath == AppRoutes.qibla ||
                    currentPath.startsWith('${AppRoutes.qibla}/');
                if (onQiblaStack) {
                  final qiblaNav = qiblaHubNavigatorKey.currentState;
                  if (qiblaNav != null && qiblaNav.canPop()) {
                    qiblaNav.pop();
                    return true;
                  }
                }
                final rootNav = router.routerDelegate.navigatorKey.currentState;
                if (rootNav != null && rootNav.canPop()) {
                  return rootNav.maybePop();
                }
                return false;
              },
              child: child,
            ),
          ),
        );
      },
    );
  }
}
