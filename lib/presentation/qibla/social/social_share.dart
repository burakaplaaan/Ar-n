import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/arin_shell_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/arin_top_toast.dart';

enum SocialPostSheetAction { copy, share, delete, report, ban }

Future<SocialPostSheetAction?> showSocialPostSheet({
  required BuildContext context,
  required bool mine,
  bool isAdmin = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<SocialPostSheetAction>(
    context: context,
    backgroundColor: ArinShellBackground.isLight(context)
        ? AppColors.creamSurface
        : AppColors.homeCardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(l10n.socialCopy),
              onTap: () => Navigator.pop(ctx, SocialPostSheetAction.copy),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: Text(l10n.socialShare),
              onTap: () => Navigator.pop(ctx, SocialPostSheetAction.share),
            ),
            if (mine || isAdmin)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(l10n.socialDelete),
                onTap: () => Navigator.pop(ctx, SocialPostSheetAction.delete),
              ),
            if (isAdmin && !mine)
              ListTile(
                leading: const Icon(
                  Icons.block_rounded,
                  color: AppColors.error,
                ),
                title: Text(l10n.socialBan),
                onTap: () => Navigator.pop(ctx, SocialPostSheetAction.ban),
              ),
            if (!mine && !isAdmin)
              ListTile(
                leading: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.error,
                ),
                title: Text(l10n.socialReport),
                onTap: () => Navigator.pop(ctx, SocialPostSheetAction.report),
              ),
          ],
        ),
      );
    },
  );
}

Future<int?> pickSocialBanHours(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: ArinShellBackground.isLight(context)
        ? AppColors.creamSurface
        : AppColors.homeCardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                l10n.socialBanTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              title: Text(l10n.socialBanHour),
              onTap: () => Navigator.pop(ctx, 1),
            ),
            ListTile(
              title: Text(l10n.socialBanDay),
              onTap: () => Navigator.pop(ctx, 24),
            ),
            ListTile(
              title: Text(l10n.socialBanWeek),
              onTap: () => Navigator.pop(ctx, 168),
            ),
            ListTile(
              title: Text(l10n.socialBanMonth),
              onTap: () => Navigator.pop(ctx, 720),
            ),
            ListTile(
              title: Text(l10n.socialBanPermanent),
              onTap: () => Navigator.pop(ctx, 0),
            ),
          ],
        ),
      );
    },
  );
}

/// Sistem paylaşımını sheet kapandıktan sonra açar.
/// iOS'ta sheet kapanana kadar beklenir; süre aşımı panoyu ezmez.
/// Android'de takılırsa await bırakılır, panoya yazılmaz.
Future<void> shareSocialText(BuildContext context, String text) async {
  final l10n = AppLocalizations.of(context)!;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;

  Rect? origin;
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }

  try {
    final pending = SharePlus.instance.share(
      ShareParams(
        text: trimmed,
        sharePositionOrigin:
            !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                ? origin
                : null,
      ),
    );
    final result = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? await pending
        : await pending.timeout(
            const Duration(seconds: 3),
            onTimeout: () => const ShareResult(
              '',
              ShareResultStatus.dismissed,
            ),
          );
    if (result.status == ShareResultStatus.unavailable) {
      await _copyShareFallback(context, trimmed, l10n);
    }
  } catch (_) {
    if (!context.mounted) return;
    await _copyShareFallback(context, trimmed, l10n);
  }
}

Future<void> _copyShareFallback(
  BuildContext context,
  String text,
  AppLocalizations l10n,
) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  showArinTopToast(context, l10n.socialShareUnavailable);
}
