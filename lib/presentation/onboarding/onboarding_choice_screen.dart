import 'dart:async';

import 'package:flutter/material.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../shared/widgets/arin_pressable.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';

class OnboardingChoiceOption {
  const OnboardingChoiceOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class OnboardingChoiceScreen extends StatefulWidget {
  const OnboardingChoiceScreen({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.onBack,
    required this.onContinue,
    this.progress = 0.58,
    this.initialId,
    this.autoAdvance = false,
    this.centered = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<OnboardingChoiceOption> options;
  final VoidCallback onBack;
  final ValueChanged<String> onContinue;
  final double progress;
  final String? initialId;
  final bool autoAdvance;
  final bool centered;

  static const autoAdvanceDelay = Duration(milliseconds: 220);

  @override
  State<OnboardingChoiceScreen> createState() => _OnboardingChoiceScreenState();
}

class _OnboardingChoiceScreenState extends State<OnboardingChoiceScreen> {
  String? _selected;
  bool _advancing = false;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialId;
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _onSelect(String id) {
    if (_advancing) return;
    setState(() => _selected = id);
    if (!widget.autoAdvance) return;
    _advancing = true;
    _advanceTimer = Timer(OnboardingChoiceScreen.autoAdvanceDelay, () {
      if (!mounted) return;
      widget.onContinue(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final align = widget.centered ? TextAlign.center : TextAlign.start;
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
                const SizedBox(height: 28),
                Text(
                  widget.title,
                  textAlign: align,
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
                  widget.subtitle,
                  textAlign: align,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.56),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final option = widget.options[index];
                      final selected = option.id == _selected;
                      return _ChoiceTile(
                        option: option,
                        selected: selected,
                        onTap: () => _onSelect(option.id),
                      );
                    },
                  ),
                ),
                if (!widget.autoAdvance) ...[
                  const SizedBox(height: 12),
                  OnboardingCtaButton(
                    label: '${l10n.onboardingContinue}  →',
                    enabled: _selected != null,
                    onPressed: _selected == null
                        ? null
                        : () => widget.onContinue(_selected!),
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

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OnboardingChoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ArinPressable(
      onTap: onTap,
      scale: 0.975,
      sink: 1.6,
      child: Material(
        color: Colors.white.withValues(alpha: selected ? 0.10 : 0.055),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.emeraldMid.withValues(
                    alpha: selected ? 0.42 : 0.28,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.ornamentGold
                        : Colors.white.withValues(alpha: 0.32),
                    width: 1.6,
                  ),
                  color: selected
                      ? AppColors.ornamentGold.withValues(alpha: 0.22)
                      : Colors.transparent,
                ),
                child: selected
                    ? const Icon(
                        Icons.circle,
                        size: 10,
                        color: AppColors.ornamentGold,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
