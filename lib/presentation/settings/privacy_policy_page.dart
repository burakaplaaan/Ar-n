import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/arin_shell_background.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        onDark ? Colors.white.withValues(alpha: 0.96) : AppColors.emeraldDark;
    final bodyColor =
        onDark ? Colors.white.withValues(alpha: 0.85) : AppColors.textPrimary;
    final muted =
        onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    final cardBg = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.74);
    final border = onDark
        ? Colors.white.withValues(alpha: 0.09)
        : AppColors.creamDark.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: ArinShellBackground.decoration(context)),
          ArinShellBackground.bubbleLayer(context),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: onDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.55),
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: titleColor.withValues(alpha: 0.9),
                  ),
                ),
                title: Text(
                  l10n.settingsPrivacyPageTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.settingsPrivacyLastUpdated,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.settingsPrivacyIntro,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              height: 1.45,
                              color: bodyColor,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _PolicySection(
                            title: l10n.settingsPrivacyDataCollectedTitle,
                            body: l10n.settingsPrivacyDataCollectedBody,
                            titleColor: titleColor,
                            bodyColor: bodyColor,
                          ),
                          _PolicySection(
                            title: l10n.settingsPrivacyUsageTitle,
                            body: l10n.settingsPrivacyUsageBody,
                            titleColor: titleColor,
                            bodyColor: bodyColor,
                          ),
                          _PolicySection(
                            title: l10n.settingsPrivacyStorageTitle,
                            body: l10n.settingsPrivacyStorageBody,
                            titleColor: titleColor,
                            bodyColor: bodyColor,
                          ),
                          _PolicySection(
                            title: l10n.settingsPrivacyThirdPartyTitle,
                            body: l10n.settingsPrivacyThirdPartyBody,
                            titleColor: titleColor,
                            bodyColor: bodyColor,
                          ),
                          _PolicySection(
                            title: l10n.settingsPrivacyControlsTitle,
                            body: l10n.settingsPrivacyControlsBody,
                            titleColor: titleColor,
                            bodyColor: bodyColor,
                          ),
                          _PolicySection(
                            title: l10n.settingsPrivacyChildrenTitle,
                            body: l10n.settingsPrivacyChildrenBody,
                            titleColor: titleColor,
                            bodyColor: bodyColor,
                          ),
                          _PolicySection(
                            title: l10n.settingsPrivacyContactTitle,
                            body: l10n.settingsPrivacyContactBody,
                            titleColor: titleColor,
                            bodyColor: bodyColor,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.body,
    required this.titleColor,
    required this.bodyColor,
    this.isLast = false,
  });

  final String title;
  final String body;
  final Color titleColor;
  final Color bodyColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.45,
              color: bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}
