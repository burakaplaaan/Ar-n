import 'package:arin/l10n/app_localizations.dart';

class OnboardingStruggleNoteCopy {
  const OnboardingStruggleNoteCopy({
    required this.title,
    required this.hint,
    required this.suggestion,
  });

  final String title;
  final String hint;
  final String suggestion;

  static OnboardingStruggleNoteCopy resolve({
    required AppLocalizations l10n,
    required String name,
    required String struggleId,
  }) {
    switch (struggleId) {
      case 'delay':
        return OnboardingStruggleNoteCopy(
          title: l10n.onboardingNoteTitleDelay(name),
          hint: l10n.onboardingNoteHintDelay,
          suggestion: l10n.onboardingNoteSuggestionDelay,
        );
      case 'lonely':
        return OnboardingStruggleNoteCopy(
          title: l10n.onboardingNoteTitleLonely(name),
          hint: l10n.onboardingNoteHintLonely,
          suggestion: l10n.onboardingNoteSuggestionLonely,
        );
      case 'impatience':
        return OnboardingStruggleNoteCopy(
          title: l10n.onboardingNoteTitleImpatience(name),
          hint: l10n.onboardingNoteHintImpatience,
          suggestion: l10n.onboardingNoteSuggestionImpatience,
        );
      case 'regret':
        return OnboardingStruggleNoteCopy(
          title: l10n.onboardingNoteTitleRegret(name),
          hint: l10n.onboardingNoteHintRegret,
          suggestion: l10n.onboardingNoteSuggestionRegret,
        );
      case 'anxiety':
      default:
        return OnboardingStruggleNoteCopy(
          title: l10n.onboardingNoteTitleAnxiety(name),
          hint: l10n.onboardingNoteHintAnxiety,
          suggestion: l10n.onboardingNoteSuggestionAnxiety,
        );
    }
  }
}

class OnboardingToneOption {
  const OnboardingToneOption({
    required this.level,
    required this.emoji,
    required this.label,
  });

  final int level;
  final String emoji;
  final String label;
}

List<OnboardingToneOption> onboardingToneOptions(AppLocalizations l10n) {
  return [
    OnboardingToneOption(
      level: 1,
      emoji: '😌',
      label: l10n.onboardingToneCalm,
    ),
    OnboardingToneOption(
      level: 2,
      emoji: '🙂',
      label: l10n.onboardingToneLight,
    ),
    OnboardingToneOption(
      level: 3,
      emoji: '😐',
      label: l10n.onboardingToneMid,
    ),
    OnboardingToneOption(
      level: 4,
      emoji: '😟',
      label: l10n.onboardingToneHeavy,
    ),
    OnboardingToneOption(
      level: 5,
      emoji: '😖',
      label: l10n.onboardingToneVeryHeavy,
    ),
  ];
}

OnboardingToneOption onboardingToneOptionForLevel(
  AppLocalizations l10n,
  int level,
) {
  final options = onboardingToneOptions(l10n);
  final clamped = level.clamp(1, 5);
  return options[clamped - 1];
}
