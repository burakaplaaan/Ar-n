import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/revenuecat_ids.dart';
import '../../data/models/purchase_result.dart';
import '../../data/services/purchase_service.dart';
import '../../l10n/app_localizations.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';

class SupportArinPage extends ConsumerStatefulWidget {
  const SupportArinPage({super.key});

  @override
  ConsumerState<SupportArinPage> createState() => _SupportArinPageState();
}

class _SupportArinPageState extends ConsumerState<SupportArinPage> {
  static const _privacyPolicyUrl = 'https://arinapp-7b136.web.app/privacy';
  static const _termsOfUseUrl = 'https://arinapp-7b136.web.app/terms.html';

  String? _busyProductId;
  bool _loadingProducts = true;
  final Set<String> _availableProductIds = <String>{};
  final Map<String, String> _priceByProductId = <String, String>{};
  Timer? _productRetryTimer;

  String _normalizeProductId(String productId) {
    final idx = productId.indexOf(':');
    if (idx <= 0) return productId;
    return productId.substring(0, idx);
  }

  Future<void> _retryLoadProductsNow() async {
    if (_busyProductId != null) return;
    _productRetryTimer?.cancel();
    if (!mounted) return;
    setState(() => _loadingProducts = true);
    await _loadSupportProducts();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSupportProducts);
  }

  @override
  void dispose() {
    _productRetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSupportProducts() async {
    final ids = <String>[
      RevenueCatIds.smallSupportProductId,
      RevenueCatIds.mediumSupportProductId,
      RevenueCatIds.largeSupportProductId,
    ];
    final service = ref.read(purchaseServiceProvider);
    await PurchaseService.initialize();
    final prices = await service.fetchProductPriceStrings(
      ids,
      productCategory: ProductCategory.nonSubscription,
    );
    if (!mounted) return;
    setState(() {
      _loadingProducts = false;
      _availableProductIds
        ..clear()
        ..addAll(
          prices.keys.map(_normalizeProductId).where((id) => id.isNotEmpty),
        );
      _priceByProductId
        ..clear()
        ..addEntries(
          prices.entries.map(
            (e) => MapEntry(_normalizeProductId(e.key), e.value),
          ),
        );
    });
    if (prices.isEmpty) {
      _productRetryTimer?.cancel();
      _productRetryTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted || _busyProductId != null || _availableProductIds.isNotEmpty) {
          return;
        }
        setState(() => _loadingProducts = true);
        unawaited(_loadSupportProducts());
      });
    }
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
    if (_loadingProducts || !_availableProductIds.contains(_normalizeProductId(productId))) {
      final l10n = AppLocalizations.of(context)!;
      showArinTopToast(
        context,
        l10n.supportProductNotReady,
        tone: ArinTopToastTone.error,
      );
      return;
    }
    setState(() => _busyProductId = productId);

    final service = ref.read(purchaseServiceProvider);
    final outcome = await service.purchaseSupportProduct(
      productId,
      l10n: AppLocalizations.of(context)!,
    );

    if (!mounted) return;
    setState(() => _busyProductId = null);

    switch (outcome) {
      case PurchaseOutcome _ when outcome.isSuccess:
        showArinTopToast(context, AppLocalizations.of(context)!.premiumLoadingWait);
        _showSuccessDialog();
      case PurchaseOutcome _ when outcome.isCancelled:
        break;
      default:
        final msg = outcome.userMessage;
        if (msg != null) {
          showArinTopToast(
            context,
            msg,
            tone: ArinTopToastTone.error,
          );
        }
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.supportThanksTitle),
        content: Text(l10n.supportThanksBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundNavy : AppColors.creamMist,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.emeraldDark,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(l10n.supportPageTitle),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          MediaQuery.paddingOf(context).bottom + 32,
        ),
        children: [
          const _HeaderCard(),
          const SizedBox(height: 18),
          _SupportCard(
            icon: Icons.local_cafe_rounded,
            title: l10n.supportTierSmallTitle,
            subtitle: l10n.supportTierSmallDesc,
            price: _priceByProductId[RevenueCatIds.smallSupportProductId],
            productId: RevenueCatIds.smallSupportProductId,
            isBusy: _busyProductId == RevenueCatIds.smallSupportProductId,
            anyBusy: _busyProductId != null,
            isEnabled:
                !_loadingProducts &&
                _availableProductIds.contains(
                  _normalizeProductId(RevenueCatIds.smallSupportProductId),
                ),
            onTap: () => _startPurchase(RevenueCatIds.smallSupportProductId),
          ),
          const SizedBox(height: 12),
          _SupportCard(
            icon: Icons.favorite_rounded,
            title: l10n.supportTierMediumTitle,
            subtitle: l10n.supportTierMediumDesc,
            price: _priceByProductId[RevenueCatIds.mediumSupportProductId],
            productId: RevenueCatIds.mediumSupportProductId,
            highlighted: true,
            isBusy: _busyProductId == RevenueCatIds.mediumSupportProductId,
            anyBusy: _busyProductId != null,
            isEnabled:
                !_loadingProducts &&
                _availableProductIds.contains(
                  _normalizeProductId(RevenueCatIds.mediumSupportProductId),
                ),
            onTap: () => _startPurchase(RevenueCatIds.mediumSupportProductId),
          ),
          const SizedBox(height: 12),
          _SupportCard(
            icon: Icons.workspace_premium_rounded,
            title: l10n.supportTierLargeTitle,
            subtitle: l10n.supportTierLargeDesc,
            price: _priceByProductId[RevenueCatIds.largeSupportProductId],
            productId: RevenueCatIds.largeSupportProductId,
            isBusy: _busyProductId == RevenueCatIds.largeSupportProductId,
            anyBusy: _busyProductId != null,
            isEnabled:
                !_loadingProducts &&
                _availableProductIds.contains(
                  _normalizeProductId(RevenueCatIds.largeSupportProductId),
                ),
            onTap: () => _startPurchase(RevenueCatIds.largeSupportProductId),
          ),
          const SizedBox(height: 16),
          if (_priceByProductId.length < 3) ...[
            _SupportProductsLoadingCard(
              loading: _loadingProducts,
              onRetry: _retryLoadProductsNow,
            ),
            const SizedBox(height: 10),
          ],
          if (_priceByProductId.length < 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l10n.supportProductNotReady,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white60 : AppColors.textMuted,
                ),
              ),
            ),
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final l10n = AppLocalizations.of(context)!;
              return Text(
                l10n.supportPackagesDisclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textMuted,
                  height: 1.4,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
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
                  color: isDark ? Colors.white54 : AppColors.textMuted,
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
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.76)
        : AppColors.textSecondary;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.creamDark;
    final iconBgColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.goldAccent.withValues(alpha: 0.14);

    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.emeraldDark.withValues(alpha: 0.96),
                  AppColors.goldAccent.withValues(alpha: 0.22),
                ]
              : [
                  AppColors.creamSurface,
                  AppColors.emeraldFaint.withValues(alpha: 0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.supportHeaderTitle,
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.supportHeaderDesc,
            style: TextStyle(color: subtitleColor, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.productId,
    required this.isBusy,
    required this.anyBusy,
    required this.isEnabled,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? price;
  final String productId;
  final bool isBusy;
  final bool anyBusy;
  final bool isEnabled;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : AppColors.textSecondary;
    final containerColor = highlighted
        ? AppColors.goldAccent.withValues(alpha: 0.12)
        : (isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.creamSurface.withValues(alpha: 0.85));
    final borderColor = highlighted
        ? AppColors.goldAccent.withValues(alpha: 0.7)
        : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.creamDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.accentNeonGreen.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isDark
                            ? AppColors.accentNeonGreen
                            : AppColors.accentGreenOnLight,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(color: subtitleColor, height: 1.28),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton(
                    onPressed: anyBusy || !isEnabled || price == null ? null : onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          highlighted
                              ? AppColors.goldAccent
                              : AppColors.accentNeonGreen,
                      foregroundColor: const Color(0xFF07110B),
                      disabledBackgroundColor:
                          (highlighted
                                  ? AppColors.goldAccent
                                  : AppColors.accentNeonGreen)
                              .withValues(alpha: 0.4),
                    ),
                    child:
                        isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: ArinLoader(
                                  strokeWidth: 2,
                                  color: Color(0xFF07110B),
                                ),
                              )
                            : Text(
                                price ??
                                    AppLocalizations.of(context)!.supportProductNotReady,
                              ),
                  ),
                ),
              ],
            )
          : Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accentNeonGreen.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark
                  ? AppColors.accentNeonGreen
                  : AppColors.accentGreenOnLight,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, height: 1.28),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: anyBusy || !isEnabled || price == null ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor:
                  highlighted ? AppColors.goldAccent : AppColors.accentNeonGreen,
              foregroundColor: const Color(0xFF07110B),
              disabledBackgroundColor:
                  (highlighted ? AppColors.goldAccent : AppColors.accentNeonGreen)
                      .withValues(alpha: 0.4),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: ArinLoader(
                      strokeWidth: 2,
                      color: Color(0xFF07110B),
                    ),
                  )
                : Text(
                    price ?? AppLocalizations.of(context)!.supportProductNotReady,
                  ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _SupportProductsLoadingCard extends StatelessWidget {
  const _SupportProductsLoadingCard({
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
              l10n.supportProductNotReady,
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
