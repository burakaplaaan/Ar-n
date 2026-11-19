import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/firebase/firebase_bootstrap.dart';
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
  static const _compareTry = '999,99 ₺';

  StorePriceInfo? _yearly;
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
    setState(() => _yearly = info);
  }

  Future<void> _purchase() async {
    if (_busy || _entering) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final user = isFirebaseReady ? FirebaseAuth.instance.currentUser : null;
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
      final user = isFirebaseReady ? FirebaseAuth.instance.currentUser : null;
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
    final yearly = _yearly;
    final priceLabel = yearly?.priceString ?? '—';
    final showCompare = yearly == null ||
        yearly.currencyCode.toUpperCase() == 'TRY' ||
        yearly.currencyCode.toUpperCase() == 'TL';
    final monthlyLine = yearly == null || yearly.price <= 0
        ? null
        : l10n.premiumYearlyPerMonth(yearly.formatAmount(yearly.price / 12));
    const features = <String Function(AppLocalizations)>[
      _prayer,
      _zikir,
      _widgets,
      _explore,
      _ai,
      _will,
      _circle,
      _duel,
      _ads,
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF07110C),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.85),
              radius: 1.15,
              colors: [
                Color(0xFF1B4D3E),
                Color(0xFF07110C),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
            Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                    children: [
                      const _GateMark(),
                      const SizedBox(height: 16),
                      Text(
                        greeting,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 32,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.membershipGateBody,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  l10n.membershipGateIncludes,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              for (final feature in features)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_rounded,
                                        color: AppColors.emeraldLight,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          feature(l10n),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: 14.5,
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 10),
                              if (showCompare)
                                Text(
                                  _compareTry,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.42),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor:
                                        Colors.white.withValues(alpha: 0.42),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                priceLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldLight
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  child: Text(
                                    l10n.membershipGatePerYear,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.emeraldLight,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.membershipGateRenewal,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _busy ? null : () => unawaited(_purchase()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emeraldLight,
                        disabledBackgroundColor:
                            AppColors.emeraldLight.withValues(alpha: 0.45),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.membershipGateCta,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                if (monthlyLine != null)
                  Text(
                    monthlyLine,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 4),
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
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
                Positioned(
                  top: 0,
                  right: 8,
                  child: TextButton(
                    onPressed: _busy ? null : () => unawaited(_restore()),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.9),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      l10n.premiumRestorePurchasesLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class _GateMark extends StatelessWidget {
  const _GateMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: const ClipOval(
          child: Image(
            image: AssetImage('assets/branding/app_icon_1024.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

String _prayer(AppLocalizations l10n) => l10n.membershipGateFeaturePrayer;
String _zikir(AppLocalizations l10n) => l10n.membershipGateFeatureZikir;
String _widgets(AppLocalizations l10n) => l10n.membershipGateFeatureWidgets;
String _explore(AppLocalizations l10n) => l10n.membershipGateFeatureExplore;
String _ai(AppLocalizations l10n) => l10n.membershipGateFeatureAi;
String _will(AppLocalizations l10n) => l10n.membershipGateFeatureWill;
String _circle(AppLocalizations l10n) => l10n.membershipGateFeatureCircle;
String _duel(AppLocalizations l10n) => l10n.membershipGateFeatureDuel;
String _ads(AppLocalizations l10n) => l10n.membershipGateFeatureAds;

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

