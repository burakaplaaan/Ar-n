// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get languageSettingsTitle => 'إعدادات اللغة';

  @override
  String get languageSettingsSheetTitle => 'لغة التطبيق';

  @override
  String get languageTurkishLabel => 'التركية';

  @override
  String get languageEnglishLabel => 'الإنجليزية';

  @override
  String get languageArabicLabel => 'العربية';

  @override
  String get settingsPageHeader => 'الإعدادات';

  @override
  String get settingsSectionAccount => 'حسابك';

  @override
  String get settingsSectionAppearance => 'المظهر';

  @override
  String get settingsSectionPrayerTimes => 'مواقيت الصلاة';

  @override
  String get settingsSectionApp => 'التطبيق';

  @override
  String get settingsSectionSession => 'الجلسة';

  @override
  String get settingsMenuNotificationsSubtitle => 'الصلاة والتزكية والذكر';

  @override
  String get settingsMenuNotificationsTitle => 'الإشعارات';

  @override
  String get settingsMenuAboutTitle => 'حول';

  @override
  String get settingsMenuAboutSubtitle => 'معلومات التطبيق';

  @override
  String get settingsMenuPrivacyTitle => 'سياسة الخصوصية';

  @override
  String get settingsMenuPrivacySubtitle => 'كيف نعالج بياناتك';

  @override
  String get settingsMenuSavedTitle => 'المحفوظات';

  @override
  String get settingsMenuSavedSubtitle => 'الأقوال التي حفظتها في الاستكشاف';

  @override
  String get settingsMenuAdminTitle => 'إدارة المحتوى';

  @override
  String get settingsMenuAdminSubtitle => 'مخازن الأقوال والاستكشاف';

  @override
  String get settingsMenuContactTitle => 'تواصل معنا';

  @override
  String get settingsMenuContactSubtitle => 'الدعم والملاحظات';

  @override
  String get settingsMenuSupportTitle => 'ادعم Arin';

  @override
  String get settingsMenuSupportSubtitle => 'حزم دعم لمرة واحدة';

  @override
  String get settingsMenuComingSoon => 'راسلنا عبر البريد';

  @override
  String get settingsContactPageTitle => 'تواصل معنا';

  @override
  String get settingsContactSubtitle =>
      'يمكنك إرسال الاقتراحات أو بلاغات الأعطال أو طلبات الدعم مباشرة عبر البريد الإلكتروني.';

  @override
  String get settingsContactOpenMailAction => 'فتح تطبيق البريد';

  @override
  String get settingsContactCopyMailAction => 'نسخ عنوان البريد';

  @override
  String get settingsContactEmailCopied => 'تم نسخ عنوان البريد.';

  @override
  String get settingsContactOpenFailed =>
      'تعذر فتح تطبيق البريد. يمكنك نسخ العنوان والإرسال يدويًا.';

  @override
  String get settingsContactCopyFailed =>
      'تعذر نسخ عنوان البريد. الرجاء إدخاله يدويًا: arinapphelp@gmail.com';

  @override
  String get settingsContactMailSubject => 'ملاحظات تطبيق Arin';

  @override
  String get settingsContactMailBody => 'مرحبًا فريق Arin،\n\n';

  @override
  String get settingsGuestHint =>
      'وضع الضيف — بياناتك محفوظة على هذا الجهاز. سجّل الدخول للمزامنة السحابية.';

  @override
  String get settingsAccountFallback => 'الحساب';

  @override
  String get settingsSignInGoogle => 'تسجيل الدخول عبر Google';

  @override
  String get settingsSignInApple => 'تسجيل الدخول عبر Apple';

  @override
  String get settingsSessionHint => 'لإعادة ضبط التطبيق أو إزالة الحساب:';

  @override
  String get settingsSignOutAction => 'تسجيل الخروج';

  @override
  String get settingsDeleteAccountAction => 'حذف الحساب وجميع البيانات';

  @override
  String get settingsLightThemeTitle => 'الثيم الفاتح';

  @override
  String get settingsLightThemeSubtitle => 'خلفية فاتحة أهدأ لقراءة أسهل';

  @override
  String get settingsProvinceLabel => 'المدينة';

  @override
  String get settingsProvinceHint => 'اكتب مثلاً: \"ko\" ← Kocaeli';

  @override
  String get settingsProvinceInvalid =>
      'اختر مدينة من القائمة أو تابع الكتابة.';

  @override
  String settingsLocationUpdatedMessage(Object city) {
    return 'تم تحديث الموقع: $city';
  }

  @override
  String get settingsLocationFailedMessage =>
      'تعذر الحصول على الموقع؛ تحقق من الإذن أو GPS.';

  @override
  String settingsProvinceUpdatedMessage(Object province) {
    return '$province — تم تحديث مواقيت الصلاة';
  }

  @override
  String get settingsSignOutDialogTitle => 'تسجيل الخروج';

  @override
  String get settingsSignOutDialogBody =>
      'سيتم إعادة ضبط التطبيق بدءاً من شرائح التعريف. ستُحذف جميع البيانات المحلية على هذا الجهاز وسيتم إنهاء جلسة Firebase.';

  @override
  String get settingsDialogCancel => 'إلغاء';

  @override
  String get settingsDeleteAllDataDialogTitle => 'حذف جميع البيانات';

  @override
  String get settingsDeleteAllDataDialogBody =>
      'أنت في وضع الضيف. سيتم حذف جميع بيانات التطبيق على هذا الجهاز نهائياً وستعود إلى شاشات التعريف.';

  @override
  String get settingsDeleteAction => 'حذف';

  @override
  String get settingsDeleteAccountDialogTitle => 'حذف الحساب نهائياً';

  @override
  String get settingsDeleteAccountDialogBody =>
      'سيتم حذف حسابك السحابي كما سيتم مسح جميع البيانات المحلية على هذا الجهاز. لا يمكن التراجع عن ذلك.';

  @override
  String get settingsDeleteProgressMessage =>
      'جارٍ حذف بيانات السحابة والجهاز…';

  @override
  String get settingsCloudDeleteFailedMessage =>
      'تعذر حذف بيانات السحابة. تحقق من اتصال الإنترنت وحاول مرة أخرى.';

  @override
  String get settingsAccountDeleteFailedMessage => 'تعذر حذف الحساب.';

  @override
  String get settingsAccountDeleteRetryMessage =>
      'تعذر حذف الحساب. يرجى المحاولة لاحقاً.';

  @override
  String get settingsGoogleSignInSuccess => 'تم تسجيل الدخول عبر Google.';

  @override
  String get settingsGoogleSignInCancelled =>
      'تم إلغاء تسجيل الدخول عبر Google.';

  @override
  String get settingsGoogleSignInFailed =>
      'فشل تسجيل الدخول عبر Google. حاول مرة أخرى.';

  @override
  String get settingsAppleSignInSuccess => 'تم تسجيل الدخول عبر Apple.';

  @override
  String get settingsAppleSignInFailed =>
      'فشل تسجيل الدخول عبر Apple. حاول مرة أخرى.';

  @override
  String get settingsAuthServiceUnavailable =>
      'خدمة تسجيل الدخول غير متاحة حالياً. حاول بعد قليل.';

  @override
  String get homeGreetingNight => 'مساء الخير';

  @override
  String get homeGreetingMorning => 'صباح الخير';

  @override
  String get homeGreetingNoon => 'نهارك سعيد';

  @override
  String get homeGreetingEvening => 'مساء الخير';

  @override
  String get homeGuestUser => 'ضيف';

  @override
  String homePrayerUrgentSemanticsLabel(Object remaining) {
    return 'تنبيه، وقت الفجر يوشك أن يخرج. يتبقى للشروق $remaining';
  }

  @override
  String homePrayerNextSemanticsLabel(Object nextName, Object remaining) {
    return 'الصلاة التالية $nextName، المتبقي $remaining';
  }

  @override
  String get homePrayerUrgentBadge => 'يوشك أن يخرج';

  @override
  String get homePrayerNextBadge => 'التالي';

  @override
  String get homePrayerTimesTitle => 'مواقيت الصلاة';

  @override
  String get homePrayerNextRowHint => 'الصلاة القادمة';

  @override
  String get homePrayerLoadFailedTitle => 'تعذر تحميل المواقيت';

  @override
  String get homePrayerLoadFailedBody =>
      'قد يتعذر جلب المواقيت بسبب الإنترنت أو إذن الموقع أو الحي المحدد.';

  @override
  String get homeRetryAction => 'إعادة المحاولة';

  @override
  String get homeChangeDistrictAction => 'تغيير الحي';

  @override
  String get homeOpenSettingsAction => 'فتح الإعدادات';

  @override
  String get homeRemainingPassed => 'انتهى';

  @override
  String get homeRemainingFewSeconds => 'ثوانٍ قليلة';

  @override
  String homeRemainingHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String homeRemainingHoursOnly(int hours) {
    return '$hours س';
  }

  @override
  String homeRemainingMinutesOnly(int minutes) {
    return '$minutes د';
  }

  @override
  String get homeLocationFreshNow => 'الموقع مُحدَّث';

  @override
  String homeLocationFreshMinutesAgo(int minutes) {
    return 'تم التحديث قبل $minutes د';
  }

  @override
  String homeLocationFreshHoursAgo(int hours) {
    return 'تم التحديث قبل $hours س';
  }

  @override
  String homeLocationFreshDaysAgo(int days) {
    return 'تم التحديث قبل $days يوم';
  }

  @override
  String get homeDailyReminderTitle => 'تذكير اليوم';

  @override
  String get homeNamazSetupTitle => 'إعداد متابعة الصلاة';

  @override
  String get homeNamazSetupSubtitle =>
      'قم بالإعداد من تبويب التطور؛ وبعد الإعداد ستظهر البطاقة هنا تلقائياً.';

  @override
  String get homeNamazTrackingTitle => 'متابعة الصلاة';

  @override
  String homeNamazTrackingProgressLine(Object done) {
    return 'اليوم $done/5 · اضغط للتفاصيل';
  }

  @override
  String get onboardingNotificationPermissionDenied =>
      'لم يتم منح إذن الإشعارات. يمكنك تفعيله لاحقاً من الإعدادات ← الإشعارات لتذكيرات الأذان.';

  @override
  String onboardingGenderPromptWithName(Object name) {
    return '$name، هل يمكننا معرفة جنسك؟';
  }

  @override
  String get onboardingNotificationSkippedWarning =>
      'بقيت الإشعارات مغلقة. لن تصلك تذكيرات الأذان في أوقات الصلاة — يمكنك تفعيلها لاحقاً من الإعدادات ← الإشعارات.';

  @override
  String get onboardingOpenNowAction => 'فعّل الآن';

  @override
  String get commonPreview => 'معاينة';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonDone => 'تم';

  @override
  String get commonBack => 'رجوع';

  @override
  String get prayerNameImsak => 'الفجر';

  @override
  String get prayerNameSunrise => 'الشروق';

  @override
  String get prayerNameDhuhr => 'الظهر';

  @override
  String get prayerNameAsr => 'العصر';

  @override
  String get prayerNameMaghrib => 'المغرب';

  @override
  String get prayerNameIsha => 'العشاء';

  @override
  String get reminderOff => 'مغلق';

  @override
  String get reminderAtExactTime => 'في الوقت تماماً';

  @override
  String reminderMinutesBefore(int minutes) {
    return 'قبل $minutes د';
  }

  @override
  String get reminderCardSubtitle => 'إعداد منفصل لكل صلاة · اضغط لتعديل المدد';

  @override
  String get reminderFirstOff => 'الأول مغلق';

  @override
  String reminderFirstValue(Object value) {
    return 'الأول $value';
  }

  @override
  String reminderPairSecondOff(Object first) {
    return '$first · الثاني مغلق';
  }

  @override
  String reminderPairSecondValue(Object first, Object second) {
    return '$first · الثاني $second';
  }

  @override
  String get reminderPermissionRequiredMessage =>
      'إذن الإشعارات مطلوب. يمكنك تفعيله من الإعدادات.';

  @override
  String get reminderPrayerNotificationTitle => 'إشعارات الصلاة';

  @override
  String get reminderCardDisabledHint => 'مغلق · فعّل المفتاح واضبط الأوقات';

  @override
  String get reminderLocalNotificationUnavailable =>
      'الإشعارات المحلية غير متاحة في هذه البيئة.';

  @override
  String get reminderSectionTitle => 'التذكير';

  @override
  String get reminderTwoAlertsPerPrayer => 'تنبيهان لكل صلاة';

  @override
  String get reminderPerPrayerDifferentSounds => 'أصوات مختلفة لكل صلاة';

  @override
  String reminderCurrentSound(Object summary) {
    return 'الحالي: $summary';
  }

  @override
  String get reminderUsePhoneDefaultSubtitle =>
      'يُستخدم صوت الإشعار المضبوط في إعدادات الهاتف.';

  @override
  String get reminderChooseArinSoundsTitle => 'اختر من أصوات أرين';

  @override
  String get reminderChooseArinSoundsSubtitle =>
      'استمع إلى نغمات الأذان والهدوء ثم طبّق.';

  @override
  String get reminderPhoneSoundActiveAllPrayers =>
      'الصوت المختار من الهاتف مفعّل لكل الصلوات.';

  @override
  String get reminderApplyOwnSoundAllPrayers =>
      'طبّق ملفك الصوتي الخاص على كل الصلوات.';

  @override
  String get reminderSetPerPrayerDifferentSound =>
      'اضبط صوتاً مختلفاً لكل صلاة';

  @override
  String get reminderAllPrayersSoundTitle => 'الصوت لكل الصلوات';

  @override
  String get reminderAllPrayersSoundSubtitle =>
      'اختر مرة واحدة لتشغيل نفس الصوت لكل الصلوات.';

  @override
  String get reminderBackToSingleSoundSelection =>
      'العودة لاختيار الصوت الواحد';

  @override
  String get reminderPerPrayerSavedInstantly => 'اختيارات كل صلاة تُحفظ فوراً.';

  @override
  String get reminderEnableNotificationsAction => 'تفعيل الإشعارات';

  @override
  String get reminderDurationsPerPrayerTitle => 'المدد لكل صلاة';

  @override
  String get reminderDurationsPerPrayerSubtitle =>
      'اضغط السطر لاختيار التنبيه الأول والثاني بشكل منفصل.';

  @override
  String get reminderApplyDurationsAllButton =>
      'تطبيق المدد المختارة على كل الصلوات';

  @override
  String get reminderAllPrayersDurationTarget => 'كل الصلوات';

  @override
  String get reminderDurationsAppliedAllSuccess =>
      'تم تطبيق المدد على كل الصلوات.';

  @override
  String reminderDualAlertTitle(Object prayerTitle) {
    return 'تنبيهان — $prayerTitle';
  }

  @override
  String get reminderDualAlertSubtitle =>
      'التنبيه الأول: مغلق أو في الوقت أو قبله بدقائق. التنبيه الثاني: مغلق أو قبله بدقائق.';

  @override
  String get reminderFirstAlertTitle => 'التنبيه الأول';

  @override
  String get reminderSecondAlertTitle => 'التنبيه الثاني';

  @override
  String get prayerSoundPickerTitle => 'صوت الإشعار';

  @override
  String get prayerSoundQuickAllSubtitle =>
      'اختر صوتاً واحداً أولاً؛ وإذا أردت يمكنك التفصيل حسب كل صلاة من الإعدادات المتقدمة.';

  @override
  String get prayerSoundApplyAllButton => 'تطبيق الصوت المختار على كل الصلوات';

  @override
  String get prayerSoundAdvancedToggle => 'إعدادات متقدمة (لكل صلاة)';

  @override
  String get prayerSoundAppliedAllSuccess =>
      'تم تطبيق الصوت المختار على كل الصلوات.';

  @override
  String get prayerSoundSystem => 'الصوت الافتراضي للهاتف';

  @override
  String get prayerSoundAdhanTurkish =>
      'أذان — معالجة تركية (10 ثوانٍ من البداية)';

  @override
  String get prayerSoundAdhanDubai => 'أذان — دبي / رمضان (9 ثوانٍ من البداية)';

  @override
  String get prayerSoundAmbientFlute => 'هدوء — نغمة فلوت (6 ثوانٍ من البداية)';

  @override
  String get prayerSoundAmbientPianoGuitar =>
      'هدوء — بيانو وغيتار (7 ثوانٍ من البداية)';

  @override
  String get prayerSoundAmbientEthereal =>
      'هدوء — أصوات حالمة (10 ثوانٍ من البداية)';

  @override
  String get prayerSoundPickFromPhone => 'اختر صوتاً من الهاتف';

  @override
  String get prayerSoundClearUserFile => 'إزالة';

  @override
  String get prayerSoundUserFromPhone => 'الصوت المختار من الهاتف';

  @override
  String get prayerSoundUserFileActiveHint =>
      'حالياً تُستخدم لهذا الوقت ملفك المختار من الهاتف. إذا اخترت صوتاً من الكتالوج فسيُزال الملف.';

  @override
  String get prayerSoundSubtitlePerPrayer =>
      'لكل صلاة بشكل مستقل: صوت الهاتف الافتراضي، أو نغمة من الكتالوج، أو ملفك من الهاتف. احفظ عبر التطبيق.';

  @override
  String get prayerSoundImportFailed =>
      'تعذر استيراد ملف الصوت. جرّب ملفاً أو تنسيقاً آخر (WAV, M4A...).';

  @override
  String get prayerSoundPreviewSystem =>
      'لا توجد معاينة — سيتم استخدام صوت الإشعار الافتراضي في جهازك.';

  @override
  String get commonStart => 'ابدأ';

  @override
  String get commonRestart => 'إعادة';

  @override
  String get willpowerHabitNotFound => 'لم يتم العثور على العادة';

  @override
  String get namazProgramHomeHintActive =>
      'تم تفعيل تتبع الصلاة. سيظهر الآن أيضاً في بطاقة الصفحة الرئيسية.';

  @override
  String get namazProgramPageTitle => 'العبادة';

  @override
  String get namazProgramVerseQuote =>
      '\"ألا بذكر الله تطمئن القلوب.\"\n(سورة الرعد، 13:28 — ترجمة)';

  @override
  String get namazProgramBreathingBreak => 'استراحة تنفّس';

  @override
  String get namazProgramTodayPrayersTitle => 'صلوات اليوم';

  @override
  String namazProgramTodayProgress(int done) {
    return '$done/5 مكتمل';
  }

  @override
  String namazProgramPercentDone(int percent) {
    return 'اكتمل %$percent';
  }

  @override
  String get namazProgramSystemNotificationSettings => 'إعدادات إشعارات النظام';

  @override
  String get namazProgramRecentDaysTitle => 'الأيام الأخيرة';

  @override
  String get namazProgramRecentDaysSubtitle =>
      'كل مربع يوضح عدد الصلوات المؤداة في ذلك اليوم (مثال 3/5).';

  @override
  String get breathingPhaseInhale => 'شهيق';

  @override
  String get breathingPhaseHold => 'حبس';

  @override
  String get breathingPhaseExhale => 'زفير';

  @override
  String breathingCycleProgress(int current, int total) {
    return 'الدورة $current/$total';
  }

  @override
  String get breathingFinishAction => 'إنهاء';

  @override
  String breathingSecondsLabel(int seconds) {
    return '$seconds ث';
  }

  @override
  String get breathingIntroTitle => 'علاج التنفس 4-7-8';

  @override
  String get breathingIntroSubtitle =>
      'نمط تنفّس بطيء يساعد على تقليل التوتر والقلق.';

  @override
  String breathingIntroCycles(int cycles) {
    return '$cycles دورات';
  }

  @override
  String get breathingIntroApproxMinutes => '~2 د';

  @override
  String get breathingPhaseHintInhale => 'ثوانٍ شهيق';

  @override
  String get breathingPhaseHintHold => 'ثوانٍ حبس';

  @override
  String get breathingPhaseHintExhale => 'ثوانٍ زفير';

  @override
  String get breathingSessionCompleteTitle => 'اكتملت الجلسة';

  @override
  String breathingSessionCompleteSubtitle(int cycles) {
    return 'اكتملت $cycles دورات. يمكنك القيام بجولة أخرى أو الخروج.';
  }

  @override
  String get breathingBottomHint =>
      'أثناء الحبس يتباطأ نبض القلب؛ واصل بوتيرة مريحة. توقّف إذا شعرت بدوار.';

  @override
  String get quitProgramNotFound => 'لم يتم العثور على البرنامج';

  @override
  String get quitOnboardingCommitmentMinLengthError =>
      'يرجى كتابة عهد لنفسك (8 أحرف على الأقل).';

  @override
  String get quitOnboardingQuickStartTitle => 'ابدأ العداد الآن';

  @override
  String get quitOnboardingQuickStartBody =>
      'سيبدأ العداد من هذه اللحظة. يمكنك إكمال عهدك لاحقاً من البرنامج.';

  @override
  String get quitOnboardingAbortAction => 'تراجع';

  @override
  String get quitOnboardingExitDraftTitle => 'هل تريد الخروج من الإعداد؟';

  @override
  String get quitOnboardingExitDraftBody =>
      'لن يتم حفظ تقدمك في جولة الإعداد هذه. يمكنك البدء مجدداً لاحقاً.';

  @override
  String get quitOnboardingStayAction => 'ابقَ';

  @override
  String get quitOnboardingExitAction => 'خروج';

  @override
  String get quitOnboardingContentLoadFailed =>
      'تعذر تحميل محتوى الإعداد. يرجى المحاولة مرة أخرى.';

  @override
  String get quitOnboardingAppBarTitle => 'الإعداد';

  @override
  String get quitOnboardingSealTitlePrefix => 'اختم عهدك';

  @override
  String get quitOnboardingSealHoldHint => 'اضغط مطولاً';

  @override
  String get quitOnboardingContinueAction => 'متابعة';

  @override
  String get quitOnboardingQuickStartInlineAction =>
      'ابدأ العداد الآن، وأكمل البرنامج لاحقاً';

  @override
  String get quitOnboardingCommitmentTitle => 'عهدك لنفسك';

  @override
  String get quitOnboardingCommitmentSubtitle =>
      'اكتبها قصيرة وواضحة؛ يمكنك تعديلها قبل الختم.';

  @override
  String get quitOnboardingCommitmentHint => 'ابتداءً من اليوم…';

  @override
  String get quitOnboardingExamplesSectionTitle => 'جمل نموذجية';

  @override
  String get quitProgramRestartTitle => 'إعادة البدء';

  @override
  String get quitProgramRestartPrompt =>
      'سيتم تصفير العداد. ماذا تريد أن يحدث للسجل؟';

  @override
  String get quitProgramRestartKeepHistoryTitle => 'الاحتفاظ بالسجل';

  @override
  String get quitProgramRestartKeepHistorySubtitle =>
      'يبدأ العداد من الصفر، لكن تبقى محاولتك السابقة وعلاماتك اليومية وإحصاءاتك محفوظة.';

  @override
  String get quitProgramRestartWipeTitle => 'البدء من الصفر';

  @override
  String get quitProgramRestartWipeSubtitle =>
      'سيتم حذف جميع العلامات اليومية السابقة أيضاً. لا يمكن التراجع.';

  @override
  String quitProgramElapsedHms(int hours, int minutes, int seconds) {
    return '$hours س $minutes د $seconds ث';
  }

  @override
  String quitProgramElapsedMs(int minutes, int seconds) {
    return '$minutes د $seconds ث';
  }

  @override
  String quitProgramElapsedS(int seconds) {
    return '$seconds ث';
  }

  @override
  String get quitProgramTabProgress => 'التقدم';

  @override
  String get quitProgramTabTips => 'نصائح';

  @override
  String get quitProgramTipsLoadFailed => 'تعذر تحميل المحتوى';

  @override
  String get quitProgramTipsWatermark => 'هِدَايَة';

  @override
  String get quitProgramTipsHeroTitle => 'هداية';

  @override
  String get quitProgramTipsHeroSubtitle =>
      'وعي وصبر واقتراحات عملية لتخفيف الطريق عليك.';

  @override
  String get quitProgramDaysUpper => 'يوم';

  @override
  String get quitProgramStartNowAction => 'أقلعت من هذه اللحظة';

  @override
  String get quitProgramStatFullDays => 'أيام كاملة';

  @override
  String get quitProgramDash => '—';

  @override
  String get quitProgramStatTimer => 'العداد';

  @override
  String quitProgramElapsedSinceQuitDays(int days) {
    return 'المدة المنقضية: $days يوم (من لحظة الإقلاع)';
  }

  @override
  String get quitProgramTasksTitle => 'المهام';

  @override
  String get quitProgramTasksSubtitle => 'تتقدم كلما أكملت عتبات الأيام.';

  @override
  String get quitProgramUiCounterSubtitleGeneric => 'أيام نظيفة';

  @override
  String get quitProgramUiMetricsSectionTitleGeneric => 'مؤشرات التقدم';

  @override
  String get quitProgramUiDisclaimerGeneric =>
      'هذه المؤشرات لأغراض التحفيز فقط.';

  @override
  String get quitProgramUiEncouragementGeneric =>
      'كل يوم نظيف له قيمة؛ الخطوات الصغيرة الثابتة تصنع تحولاً كبيراً.';

  @override
  String get quitProgramUiClockHintGeneric =>
      'عند الضغط، يستمر العداد والمؤشرات من هذه اللحظة.';

  @override
  String get quitProgramMotivationStageStart =>
      'أهم خطوة في اليوم الأول هي أن تبدأ.';

  @override
  String get quitProgramMotivationStageWeek =>
      'في الأسبوع الأول، الصبر مهم؛ الخطوات الصغيرة تصنع فرقاً كبيراً.';

  @override
  String get quitProgramMotivationStageMonth =>
      'مع اقتراب الشهر الأول، استمر بثبات وصبر.';

  @override
  String get quitProgramMotivationStageQuarter =>
      'نحو ثلاثة أشهر، يظهر أثر الاستمرارية بشكل أوضح.';

  @override
  String get quitProgramMotivationStageLong =>
      'على المدى الطويل، كل يوم نظيف هو مكسب حقيقي.';

  @override
  String get quitMetricSmokingLung => 'الرئتان / التنفس';

  @override
  String get quitMetricSmokingHeart => 'القلب والأوعية';

  @override
  String get quitMetricSmokingTeethMouth => 'الأسنان والفم';

  @override
  String get quitMetricSmokingSmellTaste => 'الشم والتذوق';

  @override
  String get quitMetricScreenFocusDepth => 'التركيز والعمق';

  @override
  String get quitMetricScreenSleepRhythm => 'إيقاع النوم';

  @override
  String get quitMetricScreenAwareness => 'وعي الشاشة';

  @override
  String get quitMetricScreenInnerCalm => 'السكينة الداخلية';

  @override
  String get quitMetricAlcoholLiverRecovery => 'تعافي الكبد';

  @override
  String get quitMetricAlcoholSleepStability => 'استقرار النوم';

  @override
  String get quitMetricAlcoholMoodBalance => 'توازن المزاج';

  @override
  String get quitMetricAlcoholClarity => 'صفاء الذهن';

  @override
  String get quitMetricSubstanceBodyBalance => 'توازن الجسد';

  @override
  String get quitMetricSubstanceSleepRhythm => 'إيقاع النوم';

  @override
  String get quitMetricSubstanceUrgeControl => 'إدارة الرغبة';

  @override
  String get quitMetricSubstanceSupportTracking => 'الدعم والمتابعة';

  @override
  String get quitMetricZinaDiscipline => 'انضباط النفس';

  @override
  String get quitMetricZinaBoundaryStrength => 'قوة الحدود';

  @override
  String get quitMetricZinaHeartCalm => 'سكينة القلب';

  @override
  String get quitMetricZinaTawbaDirection => 'اتجاه التوبة';

  @override
  String get quitMilestone1Title => 'أول نفس';

  @override
  String get quitMilestone1Subtitle => 'يوم نظيف واحد';

  @override
  String get quitMilestone2Title => 'أول سلسلة';

  @override
  String get quitMilestone2Subtitle => '48 ساعة';

  @override
  String get quitMilestone3Title => 'ثلاثة أيام';

  @override
  String get quitMilestone3Subtitle => 'ذروة الرغبة تمر';

  @override
  String get quitMilestone5Title => 'خمسة أيام';

  @override
  String get quitMilestone5Subtitle => 'الروتين ينكسر';

  @override
  String get quitMilestone7Title => 'أسبوع واحد';

  @override
  String get quitMilestone7Subtitle => 'اكتمل الأسبوع الأول';

  @override
  String get quitMilestone10Title => 'عشرة أيام';

  @override
  String get quitMilestone10Subtitle => 'الإرادة تزداد قوة';

  @override
  String get quitMilestone14Title => 'أسبوعان';

  @override
  String get quitMilestone14Subtitle => 'الإدراك يتعافى';

  @override
  String get quitMilestone21Title => 'ثلاثة أسابيع';

  @override
  String get quitMilestone21Subtitle => 'حلقة العادة تتغير';

  @override
  String get quitMilestone30Title => 'شهر واحد';

  @override
  String get quitMilestone30Subtitle => 'عتبة مهمة';

  @override
  String get quitMilestone45Title => 'خمسة وأربعون يوماً';

  @override
  String get quitMilestone45Subtitle => 'النظام يستقر';

  @override
  String get quitMilestone60Title => 'شهران';

  @override
  String get quitMilestone60Subtitle => 'الجسم يتأقلم';

  @override
  String get quitMilestone66Title => 'سيد العادة';

  @override
  String get quitMilestone66Subtitle => 'خط 66 يوماً';

  @override
  String get quitMilestone90Title => 'ثلاثة أشهر';

  @override
  String get quitMilestone90Subtitle => 'مرحلة صحية واضحة';

  @override
  String get quitMilestone120Title => 'أربعة أشهر';

  @override
  String get quitMilestone120Subtitle => 'شارة العزم';

  @override
  String get quitMilestone180Title => 'ستة أشهر';

  @override
  String get quitMilestone180Subtitle => 'نصف عام';

  @override
  String get quitMilestone270Title => 'تسعة أشهر';

  @override
  String get quitMilestone270Subtitle => 'نَفَس طويل';

  @override
  String get quitMilestone365Title => 'سنة واحدة';

  @override
  String get quitMilestone365Subtitle => 'بشارة عظيمة';

  @override
  String get quitMilestone500Title => 'خمسمائة يوم';

  @override
  String get quitMilestone500Subtitle => 'تاج المثابرة';

  @override
  String get quitMilestone730Title => 'سنتان';

  @override
  String get quitMilestone730Subtitle => 'تحول جذري';

  @override
  String get quitMilestone1000Title => 'ألف يوم';

  @override
  String get quitMilestone1000Subtitle => 'مستوى استثنائي';

  @override
  String get quitMilestoneInspiration365 =>
      '\"إِنَّمَا يُوَفَّى الصَّابِرُونَ أَجْرَهُمْ بِغَيْرِ حِسَابٍ.\" (الزمر، 10)';

  @override
  String get quitMilestoneInspiration90 =>
      '\"من كان مع الله فلا يكون وحيداً.\"';

  @override
  String get quitMilestoneInspiration30 =>
      '\"فإذا عزمت فتوكل على الله.\" (آل عمران، 159)';

  @override
  String get quitMilestoneInspiration7 =>
      '\"فَإِنَّ مَعَ الْعُسْرِ يُسْرًا.\" (الشرح، 6)';

  @override
  String get quitMilestoneInspiration1 =>
      '\"إِنَّ مَعَ الْعُسْرِ يُسْرًا.\" (الشرح، 5)';

  @override
  String quitMilestoneElapsedSummary(int days, Object subtitle) {
    return '$days يوماً من النظافة — $subtitle';
  }

  @override
  String get quitMilestoneContinueAction => 'متابعة';

  @override
  String get quitProgramCompleteCommitmentTitle => 'أكمل عهدك';

  @override
  String get quitProgramCompleteCommitmentSubtitle =>
      'العداد يعمل — اختم برنامجك بالعهد الذي كتبته لنفسك.';

  @override
  String get willpowerHubBreathingExerciseTitle => 'تمرين التنفس';

  @override
  String get willpowerHubBreathingExerciseSubtitle =>
      'التنفس البطيء يهدّئ جسدك في لحظات التوتر.';

  @override
  String get willpowerHubArchiveHabitDialogTitle => 'أرشفة العادة';

  @override
  String get willpowerHubArchiveHabitDialogBody =>
      'سيتم إزالة هذا السجل من القائمة دون حذفه نهائياً. يمكنك إعادته لاحقاً.';

  @override
  String get willpowerHubArchiveAction => 'أرشفة';

  @override
  String get willpowerHubHeaderTitle => 'التطور والتزكية';

  @override
  String get willpowerHubNoActiveHabits => 'لا توجد عادات نشطة بعد';

  @override
  String willpowerHubActiveHabits(int count) {
    return '$count عادات نشطة';
  }

  @override
  String get willpowerHubHabitCalendarTooltip => 'تقويم العادات';

  @override
  String get willpowerHubTabBuild => 'التطور';

  @override
  String get willpowerHubTabQuit => 'التزكية';

  @override
  String get willpowerHubQuitCtaEarly =>
      'كل دقيقة نظيفة تعود أكسجيناً لقلبك ورئتيك.';

  @override
  String get willpowerHubQuitCtaOngoing =>
      'الأيام الأولى صعبة، لكن جسدك بدأ يتعافى بالفعل.';

  @override
  String get willpowerHubBuildCtaEarly => 'البداية بخطوات صغيرة تكفي.';

  @override
  String get willpowerHubBuildCtaOngoing => 'روتينك يسير جيداً؛ واصل.';

  @override
  String get willpowerHubSummaryQuitLabel => 'التزكية';

  @override
  String get willpowerHubSummaryTodayLabel => 'اليوم';

  @override
  String get willpowerHubSummaryCounterProgress => 'تقدم العداد';

  @override
  String get willpowerHubSummaryCompleted => 'اكتمل';

  @override
  String get willpowerHubInsightTagSpiritual => 'روحي';

  @override
  String get willpowerHubInsightTagHealth => 'صحي';

  @override
  String get willpowerHubAddFirstBuild => 'أضف أول عادة تطوير';

  @override
  String get willpowerHubAddFirstQuit => 'أضف أول عادة تزكية';

  @override
  String get willpowerHubBuildEmptyTitle => 'مساحة التطور ما زالت فارغة';

  @override
  String get willpowerHubBuildEmptySubtitle =>
      'المواظبة على عادة نافعة هي من أبسط طرق النمو الروحي.';

  @override
  String get willpowerHubKazaLabelSabah => 'فجر';

  @override
  String get willpowerHubKazaLabelOgle => 'ظهر';

  @override
  String get willpowerHubKazaLabelIkindi => 'عصر';

  @override
  String get willpowerHubKazaLabelAksam => 'مغرب';

  @override
  String get willpowerHubKazaLabelYatsi => 'عشاء';

  @override
  String get willpowerHubKazaLabelVitir => 'وتر';

  @override
  String get willpowerHubKazaTrackingTitle => 'متابعة القضاء';

  @override
  String get willpowerHubKazaRemainingLabel => 'المتبقي';

  @override
  String get willpowerHubRemoveCardTooltip => 'إزالة البطاقة';

  @override
  String get willpowerHubHideKazaDialogTitle => 'إزالة بطاقة القضاء؟';

  @override
  String get willpowerHubHideKazaDialogBody =>
      'سيتم إخفاء هذه البطاقة من شاشة التطور. تبقى بيانات الحساب والعداد على الجهاز، ويمكنك إضافتها مجدداً من ورشة الروتين.';

  @override
  String get willpowerHubRemoveAction => 'إزالة';

  @override
  String get willpowerHubQuitEmptyTitle => 'مساحة التزكية ما زالت فارغة';

  @override
  String get willpowerHubQuitEmptySubtitle =>
      'ترك عادة ضارة طريق قوي لتأديب النفس.';

  @override
  String get willpowerHubPeriodPrefixWeek => 'هذا الأسبوع ';

  @override
  String get willpowerHubPeriodPrefixMonth => 'هذا الشهر ';

  @override
  String willpowerHubPercentTargetReached(Object prefix) {
    return '$prefixوصلت إلى النسبة المستهدفة.';
  }

  @override
  String willpowerHubPercentProgressStatus(
    Object prefix,
    int progress,
    int left,
  ) {
    return '$prefixاكتمل %$progress، والمتبقي %$left.';
  }

  @override
  String willpowerHubTargetPending(Object prefix) {
    return '$prefixالهدف بانتظار التحديد.';
  }

  @override
  String willpowerHubUnitTargetAddPrompt(
    Object prefix,
    int target,
    Object unit,
  ) {
    return '$prefixالهدف $target $unit — اضغط البطاقة للإضافة.';
  }

  @override
  String willpowerHubUnitProgressTargetFilled(
    Object prefix,
    int progress,
    Object unit,
  ) {
    return '$prefixأنجزت $progress $unit؛ اكتمل الهدف.';
  }

  @override
  String willpowerHubUnitProgressRemaining(
    Object prefix,
    int progress,
    Object unit,
    int left,
  ) {
    return '$prefixأنجزت $progress $unit، والمتبقي $left $unit.';
  }

  @override
  String willpowerHubUnitTargetDoneSuper(
    Object prefix,
    int target,
    Object unit,
  ) {
    return '$prefixاكتمل $target $unit — رائع.';
  }

  @override
  String willpowerHubUnitProgressDidRemaining(
    Object prefix,
    int progress,
    Object unit,
    int left,
  ) {
    return '$prefixقمت بـ $progress $unit، والمتبقي $left $unit.';
  }

  @override
  String get willpowerHubAddEditHint => 'اضغط البطاقة للإضافة أو التعديل';

  @override
  String get willpowerHubQuitStatusSetupMissing => 'الإعداد غير مكتمل';

  @override
  String get willpowerHubQuitStatusClockRunning => 'العداد يعمل';

  @override
  String get willpowerHubQuitStatusProgramReady => 'البرنامج جاهز';

  @override
  String get willpowerHubTapCardForDetails => 'اضغط البطاقة للتفاصيل';

  @override
  String get willpowerHubCompleteSetup => 'أكمل الإعداد';

  @override
  String get willpowerHubStartClockHint =>
      'ابدأ العداد من خيار «أقلعت من هذه اللحظة» داخل البرنامج';

  @override
  String get willpowerHubStreakSeriesLabel => 'سلسلة';

  @override
  String get willpowerHubStreakDaySeriesLabel => 'سلسلة الأيام';

  @override
  String get qiblaHubCompassTitle => 'اعثر على اتجاه القبلة';

  @override
  String get qiblaHubCompassSubtitle =>
      'اعرض اتجاه الكعبة باستخدام البوصلة والموقع';

  @override
  String get qiblaHubOpenAction => 'فتح';

  @override
  String get qiblaHubZikirTitle => 'عداد الذكر';

  @override
  String get qiblaHubZikirFeatureSubtitle =>
      'عداد رقمي مع تفاصيل الذكر، سجل الجولات، والهدف (33/99)';

  @override
  String get qiblaHubBreathingTitle => 'تمرين التنفس';

  @override
  String get qiblaHubBreathingSubtitle =>
      'اهدأ واستعد تركيزك عبر دورة التنفس 4-7-8';

  @override
  String get qiblaHubHealingTitle => 'ترددات الشفاء';

  @override
  String get qiblaHubHealingSubtitle =>
      'جلسة هادئة مع نغمات علاجية، أجواء صوتية، ومؤقت نوم';

  @override
  String get generalLoading => 'جارٍ التحميل...';

  @override
  String get settingsPrivacyPageTitle => 'سياسة الخصوصية';

  @override
  String get settingsPrivacyLastUpdated => 'آخر تحديث: 26.04.2026';

  @override
  String get settingsPrivacyIntro =>
      'تحترم Arin خصوصيتك. يوضح هذا النص ما البيانات التي تتم معالجتها، ولماذا تتم معالجتها، وكيف يمكنك إدارة هذه العمليات.';

  @override
  String get settingsPrivacyDataCollectedTitle => 'البيانات المُعالجة';

  @override
  String get settingsPrivacyDataCollectedBody =>
      'اعتمادًا على استخدامك والأذونات التي تمنحها، قد تعالج Arin بيانات الموقع لميزات مواقيت الصلاة والقبلة، وتفضيلات الإشعارات، وبيانات الحساب عند تسجيل الدخول، وبيانات تشخيص التطبيق.';

  @override
  String get settingsPrivacyUsageTitle => 'لماذا نعالج البيانات';

  @override
  String get settingsPrivacyUsageBody =>
      'تُعالج البيانات لحساب مواقيت الصلاة، وعرض اتجاه القبلة، وجدولة التذكيرات، والحفاظ على إعداداتك، وتحسين استقرار التطبيق.';

  @override
  String get settingsPrivacyStorageTitle => 'التخزين والاحتفاظ';

  @override
  String get settingsPrivacyStorageBody =>
      'يتم حفظ معظم بيانات العادات والذكر والتفضيلات على جهازك. إذا سجّلت الدخول، قد تتم مزامنة بيانات محددة مع خدمات Firebase. يتم الاحتفاظ بالبيانات حتى تحذفها من التطبيق أو تزيل حسابك.';

  @override
  String get settingsPrivacyThirdPartyTitle => 'خدمات الطرف الثالث';

  @override
  String get settingsPrivacyThirdPartyBody =>
      'تستخدم Arin خدمات Firebase Authentication وCloud Firestore وFirebase Analytics وFirebase Crashlytics لتسجيل الدخول ومزامنة البيانات وتحليل الاستخدام وتشخيص الأعطال.';

  @override
  String get settingsPrivacyControlsTitle => 'تحكم المستخدم';

  @override
  String get settingsPrivacyControlsBody =>
      'يمكنك إيقاف أذونات الموقع والإشعارات من إعدادات الجهاز، أو تسجيل الخروج من صفحة الإعدادات، أو حذف حسابك وبياناتك المحلية.';

  @override
  String get settingsPrivacyChildrenTitle => 'خصوصية الأطفال';

  @override
  String get settingsPrivacyChildrenBody =>
      'تطبيق Arin غير مصمم للأطفال دون 13 عامًا.';

  @override
  String get settingsPrivacyContactTitle => 'التواصل';

  @override
  String get settingsPrivacyContactBody =>
      'للاستفسارات المتعلقة بالخصوصية: arinapphelp@gmail.com';

  @override
  String get notificationsHubTitle => 'الإشعارات';

  @override
  String get notificationsHubHeadline => 'مركز التذكيرات';

  @override
  String get notificationsHubSubhead =>
      'الصلاة والتزكية والذكر — كلها في مكان واحد.';

  @override
  String get notificationsPermissionGranted => 'مسموح';

  @override
  String get notificationsPermissionDenied => 'موقوف';

  @override
  String get notificationsPermissionLimited => 'محدود';

  @override
  String get notificationsOpenOsSettings => 'إعدادات إشعارات النظام';

  @override
  String get notificationsGateNotification => 'الإشعارات';

  @override
  String get notificationsGateExactAlarm => 'منبّه دقيق';

  @override
  String get notificationsGateBattery => 'استثناء البطارية';

  @override
  String get notificationsGateAllGood => 'تعمل التذكيرات في الوقت المحدد.';

  @override
  String get notificationsGateMissing =>
      'هناك إذن واحد أو أكثر مفقود — قد تتأخر الإشعارات المجدولة أو لا تصل.';

  @override
  String get notificationsGateRequestExact => 'تفعيل إذن المنبّه الدقيق';

  @override
  String get notificationsGateRequestBattery => 'تجاهل تحسين البطارية';

  @override
  String get notificationsDiagnosticsQueuedLabel =>
      'التذكيرات المجدولة في الطابور';

  @override
  String get notificationsSectionGeneral => 'عام';

  @override
  String get notificationsSectionPrayer => 'مواقيت الصلاة';

  @override
  String get notificationsSectionArinma => 'التزكية والعادات';

  @override
  String get notificationsPrayerRowTitle => 'الوقت والصوت';

  @override
  String get notificationsPrayerOnSubtitle =>
      'إشعارات الصلاة مفعلة — اضغط للتعديل';

  @override
  String get notificationsPrayerOffSubtitle =>
      'إشعارات الصلاة متوقفة — اضغط للتفعيل';

  @override
  String get notificationsPrayerDetailTitle => 'إشعارات الصلاة';

  @override
  String get notificationsPrayerDetailSubtitle =>
      'لكل وقت إعداد صوت ومدة مستقلان؛ المفتاح الرئيسي بالأسفل.';

  @override
  String get notificationsArinmaDailyTitle => 'تذكير يومي';

  @override
  String get notificationsArinmaDailySubtitle =>
      'مرتان يوميًا، مقولة عشوائية أو تحفيز قصير.';

  @override
  String get notificationsMilestoneTitle => 'إشعارات الإنجاز';

  @override
  String get notificationsMilestoneSubtitle =>
      'مثل رسائل متباعدة عند 24 ساعة أو أسبوع في رحلة الإقلاع.';

  @override
  String get notificationsTaskTitle => 'تذكير المهام';

  @override
  String get notificationsTaskSubtitle =>
      'بحد أقصى تنبيه واحد يوميًا للمهام غير المكتملة.';

  @override
  String get notificationsZikirTitle => 'تذكير الذكر';

  @override
  String get notificationsZikirSubtitle =>
      'في الوقت الذي اخترته، تذكير قصير بآخر نص ذكر لديك.';

  @override
  String get notificationsZikirTimeLabel => 'وقت الذكر';

  @override
  String get notificationsZikirTimePickerTitle => 'وقت الذكر';

  @override
  String get notificationsZikirTimePickerSubtitle =>
      'تذكير يومي في هذا الوقت بآخر نص ذكر لديك.';

  @override
  String get notificationsHealthDisclaimer =>
      'النصوص المتعلقة بالصحة والتزكية هي للتوعية العامة ولا تغني عن العلاج. إذا كان لديك حالة صحية فاستشر طبيبك.';

  @override
  String get notificationsNextReminderToday => 'اليوم';

  @override
  String get notificationsNextReminderTomorrow => 'غدًا';

  @override
  String get notificationsNextReminderUnderMinute => '< دقيقة';

  @override
  String notificationsNextReminderMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String notificationsNextReminderHoursOnly(int hours) {
    return '$hours س';
  }

  @override
  String notificationsNextReminderHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String notificationsNextReminderLine(
    Object dayLabel,
    Object clock,
    Object gap,
  ) {
    return 'التذكير التالي: $dayLabel $clock · بعد $gap';
  }

  @override
  String get aboutArinHeadline => 'إلى جانب طريقك';

  @override
  String get aboutArinSubhead =>
      'رفيق صغير يقدم لك تذكيرات لطيفة لصلاتك وتنظيمك ويومك';

  @override
  String get aboutArinParagraph1 =>
      'وُجد ARIN ليساعدك على الحفاظ على صلاتك في وقتها، والاستمرار في العادات النافعة، والتخفف تدريجيًا من الأنماط المتعبة. هدفنا ليس الضغط عليك، بل البقاء بجانبك بتذكيرات هادئة في الأيام المزدحمة.';

  @override
  String get aboutArinParagraph2 =>
      'أحيانًا يكون الطريق طويلًا، وأحيانًا يكون اليوم ممتلئًا. لذلك نقدم تدفقًا بسيطًا وتذكيرات واضحة. نرغب في سماع أي نقطة تبدو ناقصة أو غير مناسبة؛ ونحن منفتحون على تحسينها معًا.';

  @override
  String get aboutArinParagraph3 =>
      'الخطوات الصغيرة هي الأكثر فاعلية على المدى الطويل. نأمل أن ترى ARIN رفيقًا هادئًا لا يستعجلك ولا يترك طريقك؛ نتمنى لك يومًا ساكنًا وخفيفًا.';

  @override
  String get aboutArinClosingWish => 'نتمنى لك استخدامًا مباركًا';

  @override
  String languageChangedMessage(Object languageName) {
    return 'تم تغيير اللغة إلى: $languageName';
  }

  @override
  String get adminIdentityBadge => 'المشرف';

  @override
  String get adminPoolsHint =>
      'اختر مخزنًا، عدّل ثم احفظ. العمليات المتقدمة بالأسفل.';

  @override
  String adminPoolsDropdownLabel(int count) {
    return 'المخزن ($count عنصر)';
  }

  @override
  String get adminAdvancedActionsTitle => 'عمليات متقدمة';

  @override
  String get adminBackupCurrentPoolJson => 'نسخ احتياطي لهذا المخزن (JSON)';

  @override
  String get adminRestoreFromBackup => 'استعادة من النسخة الاحتياطية';

  @override
  String get adminWritingInProgress => 'جارٍ الكتابة…';

  @override
  String get adminResetCompletely => 'إعادة تعيين كاملة';

  @override
  String adminVersionLabel(Object version) {
    return 'الإصدار: v$version';
  }

  @override
  String adminSearchInPoolHint(int count) {
    return 'ابحث داخل المخزن ($count سجل)';
  }

  @override
  String get adminAddAction => 'إضافة';

  @override
  String get adminAddMissingRecords => 'إضافة السجلات الناقصة';

  @override
  String get adminPoolLabelHomeNamazWisdom => 'بطاقة الصلاة في الصفحة الرئيسية';

  @override
  String get adminPoolLabelPersonalizedQuotes => 'اقتباسات مخصصة';

  @override
  String get adminPoolLabelWidgetQuote => 'اقتباس الودجت / الشاشة الرئيسية';

  @override
  String get adminPoolLabelZikirDailyReflections =>
      'بطاقة وقت الصلاة (تأمل الذكر)';

  @override
  String get adminPoolLabelHealingComfort => 'اقتباسات الشفاء / المواساة';

  @override
  String get adminPoolLabelHubGelisimIslamic => 'التطور — بطاقة إسلامية';

  @override
  String get adminPoolLabelHubGelisimMedical => 'التطور — بطاقة صحية';

  @override
  String get adminPoolLabelHubArinmaIslamic => 'التزكية — بطاقة إسلامية';

  @override
  String get adminPoolLabelHubArinmaMedical => 'التزكية — بطاقة صحية';

  @override
  String get adminPoolLabelNotificationArinmaBodies => 'نصوص إشعار التزكية';

  @override
  String adminSearchResultsCount(int count) {
    return '$count نتيجة';
  }

  @override
  String get adminPoolEmptyHint => 'هذا المخزن فارغ — يمكنك إضافة عنصر.';

  @override
  String get adminSearchNoResults => 'لا توجد نتائج مطابقة.';

  @override
  String get adminTapToEdit => 'اضغط للتعديل';

  @override
  String get adminEditTooltip => 'تعديل';

  @override
  String adminInspireHint(int count) {
    return 'أضف بطاقة ثم املأ النص واحفظ. صور الخلفية: $count.';
  }

  @override
  String get adminInspireAddNewCard => 'إضافة بطاقة جديدة';

  @override
  String get adminRefreshFromFirestore => 'تحديث من Firestore';

  @override
  String adminInspireVersionCards(Object version, int count) {
    return 'الإصدار: v$version · $count بطاقة';
  }

  @override
  String get adminInspireNoCardsYet => 'لا توجد بطاقات استكشاف بعد';

  @override
  String get adminInspireAddFirstCard => 'أضف أول بطاقة';

  @override
  String adminInspireCardLabel(int index) {
    return 'البطاقة $index';
  }

  @override
  String get adminInspireEmptyTextBadge => 'نص فارغ';

  @override
  String get adminInspireDuplicateTooltip => 'نسخ';

  @override
  String get adminInspireShuffleDesignTooltip => 'خلط التصميم';

  @override
  String adminInspireEmptyTextPreview(int index) {
    return '(نص فارغ — #$index)';
  }

  @override
  String adminInspireImageNumberLabel(Object index) {
    return 'الصورة #$index';
  }

  @override
  String get adminInspireContentKindLabel => 'نوع المحتوى';

  @override
  String get adminInspireContentKindQuote => 'مقولة';

  @override
  String get adminInspireContentKindVerse => 'آية';

  @override
  String get adminInspireContentKindHadith => 'حديث';

  @override
  String get adminInspireShowInMainFeedTitle => 'إظهار في الخلاصة الرئيسية';

  @override
  String get adminInspireShowInMainFeedSubtitle =>
      'عند الإلغاء سيظهر فقط ضمن فلاتر الآية أو الحديث.';

  @override
  String get adminInspireTurkishTextLabel => 'النص التركي *';

  @override
  String get adminOptionalArabicLabel => 'العربية (اختياري)';

  @override
  String get adminOptionalSourceLabel => 'المصدر (اختياري)';

  @override
  String get adminOptionalVerseRefLabel => 'الآية / السورة (اختياري)';

  @override
  String get adminInspireSaveAllChanges => 'حفظ كل تغييرات البطاقات';

  @override
  String get adminDiagnosticsHint =>
      'تشخيص الإشعارات التلقائي. يتم حفظ محاولات الجدولة هنا.';

  @override
  String get adminDiagnosticsStatusSummaryTitle => 'ملخص الحالة';

  @override
  String get adminDiagnosticsEnabled => 'مفعّل';

  @override
  String get adminDiagnosticsDisabled => 'معطّل';

  @override
  String adminDiagnosticsPrayerStatus(Object status) {
    return 'الصلاة: $status';
  }

  @override
  String adminDiagnosticsDailyStatus(Object status) {
    return 'اليومي: $status';
  }

  @override
  String adminDiagnosticsMilestoneStatus(Object status) {
    return 'الإنجاز: $status';
  }

  @override
  String adminDiagnosticsTaskStatus(Object status) {
    return 'المهمة: $status';
  }

  @override
  String adminDiagnosticsZikirStatus(Object status) {
    return 'الذكر: $status';
  }

  @override
  String adminDiagnosticsPendingQueue(int count) {
    return 'الطابور المعلّق: $count';
  }

  @override
  String get adminRefreshAction => 'تحديث';

  @override
  String get adminDiagnosticsExportLog => 'تصدير السجل';

  @override
  String get adminDiagnosticsClearLog => 'مسح السجل';

  @override
  String adminDiagnosticsRecentEvents(int count) {
    return 'آخر الأحداث ($count)';
  }

  @override
  String get adminDiagnosticsNoLogsHint =>
      'لا يوجد سجل بعد. أعد فتح التطبيق واستخدمه قليلًا ثم حدّث.';

  @override
  String get adminDiagnosticsOutcomeOk => 'نجاح';

  @override
  String get adminDiagnosticsOutcomeError => 'خطأ';

  @override
  String get adminDiagnosticsOutcomeCooldownSkip => 'تم التخطي (فترة التهدئة)';

  @override
  String get adminDiagnosticsOutcomePendingGuardSkip =>
      'تم التخطي (حماية المعلّق)';

  @override
  String get adminDiagnosticsOutcomeDisabled => 'معطّل';

  @override
  String get adminDiagnosticsOutcomeInvalidPayloadSkip =>
      'تم التخطي (بيانات غير صالحة)';

  @override
  String adminDiagnosticsOutcomeUnknown(Object outcome) {
    return 'غير معروف ($outcome)';
  }

  @override
  String get adminDevOffsetSavedAndRescheduled =>
      'تم حفظ الإزاحة وإعادة جدولة الإشعارات.';

  @override
  String get adminDevOffsetReset => 'تمت إعادة تعيين الإزاحة.';

  @override
  String get adminDevOffsetDisabled => 'معطّل (أوقات API)';

  @override
  String adminDevOffsetForwardMinutes(int minutes) {
    return 'أبكر: $minutes د';
  }

  @override
  String adminDevOffsetBackwardMinutes(int minutes) {
    return 'أبعد: $minutes د';
  }

  @override
  String get adminDevPrayerOffsetTitle => 'إزاحة أوقات الصلاة (هذا الجهاز فقط)';

  @override
  String get adminDevPrayerOffsetSubtitle =>
      'القيم السالبة تقدّم كل الأوقات (والإشعارات كذلك). لا يتغير API/الخادم.';

  @override
  String get adminDevResetAction => 'إعادة تعيين';

  @override
  String get adminDevSaveAndRescheduleAction => 'حفظ وإعادة جدولة';

  @override
  String get adminDevNotificationTestsTitle => 'اختبارات الإشعارات';

  @override
  String get adminDevNotificationTestsSubtitle =>
      'لتجربة القناة والصوت الحاليين فورًا.';

  @override
  String get adminDevPrayerNotificationSent => 'تم إرسال إشعار الصلاة.';

  @override
  String get adminDevPrayerNotificationNowAction => 'إشعار الصلاة (الآن)';

  @override
  String get adminDevAppNotificationSent => 'تم إرسال إشعار التطبيق.';

  @override
  String get adminDevAppNotificationNowAction => 'إشعار التطبيق (الآن)';

  @override
  String get adminDevCrashlyticsTestTitle =>
      'اختبار تقارير الأعطال (Crashlytics)';

  @override
  String get adminDevCrashlyticsDebugHint =>
      'إصدار Debug: الجمع متوقف. ثبّت APK بنمط release للاختبار.';

  @override
  String get adminDevCrashlyticsReleaseHint =>
      'الأزرار أدناه ترسل خطأ حقيقيًا إلى Firebase Console → Crashlytics.';

  @override
  String get adminFirebaseNotReady => 'Firebase غير جاهز.';

  @override
  String get adminDevCrashlyticsNonFatalSent =>
      'تم إرسال سجل non-fatal. سيظهر خلال دقائق.';

  @override
  String adminErrorWithReason(Object reason) {
    return 'خطأ: $reason';
  }

  @override
  String get adminDevSendNonFatalTestAction => 'اختبار: إرسال خطأ non-fatal';

  @override
  String get adminDevCrashNowFatalAction =>
      'اختبار: تعطيل التطبيق الآن (fatal)';

  @override
  String get adminDevCrashDialogTitle => 'تعطيل التطبيق؟';

  @override
  String get adminDevCrashDialogBody =>
      'سيغلق التطبيق خلال ثوانٍ. بعد فتحه مجددًا يُرفع التقرير إلى Firebase.\n\nاستخدمه فقط للتحقق من Crashlytics.';

  @override
  String get adminDevCrashAction => 'تعطيل';

  @override
  String get adminDiagnosticsTitle => 'التشخيص';

  @override
  String get adminDevPlatformLabel => 'المنصة';

  @override
  String get adminDevBuildLabel => 'البنية';

  @override
  String get adminDevBuildModeRelease => 'إصدار';

  @override
  String get adminDevBuildModeProfile => 'بروفايل';

  @override
  String get adminDevBuildModeDebug => 'تصحيح';

  @override
  String get adminDevPlatformWeb => 'ويب';

  @override
  String get adminDevPlatformUnknown => 'غير معروف';

  @override
  String get adminDevUidLabel => 'UID';

  @override
  String get adminDevPendingNotificationLabel => 'الإشعارات المعلّقة';

  @override
  String get adminDevTapToRefresh => 'اضغط للتحديث';

  @override
  String get adminDiagnosticsError => 'خطأ';

  @override
  String get adminPoolDataUnavailable => 'بيانات المخزن غير متاحة حاليًا.';

  @override
  String get adminPoolChangeAction => 'تعديل المخزن';

  @override
  String get adminReviewBeforeSaveTitle => 'مراجعة قبل الحفظ';

  @override
  String get adminPoolSaved => 'تم حفظ المخزن.';

  @override
  String get adminPoolSaveFailed => 'تعذر حفظ المخزن.';

  @override
  String get adminUseSeedAllForPool => 'استخدم \"زرع كل المخازن\" لهذا المخزن.';

  @override
  String get adminNoBuiltInSeedForPool =>
      'لا توجد بيانات افتراضية مدمجة لهذا المخزن.';

  @override
  String get adminSeedSelectedPoolDefaults =>
      'إعادة المخزن المحدد إلى الافتراضي';

  @override
  String get adminPoolNotLoadedYet => 'لم يتم تحميل المخزن بعد.';

  @override
  String adminPoolBackupShareText(Object poolId, Object timestamp) {
    return 'نسخة احتياطية لمخزن Arin — $poolId ($timestamp)';
  }

  @override
  String get adminPoolBackupShareSubject => 'نسخة احتياطية لمخزن Arin';

  @override
  String adminBackupCreationFailed(Object error) {
    return 'تعذر إنشاء النسخة الاحتياطية: $error';
  }

  @override
  String get adminBackupInvalidJsonObject =>
      'تعذر قراءة الملف الاحتياطي: مطلوب كائن JSON.';

  @override
  String get adminBackupPoolDocumentMissing =>
      'مستند المخزن غير موجود في ملف النسخ الاحتياطي.';

  @override
  String get adminBackupItemsListMissing =>
      'قائمة \"items\" غير موجودة في ملف النسخ الاحتياطي.';

  @override
  String get adminBackupContainsUnreadableRecords =>
      'توجد سجلات غير قابلة للقراءة؛ ربما تم تعديل الملف.';

  @override
  String get adminUnknownPool => 'مخزن غير معروف';

  @override
  String get adminRestoreBackupTitle => 'استعادة النسخة الاحتياطية';

  @override
  String adminRestoreBackupDialogBody(
    Object fileName,
    Object sourcePool,
    Object selectedPool,
    int itemCount,
    Object warningText,
  ) {
    return 'الملف: $fileName\nالمخزن في النسخة: $sourcePool\nالمخزن المحدد: $selectedPool\nعدد السجلات: $itemCount\n\n$warningTextسيتم كتابة هذه السجلات إلى المخزن المحدد. متابعة؟';
  }

  @override
  String get adminRestoreBackupDifferentPoolWarning =>
      'تحذير: النسخة من مخزن مختلف.';

  @override
  String adminRestoreFromBackupAction(Object fileName) {
    return 'استعادة من النسخة ($fileName)';
  }

  @override
  String get adminRestoreBackupFailed => 'تعذر استعادة ملف النسخة الاحتياطية.';

  @override
  String get adminRequiresManagerOrFullAccessForMissingSeed =>
      'يلزم صلاحية مدير أو كاملة لإضافة السجلات الناقصة.';

  @override
  String get adminRequiresFullAccessForReset =>
      'يلزم صلاحية كاملة لإعادة التعيين الكامل.';

  @override
  String get adminBulkPreviewFailed => 'تعذر جلب معاينة العملية الجماعية.';

  @override
  String get adminSeedAllPoolsTitle => 'زرع كل المخازن';

  @override
  String adminMergeSeedPreview(
    int poolCount,
    int changedPoolCount,
    int addedItemCount,
    int targetItemCount,
  ) {
    return 'معاينة:\n• المخازن المفحوصة: $poolCount\n• المخازن المتغيرة: $changedPoolCount\n• العناصر التي ستُضاف: $addedItemCount\n• إجمالي العناصر بعد العملية: $targetItemCount\n\nسيتم الحفاظ على التعديلات اليدوية. متابعة؟';
  }

  @override
  String adminResetSeedPreview(
    int poolCount,
    int changedPoolCount,
    int currentItemCount,
    int targetItemCount,
  ) {
    return 'معاينة:\n• المخازن المفحوصة: $poolCount\n• المخازن التي ستُستبدل: $changedPoolCount\n• العناصر الحالية: $currentItemCount\n• العناصر الجديدة: $targetItemCount\n\nسيتم حذف المحتوى الحالي. تأكد من النسخ الاحتياطي أولًا. متابعة؟';
  }

  @override
  String get adminOverwriteAction => 'استبدال';

  @override
  String get adminMissingItemsAddedToPools =>
      'تمت إضافة العناصر الناقصة إلى المخازن.';

  @override
  String get adminAllPoolsOverwritten => 'تمت إعادة كتابة كل المخازن.';

  @override
  String get adminAuditAddMissingToAllPools =>
      'إضافة العناصر الناقصة إلى جميع المخازن';

  @override
  String get adminAuditResetAllPools => 'إعادة تعيين جميع المخازن';

  @override
  String get adminInspireCardsUnavailable =>
      'بطاقات الاستكشاف غير متاحة حاليًا.';

  @override
  String get adminRequiresManagerOrFullAccessForDiagnostics =>
      'يلزم صلاحية مدير أو كاملة لإجراءات التشخيص.';

  @override
  String get adminNotificationLogsCleared => 'تم مسح سجلات الإشعارات.';

  @override
  String adminNotificationLogsShareText(Object timestamp) {
    return 'سجلات إشعارات Arin ($timestamp)';
  }

  @override
  String get adminNotificationLogsShareSubject => 'تشخيص إشعارات Arin';

  @override
  String adminLogExportFailed(Object error) {
    return 'فشل تصدير السجل: $error';
  }

  @override
  String get adminInspireCardHasEmptyTurkishText =>
      'هناك بطاقة بنص تركي فارغ؛ املأها أو احذفها.';

  @override
  String get adminReviewCardsBeforeSaveTitle => 'مراجعة قبل حفظ البطاقات';

  @override
  String get adminInspireCardsWillBeUpdated => 'سيتم تحديث بطاقات الاستكشاف';

  @override
  String get adminInspireCardsSaved => 'تم حفظ بطاقات الاستكشاف.';

  @override
  String get adminInspireCardsSaveFailed => 'تعذر حفظ بطاقات الاستكشاف.';

  @override
  String get adminAuditInspireCardsUpdated => 'تم تحديث بطاقات الاستكشاف';

  @override
  String adminCurrentRecordCount(int count) {
    return 'السجلات الحالية: $count';
  }

  @override
  String adminRecordCountToSave(int count) {
    return 'السجلات للحفظ: $count';
  }

  @override
  String adminChangedRowCount(int count) {
    return 'الأسطر المتغيرة: $count';
  }

  @override
  String get adminConcurrentEditWarning =>
      'إذا حفظ مشرف آخر أثناء ذلك فسيظهر تحذير.';

  @override
  String get adminSaveAction => 'حفظ';

  @override
  String get adminGrantsListFetchFailed => 'تعذر جلب قائمة الصلاحيات.';

  @override
  String get adminGrantAccessAction => 'منح صلاحية';

  @override
  String get adminEditGrantAction => 'تعديل الصلاحية';

  @override
  String get adminEmailOrUidLabel => 'البريد أو UID';

  @override
  String get adminLevelLabel => 'المستوى';

  @override
  String get adminRoleContentLabel => 'content - محتوى';

  @override
  String get adminRoleManagerLabel => 'manager - عمليات';

  @override
  String get adminRoleDeveloperLabel => 'developer - صلاحية كاملة';

  @override
  String get adminFullAccessRequiredForGrantManagement =>
      'يلزم صلاحية كاملة لإدارة الصلاحيات.';

  @override
  String get adminEmailOrUidCannotBeEmpty =>
      'لا يمكن أن يكون البريد أو UID فارغًا.';

  @override
  String get adminAccountAlreadyFullAccess =>
      'هذا الحساب لديه صلاحية كاملة بالفعل داخل التطبيق.';

  @override
  String get adminGrantSaved => 'تم حفظ الصلاحية.';

  @override
  String get adminGrantSaveFailed => 'تعذر حفظ الصلاحية.';

  @override
  String get adminAuditGrantSaved => 'تمت إضافة/تحديث صلاحية المشرف';

  @override
  String get adminFullAccessAccountCannotBeRemoved =>
      'هذا الحساب بصلاحية كاملة داخل التطبيق ولا يمكن إزالته من اللوحة.';

  @override
  String get adminRemoveGrantTitle => 'إزالة الصلاحية';

  @override
  String adminRemoveGrantMessage(Object label) {
    return 'ستتم إزالة صلاحية الإدارة لـ $label.';
  }

  @override
  String get adminGrantRemoved => 'تمت إزالة الصلاحية.';

  @override
  String get adminGrantRemoveFailed => 'تعذر إزالة الصلاحية.';

  @override
  String get adminAuditGrantRemoved => 'تمت إزالة صلاحية المشرف';

  @override
  String get adminEditItemTitle => 'تعديل عنصر';

  @override
  String get adminAddItemTitle => 'إضافة عنصر';

  @override
  String get adminWordLabel => 'مقولة';

  @override
  String get adminTextLabel => 'نص';

  @override
  String get adminTurkishTextLabel => 'النص التركي';

  @override
  String get adminTurkishLabel => 'تركي';

  @override
  String get adminArabicLabel => 'عربي';

  @override
  String get adminTypeLabel => 'النوع';

  @override
  String get adminReferenceLabel => 'مرجع';

  @override
  String get adminTitleLabel => 'عنوان';

  @override
  String get adminOptionalSourceReferenceLabel => 'المصدر / المرجع (اختياري)';

  @override
  String get adminWordCannotBeEmpty => 'لا يمكن أن تكون المقولة فارغة.';

  @override
  String get adminTextCannotBeEmpty => 'لا يمكن أن يكون النص فارغًا.';

  @override
  String get adminTurkishTextCannotBeEmpty =>
      'لا يمكن أن يكون النص التركي فارغًا.';

  @override
  String get adminTurkishAndArabicRequired => 'حقلا التركي والعربي مطلوبان.';

  @override
  String get adminTurkishArabicReferenceRequired =>
      'التركي والعربي والمرجع مطلوبة.';

  @override
  String get adminTitleAndTextRequired => 'العنوان والنص مطلوبان.';

  @override
  String get adminPoolItemWillBeEdited => 'سيتم تعديل عنصر المخزن';

  @override
  String get adminNewPoolItemWillBeAdded => 'سيتم إضافة عنصر جديد إلى المخزن';

  @override
  String get adminVersionConflictError =>
      'تم تحديث هذا المحتوى بواسطة مشرف آخر. رجاءً حدّث وحاول مجددًا.';

  @override
  String get adminNoPermissionForOperation => 'لا تملك صلاحية لهذه العملية.';

  @override
  String get adminNetworkOrServiceUnavailable =>
      'الاتصال ضعيف أو الخدمة غير متاحة مؤقتًا.';

  @override
  String get adminOperationTimedOut => 'انتهت مهلة العملية. حاول مرة أخرى.';

  @override
  String get adminSessionCouldNotBeVerified =>
      'تعذر التحقق من الجلسة. يرجى تسجيل الدخول مجددًا.';

  @override
  String get adminAuthorizationCouldNotBeVerified => 'تعذر التحقق من الصلاحية';

  @override
  String get adminAuthorizationCheckUnavailable =>
      'فحص الصلاحية غير متاح الآن.\nتحقق من اتصال الإنترنت ثم أعد المحاولة.';

  @override
  String get adminBackToSettings => 'العودة إلى الإعدادات';

  @override
  String get adminNoAccessTitle => 'لا صلاحية';

  @override
  String get adminPageForAdminsOnly => 'هذه الصفحة للمشرفين فقط.';

  @override
  String get adminPanelTitle => 'لوحة الإدارة';

  @override
  String get adminPoolsTab => 'المخازن';

  @override
  String get adminInspireCardsTab => 'بطاقات الاستكشاف';

  @override
  String get adminDiagnosticsTab => 'التشخيص والسجل';

  @override
  String get adminDeveloperTab => 'المطور';

  @override
  String get adminGrantsTab => 'الصلاحيات';

  @override
  String get adminSectionOnlyForFullAccess =>
      'هذا القسم متاح للصلاحية الكاملة فقط.';

  @override
  String get adminDeveloperToolsDeveloperOnly =>
      'أدوات المطور متاحة لمستوى developer فقط.';

  @override
  String get adminDeletePoolItemTitle => 'حذف عنصر من المخزن';

  @override
  String adminDeletePoolItemMessage(Object poolId) {
    return 'سيتم حذف هذا العنصر نهائيًا من المخزن \"$poolId\" وكتابته فورًا إلى Firestore. لا يمكن التراجع.';
  }

  @override
  String get adminPoolItemWillBeDeleted => 'سيتم حذف عنصر من المخزن';

  @override
  String get adminRemoveCardFromListTitle => 'إزالة البطاقة من القائمة';

  @override
  String get adminRemoveCardFromListMessage =>
      'ستزال البطاقة من القائمة المحلية. اضغط \"حفظ\" لمزامنة التغييرات مع Firestore.';

  @override
  String get adminRemoveAction => 'إزالة';

  @override
  String get adminDiagnosticsAccessDeniedTitle =>
      'شاشة التشخيص متاحة للمدير والصلاحية الكاملة.';

  @override
  String get adminDiagnosticsAccessDeniedSubtitle =>
      'مديرو المحتوى يمكنهم تعديل المخازن والاستكشاف.';

  @override
  String get adminRoleContentPlain => 'محتوى';

  @override
  String get adminRoleManagerPlain => 'مدير';

  @override
  String get adminRoleDeveloperPlain => 'مطور';

  @override
  String get adminRoleNonePlain => 'لا شيء';

  @override
  String get adminGrantManagementAccessDeniedTitle =>
      'إدارة الصلاحيات متاحة للصلاحية الكاملة فقط.';

  @override
  String get adminGrantManagementAccessDeniedSubtitle =>
      'منح/إزالة مستويات المشرف تتم عبر دور developer.';

  @override
  String get adminGrantHint =>
      'أدخل بريدًا أو UID لمنح مستوى content أو manager أو developer.';

  @override
  String adminFixedFullAccess(Object emails) {
    return 'حسابات الصلاحية الكاملة الثابتة: $emails';
  }

  @override
  String adminDefinedGrants(int count) {
    return 'الصلاحيات المعرفة ($count)';
  }

  @override
  String get adminGrantsLoading => 'جارٍ تحميل الصلاحيات...';

  @override
  String get adminNoFirestoreGrantsYet =>
      'لا توجد صلاحيات مضافة عبر Firestore بعد.';

  @override
  String get surveyBack => 'رجوع';

  @override
  String get surveyNext => 'متابعة';

  @override
  String get namazIbadetWarningTitle => 'تنبيه';

  @override
  String get namazIbadetWarningSubtitle =>
      'تتبع الصلاة ليس للمظاهر؛ بل لتنظيم قلبك بخشوع وصدق.';

  @override
  String get namazIbadetWarningBullet1 =>
      'ضع العلامات لنفسك فقط؛ ولا تجعله وسيلة للرياء أو الضغط على الآخرين.';

  @override
  String get namazIbadetWarningBullet2 =>
      'إذا فاتك وقت صلاة فلا تحتقر نفسك؛ كل رجوع هو توبة وبداية جديدة.';

  @override
  String get namazIbadetWarningBullet3 =>
      'يمكنك إدارة الإشعارات في أي وقت من إعدادات النظام؛ لا ينبغي أن يتحول التتبع إلى عبء.';

  @override
  String get namazIbadetCommitmentTitle => 'وعدك لنفسك';

  @override
  String get namazIbadetCommitmentHint =>
      'اكتب جملة صادقة عن صلاتك (8 أحرف على الأقل).';

  @override
  String get namazIbadetCommitmentFieldHint => 'جملة من قلبك...';

  @override
  String get namazIbadetCommitmentTooShort =>
      'يرجى كتابة وعد لنفسك (8 أحرف على الأقل).';

  @override
  String get namazIbadetSealTitlePrefix => 'اختم وعدك';

  @override
  String get namazIbadetSealHoldHint => 'أبق إصبعك ضاغطًا';

  @override
  String get namazIbadetSealSuccess =>
      'تم حفظ وعدك. جارٍ الانتقال إلى شاشة العبادة.';

  @override
  String get namazIbadetSealEncourageNotHolding =>
      'عندما تكون جاهزًا، اضغط مطولًا على الختم لتثبيت وعدك.';

  @override
  String get namazIbadetSealEncourageHolding =>
      'أبطئ تنفسك ودع وعدك يستقر في قلبك.';

  @override
  String get namazIbadetPrepTitle => 'تهيئة';

  @override
  String get namazIbadetExamplesTitle => 'أمثلة';

  @override
  String get closeAction => 'إغلاق';

  @override
  String get saveAction => 'حفظ';

  @override
  String get selectAction => 'اختيار';

  @override
  String get quitPickerTemplateAlreadyExists =>
      'هذا البرنامج موجود بالفعل في قائمتك؛ يُسمح بعنصر واحد فقط لكل قالب.';

  @override
  String get quitPickerOpenAction => 'فتح';

  @override
  String get quitPickerGoToListAction => 'الذهاب إلى القائمة';

  @override
  String get quitPickerTemplateScreenTitle => 'التخلص من إدمان الشاشة';

  @override
  String get quitPickerTemplateSmokingTitle => 'الإقلاع عن التدخين';

  @override
  String get quitPickerTemplateAlcoholTitle => 'الإقلاع عن الكحول';

  @override
  String get quitPickerTemplateSubstanceTitle => 'الإقلاع عن المخدرات';

  @override
  String get quitPickerTemplateZinaTitle => 'الإقلاع عن الزنا';

  @override
  String get quitPickerHeaderTitle => 'التطهر من العادات السيئة';

  @override
  String get quitPickerHeaderSubtitle =>
      'اختر العادة التي تريد تركها؛ واستخدم الخيار بالأسفل لهدف مخصص.';

  @override
  String get quitPickerScreenLabel => 'الشاشة';

  @override
  String get quitPickerScreenSubtitle => 'حدود وهدوء';

  @override
  String get quitPickerSmokingLabel => 'التدخين';

  @override
  String get quitPickerAlcoholLabel => 'الكحول';

  @override
  String get quitPickerSubstanceLabel => 'المخدرات';

  @override
  String get quitPickerSubstanceSubtitle => 'دعم ومتابعة';

  @override
  String get quitPickerZinaLabel => 'الزنا';

  @override
  String get quitPickerDefaultSubtitle => 'برنامج تطهير';

  @override
  String get quitPickerAlreadyAdded => 'مضاف بالفعل';

  @override
  String get quitPickerAddCustomTitle => 'إضافة مخصص';

  @override
  String get quitPickerAddCustomSubtitle => 'أنشئ روتين التطهير الخاص بك.';

  @override
  String get buildProgramSetupQuranTitle => 'برنامج القرآن اليومي';

  @override
  String get buildProgramSetupDefaultTitle => 'برنامج';

  @override
  String get buildProgramSetupHeadlineQuran => 'صفحة لكل يوم';

  @override
  String get buildProgramSetupHeadlineDefault => 'ابدأ برنامجك';

  @override
  String get buildProgramSetupBadge => 'خطوة تهيئة';

  @override
  String get buildProgramSetupBodyQuran =>
      'على الأقل صفحة واحدة — قليل لكنه مستمر. التقدم والنصائح بانتظارك في الشاشة التالية.';

  @override
  String get buildProgramSetupBodyDefault =>
      'التقدم والنصائح بانتظارك في الشاشة التالية.';

  @override
  String get buildProgramSetupAlreadyActive =>
      'برنامج القرآن اليومي لديك مفعّل بالفعل. تم توجيهك إلى البرنامج الحالي.';

  @override
  String get buildProgramSetupQuranHabitTitle => 'القرآن اليومي';

  @override
  String get buildProgramSetupStartAction => 'ابدأ البرنامج';

  @override
  String get buildProgramSetupPrincipleTitle =>
      'القليل المستمر خير من الكثير المنقطع';

  @override
  String get buildProgramSetupPrincipleQuote =>
      'قال النبي ﷺ: \"أحب الأعمال إلى الله أدومها وإن قل.\"';

  @override
  String get buildProgramDetailNotFound => 'لم يتم العثور على البرنامج';

  @override
  String get buildProgramDetailTabGeneral => 'عام';

  @override
  String get buildProgramDetailTabTips => 'نصائح';

  @override
  String get buildProgramDetailTabProgress => 'التقدم';

  @override
  String get buildProgramDetailTodayQuestion => 'هل أكملت هدف القراءة اليوم؟';

  @override
  String get buildProgramDetailTodayDone => 'تم الإكمال اليوم';

  @override
  String get buildProgramDetailTodayPending =>
      'لم يتم التعليم بعد اليوم — اضغط';

  @override
  String buildProgramDetailDayCount(int days) {
    return 'اليوم $days';
  }

  @override
  String get buildProgramDetailProgressIndicatorLabel => 'مؤشر تقدم تحفيزي';

  @override
  String buildProgramDetailRoutinePercent(int percent) {
    return 'اتساق الروتين $percent%';
  }

  @override
  String buildProgramDetailMilestoneLabel(int day, int percent) {
    return 'اليوم $day — $percent%';
  }

  @override
  String get buildProgramDetailDisclaimer =>
      'هذه المؤشرات للتحفيز العام وليست قياسات علمية أو طبية.';

  @override
  String get onboardingSlide1Title => 'نَفَس وسط الضجيج';

  @override
  String get onboardingSlide1Subtitle =>
      'عندما يركض الذهن، يهمس الصوت الداخلي غالبًا. التوقفات الصغيرة — نفس واحد، وقفة قصيرة — تنعش التوازن الروحي؛ فالسكينة التي تبحث عنها في الخارج قد تنبت أولًا بهدوء في الداخل.';

  @override
  String get onboardingSlide2Title => 'ابدأ صغيرًا، وانمُ بالاستمرار';

  @override
  String get onboardingSlide2Subtitle =>
      'سجّل عاداتك في التطوير والتزكية. يوم واحد، نفس واحد، اختيار واحد — تقدّم دون كسر السلسلة؛ فالتزكية مثل صعود السلالم، قوة بعد قوة.';

  @override
  String get onboardingSlide3Title => 'الوقت والصلاة وتنظيم يومك';

  @override
  String get onboardingSlide3Subtitle =>
      'اجعل أوقات الصلاة بقربك؛ ولتكن تمارين التنفس ومساحة التقوية معك في اللحظات الصعبة. اجمع عبادتك وتتبعك وصوتك الداخلي على إيقاع واحد.';

  @override
  String get onboardingSlide4Title => 'Arin: كل شيء في تطبيق واحد';

  @override
  String get onboardingSlide4Subtitle =>
      'من الإلهام إلى العادات اليومية، ومن تنبيهات الأوقات إلى عدّاد التزكية، رحلتك هنا. إن كنت جاهزًا فلنبدأ معًا — أنت تمضي ونحن نذكّرك ونرافقك.';

  @override
  String get onboardingGetStarted => 'لنبدأ';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get surveyNameTitle => 'كيف تحب أن نخاطبك؟';

  @override
  String get surveyNameHint => 'اسمك';

  @override
  String get surveyGenderTitle => 'هل يمكننا معرفة جنسك؟';

  @override
  String get surveyGenderSubtitle => 'لمساعدتك بشكل أفضل...';

  @override
  String get surveyGenderMale => 'ذكر';

  @override
  String get surveyGenderFemale => 'أنثى';

  @override
  String get surveyMoodTitle => 'ما النبرة الأبرز في داخلك الآن؟';

  @override
  String get surveyMoodSubtitle =>
      'اختر الإشارات التي تصفك؛ ليتكيّف المحتوى والتذكير معها.';

  @override
  String get surveyDailyRhythmTitle => 'أين يمضي معظم يومك عادةً؟';

  @override
  String get surveyDailyRhythmSubtitle =>
      'الإيقاع والبيئة يساعداننا على فهم النمط الأنسب لك.';

  @override
  String get surveyInnerThemesTitle => 'ما الموضوعات الداخلية الأبرز لديك؟';

  @override
  String get surveyInnerThemesSubtitle =>
      'يمكنك اختيار أكثر من خيار؛ الإشارات الصادقة تساعدنا على فهمك بشكل أفضل.';

  @override
  String get surveyNotificationTitle => 'الإشعارات';

  @override
  String get surveyNotificationLead =>
      'ليصلك تذكير الصلاة ورسائل اليوم في وقتها.';

  @override
  String get surveyNotificationSubtitle =>
      'نحتاج إذن الإشعارات حتى لا تفوتك تنبيهات الأوقات واقتراحات المحتوى. يمكنك إيقافها في أي وقت من الإعدادات.';

  @override
  String get surveyNotificationAllow => 'السماح بالإشعارات';

  @override
  String get surveyNotificationSkip => 'تخطي الآن';

  @override
  String get surveyNotificationOpenSettings => 'فتح الإعدادات';

  @override
  String get surveySave => 'ابدأ ➔';

  @override
  String get surveyGenderDecline => 'أفضل عدم المشاركة';

  @override
  String get surveyNameGreetingPrefix => 'مرحبًا';

  @override
  String get surveySummaryTitle => 'أنت جاهز';

  @override
  String get surveySummarySubtitle =>
      'حفظنا تفضيلاتك الأساسية. سنشكّل تجربة Arin وفق هذه الإشارات.';

  @override
  String get surveySummaryCardTitle => 'ملخص البداية';

  @override
  String get surveySummaryItemName => 'الاسم';

  @override
  String get surveySummaryItemMood => 'إشارات المزاج';

  @override
  String get surveySummaryItemRhythm => 'إشارات الإيقاع اليومي';

  @override
  String get surveySummaryItemThemes => 'إشارات المواضيع الداخلية';

  @override
  String get surveySummaryItemNotificationOn => 'مفعّل';

  @override
  String get surveySummaryItemNotificationOff => 'متوقف';

  @override
  String get surveySummaryNotProvided => 'غير محدد';

  @override
  String get surveySummaryAction => 'الانتقال إلى الرئيسية';

  @override
  String get surveySummarySaveError =>
      'تعذر حفظ بيانات البداية. يرجى المحاولة مرة أخرى.';

  @override
  String get moodHappy => 'سعيد';

  @override
  String get moodCalm => 'هادئ';

  @override
  String get moodStressed => 'متوتر';

  @override
  String get moodSad => 'حزين';

  @override
  String get moodGrateful => 'ممتن';

  @override
  String get moodAnxious => 'قلِق';

  @override
  String get moodMotivated => 'متحمس';

  @override
  String get sectorStudent => 'ثانوي / جامعة / تحضيري';

  @override
  String get sectorPrivate => 'القطاع الخاص';

  @override
  String get sectorPublic => 'القطاع الحكومي';

  @override
  String get sectorBusiness => 'عملي الخاص / مستقل';

  @override
  String get sectorTrade => 'التجارة';

  @override
  String get sectorHousehold => 'رب/ربة منزل';

  @override
  String get sectorOther => 'أخرى';

  @override
  String get needMotivation => 'الدافعية';

  @override
  String get needSabr => 'الصبر';

  @override
  String get needShukr => 'الشكر';

  @override
  String get needTawakkul => 'التوكل';

  @override
  String get needFocus => 'التركيز';

  @override
  String get needHealing => 'الشفاء';

  @override
  String get needRizq => 'الرزق والبركة';

  @override
  String get appPrepareTitle => 'نجهّز Arin لك';

  @override
  String get appPrepareSubtitle => 'يتم تحميل أوقات الصلاة وكلمات اليوم لك...';

  @override
  String get shellExitConfirmBackTwice => 'اضغط رجوع مرة أخرى للخروج';

  @override
  String get inspireExploreTitle => 'استكشاف';

  @override
  String get inspireSearchHint => 'بحث';

  @override
  String get inspireFilterTooltip => 'نوع المحتوى';

  @override
  String get inspireFilterMainFeed => 'التدفق الرئيسي';

  @override
  String get inspireFilterQuote => 'قول';

  @override
  String get inspireFilterVerse => 'آية';

  @override
  String get inspireFilterHadith => 'حديث';

  @override
  String get inspireSearchNoResults =>
      'لا يوجد محتوى مطابق لهذا البحث.\nجرّب كلمة مختلفة أو كتابة مبسطة.';

  @override
  String get inspireEmptyTitle => 'لا يوجد محتوى بعد';

  @override
  String get inspireEmptySubtitle =>
      'الصور: assets/inspiration/ (1.jpg, 2.jpg, ...).\nالمحتوى: assets/data/inspiration/*.json أو Firestore app_public/inspiration_cards.';

  @override
  String get inspirePullToRefreshHint => 'اسحب لأسفل للتحديث.';

  @override
  String get inspireLoadFailedTitle => 'تعذر التحميل';

  @override
  String get inspirePullToRetryHint => 'اسحب لأسفل للمحاولة مرة أخرى.';

  @override
  String get viewerBackAction => 'رجوع';

  @override
  String get viewerNoCard => 'لا توجد بطاقة';

  @override
  String get asyncErrorDefaultTitle => 'حدث خطأ ما';

  @override
  String get asyncErrorDefaultMessage =>
      'قد يكون الاتصال ضعيفًا أو الخدمة غير متاحة الآن. حاول مرة أخرى بعد قليل.';

  @override
  String get asyncErrorRetryAction => 'إعادة المحاولة';

  @override
  String get asyncErrorTechnicalDetailsTitle => 'تفاصيل تقنية';

  @override
  String get asyncErrorCopiedToClipboard => 'تم نسخ الخطأ إلى الحافظة.';

  @override
  String get savedInspirationTitle => 'المحفوظات';

  @override
  String get savedInspirationLoadFailedPrefix => 'تعذر التحميل';

  @override
  String get savedInspirationEmptyTitle => 'دفتر قلبك فارغ';

  @override
  String get savedInspirationEmptySubtitle =>
      'احفظ الكلمات التي تلمسك في الاستكشاف؛ لتجتمع هنا وتعود إليك.';

  @override
  String get savedInspirationGoExploreAction => 'الذهاب إلى الاستكشاف';

  @override
  String get clockPickerCancelAction => 'إلغاء';

  @override
  String get clockPickerConfirmAction => 'تم';

  @override
  String get clockPickerHourLabel => 'الساعة';

  @override
  String get clockPickerMinuteLabel => 'الدقيقة';

  @override
  String get salatWeekCelebrationTitle => 'أكملت الأسبوع';

  @override
  String get salatWeekCelebrationAction => 'الحمد لله';

  @override
  String get adminEmailInviteLabel => 'دعوة بريد إلكتروني';
}
