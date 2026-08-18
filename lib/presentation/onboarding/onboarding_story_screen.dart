// Onboarding hikâye ekranı: başlık + gövde daktilo animasyonu.
// Bir dokunuş hızlandırır; Devam yalnızca yazım bitince görünür.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:arin/l10n/app_localizations.dart';

import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';
import 'onboarding_typewriter_haptic.dart';

class OnboardingStoryScreen extends StatefulWidget {
  const OnboardingStoryScreen({
    required this.title,
    required this.body,
    required this.onBack,
    required this.onContinue,
    this.progress = 0.22,
    this.typewriterKey = 'onboarding_story_typewriter',
    super.key,
  });

  final String title;
  final String body;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final double progress;
  final String typewriterKey;

  static const Duration slowTick = Duration(milliseconds: 34);
  static const Duration fastTick = Duration(milliseconds: 8);

  @override
  State<OnboardingStoryScreen> createState() => _OnboardingStoryScreenState();
}

class _OnboardingStoryScreenState extends State<OnboardingStoryScreen> {
  Timer? _timer;
  final OnboardingTypewriterHaptics _haptics = OnboardingTypewriterHaptics();
  int _titleChars = 0;
  int _bodyChars = 0;
  bool _fast = false;
  String _title = '';
  String _body = '';

  bool get _titleDone => _titleChars >= _title.length;
  bool get _done => _titleDone && _bodyChars >= _body.length;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _body = widget.body;
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant OnboardingStoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title == widget.title && oldWidget.body == widget.body) {
      return;
    }
    _title = widget.title;
    _body = widget.body;
    _titleChars = 0;
    _bodyChars = 0;
    _fast = false;
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _haptics.stop();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_done) return;
    _timer = Timer.periodic(
      _fast ? OnboardingStoryScreen.fastTick : OnboardingStoryScreen.slowTick,
      (_) => _tick(),
    );
  }

  void _tick() {
    if (!mounted) return;
    if (!_titleDone) {
      setState(() => _titleChars += 1);
      _haptics.onChar(fast: _fast);
      return;
    }
    if (_bodyChars < _body.length) {
      setState(() => _bodyChars += 1);
      _haptics.onChar(fast: _fast);
      return;
    }
    _timer?.cancel();
    _haptics.stop();
    setState(() {});
  }

  void _onTapToSpeed() {
    if (_done || _fast) return;
    HapticFeedback.selectionClick();
    setState(() => _fast = true);
    _restartTimer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleText = _title.substring(0, _titleChars.clamp(0, _title.length));
    final bodyText = _body.substring(0, _bodyChars.clamp(0, _body.length));

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
                  onBack: widget.onBack,
                ),
                const SizedBox(height: 36),
                Expanded(
                  child: GestureDetector(
                    key: Key(widget.typewriterKey),
                    behavior: HitTestBehavior.opaque,
                    onTap: _onTapToSpeed,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 36,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            bodyText,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 20,
                              height: 1.45,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_done)
                  OnboardingCtaButton(
                    label: '${l10n.onboardingContinue}  →',
                    onPressed: widget.onContinue,
                  ).animate().fadeIn(duration: 280.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
