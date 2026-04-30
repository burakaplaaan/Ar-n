// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageSettingsTitle => 'Language settings';

  @override
  String get languageSettingsSheetTitle => 'App language';

  @override
  String get languageTurkishLabel => 'Turkish';

  @override
  String get languageEnglishLabel => 'English';

  @override
  String get languageArabicLabel => 'Arabic';

  @override
  String get settingsPageHeader => 'Settings';

  @override
  String get settingsSectionAccount => 'Your account';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionPrayerTimes => 'Prayer times';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionSession => 'Session';

  @override
  String get settingsMenuNotificationsSubtitle =>
      'Prayer, purification, and dhikr';

  @override
  String get settingsMenuNotificationsTitle => 'Notifications';

  @override
  String get settingsMenuAboutTitle => 'About';

  @override
  String get settingsMenuAboutSubtitle => 'Application information';

  @override
  String get settingsMenuPrivacyTitle => 'Privacy policy';

  @override
  String get settingsMenuPrivacySubtitle => 'How we process your data';

  @override
  String get settingsMenuSavedTitle => 'Saved';

  @override
  String get settingsMenuSavedSubtitle => 'Quotes you saved in Explore';

  @override
  String get settingsMenuAdminTitle => 'Content management';

  @override
  String get settingsMenuAdminSubtitle => 'Quote pools and Explore';

  @override
  String get settingsMenuContactTitle => 'Contact us';

  @override
  String get settingsMenuContactSubtitle => 'Support and feedback';

  @override
  String get settingsMenuComingSoon => 'Write to us by email';

  @override
  String get settingsContactPageTitle => 'Contact us';

  @override
  String get settingsContactSubtitle =>
      'You can send suggestions, bug reports, or support requests directly by email.';

  @override
  String get settingsContactOpenMailAction => 'Open mail app';

  @override
  String get settingsContactCopyMailAction => 'Copy email address';

  @override
  String get settingsContactEmailCopied => 'Email address copied.';

  @override
  String get settingsContactOpenFailed =>
      'Could not open the mail app. You can copy the address and send manually.';

  @override
  String get settingsContactCopyFailed =>
      'Could not copy the email address. Please enter it manually: arinapphelp@gmail.com';

  @override
  String get settingsContactMailSubject => 'Arin app feedback';

  @override
  String get settingsContactMailBody => 'Hi Arin team,\n\n';

  @override
  String get settingsGuestHint =>
      'Guest mode — your data is stored on this device. Sign in to sync to cloud.';

  @override
  String get settingsAccountFallback => 'Account';

  @override
  String get settingsSignInGoogle => 'Sign in with Google';

  @override
  String get settingsSignInApple => 'Sign in with Apple';

  @override
  String get settingsSessionHint => 'To reset the app or remove your account:';

  @override
  String get settingsSignOutAction => 'Sign out';

  @override
  String get settingsDeleteAccountAction => 'Delete account and all data';

  @override
  String get settingsLightThemeTitle => 'Light theme';

  @override
  String get settingsLightThemeSubtitle =>
      'Softer bright background for easier reading';

  @override
  String get settingsProvinceLabel => 'Province';

  @override
  String get settingsProvinceHint => 'Type; e.g. \"ko\" → Kocaeli';

  @override
  String get settingsProvinceInvalid =>
      'Pick a province from the list or keep typing.';

  @override
  String settingsLocationUpdatedMessage(Object city) {
    return 'Location updated: $city';
  }

  @override
  String get settingsLocationFailedMessage =>
      'Could not get location; check permission or GPS.';

  @override
  String settingsProvinceUpdatedMessage(Object province) {
    return '$province — prayer times updated';
  }

  @override
  String get settingsSignOutDialogTitle => 'Sign out';

  @override
  String get settingsSignOutDialogBody =>
      'The app will reset starting from onboarding slides. All local data on this device will be deleted and your Firebase session will be closed.';

  @override
  String get settingsDialogCancel => 'Cancel';

  @override
  String get settingsDeleteAllDataDialogTitle => 'Delete all data';

  @override
  String get settingsDeleteAllDataDialogBody =>
      'You are in guest mode. All app data on this device will be permanently deleted and you will return to onboarding screens.';

  @override
  String get settingsDeleteAction => 'Delete';

  @override
  String get settingsDeleteAccountDialogTitle => 'Permanently delete account';

  @override
  String get settingsDeleteAccountDialogBody =>
      'Your cloud account will be deleted and all local data on this device will be cleared. This cannot be undone.';

  @override
  String get settingsDeleteProgressMessage =>
      'Deleting your cloud and device data…';

  @override
  String get settingsCloudDeleteFailedMessage =>
      'Cloud data could not be deleted. Check your internet connection and try again.';

  @override
  String get settingsAccountDeleteFailedMessage =>
      'Account could not be deleted.';

  @override
  String get settingsAccountDeleteRetryMessage =>
      'Account could not be deleted. Please try again later.';

  @override
  String get settingsGoogleSignInSuccess => 'Signed in with Google.';

  @override
  String get settingsGoogleSignInCancelled => 'Google sign-in was cancelled.';

  @override
  String get settingsGoogleSignInFailed =>
      'Google sign-in failed. Please try again.';

  @override
  String get settingsAppleSignInSuccess => 'Signed in with Apple.';

  @override
  String get settingsAppleSignInFailed =>
      'Apple sign-in failed. Please try again.';

  @override
  String get settingsAuthServiceUnavailable =>
      'Sign-in service is currently unavailable. Please try again shortly.';

  @override
  String get homeGreetingNight => 'Good night';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingNoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeGuestUser => 'Guest';

  @override
  String homePrayerUrgentSemanticsLabel(Object remaining) {
    return 'Attention, Fajr window is ending. Sunrise in $remaining';
  }

  @override
  String homePrayerNextSemanticsLabel(Object nextName, Object remaining) {
    return 'Next prayer $nextName, remaining $remaining';
  }

  @override
  String get homePrayerUrgentBadge => 'Urgent';

  @override
  String get homePrayerNextBadge => 'Next';

  @override
  String get homePrayerTimesTitle => 'Prayer Times';

  @override
  String get homePrayerNextRowHint => 'Next prayer';

  @override
  String get homePrayerLoadFailedTitle => 'Prayer times couldn\'t load';

  @override
  String get homePrayerLoadFailedBody =>
      'Prayer times may be unavailable due to internet, location permission, or selected district.';

  @override
  String get homeRetryAction => 'Retry';

  @override
  String get homeChangeDistrictAction => 'Change district';

  @override
  String get homeOpenSettingsAction => 'Open settings';

  @override
  String get homeRemainingPassed => 'passed';

  @override
  String get homeRemainingFewSeconds => 'a few seconds';

  @override
  String homeRemainingHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String homeRemainingHoursOnly(int hours) {
    return '$hours h';
  }

  @override
  String homeRemainingMinutesOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String get homeLocationFreshNow => 'Location up to date';

  @override
  String homeLocationFreshMinutesAgo(int minutes) {
    return 'Updated $minutes min ago';
  }

  @override
  String homeLocationFreshHoursAgo(int hours) {
    return 'Updated $hours h ago';
  }

  @override
  String homeLocationFreshDaysAgo(int days) {
    return 'Updated $days day ago';
  }

  @override
  String get homeDailyReminderTitle => 'Today\'s reminder';

  @override
  String get homeNamazSetupTitle => 'Set up prayer tracking';

  @override
  String get homeNamazSetupSubtitle =>
      'Set it up in the Growth tab; once configured, this card appears here automatically.';

  @override
  String get homeNamazTrackingTitle => 'Prayer tracking';

  @override
  String homeNamazTrackingProgressLine(Object done) {
    return 'Today $done/5 · Tap for details';
  }

  @override
  String get onboardingNotificationPermissionDenied =>
      'Notification permission was not granted. You can enable it later from Settings → Notifications for Adhan reminders.';

  @override
  String onboardingGenderPromptWithName(Object name) {
    return '$name, may we ask your gender?';
  }

  @override
  String get onboardingNotificationSkippedWarning =>
      'Notifications stayed off. You won\'t receive Adhan reminders at prayer times — you can enable them later from Settings → Notifications.';

  @override
  String get onboardingOpenNowAction => 'Enable now';

  @override
  String get commonPreview => 'Preview';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDone => 'Done';

  @override
  String get commonBack => 'Back';

  @override
  String get prayerNameImsak => 'Fajr';

  @override
  String get prayerNameSunrise => 'Sunrise';

  @override
  String get prayerNameDhuhr => 'Dhuhr';

  @override
  String get prayerNameAsr => 'Asr';

  @override
  String get prayerNameMaghrib => 'Maghrib';

  @override
  String get prayerNameIsha => 'Isha';

  @override
  String get reminderOff => 'Off';

  @override
  String get reminderAtExactTime => 'At exact time';

  @override
  String reminderMinutesBefore(int minutes) {
    return '$minutes min before';
  }

  @override
  String get reminderCardSubtitle => 'Per-prayer setup · Tap to edit durations';

  @override
  String get reminderFirstOff => '1st off';

  @override
  String reminderFirstValue(Object value) {
    return '1st $value';
  }

  @override
  String reminderPairSecondOff(Object first) {
    return '$first · 2nd off';
  }

  @override
  String reminderPairSecondValue(Object first, Object second) {
    return '$first · 2nd $second';
  }

  @override
  String get reminderPermissionRequiredMessage =>
      'Notification permission is required. You can enable it from Settings.';

  @override
  String get reminderPrayerNotificationTitle => 'Prayer notifications';

  @override
  String get reminderCardDisabledHint =>
      'Off · Enable the switch and set times';

  @override
  String get reminderLocalNotificationUnavailable =>
      'Local notifications are unavailable in this environment.';

  @override
  String get reminderSectionTitle => 'Reminder';

  @override
  String get reminderTwoAlertsPerPrayer => 'Two alerts per prayer';

  @override
  String get reminderPerPrayerDifferentSounds => 'Different sounds per prayer';

  @override
  String reminderCurrentSound(Object summary) {
    return 'Current: $summary';
  }

  @override
  String get reminderUsePhoneDefaultSubtitle =>
      'Uses the notification sound configured in phone settings.';

  @override
  String get reminderChooseArinSoundsTitle => 'Choose from Arin sounds';

  @override
  String get reminderChooseArinSoundsSubtitle =>
      'Listen to Adhan and calm tones, then apply.';

  @override
  String get reminderPhoneSoundActiveAllPrayers =>
      'The phone-selected sound is active for all prayers.';

  @override
  String get reminderApplyOwnSoundAllPrayers =>
      'Apply your own audio file to all prayers.';

  @override
  String get reminderSetPerPrayerDifferentSound =>
      'Set different sounds per prayer';

  @override
  String get reminderAllPrayersSoundTitle => 'Sound for all prayers';

  @override
  String get reminderAllPrayersSoundSubtitle =>
      'Make one selection to play the same sound for all prayers.';

  @override
  String get reminderBackToSingleSoundSelection =>
      'Back to single sound selection';

  @override
  String get reminderPerPrayerSavedInstantly =>
      'Per-prayer selections are saved instantly.';

  @override
  String get reminderEnableNotificationsAction => 'Enable notifications';

  @override
  String get reminderDurationsPerPrayerTitle => 'Durations for each prayer';

  @override
  String get reminderDurationsPerPrayerSubtitle =>
      'Tap a row to choose the 1st and 2nd alerts separately.';

  @override
  String reminderDualAlertTitle(Object prayerTitle) {
    return 'Two alerts — $prayerTitle';
  }

  @override
  String get reminderDualAlertSubtitle =>
      '1st alert: Off, exact time, or minutes before. 2nd alert: Off or minutes before.';

  @override
  String get reminderFirstAlertTitle => '1st alert';

  @override
  String get reminderSecondAlertTitle => '2nd alert';

  @override
  String get prayerSoundPickerTitle => 'Notification sound';

  @override
  String get prayerSoundQuickAllSubtitle =>
      'Pick one sound first; if needed, split by prayer in advanced settings.';

  @override
  String get prayerSoundApplyAllButton => 'Apply selected sound to all prayers';

  @override
  String get prayerSoundAdvancedToggle => 'Advanced settings (per prayer)';

  @override
  String get prayerSoundAppliedAllSuccess =>
      'Selected sound applied to all prayers.';

  @override
  String get prayerSoundSystem => 'Phone default sound';

  @override
  String get prayerSoundAdhanTurkish => 'Adhan — Turkish cut (10s, from start)';

  @override
  String get prayerSoundAdhanDubai =>
      'Adhan — Dubai / Ramadan (9s, from start)';

  @override
  String get prayerSoundAmbientFlute => 'Calm — flute texture (6s, from start)';

  @override
  String get prayerSoundAmbientPianoGuitar =>
      'Calm — piano & guitar (7s, from start)';

  @override
  String get prayerSoundAmbientEthereal =>
      'Calm — ethereal voices (10s, from start)';

  @override
  String get prayerSoundPickFromPhone => 'Pick sound from phone';

  @override
  String get prayerSoundClearUserFile => 'Remove';

  @override
  String get prayerSoundUserFromPhone => 'Sound selected from phone';

  @override
  String get prayerSoundUserFileActiveHint =>
      'This prayer currently uses the file selected from your phone. If you choose a catalog sound, the file is removed.';

  @override
  String get prayerSoundSubtitlePerPrayer =>
      'Per prayer: phone default, catalog tone, or your own file from phone. Save by applying.';

  @override
  String get prayerSoundImportFailed =>
      'Could not import audio file. Try another file or format (WAV, M4A...).';

  @override
  String get prayerSoundPreviewSystem =>
      'No preview available — your device default notification sound is used.';

  @override
  String get commonStart => 'Start';

  @override
  String get commonRestart => 'Restart';

  @override
  String get willpowerHabitNotFound => 'Habit not found';

  @override
  String get namazProgramHomeHintActive =>
      'Prayer tracking is active. It now appears on the Home card as well.';

  @override
  String get namazProgramPageTitle => 'Worship';

  @override
  String get namazProgramVerseQuote =>
      '\"Surely hearts find peace in the remembrance of Allah.\"\n(Surah Ar-Ra\'d, 13:28 — translation)';

  @override
  String get namazProgramBreathingBreak => 'Breathing break';

  @override
  String get namazProgramTodayPrayersTitle => 'Today\'s prayers';

  @override
  String namazProgramTodayProgress(int done) {
    return '$done/5 completed';
  }

  @override
  String namazProgramPercentDone(int percent) {
    return '%$percent completed';
  }

  @override
  String get namazProgramSystemNotificationSettings =>
      'System notification settings';

  @override
  String get namazProgramRecentDaysTitle => 'Recent days';

  @override
  String get namazProgramRecentDaysSubtitle =>
      'Each box shows prayers completed that day (e.g. 3/5).';

  @override
  String get breathingPhaseInhale => 'Inhale';

  @override
  String get breathingPhaseHold => 'Hold';

  @override
  String get breathingPhaseExhale => 'Exhale';

  @override
  String breathingCycleProgress(int current, int total) {
    return 'Cycle $current/$total';
  }

  @override
  String get breathingFinishAction => 'Finish';

  @override
  String breathingSecondsLabel(int seconds) {
    return '$seconds sec';
  }

  @override
  String get breathingIntroTitle => '4-7-8 Breathing Therapy';

  @override
  String get breathingIntroSubtitle =>
      'A slow-paced breathing routine that helps reduce stress and anxiety.';

  @override
  String breathingIntroCycles(int cycles) {
    return '$cycles cycles';
  }

  @override
  String get breathingIntroApproxMinutes => '~2 min';

  @override
  String get breathingPhaseHintInhale => 'seconds inhale';

  @override
  String get breathingPhaseHintHold => 'seconds hold';

  @override
  String get breathingPhaseHintExhale => 'seconds exhale';

  @override
  String get breathingSessionCompleteTitle => 'Session complete';

  @override
  String breathingSessionCompleteSubtitle(int cycles) {
    return '$cycles cycles completed. You can do one more round or exit.';
  }

  @override
  String get breathingBottomHint =>
      'While holding, heart rhythm slows down; continue at a comfortable pace. Stop if you feel dizzy.';

  @override
  String get quitProgramNotFound => 'Program not found';

  @override
  String get quitOnboardingCommitmentMinLengthError =>
      'Please write a promise to yourself (at least 8 characters).';

  @override
  String get quitOnboardingQuickStartTitle => 'Start the counter now';

  @override
  String get quitOnboardingQuickStartBody =>
      'Your counter will start from this moment. You can complete your pledge later from the program.';

  @override
  String get quitOnboardingAbortAction => 'Cancel';

  @override
  String get quitOnboardingExitDraftTitle => 'Exit setup?';

  @override
  String get quitOnboardingExitDraftBody =>
      'Your progress in this setup round will not be saved. You can start again later.';

  @override
  String get quitOnboardingStayAction => 'Stay';

  @override
  String get quitOnboardingExitAction => 'Exit';

  @override
  String get quitOnboardingContentLoadFailed =>
      'Setup content failed to load. Please try again.';

  @override
  String get quitOnboardingAppBarTitle => 'Setup';

  @override
  String get quitOnboardingSealTitlePrefix => 'Seal your promise';

  @override
  String get quitOnboardingSealHoldHint => 'Press and hold';

  @override
  String get quitOnboardingContinueAction => 'Continue';

  @override
  String get quitOnboardingQuickStartInlineAction =>
      'Start the counter now, complete the program later';

  @override
  String get quitOnboardingCommitmentTitle => 'Your promise to yourself';

  @override
  String get quitOnboardingCommitmentSubtitle =>
      'Keep it short and clear; you can edit it before sealing.';

  @override
  String get quitOnboardingCommitmentHint => 'Starting today…';

  @override
  String get quitOnboardingExamplesSectionTitle => 'Example sentences';

  @override
  String get quitProgramRestartTitle => 'Restart';

  @override
  String get quitProgramRestartPrompt =>
      'The counter will reset. What should happen to your history?';

  @override
  String get quitProgramRestartKeepHistoryTitle => 'Keep history';

  @override
  String get quitProgramRestartKeepHistorySubtitle =>
      'The counter starts from zero; your previous attempt, daily marks, and stats are preserved.';

  @override
  String get quitProgramRestartWipeTitle => 'Start from scratch';

  @override
  String get quitProgramRestartWipeSubtitle =>
      'All historical daily marks are deleted too. This cannot be undone.';

  @override
  String quitProgramElapsedHms(int hours, int minutes, int seconds) {
    return '$hours h $minutes min $seconds sec';
  }

  @override
  String quitProgramElapsedMs(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String quitProgramElapsedS(int seconds) {
    return '$seconds sec';
  }

  @override
  String get quitProgramTabProgress => 'Progress';

  @override
  String get quitProgramTabTips => 'Tips';

  @override
  String get quitProgramTipsLoadFailed => 'Content failed to load';

  @override
  String get quitProgramTipsWatermark => 'هِدَايَة';

  @override
  String get quitProgramTipsHeroTitle => 'Guidance';

  @override
  String get quitProgramTipsHeroSubtitle =>
      'Awareness, patience, and practical suggestions to make your path gentler.';

  @override
  String get quitProgramDaysUpper => 'DAYS';

  @override
  String get quitProgramStartNowAction => 'I quit from this moment';

  @override
  String get quitProgramStatFullDays => 'Full days';

  @override
  String get quitProgramDash => '—';

  @override
  String get quitProgramStatTimer => 'Timer';

  @override
  String quitProgramElapsedSinceQuitDays(int days) {
    return 'Elapsed: $days days (since quit moment)';
  }

  @override
  String get quitProgramTasksTitle => 'Tasks';

  @override
  String get quitProgramTasksSubtitle =>
      'You progress as you complete day milestones.';

  @override
  String get quitProgramUiCounterSubtitleGeneric => 'clean streak';

  @override
  String get quitProgramUiMetricsSectionTitleGeneric => 'Progress indicators';

  @override
  String get quitProgramUiDisclaimerGeneric =>
      'These indicators are for motivation only.';

  @override
  String get quitProgramUiEncouragementGeneric =>
      'Every clean day matters; steady small steps create major transformation.';

  @override
  String get quitProgramUiClockHintGeneric =>
      'When you tap, timer and indicators continue from this moment.';

  @override
  String get quitProgramMotivationStageStart =>
      'The most valuable step of day one is simply to begin.';

  @override
  String get quitProgramMotivationStageWeek =>
      'In the first week, patience matters; small steps lead to big change.';

  @override
  String get quitProgramMotivationStageMonth =>
      'As you approach one month, keep going with steady patience.';

  @override
  String get quitProgramMotivationStageQuarter =>
      'Around three months, consistency starts to show visible fruit.';

  @override
  String get quitProgramMotivationStageLong =>
      'In the long run, every clean day is a meaningful gain.';

  @override
  String get quitMetricSmokingLung => 'Lungs / breathing';

  @override
  String get quitMetricSmokingHeart => 'Cardiovascular';

  @override
  String get quitMetricSmokingTeethMouth => 'Teeth and mouth';

  @override
  String get quitMetricSmokingSmellTaste => 'Smell and taste';

  @override
  String get quitMetricScreenFocusDepth => 'Focus and depth';

  @override
  String get quitMetricScreenSleepRhythm => 'Sleep rhythm';

  @override
  String get quitMetricScreenAwareness => 'Screen awareness';

  @override
  String get quitMetricScreenInnerCalm => 'Inner calm';

  @override
  String get quitMetricAlcoholLiverRecovery => 'Liver recovery';

  @override
  String get quitMetricAlcoholSleepStability => 'Sleep stability';

  @override
  String get quitMetricAlcoholMoodBalance => 'Mood balance';

  @override
  String get quitMetricAlcoholClarity => 'Mental clarity';

  @override
  String get quitMetricSubstanceBodyBalance => 'Body balance';

  @override
  String get quitMetricSubstanceSleepRhythm => 'Sleep rhythm';

  @override
  String get quitMetricSubstanceUrgeControl => 'Urge control';

  @override
  String get quitMetricSubstanceSupportTracking => 'Support and follow-up';

  @override
  String get quitMetricZinaDiscipline => 'Self-discipline';

  @override
  String get quitMetricZinaBoundaryStrength => 'Boundary strength';

  @override
  String get quitMetricZinaHeartCalm => 'Heart calm';

  @override
  String get quitMetricZinaTawbaDirection => 'Repentance direction';

  @override
  String get quitMilestone1Title => 'First breath';

  @override
  String get quitMilestone1Subtitle => 'One clean day';

  @override
  String get quitMilestone2Title => 'First streak';

  @override
  String get quitMilestone2Subtitle => '48 hours';

  @override
  String get quitMilestone3Title => 'Three days';

  @override
  String get quitMilestone3Subtitle => 'Peak craving is passing';

  @override
  String get quitMilestone5Title => 'Five days';

  @override
  String get quitMilestone5Subtitle => 'Routine is breaking';

  @override
  String get quitMilestone7Title => 'One week';

  @override
  String get quitMilestone7Subtitle => 'First week completed';

  @override
  String get quitMilestone10Title => 'Ten days';

  @override
  String get quitMilestone10Subtitle => 'Willpower is strengthening';

  @override
  String get quitMilestone14Title => 'Two weeks';

  @override
  String get quitMilestone14Subtitle => 'Perception is recovering';

  @override
  String get quitMilestone21Title => 'Three weeks';

  @override
  String get quitMilestone21Subtitle => 'Habit loop is shifting';

  @override
  String get quitMilestone30Title => 'One month';

  @override
  String get quitMilestone30Subtitle => 'Major threshold';

  @override
  String get quitMilestone45Title => 'Forty-five days';

  @override
  String get quitMilestone45Subtitle => 'Rhythm is settling';

  @override
  String get quitMilestone60Title => 'Two months';

  @override
  String get quitMilestone60Subtitle => 'Body adapts';

  @override
  String get quitMilestone66Title => 'Habit master';

  @override
  String get quitMilestone66Subtitle => '66-day line';

  @override
  String get quitMilestone90Title => 'Three months';

  @override
  String get quitMilestone90Subtitle => 'Noticeable health period';

  @override
  String get quitMilestone120Title => 'Four months';

  @override
  String get quitMilestone120Subtitle => 'Badge of determination';

  @override
  String get quitMilestone180Title => 'Six months';

  @override
  String get quitMilestone180Subtitle => 'Half a year';

  @override
  String get quitMilestone270Title => 'Nine months';

  @override
  String get quitMilestone270Subtitle => 'Long haul';

  @override
  String get quitMilestone365Title => 'One year';

  @override
  String get quitMilestone365Subtitle => 'Great glad tidings';

  @override
  String get quitMilestone500Title => 'Five hundred days';

  @override
  String get quitMilestone500Subtitle => 'Crown of perseverance';

  @override
  String get quitMilestone730Title => 'Two years';

  @override
  String get quitMilestone730Subtitle => 'Deep transformation';

  @override
  String get quitMilestone1000Title => 'One thousand days';

  @override
  String get quitMilestone1000Subtitle => 'Exceptional level';

  @override
  String get quitMilestoneInspiration365 =>
      '\"Indeed, the patient will be given their reward without measure.\" (Az-Zumar, 10)';

  @override
  String get quitMilestoneInspiration90 =>
      '\"Who is with Allah is never truly alone.\"';

  @override
  String get quitMilestoneInspiration30 =>
      '\"When you decide, then put your trust in Allah.\" (Aal Imran, 159)';

  @override
  String get quitMilestoneInspiration7 =>
      '\"With hardship comes ease.\" (Ash-Sharh, 6)';

  @override
  String get quitMilestoneInspiration1 =>
      '\"Surely with every hardship comes ease.\" (Ash-Sharh, 5)';

  @override
  String quitMilestoneElapsedSummary(int days, Object subtitle) {
    return '$days days clean — $subtitle';
  }

  @override
  String get quitMilestoneContinueAction => 'Continue';

  @override
  String get quitProgramCompleteCommitmentTitle => 'Complete your pledge';

  @override
  String get quitProgramCompleteCommitmentSubtitle =>
      'Your counter is running — seal your program with the promise you wrote for yourself.';

  @override
  String get willpowerHubBreathingExerciseTitle => 'Breathing exercise';

  @override
  String get willpowerHubBreathingExerciseSubtitle =>
      'Slow breathing helps soften your body during stress.';

  @override
  String get willpowerHubArchiveHabitDialogTitle => 'Permanently delete habit';

  @override
  String get willpowerHubArchiveHabitDialogBody =>
      'This record and its related progress data are permanently deleted. This cannot be undone.';

  @override
  String get willpowerHubArchiveAction => 'Delete permanently';

  @override
  String get willpowerHubHeaderTitle => 'Growth & Purification';

  @override
  String get willpowerHubNoActiveHabits => 'No active habits yet';

  @override
  String willpowerHubActiveHabits(int count) {
    return '$count active habits';
  }

  @override
  String get willpowerHubHabitCalendarTooltip => 'Habit calendar';

  @override
  String get willpowerHubTabBuild => 'Growth';

  @override
  String get willpowerHubTabQuit => 'Purification';

  @override
  String get willpowerHubQuitCtaEarly =>
      'Every clean minute returns as oxygen to your heart and lungs.';

  @override
  String get willpowerHubQuitCtaOngoing =>
      'The first days are hard; your body has already started healing.';

  @override
  String get willpowerHubBuildCtaEarly =>
      'Starting with small steps is enough.';

  @override
  String get willpowerHubBuildCtaOngoing =>
      'Your routine is working well; keep going.';

  @override
  String get willpowerHubSummaryQuitLabel => 'PURIFICATION';

  @override
  String get willpowerHubSummaryTodayLabel => 'TODAY';

  @override
  String get willpowerHubSummaryCounterProgress => 'counter progress';

  @override
  String get willpowerHubSummaryCompleted => 'completed';

  @override
  String get willpowerHubInsightTagSpiritual => 'SPIRITUAL';

  @override
  String get willpowerHubInsightTagHealth => 'HEALTH';

  @override
  String get willpowerHubAddFirstBuild => 'Add your first growth habit';

  @override
  String get willpowerHubAddFirstQuit => 'Add your first purification habit';

  @override
  String get willpowerHubBuildEmptyTitle => 'Your growth area is still empty';

  @override
  String get willpowerHubBuildEmptySubtitle =>
      'Maintaining a beneficial habit is one of the simplest paths to spiritual growth.';

  @override
  String get willpowerHubKazaLabelSabah => 'Fajr';

  @override
  String get willpowerHubKazaLabelOgle => 'Dhuhr';

  @override
  String get willpowerHubKazaLabelIkindi => 'Asr';

  @override
  String get willpowerHubKazaLabelAksam => 'Magh';

  @override
  String get willpowerHubKazaLabelYatsi => 'Isha';

  @override
  String get willpowerHubKazaLabelVitir => 'Witr';

  @override
  String get willpowerHubKazaTrackingTitle => 'Qada tracking';

  @override
  String get willpowerHubKazaRemainingLabel => 'remaining';

  @override
  String get willpowerHubRemoveCardTooltip => 'Remove card';

  @override
  String get willpowerHubHideKazaDialogTitle => 'Remove qada card?';

  @override
  String get willpowerHubHideKazaDialogBody =>
      'This card is hidden from the Growth screen. Account and counter data stay on device; you can add it again from the Routine workshop.';

  @override
  String get willpowerHubRemoveAction => 'Remove';

  @override
  String get willpowerHubQuitEmptyTitle =>
      'Your purification area is still empty';

  @override
  String get willpowerHubQuitEmptySubtitle =>
      'Giving up a harmful habit is a powerful way to discipline the self.';

  @override
  String get willpowerHubPeriodPrefixWeek => 'This week ';

  @override
  String get willpowerHubPeriodPrefixMonth => 'This month ';

  @override
  String willpowerHubPercentTargetReached(Object prefix) {
    return '${prefix}You reached the target percentage.';
  }

  @override
  String willpowerHubPercentProgressStatus(
    Object prefix,
    int progress,
    int left,
  ) {
    return '$prefix%$progress completed, %$left left.';
  }

  @override
  String willpowerHubTargetPending(Object prefix) {
    return '${prefix}Target pending.';
  }

  @override
  String willpowerHubUnitTargetAddPrompt(
    Object prefix,
    int target,
    Object unit,
  ) {
    return '$prefix$target $unit target — tap the card to add.';
  }

  @override
  String willpowerHubUnitProgressTargetFilled(
    Object prefix,
    int progress,
    Object unit,
  ) {
    return '$prefix$progress $unit done; target is full.';
  }

  @override
  String willpowerHubUnitProgressRemaining(
    Object prefix,
    int progress,
    Object unit,
    int left,
  ) {
    return '${prefix}You completed $progress $unit, $left $unit left.';
  }

  @override
  String willpowerHubUnitTargetDoneSuper(
    Object prefix,
    int target,
    Object unit,
  ) {
    return '$prefix$target $unit complete — great.';
  }

  @override
  String willpowerHubUnitProgressDidRemaining(
    Object prefix,
    int progress,
    Object unit,
    int left,
  ) {
    return '${prefix}You did $progress $unit, $left $unit left.';
  }

  @override
  String get willpowerHubAddEditHint => 'Tap card to add or edit';

  @override
  String get willpowerHubQuitStatusSetupMissing => 'Setup missing';

  @override
  String get willpowerHubQuitStatusClockRunning => 'Counter running';

  @override
  String get willpowerHubQuitStatusProgramReady => 'Program ready';

  @override
  String get willpowerHubTapCardForDetails => 'Tap card for details';

  @override
  String get willpowerHubCompleteSetup => 'Complete setup';

  @override
  String get willpowerHubStartClockHint =>
      'Start the counter from “I quit from this moment” in the program';

  @override
  String get willpowerHubStreakSeriesLabel => 'streak';

  @override
  String get willpowerHubStreakDaySeriesLabel => 'day streak';

  @override
  String get qiblaHubCompassTitle => 'Find the Qibla direction';

  @override
  String get qiblaHubCompassSubtitle =>
      'Show the Kaaba direction using compass and location';

  @override
  String get qiblaHubOpenAction => 'Open';

  @override
  String get qiblaHubZikirTitle => 'Dhikr Counter';

  @override
  String get qiblaHubZikirFeatureSubtitle =>
      'Digital counter with dhikr details, round history, and target (33/99)';

  @override
  String get qiblaHubBreathingTitle => 'Breathing Exercise';

  @override
  String get qiblaHubBreathingSubtitle =>
      'Calm down and refocus with the 4-7-8 breathing cycle';

  @override
  String get qiblaHubHealingTitle => 'Healing Frequencies';

  @override
  String get qiblaHubHealingSubtitle =>
      'A calming session with therapy tones, ambience, and sleep timer';

  @override
  String get generalLoading => 'Loading...';

  @override
  String get settingsPrivacyPageTitle => 'Privacy Policy';

  @override
  String get settingsPrivacyLastUpdated => 'Last updated: 26.04.2026';

  @override
  String get settingsPrivacyIntro =>
      'Arin respects your privacy. This text explains which data is processed, why it is processed, and how you can manage these processes.';

  @override
  String get settingsPrivacyDataCollectedTitle => 'Processed data';

  @override
  String get settingsPrivacyDataCollectedBody =>
      'Depending on your usage and permissions, Arin may process location data for prayer times and qibla features, notification preferences, account details when you sign in, and app diagnostics data.';

  @override
  String get settingsPrivacyUsageTitle => 'Why we process data';

  @override
  String get settingsPrivacyUsageBody =>
      'Data is processed to calculate prayer times, show qibla direction, schedule reminders, preserve your settings, and improve app stability.';

  @override
  String get settingsPrivacyStorageTitle => 'Storage and retention';

  @override
  String get settingsPrivacyStorageBody =>
      'Most habit, zikr, and preference data is stored on your device. If you sign in, selected data may be synced with Firebase services. Data is kept until you delete it in the app or remove your account.';

  @override
  String get settingsPrivacyThirdPartyTitle => 'Third-party services';

  @override
  String get settingsPrivacyThirdPartyBody =>
      'Arin uses Firebase Authentication, Cloud Firestore, Firebase Analytics, and Firebase Crashlytics for sign-in, data sync, usage analytics, and crash diagnostics.';

  @override
  String get settingsPrivacyControlsTitle => 'User control';

  @override
  String get settingsPrivacyControlsBody =>
      'You can disable location and notification permissions from device settings, sign out from Settings, or delete your account and local data.';

  @override
  String get settingsPrivacyChildrenTitle => 'Children\'s privacy';

  @override
  String get settingsPrivacyChildrenBody =>
      'Arin is not designed for children under 13.';

  @override
  String get settingsPrivacyContactTitle => 'Contact';

  @override
  String get settingsPrivacyContactBody =>
      'For privacy questions: arinapphelp@gmail.com';

  @override
  String get notificationsHubTitle => 'Notifications';

  @override
  String get notificationsHubHeadline => 'Reminder center';

  @override
  String get notificationsHubSubhead =>
      'Prayer, purification, and zikr — all in one place.';

  @override
  String get notificationsPermissionGranted => 'Granted';

  @override
  String get notificationsPermissionDenied => 'Disabled';

  @override
  String get notificationsPermissionLimited => 'Limited';

  @override
  String get notificationsOpenOsSettings => 'System notification settings';

  @override
  String get notificationsGateNotification => 'Notifications';

  @override
  String get notificationsGateExactAlarm => 'Exact alarm';

  @override
  String get notificationsGateBattery => 'Battery exemption';

  @override
  String get notificationsGateAllGood => 'Reminders are triggered on time.';

  @override
  String get notificationsGateMissing =>
      'One or more permissions are missing — scheduled notifications may be delayed or never arrive.';

  @override
  String get notificationsGateRequestExact => 'Enable exact alarm permission';

  @override
  String get notificationsGateRequestBattery => 'Ignore battery optimization';

  @override
  String get notificationsDiagnosticsQueuedLabel =>
      'Queued scheduled reminders';

  @override
  String get notificationsSectionGeneral => 'General';

  @override
  String get notificationsSectionPrayer => 'Prayer times';

  @override
  String get notificationsSectionArinma => 'Purification and habits';

  @override
  String get notificationsPrayerRowTitle => 'Time and sound';

  @override
  String get notificationsPrayerOnSubtitle =>
      'Prayer notifications are on — tap to edit';

  @override
  String get notificationsPrayerOffSubtitle =>
      'Prayer notifications are off — tap to enable';

  @override
  String get notificationsPrayerDetailTitle => 'Prayer notifications';

  @override
  String get notificationsPrayerDetailSubtitle =>
      'Separate timing and sound per prayer; main toggle is below.';

  @override
  String get notificationsArinmaDailyTitle => 'Daily reminder';

  @override
  String get notificationsArinmaDailySubtitle =>
      'Twice a day, a random quote or short motivation.';

  @override
  String get notificationsMilestoneTitle => 'Milestone notifications';

  @override
  String get notificationsMilestoneSubtitle =>
      'For example, sparse messages like 24 hours or 1 week on your quit journey.';

  @override
  String get notificationsTaskTitle => 'Task reminder';

  @override
  String get notificationsTaskSubtitle =>
      'At most one alert per day for incomplete tasks.';

  @override
  String get notificationsZikirTitle => 'Zikr reminder';

  @override
  String get notificationsZikirSubtitle =>
      'At your chosen time, a short reminder with your latest zikr text.';

  @override
  String get notificationsZikirTimeLabel => 'Zikr time';

  @override
  String get notificationsZikirTimePickerTitle => 'Zikr time';

  @override
  String get notificationsZikirTimePickerSubtitle =>
      'A daily reminder at this time with your latest zikr text.';

  @override
  String get notificationsHealthDisclaimer =>
      'Texts about health and purification are for general information and do not replace treatment. If you have a condition, consult your doctor.';

  @override
  String get notificationsNextReminderToday => 'today';

  @override
  String get notificationsNextReminderTomorrow => 'tomorrow';

  @override
  String get notificationsNextReminderUnderMinute => '< 1 min';

  @override
  String notificationsNextReminderMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String notificationsNextReminderHoursOnly(int hours) {
    return '$hours h';
  }

  @override
  String notificationsNextReminderHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String notificationsNextReminderLine(
    Object dayLabel,
    Object clock,
    Object gap,
  ) {
    return 'Next reminder: $dayLabel $clock · in $gap';
  }

  @override
  String get aboutArinHeadline => 'Beside your path';

  @override
  String get aboutArinSubhead =>
      'A small companion offering gentle reminders for your prayer, routine, and day';

  @override
  String get aboutArinParagraph1 =>
      'ARIN exists to help you keep your prayers on time, continue habits that are good for you, and slowly leave difficult patterns behind. Our goal is not pressure; we stay by your side as calm little reminders in busy days.';

  @override
  String get aboutArinParagraph2 =>
      'Sometimes the road is long, sometimes the day is full. That is why we offer a simple flow and clear reminders. We want to hear every point that feels missing or wrong; we are open to improving it together.';

  @override
  String get aboutArinParagraph3 =>
      'Small steps are the most effective in the long run. We hope you see ARIN as a peaceful companion that does not rush you and does not leave your path; may your day feel calm and light.';

  @override
  String get aboutArinClosingWish => 'Wishing you beneficial use';

  @override
  String languageChangedMessage(Object languageName) {
    return 'Language changed: $languageName';
  }

  @override
  String get adminIdentityBadge => 'ADMIN';

  @override
  String get adminPoolsHint =>
      'Select a pool, edit it, and save. Advanced operations are grouped below.';

  @override
  String adminPoolsDropdownLabel(int count) {
    return 'Pool ($count items)';
  }

  @override
  String get adminAdvancedActionsTitle => 'Advanced actions';

  @override
  String get adminBackupCurrentPoolJson => 'Back up this pool (JSON)';

  @override
  String get adminRestoreFromBackup => 'Restore from backup';

  @override
  String get adminWritingInProgress => 'Writing…';

  @override
  String get adminResetCompletely => 'Reset completely';

  @override
  String adminVersionLabel(Object version) {
    return 'Version: v$version';
  }

  @override
  String adminSearchInPoolHint(int count) {
    return 'Search in pool ($count records)';
  }

  @override
  String get adminAddAction => 'Add';

  @override
  String get adminAddMissingRecords => 'Add missing records';

  @override
  String get adminPoolLabelHomeNamazWisdom => 'Home prayer card';

  @override
  String get adminPoolLabelPersonalizedQuotes => 'Personalized quotes';

  @override
  String get adminPoolLabelWidgetQuote => 'Widget / home screen quote';

  @override
  String get adminPoolLabelZikirDailyReflections =>
      'Prayer time card (dhikr reflection)';

  @override
  String get adminPoolLabelHealingComfort => 'Healing / comfort quotes';

  @override
  String get adminPoolLabelHubGelisimIslamic => 'Growth — Islamic card';

  @override
  String get adminPoolLabelHubGelisimMedical => 'Growth — health card';

  @override
  String get adminPoolLabelHubArinmaIslamic => 'Purification — Islamic card';

  @override
  String get adminPoolLabelHubArinmaMedical => 'Purification — health card';

  @override
  String get adminPoolLabelNotificationArinmaBodies =>
      'Purification notification texts';

  @override
  String adminSearchResultsCount(int count) {
    return '$count results';
  }

  @override
  String get adminPoolEmptyHint => 'This pool is empty — you can add an item.';

  @override
  String get adminSearchNoResults => 'No results match your search.';

  @override
  String get adminTapToEdit => 'Tap to edit';

  @override
  String get adminEditTooltip => 'Edit';

  @override
  String adminInspireHint(int count) {
    return 'Add a card, fill in the text, then save. Background images: $count.';
  }

  @override
  String get adminInspireAddNewCard => 'Add new card';

  @override
  String get adminRefreshFromFirestore => 'Refresh from Firestore';

  @override
  String adminInspireVersionCards(Object version, int count) {
    return 'Version: v$version · $count cards';
  }

  @override
  String get adminInspireNoCardsYet => 'No Explore cards yet';

  @override
  String get adminInspireAddFirstCard => 'Add first card';

  @override
  String adminInspireCardLabel(int index) {
    return 'Card $index';
  }

  @override
  String get adminInspireEmptyTextBadge => 'Empty text';

  @override
  String get adminInspireDuplicateTooltip => 'Duplicate';

  @override
  String get adminInspireShuffleDesignTooltip => 'Shuffle design';

  @override
  String adminInspireEmptyTextPreview(int index) {
    return '(empty text — #$index)';
  }

  @override
  String adminInspireImageNumberLabel(Object index) {
    return 'Image #$index';
  }

  @override
  String get adminInspireContentKindLabel => 'Content type';

  @override
  String get adminInspireContentKindQuote => 'Quote';

  @override
  String get adminInspireContentKindVerse => 'Verse';

  @override
  String get adminInspireContentKindHadith => 'Hadith';

  @override
  String get adminInspireShowInMainFeedTitle => 'Show in main feed (Mixed)';

  @override
  String get adminInspireShowInMainFeedSubtitle =>
      'If unchecked, it appears only in Verse or Hadith filters.';

  @override
  String get adminInspireTurkishTextLabel => 'Turkish text *';

  @override
  String get adminOptionalArabicLabel => 'Arabic (optional)';

  @override
  String get adminOptionalSourceLabel => 'Source (optional)';

  @override
  String get adminOptionalVerseRefLabel => 'Verse / surah (optional)';

  @override
  String get adminInspireSaveAllChanges => 'Save all card changes';

  @override
  String get adminDiagnosticsHint =>
      'Automatic notification diagnostics. Logs here capture scheduling attempts.';

  @override
  String get adminDiagnosticsStatusSummaryTitle => 'Status summary';

  @override
  String get adminDiagnosticsEnabled => 'on';

  @override
  String get adminDiagnosticsDisabled => 'off';

  @override
  String adminDiagnosticsPrayerStatus(Object status) {
    return 'Prayer: $status';
  }

  @override
  String adminDiagnosticsDailyStatus(Object status) {
    return 'Daily: $status';
  }

  @override
  String adminDiagnosticsMilestoneStatus(Object status) {
    return 'Milestone: $status';
  }

  @override
  String adminDiagnosticsTaskStatus(Object status) {
    return 'Task: $status';
  }

  @override
  String adminDiagnosticsZikirStatus(Object status) {
    return 'Dhikr: $status';
  }

  @override
  String adminDiagnosticsPendingQueue(int count) {
    return 'Pending queue: $count';
  }

  @override
  String get adminRefreshAction => 'Refresh';

  @override
  String get adminDiagnosticsExportLog => 'Export log';

  @override
  String get adminDiagnosticsClearLog => 'Clear log';

  @override
  String adminDiagnosticsRecentEvents(int count) {
    return 'Recent events ($count)';
  }

  @override
  String get adminDiagnosticsNoLogsHint =>
      'No logs yet. Reopen the app, use it for a while, then refresh.';

  @override
  String get adminDiagnosticsOutcomeOk => 'ok';

  @override
  String get adminDiagnosticsOutcomeError => 'error';

  @override
  String get adminDiagnosticsOutcomeCooldownSkip => 'skipped (cooldown)';

  @override
  String get adminDiagnosticsOutcomePendingGuardSkip =>
      'skipped (pending guard)';

  @override
  String get adminDiagnosticsOutcomeDisabled => 'disabled';

  @override
  String get adminDiagnosticsOutcomeInvalidPayloadSkip =>
      'skipped (invalid payload)';

  @override
  String adminDiagnosticsOutcomeUnknown(Object outcome) {
    return 'unknown ($outcome)';
  }

  @override
  String get adminDevOffsetSavedAndRescheduled =>
      'Offset saved; notifications rescheduled.';

  @override
  String get adminDevOffsetReset => 'Offset reset.';

  @override
  String get adminDevOffsetDisabled => 'Off (API times)';

  @override
  String adminDevOffsetForwardMinutes(int minutes) {
    return 'Earlier: $minutes min';
  }

  @override
  String adminDevOffsetBackwardMinutes(int minutes) {
    return 'Later: $minutes min';
  }

  @override
  String get adminDevPrayerOffsetTitle =>
      'Prayer time offset (this device only)';

  @override
  String get adminDevPrayerOffsetSubtitle =>
      'Negative values shift all times earlier (notifications follow). API/server values are unchanged.';

  @override
  String get adminDevResetAction => 'Reset';

  @override
  String get adminDevSaveAndRescheduleAction => 'Save and reschedule';

  @override
  String get adminDevNotificationTestsTitle => 'Notification tests';

  @override
  String get adminDevNotificationTestsSubtitle =>
      'Use this to instantly test current channel and sound paths.';

  @override
  String get adminDevPrayerNotificationSent => 'Prayer notification sent.';

  @override
  String get adminDevPrayerNotificationNowAction => 'Prayer notification (now)';

  @override
  String get adminDevAppNotificationSent => 'App notification sent.';

  @override
  String get adminDevAppNotificationNowAction =>
      'Purification / app notification (now)';

  @override
  String get adminDevCrashlyticsTestTitle => 'Crash report test (Crashlytics)';

  @override
  String get adminDevCrashlyticsDebugHint =>
      'Debug build: collection is OFF. Install a release APK to test.';

  @override
  String get adminDevCrashlyticsReleaseHint =>
      'Buttons below send a real error to Firebase Console → Crashlytics. Remove after confirming the report appears.';

  @override
  String get adminFirebaseNotReady => 'Firebase is not ready.';

  @override
  String get adminDevCrashlyticsNonFatalSent =>
      'Non-fatal record sent. It should appear in Console in a few minutes.';

  @override
  String adminErrorWithReason(Object reason) {
    return 'Error: $reason';
  }

  @override
  String get adminDevSendNonFatalTestAction => 'Test: send non-fatal error';

  @override
  String get adminDevCrashNowFatalAction => 'Test: crash app NOW (fatal)';

  @override
  String get adminDevCrashDialogTitle => 'Crash the app?';

  @override
  String get adminDevCrashDialogBody =>
      'The app will close in a few seconds. When reopened on the phone, the report is uploaded to Firebase (visible in Console a few minutes later).\n\nUse only to verify Crashlytics.';

  @override
  String get adminDevCrashAction => 'Crash';

  @override
  String get adminDiagnosticsTitle => 'Diagnostics';

  @override
  String get adminDevPlatformLabel => 'Platform';

  @override
  String get adminDevBuildLabel => 'Build';

  @override
  String get adminDevBuildModeRelease => 'release';

  @override
  String get adminDevBuildModeProfile => 'profile';

  @override
  String get adminDevBuildModeDebug => 'debug';

  @override
  String get adminDevPlatformWeb => 'web';

  @override
  String get adminDevPlatformUnknown => 'unknown';

  @override
  String get adminDevUidLabel => 'UID';

  @override
  String get adminDevPendingNotificationLabel => 'Pending notifications';

  @override
  String get adminDevTapToRefresh => 'tap to refresh';

  @override
  String get adminDiagnosticsError => 'error';

  @override
  String get adminPoolDataUnavailable => 'Pool data is currently unavailable.';

  @override
  String get adminPoolChangeAction => 'Pool change';

  @override
  String get adminReviewBeforeSaveTitle => 'Review before saving';

  @override
  String get adminPoolSaved => 'Pool saved.';

  @override
  String get adminPoolSaveFailed => 'Pool could not be saved.';

  @override
  String get adminUseSeedAllForPool => 'Use “Seed all pools” for this pool.';

  @override
  String get adminNoBuiltInSeedForPool =>
      'No built-in seed is defined for this pool.';

  @override
  String get adminSeedSelectedPoolDefaults => 'Reset selected pool to defaults';

  @override
  String get adminPoolNotLoadedYet => 'Pool is not loaded yet.';

  @override
  String adminPoolBackupShareText(Object poolId, Object timestamp) {
    return 'Arin pool backup — $poolId ($timestamp)';
  }

  @override
  String get adminPoolBackupShareSubject => 'Arin pool backup';

  @override
  String adminBackupCreationFailed(Object error) {
    return 'Backup could not be created: $error';
  }

  @override
  String get adminBackupInvalidJsonObject =>
      'Backup file could not be read: JSON object expected.';

  @override
  String get adminBackupPoolDocumentMissing =>
      'Pool document was not found in backup file.';

  @override
  String get adminBackupItemsListMissing =>
      '\"items\" list is missing in backup file.';

  @override
  String get adminBackupContainsUnreadableRecords =>
      'Backup contains unreadable records; file may have been modified.';

  @override
  String get adminUnknownPool => 'unknown pool';

  @override
  String get adminRestoreBackupTitle => 'Restore backup';

  @override
  String adminRestoreBackupDialogBody(
    Object fileName,
    Object sourcePool,
    Object selectedPool,
    int itemCount,
    Object warningText,
  ) {
    return 'File: $fileName\nPool in backup: $sourcePool\nSelected pool: $selectedPool\nRecord count: $itemCount\n\n${warningText}These records will be written to the selected pool. Continue?';
  }

  @override
  String get adminRestoreBackupDifferentPoolWarning =>
      'Warning: backup is from a different pool.';

  @override
  String adminRestoreFromBackupAction(Object fileName) {
    return 'Restore from backup ($fileName)';
  }

  @override
  String get adminRestoreBackupFailed => 'Backup file could not be restored.';

  @override
  String get adminRequiresManagerOrFullAccessForMissingSeed =>
      'Manager or full access is required to add missing records.';

  @override
  String get adminRequiresFullAccessForReset =>
      'Full access is required for full reset.';

  @override
  String get adminBulkPreviewFailed =>
      'Bulk operation preview could not be fetched.';

  @override
  String get adminSeedAllPoolsTitle => 'Seed all pools';

  @override
  String adminMergeSeedPreview(
    int poolCount,
    int changedPoolCount,
    int addedItemCount,
    int targetItemCount,
  ) {
    return 'Preview:\n• Checked pools: $poolCount\n• Changed pools: $changedPoolCount\n• Items to add: $addedItemCount\n• Total items after operation: $targetItemCount\n\nManual changes are preserved. Continue?';
  }

  @override
  String adminResetSeedPreview(
    int poolCount,
    int changedPoolCount,
    int currentItemCount,
    int targetItemCount,
  ) {
    return 'Preview:\n• Checked pools: $poolCount\n• Pools to overwrite: $changedPoolCount\n• Current items: $currentItemCount\n• New items: $targetItemCount\n\nCurrent content will be removed. Make sure you backed up first. Continue?';
  }

  @override
  String get adminOverwriteAction => 'Overwrite';

  @override
  String get adminMissingItemsAddedToPools =>
      'Missing items were added to pools.';

  @override
  String get adminAllPoolsOverwritten => 'All pools were overwritten.';

  @override
  String get adminAuditAddMissingToAllPools =>
      'Add missing entries to all pools';

  @override
  String get adminAuditResetAllPools => 'Reset all pools';

  @override
  String get adminInspireCardsUnavailable =>
      'Explore cards are currently unavailable.';

  @override
  String get adminRequiresManagerOrFullAccessForDiagnostics =>
      'Manager or full access is required for diagnostics actions.';

  @override
  String get adminNotificationLogsCleared => 'Notification logs cleared.';

  @override
  String adminNotificationLogsShareText(Object timestamp) {
    return 'Arin notification logs ($timestamp)';
  }

  @override
  String get adminNotificationLogsShareSubject =>
      'Arin notification diagnostics';

  @override
  String adminLogExportFailed(Object error) {
    return 'Log export failed: $error';
  }

  @override
  String get adminInspireCardHasEmptyTurkishText =>
      'There is a card with empty Turkish text; fill it or delete it.';

  @override
  String get adminReviewCardsBeforeSaveTitle => 'Review before saving cards';

  @override
  String get adminInspireCardsWillBeUpdated => 'Explore cards will be updated';

  @override
  String get adminInspireCardsSaved => 'Explore cards saved.';

  @override
  String get adminInspireCardsSaveFailed => 'Explore cards could not be saved.';

  @override
  String get adminAuditInspireCardsUpdated => 'Explore cards were updated';

  @override
  String adminCurrentRecordCount(int count) {
    return 'Current records: $count';
  }

  @override
  String adminRecordCountToSave(int count) {
    return 'Records to save: $count';
  }

  @override
  String adminChangedRowCount(int count) {
    return 'Changed rows: $count';
  }

  @override
  String get adminConcurrentEditWarning =>
      'If another admin saved meanwhile, the system will show a warning.';

  @override
  String get adminSaveAction => 'Save';

  @override
  String get adminGrantsListFetchFailed => 'Grant list could not be fetched.';

  @override
  String get adminGrantAccessAction => 'Grant access';

  @override
  String get adminEditGrantAction => 'Edit grant';

  @override
  String get adminEmailOrUidLabel => 'Email or UID';

  @override
  String get adminLevelLabel => 'Level';

  @override
  String get adminRoleContentLabel => 'content - content';

  @override
  String get adminRoleManagerLabel => 'manager - operations';

  @override
  String get adminRoleDeveloperLabel => 'developer - full access';

  @override
  String get adminFullAccessRequiredForGrantManagement =>
      'Full access is required for grant management.';

  @override
  String get adminEmailOrUidCannotBeEmpty => 'Email or UID cannot be empty.';

  @override
  String get adminAccountAlreadyFullAccess =>
      'This account already has full access in-app.';

  @override
  String get adminGrantSaved => 'Grant saved.';

  @override
  String get adminGrantSaveFailed => 'Grant could not be saved.';

  @override
  String get adminAuditGrantSaved => 'Admin grant was added/updated';

  @override
  String get adminFullAccessAccountCannotBeRemoved =>
      'This account has in-app full access and cannot be removed from panel.';

  @override
  String get adminRemoveGrantTitle => 'Remove grant';

  @override
  String adminRemoveGrantMessage(Object label) {
    return 'Management access will be removed for $label.';
  }

  @override
  String get adminGrantRemoved => 'Grant removed.';

  @override
  String get adminGrantRemoveFailed => 'Grant could not be removed.';

  @override
  String get adminAuditGrantRemoved => 'Admin grant was removed';

  @override
  String get adminEditItemTitle => 'Edit item';

  @override
  String get adminAddItemTitle => 'Add item';

  @override
  String get adminWordLabel => 'Quote';

  @override
  String get adminTextLabel => 'Text';

  @override
  String get adminTurkishTextLabel => 'Turkish text';

  @override
  String get adminTurkishLabel => 'Turkish';

  @override
  String get adminArabicLabel => 'Arabic';

  @override
  String get adminTypeLabel => 'Type';

  @override
  String get adminReferenceLabel => 'Reference';

  @override
  String get adminTitleLabel => 'Title';

  @override
  String get adminOptionalSourceReferenceLabel =>
      'Source / reference (optional)';

  @override
  String get adminWordCannotBeEmpty => 'Quote cannot be empty.';

  @override
  String get adminTextCannotBeEmpty => 'Text cannot be empty.';

  @override
  String get adminTurkishTextCannotBeEmpty => 'Turkish text cannot be empty.';

  @override
  String get adminTurkishAndArabicRequired =>
      'Turkish and Arabic fields are required.';

  @override
  String get adminTurkishArabicReferenceRequired =>
      'Turkish, Arabic, and reference are required.';

  @override
  String get adminTitleAndTextRequired => 'Title and text are required.';

  @override
  String get adminPoolItemWillBeEdited => 'Pool item will be edited';

  @override
  String get adminNewPoolItemWillBeAdded => 'A new item will be added to pool';

  @override
  String get adminVersionConflictError =>
      'This content was updated by another admin. Please refresh and try again.';

  @override
  String get adminNoPermissionForOperation =>
      'You do not have permission for this operation.';

  @override
  String get adminNetworkOrServiceUnavailable =>
      'Internet connection is weak or service is temporarily unavailable.';

  @override
  String get adminOperationTimedOut => 'Operation timed out. Please try again.';

  @override
  String get adminSessionCouldNotBeVerified =>
      'Session could not be verified. Please sign in again.';

  @override
  String get adminAuthorizationCouldNotBeVerified =>
      'Authorization could not be verified';

  @override
  String get adminAuthorizationCheckUnavailable =>
      'Authorization check is currently unavailable.\nCheck your internet connection and try again.';

  @override
  String get adminBackToSettings => 'Back to settings';

  @override
  String get adminNoAccessTitle => 'No access';

  @override
  String get adminPageForAdminsOnly => 'This page is for admins only.';

  @override
  String get adminPanelTitle => 'Admin panel';

  @override
  String get adminPoolsTab => 'Pools';

  @override
  String get adminInspireCardsTab => 'Explore cards';

  @override
  String get adminDiagnosticsTab => 'Diagnostics & logs';

  @override
  String get adminDeveloperTab => 'Developer';

  @override
  String get adminGrantsTab => 'Grants';

  @override
  String get adminSectionOnlyForFullAccess =>
      'This section is available only with full access.';

  @override
  String get adminDeveloperToolsDeveloperOnly =>
      'Developer tools are available only for developer level.';

  @override
  String get adminDeletePoolItemTitle => 'Delete item from pool';

  @override
  String adminDeletePoolItemMessage(Object poolId) {
    return 'This item will be permanently deleted from pool \"$poolId\" and written to Firestore immediately. It cannot be undone.';
  }

  @override
  String get adminPoolItemWillBeDeleted => 'Pool item will be deleted';

  @override
  String get adminRemoveCardFromListTitle => 'Remove card from list';

  @override
  String get adminRemoveCardFromListMessage =>
      'Card will be removed from local list. Press \"Save\" for changes to sync to Firestore.';

  @override
  String get adminRemoveAction => 'Remove';

  @override
  String get adminDiagnosticsAccessDeniedTitle =>
      'Diagnostics screen is available to manager and full access roles.';

  @override
  String get adminDiagnosticsAccessDeniedSubtitle =>
      'Content managers can edit pools and Explore.';

  @override
  String get adminRoleContentPlain => 'Content';

  @override
  String get adminRoleManagerPlain => 'Manager';

  @override
  String get adminRoleDeveloperPlain => 'Developer';

  @override
  String get adminRoleNonePlain => 'None';

  @override
  String get adminGrantManagementAccessDeniedTitle =>
      'Grant management is available only with full access.';

  @override
  String get adminGrantManagementAccessDeniedSubtitle =>
      'Granting/removing admin levels can be done by developer role.';

  @override
  String get adminGrantHint =>
      'Enter an email or UID to grant content, manager, or developer level.';

  @override
  String adminFixedFullAccess(Object emails) {
    return 'Fixed full-access accounts: $emails';
  }

  @override
  String adminDefinedGrants(int count) {
    return 'Defined grants ($count)';
  }

  @override
  String get adminGrantsLoading => 'Loading grants...';

  @override
  String get adminNoFirestoreGrantsYet =>
      'No grants added through Firestore yet.';

  @override
  String get surveyBack => 'Back';

  @override
  String get surveyNext => 'Continue';

  @override
  String get namazIbadetWarningTitle => 'Attention';

  @override
  String get namazIbadetWarningSubtitle =>
      'Prayer tracking is not for show; it is for organizing your heart with humility and honesty.';

  @override
  String get namazIbadetWarningBullet1 =>
      'Mark checks only for yourself; do not let it become a tool of showing off or pressure on others.';

  @override
  String get namazIbadetWarningBullet2 =>
      'If you miss a prayer time, do not belittle yourself; every return is repentance and a fresh start.';

  @override
  String get namazIbadetWarningBullet3 =>
      'You can manage notifications anytime from system settings; tracking should not become a burden.';

  @override
  String get namazIbadetCommitmentTitle => 'Your promise to yourself';

  @override
  String get namazIbadetCommitmentHint =>
      'Write a sincere sentence about your prayer (at least 8 characters).';

  @override
  String get namazIbadetCommitmentFieldHint => 'A sentence from your heart...';

  @override
  String get namazIbadetCommitmentTooShort =>
      'Please write a promise to yourself (at least 8 characters).';

  @override
  String get namazIbadetSealTitlePrefix => 'Seal your promise';

  @override
  String get namazIbadetSealHoldHint => 'Hold your finger down';

  @override
  String get namazIbadetSealSuccess =>
      'Your promise is saved. Moving to the worship screen.';

  @override
  String get namazIbadetSealEncourageNotHolding =>
      'When ready, hold the seal to reinforce your promise.';

  @override
  String get namazIbadetSealEncourageHolding =>
      'Slow your breath and let your promise settle in your heart.';

  @override
  String get namazIbadetPrepTitle => 'Preparation';

  @override
  String get namazIbadetExamplesTitle => 'Examples';

  @override
  String get closeAction => 'Close';

  @override
  String get saveAction => 'Save';

  @override
  String get selectAction => 'Select';

  @override
  String get quitPickerTemplateAlreadyExists =>
      'This program is already in your list; only one item per template is allowed.';

  @override
  String get quitPickerOpenAction => 'Open';

  @override
  String get quitPickerGoToListAction => 'Go to list';

  @override
  String get quitPickerTemplateScreenTitle => 'Quit screen addiction';

  @override
  String get quitPickerTemplateSmokingTitle => 'Quit smoking';

  @override
  String get quitPickerTemplateAlcoholTitle => 'Quit alcohol';

  @override
  String get quitPickerTemplateSubstanceTitle => 'Quit substance use';

  @override
  String get quitPickerTemplateZinaTitle => 'Quit zina';

  @override
  String get quitPickerHeaderTitle => 'Purify from harmful habits';

  @override
  String get quitPickerHeaderSubtitle =>
      'Select the habit you want to leave; use the box below for a custom goal.';

  @override
  String get quitPickerScreenLabel => 'Screen';

  @override
  String get quitPickerScreenSubtitle => 'Boundaries and calm';

  @override
  String get quitPickerSmokingLabel => 'Smoking';

  @override
  String get quitPickerAlcoholLabel => 'Alcohol';

  @override
  String get quitPickerSubstanceLabel => 'Substance';

  @override
  String get quitPickerSubstanceSubtitle => 'Support and tracking';

  @override
  String get quitPickerZinaLabel => 'Zina';

  @override
  String get quitPickerDefaultSubtitle => 'Purification program';

  @override
  String get quitPickerAlreadyAdded => 'Already added';

  @override
  String get quitPickerAddCustomTitle => 'Add custom';

  @override
  String get quitPickerAddCustomSubtitle =>
      'Build your own purification routine.';

  @override
  String get buildProgramSetupQuranTitle => 'Daily Qur\'an program';

  @override
  String get buildProgramSetupDefaultTitle => 'Program';

  @override
  String get buildProgramSetupHeadlineQuran => 'One page each day';

  @override
  String get buildProgramSetupHeadlineDefault => 'Start your program';

  @override
  String get buildProgramSetupBadge => 'Preparation step';

  @override
  String get buildProgramSetupBodyQuran =>
      'At least one page — small but consistent. Progress and tips are waiting on the next screen.';

  @override
  String get buildProgramSetupBodyDefault =>
      'Progress and tips are waiting on the next screen.';

  @override
  String get buildProgramSetupAlreadyActive =>
      'Your daily Qur\'an program is already active. Redirected to the existing program.';

  @override
  String get buildProgramSetupQuranHabitTitle => 'Daily Qur\'an';

  @override
  String get buildProgramSetupStartAction => 'Start program';

  @override
  String get buildProgramSetupPrincipleTitle =>
      'Small and consistent is better than much then abandoned';

  @override
  String get buildProgramSetupPrincipleQuote =>
      'Prophet Muhammad (peace be upon him): \"The deeds most beloved to Allah are those done regularly, even if they are small.\"';

  @override
  String get buildProgramDetailNotFound => 'Program not found';

  @override
  String get buildProgramDetailTabGeneral => 'General';

  @override
  String get buildProgramDetailTabTips => 'Tips';

  @override
  String get buildProgramDetailTabProgress => 'Progress';

  @override
  String get buildProgramDetailTodayQuestion =>
      'Did you complete today\'s reading goal?';

  @override
  String get buildProgramDetailTodayDone => 'Completed today';

  @override
  String get buildProgramDetailTodayPending => 'Not marked yet today — tap';

  @override
  String buildProgramDetailDayCount(int days) {
    return 'Day $days';
  }

  @override
  String get buildProgramDetailProgressIndicatorLabel =>
      'Motivational progress indicator';

  @override
  String buildProgramDetailRoutinePercent(int percent) {
    return '$percent% routine alignment';
  }

  @override
  String buildProgramDetailMilestoneLabel(int day, int percent) {
    return 'Day $day — $percent%';
  }

  @override
  String get buildProgramDetailDisclaimer =>
      'These indicators are for general motivation and are not scientific or medical measurements.';

  @override
  String get onboardingSlide1Title => 'A breath inside the noise';

  @override
  String get onboardingSlide1Subtitle =>
      'When your mind is racing, your inner voice often becomes a whisper. Small pauses — one breath, one brief stop — revive spiritual balance; the peace you seek outside sometimes first grows quietly within.';

  @override
  String get onboardingSlide2Title => 'Start small, grow with consistency';

  @override
  String get onboardingSlide2Subtitle =>
      'Track your habits in Growth and Purification. One day, one breath, one choice — keep the chain unbroken; purification is like climbing stairs, getting stronger step by step.';

  @override
  String get onboardingSlide3Title => 'Prayer time and daily rhythm';

  @override
  String get onboardingSlide3Subtitle =>
      'Keep prayer times close; let breathing exercises and growth tools stay with you in difficult moments. Bring your worship, tracking, and inner voice into the same rhythm.';

  @override
  String get onboardingSlide4Title => 'Arin: together in one app';

  @override
  String get onboardingSlide4Subtitle =>
      'From inspiration to daily habits, from prayer alerts to purification counters, your journey is here. If you are ready, let\'s begin together — you walk, we remind and accompany.';

  @override
  String get onboardingGetStarted => 'Let\'s start';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get surveyNameTitle => 'How should we address you?';

  @override
  String get surveyNameHint => 'Your name';

  @override
  String get surveyGenderTitle => 'May we ask your gender?';

  @override
  String get surveyGenderSubtitle => 'To help you better...';

  @override
  String get surveyGenderMale => 'Male';

  @override
  String get surveyGenderFemale => 'Female';

  @override
  String get surveyMoodTitle =>
      'Which tone is strongest in your inner world right now?';

  @override
  String get surveyMoodSubtitle =>
      'Select signs that describe you; content and reminders adapt accordingly.';

  @override
  String get surveyDailyRhythmTitle =>
      'Where does most of your day usually flow?';

  @override
  String get surveyDailyRhythmSubtitle =>
      'Your pace and environment help us understand your best rhythm.';

  @override
  String get surveyInnerThemesTitle => 'Which inner themes stand out for you?';

  @override
  String get surveyInnerThemesSubtitle =>
      'You can select more than one; sincere signals help us know you better.';

  @override
  String get surveyNotificationTitle => 'Notifications';

  @override
  String get surveyNotificationLead =>
      'Let prayer reminders and daily messages reach you on time.';

  @override
  String get surveyNotificationSubtitle =>
      'We need notification permission so prayer alerts and content suggestions are not missed. You can turn it off anytime in settings.';

  @override
  String get surveyNotificationAllow => 'Allow notifications';

  @override
  String get surveyNotificationSkip => 'Skip for now';

  @override
  String get surveyNotificationOpenSettings => 'Open settings';

  @override
  String get surveySave => 'Start ➔';

  @override
  String get surveyGenderDecline => 'I prefer not to share';

  @override
  String get surveyNameGreetingPrefix => 'Hello';

  @override
  String get surveySummaryTitle => 'You are ready';

  @override
  String get surveySummarySubtitle =>
      'We saved your core preferences. We will shape your Arin experience with these signals.';

  @override
  String get surveySummaryCardTitle => 'Getting started summary';

  @override
  String get surveySummaryItemName => 'Name';

  @override
  String get surveySummaryItemMood => 'Mood signals';

  @override
  String get surveySummaryItemRhythm => 'Daily rhythm signals';

  @override
  String get surveySummaryItemThemes => 'Inner theme signals';

  @override
  String get surveySummaryItemNotificationOn => 'On';

  @override
  String get surveySummaryItemNotificationOff => 'Off';

  @override
  String get surveySummaryNotProvided => 'Not provided';

  @override
  String get surveySummaryAction => 'Go to home';

  @override
  String get surveySummarySaveError =>
      'Could not save start data. Please try again.';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodStressed => 'Stressed';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodGrateful => 'Grateful';

  @override
  String get moodAnxious => 'Anxious';

  @override
  String get moodMotivated => 'Motivated';

  @override
  String get sectorStudent => 'High school / University / Prep';

  @override
  String get sectorPrivate => 'Private sector';

  @override
  String get sectorPublic => 'Public sector';

  @override
  String get sectorBusiness => 'Own business / Freelance';

  @override
  String get sectorTrade => 'Trade';

  @override
  String get sectorHousehold => 'Homemaker';

  @override
  String get sectorOther => 'Other';

  @override
  String get needMotivation => 'Motivation';

  @override
  String get needSabr => 'Patience';

  @override
  String get needShukr => 'Gratitude';

  @override
  String get needTawakkul => 'Trust in God';

  @override
  String get needFocus => 'Focus';

  @override
  String get needHealing => 'Healing';

  @override
  String get needRizq => 'Provision & Blessing';

  @override
  String get appPrepareTitle => 'Preparing Arin for you';

  @override
  String get appPrepareSubtitle =>
      'Prayer times and daily wisdom are loading for you...';

  @override
  String get shellExitConfirmBackTwice => 'Press back once more to exit';

  @override
  String get inspireExploreTitle => 'Explore';

  @override
  String get inspireSearchHint => 'Search';

  @override
  String get inspireFilterTooltip => 'Content type';

  @override
  String get inspireFilterMainFeed => 'Main feed';

  @override
  String get inspireFilterQuote => 'Quote';

  @override
  String get inspireFilterVerse => 'Verse';

  @override
  String get inspireFilterHadith => 'Hadith';

  @override
  String get inspireSearchNoResults =>
      'No content matches this search.\nTry another word or an unaccented form.';

  @override
  String get inspireEmptyTitle => 'No content yet';

  @override
  String get inspireEmptySubtitle =>
      'Images: assets/inspiration/ (1.jpg, 2.jpg, ...).\nContent: assets/data/inspiration/*.json or Firestore app_public/inspiration_cards.';

  @override
  String get inspirePullToRefreshHint => 'Pull down to refresh.';

  @override
  String get inspireLoadFailedTitle => 'Could not load';

  @override
  String get inspirePullToRetryHint => 'Pull down to try again.';

  @override
  String get viewerBackAction => 'Back';

  @override
  String get viewerNoCard => 'No card';

  @override
  String get asyncErrorDefaultTitle => 'Something went wrong';

  @override
  String get asyncErrorDefaultMessage =>
      'Your connection may be weak or the service is currently unreachable. Please try again shortly.';

  @override
  String get asyncErrorRetryAction => 'Retry';

  @override
  String get asyncErrorTechnicalDetailsTitle => 'Technical details';

  @override
  String get asyncErrorCopiedToClipboard => 'Error copied to clipboard.';

  @override
  String get savedInspirationTitle => 'Saved';

  @override
  String get savedInspirationLoadFailedPrefix => 'Could not load';

  @override
  String get savedInspirationEmptyTitle => 'Your heart journal is empty';

  @override
  String get savedInspirationEmptySubtitle =>
      'Save quotes that touch you in Explore; let them gather here and return to you.';

  @override
  String get savedInspirationGoExploreAction => 'Go to Explore';

  @override
  String get clockPickerCancelAction => 'Cancel';

  @override
  String get clockPickerConfirmAction => 'OK';

  @override
  String get clockPickerHourLabel => 'Hour';

  @override
  String get clockPickerMinuteLabel => 'Minute';

  @override
  String get salatWeekCelebrationTitle => 'You completed the week';

  @override
  String get salatWeekCelebrationAction => 'Alhamdulillah';

  @override
  String get adminEmailInviteLabel => 'Email invite';
}
