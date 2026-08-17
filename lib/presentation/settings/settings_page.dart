// lib/presentation/settings/settings_page.dart
// Ayarlar: panel arka planı, hesap (Apple/Google), krem tema, menü, Firebase çıkış/sil.

import 'dart:async';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../app.dart';
import '../../core/analytics/arin_analytics.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/profile_prefs_keys.dart';
import '../../core/constants/turkey_provinces.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/providers/app_locale_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/app_router_refresh.dart';
import '../../core/theme/arin_backdrop_blur.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../data/services/habit_cloud_sync_service.dart';
import '../../data/services/inspiration_engagement_sync_service.dart';
import '../../data/services/local_data_wipe_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/user_cloud_backup_service.dart';
import '../onboarding/app_tour/app_tour_anchor.dart';
import '../onboarding/app_tour/app_tour_controller.dart';
import '../onboarding/app_tour/app_tour_keys.dart';
import '../settings/widgets/district_picker_sheet.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/providers/habit_providers.dart';
import '../inspire/inspiration_engagement_provider.dart';
import '../inspire/inspiration_like_totals_provider.dart';
import '../kaza/kaza_tracking_provider.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/premium_providers.dart';
import '../shared/providers/user_profile_providers.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';
import '../shared/widgets/arin_pressable.dart';
import '../shared/widgets/arin_premium_mark.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _cityController;
  bool _locationLoading = false;
  bool _oauthBusy = false;
  bool _accountDeleteBusy = false;

  @override
  void initState() {
    super.initState();
    final loc = ref.read(locationServiceProvider);
    final raw = loc.savedCity;
    final display = matchTurkeyProvinceExact(raw) ?? raw;
    _cityController = TextEditingController(text: display);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _locationLoading = true);
    try {
      final loc = ref.read(locationServiceProvider);
      await loc.syncPrayerLocation(
        forceRefresh: true,
        overwriteManual: true,
      );
      ref.invalidate(prayerTimesProvider);
      if (!mounted) return;
      final resolved = matchTurkeyProvinceExact(loc.savedCity) ?? loc.savedCity;
      _cityController.text = resolved;
      if (resolved != loc.savedCity && loc.savedLat != null) {
        await loc.saveCity(resolved, loc.savedCountry);
        // saveCity awaited — BuildContext'i yeniden kullanmadan önce tekrar
        // mounted kontrolü zorunlu.
        if (!mounted) return;
      }
      final ok = loc.savedLat != null;
      final l10n = AppLocalizations.of(context)!;
      showArinTopToast(context, ok
                ? l10n.settingsLocationUpdatedMessage(resolved)
                : l10n.settingsLocationFailedMessage);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showArinTopToast(context, l10n.settingsLocationFailedMessage);
    } finally {
      if (mounted) {
        setState(() => _locationLoading = false);
      }
    }
  }

  Future<void> _onProvinceSelected(String province) async {
    final loc = ref.read(locationServiceProvider);
    await loc.saveManualCity(province, 'Turkey');
    ref.invalidate(prayerTimesProvider);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      showArinTopToast(context, l10n.settingsProvinceUpdatedMessage(province));
    }
  }

  Future<void> _onDistrictSelected() async {
    final picked = await showDistrictPickerSheet(context);
    if (picked == null || !mounted) return;
    await ref.read(locationServiceProvider).saveManualDistrict(picked);
    ref.invalidate(prayerTimesProvider);
    if (!mounted) return;
    _cityController.text = picked.displayLabel;
    final l10n = AppLocalizations.of(context)!;
    showArinTopToast(context, l10n.settingsProvinceUpdatedMessage(picked.il));
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsSignOutDialogTitle),
        content: Text(l10n.settingsSignOutDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.settingsDialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsSignOutAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final prefs = ref.read(sharedPreferencesProvider);
    if (isFirebaseReady) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await HabitCloudSyncService.pushFromLocal(
            uid: user.uid,
            repo: ref.read(habitRepositoryProvider),
            prefs: prefs,
            force: true,
            bypassForceCooldown: true,
          );
          await UserCloudBackupService.pushFromLocal(
            uid: user.uid,
            prefs: prefs,
            force: true,
          );
        } catch (e) {
          debugPrint('signOut pre-push failed: $e');
        }
      }
      try {
        await ref.read(authServiceProvider).signOut();
      } catch (e) {
        // signOut (RC logout / Firebase signOut / Google signOut) hata atsa
        // bile yerel veri silme her durumda çalışmalı — aksi halde bir sonraki
        // kullanıcı önceki kullanıcının habit/zikir/ayar verilerini görür.
        debugPrint('signOut failed (continuing with local wipe): $e');
        if (mounted) {
          showArinTopToast(context, l10n.settingsAuthServiceUnavailable);
        }
      }
    }

    try {
      await LocalDataWipeService.wipeAll(prefs);
    } catch (e) {
      debugPrint('LocalDataWipeService.wipeAll failed: $e');
      if (!mounted) return;
      showArinTopToast(context, l10n.settingsAccountDeleteRetryMessage);
      return;
    }
    _invalidateAfterWipe();
    ref.read(appRouterRefreshProvider).notifyAuthOrOnboarding();
    if (mounted) context.go(AppRoutes.onboarding);
  }

  void _invalidateAfterWipe() {
    ref.invalidate(authUserProvider);
    ref.invalidate(premiumEntitlementProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(habitSummaryProvider);
    ref.invalidate(dailyContentProvider);
    ref.invalidate(prayerTimesProvider);
    ref.invalidate(inspirationSavedIdsProvider);
    ref.invalidate(inspirationLikedIdsProvider);
    ref.invalidate(inspirationLikeTotalsProvider);
    ref.invalidate(kazaTrackingProvider);
    ref.invalidate(appTourControllerProvider);
  }

  Future<void> _deleteAccount() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    if (firebaseUser == null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.settingsDeleteAllDataDialogTitle),
          content: Text(l10n.settingsDeleteAllDataDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.settingsDialogCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.settingsDeleteAction),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final prefs = ref.read(sharedPreferencesProvider);
      await LocalDataWipeService.wipeAll(prefs);
      _invalidateAfterWipe();
      ref.read(appRouterRefreshProvider).notifyAuthOrOnboarding();
      if (mounted) context.go(AppRoutes.onboarding);
      return;
    }

    if (!isFirebaseReady) {
      _snackFirebase();
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountDialogTitle),
        content: Text(l10n.settingsDeleteAccountDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.settingsDialogCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsDeleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final uid = firebaseUser.uid;
    final email =
        firebaseUser.email?.trim().toLowerCase() ??
        firebaseUser.providerData
            .map((p) => p.email?.trim().toLowerCase())
            .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);
    setState(() => _accountDeleteBusy = true);
    final rootNav = Navigator.of(context, rootNavigator: true);
    var loaderPushed = false;
    if (mounted) {
      loaderPushed = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Theme.of(ctx).colorScheme.surface,
            content: Row(
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: ArinLoader(strokeWidth: 2.4),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    l10n.settingsDeleteProgressMessage,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      await ref.read(authServiceProvider).reauthenticateCurrentUser();
    } on FirebaseAuthException catch (e) {
      if (loaderPushed && mounted) {
        rootNav.pop();
      }
      if (mounted) {
        setState(() => _accountDeleteBusy = false);
        showArinTopToast(context, e.message ?? l10n.settingsAccountDeleteFailedMessage);
      }
      return;
    } on StateError catch (e) {
      // Kullanıcının reauth'u iptali ya da oturum bulunamaması.
      if (loaderPushed && mounted) {
        rootNav.pop();
      }
      if (mounted) {
        setState(() => _accountDeleteBusy = false);
        showArinTopToast(context, e.message);
      }
      return;
    } catch (e) {
      debugPrint('Account reauth failed: $e');
      if (loaderPushed && mounted) {
        rootNav.pop();
      }
      if (mounted) {
        setState(() => _accountDeleteBusy = false);
        showArinTopToast(context, l10n.settingsAccountDeleteRetryMessage);
      }
      return;
    }

    try {
      await HabitCloudSyncService.flushPendingDeletes(
        uid: uid,
        prefs: ref.read(sharedPreferencesProvider),
      );
      await InspirationEngagementSyncService.flushPendingPush();
    } catch (_) {}

    // Oturum hâlâ açıkken cloud verisini doğrudan sil — Firestore kuralları
    // `request.auth.uid == uid` istiyor; Auth silindikten sonra istemci taraflı
    // silme imkânsız olur. Apple 5.1.1(v) / Play Data Safety: kullanıcı "Sil"
    // dediği an verisi gitmeli, 24 saatlik backend scheduler beklenmemeli.
    var cloudDeletedDirectly = false;
    try {
      await HabitCloudSyncService.deleteAllUserCloudData(uid, email: email);
      cloudDeletedDirectly = true;
    } catch (e) {
      debugPrint('Direct cloud delete failed, will rely on queue: $e');
    }

    // Doğrudan silme başarısız ya da kısmen tamamlanmış olabilir; backend
    // queue scheduled cleanup'ı yine de tetiklensin (idempotent).
    try {
      await HabitCloudSyncService.queueUserCloudDataDeletion(
        uid: uid,
        email: email,
      );
    } catch (e) {
      // Doğrudan silme başardıysa queue başarısızlığı engelleyici değil.
      if (!cloudDeletedDirectly) {
        if (loaderPushed && mounted) {
          rootNav.pop();
        }
        if (mounted) {
          setState(() => _accountDeleteBusy = false);
          showArinTopToast(context, l10n.settingsCloudDeleteFailedMessage);
        }
        return;
      }
      debugPrint('Queue write failed (cloud already purged): $e');
    }

    try {
      await ref.read(authServiceProvider).deleteAccount();
      // Silme başarılı → analytics user ID'sini de temizle ve olayı yolla.
      unawaited(ArinAnalytics.accountDelete());
      unawaited(ArinAnalytics.resetUser());
    } on FirebaseAuthException catch (e) {
      if (loaderPushed && mounted) {
        rootNav.pop();
      }
      if (mounted) {
        setState(() => _accountDeleteBusy = false);
        showArinTopToast(context, e.message ?? l10n.settingsAccountDeleteFailedMessage);
      }
      return;
    } catch (e) {
      debugPrint('Account delete failed: $e');
      if (loaderPushed && mounted) {
        rootNav.pop();
      }
      if (mounted) {
        setState(() => _accountDeleteBusy = false);
        showArinTopToast(context, l10n.settingsAccountDeleteRetryMessage);
      }
      return;
    }

    if (loaderPushed && mounted) {
      rootNav.pop();
    }
    if (mounted) {
      setState(() => _accountDeleteBusy = false);
    }

    final prefs = ref.read(sharedPreferencesProvider);
    try {
      await LocalDataWipeService.wipeAll(prefs);
    } catch (e) {
      debugPrint('LocalDataWipeService.wipeAll (delete account) failed: $e');
      if (mounted) {
        showArinTopToast(context, l10n.settingsAccountDeleteRetryMessage);
      }
      return;
    }
    _invalidateAfterWipe();
    ref.read(appRouterRefreshProvider).notifyAuthOrOnboarding();
    if (mounted) context.go(AppRoutes.onboarding);
  }

  Future<void> _signInGoogle() async {
    if (!isFirebaseReady) {
      _snackFirebase();
      return;
    }
    final localName = _currentLocalProfileName();
    setState(() => _oauthBusy = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      unawaited(ArinAnalytics.loginSuccess('google'));
      await _restoreLocalProfileName(localName);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showArinTopToast(context, l10n.settingsGoogleSignInSuccess);
      }
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final raw = e.toString();
        final looksLikeCancel =
            raw.contains('canceled') || raw.contains('cancelled');
        final msg = looksLikeCancel
            ? l10n.settingsGoogleSignInCancelled
            : l10n.settingsGoogleSignInFailed;
        showArinTopToast(context, msg);
      }
    } finally {
      if (mounted) setState(() => _oauthBusy = false);
    }
  }

  Future<void> _signInApple() async {
    if (!isFirebaseReady) {
      _snackFirebase();
      return;
    }
    final svc = ref.read(authServiceProvider);
    if (!svc.appleSignInAvailable) return;
    final localName = _currentLocalProfileName();
    setState(() => _oauthBusy = true);
    try {
      await svc.signInWithApple();
      unawaited(ArinAnalytics.loginSuccess('apple'));
      await _restoreLocalProfileName(localName);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showArinTopToast(context, l10n.settingsAppleSignInSuccess);
      }
    } catch (e, st) {
      debugPrint('Apple sign-in failed: $e\n$st');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showArinTopToast(context, _appleSignInFailureMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _oauthBusy = false);
    }
  }

  String? _currentLocalProfileName() {
    final prefs = ref.read(sharedPreferencesProvider);
    final hasNameLockPreference = prefs.containsKey(profileNameLockedByUserKey);
    final localName = ref.read(userProfileProvider).name?.trim();
    final isLocked = hasNameLockPreference
        ? (prefs.getBool(profileNameLockedByUserKey) ?? false)
        : (localName != null && localName.isNotEmpty);
    if (!isLocked) return null;
    if (localName == null || localName.isEmpty) return null;
    return localName;
  }

  Future<void> _restoreLocalProfileName(String? name) async {
    if (name == null || name.isEmpty) return;
    final current = ref.read(userProfileProvider).name?.trim();
    if (current == name) return;
    await ref.read(userProfileProvider.notifier).updateName(name);
  }

  String _appleSignInFailureMessage(Object error, AppLocalizations l10n) {
    if (error is SignInWithAppleAuthorizationException) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return _trOnlyAppleMessage(l10n, l10n.appleSignInCanceled);
      }
      if (error.code == AuthorizationErrorCode.failed) {
        return _trOnlyAppleMessage(l10n, l10n.appleSignInNotAuthorized);
      }
    }
    if (error is FirebaseAuthException) {
      debugPrint(
        'Apple FirebaseAuthException code=${error.code}, message=${error.message}',
      );
      if (error.code == 'operation-not-allowed') {
        return _trOnlyAppleMessage(l10n, l10n.appleSignInProviderDisabled);
      }
      if (error.code == 'invalid-credential' ||
          error.code == 'invalid-oauth-credential') {
        return _trOnlyAppleMessage(l10n, l10n.appleSignInInvalidCredential);
      }
      if (error.code == 'network-request-failed') {
        return _trOnlyAppleMessage(l10n, l10n.appleSignInNetworkFailed);
      }
    }
    return l10n.settingsAppleSignInFailed;
  }

  String _trOnlyAppleMessage(AppLocalizations l10n, String message) {
    return l10n.localeName.startsWith('tr')
        ? message
        : l10n.settingsAppleSignInFailed;
  }

  void _snackFirebase() {
    final l10n = AppLocalizations.of(context)!;
    showArinTopToast(context, l10n.settingsAuthServiceUnavailable);
  }

  String _languageLabelForLocale(BuildContext context, Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'en':
        return l10n.languageEnglishLabel;
      case 'ar':
        return l10n.languageArabicLabel;
      default:
        return l10n.languageTurkishLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(appLocaleProvider);
    final useCream = themeMode == ThemeMode.light;
    final authAsync = ref.watch(authUserProvider);
    final signedInUser = authAsync.asData?.value;
    // Admin paneli tetikleyicisi Firestore kontrolüne dayanıyor (bkz.
    // isCurrentUserAdminProvider). İlk yüklemede false gelir, Firestore
    // yanıtı dönünce UI otomatik güncellenir — flicker minimal.
    final showAdmin =
        ref.watch(isCurrentUserAdminProvider).asData?.value ?? false;
    final onDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = onDark
        ? Colors.white.withValues(alpha: 0.96)
        : AppColors.emeraldDark;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: ArinShellBackground.decoration(context)),
          ArinShellBackground.bubbleLayer(context),
          CustomScrollView(
            // Alt sayfaya (ör. Hakkında) girip dönünce shell PageView yeniden
            // kurulduğu için sayfa state'i sıfırlanır; PageStorageKey kaydırma
            // konumunu route'un kalıcı PageStorage bucket'ında saklayıp geri yükler.
            key: const PageStorageKey<String>('settingsScroll'),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _BrandRow(titleColor: titleColor, muted: muted)
                          .animate()
                          .fadeIn(duration: 520.ms, curve: Curves.easeOutCubic)
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            duration: 560.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 8),
                      Text(
                            l10n.settingsPageHeader,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              color: titleColor,
                              height: 1.05,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 60.ms, duration: 480.ms)
                          .slideX(
                            begin: -0.02,
                            end: 0,
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 28),
                      _SectionLabel(
                        l10n.settingsSectionAccount,
                        color: muted,
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 12),
                      _AccountCard(
                            onDark: onDark,
                            authAsync: authAsync,
                            oauthBusy: _oauthBusy,
                            onGoogle: _signInGoogle,
                            onApple: _signInApple,
                          )
                          .animate()
                          .fadeIn(delay: 140.ms)
                          .scale(
                            begin: const Offset(0.97, 0.97),
                            duration: 420.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 28),
                      _SectionLabel(
                        l10n.settingsSectionAppearance,
                        color: muted,
                      ).animate().fadeIn(delay: 160.ms),
                      const SizedBox(height: 12),
                      _CreamThemeToggle(
                        value: useCream,
                        onDark: onDark,
                        onChanged: (v) {
                          ref.read(themeModeProvider.notifier).state = v
                              ? ThemeMode.light
                              : ThemeMode.dark;
                          HapticFeedback.selectionClick();
                        },
                      ).animate().fadeIn(delay: 180.ms),
                      const SizedBox(height: 28),
                      _SectionLabel(
                        l10n.settingsSectionPrayerTimes,
                        color: muted,
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 12),
                      _LocationCard(
                        onDark: onDark,
                        cityController: _cityController,
                        locationLoading: _locationLoading,
                        onProvinceSelected: _onProvinceSelected,
                        onPickDistrict: _onDistrictSelected,
                        onDetect: _detectLocation,
                      ).animate().fadeIn(delay: 220.ms),
                      const SizedBox(height: 28),
                      _SectionLabel(
                        l10n.settingsSectionApp,
                        color: muted,
                      ).animate().fadeIn(delay: 240.ms),
                      const SizedBox(height: 12),
                      AppTourAnchor(
                        id: AppTourTargetId.settingsNotifications,
                        child: _SettingsMenuTile(
                        onDark: onDark,
                        icon: Icons.notifications_none_rounded,
                        iconColor: _settingsMenuIconTint(onDark),
                        iconBgColor: _settingsMenuIconCircle(onDark),
                        title: l10n.settingsMenuNotificationsTitle,
                        subtitle: l10n.settingsMenuNotificationsSubtitle,
                        delayMs: 260,
                        onTap: () =>
                            context.push(AppRoutes.settingsNotifications),
                      ),
                      ),
                      const SizedBox(height: 10),
                      _SettingsMenuTile(
                        onDark: onDark,
                        iconWidget: const ArinPremiumMark(size: 22),
                        iconColor: AppColors.goldAccent,
                        iconBgColor: AppColors.goldAccent.withValues(
                          alpha: onDark ? 0.14 : 0.2,
                        ),
                        title: l10n.settingsMenuPremiumTitle,
                        subtitle: l10n.settingsMenuPremiumSubtitle,
                        delayMs: 270,
                        onTap: () => context.push(AppRoutes.premium),
                      ),
                      const SizedBox(height: 10),
                      _SettingsMenuTile(
                        onDark: onDark,
                        icon: Icons.auto_stories_outlined,
                        iconColor: _settingsMenuIconTint(onDark),
                        iconBgColor: _settingsMenuIconCircle(onDark),
                        title: l10n.settingsMenuAboutTitle,
                        subtitle: l10n.settingsMenuAboutSubtitle,
                        delayMs: 280,
                        onTap: () => context.push(AppRoutes.settingsAbout),
                      ),
                      const SizedBox(height: 10),
                      AppTourAnchor(
                        id: AppTourTargetId.settingsWidgets,
                        child: _SettingsMenuTile(
                        onDark: onDark,
                        icon: Icons.widgets_outlined,
                        iconColor: AppColors.accentNeonGreen,
                        iconBgColor: AppColors.accentNeonGreen.withValues(
                          alpha: onDark ? 0.12 : 0.18,
                        ),
                        title: l10n.settingsMenuWidgetsTitle,
                        subtitle: l10n.settingsMenuWidgetsSubtitle,
                        delayMs: 285,
                        onTap: () => context.push(AppRoutes.settingsWidgets),
                      ),
                      ),
                      const SizedBox(height: 10),
                      _SettingsMenuTile(
                        onDark: onDark,
                        icon: Icons.privacy_tip_outlined,
                        iconColor: _settingsMenuIconTint(onDark),
                        iconBgColor: _settingsMenuIconCircle(onDark),
                        title: l10n.settingsMenuPrivacyTitle,
                        subtitle: l10n.settingsMenuPrivacySubtitle,
                        delayMs: 290,
                        onTap: () =>
                            context.push(AppRoutes.settingsPrivacyPolicy),
                      ),
                      const SizedBox(height: 10),
                      _SettingsMenuTile(
                        onDark: onDark,
                        icon: Icons.bookmark_add_outlined,
                        iconColor: _settingsMenuIconTint(onDark),
                        iconBgColor: _settingsMenuIconCircle(onDark),
                        title: l10n.settingsMenuSavedTitle,
                        subtitle: l10n.settingsMenuSavedSubtitle,
                        delayMs: 300,
                        onTap: () => context.push(AppRoutes.settingsSaved),
                      ),
                      if (showAdmin) ...[
                        const SizedBox(height: 10),
                        _SettingsMenuTile(
                          onDark: onDark,
                          icon: Icons.admin_panel_settings_outlined,
                          iconColor: _settingsMenuIconTint(onDark),
                          iconBgColor: _settingsMenuIconCircle(onDark),
                          title: l10n.settingsMenuAdminTitle,
                          subtitle: l10n.settingsMenuAdminSubtitle,
                          delayMs: 310,
                          onTap: () => context.push(AppRoutes.settingsAdmin),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _SettingsMenuTile(
                        onDark: onDark,
                        icon: Icons.alternate_email_rounded,
                        iconColor: _settingsMenuIconTint(onDark),
                        iconBgColor: _settingsMenuIconCircle(onDark),
                        title: l10n.settingsMenuContactTitle,
                        subtitle: l10n.settingsMenuContactSubtitle,
                        delayMs: 320,
                        onTap: () => context.push(AppRoutes.settingsContact),
                      ),
                      const SizedBox(height: 10),
                      AppTourAnchor(
                        id: AppTourTargetId.settingsLanguage,
                        child: _SettingsMenuTile(
                        onDark: onDark,
                        icon: Icons.translate_rounded,
                        iconColor: _settingsMenuIconTint(onDark),
                        iconBgColor: _settingsMenuIconCircle(onDark),
                        title: l10n.languageSettingsTitle,
                        subtitle: _languageLabelForLocale(context, appLocale),
                        delayMs: 340,
                        onTap: () => context.push(AppRoutes.settingsLanguage),
                      ),
                      ),
                      const SizedBox(height: 10),
                      _SettingsMenuTile(
                        onDark: onDark,
                        icon: Icons.volunteer_activism_outlined,
                        iconColor: _settingsMenuIconTint(onDark),
                        iconBgColor: _settingsMenuIconCircle(onDark),
                        title: l10n.settingsMenuSupportTitle,
                        subtitle: l10n.settingsMenuSupportSubtitle,
                        delayMs: 360,
                        onTap: () => context.push(AppRoutes.settingsSupport),
                      ),
                      if (signedInUser != null) ...[
                        const SizedBox(height: 28),
                        _SectionLabel(
                          l10n.settingsSectionSession,
                          color: muted,
                        ).animate().fadeIn(delay: 380.ms),
                        const SizedBox(height: 12),
                        _SessionActionsPanel(
                          onDark: onDark,
                          sessionBusy: _oauthBusy || _accountDeleteBusy,
                          onSignOut: _signOut,
                          onDeleteAccount: _deleteAccount,
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                      SizedBox(
                        height: MediaQuery.paddingOf(context).bottom + 100,
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Parçalar ───────────────────────────────────────────────────────────────

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.titleColor, required this.muted});

  final Color titleColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'ARIN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.2,
            color: muted,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: color.withValues(alpha: 0.85),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.onDark,
    required this.authAsync,
    required this.oauthBusy,
    required this.onGoogle,
    required this.onApple,
  });

  final bool onDark;
  final AsyncValue<User?> authAsync;
  final bool oauthBusy;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = onDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.creamDark.withValues(alpha: 0.65);
    final fill = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.72);

    return ArinBackdropBlur(
      sigma: 14,
      borderRadius: BorderRadius.circular(22),
      child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: onDark ? 0.22 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              authAsync.when(
                data: (user) {
                  final email = user?.email;
                  final name = user?.displayName;
                  if (user == null) {
                    return Text(
                      l10n.settingsGuestHint,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.45,
                        color: onDark
                            ? AppColors.textOnDarkMuted
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? l10n.settingsAccountFallback,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: onDark ? Colors.white : AppColors.emeraldDark,
                        ),
                      ),
                      if (email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: onDark
                                ? AppColors.textOnDarkMuted
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(minHeight: 3),
                error: (_, __) => const SizedBox.shrink(),
              ),
              authAsync.maybeWhen(
                data: (user) {
                  if (user != null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _OAuthSignInTile(
                        onDark: onDark,
                        busy: oauthBusy,
                        icon: const _GoogleGMark(size: 20),
                        title: l10n.settingsSignInGoogle,
                        onTap: onGoogle,
                      ),
                      if (defaultTargetPlatform == TargetPlatform.iOS ||
                          defaultTargetPlatform == TargetPlatform.macOS) ...[
                        const SizedBox(height: 10),
                        _OAuthSignInTile(
                          onDark: onDark,
                          busy: oauthBusy,
                          icon: Icon(
                            Icons.apple_rounded,
                            size: 22,
                            color: onDark
                                ? Colors.white
                                : AppColors.emeraldDark,
                          ),
                          title: l10n.settingsSignInApple,
                          onTap: onApple,
                        ),
                      ],
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
    );
  }
}

class _OAuthSignInTile extends StatelessWidget {
  const _OAuthSignInTile({
    required this.onDark,
    required this.busy,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final bool onDark;
  final bool busy;
  final Widget icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = onDark
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.creamDark.withValues(alpha: 0.7);
    final fg = onDark ? Colors.white : AppColors.emeraldDark;

    return ArinPressable(
      enabled: !busy,
      haptic: false,
      onTap: busy
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.1),
          color: onDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.55),
        ),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
            children: [
              Opacity(opacity: busy ? 0.45 : 1, child: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: fg.withValues(alpha: busy ? 0.45 : 1),
                  ),
                ),
              ),
              if (busy)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: ArinLoader(
                    strokeWidth: 2,
                    color: fg.withValues(alpha: 0.6),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: fg.withValues(alpha: 0.35),
                ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGMark extends StatelessWidget {
  const _GoogleGMark({required this.size});

  final double size;

  // Google "G" logosunun resmi SVG'si (Google Brand Guidelines).
  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }
}

class _SessionActionsPanel extends StatelessWidget {
  const _SessionActionsPanel({
    required this.onDark,
    required this.sessionBusy,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final bool onDark;
  final bool sessionBusy;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = onDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.creamDark.withValues(alpha: 0.55);
    final fill = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.65);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsSessionHint,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.35,
              color: onDark ? AppColors.textOnDarkMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: sessionBusy ? null : onSignOut,
            icon: Icon(
              Icons.logout_rounded,
              size: 20,
              color: AppColors.accentNeonGreen.withValues(alpha: 0.95),
            ),
            label: Text(
              l10n.settingsSignOutAction,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: onDark ? Colors.white : AppColors.emeraldDark,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: onDark
                  ? Colors.white.withValues(alpha: 0.92)
                  : AppColors.emeraldDark,
              side: BorderSide(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.5),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: AppColors.accentNeonGreen.withValues(
                alpha: onDark ? 0.1 : 0.12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: sessionBusy ? null : onDeleteAccount,
            icon: Icon(
              Icons.delete_forever_rounded,
              size: 18,
              color: AppColors.error.withValues(alpha: 0.85),
            ),
            label: Text(
              l10n.settingsDeleteAccountAction,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error.withValues(alpha: 0.88),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreamThemeToggle extends StatelessWidget {
  const _CreamThemeToggle({
    required this.value,
    required this.onDark,
    required this.onChanged,
  });

  final bool value;
  final bool onDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = onDark
        ? Colors.white.withValues(alpha: 0.1)
        : AppColors.creamDark;
    final bg = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.75);

    return ArinBackdropBlur(
      sigma: 10,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: Curves.elasticOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: AppColors.emeraldDark.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emeraldFaint.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.wb_sunny_rounded,
                  color: onDark
                      ? AppColors.accentNeonGreen
                      : AppColors.emeraldDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsLightThemeTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: onDark ? Colors.white : AppColors.emeraldDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.settingsLightThemeSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: onDark
                            ? AppColors.textOnDarkMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeThumbColor: AppColors.emeraldDark,
                activeTrackColor: AppColors.emeraldFaint,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
    );
  }
}

class _LocationCard extends StatefulWidget {
  const _LocationCard({
    required this.onDark,
    required this.cityController,
    required this.locationLoading,
    required this.onProvinceSelected,
    required this.onPickDistrict,
    required this.onDetect,
  });

  final bool onDark;
  final TextEditingController cityController;
  final bool locationLoading;
  final Future<void> Function(String province) onProvinceSelected;
  final Future<void> Function() onPickDistrict;
  final Future<void> Function() onDetect;

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  final FocusNode _cityFocus = FocusNode();

  @override
  void dispose() {
    _cityFocus.dispose();
    super.dispose();
  }

  Future<void> _pickProvince(String province) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await widget.onProvinceSelected(province);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = widget.onDark;
    final border = onDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.creamDark;
    final fill = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.7);
    final fieldFill = onDark
        ? Colors.black.withValues(alpha: 0.2)
        : AppColors.creamSurface;
    final listFill = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.95)
        : Colors.white;
    final listBorder = onDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.creamDark.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RawAutocomplete<String>(
                  focusNode: _cityFocus,
                  textEditingController: widget.cityController,
                  displayStringForOption: (s) => s,
                  optionsBuilder: (TextEditingValue value) {
                    return searchTurkeyProvinces(value.text);
                  },
                  onSelected: _pickProvince,
                  optionsViewBuilder: (context, onSelected, options) {
                    final opts = options.toList();
                    if (opts.isEmpty) return const SizedBox.shrink();
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: listFill,
                        elevation: 10,
                        shadowColor: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 240),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: listBorder),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: opts.length,
                            itemBuilder: (context, index) {
                              final opt = opts[index];
                              return ArinPressable(
                                onTap: () => onSelected(opt),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    opt,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: onDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: onDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.settingsProvinceLabel,
                            hintText: l10n.settingsProvinceHint,
                            hintStyle: TextStyle(
                              color:
                                  (onDark
                                          ? AppColors.textOnDarkMuted
                                          : AppColors.textMuted)
                                      .withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                            labelStyle: TextStyle(
                              color: onDark
                                  ? AppColors.textOnDarkMuted
                                  : AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: fieldFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) {
                            final exact = matchTurkeyProvinceExact(
                              controller.text,
                            );
                            if (exact != null) {
                              controller.text = exact;
                              _pickProvince(exact);
                              return;
                            }
                            showArinTopToast(context, l10n.settingsProvinceInvalid);
                          },
                        );
                      },
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _LocateGlossButton(
                  onDark: onDark,
                  loading: widget.locationLoading,
                  onTap: widget.onPickDistrict,
                  onLongPress: widget.onDetect,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uygulama menü satırları: tek renk (tema yeşili), nötr daire.
Color _settingsMenuIconTint(bool onDark) =>
    onDark ? AppColors.accentNeonGreen : AppColors.emeraldDark;

Color _settingsMenuIconCircle(bool onDark) => onDark
    ? Colors.white.withValues(alpha: 0.08)
    : AppColors.emeraldDark.withValues(alpha: 0.12);

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({
    required this.onDark,
    this.icon,
    this.iconWidget,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.delayMs,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  final bool onDark;
  final IconData? icon;
  final Widget? iconWidget;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final int delayMs;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = onDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppColors.creamDark.withValues(alpha: 0.5);
    final enabled = onTap != null;
    final fill = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.65);

    return ArinPressable(
          enabled: enabled,
          haptic: false,
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap?.call();
                }
              : null,
          child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: fill,
                border: Border.all(color: border),
              ),
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBgColor,
                    ),
                    child: iconWidget ??
                        Icon(icon, color: iconColor, size: 23),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                (onDark ? Colors.white : AppColors.emeraldDark)
                                    .withValues(alpha: enabled ? 1 : 0.55),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color:
                                (onDark
                                        ? AppColors.textOnDarkMuted
                                        : AppColors.textMuted)
                                    .withValues(alpha: enabled ? 1 : 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    enabled ? Icons.chevron_right_rounded : Icons.block_rounded,
                    color: onDark
                        ? Colors.white.withValues(alpha: enabled ? 0.25 : 0.2)
                        : AppColors.textMuted.withValues(
                            alpha: enabled ? 1 : 0.65,
                          ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delayMs),
          duration: 400.ms,
        )
        .slideX(
          begin: 0.04,
          end: 0,
          delay: Duration(milliseconds: delayMs),
          duration: 450.ms,
          curve: Curves.elasticOut,
        );
  }
}

/// Konum — cam yüzey, yumuşak halka, radar hissi (Material filled yerine).
class _LocateGlossButton extends StatelessWidget {
  const _LocateGlossButton({
    required this.onDark,
    required this.loading,
    required this.onTap,
    required this.onLongPress,
  });

  final bool onDark;
  final bool loading;
  final Future<void> Function() onTap;
  final Future<void> Function() onLongPress;

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
    return ArinPressable(
      enabled: !loading,
      haptic: false,
      scale: 0.92,
      onTap: loading
          ? null
          : () async {
              HapticFeedback.mediumImpact();
              await onTap();
            },
      onLongPress: loading
          ? null
          : () async {
              HapticFeedback.selectionClick();
              await onLongPress();
            },
      child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: onDark
                  ? [
                      AppColors.emeraldMid.withValues(alpha: 0.55),
                      AppColors.homeGradientTop.withValues(alpha: 0.9),
                    ]
                  : [
                      AppColors.emeraldLight.withValues(alpha: 0.35),
                      AppColors.emeraldDark.withValues(alpha: 0.85),
                    ],
            ),
            border: Border.all(
              color: AppColors.accentNeonGreen.withValues(alpha: 0.35),
              width: 1.25,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlowGreen.withValues(alpha: 0.28),
                blurRadius: 14,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: ArinLoader(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.radar_rounded,
                  color: Colors.white.withValues(alpha: 0.96),
                  size: 26,
                ),
      ),
    );
  }
}
