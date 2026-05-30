import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part of 'zikir_matik_page.dart';

/// Alt araç: yuvarlak düğme + alt etiket (titreşim / zikir bilgisi).
class _ZikirmatikRoundToolColumn extends StatelessWidget {
  const _ZikirmatikRoundToolColumn({
    required this.diameter,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tooltip,
    this.activeVisual = false,
    this.semanticsToggled,
  });

  final double diameter;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String tooltip;
  final bool activeVisual;
  final bool? semanticsToggled;

  @override
  Widget build(BuildContext context) {
    final bg = activeVisual
        ? _ZikirmatikColors.outer
        : _ZikirmatikColors.smallBtn;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Semantics(
        button: true,
        label: tooltip,
        toggled: semanticsToggled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: bg,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                splashColor: _ZikirmatikColors.lcdBg.withValues(alpha: 0.28),
                highlightColor: _ZikirmatikColors.lcdBg.withValues(alpha: 0.14),
                child: SizedBox(
                  width: diameter,
                  height: diameter,
                  child: Icon(
                    icon,
                    color: activeVisual
                        ? Colors.white
                        : _ZikirmatikColors.labelMuted.withValues(alpha: 0.95),
                    size: (diameter * 0.44).clamp(22.0, 30.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: diameter + 18,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ZikirmatikColors.labelMuted.withValues(alpha: 0.78),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beton hisli zikir metni kartı: giriş animasyonu, metin değişiminde geçiş, nefes ölçeği.
class _ZikirPhraseConcreteCard extends StatelessWidget {
  const _ZikirPhraseConcreteCard({
    required this.phrase,
    required this.onTap,
    required this.phraseAnim,
    required this.phraseScale,
  });

  final String phrase;
  final VoidCallback onTap;
  final Animation<double> phraseAnim;
  final Animation<double> phraseScale;

  static const _betonTop = Color(0xFF4E616C);
  static const _betonMid = Color(0xFF384854);
  static const _betonBot = Color(0xFF232C32);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: _ZikirmatikColors.lcdBg.withValues(alpha: 0.14),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_betonTop, _betonMid, _betonBot],
              stops: [0.0, 0.45, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.09),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 22,
                offset: const Offset(0, 10),
                spreadRadius: -6,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.04),
                blurRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.zikirmatikTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.6,
                        height: 1.1,
                        color: _ZikirmatikColors.outer.withValues(alpha: 0.92),
                      ),
                    ),
                    if (phrase.trim().isEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.zikirmatikTapToChoose,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: _ZikirmatikColors.labelMuted.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: _ZikirmatikColors.labelMuted.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AnimatedBuilder(
                              animation: Listenable.merge(<Listenable>[
                                phraseAnim,
                                phraseScale,
                              ]),
                              builder: (context, _) {
                                final glow =
                                    0.08 +
                                    0.16 *
                                        Curves.easeInOut.transform(
                                          phraseAnim.value,
                                        );
                                final blur =
                                    10 +
                                    14 *
                                        Curves.easeInOut.transform(
                                          phraseAnim.value,
                                        );
                                return Transform.scale(
                                  scale: phraseScale.value,
                                  alignment: Alignment.center,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 420),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder:
                                        (Widget child, Animation<double> anim) {
                                          final slide =
                                              Tween<Offset>(
                                                begin: const Offset(0, 0.07),
                                                end: Offset.zero,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: anim,
                                                  curve: Curves.easeOutCubic,
                                                ),
                                              );
                                          return FadeTransition(
                                            opacity: anim,
                                            child: SlideTransition(
                                              position: slide,
                                              child: child,
                                            ),
                                          );
                                        },
                                    child: Text(
                                      phrase,
                                      key: ValueKey<String>(phrase),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.fraunces(
                                        fontSize: 27,
                                        fontWeight: FontWeight.w600,
                                        height: 1.18,
                                        letterSpacing: -0.4,
                                        color: const Color(0xFFF2F6FA),
                                        shadows: [
                                          Shadow(
                                            color: _ZikirmatikColors.outer
                                                .withValues(alpha: glow),
                                            blurRadius: blur,
                                          ),
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 0,
                                            offset: const Offset(0, 1.2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedBuilder(
                            animation: phraseAnim,
                            builder: (context, _) {
                              final t = Curves.easeInOut.transform(
                                phraseAnim.value,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Transform.rotate(
                                  angle: (t - 0.5) * 0.12,
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 30,
                                    color: _ZikirmatikColors.labelMuted
                                        .withValues(alpha: 0.88),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Merkez diyalog: beton kart, kademeli giriş, özel ifade satırı.
class _ZikirPhrasePickerPanel extends StatelessWidget {
  const _ZikirPhrasePickerPanel({
    required this.entrance,
    required this.customPhrases,
    required this.onPick,
    required this.onDeleteCustom,
    required this.onCustom,
  });

  final Animation<double> entrance;
  final List<String> customPhrases;
  final void Function(String phrase) onPick;
  final Future<void> Function(String phrase) onDeleteCustom;
  final VoidCallback onCustom;

  static const _betonTop = Color(0xFF4A5C66);
  static const _betonMid = Color(0xFF323D44);
  static const _betonBot = Color(0xFF1F272C);

  Widget _stagger(
    Widget child,
    double start,
    double end, {
    double slideY = 14,
  }) {
    final safeEnd = end.clamp(0.001, 1.0);
    final safeStart = start.clamp(0.0, safeEnd - 0.001);
    final a = CurvedAnimation(
      parent: entrance,
      curve: Interval(safeStart, safeEnd, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: a,
      builder: (_, __) {
        return Opacity(
          opacity: a.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slideY * (1 - a.value)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final phrases = _zikirPresetPhrases(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_betonTop, _betonMid, _betonBot],
              stops: [0.0, 0.46, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 32,
                offset: const Offset(0, 18),
                spreadRadius: -8,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 8, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _stagger(
                          Text(
                            AppLocalizations.of(context)!.zikirmatikPickDhikr,
                            style: GoogleFonts.outfit(
                              color: _ZikirmatikColors.labelMuted,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                          ),
                          0.0,
                          0.22,
                        ),
                      ),
                      _stagger(
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close_rounded,
                            color: _ZikirmatikColors.labelMuted.withValues(
                              alpha: 0.85,
                            ),
                            size: 26,
                          ),
                          tooltip: AppLocalizations.of(context)!.zikirmatikCancel,
                        ),
                        0.04,
                        0.24,
                        slideY: 8,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < phrases.length; i++)
                        _stagger(
                          _ZikirPresetPhraseChip(
                            label: phrases[i],
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onPick(phrases[i]);
                            },
                          ),
                          0.12 + i * 0.038,
                          0.12 + i * 0.038 + 0.32,
                        ),
                    ],
                  ),
                ),
                if (customPhrases.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: _stagger(
                      _ZikirPickerSectionLabel(
                        label: AppLocalizations.of(context)!.zikirmatikSaved,
                      ),
                      0.28,
                      0.58,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < customPhrases.length; i++)
                          _stagger(
                            _ZikirSavedPhraseChip(
                              label: customPhrases[i],
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onPick(customPhrases[i]);
                              },
                              onDelete: () {
                                HapticFeedback.lightImpact();
                                onDeleteCustom(customPhrases[i]);
                              },
                            ),
                            0.32 + i * 0.03,
                            0.32 + i * 0.03 + 0.28,
                          ),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                  child: _stagger(
                    _ZikirCustomPhraseTile(onTap: onCustom),
                    0.38,
                    0.82,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZikirPickerSectionLabel extends StatelessWidget {
  const _ZikirPickerSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        color: _ZikirmatikColors.outer.withValues(alpha: 0.88),
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1.8,
        height: 1.1,
      ),
    );
  }
}

class _ZikirPresetPhraseChip extends StatelessWidget {
  const _ZikirPresetPhraseChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: _ZikirmatikColors.lcdBg.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF3D4F59).withValues(alpha: 0.95),
                const Color(0xFF283238).withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: _ZikirmatikColors.labelMuted,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZikirSavedPhraseChip extends StatelessWidget {
  const _ZikirSavedPhraseChip({
    required this.label,
    required this.onTap,
    required this.onDelete,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _ZikirmatikColors.outer.withValues(alpha: 0.42),
              const Color(0xFF263137).withValues(alpha: 0.98),
            ],
          ),
          border: Border.all(
            color: _ZikirmatikColors.lcdBg.withValues(alpha: 0.18),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: _ZikirmatikColors.lcdBg.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 15,
              top: 9,
              bottom: 9,
              end: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 210),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: _ZikirmatikColors.labelMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: AppLocalizations.of(context)!.zikirmatikDelete,
                  child: InkResponse(
                    onTap: onDelete,
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: _ZikirmatikColors.labelMuted.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZikirCustomPhraseTile extends StatelessWidget {
  const _ZikirCustomPhraseTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(999),
        splashColor: _ZikirmatikColors.lcdBg.withValues(alpha: 0.16),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                _ZikirmatikColors.smallBtn.withValues(alpha: 0.55),
                const Color(0xFF252E34).withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(
              color: _ZikirmatikColors.outer.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 24,
                  color: _ZikirmatikColors.outer.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.zikirmatikWriteOwnText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: _ZikirmatikColors.labelMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
