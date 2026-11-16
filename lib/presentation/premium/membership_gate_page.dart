import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/profile_prefs_keys.dart';
import '../../core/constants/revenuecat_ids.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/app_router_refresh.dart';
import '../../data/models/purchase_result.dart' show PurchaseOutcomeX;
import '../../data/models/store_price_info.dart';
import '../../data/services/fcm_token_service.dart';
import '../../data/services/purchase_service.dart';
import '../../data/services/startup_permission_policy.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/onboarding_entry_screens.dart';
import '../onboarding/onboarding_flow_chrome.dart';
import '../shared/providers/user_profile_providers.dart';
import '../shared/widgets/arin_top_toast.dart';

/// Yeni kurulumun son kapısı. Kapanmaz. Eski kurulumlarda açılmaz.
class MembershipGatePage extends ConsumerStatefulWidget {
  const MembershipGatePage({super.key});

  static const privacyPolicyUrl = 'https://arinapp-7b136.web.app/privacy';
  static const termsOfUseUrl = 'https://arinapp-7b136.web.app/terms.html';

  @override
  ConsumerState<MembershipGatePage> createState() => _MembershipGatePageState();
}

class _MembershipGatePageState extends ConsumerState<MembershipGatePage> {
  String? _price;
  bool _busy = false;
  bool _entering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadPrice());
    });
  }

  Future<void> _loadPrice() async {
    final service = ref.read(purchaseServiceProvider);
    final prices = await service.fetchStorePrices([
      RevenueCatIds.yearlyProductId,
    ]);
    final info = prices[RevenueCatIds.yearlyProductId] ??
        StorePriceInfo.maybeCatalogFallback(RevenueCatIds.yearlyProductId);
    if (!mounted) return;
    setState(() => _price = info?.priceString);
  }

  Future<void> _purchase() async {
    if (_busy || _entering) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await PurchaseService.loginUser(user.uid);
        } catch (_) {}
      }
      final result = await ref.read(purchaseServiceProvider).purchase(
            RevenueCatIds.yearlyProductId,
            l10n: l10n,
          );
      if (!mounted) return;
      if (result.isSuccess) {
        await _enterApp();
      } else if (!result.isCancelled) {
        final msg = result.userMessage;
        if (msg != null) showArinTopToast(context, msg);
      }
    } catch (_) {
      if (!mounted) return;
      showArinTopToast(context, l10n.premiumProductNotReadyError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy || _entering) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await PurchaseService.loginUser(user.uid);
        } catch (_) {}
      }
      final result = await ref
          .read(purchaseServiceProvider)
          .restorePurchases(l10n: l10n);
      if (!mounted) return;
      if (!result.isSuccess) {
        final msg = result.userMessage;
        if (msg != null && !result.isCancelled) {
          showArinTopToast(context, msg);
        }
        return;
      }
      final local = await ref.read(purchaseServiceProvider).isPremiumLocally();
      if (!mounted) return;
      if (local) {
        await _enterApp();
      } else {
        showArinTopToast(context, l10n.premiumNoActiveSubscription);
      }
    } catch (_) {
      if (!mounted) return;
      showArinTopToast(context, l10n.premiumProductNotReadyError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enterApp() async {
    if (_entering) return;
    _entering = true;
    final prefs = ref.read(sharedPreferencesProvider);
    final name = prefs.getString(kOnboardingDisplayNameKey)?.trim() ?? '';
    await prefs.setBool(profileNameLockedByUserKey, name.isNotEmpty);
    await prefs.setBool(kAppTourPendingKey, true);
    await prefs.setBool(kAppTourCompletedKey, false);
    await prefs.setBool('onboarding_completed', true);
    await FcmTokenService.markBroadcastPermissionPromptHandled();
    if (!mounted) return;
    try {
      await ref.read(userProfileProvider.notifier).saveProfile(
            name: name.isEmpty ? null : name,
            gender: null,
            moodTags: const [],
            sectorTags: const [],
            needTags: const [],
          );
    } catch (_) {}
    await prefs.setBool(kMembershipGatePendingKey, false);
    unawaited(ArinAnalytics.log('onboarding_complete'));
    ref.read(appRouterRefreshProvider).notifyAuthOrOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.appPrepare);
  }

  Future<void> _openUrl(String rawUrl) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final ok = await launchUrl(
        Uri.parse(rawUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        showArinTopToast(context, l10n.premiumLinkOpenFailed);
      }
    } catch (_) {
      if (!mounted) return;
      showArinTopToast(context, l10n.premiumLinkOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(sharedPreferencesProvider);
    final name = prefs.getString(kOnboardingDisplayNameKey)?.trim() ?? '';
    final greeting = name.isEmpty
        ? l10n.membershipGateGreetingPlain
        : l10n.membershipGateGreeting(name);
    final storeLine = !kIsWeb && Platform.isAndroid
        ? l10n.membershipGateGoogle
        : l10n.membershipGateApple;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const OnboardingEntryBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 34,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.membershipGateBody,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _price ?? '—',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.membershipGatePerYear,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.goldAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.membershipGateRenewal,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          l10n.membershipGateIncludes,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final feature in [
                          l10n.membershipGateFeaturePrayer,
                          l10n.membershipGateFeatureZikir,
                          l10n.membershipGateFeatureExplore,
                          l10n.membershipGateFeatureAi,
                          l10n.membershipGateFeatureWill,
                          l10n.membershipGateFeatureCircle,
                          l10n.membershipGateFeatureDuel,
                          l10n.membershipGateFeatureWidgets,
                          l10n.membershipGateFeatureAds,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: AppColors.goldAccent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      fontSize: 15,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
                    child: OnboardingCtaButton(
                      label: l10n.membershipGateCta,
                      enabled: !_busy,
                      onPressed: _busy ? null : () => unawaited(_purchase()),
                    ),
                  ),
                  Text(
                    storeLine,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Link(
                        label: l10n.membershipGateTerms,
                        onTap: () => unawaited(
                          _openUrl(MembershipGatePage.termsOfUseUrl),
                        ),
                      ),
                      _dot(),
                      _Link(
                        label: l10n.membershipGatePrivacy,
                        onTap: () => unawaited(
                          _openUrl(MembershipGatePage.privacyPolicyUrl),
                        ),
                      ),
                      _dot(),
                      _Link(
                        label: l10n.premiumRestorePurchasesLabel,
                        onTap: _busy ? null : () => unawaited(_restore()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '·',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.55),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

