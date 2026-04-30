// 4-7-8 nefes terapisi — cam / mandala görselleştirme, tut fazında yavaşlayan kalp sesi.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import 'breathing_bottom_nav_provider.dart';
import 'breathing_haptics.dart';
import 'breathing_heartbeat_audio.dart';

part 'breathing_exercise_visuals.dart';

enum _BreathPhase { inhale, holdIn, exhale }

class BreathingExercisePage extends ConsumerStatefulWidget {
  const BreathingExercisePage({super.key, this.programId});

  final String? programId;

  @override
  ConsumerState<BreathingExercisePage> createState() =>
      _BreathingExercisePageState();
}

class _BreathingExercisePageState extends ConsumerState<BreathingExercisePage>
    with TickerProviderStateMixin {
  static const _phaseDurations = [4, 7, 8];
  static const _maxCycles = 7;

  bool _intro = true;
  bool _sessionComplete = false;
  int _cycleDone = 0;

  _BreathPhase _phase = _BreathPhase.inhale;
  late AnimationController _scaleController;
  Animation<double> _scaleAnim = const AlwaysStoppedAnimation<double>(1.0);
  late AnimationController _pulseController;
  late AnimationController _idleMotionController;
  late AnimationController _mandalaRotationController;
  late AnimationController _introExitController;
  late AnimationController _completeEnterController;
  late final BreathingHeartbeatAudio _heartbeatAudio;
  bool _isDisposing = false;

  int get _phaseIndex => _phase.index;

  @override
  void initState() {
    super.initState();
    _heartbeatAudio = BreathingHeartbeatAudio();
    unawaited(_heartbeatAudio.prepare());
    unawaited(BreathingHaptics.init());
    _scaleController = AnimationController(vsync: this)
      ..addStatusListener(_onScaleStatus);
    // `AnimatedBuilder` zaten `_pulseController`'ı dinliyor (bkz. orb
    // builder) → addListener(setState) eklemesi tüm Scaffold'u her frame
    // yeniden build ettiriyordu. Orb rebuild'leri lokalde kalsın.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _idleMotionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _mandalaRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 96),
    )..repeat();
    _introExitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _completeEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
  }

  void _onScaleStatus(AnimationStatus status) {
    if (!mounted || _isDisposing) return;
    if (status != AnimationStatus.completed) return;

    if (_phase == _BreathPhase.exhale) {
      _cycleDone++;
      if (_cycleDone >= _maxCycles) {
        if (!mounted || _isDisposing) return;
        setState(() => _sessionComplete = true);
        _pulseController.stop();
        _heartbeatAudio.stop();
        _idleMotionController.repeat();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _completeEnterController.forward(from: 0);
          }
        });
        return;
      }
    }

    final next = (_phaseIndex + 1) % 3;
    if (!mounted || _isDisposing) return;
    setState(() => _phase = _BreathPhase.values[next]);
    _startPhase();
  }

  void _onIntroStartTap() {
    if (!_intro || _introExitController.isAnimating) return;
    BreathingHaptics.lightTap();
    _introExitController.forward().whenComplete(() {
      if (!mounted) return;
      _beginSession();
    });
  }

  void _beginSession() {
    ref.read(breathingBottomNavHiddenProvider.notifier).state = true;
    _introExitController.reset();
    unawaited(_heartbeatAudio.prepare());
    _idleMotionController.stop();
    setState(() {
      _intro = false;
      _sessionComplete = false;
      _cycleDone = 0;
      _phase = _BreathPhase.inhale;
    });
    unawaited(ArinAnalytics.nefesStart('breathing_4_7_8'));
    _startPhase();
  }

  void _resetToIntro() {
    ref.read(breathingBottomNavHiddenProvider.notifier).state = false;
    _scaleController.stop();
    _pulseController.stop();
    _heartbeatAudio.stop();
    _introExitController.reset();
    _completeEnterController.reset();
    setState(() {
      _intro = true;
      _sessionComplete = false;
      _cycleDone = 0;
      _phase = _BreathPhase.inhale;
    });
    _idleMotionController.repeat();
  }

  void _startPhase() {
    _heartbeatAudio.stop();
    _scaleController.removeListener(_pulseListener);
    _pulseController.stop();

    final dur = Duration(seconds: _phaseDurations[_phaseIndex]);
    _scaleController.duration = dur;

    switch (_phase) {
      case _BreathPhase.inhale:
        _scaleAnim = Tween<double>(begin: 1.0, end: 1.62).animate(
          CurvedAnimation(
            parent: _scaleController,
            curve: Curves.easeInOutCubic,
          ),
        );
        _scaleController.forward(from: 0);
        unawaited(BreathingHaptics.inhaleStartOnce());
        break;
      case _BreathPhase.holdIn:
        _scaleAnim = Tween<double>(begin: 1.62, end: 1.62).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.linear),
        );
        _scaleController.forward(from: 0);
        _pulseController.repeat(reverse: true);
        _scaleController.addListener(_pulseListener);
        _heartbeatAudio.startSlowingRhythm(
          holdSeconds: _phaseDurations[_phaseIndex],
          shouldContinue: () =>
              mounted &&
              !_intro &&
              !_sessionComplete &&
              _phase == _BreathPhase.holdIn,
        );
        break;
      case _BreathPhase.exhale:
        _scaleAnim = Tween<double>(begin: 1.62, end: 1.0).animate(
          CurvedAnimation(
            parent: _scaleController,
            curve: Curves.easeInOutCubic,
          ),
        );
        _scaleController.forward(from: 0);
        break;
    }
  }

  void _pulseListener() {
    if (!mounted || _isDisposing) return;
    setState(() {});
  }

  double get _displayScale {
    final base = _scaleAnim.value;
    if (_phase == _BreathPhase.holdIn) {
      final wobble = 0.018 * _pulseController.value;
      return base + wobble;
    }
    return base;
  }

  ({Color a, Color b, Color c}) get _orbPalette {
    switch (_phase) {
      case _BreathPhase.inhale:
        return (
          a: const Color(0xFFB8E8FF),
          b: const Color(0xFF5EEAD4),
          c: const Color(0xFF0D3D32),
        );
      case _BreathPhase.holdIn:
        return (
          a: const Color(0xFFFFE8B4),
          b: const Color(0xFFE8A838),
          c: const Color(0xFF2A2410),
        );
      case _BreathPhase.exhale:
        return (
          a: const Color(0xFFA7F3D0),
          b: const Color(0xFF34D399),
          c: const Color(0xFF082018),
        );
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    ref.read(breathingBottomNavHiddenProvider.notifier).state = false;
    _heartbeatAudio.dispose();
    _scaleController.removeStatusListener(_onScaleStatus);
    _scaleController.removeListener(_pulseListener);
    _scaleController.dispose();
    _pulseController.dispose();
    _idleMotionController.dispose();
    _mandalaRotationController.dispose();
    _introExitController.dispose();
    _completeEnterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.emeraldLight;
    const mint = AppColors.accentNeonGreen;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101820), Color(0xFF0F1A16), Color(0xFF1A1F1C)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _exitBreathing(context);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildBreathCenter(accent, mint)),
                  if (_intro)
                    AnimatedBuilder(
                      animation: _introExitController,
                      builder: (context, _) {
                        final t = Curves.easeInCubic.transform(
                          _introExitController.value,
                        );
                        return Opacity(
                          opacity: 1.0 - t,
                          child: Transform.translate(
                            offset: Offset(0, 52 * t),
                            child: _buildIntroBottomContent(
                              context,
                              accent,
                              mint,
                            ),
                          ),
                        );
                      },
                    ),
                  if (!_intro && _sessionComplete)
                    AnimatedBuilder(
                      animation: _completeEnterController,
                      builder: (context, _) {
                        final t = Curves.easeOutCubic.transform(
                          _completeEnterController.value,
                        );
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 52 * (1 - t)),
                            child: _buildCompleteBottomContent(
                              context,
                              accent,
                              mint,
                            ),
                          ),
                        );
                      },
                    ),
                  if (!_intro && !_sessionComplete)
                    _buildBottomGlass(context, accent, mint),
                ],
              ),
              if (!_intro && !_sessionComplete)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: _buildSessionTopOverlay(context, accent),
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 0, 0),
                    child: _buildBackButton(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _exitBreathing(context),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: Color(0xE8FFFFFF),
          ),
        ),
      ),
    );
  }

  void _exitBreathing(BuildContext context) {
    if (!mounted || _isDisposing) return;
    _isDisposing = true;
    BreathingHaptics.lightTap();
    ref.read(breathingBottomNavHiddenProvider.notifier).state = false;
    _heartbeatAudio.stop();
    _scaleController.removeStatusListener(_onScaleStatus);
    _scaleController.removeListener(_pulseListener);
    _scaleController.stop();
    _pulseController.stop();
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    popOrGoWillpowerHub(context);
  }

  Widget _buildSessionTopOverlay(BuildContext context, Color accent) {
    final l10n = AppLocalizations.of(context)!;
    final labels = <String>[
      l10n.breathingPhaseInhale,
      l10n.breathingPhaseHold,
      l10n.breathingPhaseExhale,
    ];
    const topFade = 0.4;
    const phaseFade = 0.48;
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _pulseController]),
      builder: (context, _) {
        final total = _phaseDurations[_phaseIndex];
        final showSec = (total * (1 - _scaleController.value)).ceil().clamp(
          1,
          total,
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(56, 2, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    l10n.breathingCycleProgress(_cycleDone + 1, _maxCycles),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.creamBase.withValues(
                        alpha: topFade * 0.9,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.creamBase.withValues(
                        alpha: topFade,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      _exitBreathing(context);
                    },
                    child: Text(
                      l10n.breathingFinishAction,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.creamBase.withValues(alpha: topFade),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                labels[_phaseIndex],
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: accent.withValues(alpha: phaseFade),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.breathingSecondsLabel(showSec),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.creamBase.withValues(alpha: topFade * 0.85),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreathCenter(Color accent, Color mint) {
    if (_intro || _sessionComplete) {
      return AnimatedBuilder(
        animation: Listenable.merge([
          _idleMotionController,
          _mandalaRotationController,
        ]),
        builder: (context, _) {
          final t = _idleMotionController.value * math.pi * 2;
          final idleScale = 1.0 + 0.06 * math.sin(t);
          final palette = _sessionComplete
              ? (
                  a: accent.withValues(alpha: 0.95),
                  b: mint,
                  c: const Color(0xFF0D2818),
                )
              : (
                  a: const Color(0xFFB8E8FF),
                  b: const Color(0xFF5EEAD4),
                  c: const Color(0xFF0D3D32),
                );
          return Center(
            child: RepaintBoundary(
              child: _AuroraBreathVisual(
                breathScale: idleScale,
                rotation: _mandalaRotationController.value * math.pi * 2,
                pulseT: 0,
                palette: palette,
                isIdle: true,
              ),
            ),
          );
        },
      );
    }
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleController,
        _pulseController,
        _mandalaRotationController,
      ]),
      builder: (context, _) {
        return Center(
          child: RepaintBoundary(
            child: _AuroraBreathVisual(
              breathScale: _displayScale,
              rotation: _mandalaRotationController.value * math.pi * 2,
              pulseT: _phase == _BreathPhase.holdIn
                  ? _pulseController.value
                  : 0,
              palette: _orbPalette,
              isIdle: false,
            ),
          ),
        );
      },
    );
  }

  /// Altta, panel yok; Başla’da aşağı + soluk çıkış.
  Widget _buildIntroBottomContent(
    BuildContext context,
    Color accent,
    Color mint,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 8 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    _exitBreathing(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.commonClose,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.creamBase.withValues(alpha: 0.42),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              l10n.breathingIntroTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.creamBase.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
                fontSize: 17,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.breathingIntroSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.creamBase.withValues(alpha: 0.55),
                height: 1.35,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _IntroMetaChip(
                  icon: Icons.repeat_rounded,
                  label: l10n.breathingIntroCycles(_maxCycles),
                  mint: mint,
                ),
                _IntroMetaChip(
                  icon: Icons.schedule_rounded,
                  label: l10n.breathingIntroApproxMinutes,
                  mint: mint,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _IntroPhaseHint(
                    n: 4,
                    caption: l10n.breathingPhaseHintInhale,
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _IntroPhaseHint(
                    n: 7,
                    caption: l10n.breathingPhaseHintHold,
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _IntroPhaseHint(
                    n: 8,
                    caption: l10n.breathingPhaseHintExhale,
                    accent: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton(
                onPressed: _onIntroStartTap,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: mint,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  side: BorderSide(
                    color: mint.withValues(alpha: 0.88),
                    width: 1.6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 12,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  l10n.commonStart,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: mint,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Giriş paneli ile aynı düzen: cam kutu yok; şeffaf çerçeveli Yeniden + aynı stilde Kapat.
  Widget _buildCompleteBottomContent(
    BuildContext context,
    Color accent,
    Color mint,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sessionEndBtnStyle = OutlinedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: mint,
      shadowColor: Colors.transparent,
      elevation: 0,
      side: BorderSide(color: mint.withValues(alpha: 0.88), width: 1.6),
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    );
    final sessionEndBtnTextStyle = AppTextStyles.labelLarge.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 15,
      color: mint,
      letterSpacing: 0.35,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 8 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Icon(
                Icons.check_circle_rounded,
                size: 44,
                color: mint.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.breathingSessionCompleteTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.creamBase.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
                fontSize: 17,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.breathingSessionCompleteSubtitle(_maxCycles),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.creamBase.withValues(alpha: 0.55),
                height: 1.4,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton(
                onPressed: () {
                  BreathingHaptics.lightTap();
                  _resetToIntro();
                },
                style: sessionEndBtnStyle,
                child: Text(l10n.commonRestart, style: sessionEndBtnTextStyle),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton(
                onPressed: () {
                  _exitBreathing(context);
                },
                style: sessionEndBtnStyle,
                child: Text(l10n.commonClose, style: sessionEndBtnTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomGlass(BuildContext context, Color accent, Color mint) {
    final l10n = AppLocalizations.of(context)!;
    return _BreathingGlassPanel(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 16,
                color: mint.withValues(alpha: 0.38),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.breathingBottomHint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.creamBase.withValues(alpha: 0.38),
                    height: 1.45,
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

