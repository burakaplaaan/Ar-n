// Ayarlar → Hakkında: samimi metin, ARIN kabuğu ile uyumlu arka plan.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/arin_shell_background.dart';

class AboutArinPage extends StatelessWidget {
  const AboutArinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paragraphs = <String>[
      l10n.aboutArinParagraph1,
      l10n.aboutArinParagraph2,
      l10n.aboutArinParagraph3,
    ];
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        onDark ? Colors.white.withValues(alpha: 0.96) : AppColors.emeraldDark;
    final bodyColor =
        onDark ? Colors.white.withValues(alpha: 0.78) : AppColors.textPrimary;
    final muted =
        onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: ArinShellBackground.decoration(context)),
          ArinShellBackground.bubbleLayer(context),
          const Positioned.fill(child: _AboutAmbientLayer()),
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
                  l10n.settingsMenuAboutTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 280.ms, curve: Curves.easeOut),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),
                    _BookBadge(onDark: onDark)
                        .animate()
                        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
                        .scale(
                          begin: const Offset(0.92, 0.92),
                          duration: 480.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.aboutArinHeadline,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: AppColors.accentNeonGreen,
                        height: 1.2,
                      ),
                    )
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
                        .slideY(
                          begin: 0.12,
                          end: 0,
                          duration: 520.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.aboutArinSubhead,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: muted,
                        height: 1.35,
                      ),
                    )
                        .animate(delay: 140.ms)
                        .fadeIn(duration: 480.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: 28),
                    for (var i = 0; i < paragraphs.length; i++) ...[
                      Text(
                        paragraphs[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                          color: bodyColor,
                        ),
                      )
                          .animate(delay: (200 + i * 90).ms)
                          .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
                          .slideX(
                            begin: 0.03,
                            end: 0,
                            duration: 480.ms,
                            curve: Curves.easeOutCubic,
                          ),
                      if (i < paragraphs.length - 1)
                        const SizedBox(height: 18),
                    ],
                    const SizedBox(height: 36),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: onDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : AppColors.emeraldFaint.withValues(alpha: 0.35),
                          border: Border.all(
                            color: AppColors.accentNeonGreen
                                .withValues(alpha: onDark ? 0.22 : 0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 18,
                              color: AppColors.accentNeonGreen
                                  .withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.aboutArinClosingWish,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: titleColor.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate(delay: 480.ms)
                        .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
                        .scale(
                          begin: const Offset(0.96, 0.96),
                          duration: 420.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'ARIN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                          color: muted.withValues(alpha: 0.75),
                        ),
                      ),
                    )
                        .animate(delay: 560.ms)
                        .fadeIn(duration: 400.ms),
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

class _BookBadge extends StatelessWidget {
  const _BookBadge({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.emeraldFaint.withValues(alpha: 0.4),
          border: Border.all(
            color: AppColors.accentNeonGreen.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGlowGreen.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.auto_stories_rounded,
          size: 34,
          color: AppColors.accentNeonGreen.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _AboutAmbientLayer extends StatelessWidget {
  const _AboutAmbientLayer();

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    return IgnorePointer(
      child: CustomPaint(
        painter: _AboutGridPainter(isLight: light),
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0.2, -0.45),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (light ? AppColors.emeraldMid : AppColors.accentPurple)
                          .withValues(alpha: light ? 0.08 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Transform.translate(
                offset: const Offset(30, 20),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentNeonGreen.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutGridPainter extends CustomPainter {
  _AboutGridPainter({required this.isLight});

  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..strokeWidth = 0.6
      ..color = (isLight ? AppColors.emeraldDark : Colors.white)
          .withValues(alpha: isLight ? 0.05 : 0.04);

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _AboutGridPainter oldDelegate) =>
      oldDelegate.isLight != isLight;
}
