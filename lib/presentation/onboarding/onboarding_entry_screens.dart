// İlk açılış: karşılama + kilit ekranı tanıtımı.
// Düzen rakip akışa yakın; renk, yazı ve zemin Arın teması.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/app_locale_provider.dart';
import '../../core/theme/arin_shell_background.dart';
import '../shared/widgets/arin_pressable.dart';
import 'onboarding_flow_chrome.dart';

const String _kAppIconAsset = 'assets/branding/app_icon_1024.png';

class OnboardingLandingScreen extends StatelessWidget {
  const OnboardingLandingScreen({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        const OnboardingEntryBackdrop(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
            child: Column(
              children: [
                const Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: OnboardingLanguageButton(),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _ArinAppLogo(size: 96)
                          .animate()
                          .fadeIn(duration: 640.ms)
                          .scale(
                            begin: const Offset(0.88, 0.88),
                            end: const Offset(1, 1),
                          ),
                      const SizedBox(height: 18),
                      const _ArinWordmark(size: 58)
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 560.ms),
                      const SizedBox(height: 28),
                      _GlowCtaButton(
                        label: l10n.onboardingStart,
                        onPressed: onStart,
                      ).animate().fadeIn(delay: 160.ms, duration: 480.ms),
                      const SizedBox(height: 28),
                      _LandingVerse(
                        arabic: l10n.onboardingLandingVerseArabic,
                        translation: l10n.onboardingLandingVerseTranslation,
                        source: l10n.onboardingLandingVerseSource,
                      ).animate().fadeIn(delay: 240.ms, duration: 560.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        const OnboardingEntryBackdrop(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              children: [
                const Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: OnboardingLanguageButton(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final lockHeight = (constraints.maxHeight * 0.58).clamp(
                        300.0,
                        460.0,
                      );
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _LockScreenPreview(
                              height: lockHeight,
                              verseArabic:
                                  l10n.onboardingWelcomeWidgetVerseArabic,
                              verseTranslation:
                                  l10n.onboardingWelcomeWidgetVerseTranslation,
                              verseSource:
                                  l10n.onboardingWelcomeWidgetVerseSource,
                            )
                                .animate()
                                .fadeIn(duration: 520.ms)
                                .slideY(begin: 0.05, end: 0),
                            const SizedBox(height: 22),
                            const _ArinAppLogo(size: 64)
                                .animate()
                                .fadeIn(delay: 80.ms, duration: 420.ms),
                            const SizedBox(height: 10),
                            const _ArinWordmark(size: 36)
                                .animate()
                                .fadeIn(delay: 110.ms, duration: 420.ms),
                            const SizedBox(height: 12),
                            Text(
                              l10n.onboardingWelcomeTitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.displayMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 32,
                                height: 1.15,
                              ),
                            ).animate().fadeIn(delay: 140.ms, duration: 480.ms),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                l10n.onboardingWelcomeBody,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  height: 1.45,
                                ),
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 480.ms),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                OnboardingCtaButton(
                  label: '${l10n.onboardingGetStarted}  →',
                  onPressed: onContinue,
                ).animate().fadeIn(delay: 240.ms, duration: 420.ms),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingLanguageButton extends ConsumerWidget {
  const OnboardingLanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ArinPressable(
      scale: 0.9,
      sink: 1.8,
      onTap: () => unawaited(_openLanguageSheet(context, ref)),
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        shape: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.language_rounded,
            color: Colors.white.withValues(alpha: 0.92),
            size: 22,
            semanticLabel: l10n.onboardingLanguagePickerTitle,
          ),
        ),
      ),
    );
  }

  Future<void> _openLanguageSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(appLocaleProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.homeCardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onboardingLanguagePickerTitle,
                  style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 14),
                for (final locale in kSupportedAppLocales)
                  _LanguageTile(
                    locale: locale,
                    selected: current.languageCode == locale.languageCode,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      if (current.languageCode == locale.languageCode) return;
                      await ref
                          .read(appLocaleProvider.notifier)
                          .setLocale(locale);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final Locale locale;
  final bool selected;
  final VoidCallback onTap;

  String get _native {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'Türkçe';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: selected
            ? AppColors.emeraldMid.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.04),
        title: Text(
          _native,
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: AppColors.accentNeonGreen)
            : null,
      ),
    );
  }
}

class OnboardingEntryBackdrop extends StatelessWidget {
  const OnboardingEntryBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ArinShellBackground.backdropLayer(context),
        const IgnorePointer(child: CustomPaint(painter: _AmbientGlowPainter())),
      ],
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  const _AmbientGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.38);
    canvas.drawCircle(
      center,
      size.shortestSide * 0.42,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.emeraldLight.withValues(alpha: 0.22),
            AppColors.emeraldMid.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.42)),
    );

    final orbs = <(Offset, double, Color)>[
      (
        Offset(size.width * 0.18, size.height * 0.22),
        46,
        AppColors.ornamentGold.withValues(alpha: 0.07),
      ),
      (
        Offset(size.width * 0.84, size.height * 0.30),
        34,
        AppColors.emeraldLight.withValues(alpha: 0.10),
      ),
      (
        Offset(size.width * 0.72, size.height * 0.16),
        18,
        Colors.white.withValues(alpha: 0.05),
      ),
      (
        Offset(size.width * 0.28, size.height * 0.58),
        28,
        AppColors.emeraldMid.withValues(alpha: 0.08),
      ),
    ];
    for (final orb in orbs) {
      canvas.drawCircle(orb.$1, orb.$2, Paint()..color = orb.$3);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArinAppLogo extends StatelessWidget {
  const _ArinAppLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldLight.withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(_kAppIconAsset, fit: BoxFit.cover),
    );
  }
}

class _ArinWordmark extends StatelessWidget {
  const _ArinWordmark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Arın',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppTextStyles.primaryFontFamily,
        fontWeight: FontWeight.w200,
        fontSize: size,
        height: 1,
        letterSpacing: 1.4,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.white.withValues(alpha: 0.24),
            blurRadius: 20,
          ),
          Shadow(
            color: AppColors.emeraldLight.withValues(alpha: 0.36),
            blurRadius: 32,
          ),
        ],
      ),
    );
  }
}

class _GlowCtaButton extends StatelessWidget {
  const _GlowCtaButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OnboardingCtaButton(
      label: '$label  →',
      expand: false,
      onPressed: onPressed,
    );
  }
}

class _LandingVerse extends StatelessWidget {
  const _LandingVerse({
    required this.arabic,
    required this.translation,
    required this.source,
  });

  final String arabic;
  final String translation;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          arabic,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.ornamentGold,
            fontSize: 24,
            height: 1.65,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: AppColors.ornamentGold.withValues(alpha: 0.28),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          translation,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.45,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          source,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.3,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _LockScreenPreview extends StatelessWidget {
  const _LockScreenPreview({
    required this.height,
    required this.verseArabic,
    required this.verseTranslation,
    required this.verseSource,
  });

  final double height;
  final String verseArabic;
  final String verseTranslation;
  final String verseSource;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(now),
      alwaysUse24HourFormat: true,
    );
    final date = MaterialLocalizations.of(context).formatFullDate(now);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101A16), Color(0xFF0A100D), Color(0xFF070B09)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              left: 40,
              right: 40,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emeraldMid.withValues(alpha: 0.16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    time,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 58,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _LockVerseWidget(
                    verseArabic: verseArabic,
                    verseTranslation: verseTranslation,
                    verseSource: verseSource,
                  ),
                  const Spacer(),
                  Container(
                    width: 108,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockVerseWidget extends StatelessWidget {
  const _LockVerseWidget({
    required this.verseArabic,
    required this.verseTranslation,
    required this.verseSource,
  });

  final String verseArabic;
  final String verseTranslation;
  final String verseSource;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verseSource,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.emeraldLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  verseTranslation,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 84,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white.withValues(alpha: 0.12),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  verseSource,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.emeraldLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  verseArabic,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.94),
                    height: 1.55,
                    fontSize: 15,
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
