// lib/presentation/onboarding/onboarding_page.dart
// Kullanıcıyı ilk açılışta karşılayan 4 slaytlı onboarding ekranı.
// Glassmorphism arka plan, yumuşak animasyonlar ve ileri/atla butonları içerir.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

// ─── Slayt Veri Modeli ───────────────────────────────────────────────────────

class _SlideData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}

// ─── Onboarding Sayfası ──────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool get _isLastPage => _currentPage == 3;

  void _nextPage() {
    if (_isLastPage) {
      context.go(AppRoutes.onboardingSurvey);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skip() => context.go(AppRoutes.onboardingSurvey);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slides = [
      _SlideData(
        title: l10n.onboardingSlide1Title,
        subtitle: l10n.onboardingSlide1Subtitle,
        icon: Icons.wb_twilight_rounded,
        accentColor: AppColors.emeraldMid,
      ),
      _SlideData(
        title: l10n.onboardingSlide2Title,
        subtitle: l10n.onboardingSlide2Subtitle,
        icon: Icons.trending_up_rounded,
        accentColor: AppColors.emeraldDark,
      ),
      _SlideData(
        title: l10n.onboardingSlide3Title,
        subtitle: l10n.onboardingSlide3Subtitle,
        icon: Icons.schedule_rounded,
        accentColor: AppColors.anthraciteLight,
      ),
      _SlideData(
        title: l10n.onboardingSlide4Title,
        subtitle: l10n.onboardingSlide4Subtitle,
        icon: Icons.layers_rounded,
        accentColor: AppColors.emeraldMid,
      ),
    ];
    final isLastPage = _currentPage == slides.length - 1;
    return Scaffold(
      body: Stack(
        children: [
          // ── Degrade Arka Plan ────────────────────────────────────────
          _GradientBackground(pageIndex: _currentPage),

          // ── Slaytlar ────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: slides.length,
            itemBuilder: (context, i) =>
                _SlideContent(data: slides[i], isActive: _currentPage == i),
          ),

          // ── Üst: Atla butonu ─────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: AnimatedOpacity(
              opacity: isLastPage ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  l10n.onboardingSkip,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
              ),
            ),
          ),

          // ── Alt: Nokta göstergesi + İleri butonu ─────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 28,
            right: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nokta Göstergesi
                Row(
                  children: List.generate(
                    slides.length,
                    (i) => _DotIndicator(isActive: i == _currentPage),
                  ),
                ),

                // İleri / Başlayalım Butonu
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: FilledButton(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.creamBase,
                      foregroundColor: AppColors.emeraldDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      isLastPage
                          ? l10n.onboardingGetStarted
                          : l10n.onboardingNext,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.emeraldDark,
                      ),
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

// ─── Degrade Arka Plan ───────────────────────────────────────────────────────

class _GradientBackground extends StatelessWidget {
  final int pageIndex;

  const _GradientBackground({required this.pageIndex});

  static const _gradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B4D3E), Color(0xFF2D7A5F), Color(0xFF1A1F1C)],
    ),
    LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF1A1F1C), Color(0xFF1B4D3E), Color(0xFF242B26)],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF242B26), Color(0xFF1B4D3E), Color(0xFF1A1F1C)],
    ),
    LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [Color(0xFF1B4D3E), Color(0xFF2A5C4A), Color(0xFF1A1F1C)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(gradient: _gradients[pageIndex]),
    );
  }
}

// ─── Slayt İçerik Alanı ─────────────────────────────────────────────────────

class _SlideContent extends StatelessWidget {
  final _SlideData data;
  final bool isActive;

  const _SlideContent({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon cam kabı
          GlassContainer(
            style: GlassPresets.prayerCard,
            padding: const EdgeInsets.all(32),
            child: Icon(data.icon, size: 72, color: AppColors.creamBase),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms, delay: 100.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

          const SizedBox(height: 48),

          // Başlık
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.textOnDark,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Alt başlık
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textOnDarkMuted,
              height: 1.65,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms, delay: 320.ms)
              .slideY(begin: 0.15, end: 0),
        ],
      ),
    );
  }
}

// ─── Nokta Göstergesi ────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final bool isActive;

  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.creamBase
            : AppColors.creamBase.withAlpha(77),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
