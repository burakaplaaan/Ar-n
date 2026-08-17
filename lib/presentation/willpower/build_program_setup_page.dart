import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/router/app_router.dart';
import '../../data/models/habit_model.dart';
import '../shared/providers/habit_providers.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';

/// Şablon kurulumu — şu an yalnızca quran_daily tam akışlı.
/// Tasarım: gradient arkaplan + kitap kaligrafi, hero ikon halkası,
/// açıklama kartı + güçlü CTA. Daha önce düz anthracite zemin + kısa
/// paragraf + düz button vardı; aynı bilgiyi verirken "programa başlıyorum"
/// momentumunu görsel olarak destekliyoruz.
class BuildProgramSetupPage extends ConsumerWidget {
  const BuildProgramSetupPage({super.key, required this.templateId});

  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isQuran = templateId == WillpowerTemplates.quranDaily;
    final title = isQuran
        ? l10n.buildProgramSetupQuranTitle
        : l10n.buildProgramSetupDefaultTitle;
    const accent = Color(0xFFC9A962);

    return Scaffold(
      backgroundColor: AppColors.anthraciteDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Zengin arka plan: diagonal gradient + halo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF141826),
                  Color(0xFF0F1418),
                  Color(0xFF1A1F1C),
                ],
              ),
            ),
          ),
          // Arapça kaligrafi fısıltısı (Kitap anlamına "kitâb").
          if (isQuran)
            Positioned(
              top: -20,
              right: -30,
              child: Text(
                'كِتَاب',
                style: GoogleFonts.scheherazadeNew(
                  fontSize: 220,
                  color: accent.withValues(alpha: 0.055),
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ).animate().fadeIn(duration: 1200.ms),
            ),
          // Soft halo.
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withValues(alpha: 0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 14, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.creamBase,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.creamBase,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        // Hero ikon halkası.
                        Center(
                          child:
                              Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          accent.withValues(alpha: 0.22),
                                          accent.withValues(alpha: 0.04),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.42),
                                        width: 1.3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(alpha: 0.18),
                                          blurRadius: 28,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isQuran
                                          ? Icons.menu_book_rounded
                                          : Icons.auto_stories_outlined,
                                      size: 52,
                                      color: accent,
                                    ),
                                  )
                                  .animate()
                                  .scale(
                                    begin: const Offset(0.7, 0.7),
                                    duration: 520.ms,
                                    curve: Curves.elasticOut,
                                  )
                                  .fadeIn(duration: 420.ms),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          isQuran
                              ? l10n.buildProgramSetupHeadlineQuran
                              : l10n.buildProgramSetupHeadlineDefault,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.creamBase,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
                        const SizedBox(height: 10),
                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: accent.withValues(alpha: 0.12),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.32),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 14,
                                    color: accent.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.buildProgramSetupBadge,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.creamBase.withValues(
                                        alpha: 0.88,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Text(
                          isQuran
                              ? l10n.buildProgramSetupBodyQuran
                              : l10n.buildProgramSetupBodyDefault,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textOnDarkMuted,
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ).animate().fadeIn(delay: 260.ms, duration: 420.ms),
                        const SizedBox(height: 26),
                        // Vurgu kartı — süreklilik prensibi.
                        if (isQuran)
                          const _PrincipleCard(accent: accent)
                              .animate()
                              .fadeIn(delay: 340.ms, duration: 420.ms)
                              .slideY(
                                begin: 0.15,
                                end: 0,
                                duration: 460.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () async {
                            if (!isQuran) {
                              if (context.mounted) context.pop();
                              return;
                            }
                            final repo = ref.read(habitRepositoryProvider);
                            final existing = repo.findActiveByTemplateId(
                              WillpowerTemplates.quranDaily,
                            );
                            if (existing != null) {
                              if (context.mounted) {
                                showArinTopToast(context, l10n.buildProgramSetupAlreadyActive);
                                context.go(
                                  AppRoutes.willBuildDetail(existing.id),
                                );
                              }
                              return;
                            }
                            final h = await ref
                                .read(habitSummaryProvider.notifier)
                                .createFromTemplate(
                                  templateId: WillpowerTemplates.quranDaily,
                                  title: l10n.buildProgramSetupQuranHabitTitle,
                                  type: HabitType.good,
                                  emoji: '📖',
                                );
                            if (context.mounted) {
                              context.go(AppRoutes.willBuildDetail(h.id));
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: AppColors.anthraciteDark,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                          label: Text(l10n.buildProgramSetupStartAction),
                        ).animate().fadeIn(delay: 420.ms, duration: 380.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrincipleCard extends StatelessWidget {
  const _PrincipleCard({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: accent.withValues(alpha: 0.9),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.buildProgramSetupPrincipleTitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.creamBase,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.buildProgramSetupPrincipleQuote,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textOnDarkMuted,
                    fontSize: 12.5,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
