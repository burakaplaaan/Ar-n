// lib/app.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/analytics/arin_analytics.dart';
import 'core/analytics/meta_app_events.dart';
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
import 'data/services/startup_permission_policy.dart';
import 'data/services/prayer_notification_scheduler.dart';
import 'data/services/prayer_reminder_prefs.dart';
import 'data/services/purchase_service.dart';
import 'data/services/admob_service.dart';
import 'data/services/global_widget_lock_service.dart';
import 'data/services/widget_global_lock_push_service.dart';
import 'data/services/widget_quote_override_service.dart';
import 'l10n/app_localizations.dart';
import 'data/services/habit_cloud_sync_service.dart';
import 'data/services/inspiration_engagement_sync_service.dart';
import 'data/services/tracking_widget_service.dart';
import 'data/services/user_cloud_backup_service.dart';
import 'data/services/widget_access_service.dart';
import 'data/services/widget_metrics_service.dart';
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
import 'presentation/qibla/qibla_hub_back_dispatcher.dart';
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
  static const _systemBackChannel = MethodChannel('com.arin.arin/system_back');

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
      prayerTimes: (upcomingDays != null && upcomingDays.isNotEmpty)
          ? upcomingDays.first
          : prayerTimes,
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
    _systemBackChannel.setMethodCallHandler(_handleNativeSystemBack);
    AdMobService.setRewardedPreloadForeground(true);
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

  Future<bool> _handleNativeSystemBack(MethodCall call) async {
    if (call.method != 'handleBack' || !mounted) return false;

    final router = ref.read(appRouterProvider);
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path == AppRoutes.prayerCircle) {
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(AppRoutes.qibla);
      }
      return true;
    }
    if (dispatchQiblaHubBack(currentPath: path)) return true;
    return false;
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

      // Her resume'da premium state'in eskimesini engellemek için provider'ı invalidate edip
      // widget gate'leri (2 dakikalık throttle'a takılmadan) anlık tazeliyoruz.
      if (initial) {
        ref.invalidate(premiumEntitlementProvider);
      }

      await _maybeOneTimeWidgetQuoteRefreshAfterAdminEdit();
      try {
        // Uzun yaşayan preference cache'ini yenile; ardından background FCM
        // isolate'ının App Group/HomeWidget'a yazdığı revision'ı foreground
        // kuyruğuna al.
        await prefs.reload();
        await WidgetGlobalLockPushService.reconcileFromWidgetCache(prefs);
        await GlobalWidgetLockService.applyIfDue(prefs);
      } catch (e) {
        debugPrint('Global widget lock sync failed: $e');
      }
      try {
        final premium = await ref.read(premiumEntitlementProvider.future);
        final widgetAccess = WidgetAccessService(prefs);
        final widgetStates = await widgetAccess.syncAll(
          isPremium: premium.isActive,
        );
        unawaited(
          WidgetMetricsService.reconcile(
            prefs: prefs,
            accessService: widgetAccess,
            states: widgetStates,
            isPremium: premium.isActive,
          ),
        );
      } catch (e) {
        debugPrint('Widget access sync failed: $e');
        // Hata durumunda (internet yok, vb) isPremium: false diyerek kilitleri devreye
        // sokma; mevcut durumu bozmadan atla.
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

    // Kullanıcının onboarding'i bitiren "Başla" aksiyonu ATT için anlamlı ve
    // güvenli bağlamdır. Native Meta SDK install/launch eventini daha önce
    // otomatik yollar; burada izin durumu ve tek seferlik registration
    // dönüşümü tamamlanır.
    unawaited(MetaAppEvents.completeOnboardingAttribution());

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
    PurchaseService.onCustomerInfoUpdated = () {
      ref.invalidate(premiumEntitlementProvider);
    };
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
    _systemBackChannel.setMethodCallHandler(null);
    AdMobService.setRewardedPreloadForeground(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      AdMobService.setRewardedPreloadForeground(false);
      unawaited(_pauseLongAudioForBackground());
      return;
    }
    if (state == AppLifecycleState.resumed) {
      // Kullanıcı iOS Ayarlar'dan ATT tercihini değiştirmiş olabilir.
      unawaited(MetaAppEvents.syncTrackingAuthorization());
      AdMobService.markRewardedEligibilityPending();
      ref.invalidate(premiumEntitlementProvider);
      AdMobService.setRewardedPreloadForeground(true);
      // Kullanıcı Android/iOS sistem ayarlarında bildirim iznini değiştirmiş
      // olabilir; görünür yayın topic üyeliğini izinle yeniden uzlaştır.
      unawaited(FcmTokenService.syncBroadcastSubscriptionIfAuthorized());
      // Scheduler'lar 30 sn soğutma uygular; kullanıcı dakikalar içinde
      // uygulamayı tekrar tekrar açarsa yaklaşmakta olan bir alarm iptal edilip
      // yeniden kuyruğa alınarak kaçırılmaz. Ayarlar sayfası toggle'ında
      // `force: true` kullanılır.
      unawaited(_runForegroundMaintenance(initial: false));
      final prayer = ref.read(prayerTimesProvider);
      if (shouldInvalidatePrayerTimesOnResume(
        isLoading: prayer.isLoading,
        hasError: prayer.hasError,
        hasData: prayer.hasValue,
        cachedDateIso: prayer.valueOrNull?.date,
        now: DateTime.now(),
      )) {
        ref.invalidate(prayerTimesProvider);
      }
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
          PurchaseService.loginUser(user.uid)
              .then((_) {
                // Eşleştirme tamamlandıktan sonra premium durumunu yenile ki
                // yeni açılan/önbellekte olmayan entitlement devreye girsin.
                ref.invalidate(premiumEntitlementProvider);
              })
              .catchError((e) {
                debugPrint('PurchaseService.loginUser failed: $e');
                return null;
              }),
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
          ref.read(prayerServiceResolverProvider).invalidateCache();
          ref.invalidate(prayerTimesProvider);
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
      if (next.isLoading) {
        AdMobService.markRewardedEligibilityPending();
        return;
      }
      if (next.hasError) {
        AdMobService.setRewardedPreloadEligible(false);
        return;
      }
      final entitlement = next.asData?.value;
      if (entitlement == null) return;
      AdMobService.setRewardedPreloadEligible(!entitlement.isActive);
      unawaited(
        WidgetAccessService(
          ref.read(sharedPreferencesProvider),
        ).syncAll(isPremium: entitlement.isActive),
      );
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
        final localeBasedDirection =
            Directionality.of(context) == TextDirection.rtl
            ? TextDirection.rtl
            : TextDirection.ltr;
        return Directionality(
          textDirection: localeBasedDirection,
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
                if (dispatchQiblaHubBack(currentPath: currentPath)) {
                  return true;
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
