// Onboarding isim adımı — klavye açıkken Devam üstte kalır.

import 'package:flutter/material.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_flow_chrome.dart';

class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({
    required this.onBack,
    required this.onContinue,
    this.initialName = '',
    this.progress = 0.38,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onContinue;
  final String initialName;
  final double progress;

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  String get _trimmed => _controller.text.trim();
  bool get _canContinue => _trimmed.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canContinue) return;
    widget.onContinue(_trimmed);
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
                  onBack: widget.onBack,
                ),
                const SizedBox(height: 36),
                Text(
                  l10n.surveyNameTitle,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 32,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.onboardingNameSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 24,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.primaryFontFamily,
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: l10n.onboardingNameHint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: AppColors.ornamentGold.withValues(alpha: 0.7),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: AppColors.ornamentGold.withValues(alpha: 0.55),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: AppColors.ornamentGold,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                OnboardingCtaButton(
                  label: '${l10n.onboardingContinue}  →',
                  enabled: _canContinue,
                  onPressed: _canContinue ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
