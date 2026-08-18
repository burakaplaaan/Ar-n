import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/startup_permission_policy.dart';
import '../../shared/widgets/arin_popup.dart';

bool _promptInFlight = false;

Future<void> maybeShowPostTourWidgetPrompt({
  required BuildContext context,
  required SharedPreferences prefs,
}) async {
  if (_promptInFlight) return;
  if (prefs.getBool(kAppTourWidgetPromptPendingKey) != true) return;
  if (!context.mounted) return;
  _promptInFlight = true;
  try {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!context.mounted) return;
    if (prefs.getBool(kAppTourWidgetPromptPendingKey) != true) return;

    final goToWidgets = await showArinPopup<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _PostTourWidgetPromptCard(),
    );
    await prefs.setBool(kAppTourWidgetPromptPendingKey, false);
    if (goToWidgets == true && context.mounted) {
      context.go(AppRoutes.settingsWidgets);
    }
  } finally {
    _promptInFlight = false;
  }
}

class _PostTourWidgetPromptCard extends StatelessWidget {
  const _PostTourWidgetPromptCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ArinPopupCard(
      title: l10n.appTourWidgetPromptTitle,
      message: l10n.appTourWidgetPromptBody,
      leading: const _WidgetInviteGlyph(),
      cancelLabel: l10n.appTourWidgetPromptLater,
      confirmLabel: l10n.appTourWidgetPromptYes,
      onCancel: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(false);
      },
      onConfirm: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
      },
    );
  }
}

class _WidgetInviteGlyph extends StatelessWidget {
  const _WidgetInviteGlyph();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.ornamentGold.withValues(alpha: 0.14),
          border: Border.all(
            color: AppColors.ornamentGold.withValues(alpha: 0.42),
          ),
        ),
        child: const Icon(
          Icons.widgets_rounded,
          color: AppColors.ornamentGold,
          size: 32,
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.94, 0.94),
            end: const Offset(1.06, 1.06),
            duration: 1100.ms,
            curve: Curves.easeInOutCubic,
          ),
    );
  }
}

@visibleForTesting
bool shouldOfferPostTourWidgetPrompt({required bool promptPending}) {
  return promptPending;
}
