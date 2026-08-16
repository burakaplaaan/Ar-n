// Yazı silueti yükleniyor işareti — dönen halka yerine marka sözcüğü
// veya metin satırı iskeleti + kayan parıltı.

import 'package:flutter/material.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';

class ArinLoader extends StatelessWidget {
  const ArinLoader({
    super.key,
    this.color,
    this.strokeWidth,
    this.valueColor,
    this.compact = false,
  });

  final Color? color;
  final double? strokeWidth;
  final Animation<Color?>? valueColor;
  final bool compact;

  Color _tint(BuildContext context) {
    final fromAnim = valueColor?.value;
    if (fromAnim != null) return fromAnim;
    if (color != null) return color!;
    final onDark = Theme.of(context).brightness == Brightness.dark;
    return onDark ? AppColors.accentNeonGreen : AppColors.accentGreenOnLight;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n?.generalLoading ?? '…';
    return Semantics(
      label: label,
      liveRegion: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;
          final tight =
              compact ||
              (h.isFinite && h <= 32) ||
              (w.isFinite && w <= 32);
          final tint = _tint(context);
          if (tight) {
            final maxH = h.isFinite ? h : 22.0;
            final maxW = w.isFinite ? w : 36.0;
            final height = maxH.clamp(12.0, 28.0);
            final width = maxW.clamp(16.0, 44.0);
            return Center(
              child: _TextLineSilhouette(
                color: tint,
                width: width,
                height: height,
              ),
            );
          }
          return Center(
            child: _WordSilhouette(color: tint),
          );
        },
      ),
    );
  }
}

class _WordSilhouette extends StatefulWidget {
  const _WordSilhouette({required this.color});

  final Color color;

  @override
  State<_WordSilhouette> createState() => _WordSilhouetteState();
}

class _WordSilhouetteState extends State<_WordSilhouette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color.withValues(alpha: 0.22);
    final highlight = widget.color.withValues(alpha: 0.88);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) {
                final t = _ctrl.value;
                return LinearGradient(
                  begin: Alignment(-1.4 + t * 2.8, 0),
                  end: Alignment(-0.2 + t * 2.8, 0),
                  colors: [base, highlight, base],
                  stops: const [0.28, 0.5, 0.72],
                ).createShader(rect);
              },
              child: const Text(
                'Arın',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  height: 1,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ShimmerBar(
              width: 72,
              height: 5,
              radius: 99,
              animation: _ctrl,
              base: base,
              highlight: highlight,
            ),
          ],
        );
      },
    );
  }
}

class _TextLineSilhouette extends StatefulWidget {
  const _TextLineSilhouette({
    required this.color,
    required this.width,
    required this.height,
  });

  final Color color;
  final double width;
  final double height;

  @override
  State<_TextLineSilhouette> createState() => _TextLineSilhouetteState();
}

class _TextLineSilhouetteState extends State<_TextLineSilhouette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color.withValues(alpha: 0.20);
    final highlight = widget.color.withValues(alpha: 0.78);
    final gap = (widget.height * 0.12).clamp(1.6, 3.2);
    final barH = ((widget.height - gap * 2) / 3).clamp(2.0, 5.5);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBar(
                width: widget.width,
                height: barH,
                radius: 99,
                animation: _ctrl,
                base: base,
                highlight: highlight,
              ),
              SizedBox(height: gap),
              _ShimmerBar(
                width: widget.width * 0.72,
                height: barH,
                radius: 99,
                animation: _ctrl,
                base: base,
                highlight: highlight,
              ),
              SizedBox(height: gap),
              _ShimmerBar(
                width: widget.width * 0.44,
                height: barH,
                radius: 99,
                animation: _ctrl,
                base: base,
                highlight: highlight,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.radius,
    required this.animation,
    required this.base,
    required this.highlight,
  });

  final double width;
  final double height;
  final double radius;
  final Animation<double> animation;
  final Color base;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    final t = animation.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.4 + t * 2.8, 0),
          end: Alignment(-0.2 + t * 2.8, 0),
          colors: [base, highlight, base],
          stops: const [0.28, 0.5, 0.72],
        ),
      ),
    );
  }
}
