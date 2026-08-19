import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/arin_shell_background.dart';
import 'assistant_hilal_mark.dart';

class AssistantHomeBubble extends StatelessWidget {
  const AssistantHomeBubble({super.key, this.compact = false});

  /// Kenara çekilince yalnızca hilal kalsın.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final onDark = !ArinShellBackground.isLight(context);
    final l10n = AppLocalizations.of(context)!;
    const bronze = Color(0xFFC59B6D);
    final mark = onDark ? bronze : const Color(0xFF8B5E3C);
    final fill = onDark ? const Color(0xFF122018) : AppColors.creamSurface;
    final ring = Color.lerp(
      onDark ? AppColors.accentNeonGreen : AppColors.accentGreenOnLight,
      bronze,
      0.55,
    )!.withValues(alpha: 0.5);
    final text = onDark ? Colors.white.withValues(alpha: 0.94) : AppColors.emeraldDark;
    final glow = bronze.withValues(alpha: onDark ? 0.28 : 0.18);

    return Semantics(
      button: true,
      label: l10n.assistantTitle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: fill.withValues(alpha: onDark ? 0.94 : 0.97),
          border: Border.all(color: ring, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: glow,
              blurRadius: 14,
              spreadRadius: -2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.center,
          child: Padding(
            padding: compact
                ? const EdgeInsets.all(10)
                : const EdgeInsets.fromLTRB(12, 9, 14, 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AssistantHilalMark(size: 20, color: mark),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Text(
                    l10n.assistantAskChip,
                    style: GoogleFonts.plusJakartaSans(
                      color: text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
