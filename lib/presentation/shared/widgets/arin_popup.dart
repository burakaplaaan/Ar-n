import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/arin_shell_background.dart';

/// Son dokunuş noktası — popup tıklanan yerden büyüsün diye.
abstract final class ArinDialogOrigin {
  static Offset? lastGlobal;

  static void remember(Offset global) => lastGlobal = global;

  static Alignment resolve(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final tap = lastGlobal;
    if (tap != null && size.width > 0 && size.height > 0) {
      return Alignment(
        ((tap.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
        ((tap.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
      );
    }
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && size.width > 0 && size.height > 0) {
      final center = box.localToGlobal(box.size.center(Offset.zero));
      return Alignment(
        ((center.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
        ((center.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
      );
    }
    return Alignment.center;
  }
}

enum ArinPopupTone { accent, destructive, warning }

/// Tıklanan noktadan büyüyen, Arın temalı genel popup.
Future<T?> showArinPopup<T>({
  required BuildContext context,
  required Widget Function(BuildContext dialogContext) builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final alignment = ArinDialogOrigin.resolve(context);
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Builder(
          builder: (safeContext) => Center(
            child: builder(safeContext),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.16, end: 1).animate(curved),
          alignment: alignment,
          child: child,
        ),
      );
    },
  );
}

Future<bool> showArinConfirm({
  required BuildContext context,
  required String title,
  String? message,
  required String cancelLabel,
  required String confirmLabel,
  ArinPopupTone tone = ArinPopupTone.accent,
  IconData? icon,
  bool barrierDismissible = true,
}) async {
  final result = await showArinPopup<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => ArinPopupCard(
      title: title,
      message: message,
      icon: icon,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      tone: tone,
      onCancel: () => Navigator.of(ctx).pop(false),
      onConfirm: () => Navigator.of(ctx).pop(true),
    ),
  );
  return result ?? false;
}

Future<void> showArinNotice({
  required BuildContext context,
  required String title,
  String? message,
  required String actionLabel,
  IconData? icon,
  bool barrierDismissible = true,
}) {
  return showArinPopup<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => ArinPopupCard(
      title: title,
      message: message,
      icon: icon,
      confirmLabel: actionLabel,
      tone: ArinPopupTone.accent,
      onConfirm: () => Navigator.of(ctx).pop(),
    ),
  );
}

class ArinPopupCard extends StatelessWidget {
  const ArinPopupCard({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.cancelLabel,
    this.confirmLabel,
    this.tone = ArinPopupTone.accent,
    this.onCancel,
    this.onConfirm,
    this.leading,
    this.extra,
    this.showActions = true,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? cancelLabel;
  final String? confirmLabel;
  final ArinPopupTone tone;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final Widget? leading;
  final Widget? extra;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final isDark = !ArinShellBackground.isLight(context);
    final surface = isDark ? AppColors.homeCardSurface : AppColors.creamSurface;
    final border = isDark
        ? AppColors.emeraldMid.withValues(alpha: 0.42)
        : AppColors.creamDark;
    final accent = switch (tone) {
      ArinPopupTone.accent =>
        isDark ? AppColors.accentNeonGreen : AppColors.accentGreenOnLight,
      ArinPopupTone.destructive => AppColors.error,
      ArinPopupTone.warning => const Color(0xFFE08A2C),
    };
    final titleColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final bodyColor = isDark
        ? AppColors.textOnDarkMuted
        : AppColors.textSecondary;
    final mediaQuery = MediaQuery.of(context);
    final stackActions =
        mediaQuery.size.width < 380 || mediaQuery.textScaler.scale(1) > 1.25;
    final hasCancel = cancelLabel != null && onCancel != null;
    final hasConfirm = showActions && confirmLabel != null && onConfirm != null;

    Widget cancelButton() => OutlinedButton(
      onPressed: onCancel,
      style: OutlinedButton.styleFrom(
        foregroundColor: bodyColor,
        side: BorderSide(color: border),
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.smBorderRadius,
        ),
      ),
      child: Text(
        cancelLabel!,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    Widget confirmButton() => FilledButton(
      onPressed: onConfirm,
      style: FilledButton.styleFrom(
        backgroundColor: switch (tone) {
          ArinPopupTone.accent =>
            isDark ? AppColors.emeraldMid : AppColors.emeraldDark,
          ArinPopupTone.destructive => AppColors.error,
          ArinPopupTone.warning => const Color(0xFFC56A12),
        },
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.smBorderRadius,
        ),
      ),
      child: Text(
        confirmLabel!,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadii.lgBorderRadius,
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.46 : 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(height: 18),
                        ],
                        if (icon != null) ...[
                          ExcludeSemantics(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                  alpha: isDark ? 0.14 : 0.12,
                                ),
                                borderRadius: AppRadii.smBorderRadius,
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.34),
                                ),
                              ),
                              child: Icon(icon, color: accent, size: 27),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.25,
                            ),
                          ),
                        ),
                        if (message != null && message!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            message!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: bodyColor,
                              height: 1.55,
                            ),
                          ),
                        ],
                        if (extra != null) ...[
                          const SizedBox(height: 14),
                          extra!,
                        ],
                      ],
                    ),
                  ),
                  if (hasConfirm || hasCancel) const SizedBox(height: 24),
                  if (hasConfirm && hasCancel && stackActions)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        confirmButton(),
                        const SizedBox(height: 10),
                        cancelButton(),
                      ],
                    )
                  else if (hasConfirm && hasCancel)
                    Row(
                      children: [
                        Expanded(child: cancelButton()),
                        const SizedBox(width: 10),
                        Expanded(child: confirmButton()),
                      ],
                    )
                  else if (hasConfirm)
                    SizedBox(width: double.infinity, child: confirmButton())
                  else if (hasCancel)
                    SizedBox(width: double.infinity, child: cancelButton()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
