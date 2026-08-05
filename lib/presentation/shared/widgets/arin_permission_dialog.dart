import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_text_styles.dart';

/// Shows an ARIN-branded explanation before handing control to an OS
/// permission screen. Native Android/iOS permission dialogs themselves
/// cannot be styled by the application.
Future<bool> showArinPermissionDialog({
  required BuildContext context,
  required String title,
  required String body,
  required IconData icon,
  required String cancelLabel,
  required String confirmLabel,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => ArinPermissionDialog(
      title: title,
      body: body,
      icon: icon,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
    ),
  );
  return result ?? false;
}

class ArinPermissionDialog extends StatelessWidget {
  const ArinPermissionDialog({
    required this.title,
    required this.body,
    required this.icon,
    required this.cancelLabel,
    required this.confirmLabel,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;
  final String cancelLabel;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.homeCardSurface : AppColors.creamSurface;
    final border = isDark
        ? AppColors.emeraldMid.withValues(alpha: 0.42)
        : AppColors.creamDark;
    final accent = isDark
        ? AppColors.accentNeonGreen
        : AppColors.accentGreenOnLight;
    final titleColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final bodyColor = isDark
        ? AppColors.textOnDarkMuted
        : AppColors.textSecondary;
    final mediaQuery = MediaQuery.of(context);
    final stackActions =
        mediaQuery.size.width < 380 || mediaQuery.textScaler.scale(1) > 1.25;

    Widget cancelButton() => OutlinedButton(
      onPressed: () => Navigator.of(context).pop(false),
      style: OutlinedButton.styleFrom(
        foregroundColor: bodyColor,
        side: BorderSide(color: border),
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.smBorderRadius,
        ),
      ),
      child: Text(
        cancelLabel,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    Widget confirmButton() => FilledButton(
      onPressed: () => Navigator.of(context).pop(true),
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? AppColors.emeraldMid : AppColors.emeraldDark,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.smBorderRadius,
        ),
      ),
      child: Text(
        confirmLabel,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 10),
                      Text(
                        body,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: bodyColor,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (stackActions)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    confirmButton(),
                    const SizedBox(height: 10),
                    cancelButton(),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: cancelButton()),
                    const SizedBox(width: 10),
                    Expanded(child: confirmButton()),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
