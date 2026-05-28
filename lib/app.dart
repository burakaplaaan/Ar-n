// lib/app.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/analytics/arin_analytics.dart';
import 'core/debug/arin_error_reporting.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/providers/app_locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/router/app_router_refresh.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/quote_pool_ids.dart';
import 'data/models/prayer_times_model.dart';
import 'data/services/audio_session_coordinator.dart';
import 'data/services/app_local_notification_scheduler.dart';
import 'data/services/prayer_service_resolver.dart';
import 'data/services/fcm_token_service.dart';
import 'data/services/location_service.dart';
import 'data/services/prayer_notification_scheduler.dart';
import 'data/services/prayer_reminder_prefs.dart';
import 'data/services/purchase_service.dart';
import 'data/services/global_widget_lock_service.dart';
import 'data/services/widget_quote_override_service.dart';
import 'l10n/app_localizations.dart';
import 'data/services/habit_cloud_sync_service.dart';
import 'data/services/inspiration_engagement_sync_service.dart';
import 'data/services/tracking_widget_service.dart';
import 'data/services/user_cloud_backup_service.dart';
import 'data/services/widget_access_service.dart';
import 'data/repositories/salat_log_repository.dart';
import 'presentation/inspire/explore_bgm_controller.dart';
import 'presentation/inspire/inspiration_engagement_provider.dart';
import 'presentation/shared/providers/auth_providers.dart';
import 'presentation/shared/providers/habit_providers.dart';
import 'presentation/shared/providers/quotes_providers.dart';
import 'presentation/shared/providers/prayer_time_providers.dart';
import 'presentation/shared/providers/premium_providers.dart';
import 'presentation/shared/providers/user_profile_providers.dart';
import 'presentation/shared/widgets/global_edge_swipe_back.dart';
import 'presentation/shared/widgets/location_change_listener.dart';
import 'presentation/shared/widgets/widget_launch_gate_listener.dart';
import 'presentation/qibla/qibla_hub_navigator_key.dart';
import 'main.dart' show runDeferredStartupIfNeeded;

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
  DateTime? _lastForegroundMaintenance;
  bool _postOnboardingStartupScheduled = false;
  bool _foregroundMaintenanceInFlight = false;
  bool _foregroundMaintenanceQueued = false;

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
    var skipWidgetQuoteSync = false;
    try {
      final override = await WidgetQuoteOverrideService.applyIfDue(prefs);
      skipWidgetQuoteSync = override.activeApplied;
      if (override.shouldResumeNormal) {
        await pools.clearCacheForPool(QuotePoolIds.widgetQuote);
      }
    } catch (e) {
      debugPrint('Widget override sync failed: $e');
    }
    try {
      if (!skipWidgetQuoteSync) {
        await pools.ensureSyncedToday(QuotePoolIds.widgetQuote);
      }
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
    final prayerTimes = ref.read(prayerTimesProvider).valueOrNull;
    List<PrayerTimesModel>? upcomingDays;
    try {
      final resolver = ref.read(prayerServiceResolverProvider);
      final list = await resolver.fetchUpcomingDays(days: 7);
      if (list.isNotEmpty) upcomingDays = list;
    } catch (e) {
      debugPrint('rescheduleAll upcoming fetch failed: $e');
    }
    await AppLocalNotificationScheduler.rescheduleAll(
      prefs,
      pools: pools,
      prayerTimes: (upcomingDays != null && upcomingDays.isNotEmpty) ? upcomingDays.first : prayerTimes,
      upcomingDays: upcomingDays,
    );
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
    if (isFirebaseReady) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserCloudBackupService.pushFromLocal(
          uid: user.uid,
          prefs: ref.read(sharedPreferencesProvider),
          force: true,
        );
      }
    }
    await InspirationEngagementSyncService.flushPendingPush();
    await ref
        .read(exploreBgmNotifierProvider.notifier)
        .pauseForVisibilityLoss();
    await AudioSessionCoordinator.pauseActive();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // FCM bildirim tıklaması yönlendirmesi: router hazır olduktan hemen
      // sonra callback enjekte edilir; initIfNeeded henüz çağrılmamışsa
      // _pendingNavigationRoute mekanizması yarış durumunu yakalar.
      FcmTokenService.setNavigationCallback((route) {
        final liveRouter = ref.read(appRouterProvider);
        liveRouter.go(route);
      });

      unawaited(_runForegroundMaintenance(initial: true));
    });
  }

  Future<void> _runForegroundMaintenance({required bool initial}) async {
    if (_foregroundMaintenanceInFlight) {
      _foregroundMaintenanceQueued = true;
      return;
    }
    _foregroundMaintenanceInFlight = true;
    try {
      if (!_isOnboardingCompletedForMaintenance()) {
        debugPrint(
          '══ ARIN ══ foreground maintenance: onboarding bitmemiş, atlandı',
        );
        return;
      }

      final now = DateTime.now();
      final last = _lastForegroundMaintenance;
      if (!initial &&
          last != null &&
          now.difference(last) < const Duration(minutes: 2)) {
        return;
      }
      _lastForegroundMaintenance = now;

      final prefs = ref.read(sharedPreferencesProvider);
      if (initial) {
        await Future<void>.delayed(const Duration(seconds: 2));
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
      if (!mounted) return;

      if (PrayerReminderPrefs.isEnabled(prefs)) {
        await PrayerNotificationScheduler.promptLocalNotificationPermissions();
      }
      await _maybeOneTimeWidgetQuoteRefreshAfterAdminEdit();
      try {
        await GlobalWidgetLockService.applyIfDue(prefs);
      } catch (e) {
        debugPrint('Global widget lock sync failed: $e');
      }
      try {
        final premium = await ref.read(premiumEntitlementProvider.future);
        await WidgetAccessService(prefs).syncAll(isPremium: premium.isActive);
      } catch (e) {
        debugPrint('Widget access sync failed: $e');
        await WidgetAccessService(prefs).syncAll(isPremium: false);
      }
      unawaited(
        TrackingWidgetService.refreshSelected(
          prefs: prefs,
          habitRepo: ref.read(habitRepositoryProvider),
          salatRepo: SalatLogRepository(),
        ),
      );

      unawaited(_flushHabitDeleteQueueIfSignedIn());
      if (isFirebaseReady) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          unawaited(
            UserCloudBackupService.pushFromLocal(uid: user.uid, prefs: prefs),
          );
        }
      }

      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      unawaited(_warmupPoolsAndReschedule());

      if (PrayerReminderPrefs.isEnabled(prefs)) {
        await Future<void>.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        unawaited(_bootstrapPrayerNotifications());
      }
    } finally {
      _foregroundMaintenanceInFlight = false;
      if (_foregroundMaintenanceQueued && mounted) {
        _foregroundMaintenanceQueued = false;
        unawaited(_runForegroundMaintenance(initial: false));
      }
    }
  }

  Future<void> _runPostOnboardingStartup() async {
    if (_postOnboardingStartupScheduled) return;
    _postOnboardingStartupScheduled = true;

    if (!isFirebaseReady) {
      await bootstrapFirebase();
    }
    if (!mounted) return;

    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      enableCrashlyticsIntegration();
    } catch (e) {
      debugPrint('══ ARIN ══ post-onboarding Crashlytics init failed: $e');
    }

    // Firebase hazırlandıktan sonra auth/admin/router provider'ları yeniden
    // değerlensin. İlk kurulum sırasında Firebase'i bilinçli ertelediğimiz
    // için bu hook aynı app process içinde home'a geçerken gerekli.
    ref.invalidate(authUserProvider);
    ref.invalidate(currentAdminRoleProvider);
    ref.invalidate(isCurrentUserAdminProvider);
    ref.invalidate(appRouterProvider);
    ref.read(appRouterRefreshProvider).notifyAuthOrOnboarding();
    unawaited(ArinAnalytics.enable());
    final uid = isFirebaseReady ? FirebaseAuth.instance.currentUser?.uid : null;
    unawaited(PurchaseService.initialize(firebaseUid: uid));
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(runDeferredStartupIfNeeded(prefs));

    unawaited(_runForegroundMaintenance(initial: false));
  }

  bool _isOnboardingCompletedForMaintenance() {
    final prefs = ref.read(sharedPreferencesProvider);
    final flag = prefs.getBool('onboarding_completed');
    if (flag == false) return false;
    if (flag == true) return true;
    try {
      return ref.read(userProfileRepositoryProvider).isOnboardingCompleted;
    } catch (_) {
      return false;
    }
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
      unawaited(_runForegroundMaintenance(initial: false));
      ref.invalidate(prayerTimesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(appLocaleProvider);

    ref.listen(userProfileProvider, (previous, next) {
      final wasDone = previous?.onboardingCompleted == true;
      if (!wasDone && next.onboardingCompleted) {
        unawaited(_runPostOnboardingStartup());
      }
    });

    ref.listen(appRouterProvider, (_, __) {
      FcmTokenService.setNavigationCallback((route) {
        final liveRouter = ref.read(appRouterProvider);
        liveRouter.go(route);
      });
    });

    ref.listen<AsyncValue<User?>>(authUserProvider, (previous, next) {
      next.whenData((user) {
        final prev = previous?.asData?.value;
        final signedOut = user == null;
        if (signedOut) {
          _foregroundMaintenanceQueued = false;
          return;
        }
        if (prev != null && prev.uid == user.uid) return;
        // RC kimliğini Firebase UID ile eşleştir ki webhook/restore akışı
        // anonim kullanıcıya düşmesin.
        unawaited(
          PurchaseService.loginUser(user.uid).catchError(
            (e) => debugPrint('PurchaseService.loginUser failed: $e'),
          ),
        );
        if (!isFirebaseReady) return;
        final prefs = ref.read(sharedPreferencesProvider);
        unawaited(
          HabitCloudSyncService.flushPendingDeletes(
            uid: user.uid,
            prefs: prefs,
          ),
        );

        final uid = user.uid;
        bool isStillSignedInAsCurrentUser() =>
            FirebaseAuth.instance.currentUser?.uid == uid;

        Future<void> run() async {
          if (!isStillSignedInAsCurrentUser()) return;
          final repo = ref.read(habitRepositoryProvider);
          final habitPullOk = await HabitCloudSyncService.pullToLocal(
            uid: uid,
            repo: repo,
            prefs: prefs,
          );
          if (!isStillSignedInAsCurrentUser()) return;
          if (!habitPullOk) return;
          await HabitCloudSyncService.pushFromLocal(
            uid: uid,
            repo: repo,
            prefs: prefs,
          );
          if (!isStillSignedInAsCurrentUser()) return;
          await UserCloudBackupService.syncAfterSignIn(uid: uid, prefs: prefs);
          if (!isStillSignedInAsCurrentUser()) return;
          await InspirationEngagementSyncService.pullMergeLocal(
            uid: uid,
            prefs: prefs,
          );
          if (!isStillSignedInAsCurrentUser()) return;
          await InspirationEngagementSyncService.pushFromPrefs(prefs);
          if (!isStillSignedInAsCurrentUser()) return;
          await InspirationEngagementSyncService.flushPendingPush();
          if (!isStillSignedInAsCurrentUser()) return;
          ref.invalidate(inspirationSavedIdsProvider);
          ref.invalidate(inspirationLikedIdsProvider);
          ref.read(habitSummaryProvider.notifier).refresh();
          unawaited(_warmupPoolsAndReschedule());
          if (PrayerReminderPrefs.isEnabled(prefs)) {
            unawaited(_bootstrapPrayerNotifications());
          }
        }

        unawaited(run());
      });
    });

    ref.listen(premiumEntitlementProvider, (previous, next) {
      next.whenData((entitlement) {
        unawaited(
          WidgetAccessService(
            ref.read(sharedPreferencesProvider),
          ).syncAll(isPremium: entitlement.isActive),
        );
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
                final currentPath = router.routeInformationProvider.value.uri.path;
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
              child: WidgetLaunchGateListener(
                child: LocationChangeListener(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
