import 'package:flutter/material.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';

String onboardingHeartLabelForPercent(AppLocalizations l10n, int percent) {
  if (percent < 20) return l10n.onboardingHeartLabelFar;
  if (percent < 40) return l10n.onboardingHeartLabelSeeking;
  if (percent < 62) return l10n.onboardingHeartLabelHolding;
  if (percent < 82) return l10n.onboardingHeartLabelNear;
  return l10n.onboardingHeartLabelFull;
}

class OnboardingHeartScreen extends StatefulWidget {
  const OnboardingHeartScreen({
    required this.title,
    required this.onBack,
    required this.onContinue,
    this.progress = 0.68,
    this.initialPercent = 58,
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final ValueChanged<int> onContinue;
  final double progress;
  final int initialPercent;

  @override
  State<OnboardingHeartScreen> createState() => _OnboardingHeartScreenState();
}

class _OnboardingHeartScreenState extends State<OnboardingHeartScreen> {
  late double _fill;

  @override
  void initState() {
    super.initState();
    _fill = widget.initialPercent.clamp(0, 100) / 100;
  }

  int get _percent => (_fill * 100).round().clamp(0, 100);

  void _setFromLocalY(double localY, double height) {
    final next = 1 - (localY / height);
    setState(() => _fill = next.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = onboardingHeartLabelForPercent(l10n, _percent);
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
                const SizedBox(height: 28),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 26,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.onboardingHeartHint,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest.shortestSide
                            .clamp(188.0, 236.0);
                        return GestureDetector(
                          onTapDown: (d) =>
                              _setFromLocalY(d.localPosition.dy, size),
                          onVerticalDragUpdate: (d) =>
                              _setFromLocalY(d.localPosition.dy, size),
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: CustomPaint(
                              painter: _HeartFillPainter(fill: _fill),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.ornamentGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '%$_percent',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 22),
                OnboardingCtaButton(
                  label: '${l10n.onboardingContinue}  →',
                  onPressed: () => widget.onContinue(_percent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeartFillPainter extends CustomPainter {
  const _HeartFillPainter({required this.fill});

  final double fill;

  Path _heart(Size size) {
    // Material favorite yolu — klasik, sivri uçlu kalp.
    final path = Path()
      ..moveTo(12, 21.35)
      ..lineTo(10.55, 20.03)
      ..cubicTo(5.4, 15.36, 2, 12.28, 2, 8.5)
      ..cubicTo(2, 5.42, 4.42, 3, 7.5, 3)
      ..cubicTo(9.24, 3, 10.91, 3.81, 12, 5.09)
      ..cubicTo(13.09, 3.81, 14.76, 3, 16.5, 3)
      ..cubicTo(19.58, 3, 22, 5.42, 22, 8.5)
      ..cubicTo(22, 12.28, 18.6, 15.36, 13.45, 20.03)
      ..lineTo(12, 21.35)
      ..close();
    final matrix = Matrix4.diagonal3Values(
      size.width / 24,
      size.height / 24,
      1,
    );
    return path.transform(matrix.storage);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 4.0;
    final path = _heart(Size(size.width - inset * 2, size.height - inset * 2))
        .shift(const Offset(inset, inset));
    canvas.drawPath(
      path.shift(const Offset(0, 6)),
      Paint()
        ..color = AppColors.emeraldLight.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    canvas.save();
    canvas.clipPath(path);
    final fillTop = size.height * (1 - fill);
    canvas.drawRect(
      Rect.fromLTWH(0, fillTop, size.width, size.height - fillTop),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.emeraldLight.withValues(alpha: 0.92),
            AppColors.emeraldMid.withValues(alpha: 0.55),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _HeartFillPainter oldDelegate) {
    return oldDelegate.fill != fill;
  }
}
