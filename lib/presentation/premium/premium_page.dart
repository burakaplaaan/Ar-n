import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/revenuecat_ids.dart';
import '../../core/router/app_router.dart';
import '../../data/models/purchase_result.dart' show PurchaseOutcomeX;
import '../../data/models/store_price_info.dart';
import '../../data/services/purchase_service.dart';
import '../../l10n/app_localizations.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/providers/premium_providers.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';
import 'package:arin/presentation/shared/widgets/arin_popup.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';

/// Android/iOS'ta mağazadan gerçek fiyatları çeker.
final _premiumPricesProvider =
    FutureProvider.autoDispose<Map<String, StorePriceInfo>>((ref) async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return {};
  final service = PurchaseService();
  final subscriptions = await service.fetchStorePrices([
    PremiumPage.yearlyProductId,
    PremiumPage.monthlyProductId,
  ]);
  final lifetime = await service.fetchLifetimeStorePrices();
  return {...subscriptions, ...lifetime};
});

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  static const monthlyProductId = RevenueCatIds.monthlyProductId;
  static const yearlyProductId = RevenueCatIds.yearlyProductId;
  static const lifetimeProductId = RevenueCatIds.lifetimeProductId;

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  static const _privacyPolicyUrl = 'https://arinapp-7b136.web.app/privacy';
  static const _termsOfUseUrl = 'https://arinapp-7b136.web.app/terms.html';

  String? _busyProductId;
  bool _loadingProducts = true;
  int _incompleteRetryCount = 0;
  final Set<String> _availableProductIds = <String>{};
  final Map<String, StorePriceInfo> _storePriceByBaseId = <String, StorePriceInfo>{};
  Timer? _productRetryTimer;

  static const _expectedProductIds = [
    PremiumPage.yearlyProductId,
    PremiumPage.monthlyProductId,
    PremiumPage.lifetimeProductId,
  ];
  static const _maxIncompleteRetries = 4;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPremiumProducts);
  }

  @override
  void dispose() {
    _productRetryTimer?.cancel();
    super.dispose();
  }

  bool get _catalogComplete =>
      _expectedProductIds.every(_availableProductIds.contains);

  Future<void> _loadPremiumProducts({bool showSpinner = false}) async {
    if (showSpinner && mounted) {
      setState(() => _loadingProducts = true);
    }
    await PurchaseService.initialize();
    final service = ref.read(purchaseServiceProvider);
    final prices = {
      ...await service.fetchStorePrices([
        PremiumPage.yearlyProductId,
        PremiumPage.monthlyProductId,
      ]),
      ...await service.fetchLifetimeStorePrices(),
    };
    if (!mounted) return;
    setState(() {
      _loadingProducts = false;
      _availableProductIds.addAll(
        prices.keys.map((id) => _normalizeProductId(id)).where((id) => id.isNotEmpty),
      );
      _storePriceByBaseId.addEntries(
        prices.entries.map(
          (e) => MapEntry(_normalizeProductId(e.key), e.value),
        ),
      );
    });
    _scheduleIncompleteRetry();
  }

  void _scheduleIncompleteRetry() {
    if (_catalogComplete || _incompleteRetryCount >= _maxIncompleteRetries) {
      return;
    }
    _productRetryTimer?.cancel();
    _productRetryTimer = Timer(
      Duration(seconds: 2 + _incompleteRetryCount),
      () {
        if (!mounted || _busyProductId != null || _catalogComplete) {
          return;
        }
        _incompleteRetryCount += 1;
        unawaited(_loadPremiumProducts(showSpinner: !_catalogComplete && _availableProductIds.isEmpty));
      },
    );
  }

  Future<void> _retryLoadProductsNow() async {
    if (_busyProductId != null) return;
    _productRetryTimer?.cancel();
    _incompleteRetryCount = 0;
    if (!mounted) return;
    await _loadPremiumProducts(showSpinner: _availableProductIds.isEmpty);
  }

  Future<void> _openExternalUrl(String rawUrl) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final uri = Uri.parse(rawUrl);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        showArinTopToast(context, l10n.premiumLinkOpenFailed);
      }
    } catch (_) {
      if (!mounted) return;
      showArinTopToast(context, l10n.premiumLinkOpenFailed);
    }
  }

  Future<void> _startPurchase(String productId) async {
    if (_busyProductId != null) return;
    final l10n = AppLocalizations.of(context)!;
    if (RevenueCatIds.isLegacyProductId(productId) ||
        !RevenueCatIds.canPurchaseInApp(productId)) {
      showArinTopToast(context, l10n.purchaseErrorLegacyPlan);
      return;
    }
    final entitlement = ref.read(premiumEntitlementProvider).asData?.value;
    final activeProductId = entitlement?.productId ?? '';
    if (RevenueCatIds.isLegacyProductId(activeProductId) &&
        _normalizeProductId(productId) != PremiumPage.lifetimeProductId) {
      showArinTopToast(context, l10n.purchaseErrorLegacyPlan);
      return;
    }
    if (_loadingProducts || !_containsProduct(productId)) {
      showArinTopToast(
        context,
        l10n.premiumProductNotReadyError,
        tone: ArinTopToastTone.error,
      );
      return;
    }
    final user = ref.read(authUserProvider).asData?.value;
    if (user != null) {
      try {
        await PurchaseService.loginUser(user.uid);
      } catch (e) {
        if (mounted) {
          showArinTopToast(context, l10n.premiumAccountLinkError);
        }
        return;
      }
    }

    setState(() => _busyProductId = productId);
    try {
      final service = ref.read(purchaseServiceProvider);
      final result = _normalizeProductId(productId) == PremiumPage.lifetimeProductId
          ? await service.purchaseLifetime(l10n: l10n)
          : await service.purchase(productId, l10n: l10n);

      if (!mounted) return;

      if (result.isSuccess) {
        // Premium aktif: Firestore'u yenile ve başarı sayfası/mesajı göster.
        ref.invalidate(premiumEntitlementProvider);
        var entitlement = await ref.read(premiumEntitlementProvider.future);
        if (!entitlement.isActive) {
          await Future<void>.delayed(const Duration(seconds: 3));
          ref.invalidate(premiumEntitlementProvider);
          entitlement = await ref.read(premiumEntitlementProvider.future);
        }
        final localActive = await ref.read(purchaseServiceProvider).isPremiumLocally();
        final premiumConfirmed = entitlement.isActive || localActive;
        if (!premiumConfirmed && mounted) {
          showArinTopToast(context, l10n.premiumLoadingWait);
        }
        if (mounted && ref.read(authUserProvider).asData?.value == null) {
          await _maybePromptAccountLinkAfterPurchase();
        }
        if (premiumConfirmed) {
          await _showSuccessDialog();
        }
      } else if (!result.isCancelled) {
        final msg = result.userMessage;
        if (msg != null) {
          showArinTopToast(context, msg);
        }
      }
    } finally {
      if (mounted) setState(() => _busyProductId = null);
    }
  }

  Future<void> _maybePromptAccountLinkAfterPurchase() async {
    final l10n = AppLocalizations.of(context)!;
    final shouldLink = await showArinConfirm(
      context: context,
      title: l10n.premiumPostPurchaseLinkTitle,
      message: l10n.premiumPostPurchaseLinkBody,
      cancelLabel: l10n.premiumPostPurchaseLinkLater,
      confirmLabel: l10n.premiumPostPurchaseLinkNow,
      icon: Icons.link_rounded,
    );
    if (shouldLink != true || !mounted) return;
    final signedIn = await _showSignInSheet();
    if (signedIn != true || !mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await PurchaseService.loginUser(uid);
      if (!mounted) return;
      ref.invalidate(premiumEntitlementProvider);
      showArinTopToast(context, l10n.premiumPostPurchaseLinkSuccess);
    } catch (e) {
      if (!mounted) return;
      showArinTopToast(context, l10n.premiumAccountLinkError);
    }
  }

  String _normalizeProductId(String productId) {
    final idx = productId.indexOf(':');
    if (idx <= 0) return productId;
    return productId.substring(0, idx);
  }

  bool _containsProduct(String productId) =>
      _availableProductIds.contains(_normalizeProductId(productId));

  bool _ownsAny(String activeProductId, List<String> candidates) {
    final base = _normalizeProductId(activeProductId);
    if (base.isEmpty) return false;
    return candidates.any((id) => base == id || base.startsWith(id));
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showArinPopup<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ArinPopupCard(
        title: l10n.premiumWelcomeTitle,
        message: l10n.premiumWelcomeMessage,
        confirmLabel: l10n.premiumWelcomeButton,
        icon: Icons.workspace_premium_rounded,
        onConfirm: () {
          Navigator.pop(ctx);
          if (mounted && context.canPop()) context.pop();
        },
      ),
    );
  }

  Future<void> _restorePurchases() async {
    if (_busyProductId != null) return;
    final l10n = AppLocalizations.of(context)!;

    final user = ref.read(authUserProvider).asData?.value;
    if (user != null) {
      try {
        await PurchaseService.loginUser(user.uid);
      } catch (e) {
        if (mounted) {
          showArinTopToast(context, l10n.premiumAccountLinkError);
        }
        return;
      }
    }

    setState(() => _busyProductId = '__restore__');
    try {
      final result = await ref
          .read(purchaseServiceProvider)
          .restorePurchases(l10n: l10n);
      if (!mounted) return;

      if (result.isSuccess) {
        ref.invalidate(premiumEntitlementProvider);
        final entitlement = await ref.read(premiumEntitlementProvider.future);
        if (!mounted) return;
        
        final localActive = await ref.read(purchaseServiceProvider).isPremiumLocally();
        
        if (entitlement.isActive || localActive) {
          showArinTopToast(context, l10n.premiumRestoreSuccess);
        } else {
          showArinTopToast(context, l10n.premiumNoActiveSubscription);
        }
      } else {
        final msg = result.userMessage ?? l10n.premiumNoActiveSubscription;
        showArinTopToast(context, msg);
      }
    } finally {
      if (mounted) setState(() => _busyProductId = null);
    }
  }

  Future<bool?> _showSignInSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var authBusy = false;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? const Color(0xFF08130E) : AppColors.creamSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> signIn(_PremiumAuth provider) async {
            if (authBusy) return;
            setSheetState(() => authBusy = true);
            final ok = await _signInForPremium(provider: provider);
            if (ctx.mounted && ok) {
              Navigator.pop(ctx, true);
              return;
            }
            if (ctx.mounted) {
              setSheetState(() => authBusy = false);
            }
          }

          return _PremiumSignInSheet(
            authBusy: authBusy,
            appleAvailable: ref.read(authServiceProvider).appleSignInAvailable,
            onGoogle: () => signIn(_PremiumAuth.google),
            onApple: () => signIn(_PremiumAuth.apple),
          );
        },
      ),
    );
  }

  Future<bool> _signInForPremium({required _PremiumAuth provider}) async {
    try {
      final service = ref.read(authServiceProvider);
      switch (provider) {
        case _PremiumAuth.google:
          await service.signInWithGoogle();
          break;
        case _PremiumAuth.apple:
          await service.signInWithApple();
          break;
      }
      if (!mounted) return false;
      ref.invalidate(premiumEntitlementProvider);
      return true;
    } catch (e) {
      if (mounted) {
        showArinTopToast(context, '${AppLocalizations.of(context)!.premiumSignInErrorPrefix}$e');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final premiumAsync = ref.watch(premiumEntitlementProvider);
    
    // Yükleniyor durumundayken "ücretsiz" muamelesi yapmamak için skeleton veya loading gösterebiliriz.
    // Ancak arka plandaki fetchProducts devam ederken de premium loading state'te olabilir,
    // tüm paywall'u gizlemeyip isPremium fallback değerini bilinmeyen durumda null tutalım.
    final entitlement = premiumAsync.asData?.value;
    final isPremium = premiumAsync.isLoading ? null : (entitlement?.isActive ?? false);
    final activeProductId = entitlement?.productId ?? '';

    // Google Play subscription id'leri basePlan id'si ile birleşip gelebilir
    // (örn: arin_premium_yearly:p1y). Eski lansman SKU'ları da sahiplik sayılır.
    final hasYearly =
        isPremium == true &&
        _ownsAny(activeProductId, RevenueCatIds.allYearlyProductIds);
    final hasMonthly =
        isPremium == true &&
        _ownsAny(activeProductId, RevenueCatIds.allMonthlyProductIds);
    final hasLifetime =
        isPremium == true &&
        _ownsAny(activeProductId, RevenueCatIds.allLifetimeProductIds);
    final hasLegacyPlan =
        isPremium == true && RevenueCatIds.isLegacyProductId(activeProductId);
    final canSwitchToYearly = hasMonthly && !hasLegacyPlan;
    final signedIn = ref.watch(authUserProvider).asData?.value != null;

    // Android/iOS'ta mağazadan gerçek fiyatlar kullanılır.
    final prices = ref.watch(_premiumPricesProvider).asData?.value ?? {};
    final providerPriceByBaseId = <String, StorePriceInfo>{
      for (final entry in prices.entries)
        _normalizeProductId(entry.key): entry.value,
    };
    final mergedPriceByBaseId = {
      ...providerPriceByBaseId,
      ..._storePriceByBaseId,
    };
    
    final yearlyInfo = mergedPriceByBaseId[PremiumPage.yearlyProductId] ??
        StorePriceInfo.maybeCatalogFallback(PremiumPage.yearlyProductId);
    final monthlyInfo = mergedPriceByBaseId[PremiumPage.monthlyProductId] ??
        StorePriceInfo.maybeCatalogFallback(PremiumPage.monthlyProductId);
    final lifetimeInfo = mergedPriceByBaseId[PremiumPage.lifetimeProductId] ??
        StorePriceInfo.maybeCatalogFallback(PremiumPage.lifetimeProductId);
    final yearlyPrice = yearlyInfo?.priceString;
    final monthlyPrice = monthlyInfo?.priceString;
    final lifetimePrice = lifetimeInfo?.priceString;
    final yearlyPerMonth = yearlyInfo?.monthlyEquivalentString ?? '';
    final yearlyReady =
        yearlyPrice != null && _containsProduct(PremiumPage.yearlyProductId);
    final monthlyReady =
        monthlyPrice != null && _containsProduct(PremiumPage.monthlyProductId);
    final lifetimeReady =
        lifetimePrice != null && _containsProduct(PremiumPage.lifetimeProductId);
    final anyProductReady = yearlyReady || monthlyReady || lifetimeReady;

    final titleTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleTextColor = isDark
        ? Colors.white.withValues(alpha: 0.74)
        : AppColors.textSecondary;
    final footerTextColor = isDark
        ? Colors.white.withValues(alpha: 0.52)
        : AppColors.textMuted;

    final restoreBusy = _busyProductId == '__restore__';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundNavy : AppColors.creamMist,
      body: Stack(
        children: [
          const _PremiumBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _PremiumCloseButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                  return;
                                }
                                context.go(AppRoutes.home);
                              },
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: restoreBusy ? null : () => _restorePurchases(),
                              icon: restoreBusy
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: ArinLoader(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.restore_rounded, size: 18),
                              label: Text(l10n.premiumRestorePurchasesLabel),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _LaunchBadge(),
                        const SizedBox(height: 18),
                        if (isPremium == null)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: ArinLoader(),
                            ),
                          )
                        else ...[
                          Text(
                            isPremium ? l10n.premiumActiveTitle : l10n.premiumTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: titleTextColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isPremium
                                ? l10n.premiumActiveSubtitle
                                : l10n.premiumSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: subtitleTextColor,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (isPremium) ...[
                            const _GrandfatherNotice(),
                            const SizedBox(height: 14),
                          ],
                          if (!isPremium && !signedIn) ...[
                            const _SignInRequiredNotice(),
                            const SizedBox(height: 14),
                          ],
                          if (!anyProductReady) ...[
                            _ProductsLoadingCard(
                              loading: _loadingProducts,
                              onRetry: _retryLoadProductsNow,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _PlanCard(
                            title: l10n.premiumYearlyPlanTitle,
                            badge: hasYearly ? null : l10n.premiumMostAdvantageousBadge,
                            oldPrice: null,
                            price: hasYearly && hasLegacyPlan
                                ? l10n.premiumLegacyOwnedPrice
                                : yearlyPrice ?? '—',
                            subline: yearlyReady
                                ? (yearlyPerMonth.isNotEmpty
                                    ? l10n.premiumYearlyPerMonth(yearlyPerMonth)
                                    : l10n.premiumYearlyPlanSubtitle)
                                : l10n.premiumPlanComingSoon,
                            footnote: yearlyReady ? l10n.premiumYearlyTrialNote : null,
                            saveHint: yearlyReady && !hasYearly && !hasLegacyPlan
                                ? l10n.premiumYearlySaveVsMonthly
                                : null,
                            productId: PremiumPage.yearlyProductId,
                            highlighted: !hasYearly,
                            isOwned: hasYearly,
                            enabled:
                                yearlyReady &&
                                !hasLifetime &&
                                (!isPremium || canSwitchToYearly) &&
                                !_loadingProducts,
                            buttonLabel: canSwitchToYearly
                                ? l10n.premiumSwitchToYearly
                                : l10n.premiumYearlyTrialCta,
                            busy: _busyProductId == PremiumPage.yearlyProductId,
                            productReady: yearlyReady,
                            currentlyPremium: isPremium == true,
                            onPressed: () => _startPurchase(PremiumPage.yearlyProductId),
                            onRetry: yearlyReady ? null : _retryLoadProductsNow,
                          ),
                          const SizedBox(height: 12),
                          _PlanCard(
                            title: l10n.premiumMonthlyPlanTitle,
                            oldPrice: null,
                            price: hasMonthly && hasLegacyPlan
                                ? l10n.premiumLegacyOwnedPrice
                                : monthlyPrice ?? '—',
                            subline: monthlyReady
                                ? l10n.premiumMonthlyPlanSubtitle
                                : l10n.premiumPlanComingSoon,
                            productId: PremiumPage.monthlyProductId,
                            highlighted: false,
                            isOwned: hasMonthly,
                            enabled:
                                monthlyReady &&
                                !isPremium &&
                                !hasLifetime &&
                                !_loadingProducts,
                            buttonLabel: l10n.premiumMonthlyCta,
                            busy: _busyProductId == PremiumPage.monthlyProductId,
                            productReady: monthlyReady,
                            currentlyPremium: isPremium == true,
                            onPressed: () => _startPurchase(PremiumPage.monthlyProductId),
                            onRetry: monthlyReady ? null : _retryLoadProductsNow,
                          ),
                          const SizedBox(height: 12),
                          _PlanCard(
                            title: l10n.premiumLifetimePlanTitle,
                            badge: hasLifetime ? null : l10n.premiumLifetimeBadge,
                            oldPrice: null,
                            price: lifetimePrice ?? '—',
                            subline: lifetimeReady
                                ? l10n.premiumLifetimePlanSubtitle
                                : l10n.premiumPlanComingSoon,
                            footnote: lifetimeReady ? l10n.premiumLifetimeNote : null,
                            productId: PremiumPage.lifetimeProductId,
                            highlighted: false,
                            isOwned: hasLifetime,
                            enabled:
                                lifetimeReady &&
                                !hasLifetime &&
                                !_loadingProducts,
                            buttonLabel: l10n.premiumLifetimeCta,
                            busy: _busyProductId == PremiumPage.lifetimeProductId,
                            productReady: lifetimeReady,
                            currentlyPremium: isPremium == true,
                            onPressed: () =>
                                _startPurchase(PremiumPage.lifetimeProductId),
                            onRetry: lifetimeReady ? null : _retryLoadProductsNow,
                          ),
                          const SizedBox(height: 22),
                          const _FreePremiumCompare(),
                          const SizedBox(height: 18),
                        ],
                        Text(
                          l10n.premiumFooterText1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: footerTextColor,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.premiumFooterText2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: footerTextColor,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => _openExternalUrl(_privacyPolicyUrl),
                              child: Text(l10n.premiumLegalPrivacyPolicy),
                            ),
                            Text(
                              '•',
                              style: TextStyle(
                                color: footerTextColor,
                                fontSize: 12,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openExternalUrl(_termsOfUseUrl),
                              child: Text(l10n.premiumLegalTermsOfUse),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF020604),
                      Color(0xFF0C1F17),
                      Color(0xFF050806),
                    ]
                  : [
                      AppColors.creamMist,
                      AppColors.creamBase,
                      AppColors.creamShellDeep,
                    ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: -90,
          right: -80,
          child: _Glow(
            color: AppColors.goldAccent.withValues(
              alpha: isDark ? 0.28 : 0.18,
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: -110,
          child: _Glow(
            color: AppColors.emeraldMid.withValues(
              alpha: isDark ? 0.2 : 0.12,
            ),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 54, sigmaY: 54),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _PremiumCloseButton extends StatelessWidget {
  const _PremiumCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.premiumCloseSemantics,
      child: Material(
        color: isDark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              Icons.close_rounded,
              size: 28,
              color: isDark ? Colors.white : AppColors.emeraldDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchBadge extends StatelessWidget {
  const _LaunchBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.goldAccent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.goldAccent.withValues(alpha: 0.58),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.premiumLaunchBadge,
          style: const TextStyle(
            color: AppColors.goldAccent,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.9,
          ),
        ),
      ),
    );
  }
}

class _FreePremiumCompare extends StatelessWidget {
  const _FreePremiumCompare();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final freeColor = isDark
        ? Colors.white.withValues(alpha: 0.52)
        : AppColors.textMuted;
    final premiumColor = isDark
        ? AppColors.goldAccent
        : AppColors.emeraldDark;
    final rows = [
      (l10n.premiumCompareAds, l10n.premiumCompareAdsFree, l10n.premiumCompareAdsPremium),
      (l10n.premiumCompareWidgets, l10n.premiumCompareWidgetsFree, l10n.premiumCompareWidgetsPremium),
      (l10n.premiumCompareThemes, l10n.premiumCompareThemesFree, l10n.premiumCompareThemesPremium),
      (l10n.premiumCompareAi, l10n.premiumCompareAiFree, l10n.premiumCompareAiPremium),
      (l10n.qiblaHubAssistantTitle, l10n.premiumCompareWidgetsFree, l10n.premiumCompareWidgetsPremium),
      (l10n.premiumCompareExplore, l10n.premiumCompareExploreFree, l10n.premiumCompareExplorePremium),
      (l10n.premiumCompareAdhan, l10n.premiumCompareAdhanFree, l10n.premiumCompareAdhanPremium),
      (l10n.premiumComparePrayer, l10n.premiumComparePrayerFree, l10n.premiumComparePrayerPremium),
      (l10n.premiumCompareContest, l10n.premiumCompareContestFree, l10n.premiumCompareContestPremium),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.creamSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.goldAccent.withValues(alpha: 0.28)
              : AppColors.goldAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.premiumCompareTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox.shrink()),
              Expanded(
                flex: 3,
                child: Text(
                  l10n.premiumCompareColFree,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: freeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  l10n.premiumCompareColPremium,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: premiumColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.creamDark.withValues(alpha: 0.7),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      rows[i].$1,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: freeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[i].$3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: premiumColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GrandfatherNotice extends StatelessWidget {
  const _GrandfatherNotice();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_outlined,
            color: isDark ? AppColors.goldAccent : AppColors.emeraldDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.premiumGrandfatherNotice,
              style: TextStyle(
                color: textColor,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInRequiredNotice extends StatelessWidget {
  const _SignInRequiredNotice();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentNeonGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentNeonGreen.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_circle_outlined,
            color: isDark
                ? AppColors.accentNeonGreen
                : AppColors.accentGreenOnLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.premiumSignInRequired,
              style: TextStyle(
                color: textColor,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsLoadingCard extends StatelessWidget {
  const _ProductsLoadingCard({
    required this.loading,
    required this.onRetry,
  });

  final bool loading;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.creamSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.14) : AppColors.creamDark,
        ),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: ArinLoader(strokeWidth: 2),
            )
          else
            const Icon(Icons.info_outline_rounded, color: AppColors.goldAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.premiumProductNotReadyError,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: loading ? null : () => onRetry(),
            child: Text(l10n.asyncErrorRetryAction),
          ),
        ],
      ),
    );
  }
}

enum _PremiumAuth { google, apple }

class _PremiumSignInSheet extends StatelessWidget {
  const _PremiumSignInSheet({
    required this.authBusy,
    required this.appleAvailable,
    required this.onGoogle,
    required this.onApple,
  });

  final bool authBusy;
  final bool appleAvailable;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textSecondary;
    final appleButtonColor =
        isDark ? Colors.white : AppColors.textPrimary;
    final appleBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.24)
        : AppColors.creamDark;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.paddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.lock_open_rounded,
              color: AppColors.goldAccent,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.premiumSignInSheetTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.premiumSignInSheetSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, height: 1.35),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: authBusy ? null : onGoogle,
              icon: authBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ArinLoader(strokeWidth: 2),
                    )
                  : SvgPicture.string(
                      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/><path fill="none" d="M0 0h48v48H0z"/></svg>''',
                      width: 20,
                      height: 20,
                    ),
              label: Text(AppLocalizations.of(context)!.premiumContinueWithGoogle),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentNeonGreen,
                foregroundColor: const Color(0xFF07110B),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (appleAvailable) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: authBusy ? null : onApple,
                icon: const Icon(Icons.apple_rounded),
                label: Text(AppLocalizations.of(context)!.premiumContinueWithApple),
                style: OutlinedButton.styleFrom(
                  foregroundColor: appleButtonColor,
                  side: BorderSide(color: appleBorderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: authBusy ? null : () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.premiumCancelForNow),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.oldPrice,
    required this.price,
    required this.subline,
    required this.productId,
    required this.highlighted,
    required this.enabled,
    required this.busy,
    required this.onPressed,
    this.badge,
    this.isOwned = false,
    this.buttonLabel,
    this.productReady = true,
    this.currentlyPremium = false,
    this.footnote,
    this.saveHint,
    this.onRetry,
  });

  final String title;
  final String? oldPrice;
  final String price;
  final String subline;
  final String? footnote;
  final String? saveHint;
  final String productId;
  final bool highlighted;
  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;
  final String? badge;
  /// Kullanıcının aktif olarak sahip olduğu plan.
  final bool isOwned;
  /// Varsayılan buton metnini override eder (örn. "Yıllığa geç").
  final String? buttonLabel;
  final bool productReady;
  final bool currentlyPremium;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final oldPriceColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.textMuted;
    final priceTextColor = isDark ? Colors.white : AppColors.textPrimary;

    // isOwned ise yeşil border + hafif yeşil arka plan.
    final borderColor = isOwned
        ? AppColors.accentNeonGreen.withValues(alpha: 0.7)
        : (highlighted
              ? AppColors.goldAccent
              : (isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppColors.creamDark));
    final containerColor = isOwned
        ? AppColors.accentNeonGreen.withValues(alpha: 0.08)
        : (highlighted
              ? AppColors.goldAccent.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : AppColors.creamSurface.withValues(alpha: 0.85)));

    // Badge: isOwned ise "Aktif planınız ✓", aksi halde verilen badge.
    final effectiveBadge = isOwned ? AppLocalizations.of(context)!.premiumActivePlanBadge : badge;
    final badgeBgColor =
        isOwned ? AppColors.accentNeonGreen : AppColors.goldAccent;
    final badgeFgColor =
        isOwned ? const Color(0xFF07110B) : const Color(0xFF241900);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: (highlighted || isOwned) ? 1.4 : 1,
        ),
        boxShadow: highlighted && !isOwned
            ? [
                BoxShadow(
                  color: AppColors.goldAccent.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (effectiveBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    effectiveBadge,
                    style: TextStyle(
                      color: badgeFgColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (oldPrice != null) ...[
            Text(
              oldPrice!,
              style: TextStyle(
                color: oldPriceColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.lineThrough,
                decorationColor: oldPriceColor,
                decorationThickness: 2,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            price,
            style: TextStyle(
              color: priceTextColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subline,
            style: TextStyle(
              color: isOwned
                  ? (isDark
                        ? AppColors.accentNeonGreen
                        : AppColors.accentGreenOnLight)
                  : (highlighted
                        ? AppColors.goldAccent
                        : (isDark
                              ? AppColors.accentNeonGreen
                              : AppColors.accentGreenOnLight)),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (saveHint != null) ...[
            const SizedBox(height: 8),
            Text(
              saveHint!,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.72)
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (footnote != null) ...[
            const SizedBox(height: 6),
            Text(
              footnote!,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.62)
                    : AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy
                  ? null
                  : (!isOwned && !productReady
                        ? onRetry
                        : (enabled ? onPressed : null)),
              style: FilledButton.styleFrom(
                backgroundColor: highlighted
                    ? AppColors.goldAccent
                    : AppColors.accentNeonGreen,
                foregroundColor: const Color(0xFF07110B),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: ArinLoader(strokeWidth: 2),
                    )
                  : Text(
                      isOwned
                          ? AppLocalizations.of(context)!.premiumActivePlanButton
                          : (!productReady
                                ? (onRetry != null
                                      ? AppLocalizations.of(context)!.asyncErrorRetryAction
                                      : AppLocalizations.of(context)!.premiumPlanComingSoon)
                                : (enabled
                                      ? (buttonLabel ?? AppLocalizations.of(context)!.premiumStartWithLaunchPrice)
                                      : (currentlyPremium
                                            ? AppLocalizations.of(context)!.premiumIsActiveButton
                                            : (buttonLabel ?? AppLocalizations.of(context)!.premiumStartWithLaunchPrice)))),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
