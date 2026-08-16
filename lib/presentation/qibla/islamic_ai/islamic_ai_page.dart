import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../../../data/services/paywall_prompt_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/providers/premium_providers.dart';
import '../../shared/widgets/arin_shell_layout.dart';

/// Arkadaşın AI kodu gelene kadar duran Premium kapısı.
/// Ücretsiz kullanıcı paywall görür; Premium kullanıcı bekleme ekranı görür.
class IslamicAiPage extends ConsumerStatefulWidget {
  const IslamicAiPage({super.key});

  @override
  ConsumerState<IslamicAiPage> createState() => _IslamicAiPageState();
}

class _IslamicAiPageState extends ConsumerState<IslamicAiPage> {
  var _openedPaywall = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_gateIfNeeded());
    });
  }

  Future<void> _gateIfNeeded() async {
    if (!mounted || _openedPaywall) return;
    final access = ref.read(premiumAccessStateProvider);
    if (access == PremiumAccessState.premium) return;
    if (access == PremiumAccessState.loading) {
      try {
        final entitlement = await ref.read(premiumEntitlementProvider.future);
        if (!mounted) return;
        if (entitlement.isActive) return;
      } catch (_) {
        if (!mounted) return;
      }
    }
    _openedPaywall = true;
    await PaywallPromptService.showForLockedFeature(context);
    if (!mounted) return;
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(premiumAccessStateProvider, (previous, next) {
      if (next == PremiumAccessState.free) {
        unawaited(_gateIfNeeded());
      }
    });
    final l10n = AppLocalizations.of(context)!;
    final onDark = !ArinShellBackground.isLight(context);
    final titleColor = onDark ? Colors.white : AppColors.emeraldDark;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: ArinShellBackground.decoration(context)),
          ArinShellBackground.bubbleLayer(context),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                8,
                22,
                ArinShellLayout.bottomContentPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 48,
                    color: AppColors.goldAccent.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.islamicAiComingSoonTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.islamicAiComingSoonBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
