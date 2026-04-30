// Hazırlık panelleri — örnek söz chip’leri (modern pill, hafif vurgu).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

enum CommitmentChipInsertMode {
  /// Chip metni alanı tek başına doldurur.
  replace,

  /// Mevcut metnin sonuna boşlukla ekler.
  appendWithSpace,
}

class CommitmentExampleChips extends StatelessWidget {
  const CommitmentExampleChips({
    super.key,
    required this.chips,
    required this.controller,
    required this.insertMode,
    this.sectionTitle = 'Örnekler',
    this.accentColor = AppColors.accentNeonGreen,
  });

  final Map<String, String> chips;
  final TextEditingController controller;
  final CommitmentChipInsertMode insertMode;
  final String sectionTitle;
  final Color accentColor;

  void _onChip(String key, String value) {
    HapticFeedback.selectionClick();
    switch (insertMode) {
      case CommitmentChipInsertMode.replace:
        controller.text = value;
        break;
      case CommitmentChipInsertMode.appendWithSpace:
        final cur = controller.text.trim();
        controller.text = cur.isEmpty ? value : '$cur $value';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = onDark
        ? AppColors.creamBase.withValues(alpha: 0.88)
        : AppColors.textPrimary.withValues(alpha: 0.9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: accentColor.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 6),
            Text(
              sectionTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: AppColors.creamBase.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: chips.entries.map((e) {
            return _CommitmentPillChip(
              label: e.key,
              accentColor: accentColor,
              labelColor: labelColor,
              onTap: () => _onChip(e.key, e.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CommitmentPillChip extends StatelessWidget {
  const _CommitmentPillChip({
    required this.label,
    required this.accentColor,
    required this.labelColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: accentColor.withValues(alpha: 0.14),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF101614).withValues(alpha: 0.96),
                const Color(0xFF141A18).withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(color: accentColor.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.nightlight_round,
                  size: 13,
                  color: accentColor.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.25,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
