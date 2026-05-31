// lib/presentation/shared/widgets/commitment_seal_widget.dart
// Basılı tutarak söz mühürleme — onboarding ve İrade akışlarında ortak.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_text_styles.dart';
import 'package:arin/l10n/app_localizations.dart';

class CommitmentSealWidget extends StatefulWidget {
  const CommitmentSealWidget({
    super.key,
    required this.displayNameSuffix,
    required this.onCompleted,
    this.titlePrefix,
    this.infoBannerText,
    this.encourageWhileNotHolding,
    this.encourageWhileHolding,
    this.successMessage,
    this.holdHint,
    this.holdDuration = const Duration(seconds: 3),
    this.accentColor = const Color(0xFFFFC107),
    this.progressTrackColor,
    this.showSkip = true,
    this.skipLabel,
    this.ambientBreathingRings = false,
    this.echoLines,
  });

  final String displayNameSuffix;
  final VoidCallback onCompleted;
  final String? titlePrefix;
  final String? infoBannerText;
  final String? encourageWhileNotHolding;
  final String? encourageWhileHolding;
  final String? successMessage;
  final String? holdHint;
  final Duration holdDuration;
  final Color accentColor;
  final Color? progressTrackColor;
  final bool showSkip;
  final String? skipLabel;
  final bool ambientBreathingRings;
  final List<String>? echoLines;

  @override
  State<CommitmentSealWidget> createState() => _CommitmentSealWidgetState();
}

class _CommitmentSealWidgetState extends State<CommitmentSealWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  AnimationController? _ambientController;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )..addListener(_onProgressChanged);
    if (widget.ambientBreathingRings) {
      _ambientController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3600),
      )..repeat(reverse: true);
    }
  }

  Future<void> _onProgressChanged() async {
    setState(() {});

    if (_isCompleted) return;

    if (_progressController.isCompleted && !_isCompleted) {
      setState(() => _isCompleted = true);
      // Basılı tutma boyunca titreşim yok; yalnızca mühür tamamlanınca kısa geri bildirim.
      await Future<void>.delayed(const Duration(milliseconds: 40));
      HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 70));
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 55));
      HapticFeedback.selectionClick();

      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        widget.onCompleted();
      });
    }
  }

  @override
  void dispose() {
    _ambientController?.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _onPanDown(_) {
    if (!_isCompleted) {
      _progressController.forward();
    }
  }

  void _onPanCancel() {
    if (!_isCompleted && !_progressController.isCompleted) {
      _progressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titlePrefix = widget.titlePrefix ?? AppLocalizations.of(context)!.sealYourIntention;
    final infoText = widget.infoBannerText ?? AppLocalizations.of(context)!.sealIntentionInfo;
    final encourageIdle = widget.encourageWhileNotHolding ?? AppLocalizations.of(context)!.touchAndHoldWhenReady;
    final encourageHold = widget.encourageWhileHolding ?? AppLocalizations.of(context)!.youAreAlmostThere;
    final successMsg = widget.successMessage ?? AppLocalizations.of(context)!.promiseSealed;
    final holdBottom = widget.holdHint ?? AppLocalizations.of(context)!.touchAndHoldToContinue;
    final skipLabel = widget.skipLabel ?? AppLocalizations.of(context)!.skipWithArrow;
    final track = widget.progressTrackColor ??
        Colors.white.withValues(alpha: 0.1);
    final accent = widget.accentColor;

    final totalSec = widget.holdDuration.inSeconds;
    final remainingSeconds =
        totalSec - (_progressController.value * totalSec).ceil();
    final isHolding = _progressController.isAnimating;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (widget.showSkip)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onCompleted,
                child: Text(
                  skipLabel,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
            ).animate().fadeIn(),
          if (widget.showSkip) const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    infoText,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),
          const SizedBox(height: 40),
          Text(
            '$titlePrefix${widget.displayNameSuffix}',
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
          if (widget.echoLines != null && widget.echoLines!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Column(
              children: [
                for (final line in widget.echoLines!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '◦ $line',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ).animate().fadeIn(delay: 480.ms).slideY(begin: 0.04),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _isCompleted
                  ? accent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _isCompleted ? accent : Colors.transparent,
              ),
            ),
            child: Text(
              _isCompleted
                  ? successMsg
                  : (isHolding ? encourageHold : encourageIdle),
              style: TextStyle(
                color: _isCompleted ? accent : Colors.white,
                fontSize: 16,
                fontWeight: _isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
          const Spacer(),
          if (isHolding && !_isCompleted)
            Text(
              '$remainingSeconds s',
              style: TextStyle(
                color: accent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 300.ms).then().fadeOut(duration: 300.ms),
          if (!isHolding && !_isCompleted) const SizedBox(height: 28),
          const SizedBox(height: 16),
          GestureDetector(
            onPanDown: _onPanDown,
            onPanEnd: (_) => _onPanCancel(),
            onPanCancel: _onPanCancel,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (_ambientController != null)
                  ..._ambientRingLayers(accent),
                if (_isCompleted)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(track),
                  ),
                ),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _progressController.value,
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isCompleted ? accent : Colors.white,
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: _progressController.isAnimating ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isCompleted ? Icons.check_circle : Icons.touch_app,
                    color: _isCompleted
                        ? accent
                        : Colors.white.withValues(
                            alpha: _progressController.isAnimating ? 1.0 : 0.8,
                          ),
                    size: 80,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms).scale(),
          const SizedBox(height: 40),
          Text(
            _isCompleted
                ? AppLocalizations.of(context)!.redirecting
                : (isHolding
                    ? AppLocalizations.of(context)!.keepGoing
                    : holdBottom),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isCompleted
                  ? accent
                  : Colors.white.withValues(alpha: 0.5),
              height: 1.5,
              fontWeight:
                  _isCompleted ? FontWeight.bold : FontWeight.normal,
            ),
          ).animate().fadeIn(delay: 1000.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Arka planda hafif nefes halkaları (onboarding mühürü).
  List<Widget> _ambientRingLayers(Color accent) {
    final c = _ambientController!;
    return List<Widget>.generate(3, (i) {
      final base = 168.0 + i * 38.0;
      return AnimatedBuilder(
        animation: c,
        builder: (context, child) {
          final t = c.value;
          final wave = (math.sin(t * math.pi * 2 + i * 0.9) + 1) * 0.5;
          final scale = 0.94 + 0.1 * wave;
          final opacity = (0.1 + 0.08 * wave) * (1 - i * 0.22);
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity.clamp(0.04, 0.22),
              child: Container(
                width: base,
                height: base,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35 + 0.25 * wave),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).reversed.toList();
  }
}
