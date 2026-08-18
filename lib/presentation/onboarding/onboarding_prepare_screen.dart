import 'dart:async';

import 'package:flutter/material.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../shared/widgets/arin_pressable.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';

enum OnboardingPrepareQuestion { lock, verses, shortcuts }

class OnboardingPrepareScreen extends StatefulWidget {
  const OnboardingPrepareScreen({
    required this.name,
    required this.onContinue,
    required this.onRequestAtt,
    required this.onAnswer,
    this.onReady,
    this.startAsReady = false,
    this.barFill = const Duration(milliseconds: 1400),
    super.key,
  });

  final String name;
  final VoidCallback onContinue;
  final Future<void> Function() onRequestAtt;
  final void Function(OnboardingPrepareQuestion question, bool yes) onAnswer;
  final VoidCallback? onReady;
  final bool startAsReady;
  final Duration barFill;

  @override
  State<OnboardingPrepareScreen> createState() =>
      _OnboardingPrepareScreenState();
}

class _OnboardingPrepareScreenState extends State<OnboardingPrepareScreen>
    with TickerProviderStateMixin {
  final List<double> _progress = [0, 0, 0, 0];
  OnboardingPrepareQuestion? _question;
  Completer<bool>? _questionWait;
  AnimationController? _fill;
  bool _ready = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    if (widget.startAsReady) {
      _progress
        ..[0] = 1
        ..[1] = 1
        ..[2] = 1
        ..[3] = 1;
      _ready = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_run());
      });
    }
  }

  @override
  void dispose() {
    _fill?.dispose();
    final wait = _questionWait;
    _questionWait = null;
    if (wait != null && !wait.isCompleted) wait.complete(false);
    super.dispose();
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    await _fillBar(0, 1);
    await _fillBar(1, 0.82);
    final lockYes = await _ask(OnboardingPrepareQuestion.lock);
    if (!mounted) return;
    widget.onAnswer(OnboardingPrepareQuestion.lock, lockYes);
    await _fillBar(1, 1);
    await _fillBar(2, 0.36);
    if (!mounted) return;
    await widget.onRequestAtt();
    if (!mounted) return;
    final verseYes = await _ask(OnboardingPrepareQuestion.verses);
    if (!mounted) return;
    widget.onAnswer(OnboardingPrepareQuestion.verses, verseYes);
    await _fillBar(2, 1);
    await _fillBar(3, 0.88);
    final shortcutYes = await _ask(OnboardingPrepareQuestion.shortcuts);
    if (!mounted) return;
    widget.onAnswer(OnboardingPrepareQuestion.shortcuts, shortcutYes);
    await _fillBar(3, 1);
    if (!mounted) return;
    setState(() => _ready = true);
    widget.onReady?.call();
  }

  Future<void> _fillBar(int index, double target) async {
    if (!mounted) return;
    _fill?.dispose();
    final start = _progress[index];
    if (target <= start + 0.001) {
      setState(() => _progress[index] = target);
      return;
    }
    final ms = (widget.barFill.inMilliseconds * (target - start))
        .round()
        .clamp(220, widget.barFill.inMilliseconds);
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    _fill = controller;
    final ticker = controller.drive(CurveTween(curve: Curves.easeInOutCubic));
    void listener() {
      if (!mounted) return;
      setState(() => _progress[index] = start + ((target - start) * ticker.value));
    }

    controller.addListener(listener);
    await controller.forward();
    controller.removeListener(listener);
    if (mounted) setState(() => _progress[index] = target);
  }

  Future<bool> _ask(OnboardingPrepareQuestion question) {
    if (!mounted) return Future<bool>.value(false);
    final wait = Completer<bool>();
    _questionWait = wait;
    setState(() => _question = question);
    return wait.future;
  }

  void _resolveQuestion(bool yes) {
    final wait = _questionWait;
    _questionWait = null;
    setState(() => _question = null);
    if (wait != null && !wait.isCompleted) wait.complete(yes);
  }

  String _questionText(AppLocalizations l10n) {
    switch (_question) {
      case OnboardingPrepareQuestion.lock:
        return l10n.onboardingPrepareAskLock;
      case OnboardingPrepareQuestion.verses:
        return l10n.onboardingPrepareAskVerses;
      case OnboardingPrepareQuestion.shortcuts:
        return l10n.onboardingPrepareAskShortcuts;
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bars = [
      (
        l10n.onboardingPrepareBar1Title(widget.name),
        l10n.onboardingPrepareBar1Body,
        Icons.menu_book_rounded,
      ),
      (
        l10n.onboardingPrepareBar2Title,
        l10n.onboardingPrepareBar2Body,
        Icons.lock_rounded,
      ),
      (
        l10n.onboardingPrepareBar3Title,
        l10n.onboardingPrepareBar3Body,
        Icons.public_rounded,
      ),
      (
        l10n.onboardingPrepareBar4Title,
        l10n.onboardingPrepareBar4Body,
        Icons.apps_rounded,
      ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        const OnboardingEntryBackdrop(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            child: Column(
              children: [
                Text(
                  _ready
                      ? l10n.onboardingPrepareReadyTitle
                      : l10n.onboardingPrepareTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _ready
                      ? l10n.onboardingPrepareReadySubtitle
                      : l10n.onboardingPrepareSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.56),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: bars.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      return _PrepareBarCard(
                        title: bars[i].$1,
                        body: bars[i].$2,
                        icon: bars[i].$3,
                        progress: _progress[i],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (_ready) ...[
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.ornamentGold,
                    size: 36,
                  ),
                  const SizedBox(height: 14),
                  OnboardingCtaButton(
                    label: '${l10n.onboardingContinue}  →',
                    onPressed: widget.onContinue,
                  ),
                ] else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.ornamentGold.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.onboardingPrepareStatus,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (_question != null)
          _PrepareQuestionOverlay(
            question: _questionText(l10n),
            yesLabel: l10n.onboardingPrepareYes,
            noLabel: l10n.onboardingPrepareNo,
            onYes: () => _resolveQuestion(true),
            onNo: () => _resolveQuestion(false),
          ),
      ],
    );
  }
}

class _PrepareBarCard extends StatelessWidget {
  const _PrepareBarCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.progress,
  });

  final String title;
  final String body;
  final IconData icon;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final done = progress >= 0.999;
    final pct = (progress * 100).round();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? const Color(0xFF2E7D4F)
                        : AppColors.emeraldMid.withValues(alpha: 0.42),
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        body,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.52),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$pct%',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                color: done ? const Color(0xFF2E7D4F) : AppColors.emeraldLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrepareQuestionOverlay extends StatelessWidget {
  const _PrepareQuestionOverlay({
    required this.question,
    required this.yesLabel,
    required this.noLabel,
    required this.onYes,
    required this.onNo,
  });

  final String question;
  final String yesLabel;
  final String noLabel;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0C1410),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.ornamentGold.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emeraldMid.withValues(alpha: 0.5),
                    ),
                    child: const Text(
                      '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 20,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ArinPressable(
                          onTap: onNo,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            child: SizedBox(
                              height: 48,
                              child: Center(
                                child: Text(
                                  noLabel,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ArinPressable(
                          onTap: onYes,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.emeraldLight,
                            ),
                            child: SizedBox(
                              height: 48,
                              child: Center(
                                child: Text(
                                  yesLabel,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
