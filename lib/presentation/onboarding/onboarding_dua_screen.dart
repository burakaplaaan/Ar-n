import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_typewriter_haptic.dart';

class OnboardingDuaScreen extends StatefulWidget {
  const OnboardingDuaScreen({
    required this.name,
    required this.onFinished,
    this.tick = const Duration(milliseconds: 36),
    this.hold = const Duration(milliseconds: 1100),
    super.key,
  });

  final String name;
  final VoidCallback onFinished;
  final Duration tick;
  final Duration hold;

  @override
  State<OnboardingDuaScreen> createState() => _OnboardingDuaScreenState();
}

class _OnboardingDuaScreenState extends State<OnboardingDuaScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _chars = 0;
  bool _holdDone = false;
  Offset? _washOrigin;
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _aminKey = GlobalKey();
  late final AnimationController _hold;
  List<_DuaChunk> _chunks = const [];

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: widget.hold)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finishHold();
      });
    _hold.addListener(() {
      if (!mounted) return;
      _syncWashOrigin();
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chunks = _buildChunks(AppLocalizations.of(context)!);
      _timer = Timer.periodic(widget.tick, (_) => _tick());
      setState(() {});
    });
  }

  List<_DuaChunk> _buildChunks(AppLocalizations l10n) {
    return [
      _DuaChunk(
        text: l10n.onboardingDuaTitle,
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      _DuaChunk(
        text: l10n.onboardingDuaBody(widget.name),
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 18,
          height: 1.45,
          color: Colors.white,
        ),
      ),
      _DuaChunk(
        text: l10n.onboardingDuaVerseArabic,
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 20,
          height: 1.7,
          color: AppColors.ornamentGold,
        ),
        rtl: true,
      ),
      _DuaChunk(
        text: l10n.onboardingDuaVerseTranslation,
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: AppColors.ornamentGold,
        ),
      ),
      _DuaChunk(
        text: l10n.onboardingDuaVerseSource,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.ornamentGold.withValues(alpha: 0.86),
        ),
      ),
      _DuaChunk(
        text: l10n.onboardingDuaAmin,
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ];
  }

  int get _totalChars {
    var n = 0;
    for (final chunk in _chunks) {
      n += chunk.text.length;
    }
    return n;
  }

  bool get _typed => _chunks.isNotEmpty && _chars >= _totalChars;

  bool _shouldHapticForIndex(int index) {
    var start = 0;
    for (final chunk in _chunks) {
      final end = start + chunk.text.length;
      if (index < end) return !chunk.rtl;
      start = end;
    }
    return false;
  }

  void _tick() {
    if (!mounted || _chunks.isEmpty || _typed) {
      _timer?.cancel();
      if (mounted) setState(() {});
      return;
    }
    final next = _chars;
    setState(() => _chars += 1);
    if (_shouldHapticForIndex(next)) {
      playOnboardingTypewriterHaptic();
    }
  }

  void _syncWashOrigin() {
    final amin = _aminKey.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (amin == null || stack == null || !amin.hasSize || !stack.hasSize) {
      return;
    }
    _washOrigin = stack.globalToLocal(
      amin.localToGlobal(amin.size.center(Offset.zero)),
    );
  }

  void _finishHold() {
    if (_holdDone || !mounted) return;
    _holdDone = true;
    HapticFeedback.mediumImpact();
    widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      key: _stackKey,
      fit: StackFit.expand,
      children: [
        const OnboardingEntryBackdrop(),
        if (_hold.value > 0)
          IgnorePointer(
            child: CustomPaint(
              painter: _GoldWashPainter(
                progress: _hold.value,
                origin: _washOrigin,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: AbsorbPointer(
                      child: _DuaTypedText(chunks: _chunks, chars: _chars),
                    ),
                  ),
                ),
                if (_typed) ...[
                  const SizedBox(height: 12),
                  _AminHoldButton(
                    buttonKey: _aminKey,
                    label: l10n.onboardingDuaAmin.replaceAll('.', ''),
                    hint: l10n.onboardingDuaHoldHint,
                    progress: _hold.value,
                    pressed: _hold.isAnimating || _hold.value > 0,
                    onHoldStart: () {
                      HapticFeedback.selectionClick();
                      _syncWashOrigin();
                      _hold.forward();
                    },
                    onHoldEnd: () {
                      if (_hold.value < 1 && !_holdDone) {
                        _hold.reverse();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DuaChunk {
  const _DuaChunk({
    required this.text,
    required this.style,
    this.rtl = false,
  });

  final String text;
  final TextStyle style;
  final bool rtl;
}

class _DuaTypedText extends StatelessWidget {
  const _DuaTypedText({required this.chunks, required this.chars});

  final List<_DuaChunk> chunks;
  final int chars;

  @override
  Widget build(BuildContext context) {
    var remaining = chars;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final chunk in chunks) ...[
          Builder(
            builder: (context) {
              final take = remaining.clamp(0, chunk.text.length);
              remaining -= take;
              if (take == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  chunk.text.substring(0, take),
                  textAlign: chunk.rtl ? TextAlign.right : TextAlign.left,
                  textDirection:
                      chunk.rtl ? TextDirection.rtl : TextDirection.ltr,
                  style: chunk.style,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _AminHoldButton extends StatelessWidget {
  const _AminHoldButton({
    required this.buttonKey,
    required this.label,
    required this.hint,
    required this.progress,
    required this.pressed,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final Key buttonKey;
  final String label;
  final String hint;
  final double progress;
  final bool pressed;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onHoldStart(),
      onTapUp: (_) => onHoldEnd(),
      onTapCancel: onHoldEnd,
      child: Center(
        child: AnimatedScale(
          scale: pressed ? 0.9 : 1,
          duration: Duration(milliseconds: pressed ? 80 : 160),
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: pressed ? const Offset(0, 0.045) : Offset.zero,
            duration: Duration(milliseconds: pressed ? 80 : 160),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              key: buttonKey,
              width: 128,
              height: 128,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emeraldDark.withValues(
                    alpha: pressed ? 0.98 : 0.94,
                  ),
                  border: Border.all(
                    color: AppColors.ornamentGold.withValues(alpha: 0.85),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: pressed ? 0.28 : 0.12,
                      ),
                      blurRadius: pressed ? 8 : 16,
                      offset: Offset(0, pressed ? 2 : 6),
                    ),
                    BoxShadow(
                      color: AppColors.ornamentGold.withValues(
                        alpha: 0.18 + (0.2 * progress),
                      ),
                      blurRadius: 16 + (10 * progress),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldWashPainter extends CustomPainter {
  const _GoldWashPainter({required this.progress, required this.origin});

  final double progress;
  final Offset? origin;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final start = origin ?? Offset(size.width / 2, size.height - 116);
    final maxRadius = math.sqrt(
      math.pow(size.width, 2) + math.pow(size.height, 2),
    );
    final radius = maxRadius * Curves.easeInCubic.transform(progress);
    canvas.drawCircle(
      start,
      radius,
      Paint()..color = AppColors.ornamentGold.withValues(alpha: 0.42),
    );
  }

  @override
  bool shouldRepaint(covariant _GoldWashPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.origin != origin;
  }
}
