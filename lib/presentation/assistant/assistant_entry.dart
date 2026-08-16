import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../data/services/paywall_prompt_service.dart';
import '../shared/providers/premium_providers.dart';

/// Premium değilse paywall, Premium ise asistan sohbeti.
Future<void> openAssistantOrPaywall({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final isPremium = ref.read(premiumAccessStateProvider) ==
      PremiumAccessState.premium;
  if (!isPremium) {
    await PaywallPromptService.showForLockedFeature(context);
    return;
  }
  if (!context.mounted) return;
  context.push(AppRoutes.assistant);
}
