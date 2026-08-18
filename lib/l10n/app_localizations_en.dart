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
  String get settingsMenuSupportTitle => 'Support Arin';

  @override
  String get settingsMenuSupportSubtitle => 'One-time support packs';

  @override
  String get settingsMenuComingSoon => 'Write to us by email';

  @override
  String get settingsContactPageTitle => 'Contact us';

  @override
  String get settingsContactSubtitle =>
      'You can send suggestions, bug reports, or support requests directly by email. Please also include your phone’s brand and model.';

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
  String settingsContactMailBody(Object device) {
    return 'Hi Arin team,\n\nDevice (brand and model): $device\n\n';
  }

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
  String get homeRequestLocationAction => 'Allow location';

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
  String get reminderApplyDurationsAllButton =>
      'Apply selected durations to all prayers';

  @override
  String get reminderAllPrayersDurationTarget => 'All prayers';

  @override
  String get reminderDurationsAppliedAllSuccess =>
      'Durations applied to all prayers.';

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
  String quitProgramElapsedDHms(int days, int hours, int minutes, int seconds) {
    return '$days d $hours h $minutes min $seconds sec';
  }

  @override
  String quitProgramElapsedMdHms(
    int months,
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$months mo $days d $hours h $minutes min $seconds sec';
  }

  @override
  String quitProgramElapsedYmdHms(
    int years,
    int months,
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$years y $months mo $days d $hours h $minutes min $seconds sec';
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
  String get qiblaHubAssistantTitle => 'Arın Assistant';

  @override
  String get qiblaHubAssistantSubtitle =>
      'Chat; manage prayer, alerts, and reminders';

  @override
  String get assistantTitle => 'Arın Assistant';

  @override
  String get assistantSubtitle => '';

  @override
  String get assistantAskChip => 'Assistant';

  @override
  String get assistantInputHint => 'Write briefly…';

  @override
  String get assistantEmptyTitle => 'Assalamu alaikum!';

  @override
  String get assistantEmptyBody => 'I am an Islamic AI.';

  @override
  String get assistantHello => 'Assalamu alaikum!';

  @override
  String assistantHelloName(String name) {
    return 'Assalamu alaikum! $name';
  }

  @override
  String get assistantPromptLockVerse =>
      'How do I put a verse on the lock screen?';

  @override
  String get assistantPromptInshirah => 'Explain Surah Ash-Sharh.';

  @override
  String get assistantPromptRamadan => 'How many days until Ramadan?';

  @override
  String get assistantNeedSignIn => 'Sign in to use the assistant.';

  @override
  String get assistantNeedPremium => 'Arın Assistant is for Premium.';

  @override
  String get assistantGateHint =>
      'Sign in and unlock Premium to start a written chat. Conversations are not saved.';

  @override
  String get assistantOpenPremium => 'Open Premium';

  @override
  String get assistantSignIn => 'Sign in';

  @override
  String get assistantGenericError =>
      'The assistant could not reply right now.';

  @override
  String get assistantQuotaReached => 'Today’s message limit is used up.';

  @override
  String get assistantMessageTooLong =>
      'Shorten the message (100 characters max).';

  @override
  String get assistantNotReady => 'The assistant is not ready yet.';

  @override
  String assistantWordCount(int count, int max) {
    return '$count/$max characters';
  }

  @override
  String assistantRemainingToday(int count) {
    return '$count left';
  }

  @override
  String get assistantActionFailed => 'I could not do that.';

  @override
  String get assistantActionUnknownPage => 'I could not open that page.';

  @override
  String get assistantNavigatingThere => 'Opening it now.';

  @override
  String get assistantLockVerseGuide =>
      'You can do this in Arın. Open Settings → Widget Center and add the lock-screen verse. You do not need another app.';

  @override
  String assistantRamadanDays(String today, int days, String date) {
    return 'Today is $today. There are $days days until Ramadan. Approximate start: $date; the crescent may shift it by a day.';
  }

  @override
  String assistantRamadanTomorrow(String today, String date) {
    return 'Today is $today. Ramadan starts tomorrow (about $date).';
  }

  @override
  String assistantRamadanToday(String today) {
    return 'Today is $today. Ramadan starts today.';
  }

  @override
  String assistantRamadanOngoing(String today, int day) {
    return 'Today is $today. We are in Ramadan; it is day $day.';
  }

  @override
  String get assistantPrayerTimesMissing =>
      'Prayer times are not ready yet. Turn on location and wait a moment.';

  @override
  String assistantPrayerCountdown(String label, String remaining, String time) {
    return '$label $remaining. Time: $time.';
  }

  @override
  String assistantPrayerCountdownTomorrow(
    String label,
    String remaining,
    String time,
  ) {
    return '$label $remaining. Tomorrow at $time.';
  }

  @override
  String get assistantPrayerLabelIftar => 'Until iftar:';

  @override
  String get assistantPrayerLabelImsak => 'Until imsak:';

  @override
  String get assistantPrayerLabelDhuhr => 'Until Dhuhr:';

  @override
  String get assistantPrayerLabelAsr => 'Until Asr:';

  @override
  String get assistantPrayerLabelMaghrib => 'Until Maghrib:';

  @override
  String get assistantPrayerLabelIsha => 'Until Isha:';

  @override
  String assistantPrayerLabelNext(String name) {
    return 'Until the next prayer ($name):';
  }

  @override
  String assistantDurationHm(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String assistantDurationH(int hours) {
    return '${hours}h';
  }

  @override
  String assistantDurationM(int minutes) {
    return '${minutes}m';
  }

  @override
  String get assistantDurationSoon => 'less than a minute';

  @override
  String get assistantActionCancelled => 'Cancelled.';

  @override
  String get assistantSalatHabitMissing => 'Start the prayer program first.';

  @override
  String get assistantPrayerMarked => 'Marked that prayer as done.';

  @override
  String get assistantPrayerUnmarked => 'Removed the prayer mark.';

  @override
  String get assistantAlarmDefaultTitle => 'Arın reminder';

  @override
  String get assistantAlarmBody => 'The reminder you set.';

  @override
  String get assistantAlarmPermissionDenied =>
      'I cannot set an alarm without notification permission.';

  @override
  String assistantAlarmSet(String time) {
    return 'Reminder set for $time.';
  }

  @override
  String get assistantNotificationsOn => 'Notification turned on.';

  @override
  String get assistantNotificationsOff => 'Notification turned off.';

  @override
  String get assistantConfirmDisablePrayerTitle => 'Turn off prayer alerts?';

  @override
  String get assistantConfirmDisablePrayerBody =>
      'All prayer-time reminders will be turned off.';

  @override
  String get assistantCancel => 'Cancel';

  @override
  String get assistantConfirm => 'Turn off';

  @override
  String get qiblaHubHealingTitle => 'Healing Frequencies';

  @override
  String get qiblaHubHealingSubtitle =>
      'A calming session with therapy tones, ambience, and sleep timer';

  @override
  String get qiblaHubAiTitle => 'Islamic AI';

  @override
  String get qiblaHubAiSubtitle =>
      'Ask what\'s on your mind and start an Islamic chat';

  @override
  String get islamicAiComingSoonTitle => 'Islamic AI';

  @override
  String get islamicAiComingSoonBody =>
      'This feature is being prepared. You already have Premium; the chat will open here after the code is merged.';

  @override
  String get widgetThemeSectionTitle => 'Widget themes';

  @override
  String get widgetThemeSectionSubtitle =>
      'The classic theme is free. Other themes are Premium-only and look the same on iPhone and Android.';

  @override
  String get widgetThemeApplied => 'Widget theme updated.';

  @override
  String get widgetThemePremiumRequired => 'This theme is Premium-only.';

  @override
  String get widgetLockTextSectionTitle => 'Lock screen text';

  @override
  String get widgetLockTextSectionSubtitle =>
      'Lock screen color cannot change. You can make the text clear or soft. Premium only.';

  @override
  String get widgetLockTextClear => 'Clear';

  @override
  String get widgetLockTextSoft => 'Soft';

  @override
  String get widgetLockTextApplied => 'Lock screen text updated.';

  @override
  String get qiblaHubHilalDuelTitle => 'Knowledge Duel';

  @override
  String get qiblaHubHilalDuelSubtitle =>
      'Compete across 7 Islamic knowledge questions, earn crescents, and level up';

  @override
  String get hilalDuelTitle => 'Knowledge Duel';

  @override
  String get hilalDuelLanguageNote => 'Questions are currently in Turkish';

  @override
  String get hilalDuelRulesSummary =>
      '7 questions • 20 seconds each\nAccuracy and speed win. The next question opens once both players answer. Watch an ad for a heart or play unlimited with Premium.';

  @override
  String hilalDuelLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String hilalDuelHilalsLabel(int count) {
    return '$count crescents';
  }

  @override
  String hilalDuelHeartsLabel(int count) {
    return '$count hearts';
  }

  @override
  String get hilalDuelPlay => 'Play live';

  @override
  String get hilalDuelWatchAdForHeart => 'Watch ad for 1 heart';

  @override
  String get hilalDuelNeedHeartTitle => 'You need 1 heart to play';

  @override
  String get hilalDuelNeedHeartHint =>
      'Watch a short ad → earn 1 heart and find a rival';

  @override
  String get hilalDuelNeedHeartCta => 'Watch ad';

  @override
  String get hilalDuelSearching => 'Searching for opponent…';

  @override
  String get hilalDuelCancelSearch => 'Cancel search';

  @override
  String get hilalDuelCancelFailed =>
      'Cancel failed. Retry to refund your heart.';

  @override
  String hilalDuelQuestionProgress(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get hilalDuelDifficultyEasy => 'Easy';

  @override
  String get hilalDuelDifficultyMedium => 'Medium';

  @override
  String get hilalDuelDifficultyHard => 'Hard';

  @override
  String get hilalDuelWaitingOpponent => 'Opponent is answering…';

  @override
  String get hilalDuelAnsweredBubble => 'Answered';

  @override
  String get hilalDuelRoundCorrect => 'Correct';

  @override
  String get hilalDuelRoundWrong => 'Wrong';

  @override
  String get hilalDuelNoAnswer => 'No answer';

  @override
  String get hilalDuelFastOpponent => 'Quick Opponent';

  @override
  String get hilalDuelResultWin => 'You won';

  @override
  String get hilalDuelResultLose => 'You lost';

  @override
  String get hilalDuelResultDraw => 'Draw';

  @override
  String get hilalDuelResultScoreCaption => 'Correct answers';

  @override
  String hilalDuelCorrectCount(int count) {
    return '$count correct';
  }

  @override
  String hilalDuelTotalSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String hilalDuelHilalsEarned(int count) {
    return '+$count crescents';
  }

  @override
  String get hilalDuelDoubleReward => 'Watch ad to double crescents';

  @override
  String get hilalDuelDoubled => 'Crescents doubled';

  @override
  String get hilalDuelLobby => 'Back to lobby';

  @override
  String get hilalDuelRematch => 'Play again';

  @override
  String get hilalDuelChallengeAgain => 'Challenge again';

  @override
  String get hilalDuelRetry => 'Try again';

  @override
  String get hilalDuelPremiumUnlimited => 'Premium: unlimited hearts';

  @override
  String get hilalDuelUpgradePremium => 'Upgrade to Premium • Play Unlimited';

  @override
  String get hilalDuelNextLevel => 'Next level';

  @override
  String get hilalDuelMaxLevel => 'Maximum level';

  @override
  String hilalDuelNextRewardFrame(int level) {
    return 'Next reward: Avatar frame (LV $level)';
  }

  @override
  String hilalDuelNextRewardTitle(String title, int level) {
    return 'Next reward: Title “$title” (LV $level)';
  }

  @override
  String hilalDuelNextRewardHilalIcon(int level) {
    return 'Next reward: Special crescent icon (LV $level)';
  }

  @override
  String hilalDuelNextRewardFrameSilver(int level) {
    return 'Next reward: Silver frame (LV $level)';
  }

  @override
  String hilalDuelNextRewardGlow(int level) {
    return 'Next reward: Avatar glow (LV $level)';
  }

  @override
  String hilalDuelNextRewardNameAccent(int level) {
    return 'Next reward: Name color (LV $level)';
  }

  @override
  String get hilalDuelWeeklyTitle => 'Player of the Week';

  @override
  String get hilalDuelWeeklyResetHint => 'Resets on Monday';

  @override
  String hilalDuelWeeklyThisWeek(int count) {
    return 'This week: $count crescents';
  }

  @override
  String hilalDuelWeeklyRank(int rank) {
    return 'Rank: #$rank';
  }

  @override
  String get hilalDuelWeeklyRankNone => 'Rank: —';

  @override
  String get hilalDuelWeeklyTapHint => 'View leaderboard';

  @override
  String get hilalDuelWeeklyTopPreview => 'Top 3';

  @override
  String get hilalDuelWeeklyClimbHint =>
      'Top 10 is the green league — play and climb!';

  @override
  String get hilalDuelWeeklyPremiumRewardHint =>
      '1st → 14 days Premium + champion badge\n2nd → 7 days Premium\n3rd → 3 days Premium';

  @override
  String get hilalDuelWeeklyLastWinnersTitle => 'Last week\'s winners';

  @override
  String get hilalDuelWeeklyLastWinnerPrize1 =>
      '14 days Premium + champion badge';

  @override
  String get hilalDuelWeeklyLastWinnerPrize2 => '7 days Premium';

  @override
  String get hilalDuelWeeklyLastWinnerPrize3 => '3 days Premium';

  @override
  String get hilalDuelWeeklyEmpty =>
      'No crescents earned this week yet. Finish the first match!';

  @override
  String hilalDuelWeeklyYourPlace(int rank, int count) {
    return 'Your place: #$rank · $count crescents';
  }

  @override
  String get hilalDuelAdminRemoveTitle => 'Remove from board';

  @override
  String hilalDuelAdminRemoveBody(String name) {
    return 'Remove “$name” from this week’s leaderboard? Players below move up one place; they won’t reappear on the board this week.';
  }

  @override
  String get hilalDuelAdminRemoveAction => 'Remove';

  @override
  String get hilalDuelAdminRemoved => 'Player removed from the board.';

  @override
  String get hilalDuelTitleTalebe => 'Student';

  @override
  String get hilalDuelTitleMuderris => 'Mudarris';

  @override
  String get hilalDuelTitleIlimDostu => 'Friend of Knowledge';

  @override
  String get hilalDuelYouLabel => 'You';

  @override
  String get hilalDuelOpponentLabel => 'Opponent';

  @override
  String get hilalDuelChallengeAction => 'Challenge';

  @override
  String get hilalDuelAdminChallengeTitle => 'Challenge';

  @override
  String get hilalDuelAdminChallengeBody =>
      'Play it yourself, or auto-send a 3–5 correct run to provoke the opponent.';

  @override
  String get hilalDuelAdminChallengePlay => 'Play for real';

  @override
  String get hilalDuelAdminChallengeAuto => 'Auto-send';

  @override
  String get hilalDuelChallengeInboxTitle => 'Challenges';

  @override
  String get hilalDuelChallengeAccept => 'Accept';

  @override
  String get hilalDuelChallengeContinue => 'Continue';

  @override
  String get hilalDuelChallengeSeeResult => 'See result';

  @override
  String get hilalDuelChallengeWaiting => 'Waiting for opponent';

  @override
  String get hilalDuelChallengeYourTurn => 'Your turn';

  @override
  String get hilalDuelChallengeExpired => 'Time\'s up — no points';

  @override
  String get hilalDuelChallengeHint =>
      'Challenge someone from the list. You spend 1 heart; if time runs out, nobody scores.';

  @override
  String get hilalDuelChallengePickTitle => 'Pick opponent';

  @override
  String get hilalDuelChallengePickHint =>
      'Choose a player to challenge. You answer first. Your opponent has 24 hours to reply.';

  @override
  String get hilalDuelChallengeSentTitle => 'Challenge sent';

  @override
  String hilalDuelChallengeSentBody(String name) {
    return 'You\'ll see the result when $name answers.';
  }

  @override
  String get hilalDuelChallengeSentOk => 'OK';

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
      'Arin uses Firebase services (Authentication, Firestore) for sign-in, notifications, and sync, Firebase Analytics/Crashlytics for analytics and crash diagnostics, Google AdMob for ads, RevenueCat for subscription and in-app purchase verification, and Aladhan/Diyanet APIs for prayer times. Premium Arın Assistant messages are sent to Google Gemini; chat text is not stored in the app. On Gemini’s free tier, this content may be used to improve Google’s products.';

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
  String get notificationsBatteryRationaleTitle =>
      'Why is battery exemption needed?';

  @override
  String get notificationsBatteryRationaleBody =>
      'Prayer time and purification reminders need to be exempt from battery optimisation so they can arrive at the exact scheduled time, even when the phone is in sleep (Doze) mode. This permission only affects scheduled notifications and does not run in the background continuously.';

  @override
  String get notificationsBatteryRationaleConfirm => 'Allow';

  @override
  String get notificationsBatteryRationaleCancel => 'Not now';

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
      'Quit milestones, recovery percentages, monthly encouragement, and occasional tips or inspiration.';

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
  String get adminPoolLabelNotificationNamazWisdom =>
      'Prayer notification quotes';

  @override
  String get adminPoolLabelNotificationDailyNamazReminder =>
      'Daily prayer reminder texts';

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
  String get onboardingStart => 'Start';

  @override
  String get onboardingWelcomeTitle => 'Welcome.';

  @override
  String get onboardingWelcomeBody =>
      'Let verses, prayers, and prayer reminders stay with you through the day.';

  @override
  String get onboardingLandingVerseArabic => 'قَدْ أَفْلَحَ مَن زَكَّاهَا';

  @override
  String get onboardingLandingVerseTranslation =>
      'Successful is the one who purifies it.';

  @override
  String get onboardingLandingVerseSource => 'Ash-Shams 9';

  @override
  String get onboardingWelcomeWidgetVerseArabic =>
      'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ';

  @override
  String get onboardingWelcomeWidgetVerseTranslation =>
      'Surely in the remembrance of Allah do hearts find rest.';

  @override
  String get onboardingWelcomeWidgetVerseSource => 'Ar-Ra\'d 13:28';

  @override
  String get onboardingLanguagePickerTitle => 'Language';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingStoryBody =>
      'Just take a calm breath.\n\nArın will stay with you through the day with short reminders from the Qur\'an.\n\nA small verse pause will greet you every time you open your phone.\n\nIf you are ready, let\'s begin.';

  @override
  String get onboardingNameSubtitle =>
      'So verse and reminder texts feel more personal.';

  @override
  String get onboardingNameHint => 'Your name';

  @override
  String onboardingGreetingTitle(String name) {
    return 'Glad to meet you, $name.';
  }

  @override
  String get onboardingGreetingBody =>
      'Downloading this app today is not a coincidence.\n\nArın will stay with you from here: a verse, a prayer time, a reminder.\n\nLet us get to know you a little. Answer as it comes from within.';

  @override
  String onboardingIntentTitle(String name) {
    return '$name, what brought you here?';
  }

  @override
  String get onboardingIntentSubtitle =>
      'We will bring reminders closer to this intention.';

  @override
  String get onboardingIntentLock => 'See a verse on the lock screen';

  @override
  String get onboardingIntentFaith => 'Keep my faith fresh';

  @override
  String get onboardingIntentCalm => 'Quiet my heart';

  @override
  String get onboardingIntentDaily => 'Begin the day with a verse';

  @override
  String get onboardingIntentPrayer => 'Not miss prayer times';

  @override
  String onboardingHeartTitle(String name) {
    return '$name, how close to Allah do you feel today?';
  }

  @override
  String get onboardingHeartHint => 'Touch or drag the heart.';

  @override
  String get onboardingHeartLabelFar => 'I feel distant';

  @override
  String get onboardingHeartLabelSeeking => 'I am seeking the way';

  @override
  String get onboardingHeartLabelHolding => 'I am keeping the bond';

  @override
  String get onboardingHeartLabelNear => 'I am standing close';

  @override
  String get onboardingHeartLabelFull => 'My heart is full';

  @override
  String get onboardingHoldVerseArabic =>
      'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ';

  @override
  String get onboardingHoldVerseTranslation =>
      'When My servants ask you about Me, I am near.';

  @override
  String get onboardingHoldVerseSource => 'Al-Baqarah 186';

  @override
  String onboardingHoldFooter(String name) {
    return '$name, this is only a beginning...';
  }

  @override
  String onboardingStruggleTitle(String name) {
    return '$name, what is weighing on your heart most lately?';
  }

  @override
  String get onboardingStruggleSubtitle =>
      'We will soften reminders around this weight.';

  @override
  String get onboardingStruggleAnxiety => 'Anxiety';

  @override
  String get onboardingStruggleDelay => 'Procrastination';

  @override
  String get onboardingStruggleLonely => 'Loneliness';

  @override
  String get onboardingStruggleImpatience => 'Impatience';

  @override
  String get onboardingStruggleRegret => 'Regret';

  @override
  String get onboardingNoteSubtitle =>
      'A short sentence is enough. Only you can see this answer.';

  @override
  String onboardingNoteTitleAnxiety(String name) {
    return '$name, is there something you want to put into words about your anxiety?';
  }

  @override
  String onboardingNoteTitleDelay(String name) {
    return '$name, is there something you keep putting off?';
  }

  @override
  String onboardingNoteTitleLonely(String name) {
    return '$name, is there something you want to put into words about your loneliness?';
  }

  @override
  String onboardingNoteTitleImpatience(String name) {
    return '$name, is there something you want to put into words about your impatience?';
  }

  @override
  String onboardingNoteTitleRegret(String name) {
    return '$name, is there something you want to put into words about your regret?';
  }

  @override
  String get onboardingNoteHintAnxiety =>
      'E.g. Worry about the future keeps me awake at night.';

  @override
  String get onboardingNoteHintDelay =>
      'E.g. I keep leaving the work I meant to do until tomorrow.';

  @override
  String get onboardingNoteHintLonely =>
      'E.g. Even in a crowd I feel empty inside.';

  @override
  String get onboardingNoteHintImpatience =>
      'E.g. When things move slowly, my chest tightens.';

  @override
  String get onboardingNoteHintRegret =>
      'E.g. A word from the past still sits in my heart.';

  @override
  String get onboardingNoteSuggestionAnxiety =>
      'I want to leave my anxiety with Allah and settle my heart.';

  @override
  String get onboardingNoteSuggestionDelay =>
      'I want to do what I intended without putting it off.';

  @override
  String get onboardingNoteSuggestionLonely =>
      'I want to remember that my Lord is with me even when I am alone.';

  @override
  String get onboardingNoteSuggestionImpatience =>
      'I want to walk with patience, without rushing.';

  @override
  String get onboardingNoteSuggestionRegret =>
      'I want to set my regret down through repentance.';

  @override
  String get onboardingHeardTitle => 'We heard you.';

  @override
  String get onboardingHeardVerse => 'Indeed, with hardship comes ease.';

  @override
  String get onboardingHeardSource => '— Ash-Sharh, 94:6';

  @override
  String onboardingToneTitle(String name) {
    return '$name, how weary has your heart felt lately?';
  }

  @override
  String get onboardingToneSubtitle => 'Pour your heart out.';

  @override
  String get onboardingToneCalm => 'Calm';

  @override
  String get onboardingToneLight => 'Light';

  @override
  String get onboardingToneMid => 'Medium';

  @override
  String get onboardingToneHeavy => 'Heavy';

  @override
  String get onboardingToneVeryHeavy => 'Very heavy';

  @override
  String onboardingToneValue(int value) {
    return '$value / 5';
  }

  @override
  String onboardingTurnTitle(String name) {
    return '$name, when hard days come...';
  }

  @override
  String get onboardingTurnSubtitle => 'Do you turn to Allah?';

  @override
  String get onboardingTurnAlways => 'In every tightness I return to Him';

  @override
  String get onboardingTurnSometimes => 'I turn sometimes';

  @override
  String get onboardingTurnRarely => 'Rarely, but I want more';

  @override
  String get onboardingTurnStarting => 'I am new on this path';

  @override
  String get onboardingShapeTitle => 'We are weaving this to your heart';

  @override
  String get onboardingShapeSubtitle =>
      'Not more screens; a short pause at the right moment.';

  @override
  String get onboardingShapeCard1Title => 'Verses close to you';

  @override
  String get onboardingShapeCard1Body =>
      'Content rises according to the weight you chose.';

  @override
  String get onboardingShapeCard2Title => 'Soft reminders';

  @override
  String get onboardingShapeCard2Body =>
      'The language stays calm, short, and aimed at the heart.';

  @override
  String get onboardingShapeCard3Title => 'Around the Quran';

  @override
  String get onboardingShapeCard3Body =>
      'The day walks the same line as verse and remembrance.';

  @override
  String onboardingPrayerTitle(String name) {
    return '$name, how would you describe your prayer rhythm?';
  }

  @override
  String get onboardingPrayerSubtitle =>
      'Let us pick a starting tempo that fits you.';

  @override
  String get onboardingPrayerRegular => 'I keep my rhythm';

  @override
  String get onboardingPrayerOccasional => 'I catch it now and then';

  @override
  String get onboardingPrayerStruggling => 'I struggle when I slip';

  @override
  String get onboardingPrayerStarting => 'I am only just settling in';

  @override
  String get onboardingPrayerBeginHere => 'I want to start from this screen';

  @override
  String onboardingWaswasaTitle(String name) {
    return '$name, what do you do when doubt or whispers come?';
  }

  @override
  String get onboardingWaswasaSubtitle =>
      'This answer shapes how we stand beside you.';

  @override
  String get onboardingWaswasaPray => 'I meet it with prayer';

  @override
  String get onboardingWaswasaRead => 'I read and try to understand';

  @override
  String get onboardingWaswasaAsk => 'I open it to someone I trust';

  @override
  String get onboardingWaswasaCarry => 'I carry it quietly inside';

  @override
  String get onboardingPathVerseArabic =>
      'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ';

  @override
  String get onboardingPathVerseTranslation =>
      'Whoever puts their trust in Allah, He is sufficient for them.';

  @override
  String get onboardingPathVerseSource => 'At-Talaq 65:3';

  @override
  String onboardingPathVerseFooter(String name) {
    return '$name, let the Quran rest in your heart.';
  }

  @override
  String get onboardingPathTitle => 'Your daily line is beginning to appear';

  @override
  String get onboardingPathSubtitle =>
      'We will join your rhythm, heart-state, and intention in one simple day.';

  @override
  String get onboardingPathCard1Title => 'Your need first';

  @override
  String get onboardingPathCard1Body =>
      'Verses that fit you stay at the top of the list.';

  @override
  String get onboardingPathCard2Title => 'Your own tempo';

  @override
  String get onboardingPathCard2Body =>
      'The flow breathes with how you actually read.';

  @override
  String get onboardingPathCard3Title => 'In front of your eyes';

  @override
  String get onboardingPathCard3Body =>
      'The lock screen becomes a short pause scattered through the day.';

  @override
  String get onboardingRhythmTitle => 'Arın settles quietly into the day';

  @override
  String get onboardingRhythmSubtitle =>
      'The aim is not more time on screen; a short reminder at the right moment. We will ask for notification permission for this.';

  @override
  String get onboardingRhythmFeaturedTitle => 'The day\'s verse reminder';

  @override
  String get onboardingRhythmFeaturedBody =>
      'When you continue, we will ask for notification permission. You can change the hours and rhythm from settings whenever you want.';

  @override
  String get onboardingRhythmCard1Title => 'A short pause';

  @override
  String get onboardingRhythmCard1Body =>
      'Verses appear calmly and briefly through the day.';

  @override
  String get onboardingRhythmCard2Title => 'A breath on the lock screen';

  @override
  String get onboardingRhythmCard2Body =>
      'Each glance at the phone holds a small reminder.';

  @override
  String get onboardingRhythmCard3Title => 'Staying on the same line';

  @override
  String get onboardingRhythmCard3Body =>
      'Prayer, remembrance, and reflection follow one another.';

  @override
  String get onboardingLocationTitle => 'Location for prayer times';

  @override
  String get onboardingLocationSubtitle =>
      'We kindly ask for your location so we can show imsak, noon, and evening for your city. Location is used only for prayer times and qibla.';

  @override
  String get onboardingLocationFeaturedTitle => 'Times for where you are';

  @override
  String get onboardingLocationFeaturedBody =>
      'When you continue, we will ask for location permission. You can change this later from settings.';

  @override
  String get onboardingLocationCard1Title => 'Prayer times';

  @override
  String get onboardingLocationCard1Body =>
      'Daily times stay fresh for your city.';

  @override
  String get onboardingLocationCard2Title => 'Qibla direction';

  @override
  String get onboardingLocationCard2Body =>
      'The same permission is enough to calculate the direction.';

  @override
  String get onboardingLocationCard3Title => 'It stays with you';

  @override
  String get onboardingLocationCard3Body =>
      'Your location is not shared for any other purpose.';

  @override
  String get onboardingPrepareTitle => 'Final settings are being made';

  @override
  String get onboardingPrepareSubtitle =>
      'Each part is being prepared one by one.';

  @override
  String get onboardingPrepareReadyTitle => 'Your experience is ready';

  @override
  String get onboardingPrepareReadySubtitle =>
      'In the last step you will say Amen to a short prayer.';

  @override
  String get onboardingPrepareStatus => 'Preparing';

  @override
  String get onboardingPrepareYes => 'Yes';

  @override
  String get onboardingPrepareNo => 'No';

  @override
  String onboardingPrepareBar1Title(String name) {
    return '$name, your verse flow is being woven';
  }

  @override
  String get onboardingPrepareBar1Body =>
      'Language and emphasis are chosen from your answers.';

  @override
  String get onboardingPrepareBar2Title => 'Lock screen view is being prepared';

  @override
  String get onboardingPrepareBar2Body => 'The clock and verse stay simple.';

  @override
  String get onboardingPrepareBar3Title =>
      'Adjusting so we can reach more people';

  @override
  String get onboardingPrepareBar3Body =>
      'Discovery sources are measured privately.';

  @override
  String get onboardingPrepareBar4Title => 'Shortcuts are being placed';

  @override
  String get onboardingPrepareBar4Body =>
      'Tasbih, qibla, prayer, and conversation are being readied.';

  @override
  String get onboardingPrepareAskLock =>
      'Shall we use a simple verse view on the lock screen?';

  @override
  String get onboardingPrepareAskVerses =>
      'Shall we put verses first according to your answers?';

  @override
  String get onboardingPrepareAskShortcuts =>
      'Shall we lift worship shortcuts in the main flow?';

  @override
  String get onboardingDuaTitle => 'A short prayer';

  @override
  String onboardingDuaBody(String name) {
    return 'O Allah, grant Your servant $name goodness, blessing, health, peace, wisdom, and steadfastness. Keep their heart alive with the Quran, and their steps firm in what is good. Let Your word stay close to them in every season.';
  }

  @override
  String get onboardingDuaVerseArabic =>
      'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً';

  @override
  String get onboardingDuaVerseTranslation =>
      'Our Lord, give us good in this world and good in the Hereafter.';

  @override
  String get onboardingDuaVerseSource => 'Al-Baqarah 2:201';

  @override
  String get onboardingDuaAmin => 'Amen.';

  @override
  String get onboardingDuaHoldHint => 'Hold down';

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
  String get surveyNotificationAllow => 'Turn on notifications';

  @override
  String get surveyNotificationSkip => 'Skip for now';

  @override
  String get surveyNotificationOpenSettings => 'Open settings';

  @override
  String get surveyLockWidgetsTitle => 'Lock screen';

  @override
  String get surveyLockWidgetsLead =>
      'Would you like prayer times and the daily quote on your lock screen?';

  @override
  String get surveyLockWidgetsSubtitle =>
      'Android can’t place real widgets on the lock screen; your choices appear as persistent notifications. You can change this anytime in Widget Center.';

  @override
  String get surveyLockWidgetsPrayerTitle => 'Prayer Time';

  @override
  String get surveyLockWidgetsPrayerSubtitle =>
      'Shows the next prayer and countdown on the lock screen.';

  @override
  String get surveyLockWidgetsQuoteTitle => 'Daily Quote';

  @override
  String get surveyLockWidgetsQuoteSubtitle =>
      'Shows today’s quote on the lock screen.';

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
  String get premiumLegalPrivacyPolicy => 'Privacy Policy';

  @override
  String get premiumLegalTermsOfUse => 'Terms of Use';

  @override
  String get premiumLinkOpenFailed => 'Could not open link. Please try again.';

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

  @override
  String get offlineBannerOffline => 'You are offline';

  @override
  String get offlineBannerReconnected => 'Reconnected';

  @override
  String get premiumRestorePurchasesLabel => 'Restore purchases';

  @override
  String get premiumActivePlanLabel => 'Active plan';

  @override
  String get premiumPlanMonthlyLaunch => 'Start with Launch Price';

  @override
  String get premiumPlanYearlySwitch => 'Switch to Yearly';

  @override
  String get premiumFeatureNoAds => 'Ad-free experience';

  @override
  String get premiumFeatureWidgets => 'No widget locks';

  @override
  String get premiumFeatureReels => 'Uninterrupted explore feed';

  @override
  String get premiumFeatureSecondAlarm => '2nd adhan alarm enabled';

  @override
  String get premiumFeatureExtras => 'No ads in zikr, compass, and frequencies';

  @override
  String get premiumSignInRequired =>
      'Sign-in is not required for purchase. You can use Premium on this device immediately and optionally link your account later to access it on other devices.';

  @override
  String get premiumSignInTitle => 'Sign in for Premium';

  @override
  String get premiumSignInSubtitle =>
      'Your premium purchase is linked to your account first so it isn\'t lost when changing devices. Sign in is not required to view prices.';

  @override
  String get premiumSignInGoogle => 'Continue with Google';

  @override
  String get premiumSignInApple => 'Continue with Apple';

  @override
  String get premiumSignInCancel => 'Not now';

  @override
  String get locationPermissionRequiredTitle => 'Location Permission Required';

  @override
  String get locationPermissionRequiredBody =>
      'Arin requires access to your location to accurately calculate prayer times and Qibla direction. Your location data is used only for these purposes and processed on your device.';

  @override
  String get locationPermissionNotNow => 'Not Now';

  @override
  String get locationPermissionContinue => 'Continue';

  @override
  String get errorScreenTitle => 'Something went wrong';

  @override
  String get errorScreenBody =>
      'This section could not be opened right now. You can try closing and reopening the app.';

  @override
  String get errorScreenDebugTitle => 'ARIN — widget error (debug)';

  @override
  String get errorScreenDebugBody =>
      'You are in debug mode. Copy the text below.';

  @override
  String get widgetUnlockQuoteTitle => 'Daily Quote Widget';

  @override
  String get widgetUnlockPrayerTitle => 'Prayer Time Widget';

  @override
  String get widgetUnlockComboTitle => 'Quote + Prayer Widget';

  @override
  String get widgetUnlockTrackingTitle => 'Tracking Widget';

  @override
  String get widgetUnlockZikirTitle => 'Dhikr Counter Widget';

  @override
  String get widgetUnlockAdPreparing => 'Preparing the ad…';

  @override
  String get widgetUnlockAdLoadFailed =>
      'No suitable ad is available right now. Please try again in a few seconds.';

  @override
  String get widgetUnlockAdRetryButton => 'Try again';

  @override
  String get widgetUnlockAdLaterButton => 'Later';

  @override
  String widgetUnlockSuccessTitle(Object title, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$title unlocked for $hours hours! 🎉',
      one: '$title unlocked for 1 hour! 🎉',
    );
    return '$_temp0';
  }

  @override
  String get widgetUnlockPremiumSuccess =>
      'Premium active! All widgets unlocked. 🎉';

  @override
  String widgetUnlockDescription(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other:
          'You can watch a short ad to unlock this widget for $hours hours. Upgrade to Premium for permanent access.',
      one:
          'You can watch a short ad to unlock this widget for 1 hour. Upgrade to Premium for permanent access.',
    );
    return '$_temp0';
  }

  @override
  String widgetUnlockAdButton(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Watch ad — Unlock for $hours hours',
      one: 'Watch ad — Unlock for 1 hour',
    );
    return '$_temp0';
  }

  @override
  String get widgetUnlockPremiumButton => 'Upgrade to Premium';

  @override
  String get widgetUnlockCancelButton => 'Not now';

  @override
  String get purchaseErrorLegacyPlan =>
      'This plan is no longer sold. Existing subscribers keep their current price.';

  @override
  String get purchaseErrorNotFound =>
      'Product not found. Please check your internet connection.';

  @override
  String purchaseErrorUnexpected(Object error) {
    return 'Unexpected error: $error';
  }

  @override
  String get purchaseErrorNotSupported =>
      'Purchasing is not supported on this platform.';

  @override
  String get audioPermissionRequiredTitle => 'Media Permission Required';

  @override
  String get audioPermissionRequiredBody =>
      'Arin requires access to your audio files so you can choose a custom adhan or notification sound from your device. These files are only used as notifications within the app.';

  @override
  String get audioPickerTitle => 'Select audio file';

  @override
  String get mgmtDailyPrayers => 'Daily prayers';

  @override
  String get mgmtRoutineWorkshop => 'Routine workshop';

  @override
  String get mgmtChooseGrowth => 'Choose growth';

  @override
  String get mgmtPickPrayerOrMakeup =>
      'Pick prayer or makeup tracking; use the section below for a custom growth routine.';

  @override
  String get mgmtCountingAndCompensation => 'Counting and compensation';

  @override
  String get mgmtPrayer => 'Prayer';

  @override
  String get mgmtTimeAndKhushu => 'Time and khushu';

  @override
  String get mgmtCustomRoutine => 'Custom routine';

  @override
  String get mgmtChooseYourOwnTitle =>
      'Choose your own title, emoji and reminder.';

  @override
  String get mgmtSelect => 'Select';

  @override
  String get habitsMyHabits => 'My Habits';

  @override
  String get habitsNoHabitsYet =>
      'You have not added any habits yet.\nReady for a fresh start?';

  @override
  String get habitsGrowth => 'Growth';

  @override
  String get habitsPurification => 'Purification';

  @override
  String get habitsAddPurificationGoal => 'Add purification goal';

  @override
  String get habitsAddGrowthRoutine => 'Add growth routine';

  @override
  String get habitsDeleteConfirmTitle => 'Do you want to delete this habit?';

  @override
  String get habitsCancel => 'Cancel';

  @override
  String get habitsYesDelete => 'Yes, Delete';

  @override
  String get habitsDayStreak => 'day streak';

  @override
  String get customHabitThisWeekGoal => 'This week\'s goal';

  @override
  String get customHabitThisMonthGoal => 'This month\'s goal';

  @override
  String get customHabitDailyGoal => 'Daily goal';

  @override
  String get customHabitThisWeekGoalComplete =>
      'This week\'s goal is complete.';

  @override
  String get customHabitThisMonthGoalComplete =>
      'This month\'s goal is complete.';

  @override
  String get customHabitTodayGoalComplete => 'Today\'s goal is complete.';

  @override
  String get customHabitLetsStart => 'Let\'s start!';

  @override
  String get customHabitDoingWell => 'You are doing well.';

  @override
  String get customHabitAlmostThere => 'Almost there.';

  @override
  String get customHabitOneLastStep => 'One last step.';

  @override
  String get customHabitRecordNotFound => 'Record not found';

  @override
  String get customHabitStreak => 'Streak';

  @override
  String get customHabitDayStreak => 'Day streak';

  @override
  String get customHabitBack => 'Back';

  @override
  String get customHabitRemove => 'Remove';

  @override
  String get customHabitBackToTracker => 'Back to habit tracker';

  @override
  String get customHabitGoal => 'Goal';

  @override
  String get customHabitCompletedToday => 'You completed today\'s goal.';

  @override
  String get customHabitCompletedPeriod => 'You completed this period\'s goal.';

  @override
  String get customHabitFinish => 'Finish';

  @override
  String get addHabitUnitTimes => 'times';

  @override
  String get addHabitUnitMinutes => 'minutes';

  @override
  String get addHabitUnitHours => 'hours';

  @override
  String get addHabitUnitPages => 'pages';

  @override
  String get addHabitUnitGlasses => 'glasses';

  @override
  String get addHabitUnitSets => 'sets';

  @override
  String get addHabitUnitLaps => 'laps';

  @override
  String get addHabitDaily => 'Daily';

  @override
  String get addHabitWeekly => 'Weekly';

  @override
  String get addHabitMonthly => 'Monthly';

  @override
  String addHabitSummaryWeekly(Object amount, Object unit) {
    return '$amount $unit weekly';
  }

  @override
  String addHabitSummaryMonthly(Object amount, Object unit) {
    return '$amount $unit monthly';
  }

  @override
  String addHabitSummaryDaily(Object amount, Object unit) {
    return '$amount $unit daily';
  }

  @override
  String get addHabitCancel => 'Cancel';

  @override
  String get addHabitOk => 'OK';

  @override
  String get addHabitCustom => 'Custom';

  @override
  String get addHabitSave => 'Save';

  @override
  String get addHabitGrowthName => 'Growth Name';

  @override
  String get addHabitPurificationName => 'Purification Name';

  @override
  String get addHabitGrowthHint => 'Ex: Read a book for 30 minutes';

  @override
  String get addHabitPurificationHint => 'Ex: Reduce unnecessary screen time';

  @override
  String get addHabitNameRequired => 'Name is required';

  @override
  String get addHabitNameTooLong => 'Maximum 60 characters';

  @override
  String get addHabitNoteOptional => 'Note (optional)';

  @override
  String get addHabitNoteHint => 'A short note to yourself...';

  @override
  String habitCalendarToday(Object date) {
    return 'Today: $date';
  }

  @override
  String get habitCalendarTitle => 'Habit calendar';

  @override
  String get habitCalendarMonth => 'Month';

  @override
  String habitCalendarMonthNote(Object month, Object year) {
    return 'Month note · $month $year';
  }

  @override
  String get habitCalendarNoRecords =>
      'No records yet for this month or no habits added.';

  @override
  String habitCalendarQuitInsight(Object n, Object title) {
    return '“$title”: $n days Purification counter on calendar this month (since start).';
  }

  @override
  String habitCalendarPrayerInsight(
    Object anyPrayer,
    Object fullFive,
    Object title,
  ) {
    return '“$title”: At least one prayer marked on $anyPrayer days; 5/5 completed on $fullFive days.';
  }

  @override
  String habitCalendarCustomInsightPeriod(
    Object n,
    Object periodLabel,
    Object title,
  ) {
    return '“$title”: $n $periodLabel goal reached this month.';
  }

  @override
  String get habitCalendarWeekLabel => 'week';

  @override
  String get habitCalendarMonthLabel => 'month';

  @override
  String habitCalendarCustomInsightDays(Object completedDays, Object title) {
    return '“$title”: A total of $completedDays days marked as completed this month.';
  }

  @override
  String get habitCalendarLegend =>
      'Grey icons in cells: means there is a record for that day. The purification icon specifically shows days the counter was active; prayer/routine icons show completed records for the respective day.';

  @override
  String get kazaPrayerFajr => 'Fajr prayer';

  @override
  String get kazaPrayerDhuhr => 'Dhuhr prayer';

  @override
  String get kazaPrayerAsr => 'Asr prayer';

  @override
  String get kazaPrayerMaghrib => 'Maghrib prayer';

  @override
  String get kazaPrayerIsha => 'Isha prayer';

  @override
  String get kazaPrayerWitr => 'Witr prayer';

  @override
  String get kazaReset => 'Reset';

  @override
  String get kazaResetConfirmDesc =>
      'All makeup prayer counts will be reset. Are you sure?';

  @override
  String get kazaCancel => 'Cancel';

  @override
  String get kazaTrackerTitle => 'Makeup tracking';

  @override
  String get kazaClose => 'Close';

  @override
  String get kazaTrackerSubtitle => 'Makeup prayer tracking';

  @override
  String get kazaTrackerDesc =>
      'Try to perform makeup prayers after the regular daily prayers. You can add debt with (+) and decrease the counter with (−) for each prayer performed.';

  @override
  String get kazaCalcBirthDate => 'Birth date';

  @override
  String get kazaCalcApply => 'Apply';

  @override
  String get kazaCalcUpdateCounters => 'Update counters?';

  @override
  String get kazaCalcUpdateDesc =>
      'Your current makeup prayer counts will be deleted and replaced with calculated values.';

  @override
  String get kazaCalcCancel => 'Cancel';

  @override
  String get kazaCalcContinue => 'Continue';

  @override
  String get kazaCalcErrorPubertyFuture =>
      'Puberty date cannot be after today. Check birth date or puberty age.';

  @override
  String get kazaCalcErrorZeroRemaining =>
      'Remaining prayers 0: if fully prayed days equal or exceed liable days, it is capped; the 6 prayer counters remain zero accordingly.';

  @override
  String get kazaCalcTitle => 'Makeup tracking';

  @override
  String get kazaCalcSubtitle => 'Makeup prayer tracking';

  @override
  String get kazaCalcDesc =>
      'Obligatory prayers start from puberty. If you don\'t know the exact age, you can reference 12 for males and 9 for females. This screen produces an estimated number; continue performing makeup prayers after regular prayers.';

  @override
  String get kazaCalcFemaleNote =>
      'For females: roughly 6 days are exempted from prayers for each calendar month passed since puberty (not exceeding total days).';

  @override
  String get kazaCalcFormula =>
      'Formula: liable days = calendar days − menstruation exemption; total prayers = liable days × 6 − (fully prayed days × 6). Prayed days cannot exceed liable days.';

  @override
  String get kazaCalcCalculateTitle => 'Calculate makeup prayers';

  @override
  String get kazaCalcGender => 'Your gender';

  @override
  String get kazaCalcMale => 'Male';

  @override
  String get kazaCalcFemale => 'Female';

  @override
  String get kazaCalcBirthDateTitle => 'Your birth date';

  @override
  String get kazaCalcPubertyAge => 'Age you reached puberty';

  @override
  String kazaCalcPubertyNote(Object minPuberty) {
    return 'Lower limit: male 12, female 9 years (if smaller is entered, $minPuberty is used in calculation).';
  }

  @override
  String get kazaCalcPrayedDays => 'How many days have you prayed?';

  @override
  String get kazaCalcPrayedDaysNote =>
      'Total number of days so far where you performed all prayers within the day.';

  @override
  String get kazaCalcCalculate => 'Calculate';

  @override
  String get kazaCalcLiveError =>
      'Puberty date cannot be after today; check birth and puberty age.';

  @override
  String kazaCalcLiveHayiz(Object days) {
    return 'Menstruation exemption: −$days days\n';
  }

  @override
  String kazaCalcLiveApplied(Object applied) {
    return '\n(Fully prayed days upper limit: $applied)';
  }

  @override
  String get kazaCalcLiveSummary => 'Live summary';

  @override
  String kazaCalcLiveCalendarDays(Object days) {
    return 'Calendar days: $days\n';
  }

  @override
  String kazaCalcLiveLiableDays(Object days) {
    return 'Liable days: $days\n';
  }

  @override
  String kazaCalcLiveOwed(Object perDay, Object total) {
    return 'Prayer debt (liable days × $perDay): $total\n';
  }

  @override
  String kazaCalcLiveCredited(
    Object appliedNote,
    Object credited,
    Object perDay,
  ) {
    return 'Deducted (full days × $perDay): $credited$appliedNote\n';
  }

  @override
  String kazaCalcLiveRemaining(Object remaining) {
    return '—\nRemaining total: $remaining prayers';
  }

  @override
  String get kazaCalcLiveZeroNote =>
      'Post-calculation counter: remaining total is divided into 6 prayers; if remaining is 0, each prayer stays 0.';

  @override
  String get dailyNamazWisdomFallback =>
      'Reminder text could not be loaded. Try refreshing the page.';

  @override
  String get momentVerseError => 'Failed to load. Please try again.';

  @override
  String get momentVerseEmptyTitle => 'No moment yet';

  @override
  String get momentVerseEmptyDesc => 'Wait for the next notification.';

  @override
  String get momentVerseExpiredTitle => 'This time has passed';

  @override
  String get momentVerseExpiredDesc =>
      'Some moments only come once.\nMaybe we will meet in the next one.';

  @override
  String get momentVerseExpiredNote =>
      'Keep notifications on,\nso you don\'t miss the next moment.';

  @override
  String get momentVerseActiveWhisper =>
      'The verse whispered to you by the clock';

  @override
  String get momentVerseSurah => 'Surah';

  @override
  String get momentVerseVerse => 'Verse';

  @override
  String get momentVerseOneVerse => 'a verse';

  @override
  String get momentVerseClock => 'Clock';

  @override
  String get momentVerseMeaningDesc =>
      'This is no coincidence; the numbers of time turn into an address in the Quran. So does you opening this notification exactly on time and standing before this verse.';

  @override
  String get momentVerseDisappear => 'this moment will disappear in';

  @override
  String get momentVerseReturnHome => 'Return to Home';

  @override
  String get momentVerseClose => 'Close';

  @override
  String get surveyDictMoodHappy => 'Happy';

  @override
  String get surveyDictMoodCalm => 'Calm';

  @override
  String get surveyDictMoodStressed => 'Stressed';

  @override
  String get surveyDictMoodSad => 'Sad';

  @override
  String get surveyDictMoodGrateful => 'Grateful';

  @override
  String get surveyDictMoodAnxious => 'Anxious';

  @override
  String get surveyDictMoodMotivated => 'Motivated';

  @override
  String get surveyDictSectorStudent => 'High school / University / Prep';

  @override
  String get surveyDictSectorPrivate => 'Private sector';

  @override
  String get surveyDictSectorPublic => 'Public sector';

  @override
  String get surveyDictSectorBusiness => 'Own business / Freelance';

  @override
  String get surveyDictSectorTrade => 'Trade';

  @override
  String get surveyDictSectorHousehold => 'Homemaker';

  @override
  String get surveyDictSectorOther => 'Other';

  @override
  String get surveyDictNeedMotivation => 'Motivation';

  @override
  String get surveyDictNeedSabr => 'Patience';

  @override
  String get surveyDictNeedShukr => 'Gratitude';

  @override
  String get surveyDictNeedTawakkul => 'Trust in God';

  @override
  String get surveyDictNeedFocus => 'Focus';

  @override
  String get surveyDictNeedHealing => 'Healing';

  @override
  String get surveyDictNeedRizq => 'Provision & Blessing';

  @override
  String get surveyDictGenderMale => 'Male';

  @override
  String get surveyDictGenderFemale => 'Female';

  @override
  String get premiumProductNotReadyError =>
      'Product information is not ready yet. Please try again.';

  @override
  String get premiumAccountLinkError =>
      'Account linking could not be completed. Please try again.';

  @override
  String get premiumWelcomeTitle => '🌿 Welcome!';

  @override
  String get premiumWelcomeMessage =>
      'ARIN Premium is active. Your ad-free, unlocked experience is open.\n\nYou can manage your subscription from your store account at any time.';

  @override
  String get premiumWelcomeButton => 'Great!';

  @override
  String get premiumRestoreSuccess => 'Premium restored!';

  @override
  String get premiumNoActiveSubscription => 'No active subscription found.';

  @override
  String get premiumSignInErrorPrefix => 'Sign in could not be completed: ';

  @override
  String get premiumActiveTitle => 'ARIN Premium is active';

  @override
  String get premiumTitle => 'ARIN Premium';

  @override
  String get premiumActiveSubtitle =>
      'Your ad-free and unlocked experience is open.';

  @override
  String get premiumSubtitle =>
      'Ad-free, uninterrupted and unlocked spiritual routine.';

  @override
  String get premiumYearlyPlanTitle => 'Yearly Premium';

  @override
  String get premiumMostAdvantageousBadge => 'BEST VALUE';

  @override
  String get premiumYearlyPlanSubtitle => 'Yearly Subscription';

  @override
  String premiumYearlyPerMonth(String price) {
    return '$price / month';
  }

  @override
  String get premiumYearlyTrialCta => 'Start 3-day free trial';

  @override
  String get premiumYearlyTrialNote =>
      'Try free for 3 days. After the trial the yearly plan renews automatically; you can cancel anytime.';

  @override
  String get premiumMonthlyCta => 'Subscribe monthly';

  @override
  String get premiumCloseSemantics => 'Close';

  @override
  String get premiumBenefitAi => 'Islamic AI';

  @override
  String get premiumBenefitThemes => 'Premium widget themes';

  @override
  String get premiumSwitchToYearly => 'Switch to Yearly';

  @override
  String get premiumMonthlyPlanTitle => 'Monthly Premium';

  @override
  String get premiumMonthlyPlanSubtitle => 'Monthly Subscription';

  @override
  String get premiumLifetimePlanTitle => 'Lifetime Premium';

  @override
  String get premiumLifetimePlanSubtitle => 'One-time purchase, no renewal';

  @override
  String get premiumLifetimeCta => 'Unlock for life';

  @override
  String get premiumLifetimeNote =>
      'Pay once and keep Premium forever. This is not a subscription and does not auto-renew.';

  @override
  String get premiumLifetimeBadge => 'ONE PAYMENT';

  @override
  String get premiumPlanComingSoon => 'Coming soon';

  @override
  String get premiumYearlySaveVsMonthly => 'Better value than monthly';

  @override
  String get premiumCompareTitle => 'Free vs Premium';

  @override
  String get premiumCompareColFree => 'Free';

  @override
  String get premiumCompareColPremium => 'Premium';

  @override
  String get premiumCompareAds => 'Ads';

  @override
  String get premiumCompareAdsFree => 'Yes';

  @override
  String get premiumCompareAdsPremium => 'None';

  @override
  String get premiumCompareWidgets => 'Widgets';

  @override
  String get premiumCompareWidgetsFree => 'Locked';

  @override
  String get premiumCompareWidgetsPremium => 'Unlocked';

  @override
  String get premiumCompareThemes => 'Widget themes';

  @override
  String get premiumCompareThemesFree => 'Classic';

  @override
  String get premiumCompareThemesPremium => '6 themes';

  @override
  String get premiumCompareAi => 'Islamic AI';

  @override
  String get premiumCompareAiFree => 'Locked';

  @override
  String get premiumCompareAiPremium => 'Unlocked';

  @override
  String get premiumCompareExplore => 'Explore';

  @override
  String get premiumCompareExploreFree => 'With ads';

  @override
  String get premiumCompareExplorePremium => 'Uninterrupted';

  @override
  String get premiumCompareAdhan => '2nd adhan alarm';

  @override
  String get premiumCompareAdhanFree => 'Locked';

  @override
  String get premiumCompareAdhanPremium => 'Included';

  @override
  String get premiumComparePrayer => 'Prayer Circle';

  @override
  String get premiumComparePrayerFree => 'Limited';

  @override
  String get premiumComparePrayerPremium => 'Unlimited';

  @override
  String get premiumCompareContest => 'Contest plays';

  @override
  String get premiumCompareContestFree => 'Limited';

  @override
  String get premiumCompareContestPremium => 'Unlimited';

  @override
  String get premiumGrandfatherNotice =>
      'Your current Premium plan keeps the same price. New prices apply only to new subscriptions.';

  @override
  String get premiumLegacyOwnedPrice => 'Your launch price still applies';

  @override
  String get premiumFooterText1 =>
      'New prices apply only to new subscriptions. Existing subscribers keep their current price. The subscription is managed through your store account and can be canceled at any time.';

  @override
  String get premiumFooterText2 =>
      'The subscription renews automatically unless canceled at least 24 hours before the end of the period. The renewal fee is charged to your store account 24 hours before the end of the period. You can manage your subscriptions in App Store/Play account settings.';

  @override
  String get premiumLaunchBadge => '3 DAYS FREE';

  @override
  String get premiumCountdownNotice =>
      'Try the yearly plan free for 3 days. Existing subscribers keep their current price.';

  @override
  String get premiumBenefitAdFree => 'Ad-free usage';

  @override
  String get premiumBenefitWidgets => 'No widget locks';

  @override
  String get premiumBenefitExplore => 'Uninterrupted explore feed';

  @override
  String get premiumBenefitAdhan => '2nd adhan alarm enabled';

  @override
  String get premiumBenefitPrayerCircle => 'Prayer Circle: unlimited requests';

  @override
  String get premiumBenefitContest => 'Unlimited contest plays';

  @override
  String get premiumBenefitExtras => 'No ads in zikr, compass, and frequencies';

  @override
  String get premiumBenefitAssistant =>
      'Arın Assistant: written chat and in-app actions';

  @override
  String get premiumSignInRequiredNotice =>
      'Sign-in is not required for purchase. You can use Premium on this device right away; optionally link your account afterward to access it on your other devices.';

  @override
  String get premiumSignInSheetTitle => 'Link your account for Premium';

  @override
  String get premiumSignInSheetSubtitle =>
      'Linking your account makes it easier to restore Premium on your other devices. Sign-in is optional for purchase.';

  @override
  String get premiumContinueWithGoogle => 'Continue with Google';

  @override
  String get premiumContinueWithApple => 'Continue with Apple';

  @override
  String get premiumCancelForNow => 'Cancel for now';

  @override
  String get premiumPostPurchaseLinkTitle => 'Premium is active';

  @override
  String get premiumPostPurchaseLinkBody =>
      'Premium is active on this device. Would you like to link your account now so you can easily use it on your other devices?';

  @override
  String get premiumPostPurchaseLinkLater => 'Later';

  @override
  String get premiumPostPurchaseLinkNow => 'Link my account';

  @override
  String get premiumPostPurchaseLinkSuccess =>
      'Account linked. Premium can now be synced across your devices.';

  @override
  String get premiumActivePlanBadge => 'Your active plan ✓';

  @override
  String get premiumActivePlanButton => 'Your active plan';

  @override
  String get premiumStartWithLaunchPrice => 'Start with Launch Price';

  @override
  String get premiumIsActiveButton => 'Premium active';

  @override
  String get qiblaCompassTitle => 'Qibla Compass';

  @override
  String get qiblaCompassQibla => 'Qibla';

  @override
  String get qiblaCompassGettingLocation => 'Getting location…';

  @override
  String get qiblaCompassInitError =>
      'Location or compass\ncould not be initialized';

  @override
  String get qiblaCompassRetry => 'Retry';

  @override
  String get qiblaCompassAligned => 'You are facing the Kaaba';

  @override
  String get qiblaCompassDeviation => 'deviation';

  @override
  String qiblaCompassDistanceKm(Object distance) {
    return '$distance km to the Kaaba';
  }

  @override
  String qiblaCompassDistanceM(Object distance) {
    return '$distance m to the Kaaba';
  }

  @override
  String get qiblaCompassProximityFar => 'The heart\'s compass never strays';

  @override
  String get qiblaCompassProximityApproaching =>
      'Every step is an invitation to Him';

  @override
  String get qiblaCompassProximityMecca =>
      'You are in the blessed lands of the Haramain';

  @override
  String get qiblaCompassProximityHaram =>
      'You stand before the Kaaba, may your prayers be accepted';

  @override
  String get qiblaCompassStabilizing => 'Stabilizing measurement';

  @override
  String get qiblaCompassGuidanceTiltTitle => 'Hold phone flat';

  @override
  String get qiblaCompassGuidanceTiltBody =>
      'Use compass horizontally. Direction won\'t lock if held upright, sideways, or upside down.';

  @override
  String get qiblaCompassGuidanceCalibrateTitle => 'Calibrate compass';

  @override
  String get qiblaCompassGuidanceCalibrateBody =>
      'Move phone in a figure 8 a few times, then keep away from metal.';

  @override
  String get qiblaCompassGuidanceUnstableTitle => 'Magnetic field unstable';

  @override
  String get qiblaCompassGuidanceUnstableBody =>
      'Move away from laptops, magnets, metal tables, and magnetic cases.';

  @override
  String get qiblaCompassGuidanceGoodTitle => 'Measurement ready';

  @override
  String get qiblaCompassGuidanceGoodBody =>
      'Hold phone flat, turn slowly to Qibla. A golden glow appears when aligned.';

  @override
  String get qiblaCompassNorth => 'N';

  @override
  String get qiblaCompassEast => 'E';

  @override
  String get qiblaCompassSouth => 'S';

  @override
  String get qiblaCompassWest => 'W';

  @override
  String get qiblaCompassQiblaText => 'QIBLA';

  @override
  String get zikirmatikCounterSemantics => 'Dhikr counter';

  @override
  String get zikirmatikRound => 'ROUND';

  @override
  String get zikirmatikRoundCompleted => 'Round completed';

  @override
  String get zikirmatikResetCounter => 'Reset counter?';

  @override
  String get zikirmatikResetCounterDesc =>
      'Total count and round information will reset.';

  @override
  String get zikirmatikCancel => 'Cancel';

  @override
  String get zikirmatikReset => 'Reset';

  @override
  String get zikirmatikEditPhraseTitle => 'Edit dhikr name';

  @override
  String get zikirmatikUse => 'Use';

  @override
  String get zikirmatikSaveAndUse => 'Save & Use';

  @override
  String get zikirmatikThisRound => 'THIS ROUND';

  @override
  String get zikirmatikTarget => 'Target';

  @override
  String zikirmatikCounterSemanticsLabel(
    Object round,
    Object target,
    Object total,
  ) {
    return 'Dhikr counter. $round / $target, total $total';
  }

  @override
  String get zikirmatikCounterSemanticsHint => 'Tap to increase by one';

  @override
  String get zikirmatikVibration => 'Vibration';

  @override
  String get zikirmatikVibrationTooltip =>
      'Vibrates on each count; stronger vibration at round end';

  @override
  String get zikirmatikInfo => 'Dhikr info';

  @override
  String get zikirmatikTitle => 'Dhikr Counter';

  @override
  String get zikirmatikTapToChoose => 'Tap to choose dhikr';

  @override
  String get zikirmatikPickDhikr => 'PICK DHIKR';

  @override
  String get zikirmatikSaved => 'SAVED';

  @override
  String get zikirmatikDelete => 'Delete';

  @override
  String get zikirmatikWriteOwnText => 'WRITE YOUR OWN TEXT…';

  @override
  String get zikirmatikCustomTarget => 'Custom…';

  @override
  String get zikirmatikTargetOk => 'OK';

  @override
  String get zikirmatikDeleteRoundRecord => 'Delete this round record?';

  @override
  String get zikirmatikDhikr => 'dhikr';

  @override
  String get zikirmatikShareError =>
      'Share could not be opened. Please try again.';

  @override
  String get zikirmatikDeleteRecord => 'Delete record?';

  @override
  String get zikirmatikCompletedRounds => 'Completed rounds';

  @override
  String get zikirmatikNoCompletedRounds =>
      'No completed rounds yet. They will appear here when you hit your target.';

  @override
  String get zikirmatikArchivedSessions => 'Archived sessions';

  @override
  String get zikirmatikTodaysReflection => 'Today\'s reflection';

  @override
  String zikirmatikCompareLine(Object diff, Object first, Object second) {
    return 'You completed “$first” $diff more rounds than “$second”.';
  }

  @override
  String zikirmatikOnlyOneRecord(Object first) {
    return 'Right now you only have round records for “$first”.';
  }

  @override
  String get zikirmatikSummaryAndAnalytics => 'Summary and analytics';

  @override
  String get zikirmatikAnalyticsNoLogs =>
      'As you complete more rounds, summaries and comparisons appear here.';

  @override
  String zikirmatikTotalRoundsCompleted(Object total) {
    return 'You completed $total rounds in total.';
  }

  @override
  String zikirmatikActiveDays(Object days) {
    return 'You have dhikr records on $days different days.';
  }

  @override
  String zikirmatikLast7Days(Object rounds) {
    return '$rounds rounds were completed in the last 7 days.';
  }

  @override
  String zikirmatikMostCompleted(Object phrase, Object rounds) {
    return 'Most completed: “$phrase” ($rounds rounds).';
  }

  @override
  String get zikirmatikCompleted => 'completed';

  @override
  String get zikirmatikTotalCounter => 'total counter';

  @override
  String get healingAmbientForest => 'Forest Sound';

  @override
  String get healingAmbientFire => 'Fire Sound';

  @override
  String get healingAmbientCosmic => 'Cosmic Sound';

  @override
  String get healingAmbientInshirah => 'Surah Al-Inshirah';

  @override
  String get healingSleepOff => 'Off';

  @override
  String get healingSleepRemaining => 'Remaining ';

  @override
  String healingSleepMinutes(Object m) {
    return '$m minutes';
  }

  @override
  String get healingInfoTitle => 'Info';

  @override
  String get healingInfoBody =>
      'This section is for relaxation and reflection; it is not a medical treatment. Listen at low volume. Stop if you feel discomfort.';

  @override
  String get healingInfoOk => 'OK';

  @override
  String get healingFrequenciesTitle => 'Healing Frequencies';

  @override
  String get healingAmbientSound => 'Ambient Sound';

  @override
  String get healingPresets => 'PRESETS';

  @override
  String get healingFrequencyTone => 'Frequency tone (Hz)';

  @override
  String get healingAmbient => 'Ambient';

  @override
  String get healingSleepTimer => 'Sleep Timer';

  @override
  String get healingInshirahLocked =>
      'Frequency controls are locked in Inshirah mode.';

  @override
  String get healingAllFrequencies => 'All Frequencies';

  @override
  String get healingPresetFocus => 'Focus';

  @override
  String get healingPresetSleep => 'Sleep';

  @override
  String get healingAmbientForestShort => 'Forest';

  @override
  String get healingAmbientFireShort => 'Fire';

  @override
  String get healingAmbientCosmicShort => 'Cosmic';

  @override
  String get healingAmbientInshirahShort => 'Inshirah';

  @override
  String get healingAmbientChoose => 'Choose Ambient Sound';

  @override
  String get healingSleepCancel => 'Cancel';

  @override
  String get healingSleepStopAfter => 'Stop after how many minutes?';

  @override
  String get healingSleepTimerOff => 'Timer off';

  @override
  String get healingFreq174Short => 'Therapy Frequency';

  @override
  String get healingFreq285Short => 'Resilience';

  @override
  String get healingFreq396Short => 'Renewal';

  @override
  String get healingFreq417Short => 'Inner strength';

  @override
  String get healingFreq528Short => 'Peace';

  @override
  String get healingFreq639Short => 'Purification';

  @override
  String get healingFreq741Short => 'Contemplation';

  @override
  String get healingFreq852Short => 'Tranquility';

  @override
  String get healingFreq174Heading => '174 Hz - Healing and Relaxation';

  @override
  String get healingFreq285Heading => '285 Hz - Patience and Steadiness';

  @override
  String get healingFreq396Heading => '396 Hz - Blessing and New Start';

  @override
  String get healingFreq417Heading => '417 Hz - Inner Strength and Faith';

  @override
  String get healingFreq528Heading => '528 Hz - Peace and Calm';

  @override
  String get healingFreq639Heading => '639 Hz - Purification and Cleansing';

  @override
  String get healingFreq741Heading => '741 Hz - Reflection and Focus';

  @override
  String get healingFreq852Heading => '852 Hz - Tranquility (Deep Peace)';

  @override
  String get healingFreq174Body =>
      'Turn toward calm in physical and spiritual fatigue; healing is from Allah.';

  @override
  String get healingFreq285Body =>
      'Soften the heart in hardship; continue with trust in Allah.';

  @override
  String get healingFreq396Body =>
      'Open a new page; a prayer for repentance and forgiveness.';

  @override
  String get healingFreq417Body =>
      'Strengthen the heart; renew faith and remember right direction.';

  @override
  String get healingFreq528Body =>
      'Inner calm; breathe with gratitude and surrender.';

  @override
  String get healingFreq639Body =>
      'Step away from thoughts that cloud the heart; seek forgiveness.';

  @override
  String get healingFreq741Body =>
      'Focus on verses and creation; gather a scattered mind.';

  @override
  String get healingFreq852Body =>
      'A calm that brings relief to the heart; seek Allah’s mercy.';

  @override
  String get appleSignInCanceled => 'Apple sign in canceled.';

  @override
  String get appleSignInNotAuthorized =>
      'Apple account not authorized. Check Apple sign in permission from iPhone Settings > Apple ID > Sign-In & Security.';

  @override
  String get appleSignInProviderDisabled =>
      'Apple sign in provider appears disabled in Firebase console.';

  @override
  String get appleSignInInvalidCredential =>
      'Invalid Apple authentication credential. Check Bundle ID and Apple Sign In capabilities on Xcode/Firebase.';

  @override
  String get appleSignInNetworkFailed =>
      'Apple sign in could not be completed due to network connection.';

  @override
  String get settingsMenuPremiumTitle => 'ARIN Premium';

  @override
  String get settingsMenuPremiumSubtitle =>
      'Launch prices and ad-free experience';

  @override
  String get settingsMenuWidgetsTitle => 'Widget Center';

  @override
  String get settingsMenuWidgetsSubtitle => 'Usage info and tracking widget';

  @override
  String get supportProductNotReady =>
      'Product information is not ready yet. Please try again.';

  @override
  String get supportThanksTitle => 'Thank You! 🙏';

  @override
  String get supportThanksBody =>
      'Your support is very valuable to Arın. With this contribution, we will continue to provide a better experience.';

  @override
  String get commonOk => 'OK';

  @override
  String get supportPageTitle => 'Support Arın';

  @override
  String get supportTierSmallTitle => 'Small Support';

  @override
  String get supportTierSmallDesc =>
      'Contribute to development with a coffee support.';

  @override
  String get supportTierMediumTitle => 'Medium Support';

  @override
  String get supportTierMediumDesc =>
      'Accelerate the development of new content and features.';

  @override
  String get supportTierLargeTitle => 'Large Support';

  @override
  String get supportTierLargeDesc =>
      'Make a strong contribution to Arın\'s long-term development.';

  @override
  String get supportPackagesDisclaimer =>
      'Support packages work as one-time store products. They are separate from Premium subscription.';

  @override
  String get supportHeaderTitle => 'Stand with Arın';

  @override
  String get supportHeaderDesc =>
      'Not a donation, but one-time support packages compliant with store rules. They help us grow the ad-free and premium experience of the app.';

  @override
  String get languageChangeFailed =>
      'Language could not be changed. Please try again.';

  @override
  String get differentLocation => 'You are in a different location';

  @override
  String updatePrayerTimesForCity(Object city) {
    return 'Should we update prayer times for $city?';
  }

  @override
  String get rememberThisChoice => 'Remember this choice, do not ask again';

  @override
  String get keepCurrentLocation => 'Keep';

  @override
  String get updateLocation => 'Update';

  @override
  String get settingsBackgroundLocationTitle =>
      'Update automatically in the background';

  @override
  String get settingsBackgroundLocationSubtitle =>
      'When on, prayer times update by themselves as soon as your city changes, without opening the app.';

  @override
  String get settingsBackgroundLocationPermissionDenied =>
      'For background updates, set location permission to \"Allow all the time\" in your phone settings.';

  @override
  String get settingsBackgroundLocationEnabledMessage =>
      'Background automatic updates turned on.';

  @override
  String get settingsBackgroundLocationDisabledMessage =>
      'Background automatic updates turned off.';

  @override
  String get backgroundLocationDisclosureTitle => 'Background Location Use';

  @override
  String get backgroundLocationDisclosureBody =>
      'If you allow \"Allow all the time\", Arın checks your location in the background at a low frequency, even when the app is closed. This lets prayer times, qibla direction, and prayer notifications update automatically when your city changes, without opening the app. Your location data is processed only on your device and is never used for ads or analytics.';

  @override
  String get backgroundLocationDisclosureDecline => 'Cancel';

  @override
  String get backgroundLocationDisclosureAccept => 'Continue';

  @override
  String get sealYourIntention => 'Seal your intention';

  @override
  String get sealIntentionInfo =>
      'The details you just shared are part of this beginning; hold to reinforce your intention.';

  @override
  String get touchAndHoldWhenReady => 'Touch and hold when you are ready.';

  @override
  String get youAreAlmostThere => 'You are almost there!';

  @override
  String get promiseSealed => 'Congratulations, your promise is sealed!';

  @override
  String get touchAndHoldToContinue =>
      'Touch and hold the screen\nTo continue…';

  @override
  String get skipWithArrow => 'Skip ➔';

  @override
  String get redirecting => 'Redirecting...';

  @override
  String get keepGoing => 'Keep going...';

  @override
  String get premiumLoadingWait =>
      'Loading premium status. Please try again shortly.';

  @override
  String get secondAlarmPremiumFeature => '2nd alarm premium feature';

  @override
  String get secondAlarmAdWatchText =>
      'To unlock the 2nd azan alarm for 2 days in free usage, a short ad is watched. Premium users do not see this lock.';

  @override
  String get giveUp => 'Give up';

  @override
  String get openAfterAd => 'Open after ad';

  @override
  String get reflection => 'Reflection';

  @override
  String yesterdayPrayerSummary(Object avg, Object weekday, Object yDone) {
    return 'Yesterday · $weekday · $yDone/5  ·  Last 7 days avg. $avg/5';
  }

  @override
  String get weeklyView => 'Weekly view';

  @override
  String daysDoneSummary(Object done) {
    return '$done/7 days';
  }

  @override
  String get inspirationAndAwareness => 'Inspiration and awareness';

  @override
  String get shortBreaksForTruth => 'Short breaks for truth and consciousness';

  @override
  String get insightCommentStrong =>
      'Your rhythm is very strong recently; your heart seems aligned with order. Keep it up.';

  @override
  String get insightCommentPerfect =>
      'Five times completed yesterday — you\'ve spent a day close to your Lord. You can continue with the same intention today.';

  @override
  String get insightCommentZero =>
      'Yesterday might not have been recorded or checked yet. Even with a single prayer today, you can redraw the line.';

  @override
  String get insightCommentLow =>
      'The average is low this week; this is normal — it rises with reflection and small steps. One more prayer makes a big difference.';

  @override
  String insightCommentGood(Object count) {
    return '$count/5 prayers marked yesterday; it\'s possible to complete the balance with one or two prayers today.';
  }

  @override
  String get insightCommentDefault =>
      'Past days\' data is a mirror for you: mercy in the missing parts, gratitude in the completed ones.';

  @override
  String get qiblaHubPrayerCircleTitle => 'Prayer Circle';

  @override
  String get qiblaHubPrayerCircleSubtitle =>
      'Share a prayer request and join with sincerity';

  @override
  String get prayerCircleTitle => 'Prayer Circle';

  @override
  String get prayerCircleHeroTitle => 'Join a prayer wholeheartedly';

  @override
  String get prayerCircleHeroBody =>
      'Anonymous prayer requests meet here. Let us quietly say amen to one another\'s intentions.';

  @override
  String get prayerCircleTwentyFourHours => 'Each request remains for 24 hours';

  @override
  String get prayerCircleAll => 'Prayer circle';

  @override
  String get prayerCircleMine => 'My prayers';

  @override
  String get prayerCircleCreate => 'Send a prayer request';

  @override
  String get prayerCircleEmptyTitle => 'The circle is waiting for a prayer';

  @override
  String get prayerCircleEmptyBody =>
      'Share the first prayer request and begin this circle of kindness.';

  @override
  String get prayerCircleMineEmptyTitle => 'You have no prayer requests yet';

  @override
  String get prayerCircleMineEmptyBody =>
      'Share your intention anonymously; it will remain here for 24 hours.';

  @override
  String get prayerCircleLoadFailed => 'The prayer circle could not load';

  @override
  String get prayerCircleTryAgain => 'Try again';

  @override
  String get prayerCircleComposeTitle => 'Write your prayer request';

  @override
  String get prayerCircleComposeBody =>
      'Share a brief, sincere intention without personal information.';

  @override
  String get prayerCircleHint =>
      'For example: Please pray for my family\'s health and peace…';

  @override
  String get prayerCircleCategory => 'Intention';

  @override
  String get prayerCircleCategoryGeneral => 'General';

  @override
  String get prayerCircleCategoryHealth => 'Health';

  @override
  String get prayerCircleCategoryFamily => 'Family';

  @override
  String get prayerCircleCategoryPeace => 'Peace';

  @override
  String get prayerCircleCategoryEducation => 'Education';

  @override
  String get prayerCircleCategoryWork => 'Work & provision';

  @override
  String get prayerCirclePrivacyNote =>
      'For your safety, do not share names, phone numbers, social media, payment details, or links. Automated checks and user reports are used, but you remain responsible for withholding personal information.';

  @override
  String get prayerCircleContinue => 'Continue to send';

  @override
  String get prayerCircleTooShort =>
      'Your prayer request must be at least 8 characters.';

  @override
  String get prayerCircleAdGateTitle => 'Add your prayer to the circle';

  @override
  String get prayerCircleAdGateBody =>
      'Free users watch one short rewarded ad for each request. Premium users never see this ad.';

  @override
  String get prayerCircleWatchAd => 'Watch ad and send';

  @override
  String get prayerCirclePremiumOption => 'Send ad-free with Premium';

  @override
  String get prayerCircleAdFailed =>
      'The ad is not ready right now. Please try again shortly.';

  @override
  String get prayerCircleSent =>
      'Your prayer request joined the circle. May it bring goodness.';

  @override
  String get prayerCirclePray => 'I prayed';

  @override
  String get prayerCirclePrayed => 'You joined';

  @override
  String get prayerCircleOwnRequest => 'Your prayer';

  @override
  String get prayerCircleYours => 'Your request';

  @override
  String get prayerCirclePrayedThanks =>
      'Amen. You joined this prayer wholeheartedly.';

  @override
  String get prayerCircleAlreadyPrayed =>
      'You have already joined this prayer.';

  @override
  String prayerCirclePrayerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people prayed',
      one: '1 person prayed',
      zero: 'No one has prayed yet',
    );
    return '$_temp0';
  }

  @override
  String prayerCircleHoursLeft(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hr left',
      one: '1 hr left',
    );
    return '$_temp0';
  }

  @override
  String prayerCircleMinutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min left',
      one: '1 min left',
    );
    return '$_temp0';
  }

  @override
  String get prayerCircleLoadMore => 'Load more requests';

  @override
  String get prayerCircleReportTitle => 'Report this prayer request?';

  @override
  String get prayerCircleReportBody =>
      'Reports help keep the circle safe and respectful. We will review this request.';

  @override
  String get prayerCircleReportAction => 'Report';

  @override
  String get prayerCircleReported => 'Thank you. This request was reported.';

  @override
  String get prayerCircleAcceptRulesLabel =>
      'Your request is shared anonymously and must follow the community rules.';

  @override
  String get prayerCircleAcceptRulesRequired =>
      'Please confirm the community rules before sending.';

  @override
  String get prayerCircleMoreActions => 'More actions';

  @override
  String get prayerCircleDeleteTitle => 'Remove your prayer request?';

  @override
  String get prayerCircleDeleteBody =>
      'The request will be removed from the circle immediately and cannot be restored.';

  @override
  String get prayerCircleDeleteAction => 'Remove';

  @override
  String get prayerCircleAdminDeleteTitle => 'Remove this request as an admin?';

  @override
  String get prayerCircleAdminDeleteBody =>
      'It will be permanently removed as inappropriate content and cannot be restored.';

  @override
  String get prayerCircleAdminDeleteAction => 'Admin: Remove';

  @override
  String get prayerCircleAdminDeleted => 'Request removed by an admin.';

  @override
  String get prayerCircleCancel => 'Cancel';

  @override
  String get prayerCircleSlowDown =>
      'You are acting too quickly. Please try again shortly.';

  @override
  String get prayerCircleContentRejected =>
      'Check the text and remove personal, contact, or payment information.';

  @override
  String get prayerCircleExpired => 'This prayer request may have expired.';

  @override
  String get prayerCircleGenericError =>
      'The action could not be completed. Check your connection and try again.';

  @override
  String get appTourNext => 'Continue';

  @override
  String get appTourSkip => 'Skip';

  @override
  String get appTourLetsStart => 'Let\'s get started!';

  @override
  String appTourProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get appTourHomeHeaderTitle => 'Your home';

  @override
  String get appTourHomeHeaderBody =>
      'Your greeting, name, and next-prayer countdown live here. Tap your name to change how we address you.';

  @override
  String get appTourHomeWisdomTitle => 'Daily wisdom';

  @override
  String get appTourHomeWisdomBody =>
      'A prayer insight each day. Swipe the card to refresh or save it.';

  @override
  String get appTourHomeNamazTitle => 'Prayer tracking';

  @override
  String get appTourHomeNamazBody =>
      'Mark the prayers, keep your streak. Makeup prayers and reminders are here too.';

  @override
  String get appTourHomePrayerTimesTitle => 'Prayer times';

  @override
  String get appTourHomePrayerTimesBody =>
      'Times for your district. You can change the location in Settings.';

  @override
  String get appTourNavToolsTitle => 'Tools';

  @override
  String get appTourNavToolsBody =>
      'Qibla, dhikr, the prayer circle, and other spiritual tools live on this tab.';

  @override
  String get appTourQiblaAssistantTitle => 'Arin Assistant';

  @override
  String get appTourQiblaAssistantBody =>
      'Manage prayer, notifications, and reminders through chat.';

  @override
  String get appTourQiblaAiTitle => 'Islamic AI';

  @override
  String get appTourQiblaAiBody =>
      'Answers grounded in Islamic sources. Unlocks with Premium.';

  @override
  String get appTourQiblaCompassTitle => 'Qibla compass';

  @override
  String get appTourQiblaCompassBody =>
      'Shows the direction of the Kaaba from your location.';

  @override
  String get appTourQiblaZikirTitle => 'Dhikr counter';

  @override
  String get appTourQiblaZikirBody =>
      'A digital tasbih with goals, rounds, and dhikr notes.';

  @override
  String get appTourQiblaHilalTitle => 'Knowledge duel';

  @override
  String get appTourQiblaHilalBody =>
      'Quiz yourself with Islamic questions and sharpen what you know.';

  @override
  String get appTourQiblaPrayerCircleTitle => 'Prayer circle';

  @override
  String get appTourQiblaPrayerCircleBody =>
      'Share an intention anonymously, and say amen to others.';

  @override
  String get appTourQiblaHealingTitle => 'Healing frequencies';

  @override
  String get appTourQiblaHealingBody =>
      'Calming sounds to gather your breath and focus.';

  @override
  String get appTourQiblaBreathingTitle => 'Breathing exercise';

  @override
  String get appTourQiblaBreathingBody =>
      'Use the 4-7-8 cycle to settle in a stressful moment.';

  @override
  String get appTourNavWillpowerTitle => 'Growth and purification';

  @override
  String get appTourNavWillpowerBody =>
      'Habit tracking and quit programs live in this triangle.';

  @override
  String get appTourWillpowerTabsTitle => 'Growth and purification';

  @override
  String get appTourWillpowerTabsBody =>
      'Growth is for habits you want to keep. Purification is for what you want to leave.';

  @override
  String get appTourWillpowerBreathingTitle => 'Breath';

  @override
  String get appTourWillpowerBreathingBody =>
      'In a hard moment, open the breathing exercise from here.';

  @override
  String get appTourWillpowerAddTitle => 'New program';

  @override
  String get appTourWillpowerAddBody =>
      'Use plus to add a growth habit or a purification program.';

  @override
  String get appTourNavExploreTitle => 'Explore';

  @override
  String get appTourNavExploreBody =>
      'Verses, hadith, and quotes — swipe, save, and share.';

  @override
  String get appTourInspireSearchTitle => 'Search';

  @override
  String get appTourInspireSearchBody =>
      'Type a word; unaccented search works too.';

  @override
  String get appTourInspireFilterTitle => 'Filter';

  @override
  String get appTourInspireFilterBody =>
      'Narrow the feed to quotes, verses, or hadith.';

  @override
  String get appTourNavSettingsTitle => 'Settings';

  @override
  String get appTourNavSettingsBody =>
      'Notifications, language, widgets, and your account are here.';

  @override
  String get appTourSettingsNotificationsTitle => 'Notifications';

  @override
  String get appTourSettingsNotificationsBody =>
      'Manage adhan, purification, and dhikr reminders here.';

  @override
  String get appTourSettingsWidgetsTitle => 'Widget Center';

  @override
  String get appTourSettingsWidgetsBody =>
      'Unlock home-screen and lock-screen widgets here.';

  @override
  String get appTourSettingsLanguageTitle => 'Language';

  @override
  String get appTourSettingsLanguageBody =>
      'Choose Turkish, English, or Arabic.';

  @override
  String get appTourAssistantFabTitle => 'Assistant bubble';

  @override
  String get appTourAssistantFabBody =>
      'A draggable shortcut that opens the assistant on any tab.';

  @override
  String get appTourFinaleTitle => 'You are ready';

  @override
  String get appTourFinaleBody =>
      'The tour is over. Continue from any tab — we will remind you and walk with you.';

  @override
  String get appTourWidgetPromptTitle => 'Would you like to add a widget?';

  @override
  String get appTourWidgetPromptBody =>
      'Keep a short verse or prayer time on your home and lock screens. We can add it now from Widget Center.';

  @override
  String get appTourWidgetPromptYes => 'Yes';

  @override
  String get appTourWidgetPromptLater => 'Later';
}
