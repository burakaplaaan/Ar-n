// Ayarlar → Bildirimler → Vakit ve ses: mevcut [NamazAdhanReminderCard] tek kaynak.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/arin_shell_background.dart';
import '../shared/widgets/arin_shell_layout.dart';
import '../willpower/widgets/namaz_adhan_reminder_card.dart';

class PrayerNotificationsDetailPage extends ConsumerWidget {
  const PrayerNotificationsDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        onDark ? Colors.white.withValues(alpha: 0.96) : AppColors.emeraldDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: ArinShellBackground.decoration(context)),
          ArinShellBackground.bubbleLayer(context),
          const Positioned.fill(child: _PrayerNtfAmbientLayer()),
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
                    color: titleColor.withValues(alpha: 0.88),
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.notificationsPrayerDetailTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ).animate().fadeIn(duration: 280.ms, curve: Curves.easeOut),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  ArinShellLayout.bottomContentPadding(context),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      l10n.notificationsPrayerDetailSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: onDark
                            ? AppColors.textOnDarkMuted
                            : AppColors.textSecondary,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 40.ms, duration: 400.ms),
                    const SizedBox(height: 18),
                    const NamazAdhanReminderCard()
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 450.ms)
                        .slideY(
                          begin: 0.04,
                          end: 0,
                          delay: 100.ms,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
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

class _PrayerNtfAmbientLayer extends StatelessWidget {
  const _PrayerNtfAmbientLayer();

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(-0.35, -0.35),
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.accentNeonGreen.withValues(alpha: light ? 0.06 : 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
