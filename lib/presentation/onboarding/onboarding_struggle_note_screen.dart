import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../shared/widgets/arin_pressable.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';
import 'onboarding_struggle_copy.dart';

class OnboardingStruggleNoteScreen extends StatefulWidget {
  const OnboardingStruggleNoteScreen({
    required this.copy,
    required this.onBack,
    required this.onContinue,
    this.onNoteReady,
    this.initialNote = '',
    this.progress = 0.86,
    this.heardHold = const Duration(milliseconds: 2400),
    super.key,
  });

  final OnboardingStruggleNoteCopy copy;
  final VoidCallback onBack;
  final ValueChanged<String> onContinue;
  final ValueChanged<String>? onNoteReady;
  final String initialNote;
  final double progress;
  final Duration heardHold;

  @override
  State<OnboardingStruggleNoteScreen> createState() =>
      OnboardingStruggleNoteScreenState();
}

class OnboardingStruggleNoteScreenState
    extends State<OnboardingStruggleNoteScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  late final AnimationController _heardAnim;
  Timer? _heardTimer;
  bool _showingHeard = false;
  bool _finished = false;

  String get _trimmed => _controller.text.trim();
  bool get _canContinue => _trimmed.isNotEmpty && !_showingHeard;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
    _heardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_showingHeard) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _heardTimer?.cancel();
    _heardAnim.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _fillSuggestion() {
    if (_showingHeard) return;
    HapticFeedback.selectionClick();
    _controller
      ..text = widget.copy.suggestion
      ..selection = TextSelection.collapsed(
        offset: widget.copy.suggestion.length,
      );
    setState(() {});
  }

  void _submit() {
    if (!_canContinue) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    widget.onNoteReady?.call(_trimmed);
    setState(() => _showingHeard = true);
    _heardAnim.forward(from: 0);
    _heardTimer?.cancel();
    _heardTimer = Timer(widget.heardHold, _finishHeard);
  }

  void _finishHeard() {
    if (_finished || !mounted) return;
    _finished = true;
    _heardTimer?.cancel();
    widget.onContinue(_trimmed);
  }

  bool consumeBack() {
    if (!_showingHeard) return false;
    _heardTimer?.cancel();
    _heardAnim.reverse();
    setState(() {
      _showingHeard = false;
      _finished = false;
    });
    return true;
  }

  void _handleBack() {
    if (consumeBack()) return;
    widget.onBack();
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OnboardingFlowTopBar(
                    progress: widget.progress,
                    onBack: _handleBack,
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.copy.title,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 28,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.onboardingNoteSubtitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.56),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _controller,
                            focusNode: _focus,
                            enabled: !_showingHeard,
                            minLines: 3,
                            maxLines: 5,
                            maxLength: 180,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontFamily: AppTextStyles.primaryFontFamily,
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: widget.copy.hint,
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.38),
                                fontSize: 15,
                                height: 1.4,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              contentPadding: const EdgeInsets.fromLTRB(
                                18,
                                16,
                                18,
                                16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: AppColors.ornamentGold.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: AppColors.ornamentGold.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: AppColors.ornamentGold,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SuggestionChip(
                            text: widget.copy.suggestion,
                            onTap: _fillSuggestion,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OnboardingCtaButton(
                    label: '${l10n.onboardingContinue}  →',
                    enabled: _canContinue,
                    onPressed: _canContinue ? _submit : null,
                  ),
                ],
              ),
            ),
          ),
          if (_showingHeard)
            _HeardVerseOverlay(
              animation: _heardAnim,
              onDismiss: _finishHeard,
            ),
        ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ArinPressable(
      onTap: onTap,
      scale: 0.97,
      sink: 1.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.emeraldDark.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.emeraldLight.withValues(alpha: 0.38),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.ornamentGold.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '“$text”',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeardVerseOverlay extends StatelessWidget {
  const _HeardVerseOverlay({
    required this.animation,
    required this.onDismiss,
  });

  final Animation<double> animation;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.92 + (0.08 * t),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.black.withValues(alpha: 0.58),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onDismiss,
          child: Center(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1410),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.ornamentGold.withValues(alpha: 0.55),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ornamentGold.withValues(alpha: 0.18),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.ornamentGold,
                          size: 30,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.onboardingHeardTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.onboardingHeardVerse,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 18,
                            height: 1.45,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.onboardingHeardSource,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 14,
                            color: AppColors.ornamentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
          ),
        ),
      ),
    );
  }
}
