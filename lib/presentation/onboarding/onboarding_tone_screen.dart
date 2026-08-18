import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../shared/widgets/arin_pressable.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';
import 'onboarding_struggle_copy.dart';

class OnboardingToneScreen extends StatefulWidget {
  const OnboardingToneScreen({
    required this.title,
    required this.onBack,
    required this.onContinue,
    this.progress = 0.93,
    this.initialLevel = 3,
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final ValueChanged<int> onContinue;
  final double progress;
  final int initialLevel;

  @override
  State<OnboardingToneScreen> createState() => _OnboardingToneScreenState();
}

class _OnboardingToneScreenState extends State<OnboardingToneScreen> {
  late int _level;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel.clamp(1, 5);
  }

  void _setLevel(int level) {
    final next = level.clamp(1, 5);
    if (next == _level) return;
    HapticFeedback.selectionClick();
    setState(() => _level = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = onboardingToneOptions(l10n);
    final selected = onboardingToneOptionForLevel(l10n, _level);

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
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.onboardingToneSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.56),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 92,
                          height: 92,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: AppColors.emeraldLight.withValues(
                                alpha: 0.28,
                              ),
                            ),
                          ),
                          child: Text(
                            selected.emoji,
                            style: const TextStyle(fontSize: 42),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          selected.label,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.onboardingToneValue(_level),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _ToneSlider(level: _level, onChanged: _setLevel),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            for (final option in options)
                              Expanded(
                                child: _ToneTick(
                                  option: option,
                                  selected: option.level == _level,
                                  onTap: () => _setLevel(option.level),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OnboardingCtaButton(
                  label: '${l10n.onboardingContinue}  →',
                  onPressed: () => widget.onContinue(_level),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToneTick extends StatelessWidget {
  const _ToneTick({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OnboardingToneOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ArinPressable(
      onTap: onTap,
      scale: 0.94,
      sink: 1.4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Text(
              option.emoji,
              style: TextStyle(
                fontSize: selected ? 22 : 18,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white.withValues(alpha: selected ? 0.9 : 0.48),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToneSlider extends StatelessWidget {
  const _ToneSlider({required this.level, required this.onChanged});

  final int level;
  final ValueChanged<int> onChanged;

  void _fromLocalX(double x, double width) {
    if (width <= 0) return;
    final t = (x / width).clamp(0.0, 1.0);
    onChanged((t * 4).round() + 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final t = (level - 1) / 4;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _fromLocalX(d.localPosition.dx, width),
          onHorizontalDragUpdate: (d) =>
              _fromLocalX(d.localPosition.dx, width),
          child: SizedBox(
            height: 44,
            width: width,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  width: (width - 20) * t,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                for (var i = 0; i < 5; i++)
                  Positioned(
                    left: 10 + ((width - 20) * (i / 4)) - 3,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= level - 1
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                Positioned(
                  left: (width - 36) * t,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emeraldLight.withValues(alpha: 0.28),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      onboardingToneOptionForLevel(
                        AppLocalizations.of(context)!,
                        level,
                      ).emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
