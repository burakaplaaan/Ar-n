// Günlük namaz — dikkat, kendine söz, mühür (bırakma programlarıyla aynı ritim).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/willpower/quit_commitment_chips.dart';
import '../shared/providers/habit_providers.dart';
import '../shared/widgets/arin_shell_layout.dart';
import '../shared/widgets/commitment_seal_widget.dart';
import 'salat_tracking_visibility_provider.dart';
import 'widgets/commitment_example_chips.dart';
import 'widgets/commitment_input_tokens.dart';

class NamazIbadetOnboarding extends ConsumerStatefulWidget {
  const NamazIbadetOnboarding({
    super.key,
    required this.habitId,
    required this.onClose,
  });

  final String habitId;
  final VoidCallback onClose;

  @override
  ConsumerState<NamazIbadetOnboarding> createState() =>
      _NamazIbadetOnboardingState();
}

class _NamazIbadetOnboardingState extends ConsumerState<NamazIbadetOnboarding> {
  final PageController _page = PageController();
  final TextEditingController _commitment = TextEditingController();
  int _pageIndex = 0;
  bool _completed = false;
  bool _closing = false;

  double _shellBottomReserve(BuildContext context) {
    return ArinShellLayout.bottomContentPadding(context);
  }

  double _actionBottomInset(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return (bottom + 10).clamp(10, 26).toDouble();
  }

  int _segmentFilled() {
    if (_pageIndex >= 2) return 3;
    return (_pageIndex + 1).clamp(1, 3);
  }

  Future<void> _next() async {
    final l10n = AppLocalizations.of(context)!;
    if (_pageIndex == 1) {
      final t = _commitment.text.trim();
      if (t.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.namazIbadetCommitmentTooShort,
              style: TextStyle(
                color: AppColors.creamBase.withValues(alpha: 0.92),
              ),
            ),
            backgroundColor: AppColors.anthraciteMid,
          ),
        );
        return;
      }
    }
    await _page.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _back() async {
    if (_pageIndex == 0) {
      _closeIncomplete();
      return;
    }
    await _page.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _closeIncomplete() {
    if (_closing || _completed) return;
    _closing = true;
    widget.onClose();
  }

  @override
  void dispose() {
    _page.dispose();
    _commitment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_pageIndex > 0) {
          unawaited(_back());
          return;
        }
        _closeIncomplete();
      },
      child: Scaffold(
        backgroundColor: AppColors.anthraciteDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.creamBase,
            ),
            onPressed: _back,
          ),
          title: Text(
            l10n.namazIbadetPrepTitle,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.creamBase,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: List.generate(3, (i) {
                  final filled = i < _segmentFilled();
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: filled
                              ? AppColors.accentNeonGreen
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _pageIndex = i),
                children: [
                  _NamazWarningPage(),
                  _NamazCommitmentPage(
                    controller: _commitment,
                    chips: namazIbadetCommitmentChipsFor(
                      localeCode: Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: _shellBottomReserve(context),
                    ),
                    child: CommitmentSealWidget(
                      displayNameSuffix: '',
                      titlePrefix: l10n.namazIbadetSealTitlePrefix,
                      infoBannerText: _commitment.text.trim().length > 120
                          ? '${_commitment.text.trim().substring(0, 120)}…'
                          : _commitment.text.trim(),
                      accentColor: AppColors.accentNeonGreen,
                      progressTrackColor: Colors.white.withValues(alpha: 0.12),
                      showSkip: false,
                      holdHint: l10n.namazIbadetSealHoldHint,
                      successMessage: l10n.namazIbadetSealSuccess,
                      encourageWhileNotHolding:
                          l10n.namazIbadetSealEncourageNotHolding,
                      encourageWhileHolding:
                          l10n.namazIbadetSealEncourageHolding,
                      onCompleted: () async {
                        await ref
                            .read(habitSummaryProvider.notifier)
                            .completeQuitOnboarding(
                              habitId: widget.habitId,
                              commitmentText: _commitment.text.trim(),
                            );
                        await ref
                            .read(salatTrackingVisibleOnHomeProvider.notifier)
                            .enableFromGelisim();
                        _completed = true;
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_pageIndex < 2)
              SafeArea(
                top: false,
                minimum: EdgeInsets.fromLTRB(
                  14,
                  8,
                  14,
                  _actionBottomInset(context),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _back,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: AppColors.creamBase,
                        ),
                        label: Text(
                          l10n.surveyBack,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.creamBase,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentNeonGreen,
                          foregroundColor: AppColors.anthraciteDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        label: Text(l10n.surveyNext),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NamazWarningPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final icon = Icon(
      Icons.warning_amber_rounded,
      size: 56,
      color: AppColors.accentNeonGreen.withValues(alpha: 0.9),
    );
    final bullets = [
      l10n.namazIbadetWarningBullet1,
      l10n.namazIbadetWarningBullet2,
      l10n.namazIbadetWarningBullet3,
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        Center(child: icon.animate().shake(hz: 2, duration: 400.ms)),
        const SizedBox(height: 20),
        Text(
          l10n.namazIbadetWarningTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.creamBase,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.namazIbadetWarningSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
        const SizedBox(height: 24),
        ...bullets.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '• ${e.value}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.creamBase.withValues(alpha: 0.9),
                height: 1.45,
              ),
            ).animate().fadeIn(delay: (80 * e.key).ms),
          ),
        ),
      ],
    );
  }
}

class _NamazCommitmentPage extends StatelessWidget {
  const _NamazCommitmentPage({required this.controller, required this.chips});

  final TextEditingController controller;
  final Map<String, String> chips;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: AppColors.accentNeonGreen.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.namazIbadetCommitmentTitle,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.creamBase,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.namazIbadetCommitmentHint,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDarkMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            cursorColor: AppColors.accentNeonGreen,
            style: commitmentInputTextStyle(color: AppColors.creamBase),
            decoration: InputDecoration(
              hintText: l10n.namazIbadetCommitmentFieldHint,
              hintStyle: commitmentInputHintStyle(),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        CommitmentExampleChips(
          chips: chips,
          controller: controller,
          insertMode: CommitmentChipInsertMode.replace,
          sectionTitle: l10n.namazIbadetExamplesTitle,
          accentColor: AppColors.accentNeonGreen,
        ),
      ],
    );
  }
}
