import 'package:flutter/material.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';

class OnboardingVerseHoldScreen extends StatefulWidget {
  const OnboardingVerseHoldScreen({
    required this.name,
    required this.onBack,
    required this.onFinished,
    this.progress = 0.76,
    this.hold = const Duration(seconds: 5),
    this.verseArabic,
    this.verseTranslation,
    this.verseSource,
    this.footer,
    this.showFooter = true,
    super.key,
  });

  final String name;
  final VoidCallback onBack;
  final VoidCallback onFinished;
  final double progress;
  final Duration hold;
  final String? verseArabic;
  final String? verseTranslation;
  final String? verseSource;
  final String? footer;
  final bool showFooter;

  @override
  State<OnboardingVerseHoldScreen> createState() =>
      _OnboardingVerseHoldScreenState();
}

class _OnboardingVerseHoldScreenState extends State<OnboardingVerseHoldScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bar;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _bar = AnimationController(vsync: this, duration: widget.hold)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        const OnboardingEntryBackdrop(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
            child: Column(
              children: [
                OnboardingFlowTopBar(
                  progress: widget.progress,
                  onBack: widget.onBack,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '“',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 56,
                          height: 0.8,
                          color: AppColors.ornamentGold.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.verseArabic ?? l10n.onboardingHoldVerseArabic,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.ornamentGold,
                          fontSize: 22,
                          height: 1.7,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.verseTranslation ??
                            l10n.onboardingHoldVerseTranslation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 20,
                          height: 1.45,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (widget.verseSource ?? l10n.onboardingHoldVerseSource)
                            .toUpperCase(),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.ornamentGold.withValues(alpha: 0.86),
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showFooter) ...[
                  Text(
                    widget.footer ?? l10n.onboardingHoldFooter(widget.name),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                AnimatedBuilder(
                  animation: _bar,
                  builder: (context, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _bar.value,
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        color: AppColors.ornamentGold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
