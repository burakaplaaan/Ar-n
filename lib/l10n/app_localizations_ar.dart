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
      'يمكنك إرسال الاقتراحات أو بلاغات الأعطال أو طلبات الدعم مباشرة عبر البريد الإلكتروني. يرجى أيضًا كتابة ماركة هاتفك وطرازه.';

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
  String settingsContactMailBody(Object device) {
    return 'مرحبًا فريق Arin،\n\nالجهاز (الماركة والطراز): $device\n\n';
  }

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
  String get settingsSessionHint => 'لإغلاق الجلسة أو حذف الحساب:';

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
      'سيتم إغلاق جلسة Google أو Apple. يبقى اسمك وعاداتك وإعداداتك على هذا الجهاز. لن تبدأ خطوات الإعداد من جديد.';

  @override
  String get settingsSignOutSuccess => 'تم إغلاق الجلسة.';

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
  String get homeRequestLocationAction => 'السماح بالموقع';

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
  String quitProgramElapsedDHms(int days, int hours, int minutes, int seconds) {
    return '$days ي $hours س $minutes د $seconds ث';
  }

  @override
  String quitProgramElapsedMdHms(
    int months,
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$months ش $days ي $hours س $minutes د $seconds ث';
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
    return '$years سنة $months ش $days ي $hours س $minutes د $seconds ث';
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
  String get qiblaHubAssistantTitle => 'مساعد أرِن';

  @override
  String get qiblaHubAssistantSubtitle =>
      'محادثة؛ إدارة الصلاة والتنبيهات والتذكيرات';

  @override
  String get assistantTitle => 'مساعد أرِن';

  @override
  String get assistantSubtitle => '';

  @override
  String get assistantAskChip => 'المساعد';

  @override
  String get assistantInputHint => 'اكتب باختصار…';

  @override
  String get assistantEmptyTitle => 'السلام عليكم!';

  @override
  String get assistantEmptyBody => 'أنا ذكاء اصطناعي إسلامي.';

  @override
  String get assistantHello => 'السلام عليكم!';

  @override
  String assistantHelloName(String name) {
    return 'السلام عليكم! $name';
  }

  @override
  String get assistantPromptLockVerse => 'كيف أضع آية على شاشة القفل؟';

  @override
  String get assistantPromptInshirah => 'اشرح سورة الانشراح.';

  @override
  String get assistantPromptRamadan => 'كم يوماً بقي لرمضان؟';

  @override
  String get assistantNeedSignIn => 'سجّل الدخول لاستخدام المساعد.';

  @override
  String get assistantNeedPremium => 'مساعد أرِن مخصص للبريميوم.';

  @override
  String get assistantGateHint =>
      'سجّل الدخول وفعّل البريميوم لبدء الدردشة الكتابية. لا تُحفظ المحادثات.';

  @override
  String get assistantOpenPremium => 'افتح البريميوم';

  @override
  String get assistantSignIn => 'تسجيل الدخول';

  @override
  String get assistantGenericError => 'تعذّر على المساعد الرد الآن.';

  @override
  String get assistantQuotaReached => 'انتهى حد رسائل اليوم.';

  @override
  String get assistantMessageTooLong => 'اختصر الرسالة (100 حرف كحد أقصى).';

  @override
  String get assistantNotReady => 'المساعد غير جاهز بعد.';

  @override
  String assistantWordCount(int count, int max) {
    return '$count/$max حرف';
  }

  @override
  String assistantRemainingToday(int count) {
    return 'بقي $count';
  }

  @override
  String get assistantActionFailed => 'تعذّر تنفيذ ذلك.';

  @override
  String get assistantActionUnknownPage => 'تعذّر فتح تلك الصفحة.';

  @override
  String get assistantNavigatingThere => 'أفتحها الآن.';

  @override
  String get assistantLockVerseGuide =>
      'يمكنك فعل ذلك من أرِن. من الإعدادات → مركز الأدوات أضف آية شاشة القفل. لا تحتاج تطبيقاً آخر.';

  @override
  String assistantRamadanDays(String today, int days, String date) {
    return 'اليوم $today. تبقّى $days يوماً لرمضان. البداية التقريبية $date؛ قد يتأخر الهلال يوماً.';
  }

  @override
  String assistantRamadanTomorrow(String today, String date) {
    return 'اليوم $today. رمضان يبدأ غداً (تقريباً $date).';
  }

  @override
  String assistantRamadanToday(String today) {
    return 'اليوم $today. رمضان يبدأ اليوم.';
  }

  @override
  String assistantRamadanOngoing(String today, int day) {
    return 'اليوم $today. نحن في رمضان؛ هذا اليوم $day.';
  }

  @override
  String get assistantPrayerTimesMissing =>
      'مواقيت الصلاة غير جاهزة بعد. فعّل الموقع وانتظر قليلاً.';

  @override
  String assistantPrayerCountdown(String label, String remaining, String time) {
    return '$label $remaining. الوقت $time.';
  }

  @override
  String assistantPrayerCountdownTomorrow(
    String label,
    String remaining,
    String time,
  ) {
    return '$label $remaining. غداً الساعة $time.';
  }

  @override
  String get assistantPrayerLabelIftar => 'إلى الإفطار';

  @override
  String get assistantPrayerLabelImsak => 'إلى الإمساك';

  @override
  String get assistantPrayerLabelDhuhr => 'إلى الظهر';

  @override
  String get assistantPrayerLabelAsr => 'إلى العصر';

  @override
  String get assistantPrayerLabelMaghrib => 'إلى المغرب';

  @override
  String get assistantPrayerLabelIsha => 'إلى العشاء';

  @override
  String assistantPrayerLabelNext(String name) {
    return 'إلى الصلاة التالية ($name)';
  }

  @override
  String assistantDurationHm(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String assistantDurationH(int hours) {
    return '$hours س';
  }

  @override
  String assistantDurationM(int minutes) {
    return '$minutes د';
  }

  @override
  String get assistantDurationSoon => 'أقل من دقيقة';

  @override
  String get assistantActionCancelled => 'تم الإلغاء.';

  @override
  String get assistantSalatHabitMissing => 'ابدأ برنامج الصلاة أولاً.';

  @override
  String get assistantPrayerMarked => 'تم تعليم الصلاة كمُؤدّاة.';

  @override
  String get assistantPrayerUnmarked => 'أزلت علامة الصلاة.';

  @override
  String get assistantAlarmDefaultTitle => 'تذكير أرِن';

  @override
  String get assistantAlarmBody => 'التذكير الذي ضبطته.';

  @override
  String get assistantAlarmPermissionDenied =>
      'لا يمكن ضبط منبّه دون إذن الإشعارات.';

  @override
  String assistantAlarmSet(String time) {
    return 'تم ضبط التذكير عند $time.';
  }

  @override
  String get assistantNotificationsOn => 'تم تفعيل الإشعار.';

  @override
  String get assistantNotificationsOff => 'تم إيقاف الإشعار.';

  @override
  String get assistantConfirmDisablePrayerTitle => 'إيقاف تنبيهات الصلاة؟';

  @override
  String get assistantConfirmDisablePrayerBody =>
      'ستُوقف كل تذكيرات أوقات الصلاة.';

  @override
  String get assistantCancel => 'إلغاء';

  @override
  String get assistantConfirm => 'إيقاف';

  @override
  String get qiblaHubHealingTitle => 'ترددات الشفاء';

  @override
  String get qiblaHubHealingSubtitle =>
      'جلسة هادئة مع نغمات علاجية، أجواء صوتية، ومؤقت نوم';

  @override
  String get qiblaHubAiTitle => 'الذكاء الاصطناعي الإسلامي';

  @override
  String get qiblaHubAiSubtitle => 'اسأل ما يدور في ذهنك وابدأ محادثة إسلامية';

  @override
  String get islamicAiComingSoonTitle => 'الذكاء الاصطناعي الإسلامي';

  @override
  String get islamicAiComingSoonBody =>
      'هذه الميزة قيد الإعداد. Premium لديك مفعّل؛ ستُفتح المحادثة هنا بعد دمج الشيفرة.';

  @override
  String get widgetThemeSectionTitle => 'سمات الأدوات';

  @override
  String get widgetThemeSectionSubtitle =>
      'السمة الكلاسيكية مجانية. السمات الأخرى خاصة بـ Premium وتظهر بنفس الشكل على iPhone وAndroid.';

  @override
  String get widgetThemeApplied => 'تم تحديث سمة الأداة.';

  @override
  String get widgetThemePremiumRequired => 'هذه السمة خاصة بـ Premium.';

  @override
  String get widgetLockTextSectionTitle => 'نص شاشة القفل';

  @override
  String get widgetLockTextSectionSubtitle =>
      'لا يمكن تغيير اللون على شاشة القفل. يمكنك جعل النص واضحًا أو ناعمًا. خاص بـ Premium.';

  @override
  String get widgetLockTextClear => 'واضح';

  @override
  String get widgetLockTextSoft => 'ناعم';

  @override
  String get widgetLockTextApplied => 'تم تحديث نص شاشة القفل.';

  @override
  String get qiblaHubHilalDuelTitle => 'مبارزة المعرفة';

  @override
  String get qiblaHubHilalDuelSubtitle =>
      'تنافس في 7 أسئلة إسلامية، واجمع الأهلة وتقدّم بالمستوى';

  @override
  String get hilalDuelTitle => 'مبارزة المعرفة';

  @override
  String get hilalDuelLanguageNote => 'الأسئلة حالياً بالتركية';

  @override
  String get hilalDuelRulesSummary =>
      '7 أسئلة • 20 ثانية لكل سؤال\nالدقة والسرعة تحسمان الفوز. يفتح السؤال التالي فور إجابة الطرفين. شاهد إعلانًا لقلب أو العب بلا حدود مع بريميوم.';

  @override
  String hilalDuelLevelLabel(int level) {
    return 'المستوى $level';
  }

  @override
  String hilalDuelHilalsLabel(int count) {
    return '$count هلال';
  }

  @override
  String hilalDuelHeartsLabel(int count) {
    return '$count قلب';
  }

  @override
  String get hilalDuelPlay => 'العب مباشرة';

  @override
  String get hilalDuelWatchAdForHeart => 'شاهد إعلاناً لتحصل على قلب واحد';

  @override
  String get hilalDuelNeedHeartTitle => 'تحتاج قلباً واحداً للعب';

  @override
  String get hilalDuelNeedHeartHint =>
      'شاهد إعلاناً قصيراً ← احصل على قلب واحد والعب فوراً';

  @override
  String get hilalDuelNeedHeartCta => 'شاهد الإعلان';

  @override
  String get hilalDuelSearching => 'جارٍ البحث عن منافس…';

  @override
  String get hilalDuelCancelSearch => 'إلغاء البحث';

  @override
  String get hilalDuelCancelFailed =>
      'تعذّر الإلغاء. أعد المحاولة لاسترداد القلب.';

  @override
  String hilalDuelQuestionProgress(int current, int total) {
    return 'سؤال $current/$total';
  }

  @override
  String get hilalDuelDifficultyEasy => 'سهل';

  @override
  String get hilalDuelDifficultyMedium => 'متوسط';

  @override
  String get hilalDuelDifficultyHard => 'صعب';

  @override
  String get hilalDuelWaitingOpponent => 'المنافس يجيب…';

  @override
  String get hilalDuelAnsweredBubble => 'أجاب';

  @override
  String get hilalDuelRoundCorrect => 'صحيح';

  @override
  String get hilalDuelRoundWrong => 'خطأ';

  @override
  String get hilalDuelNoAnswer => 'بلا إجابة';

  @override
  String get hilalDuelFastOpponent => 'منافس سريع';

  @override
  String get hilalDuelResultWin => 'لقد فزت';

  @override
  String get hilalDuelResultLose => 'لقد خسرت';

  @override
  String get hilalDuelResultDraw => 'تعادل';

  @override
  String get hilalDuelResultScoreCaption => 'عدد الإجابات الصحيحة';

  @override
  String hilalDuelCorrectCount(int count) {
    return '$count صحيحة';
  }

  @override
  String hilalDuelTotalSeconds(int seconds) {
    return '$seconds ث';
  }

  @override
  String hilalDuelHilalsEarned(int count) {
    return '+$count هلال';
  }

  @override
  String get hilalDuelDoubleReward => 'شاهد إعلاناً لمضاعفة الأهلة';

  @override
  String get hilalDuelDoubled => 'تم مضاعفة الأهلة';

  @override
  String get hilalDuelLobby => 'العودة إلى الردهة';

  @override
  String get hilalDuelRematch => 'العب مجدداً';

  @override
  String get hilalDuelChallengeAgain => 'تحدَّ مجدداً';

  @override
  String get hilalDuelRetry => 'أعد المحاولة';

  @override
  String get hilalDuelPremiumUnlimited => 'بريميوم: قلوب غير محدودة';

  @override
  String get hilalDuelUpgradePremium => 'الترقية إلى بريميوم • لعب بلا حدود';

  @override
  String get hilalDuelNextLevel => 'المستوى التالي';

  @override
  String get hilalDuelMaxLevel => 'أقصى مستوى';

  @override
  String hilalDuelNextRewardFrame(int level) {
    return 'المكافأة التالية: إطار الصورة (LV $level)';
  }

  @override
  String hilalDuelNextRewardTitle(String title, int level) {
    return 'المكافأة التالية: لقب “$title” (LV $level)';
  }

  @override
  String hilalDuelNextRewardHilalIcon(int level) {
    return 'المكافأة التالية: أيقونة هلال خاصة (LV $level)';
  }

  @override
  String hilalDuelNextRewardFrameSilver(int level) {
    return 'المكافأة التالية: إطار فضي (LV $level)';
  }

  @override
  String hilalDuelNextRewardGlow(int level) {
    return 'المكافأة التالية: توهج الصورة (LV $level)';
  }

  @override
  String hilalDuelNextRewardNameAccent(int level) {
    return 'المكافأة التالية: لون الاسم (LV $level)';
  }

  @override
  String get hilalDuelWeeklyTitle => 'أفضل لاعب هذا الأسبوع';

  @override
  String get hilalDuelWeeklyResetHint => 'يُصفَّر يوم الاثنين';

  @override
  String hilalDuelWeeklyThisWeek(int count) {
    return 'هذا الأسبوع: $count هلال';
  }

  @override
  String hilalDuelWeeklyRank(int rank) {
    return 'الترتيب: #$rank';
  }

  @override
  String get hilalDuelWeeklyRankNone => 'الترتيب: —';

  @override
  String get hilalDuelWeeklyTapHint => 'عرض الترتيب';

  @override
  String get hilalDuelWeeklyTopPreview => 'أفضل 3';

  @override
  String get hilalDuelWeeklyClimbHint =>
      'أفضل 10 في الدوري الأخضر — العب وتقدّم!';

  @override
  String get hilalDuelWeeklyPremiumRewardHint =>
      '1 ← 14 يوم Premium + شارة البطل\n2 ← 7 أيام Premium\n3 ← 3 أيام Premium';

  @override
  String get hilalDuelWeeklyLastWinnersTitle => 'فائزو الأسبوع الماضي';

  @override
  String get hilalDuelWeeklyLastWinnerPrize1 => '14 يوم Premium + شارة البطل';

  @override
  String get hilalDuelWeeklyLastWinnerPrize2 => '7 أيام Premium';

  @override
  String get hilalDuelWeeklyLastWinnerPrize3 => '3 أيام Premium';

  @override
  String get hilalDuelWeeklyEmpty =>
      'لم يكتسب أحد أهلة هذا الأسبوع بعد. أنهِ أول مباراة!';

  @override
  String hilalDuelWeeklyYourPlace(int rank, int count) {
    return 'ترتيبك: #$rank · $count هلال';
  }

  @override
  String get hilalDuelAdminRemoveTitle => 'إزالة من القائمة';

  @override
  String hilalDuelAdminRemoveBody(String name) {
    return 'هل تريد إزالة “$name” من ترتيب هذا الأسبوع؟ يتقدم من بعده مرتبة واحدة؛ ولن يظهر في القائمة هذا الأسبوع.';
  }

  @override
  String get hilalDuelAdminRemoveAction => 'إزالة';

  @override
  String get hilalDuelAdminRemoved => 'تمت إزالة اللاعب من القائمة.';

  @override
  String get hilalDuelTitleTalebe => 'طالب';

  @override
  String get hilalDuelTitleMuderris => 'مدرّس';

  @override
  String get hilalDuelTitleIlimDostu => 'صديق العلم';

  @override
  String get hilalDuelYouLabel => 'أنت';

  @override
  String get hilalDuelOpponentLabel => 'المنافس';

  @override
  String get hilalDuelChallengeAction => 'تحدَّ';

  @override
  String get hilalDuelAdminChallengeTitle => 'تحدٍّ';

  @override
  String get hilalDuelAdminChallengeBody =>
      'العب بنفسك، أو أرسل تلقائياً بنتيجة 3–5 إجابات صحيحة لإثارة المنافس.';

  @override
  String get hilalDuelAdminChallengePlay => 'العب فعلاً';

  @override
  String get hilalDuelAdminChallengeAuto => 'إرسال تلقائي';

  @override
  String get hilalDuelChallengeInboxTitle => 'التحديات';

  @override
  String get hilalDuelChallengeAccept => 'اقبل';

  @override
  String get hilalDuelChallengeContinue => 'متابعة';

  @override
  String get hilalDuelChallengeSeeResult => 'عرض النتيجة';

  @override
  String get hilalDuelChallengeWaiting => 'بانتظار المنافس';

  @override
  String get hilalDuelChallengeYourTurn => 'دورك';

  @override
  String get hilalDuelChallengeExpired => 'انتهى الوقت — بلا نقاط';

  @override
  String get hilalDuelChallengeHint =>
      'تحدَّ أحداً من القائمة. تستهلك قلباً واحداً؛ إذا انتهى الوقت فلن يحصل أحد على نقاط.';

  @override
  String get hilalDuelChallengePickTitle => 'اختر منافساً';

  @override
  String get hilalDuelChallengePickHint =>
      'اختر لاعباً للتحدي. تجيب أولاً. لدى المنافس 24 ساعة للرد.';

  @override
  String get hilalDuelChallengeSentTitle => 'تم إرسال التحدي';

  @override
  String hilalDuelChallengeSentBody(String name) {
    return 'ستظهر النتيجة عندما يجيب $name.';
  }

  @override
  String get hilalDuelChallengeSentOk => 'حسناً';

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
      'تستخدم Arin خدمات Firebase (Authentication وFirestore) لتسجيل الدخول والإشعارات والمزامنة، وFirebase Analytics/Crashlytics للتحليلات وتشخيص الأعطال، وGoogle AdMob للإعلانات، وRevenueCat للتحقق من الاشتراكات وعمليات الشراء داخل التطبيق، وواجهات Aladhan/Diyanet لمواقيت الصلاة. تُرسل رسائل مساعد أرِن في البريميوم إلى Google Gemini ولا يُحفظ نص المحادثة في التطبيق. في الطبقة المجانية من Gemini قد يُستخدم هذا المحتوى لتحسين منتجات Google.';

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
  String get notificationsBatteryRationaleTitle =>
      'لماذا نحتاج إعفاء البطارية؟';

  @override
  String get notificationsBatteryRationaleBody =>
      'تحتاج تذكيرات مواقيت الصلاة والتزكية إلى إعفاء من تحسين البطارية حتى تصل في الوقت المحدد بالضبط، حتى عندما يكون الهاتف في وضع السكون (Doze). يؤثر هذا الإذن فقط على الإشعارات المجدولة ولا يعمل في الخلفية باستمرار.';

  @override
  String get notificationsBatteryRationaleConfirm => 'السماح';

  @override
  String get notificationsBatteryRationaleCancel => 'ليس الآن';

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
      'عتبات التزكية ونسب التعافي والتحفيز الشهري ونصائح أو إلهام من حين لآخر.';

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
  String get adminPoolLabelNotificationNamazWisdom => 'اقتباسات إشعار الصلاة';

  @override
  String get adminPoolLabelNotificationDailyNamazReminder =>
      'نصوص تذكير الصلاة اليومي';

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
  String get onboardingStart => 'ابدأ';

  @override
  String get onboardingWelcomeTitle => 'مرحباً.';

  @override
  String get onboardingWelcomeBody =>
      'لتكن الآيات والأدعية وتذكيرات الصلاة معك طوال اليوم.';

  @override
  String get onboardingLandingVerseArabic => 'قَدْ أَفْلَحَ مَن زَكَّاهَا';

  @override
  String get onboardingLandingVerseTranslation => 'قد أفلح من زكّاها.';

  @override
  String get onboardingLandingVerseSource => 'الشمس ٩';

  @override
  String get onboardingWelcomeWidgetVerseArabic =>
      'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ';

  @override
  String get onboardingWelcomeWidgetVerseTranslation =>
      'ألا بذكر الله تطمئن القلوب.';

  @override
  String get onboardingWelcomeWidgetVerseSource => 'الرعد ١٣:٢٨';

  @override
  String get onboardingLanguagePickerTitle => 'اللغة';

  @override
  String get onboardingContinue => 'متابعة';

  @override
  String get onboardingStoryBody =>
      'خذ نفساً هادئاً فقط.\n\nستكون أرن معك خلال اليوم بتذكيرات قصيرة من القرآن.\n\nوسيستقبلك توقفٌ قصير مع آية في كل مرة تفتح فيها هاتفك.\n\nإن كنت جاهزاً فلنبدأ.';

  @override
  String get onboardingNameSubtitle =>
      'لتشعر نصوص الآيات والتذكيرات بمزيد من القرب.';

  @override
  String get onboardingNameHint => 'اسمك';

  @override
  String onboardingGreetingTitle(String name) {
    return 'سعدت بلقائك، $name.';
  }

  @override
  String get onboardingGreetingBody =>
      'تنزيلك هذا التطبيق اليوم ليس صدفة.\n\nستكون أرن بعد اليوم إلى جانبك: آية، ووقت صلاة، وتذكير.\n\nدعنا نتعرف عليك قليلاً. أجب بما يأتي من داخلك.';

  @override
  String onboardingIntentTitle(String name) {
    return '$name، ما الذي جاء بك إلى هنا؟';
  }

  @override
  String get onboardingIntentSubtitle => 'سنقرّب التذكيرات وفق هذه النية.';

  @override
  String get onboardingIntentLock => 'رؤية آية على شاشة القفل';

  @override
  String get onboardingIntentFaith => 'تجديد إيماني';

  @override
  String get onboardingIntentCalm => 'تسكين قلبي';

  @override
  String get onboardingIntentDaily => 'بدء اليوم بآية';

  @override
  String get onboardingIntentPrayer => 'ألا تفوتني أوقات الصلاة';

  @override
  String onboardingHeartTitle(String name) {
    return '$name، كيف تشعر بقربك من الله اليوم؟';
  }

  @override
  String get onboardingHeartHint => 'المس القلب أو اسحبه.';

  @override
  String get onboardingHeartLabelFar => 'أشعر بالبعد';

  @override
  String get onboardingHeartLabelSeeking => 'أبحث عن الطريق';

  @override
  String get onboardingHeartLabelHolding => 'أحفظ الصلة';

  @override
  String get onboardingHeartLabelNear => 'أقف قريباً';

  @override
  String get onboardingHeartLabelFull => 'قلبي ممتلئ';

  @override
  String get onboardingHoldVerseArabic =>
      'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ';

  @override
  String get onboardingHoldVerseTranslation => 'وإذا سألك عبادي عني فإني قريب.';

  @override
  String get onboardingHoldVerseSource => 'البقرة ١٨٦';

  @override
  String onboardingHoldFooter(String name) {
    return '$name، هذا مجرد بداية...';
  }

  @override
  String onboardingStruggleTitle(String name) {
    return '$name، ما أثقل ما يرهق قلبك الآن؟';
  }

  @override
  String get onboardingStruggleSubtitle => 'سنلطّف التذكيرات وفق هذا الثقل.';

  @override
  String get onboardingStruggleAnxiety => 'القلق';

  @override
  String get onboardingStruggleDelay => 'التسويف';

  @override
  String get onboardingStruggleLonely => 'الوحدة';

  @override
  String get onboardingStruggleImpatience => 'قلة الصبر';

  @override
  String get onboardingStruggleRegret => 'الندم';

  @override
  String get onboardingNoteSubtitle =>
      'جملة قصيرة تكفي. هذا الجواب تراه أنت فقط.';

  @override
  String onboardingNoteTitleAnxiety(String name) {
    return '$name، هل تريد أن تضع شيئاً عن قلقك في كلمات؟';
  }

  @override
  String onboardingNoteTitleDelay(String name) {
    return '$name، هل هناك أمر تؤجّله مراراً؟';
  }

  @override
  String onboardingNoteTitleLonely(String name) {
    return '$name، هل تريد أن تضع شيئاً عن وحدتك في كلمات؟';
  }

  @override
  String onboardingNoteTitleImpatience(String name) {
    return '$name، هل تريد أن تضع شيئاً عن قلة صبرك في كلمات؟';
  }

  @override
  String onboardingNoteTitleRegret(String name) {
    return '$name، هل تريد أن تضع شيئاً عن ندمك في كلمات؟';
  }

  @override
  String get onboardingNoteHintAnxiety =>
      'مثال: قلق المستقبل يمنع نومي في الليل.';

  @override
  String get onboardingNoteHintDelay =>
      'مثال: أؤجّل العمل الذي نويتُه إلى الغد مرة أخرى.';

  @override
  String get onboardingNoteHintLonely =>
      'مثال: حتى في الزحام أشعر بفراغ في داخلي.';

  @override
  String get onboardingNoteHintImpatience => 'مثال: حين تبطئ الأمور يضيق صدري.';

  @override
  String get onboardingNoteHintRegret =>
      'مثال: كلمة من الماضي ما زالت في قلبي.';

  @override
  String get onboardingNoteSuggestionAnxiety =>
      'أريد أن أترك قلقي عند الله وأُسكن قلبي.';

  @override
  String get onboardingNoteSuggestionDelay =>
      'أريد أن أؤدي ما نويتُه دون تأجيل.';

  @override
  String get onboardingNoteSuggestionLonely =>
      'أريد أن أذكر أن ربي معي حتى حين أكون وحدي.';

  @override
  String get onboardingNoteSuggestionImpatience =>
      'أريد أن أمشي بصبر من غير عجلة.';

  @override
  String get onboardingNoteSuggestionRegret => 'أريد أن أضع ندمي بالتوبة.';

  @override
  String get onboardingHeardTitle => 'سمعناك.';

  @override
  String get onboardingHeardVerse => 'إن مع العسر يسراً.';

  @override
  String get onboardingHeardSource => '— الشرح، ٩٤:٦';

  @override
  String onboardingToneTitle(String name) {
    return '$name، كم يبدو قلبك متعباً في هذه الأيام؟';
  }

  @override
  String get onboardingToneSubtitle => 'أفرغ ما في قلبك.';

  @override
  String get onboardingToneCalm => 'هادئ';

  @override
  String get onboardingToneLight => 'خفيف';

  @override
  String get onboardingToneMid => 'متوسط';

  @override
  String get onboardingToneHeavy => 'ثقيل';

  @override
  String get onboardingToneVeryHeavy => 'ثقيل جداً';

  @override
  String onboardingToneValue(int value) {
    return '$value / 5';
  }

  @override
  String onboardingTurnTitle(String name) {
    return '$name، حين تمرّ أيام عسيرة...';
  }

  @override
  String get onboardingTurnSubtitle => 'هل تتوجه إلى الله؟';

  @override
  String get onboardingTurnAlways => 'في كل ضيق أعود إليه';

  @override
  String get onboardingTurnSometimes => 'أتوجه أحياناً';

  @override
  String get onboardingTurnRarely => 'نادراً، لكنّي أريد المزيد';

  @override
  String get onboardingTurnStarting => 'أنا جديد على هذا الطريق';

  @override
  String get onboardingShapeTitle => 'ننسج هذا وفق قلبك';

  @override
  String get onboardingShapeSubtitle =>
      'ليس مزيداً من الشاشات؛ بل وقفة قصيرة في الوقت المناسب.';

  @override
  String get onboardingShapeCard1Title => 'آيات قريبة منك';

  @override
  String get onboardingShapeCard1Body => 'يظهر المحتوى وفق الثقل الذي اخترته.';

  @override
  String get onboardingShapeCard2Title => 'تذكير لطيف';

  @override
  String get onboardingShapeCard2Body =>
      'يبقى اللسان هادئاً وقصيراً ومتجهاً إلى القلب.';

  @override
  String get onboardingShapeCard3Title => 'حول القرآن';

  @override
  String get onboardingShapeCard3Body =>
      'يسير اليوم مع الآية والذكر على خط واحد.';

  @override
  String onboardingPrayerTitle(String name) {
    return '$name، كيف تصف إيقاع صلاتك ودعائك؟';
  }

  @override
  String get onboardingPrayerSubtitle => 'لنختر إيقاعاً يناسبك في البداية.';

  @override
  String get onboardingPrayerRegular => 'أحفظ نظمي';

  @override
  String get onboardingPrayerOccasional => 'أوفّق أحياناً';

  @override
  String get onboardingPrayerStruggling => 'أتعثر حين أنقطع';

  @override
  String get onboardingPrayerStarting => 'ما زلت أتدرّب';

  @override
  String get onboardingPrayerBeginHere => 'أريد أن أبدأ من هذه الشاشة';

  @override
  String onboardingWaswasaTitle(String name) {
    return '$name، ماذا تفعل حين يأتيك الشك أو الوسوسة؟';
  }

  @override
  String get onboardingWaswasaSubtitle => 'هذا الجواب يحدّد كيف نقف إلى جانبك.';

  @override
  String get onboardingWaswasaPray => 'أقابلها بالدعاء';

  @override
  String get onboardingWaswasaRead => 'أقرأ وأحاول أن أفهم';

  @override
  String get onboardingWaswasaAsk => 'أفتحها لمن أثق به';

  @override
  String get onboardingWaswasaCarry => 'أحملها بهدوء في داخلي';

  @override
  String get onboardingPathVerseArabic =>
      'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ';

  @override
  String get onboardingPathVerseTranslation => 'ومن يتوكل على الله فهو حسبه.';

  @override
  String get onboardingPathVerseSource => 'الطلاق ٦٥:٣';

  @override
  String onboardingPathVerseFooter(String name) {
    return '$name، ليقرّ القرآن في قلبك.';
  }

  @override
  String get onboardingPathTitle => 'خطّ يومك بدأ يظهر';

  @override
  String get onboardingPathSubtitle =>
      'سنجمع إيقاعك وحال قلبك ونيّتك في يوم واحد بسيط.';

  @override
  String get onboardingPathCard1Title => 'حاجتك أولاً';

  @override
  String get onboardingPathCard1Body =>
      'الآيات التي تناسبك تبقى في رأس القائمة.';

  @override
  String get onboardingPathCard2Title => 'إيقاعك أنت';

  @override
  String get onboardingPathCard2Body => 'يتنفّس التدفق وفق قراءتك الحقيقية.';

  @override
  String get onboardingPathCard3Title => 'أمام عينيك';

  @override
  String get onboardingPathCard3Body =>
      'تصبح شاشة القفل وقفة قصيرة في أثناء اليوم.';

  @override
  String get onboardingFirstStepTitle => 'هل تريد أن تخطو الخطوة الأولى الآن؟';

  @override
  String get onboardingFirstStepSubtitle =>
      'ظهر الطريق. إن شئت عقدنا اليوم نيّة لترك شيء أو لبناء شيء. وإن لم ترد فيُقام لاحقاً؛ والطريق لا يُغلق.';

  @override
  String get onboardingFirstStepArinmaTitle => 'التطهر';

  @override
  String get onboardingFirstStepArinmaBody =>
      'أقِم متابعة لترك عادة تثقل القلب.';

  @override
  String get onboardingFirstStepGelisimTitle => 'النمو';

  @override
  String get onboardingFirstStepGelisimBody =>
      'ضع الصلاة أو القضاء أو روتيناً يومياً على الطريق من اليوم.';

  @override
  String get onboardingFirstStepLater => 'الإعداد لاحقاً';

  @override
  String get onboardingRhythmTitle => 'أرِن يستقر بهدوء في يومك';

  @override
  String get onboardingRhythmSubtitle =>
      'ليس الهدف وقتاً أطول على الشاشة؛ بل تذكيراً قصيراً في الوقت المناسب. وسنطلب إذن الإشعارات لهذا.';

  @override
  String get onboardingRhythmFeaturedTitle => 'تذكير آية اليوم';

  @override
  String get onboardingRhythmFeaturedBody =>
      'عند المتابعة سنطلب إذن الإشعارات. يمكنك تغيير الساعات والإيقاع من الإعدادات متى شئت.';

  @override
  String get onboardingRhythmCard1Title => 'وقفة قصيرة';

  @override
  String get onboardingRhythmCard1Body =>
      'تظهر الآيات بهدوء واختصار في أثناء اليوم.';

  @override
  String get onboardingRhythmCard2Title => 'نفس على شاشة القفل';

  @override
  String get onboardingRhythmCard2Body =>
      'كل نظرة إلى الهاتف تُبقي تذكيراً صغيراً.';

  @override
  String get onboardingRhythmCard3Title => 'البقاء على الخط نفسه';

  @override
  String get onboardingRhythmCard3Body =>
      'الصلاة والذكر والتفكّر يتبع بعضها بعضاً.';

  @override
  String get onboardingLocationTitle => 'الموقع لأوقات الصلاة';

  @override
  String get onboardingLocationSubtitle =>
      'نطلب موقعك بلطف حتى نعرض الإمساك والظهر والمغرب وفق مدينتك. يُستخدم الموقع فقط لأوقات الصلاة والقبلة.';

  @override
  String get onboardingLocationFeaturedTitle => 'الأوقات بحسب مكانك';

  @override
  String get onboardingLocationFeaturedBody =>
      'عند المتابعة سنطلب إذن الموقع. يمكنك تغييره لاحقاً من الإعدادات.';

  @override
  String get onboardingLocationCard1Title => 'أوقات الصلاة';

  @override
  String get onboardingLocationCard1Body =>
      'تبقى الأوقات اليومية متجددة لمدينتك.';

  @override
  String get onboardingLocationCard2Title => 'اتجاه القبلة';

  @override
  String get onboardingLocationCard2Body => 'الإذن نفسه يكفي لحساب الاتجاه.';

  @override
  String get onboardingLocationCard3Title => 'يبقى عندك';

  @override
  String get onboardingLocationCard3Body => 'لا يُشارك موقعك لأي غرض آخر.';

  @override
  String get onboardingPrepareTitle => 'يتم إعداد الإعدادات الأخيرة';

  @override
  String get onboardingPrepareSubtitle => 'كل قسم يُجهَّز واحداً تلو الآخر.';

  @override
  String get onboardingPrepareReadyTitle => 'تجربتك جاهزة';

  @override
  String get onboardingPrepareReadySubtitle =>
      'في الخطوة الأخيرة ستقول آمين على دعاء قصير.';

  @override
  String get onboardingPrepareStatus => 'جارٍ التحضير';

  @override
  String get onboardingPrepareYes => 'نعم';

  @override
  String get onboardingPrepareNo => 'لا';

  @override
  String onboardingPrepareBar1Title(String name) {
    return '$name، يُنسج مسار آياتك';
  }

  @override
  String get onboardingPrepareBar1Body => 'يُختار اللسان والتأكيد وفق إجاباتك.';

  @override
  String get onboardingPrepareBar2Title => 'يتم إعداد مظهر شاشة القفل';

  @override
  String get onboardingPrepareBar2Body => 'يبقى الوقت والآية بسيطين.';

  @override
  String get onboardingPrepareBar3Title => 'يُضبط للوصول إلى المزيد من الناس';

  @override
  String get onboardingPrepareBar3Body => 'تُقاس مصادر الاكتشاف بخصوصية.';

  @override
  String get onboardingPrepareBar4Title => 'تُوضع الاختصارات';

  @override
  String get onboardingPrepareBar4Body =>
      'يُجهَّز التسبيح والقبلة والصلاة والمحادثة.';

  @override
  String get onboardingPrepareAskLock =>
      'هل نستخدم عرضاً بسيطاً للآية على شاشة القفل؟';

  @override
  String get onboardingPrepareAskVerses => 'هل نقدّم الآيات وفق إجاباتك؟';

  @override
  String get onboardingPrepareAskShortcuts =>
      'هل نبرز اختصارات العبادة في المسار الرئيسي؟';

  @override
  String get onboardingDuaTitle => 'دعاء قصير';

  @override
  String onboardingDuaBody(String name) {
    return 'اللهم ارزق عبدك $name خيراً وبركة وصحة وسكينة وحكمة واستقامة. أحيِ قلبه بالقرآن وثبّت خطاه في الخير. ولتكن كلمتك قريبة منه في كل حين.';
  }

  @override
  String get onboardingDuaVerseArabic =>
      'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً';

  @override
  String get onboardingDuaVerseTranslation =>
      'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة.';

  @override
  String get onboardingDuaVerseSource => 'البقرة ٢:٢٠١';

  @override
  String get onboardingDuaAmin => 'آمين.';

  @override
  String get onboardingDuaHoldHint => 'اضغط مع الاستمرار';

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
  String get surveyNotificationAllow => 'تفعيل الإشعارات';

  @override
  String get surveyNotificationSkip => 'تخطي الآن';

  @override
  String get surveyNotificationOpenSettings => 'فتح الإعدادات';

  @override
  String get surveyLockWidgetsTitle => 'شاشة القفل';

  @override
  String get surveyLockWidgetsLead =>
      'هل تريد أوقات الصلاة وكلمة اليوم على شاشة القفل؟';

  @override
  String get surveyLockWidgetsSubtitle =>
      'أضف أولاً ودجة عادية إلى الشاشة الرئيسية. إن تعذّر ذلك أو أردتها أيضًا على شاشة القفل، تبقى اختياراتك كإشعار نظام. يمكنك تغييرها لاحقًا من مركز الودجات.';

  @override
  String get surveyLockWidgetsPrayerTitle => 'وقت الصلاة';

  @override
  String get surveyLockWidgetsPrayerSubtitle =>
      'يعرض الوقت التالي والعد التنازلي على شاشة القفل.';

  @override
  String get surveyLockWidgetsQuoteTitle => 'كلمة اليوم';

  @override
  String get surveyLockWidgetsQuoteSubtitle =>
      'يعرض كلمة اليوم على شاشة القفل.';

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
  String get premiumLegalPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get premiumLegalTermsOfUse => 'شروط الاستخدام';

  @override
  String get premiumLinkOpenFailed =>
      'تعذر فتح الرابط. يرجى المحاولة مرة أخرى.';

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

  @override
  String get offlineBannerOffline => 'أنت غير متصل بالإنترنت';

  @override
  String get offlineBannerReconnected => 'تمت إعادة الاتصال';

  @override
  String get premiumRestorePurchasesLabel => 'استعادة المشتريات';

  @override
  String get premiumActivePlanLabel => 'الخطة الفعالة';

  @override
  String get premiumPlanMonthlyLaunch => 'ابدأ بسعر الإطلاق';

  @override
  String get premiumPlanYearlySwitch => 'التبديل إلى السنوي';

  @override
  String get premiumFeatureNoAds => 'استخدام بدون إعلانات';

  @override
  String get premiumFeatureWidgets => 'بدون أقفال للأدوات (Widgets)';

  @override
  String get premiumFeatureReels => 'تصفح مستمر بدون انقطاع';

  @override
  String get premiumFeatureSecondAlarm => 'تمكين التنبيه الثاني للأذان';

  @override
  String get premiumFeatureExtras => 'بدون إعلانات في الذكر والبوصلة والترددات';

  @override
  String get premiumSignInRequired =>
      'تسجيل الدخول غير مطلوب للشراء. يمكنك استخدام Premium على هذا الجهاز فورًا، ويمكنك ربط حسابك لاحقًا لاستخدامه على الأجهزة الأخرى.';

  @override
  String get premiumSignInTitle => 'تسجيل الدخول للاشتراك';

  @override
  String get premiumSignInSubtitle =>
      'يُربط الاشتراك المميز بحسابك حتى لا تفقده عند تغيير الجهاز. لا يتطلب تسجيل الدخول لعرض الأسعار.';

  @override
  String get premiumSignInGoogle => 'المتابعة مع جوجل';

  @override
  String get premiumSignInApple => 'المتابعة مع آبل';

  @override
  String get premiumSignInCancel => 'ليس الآن';

  @override
  String get locationPermissionRequiredTitle => 'إذن الموقع مطلوب';

  @override
  String get locationPermissionRequiredBody =>
      'يتطلب أرين الوصول إلى موقعك لحساب أوقات الصلاة واتجاه القبلة بدقة. تُستخدم بيانات موقعك لهذه الأغراض فقط وتتم معالجتها على جهازك.';

  @override
  String get locationPermissionNotNow => 'ليس الآن';

  @override
  String get locationPermissionContinue => 'متابعة';

  @override
  String get errorScreenTitle => 'حدث خطأ ما';

  @override
  String get errorScreenBody =>
      'لا يمكن فتح هذا القسم في الوقت الحالي. يمكنك محاولة إغلاق التطبيق وإعادة فتحه.';

  @override
  String get errorScreenDebugTitle => 'أرين - خطأ في الأداة (تصحيح)';

  @override
  String get errorScreenDebugBody => 'أنت في وضع التصحيح. انسخ النص أدناه.';

  @override
  String get widgetUnlockQuoteTitle => 'أداة الاقتباس اليومي';

  @override
  String get widgetUnlockPrayerTitle => 'أداة وقت الصلاة';

  @override
  String get widgetUnlockComboTitle => 'أداة الاقتباس + الصلاة';

  @override
  String get widgetUnlockTrackingTitle => 'أداة التتبع';

  @override
  String get widgetUnlockZikirTitle => 'أداة المسبحة';

  @override
  String get widgetUnlockAdPreparing => 'جارٍ تجهيز الإعلان…';

  @override
  String get widgetUnlockAdLoadFailed =>
      'لا يتوفر إعلان مناسب الآن. يرجى المحاولة مرة أخرى بعد بضع ثوانٍ.';

  @override
  String get widgetUnlockAdRetryButton => 'حاول مجددًا';

  @override
  String get widgetUnlockAdLaterButton => 'لاحقًا';

  @override
  String widgetUnlockSuccessTitle(Object title, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'تم فتح $title لمدة $hours ساعة! 🎉',
      few: 'تم فتح $title لمدة $hours ساعات! 🎉',
      two: 'تم فتح $title لمدة ساعتين! 🎉',
      one: 'تم فتح $title لمدة ساعة واحدة! 🎉',
    );
    return '$_temp0';
  }

  @override
  String get widgetUnlockPremiumSuccess =>
      'النسخة المميزة نشطة! تم فتح جميع الأدوات. 🎉';

  @override
  String widgetUnlockDescription(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other:
          'يمكنك مشاهدة إعلان قصير لفتح هذه الأداة لمدة $hours ساعة. قم بالترقية إلى النسخة المميزة للوصول الدائم.',
      few:
          'يمكنك مشاهدة إعلان قصير لفتح هذه الأداة لمدة $hours ساعات. قم بالترقية إلى النسخة المميزة للوصول الدائم.',
      two:
          'يمكنك مشاهدة إعلان قصير لفتح هذه الأداة لمدة ساعتين. قم بالترقية إلى النسخة المميزة للوصول الدائم.',
      one:
          'يمكنك مشاهدة إعلان قصير لفتح هذه الأداة لمدة ساعة واحدة. قم بالترقية إلى النسخة المميزة للوصول الدائم.',
    );
    return '$_temp0';
  }

  @override
  String widgetUnlockAdButton(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'مشاهدة إعلان — الفتح لمدة $hours ساعة',
      few: 'مشاهدة إعلان — الفتح لمدة $hours ساعات',
      two: 'مشاهدة إعلان — الفتح لمدة ساعتين',
      one: 'مشاهدة إعلان — الفتح لمدة ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get widgetUnlockPremiumButton => 'الترقية إلى النسخة المميزة';

  @override
  String get widgetUnlockCancelButton => 'ليس الآن';

  @override
  String get purchaseErrorLegacyPlan =>
      'هذه الخطة لم تعد تُباع. يبقى سعر المشتركين الحاليين كما هو.';

  @override
  String get purchaseErrorNotFound =>
      'لم يتم العثور على المنتج. يرجى التحقق من اتصالك بالإنترنت.';

  @override
  String purchaseErrorUnexpected(Object error) {
    return 'خطأ غير متوقع: $error';
  }

  @override
  String get purchaseErrorNotSupported => 'الشراء غير مدعوم على هذه المنصة.';

  @override
  String get audioPermissionRequiredTitle => 'مطلوب إذن الوسائط';

  @override
  String get audioPermissionRequiredBody =>
      'يتطلب أرين الوصول إلى ملفات الصوت الخاصة بك حتى تتمكن من اختيار أذان مخصص أو صوت إشعار من جهازك. تُستخدم هذه الملفات كإشعارات داخل التطبيق فقط.';

  @override
  String get audioPickerTitle => 'اختر ملف صوتي';

  @override
  String get mgmtDailyPrayers => 'الصلوات اليومية';

  @override
  String get mgmtRoutineWorkshop => 'ورشة الروتين';

  @override
  String get mgmtChooseGrowth => 'اختر التطوير';

  @override
  String get mgmtPickPrayerOrMakeup =>
      'اختر تتبع الصلاة أو القضاء؛ واستخدم القسم أدناه لروتين تطوير مخصص.';

  @override
  String get mgmtCountingAndCompensation => 'العدّ والتدارك';

  @override
  String get mgmtPrayer => 'الصلاة';

  @override
  String get mgmtTimeAndKhushu => 'الوقت والخشوع';

  @override
  String get mgmtCustomRoutine => 'روتين مخصص';

  @override
  String get mgmtChooseYourOwnTitle =>
      'حدد العنوان والرمز التفاعلي والتذكير بنفسك.';

  @override
  String get mgmtSelect => 'اختر';

  @override
  String get habitsMyHabits => 'عاداتي';

  @override
  String get habitsNoHabitsYet =>
      'لم تضف أي عادة بعد.\nهل أنت مستعد لبداية جديدة؟';

  @override
  String get habitsGrowth => 'التطوير';

  @override
  String get habitsPurification => 'التزكية';

  @override
  String get habitsAddPurificationGoal => 'أضف هدف تزكية';

  @override
  String get habitsAddGrowthRoutine => 'أضف روتين تطوير';

  @override
  String get habitsDeleteConfirmTitle => 'هل تريد حذف هذه العادة؟';

  @override
  String get habitsCancel => 'إلغاء';

  @override
  String get habitsYesDelete => 'نعم، احذف';

  @override
  String get habitsDayStreak => 'سلسلة أيام';

  @override
  String get customHabitThisWeekGoal => 'هدف هذا الأسبوع';

  @override
  String get customHabitThisMonthGoal => 'هدف هذا الشهر';

  @override
  String get customHabitDailyGoal => 'الهدف اليومي';

  @override
  String get customHabitThisWeekGoalComplete => 'اكتمل هدف هذا الأسبوع.';

  @override
  String get customHabitThisMonthGoalComplete => 'اكتمل هدف هذا الشهر.';

  @override
  String get customHabitTodayGoalComplete => 'اكتمل هدف اليوم.';

  @override
  String get customHabitLetsStart => 'هيا ابدأ!';

  @override
  String get customHabitDoingWell => 'أنت تسير بشكل جيد.';

  @override
  String get customHabitAlmostThere => 'أوشكت.';

  @override
  String get customHabitOneLastStep => 'خطوة أخيرة.';

  @override
  String get customHabitRecordNotFound => 'لم يتم العثور على السجل';

  @override
  String get customHabitStreak => 'سلسلة';

  @override
  String get customHabitDayStreak => 'سلسلة أيام';

  @override
  String get customHabitBack => 'رجوع';

  @override
  String get customHabitRemove => 'إزالة';

  @override
  String get customHabitBackToTracker => 'العودة لمتابعة العادات';

  @override
  String get customHabitGoal => 'الهدف';

  @override
  String get customHabitCompletedToday => 'أكملت هدف اليوم.';

  @override
  String get customHabitCompletedPeriod => 'أكملت هدف هذه الفترة.';

  @override
  String get customHabitFinish => 'إنهاء';

  @override
  String get addHabitUnitTimes => 'مرات';

  @override
  String get addHabitUnitMinutes => 'دقائق';

  @override
  String get addHabitUnitHours => 'ساعات';

  @override
  String get addHabitUnitPages => 'صفحات';

  @override
  String get addHabitUnitGlasses => 'أكواب';

  @override
  String get addHabitUnitSets => 'مجموعات';

  @override
  String get addHabitUnitLaps => 'دورات';

  @override
  String get addHabitDaily => 'يومي';

  @override
  String get addHabitWeekly => 'أسبوعي';

  @override
  String get addHabitMonthly => 'شهري';

  @override
  String addHabitSummaryWeekly(Object amount, Object unit) {
    return '$amount $unit أسبوعي';
  }

  @override
  String addHabitSummaryMonthly(Object amount, Object unit) {
    return '$amount $unit شهري';
  }

  @override
  String addHabitSummaryDaily(Object amount, Object unit) {
    return '$amount $unit يومي';
  }

  @override
  String get addHabitCancel => 'إلغاء';

  @override
  String get addHabitOk => 'حسناً';

  @override
  String get addHabitCustom => 'مخصص';

  @override
  String get addHabitSave => 'حفظ';

  @override
  String get addHabitGrowthName => 'اسم التطوير';

  @override
  String get addHabitPurificationName => 'اسم التزكية';

  @override
  String get addHabitGrowthHint => 'مثال: قراءة كتاب لمدة 30 دقيقة';

  @override
  String get addHabitPurificationHint => 'مثال: تقليل وقت الشاشة غير الضروري';

  @override
  String get addHabitNameRequired => 'الاسم مطلوب';

  @override
  String get addHabitNameTooLong => 'الحد الأقصى 60 حرفاً';

  @override
  String get addHabitNoteOptional => 'ملاحظة (اختياري)';

  @override
  String get addHabitNoteHint => 'ملاحظة قصيرة لنفسك...';

  @override
  String habitCalendarToday(Object date) {
    return 'اليوم: $date';
  }

  @override
  String get habitCalendarTitle => 'تقويم العادات';

  @override
  String get habitCalendarMonth => 'شهر';

  @override
  String habitCalendarMonthNote(Object month, Object year) {
    return 'ملاحظة الشهر · $month $year';
  }

  @override
  String get habitCalendarNoRecords =>
      'لا توجد سجلات لهذا الشهر بعد أو لم تتم إضافة عادات.';

  @override
  String habitCalendarQuitInsight(Object n, Object title) {
    return '“$title”: $n أيام عداد التزكية في التقويم هذا الشهر (منذ البداية).';
  }

  @override
  String habitCalendarPrayerInsight(
    Object anyPrayer,
    Object fullFive,
    Object title,
  ) {
    return '“$title”: تم وضع علامة على صلاة واحدة على الأقل في $anyPrayer يوماً؛ اكتمل 5/5 في $fullFive يوماً.';
  }

  @override
  String habitCalendarCustomInsightPeriod(
    Object n,
    Object periodLabel,
    Object title,
  ) {
    return '“$title”: تم الوصول إلى هدف $n $periodLabel هذا الشهر.';
  }

  @override
  String get habitCalendarWeekLabel => 'أسبوع';

  @override
  String get habitCalendarMonthLabel => 'شهر';

  @override
  String habitCalendarCustomInsightDays(Object completedDays, Object title) {
    return '“$title”: تم وضع علامة مكتمل على $completedDays يوماً إجمالاً هذا الشهر.';
  }

  @override
  String get habitCalendarLegend =>
      'الرموز الرمادية في الخلايا: تعني وجود سجل لذلك اليوم. يوضح رمز التزكية تحديداً الأيام التي كان فيها العداد نشطاً؛ رموز الصلاة/الروتين تظهر السجلات المكتملة لليوم المعني.';

  @override
  String get kazaPrayerFajr => 'صلاة الفجر';

  @override
  String get kazaPrayerDhuhr => 'صلاة الظهر';

  @override
  String get kazaPrayerAsr => 'صلاة العصر';

  @override
  String get kazaPrayerMaghrib => 'صلاة المغرب';

  @override
  String get kazaPrayerIsha => 'صلاة العشاء';

  @override
  String get kazaPrayerWitr => 'صلاة الوتر';

  @override
  String get kazaReset => 'إعادة تعيين';

  @override
  String get kazaResetConfirmDesc =>
      'سيتم إعادة تعيين جميع أعداد قضاء الصلوات. هل أنت متأكد؟';

  @override
  String get kazaCancel => 'إلغاء';

  @override
  String get kazaTrackerTitle => 'تتبع القضاء';

  @override
  String get kazaClose => 'إغلاق';

  @override
  String get kazaTrackerSubtitle => 'تتبع قضاء الصلوات';

  @override
  String get kazaTrackerDesc =>
      'احرص على أداء صلوات القضاء بعد الصلوات اليومية. يمكنك إضافة دين بـ (+) وتقليل العداد بـ (−) لكل صلاة تؤديها.';

  @override
  String get kazaCalcBirthDate => 'تاريخ الميلاد';

  @override
  String get kazaCalcApply => 'تطبيق';

  @override
  String get kazaCalcUpdateCounters => 'تحديث العدادات؟';

  @override
  String get kazaCalcUpdateDesc =>
      'سيتم حذف أعداد صلوات القضاء الحالية واستبدالها بالقيم المحسوبة.';

  @override
  String get kazaCalcCancel => 'إلغاء';

  @override
  String get kazaCalcContinue => 'متابعة';

  @override
  String get kazaCalcErrorPubertyFuture =>
      'لا يمكن أن يكون تاريخ البلوغ بعد اليوم. تحقق من تاريخ الميلاد أو سن البلوغ.';

  @override
  String get kazaCalcErrorZeroRemaining =>
      'الصلوات المتبقية 0: إذا كانت الأيام المصلّاة بالكامل تساوي أو تتجاوز الأيام الملزم بها، يتم تقييدها؛ وتبقى عدادات الصلوات الـ 6 صفراً بناءً على ذلك.';

  @override
  String get kazaCalcTitle => 'تتبع القضاء';

  @override
  String get kazaCalcSubtitle => 'تتبع قضاء الصلوات';

  @override
  String get kazaCalcDesc =>
      'الصلوات المفروضة تبدأ من سن البلوغ. إذا كنت لا تعرف العمر الدقيق، يمكنك الرجوع إلى 12 للذكور و 9 للإناث كمرجع. تنتج هذه الشاشة عدداً تقديرياً؛ استمر في أداء صلوات القضاء بعد الصلوات المنتظمة.';

  @override
  String get kazaCalcFemaleNote =>
      'للإناث: يُعفى تقريباً 6 أيام من الصلاة لكل شهر تقويمي مضى منذ البلوغ (لا يتجاوز إجمالي الأيام).';

  @override
  String get kazaCalcFormula =>
      'المعادلة: الأيام الملزم بها = أيام التقويم − إعفاء الحيض؛ إجمالي الصلوات = الأيام الملزم بها × 6 − (الأيام المصلّاة بالكامل × 6). لا يمكن أن تتجاوز الأيام المصلّاة الأيام الملزم بها.';

  @override
  String get kazaCalcCalculateTitle => 'حساب صلوات القضاء';

  @override
  String get kazaCalcGender => 'جنسك';

  @override
  String get kazaCalcMale => 'ذكر';

  @override
  String get kazaCalcFemale => 'أنثى';

  @override
  String get kazaCalcBirthDateTitle => 'تاريخ ميلادك';

  @override
  String get kazaCalcPubertyAge => 'عمر بلوغك';

  @override
  String kazaCalcPubertyNote(Object minPuberty) {
    return 'الحد الأدنى: ذكر 12، أنثى 9 سنوات (إذا تم إدخال رقم أصغر، يتم استخدام $minPuberty في الحساب).';
  }

  @override
  String get kazaCalcPrayedDays => 'كم يوماً صليت؟';

  @override
  String get kazaCalcPrayedDaysNote =>
      'إجمالي عدد الأيام حتى الآن التي أديت فيها جميع الصلوات خلال اليوم.';

  @override
  String get kazaCalcCalculate => 'حساب';

  @override
  String get kazaCalcLiveError =>
      'لا يمكن أن يكون تاريخ البلوغ بعد اليوم؛ تحقق من تاريخ الميلاد وعمر البلوغ.';

  @override
  String kazaCalcLiveHayiz(Object days) {
    return 'إعفاء الحيض: −$days أيام\n';
  }

  @override
  String kazaCalcLiveApplied(Object applied) {
    return '\n(الحد الأقصى للأيام المصلّاة بالكامل: $applied)';
  }

  @override
  String get kazaCalcLiveSummary => 'ملخص مباشر';

  @override
  String kazaCalcLiveCalendarDays(Object days) {
    return 'أيام التقويم: $days\n';
  }

  @override
  String kazaCalcLiveLiableDays(Object days) {
    return 'الأيام الملزم بها: $days\n';
  }

  @override
  String kazaCalcLiveOwed(Object perDay, Object total) {
    return 'دين الصلاة (الأيام الملزم بها × $perDay): $total\n';
  }

  @override
  String kazaCalcLiveCredited(
    Object appliedNote,
    Object credited,
    Object perDay,
  ) {
    return 'المخصوم (أيام كاملة × $perDay): $credited$appliedNote\n';
  }

  @override
  String kazaCalcLiveRemaining(Object remaining) {
    return '—\nالإجمالي المتبقي: $remaining صلوات';
  }

  @override
  String get kazaCalcLiveZeroNote =>
      'عداد ما بعد الحساب: يتم تقسيم الإجمالي المتبقي إلى 6 صلوات؛ إذا كان المتبقي 0، تظل كل صلاة 0.';

  @override
  String get dailyNamazWisdomFallback =>
      'تعذر تحميل نص التذكير. حاول تحديث الصفحة.';

  @override
  String get momentVerseError => 'فشل التحميل. حاول مرة أخرى.';

  @override
  String get momentVerseEmptyTitle => 'لا توجد لحظة بعد';

  @override
  String get momentVerseEmptyDesc => 'انتظر الإشعار التالي.';

  @override
  String get momentVerseExpiredTitle => 'لقد مر هذا الوقت';

  @override
  String get momentVerseExpiredDesc =>
      'بعض اللحظات تأتي مرة واحدة فقط.\nربما نلتقي في اللحظة التالية.';

  @override
  String get momentVerseExpiredNote =>
      'احتفظ بالإشعارات قيد التشغيل،\nحتى لا تفوت اللحظة التالية.';

  @override
  String get momentVerseActiveWhisper => 'الآية التي همست لك بها الساعة';

  @override
  String get momentVerseSurah => 'سورة';

  @override
  String get momentVerseVerse => 'آية';

  @override
  String get momentVerseOneVerse => 'آية';

  @override
  String get momentVerseClock => 'الساعة';

  @override
  String get momentVerseMeaningDesc =>
      'هذه ليست صدفة؛ تتحول أرقام الوقت إلى عنوان في القرآن. وكذلك فتحك لهذا الإشعار في الوقت المحدد ووقوفك أمام هذه الآية.';

  @override
  String get momentVerseDisappear => 'ستختفي هذه اللحظة بعد';

  @override
  String get momentVerseReturnHome => 'العودة إلى الصفحة الرئيسية';

  @override
  String get momentVerseClose => 'إغلاق';

  @override
  String get surveyDictMoodHappy => 'سعيد';

  @override
  String get surveyDictMoodCalm => 'هادئ';

  @override
  String get surveyDictMoodStressed => 'متوتر';

  @override
  String get surveyDictMoodSad => 'حزين';

  @override
  String get surveyDictMoodGrateful => 'ممتن';

  @override
  String get surveyDictMoodAnxious => 'قلِق';

  @override
  String get surveyDictMoodMotivated => 'متحمس';

  @override
  String get surveyDictSectorStudent => 'ثانوي / جامعة / تحضيري';

  @override
  String get surveyDictSectorPrivate => 'القطاع الخاص';

  @override
  String get surveyDictSectorPublic => 'القطاع الحكومي';

  @override
  String get surveyDictSectorBusiness => 'عملي الخاص / مستقل';

  @override
  String get surveyDictSectorTrade => 'التجارة';

  @override
  String get surveyDictSectorHousehold => 'رب/ربة منزل';

  @override
  String get surveyDictSectorOther => 'أخرى';

  @override
  String get surveyDictNeedMotivation => 'الدافعية';

  @override
  String get surveyDictNeedSabr => 'الصبر';

  @override
  String get surveyDictNeedShukr => 'الشكر';

  @override
  String get surveyDictNeedTawakkul => 'التوكل';

  @override
  String get surveyDictNeedFocus => 'التركيز';

  @override
  String get surveyDictNeedHealing => 'الشفاء';

  @override
  String get surveyDictNeedRizq => 'الرزق والبركة';

  @override
  String get surveyDictGenderMale => 'ذكر';

  @override
  String get surveyDictGenderFemale => 'أنثى';

  @override
  String get premiumProductNotReadyError =>
      'معلومات المنتج ليست جاهزة بعد. يرجى المحاولة مرة أخرى.';

  @override
  String get premiumAccountLinkError =>
      'تعذر إكمال ربط الحساب. يرجى المحاولة مرة أخرى.';

  @override
  String get premiumWelcomeTitle => '🌿 أهلاً بك!';

  @override
  String get premiumWelcomeMessage =>
      'ARIN Premium نشط. تجربتك الخالية من الإعلانات والمفتوحة متاحة.\n\nيمكنك إدارة اشتراكك من حساب المتجر الخاص بك في أي وقت.';

  @override
  String get premiumWelcomeButton => 'رائع!';

  @override
  String get premiumRestoreSuccess => 'تم استعادة Premium!';

  @override
  String get premiumNoActiveSubscription => 'لم يتم العثور على اشتراك نشط.';

  @override
  String get premiumSignInErrorPrefix => 'تعذر إكمال تسجيل الدخول: ';

  @override
  String get premiumActiveTitle => 'ARIN Premium نشط';

  @override
  String get premiumTitle => 'ARIN Premium';

  @override
  String get premiumActiveSubtitle =>
      'تجربتك الخالية من الإعلانات والمفتوحة متاحة.';

  @override
  String get premiumSubtitle =>
      'روتين روحي خالٍ من الإعلانات، غير منقطع ومفتوح.';

  @override
  String get premiumYearlyPlanTitle => 'Premium سنوي';

  @override
  String get premiumMostAdvantageousBadge => 'الأكثر فائدة';

  @override
  String get premiumYearlyPlanSubtitle => 'اشتراك سنوي';

  @override
  String premiumYearlyPerMonth(String price) {
    return '$price / شهر';
  }

  @override
  String get premiumYearlyTrialCta => 'ابدأ التجربة المجانية لـ 3 أيام';

  @override
  String get premiumYearlyTrialNote =>
      'جرّب مجانًا لمدة 3 أيام. بعد التجربة يتجدد الاشتراك السنوي تلقائيًا ويمكنك الإلغاء في أي وقت.';

  @override
  String get premiumMonthlyCta => 'اشترك شهريًا';

  @override
  String get premiumCloseSemantics => 'إغلاق';

  @override
  String get premiumBenefitAi => 'الذكاء الاصطناعي الإسلامي';

  @override
  String get premiumBenefitThemes => 'سمات الأدوات المميزة';

  @override
  String get premiumSwitchToYearly => 'التبديل إلى السنوي';

  @override
  String get premiumMonthlyPlanTitle => 'Premium شهري';

  @override
  String get premiumMonthlyPlanSubtitle => 'اشتراك شهري';

  @override
  String get premiumLifetimePlanTitle => 'Premium مدى الحياة';

  @override
  String get premiumLifetimePlanSubtitle => 'شراء لمرة واحدة، بدون تجديد';

  @override
  String get premiumLifetimeCta => 'افتح مدى الحياة';

  @override
  String get premiumLifetimeNote =>
      'ادفع مرة واحدة واحتفظ بـ Premium إلى الأبد. هذا ليس اشتراكًا ولا يتجدد تلقائيًا.';

  @override
  String get premiumLifetimeBadge => 'دفعة واحدة';

  @override
  String get premiumPlanComingSoon => 'قريبًا';

  @override
  String get premiumYearlySaveVsMonthly => 'أوفر من الاشتراك الشهري';

  @override
  String get premiumCompareTitle => 'مجاني و Premium';

  @override
  String get premiumCompareColFree => 'مجاني';

  @override
  String get premiumCompareColPremium => 'Premium';

  @override
  String get premiumCompareAds => 'الإعلانات';

  @override
  String get premiumCompareAdsFree => 'موجودة';

  @override
  String get premiumCompareAdsPremium => 'بدون';

  @override
  String get premiumCompareWidgets => 'الأدوات';

  @override
  String get premiumCompareWidgetsFree => 'محدود';

  @override
  String get premiumCompareWidgetsPremium => 'غير محدود';

  @override
  String get premiumCompareThemes => 'سمات الأدوات';

  @override
  String get premiumCompareThemesFree => 'كلاسيكي';

  @override
  String get premiumCompareThemesPremium => '6 سمات';

  @override
  String get premiumCompareAi => 'الذكاء الاصطناعي الإسلامي';

  @override
  String get premiumCompareAiFree => 'مقفل';

  @override
  String get premiumCompareAiPremium => 'مفتوح';

  @override
  String get premiumCompareExplore => 'استكشف';

  @override
  String get premiumCompareExploreFree => 'مع إعلانات';

  @override
  String get premiumCompareExplorePremium => 'بدون انقطاع';

  @override
  String get premiumCompareAdhan => 'منبه الأذان الثاني';

  @override
  String get premiumCompareAdhanFree => 'مقفل';

  @override
  String get premiumCompareAdhanPremium => 'مفتوح';

  @override
  String get premiumComparePrayer => 'حلقة الدعاء';

  @override
  String get premiumComparePrayerFree => 'محدود';

  @override
  String get premiumComparePrayerPremium => 'غير محدود';

  @override
  String get premiumCompareContest => 'حق المسابقة';

  @override
  String get premiumCompareContestFree => 'محدود';

  @override
  String get premiumCompareContestPremium => 'غير محدود';

  @override
  String get premiumGrandfatherNotice =>
      'تبقى خطة Premium الحالية بنفس السعر. الأسعار الجديدة تنطبق فقط على الاشتراكات الجديدة.';

  @override
  String get premiumLegacyOwnedPrice => 'سعر الإطلاق ما زال ساريًا';

  @override
  String get premiumFooterText1 =>
      'الأسعار الجديدة تنطبق فقط على الاشتراكات الجديدة. يبقى سعر المشتركين الحاليين كما هو. تتم إدارة الاشتراك من خلال حساب المتجر ويمكن إلغاؤه في أي وقت.';

  @override
  String get premiumFooterText2 =>
      'يتم تجديد الاشتراك تلقائيًا ما لم يتم إلغاؤه قبل 24 ساعة على الأقل من نهاية الفترة. يتم خصم رسوم التجديد من حساب المتجر الخاص بك قبل 24 ساعة من نهاية الفترة. يمكنك إدارة اشتراكاتك في إعدادات حساب App Store/Play.';

  @override
  String get premiumLaunchBadge => '3 أيام مجانًا';

  @override
  String get premiumCountdownNotice =>
      'جرّب الخطة السنوية مجانًا لمدة 3 أيام. يبقى سعر المشتركين الحاليين كما هو.';

  @override
  String get premiumBenefitAdFree => 'استخدام بدون إعلانات';

  @override
  String get premiumBenefitWidgets => 'لا يوجد قفل للأدوات';

  @override
  String get premiumBenefitExplore => 'تدفق استكشاف غير منقطع';

  @override
  String get premiumBenefitAdhan => 'منبه الأذان الثاني مفعل';

  @override
  String get premiumBenefitPrayerCircle => 'حلقة الدعاء: طلبات غير محدودة';

  @override
  String get premiumBenefitContest => 'مشاركات مسابقة غير محدودة';

  @override
  String get premiumBenefitExtras => 'بدون إعلانات في الذكر والبوصلة والترددات';

  @override
  String get premiumBenefitAssistant =>
      'مساعد أرِن: دردشة كتابية وإدارة التطبيق';

  @override
  String get premiumSignInRequiredNotice =>
      'تسجيل الدخول غير مطلوب للشراء. يمكنك استخدام Premium على هذا الجهاز فورًا، ويمكنك ربط حسابك لاحقًا لاستخدامه على أجهزتك الأخرى.';

  @override
  String get premiumSignInSheetTitle => 'اربط حسابك لـ Premium';

  @override
  String get premiumSignInSheetSubtitle =>
      'ربط الحساب يجعل استعادة Premium على أجهزتك الأخرى أسهل. تسجيل الدخول اختياري لإتمام الشراء.';

  @override
  String get premiumContinueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get premiumContinueWithApple => 'المتابعة باستخدام Apple';

  @override
  String get premiumCancelForNow => 'إلغاء الآن';

  @override
  String get premiumPostPurchaseLinkTitle => 'Premium مفعل';

  @override
  String get premiumPostPurchaseLinkBody =>
      'Premium مفعل على هذا الجهاز. هل تريد ربط حسابك الآن لاستخدامه بسهولة على أجهزتك الأخرى؟';

  @override
  String get premiumPostPurchaseLinkLater => 'لاحقًا';

  @override
  String get premiumPostPurchaseLinkNow => 'اربط حسابي';

  @override
  String get premiumPostPurchaseLinkSuccess =>
      'تم ربط الحساب. يمكن الآن مزامنة Premium بين أجهزتك.';

  @override
  String get premiumActivePlanBadge => 'خطتك النشطة ✓';

  @override
  String get premiumActivePlanButton => 'خطتك النشطة';

  @override
  String get premiumStartWithLaunchPrice => 'ابدأ بسعر الإطلاق';

  @override
  String get premiumIsActiveButton => 'Premium نشط';

  @override
  String get qiblaCompassTitle => 'بوصلة القبلة';

  @override
  String get qiblaCompassQibla => 'القبلة';

  @override
  String get qiblaCompassGettingLocation => 'جاري تحديد الموقع…';

  @override
  String get qiblaCompassInitError => 'تعذر تهيئة\nالموقع أو البوصلة';

  @override
  String get qiblaCompassRetry => 'إعادة المحاولة';

  @override
  String get qiblaCompassAligned => 'أنت متجه نحو الكعبة';

  @override
  String get qiblaCompassDeviation => 'انحراف';

  @override
  String qiblaCompassDistanceKm(Object distance) {
    return '$distance كم إلى الكعبة';
  }

  @override
  String qiblaCompassDistanceM(Object distance) {
    return '$distance م إلى الكعبة';
  }

  @override
  String get qiblaCompassProximityFar => 'بوصلة القلب لا تخطئ طريقها';

  @override
  String get qiblaCompassProximityApproaching => 'كل خطوة دعوة إليه';

  @override
  String get qiblaCompassProximityMecca => 'أنتم في أرض الحرمين المباركة';

  @override
  String get qiblaCompassProximityHaram =>
      'أنتم في حضرة الكعبة، تقبل الله دعاءكم';

  @override
  String get qiblaCompassStabilizing => 'جاري استقرار القياس';

  @override
  String get qiblaCompassGuidanceTiltTitle => 'امسك الهاتف بشكل مسطح';

  @override
  String get qiblaCompassGuidanceTiltBody =>
      'استخدم البوصلة أفقيًا. لن يتم قفل الاتجاه إذا تم الإمساك به بشكل عمودي أو جانبي أو مقلوب.';

  @override
  String get qiblaCompassGuidanceCalibrateTitle => 'معايرة البوصلة';

  @override
  String get qiblaCompassGuidanceCalibrateBody =>
      'حرك الهاتف على شكل رقم 8 عدة مرات، ثم ابعده عن المعادن.';

  @override
  String get qiblaCompassGuidanceUnstableTitle => 'المجال المغناطيسي غير مستقر';

  @override
  String get qiblaCompassGuidanceUnstableBody =>
      'ابتعد عن أجهزة الكمبيوتر المحمولة والمغناطيس والطاولات المعدنية والأغطية المغناطيسية.';

  @override
  String get qiblaCompassGuidanceGoodTitle => 'القياس جاهز';

  @override
  String get qiblaCompassGuidanceGoodBody =>
      'امسك الهاتف بشكل مسطح، استدر ببطء نحو القبلة. يظهر توهج ذهبي عند المحاذاة.';

  @override
  String get qiblaCompassNorth => 'ش';

  @override
  String get qiblaCompassEast => 'ق';

  @override
  String get qiblaCompassSouth => 'ج';

  @override
  String get qiblaCompassWest => 'غ';

  @override
  String get qiblaCompassQiblaText => 'القبلة';

  @override
  String get zikirmatikCounterSemantics => 'عداد الذكر';

  @override
  String get zikirmatikRound => 'جولة';

  @override
  String get zikirmatikRoundCompleted => 'اكتملت الجولة';

  @override
  String get zikirmatikResetCounter => 'إعادة تعيين العداد؟';

  @override
  String get zikirmatikResetCounterDesc =>
      'سيتم تصفير العدد الإجمالي ومعلومات الجولة.';

  @override
  String get zikirmatikCancel => 'إلغاء';

  @override
  String get zikirmatikReset => 'تصفير';

  @override
  String get zikirmatikEditPhraseTitle => 'تعديل اسم الذكر';

  @override
  String get zikirmatikUse => 'استخدم';

  @override
  String get zikirmatikSaveAndUse => 'احفظ واستخدم';

  @override
  String get zikirmatikThisRound => 'هذه الجولة';

  @override
  String get zikirmatikTarget => 'الهدف';

  @override
  String zikirmatikCounterSemanticsLabel(
    Object round,
    Object target,
    Object total,
  ) {
    return 'عداد الذكر. $round / $target، الإجمالي $total';
  }

  @override
  String get zikirmatikCounterSemanticsHint => 'اضغط لزيادة العد بواحد';

  @override
  String get zikirmatikVibration => 'اهتزاز';

  @override
  String get zikirmatikVibrationTooltip =>
      'يهتز مع كل عدّ؛ اهتزاز أقوى عند نهاية الجولة';

  @override
  String get zikirmatikInfo => 'معلومات الذكر';

  @override
  String get zikirmatikTitle => 'عداد الذكر';

  @override
  String get zikirmatikTapToChoose => 'اضغط لاختيار الذكر';

  @override
  String get zikirmatikPickDhikr => 'اختر الذكر';

  @override
  String get zikirmatikSaved => 'المحفوظة';

  @override
  String get zikirmatikDelete => 'حذف';

  @override
  String get zikirmatikWriteOwnText => 'اكتب نصك الخاص…';

  @override
  String get zikirmatikCustomTarget => 'مخصص…';

  @override
  String get zikirmatikTargetOk => 'حسنًا';

  @override
  String get zikirmatikDeleteRoundRecord => 'حذف سجل هذه الجولة؟';

  @override
  String get zikirmatikDhikr => 'ذكر';

  @override
  String get zikirmatikShareError => 'تعذر فتح المشاركة. حاول مرة أخرى.';

  @override
  String get zikirmatikDeleteRecord => 'حذف السجل؟';

  @override
  String get zikirmatikCompletedRounds => 'الجولات المكتملة';

  @override
  String get zikirmatikNoCompletedRounds =>
      'لا توجد جولات مكتملة بعد. ستظهر هنا عند بلوغ الهدف.';

  @override
  String get zikirmatikArchivedSessions => 'الجلسات المؤرشفة';

  @override
  String get zikirmatikTodaysReflection => 'ورد اليوم';

  @override
  String zikirmatikCompareLine(Object diff, Object first, Object second) {
    return 'أكملت «$first» بعدد $diff جولة أكثر من «$second».';
  }

  @override
  String zikirmatikOnlyOneRecord(Object first) {
    return 'لديك حاليًا سجلات جولات لـ «$first» فقط.';
  }

  @override
  String get zikirmatikSummaryAndAnalytics => 'الملخص والتحليل';

  @override
  String get zikirmatikAnalyticsNoLogs =>
      'كلما أكملت جولات أكثر ستظهر الملخصات والمقارنات هنا.';

  @override
  String zikirmatikTotalRoundsCompleted(Object total) {
    return 'أكملت إجمالًا $total جولة.';
  }

  @override
  String zikirmatikActiveDays(Object days) {
    return 'لديك سجلات ذكر في $days أيام مختلفة.';
  }

  @override
  String zikirmatikLast7Days(Object rounds) {
    return 'تم إكمال $rounds جولة خلال آخر 7 أيام.';
  }

  @override
  String zikirmatikMostCompleted(Object phrase, Object rounds) {
    return 'الأكثر إكمالًا: «$phrase» ($rounds جولة).';
  }

  @override
  String get zikirmatikCompleted => 'مكتملة';

  @override
  String get zikirmatikTotalCounter => 'العداد الكلي';

  @override
  String get healingAmbientForest => 'صوت الغابة';

  @override
  String get healingAmbientFire => 'صوت النار';

  @override
  String get healingAmbientCosmic => 'صوت الكون';

  @override
  String get healingAmbientInshirah => 'سورة الشرح';

  @override
  String get healingSleepOff => 'متوقف';

  @override
  String get healingSleepRemaining => 'المتبقي ';

  @override
  String healingSleepMinutes(Object m) {
    return '$m دقيقة';
  }

  @override
  String get healingInfoTitle => 'معلومات';

  @override
  String get healingInfoBody =>
      'هذا القسم للاسترخاء والتأمل وليس بديلاً عن العلاج الطبي. يُنصح بالاستماع بصوت منخفض. أوقفه إذا شعرت بعدم الارتياح.';

  @override
  String get healingInfoOk => 'حسنًا';

  @override
  String get healingFrequenciesTitle => 'الترددات العلاجية';

  @override
  String get healingAmbientSound => 'صوت الخلفية';

  @override
  String get healingPresets => 'إعدادات مسبقة';

  @override
  String get healingFrequencyTone => 'نغمة التردد (Hz)';

  @override
  String get healingAmbient => 'الخلفية';

  @override
  String get healingSleepTimer => 'مؤقت النوم';

  @override
  String get healingInshirahLocked =>
      'عناصر التحكم بالتردد مقفلة في وضع الشرح.';

  @override
  String get healingAllFrequencies => 'كل الترددات';

  @override
  String get healingPresetFocus => 'تركيز';

  @override
  String get healingPresetSleep => 'نوم';

  @override
  String get healingAmbientForestShort => 'غابة';

  @override
  String get healingAmbientFireShort => 'نار';

  @override
  String get healingAmbientCosmicShort => 'كون';

  @override
  String get healingAmbientInshirahShort => 'الشرح';

  @override
  String get healingAmbientChoose => 'اختر صوت الخلفية';

  @override
  String get healingSleepCancel => 'إلغاء';

  @override
  String get healingSleepStopAfter => 'بعد كم دقيقة يتوقف؟';

  @override
  String get healingSleepTimerOff => 'المؤقت متوقف';

  @override
  String get healingFreq174Short => 'تردد علاجي';

  @override
  String get healingFreq285Short => 'الصبر والثبات';

  @override
  String get healingFreq396Short => 'تجدد';

  @override
  String get healingFreq417Short => 'قوة داخلية';

  @override
  String get healingFreq528Short => 'سكينة';

  @override
  String get healingFreq639Short => 'تزكية';

  @override
  String get healingFreq741Short => 'تفكر';

  @override
  String get healingFreq852Short => 'سكينة عميقة';

  @override
  String get healingFreq174Heading => '174 هرتز - شفاء واسترخاء';

  @override
  String get healingFreq285Heading => '285 هرتز - صبر وثبات';

  @override
  String get healingFreq396Heading => '396 هرتز - بركة وبداية';

  @override
  String get healingFreq417Heading => '417 هرتز - قوة داخلية وإيمان';

  @override
  String get healingFreq528Heading => '528 هرتز - سكينة وهدوء';

  @override
  String get healingFreq639Heading => '639 هرتز - تزكية وتنقية';

  @override
  String get healingFreq741Heading => '741 هرتز - تفكر وتركيز';

  @override
  String get healingFreq852Heading => '852 هرتز - سكينة (طمأنينة عميقة)';

  @override
  String get healingFreq174Body =>
      'اتجه إلى السكون عند التعب الجسدي والروحي؛ الشفاء من الله.';

  @override
  String get healingFreq285Body =>
      'تليين القلب وقت الشدة؛ الاستمرار بالتوكل على الله.';

  @override
  String get healingFreq396Body => 'فتح صفحة جديدة؛ دعاء للتوبة وطلب المغفرة.';

  @override
  String get healingFreq417Body =>
      'تقوية القلب؛ تجديد الإيمان وتذكّر الاستقامة.';

  @override
  String get healingFreq528Body => 'سكون القلب؛ تنفّس بالشكر والتسليم.';

  @override
  String get healingFreq639Body =>
      'الابتعاد عن الأفكار التي تكدّر القلب؛ طلب المغفرة.';

  @override
  String get healingFreq741Body =>
      'التركيز على الآيات والخلق؛ جمع الذهن المشتت.';

  @override
  String get healingFreq852Body => 'سكينة تشرح الصدر؛ الالتجاء إلى رحمة الله.';

  @override
  String get appleSignInCanceled => 'تم إلغاء تسجيل الدخول بحساب Apple.';

  @override
  String get appleSignInNotAuthorized =>
      'حساب Apple غير مصرح به. تحقق من إذن تسجيل الدخول باستخدام Apple من إعدادات iPhone > Apple ID > تسجيل الدخول والأمان.';

  @override
  String get appleSignInProviderDisabled =>
      'يبدو أن موفر تسجيل الدخول عبر Apple معطل في وحدة تحكم Firebase.';

  @override
  String get appleSignInInvalidCredential =>
      'بيانات مصادقة Apple غير صالحة. تحقق من Bundle ID وإمكانيات تسجيل الدخول عبر Apple في Xcode/Firebase.';

  @override
  String get appleSignInNetworkFailed =>
      'تعذر إكمال تسجيل الدخول عبر Apple بسبب اتصال الشبكة.';

  @override
  String get settingsMenuPremiumTitle => 'أرين بريميوم';

  @override
  String get settingsMenuPremiumSubtitle =>
      'أسعار الإطلاق وتجربة خالية من الإعلانات';

  @override
  String get settingsMenuWidgetsTitle => 'مركز الأدوات';

  @override
  String get settingsMenuWidgetsSubtitle => 'معلومات الاستخدام وأداة التتبع';

  @override
  String get supportProductNotReady =>
      'معلومات المنتج ليست جاهزة بعد. يرجى المحاولة مرة أخرى.';

  @override
  String get supportThanksTitle => 'شكراً لك! 🙏';

  @override
  String get supportThanksBody =>
      'دعمك قيم جداً لأرين. بهذه المساهمة، سنستمر في تقديم تجربة أفضل.';

  @override
  String get commonOk => 'حسناً';

  @override
  String get supportPageTitle => 'ادعم أرين';

  @override
  String get supportTierSmallTitle => 'دعم صغير';

  @override
  String get supportTierSmallDesc => 'ساهم في التطوير بدعم يعادل قهوة.';

  @override
  String get supportTierMediumTitle => 'دعم متوسط';

  @override
  String get supportTierMediumDesc => 'تسريع تطوير محتوى وميزات جديدة.';

  @override
  String get supportTierLargeTitle => 'دعم كبير';

  @override
  String get supportTierLargeDesc =>
      'قدم مساهمة قوية في التطور طويل الأمد لأرين.';

  @override
  String get supportPackagesDisclaimer =>
      'تعمل حزم الدعم كمنتجات متجر لمرة واحدة. وهي منفصلة عن اشتراك بريميوم.';

  @override
  String get supportHeaderTitle => 'قف مع أرين';

  @override
  String get supportHeaderDesc =>
      'ليست تبرعاً، بل حزم دعم لمرة واحدة متوافقة مع قواعد المتجر. تساعدنا على تنمية التجربة الخالية من الإعلانات والمميزة للتطبيق.';

  @override
  String get languageChangeFailed =>
      'تعذر تغيير اللغة. يرجى المحاولة مرة أخرى.';

  @override
  String get differentLocation => 'أنت في موقع مختلف';

  @override
  String updatePrayerTimesForCity(Object city) {
    return 'هل يجب تحديث أوقات الصلاة لـ $city؟';
  }

  @override
  String get rememberThisChoice => 'تذكر هذا الخيار، لا تسأل مرة أخرى';

  @override
  String get keepCurrentLocation => 'احتفاظ';

  @override
  String get updateLocation => 'تحديث';

  @override
  String get settingsBackgroundLocationTitle => 'التحديث التلقائي في الخلفية';

  @override
  String get settingsBackgroundLocationSubtitle =>
      'عند التفعيل، تُحدَّث مواقيت الصلاة تلقائيًا فور تغيّر مدينتك دون الحاجة لفتح التطبيق.';

  @override
  String get settingsBackgroundLocationPermissionDenied =>
      'للتحديث في الخلفية، يجب ضبط إذن الموقع على \"السماح دائمًا\" من إعدادات هاتفك.';

  @override
  String get settingsBackgroundLocationEnabledMessage =>
      'تم تفعيل التحديث التلقائي في الخلفية.';

  @override
  String get settingsBackgroundLocationDisabledMessage =>
      'تم إيقاف التحديث التلقائي في الخلفية.';

  @override
  String get backgroundLocationDisclosureTitle => 'استخدام الموقع في الخلفية';

  @override
  String get backgroundLocationDisclosureBody =>
      'إذا وافقت على \"السماح دائمًا\"، يتحقق Arın من موقعك في الخلفية بتردد منخفض حتى عند إغلاق التطبيق. هذا يتيح تحديث مواقيت الصلاة واتجاه القبلة وتنبيهات الصلاة تلقائيًا عند تغيّر مدينتك دون الحاجة لفتح التطبيق. تُعالج بيانات موقعك على جهازك فقط ولا تُستخدم أبدًا للإعلانات أو التحليلات.';

  @override
  String get backgroundLocationDisclosureDecline => 'إلغاء';

  @override
  String get backgroundLocationDisclosureAccept => 'متابعة';

  @override
  String get sealYourIntention => 'اختم نيتك';

  @override
  String get sealIntentionInfo =>
      'التفاصيل التي شاركتها للتو جزء من هذه البداية؛ اضغط مطولًا لتثبيت نيتك.';

  @override
  String get touchAndHoldWhenReady => 'عندما تكون مستعدًا، المس واستمر بالضغط.';

  @override
  String get youAreAlmostThere => 'أنت قريب جدًا!';

  @override
  String get promiseSealed => 'تهانينا، تم ختم عهدك!';

  @override
  String get touchAndHoldToContinue => 'المس الشاشة واستمر بالضغط\nللمتابعة…';

  @override
  String get skipWithArrow => 'تخطَّ ➔';

  @override
  String get redirecting => 'جارٍ التوجيه...';

  @override
  String get keepGoing => 'تابع...';

  @override
  String get premiumLoadingWait =>
      'يتم تفعيل Premium. يرجى المحاولة مرة أخرى بعد لحظات.';

  @override
  String get secondAlarmPremiumFeature => 'ميزة الإنذار الثاني لـ Premium';

  @override
  String get secondAlarmAdWatchText =>
      'لتفعيل إنذار الأذان الثاني لمدة يومين في الاستخدام المجاني، تتم مشاهدة إعلان قصير. مستخدمو Premium لا يرون هذا القفل.';

  @override
  String get giveUp => 'تخلى';

  @override
  String get openAfterAd => 'افتح بعد الإعلان';

  @override
  String get reflection => 'انعكاس';

  @override
  String yesterdayPrayerSummary(Object avg, Object weekday, Object yDone) {
    return 'أمس · $weekday · $yDone/5  ·  متوسط آخر 7 أيام $avg/5';
  }

  @override
  String get weeklyView => 'عرض أسبوعي';

  @override
  String daysDoneSummary(Object done) {
    return '$done/7 أيام';
  }

  @override
  String get inspirationAndAwareness => 'الإلهام والوعي';

  @override
  String get shortBreaksForTruth => 'فترات راحة قصيرة للحقيقة والوعي';

  @override
  String get insightCommentStrong =>
      'إيقاعك قوي جداً مؤخراً؛ يبدو أن قلبك متوافق مع النظام. استمر.';

  @override
  String get insightCommentPerfect =>
      'خمس مرات اكتملت أمس — لقد قضيت يوماً قريباً من ربك. يمكنك الاستمرار بنفس النية اليوم.';

  @override
  String get insightCommentZero =>
      'ربما لم يتم تسجيل الأمس أو التحقق منه بعد. حتى بصلاة واحدة اليوم، يمكنك إعادة رسم الخط.';

  @override
  String get insightCommentLow =>
      'المتوسط منخفض هذا الأسبوع؛ هذا طبيعي — يرتفع بالتأمل والخطوات الصغيرة. صلاة واحدة إضافية تحدث فرقاً كبيراً.';

  @override
  String insightCommentGood(Object count) {
    return 'تم تحديد $count/5 صلوات أمس؛ من الممكن إكمال التوازن بصلاة أو صلاتين اليوم.';
  }

  @override
  String get insightCommentDefault =>
      'بيانات الأيام الماضية هي مرآة لك: رحمة في الأجزاء المفقودة، وامتنان في الأجزاء المكتملة.';

  @override
  String get qiblaHubPrayerCircleTitle => 'حلقة الدعاء';

  @override
  String get qiblaHubPrayerCircleSubtitle =>
      'شارك طلب دعاء ورافق الآخرين بإخلاص';

  @override
  String get prayerCircleTitle => 'حلقة الدعاء';

  @override
  String get prayerCircleHeroTitle => 'شارك في دعاء من قلبك';

  @override
  String get prayerCircleHeroBody =>
      'تجتمع هنا طلبات الدعاء المجهولة. لنقل آمين بهدوء لنوايا بعضنا.';

  @override
  String get prayerCircleTwentyFourHours =>
      'يبقى كل طلب في الحلقة لمدة 24 ساعة';

  @override
  String get prayerCircleAll => 'حلقة الدعاء';

  @override
  String get prayerCircleMine => 'أدعيتي';

  @override
  String get prayerCircleCreate => 'إرسال طلب دعاء';

  @override
  String get prayerCircleEmptyTitle => 'الحلقة تنتظر دعاءً جديدًا';

  @override
  String get prayerCircleEmptyBody => 'شارك أول طلب دعاء وابدأ حلقة الخير هذه.';

  @override
  String get prayerCircleMineEmptyTitle => 'ليس لديك طلب دعاء بعد';

  @override
  String get prayerCircleMineEmptyBody =>
      'شارك نيتك دون اسم؛ وسيبقى طلبك هنا لمدة 24 ساعة.';

  @override
  String get prayerCircleLoadFailed => 'تعذر تحميل حلقة الدعاء';

  @override
  String get prayerCircleTryAgain => 'حاول مجددًا';

  @override
  String get prayerCircleComposeTitle => 'اكتب طلب الدعاء';

  @override
  String get prayerCircleComposeBody =>
      'شارك نية قصيرة وصادقة دون معلومات شخصية.';

  @override
  String get prayerCircleHint => 'مثال: أرجو الدعاء لعائلتي بالصحة والسكينة…';

  @override
  String get prayerCircleCategory => 'موضوع النية';

  @override
  String get prayerCircleCategoryGeneral => 'عام';

  @override
  String get prayerCircleCategoryHealth => 'الصحة';

  @override
  String get prayerCircleCategoryFamily => 'العائلة';

  @override
  String get prayerCircleCategoryPeace => 'السكينة';

  @override
  String get prayerCircleCategoryEducation => 'التعليم';

  @override
  String get prayerCircleCategoryWork => 'العمل والرزق';

  @override
  String get prayerCirclePrivacyNote =>
      'من أجل سلامتك، لا تشارك الأسماء أو أرقام الهاتف أو حسابات التواصل أو بيانات الدفع أو الروابط. نستخدم فحوصًا آلية وبلاغات المستخدمين، وتبقى مسؤولًا عن عدم نشر معلوماتك الشخصية.';

  @override
  String get prayerCircleContinue => 'متابعة الإرسال';

  @override
  String get prayerCircleTooShort => 'يجب ألا يقل طلب الدعاء عن 8 أحرف.';

  @override
  String get prayerCircleAdGateTitle => 'أضف دعاءك إلى الحلقة';

  @override
  String get prayerCircleAdGateBody =>
      'في الاستخدام المجاني يُشاهد إعلان قصير بمكافأة لكل طلب. لا تظهر الإعلانات لمستخدمي Premium.';

  @override
  String get prayerCircleWatchAd => 'شاهد الإعلان وأرسل';

  @override
  String get prayerCirclePremiumOption => 'إرسال بلا إعلانات مع Premium';

  @override
  String get prayerCircleAdFailed =>
      'الإعلان غير جاهز الآن. حاول مرة أخرى بعد قليل.';

  @override
  String get prayerCircleSent =>
      'تمت إضافة طلب دعائك إلى الحلقة. جعله الله سببًا للخير.';

  @override
  String get prayerCirclePray => 'دعوت له';

  @override
  String get prayerCirclePrayed => 'شاركت';

  @override
  String get prayerCircleOwnRequest => 'دعاؤك';

  @override
  String get prayerCircleYours => 'طلبك';

  @override
  String get prayerCirclePrayedThanks =>
      'آمين. لقد شاركت في هذا الدعاء من قلبك.';

  @override
  String get prayerCircleAlreadyPrayed => 'لقد شاركت في هذا الدعاء من قبل.';

  @override
  String prayerCirclePrayerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شخص دعا',
      many: '$count شخصًا دعوا',
      few: '$count أشخاص دعوا',
      two: 'شخصان دعيا',
      one: 'شخص واحد دعا',
      zero: 'لم يدعُ أحد بعد',
    );
    return '$_temp0';
  }

  @override
  String prayerCircleHoursLeft(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'متبقي $hours ساعة',
      many: 'متبقي $hours ساعة',
      few: 'متبقي $hours ساعات',
      two: 'متبقي ساعتان',
      one: 'متبقي ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String prayerCircleMinutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'متبقي $minutes دقيقة',
      many: 'متبقي $minutes دقيقة',
      few: 'متبقي $minutes دقائق',
      two: 'متبقيتان دقيقتان',
      one: 'متبقي دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get prayerCircleLoadMore => 'عرض المزيد';

  @override
  String get prayerCircleReportTitle => 'هل تريد الإبلاغ عن طلب الدعاء هذا؟';

  @override
  String get prayerCircleReportBody =>
      'تساعد البلاغات في إبقاء الحلقة آمنة ومحترمة. سيتم مراجعة هذا الطلب.';

  @override
  String get prayerCircleReportAction => 'إبلاغ';

  @override
  String get prayerCircleReported => 'شكرًا لك. تم الإبلاغ عن هذا الطلب.';

  @override
  String get prayerCircleAcceptRulesLabel =>
      'يُنشر طلبك بلا اسم ويجب أن يتوافق مع قواعد المجتمع.';

  @override
  String get prayerCircleAcceptRulesRequired =>
      'يرجى تأكيد قواعد المجتمع قبل الإرسال.';

  @override
  String get prayerCircleMoreActions => 'المزيد من الإجراءات';

  @override
  String get prayerCircleDeleteTitle => 'إزالة طلب الدعاء؟';

  @override
  String get prayerCircleDeleteBody =>
      'سيُزال الطلب من الحلقة فورًا ولا يمكن استعادته.';

  @override
  String get prayerCircleDeleteAction => 'إزالة';

  @override
  String get prayerCircleAdminDeleteTitle => 'هل تريد إزالة هذا الطلب كمسؤول؟';

  @override
  String get prayerCircleAdminDeleteBody =>
      'سيُحذف نهائيًا باعتباره محتوى غير لائق ولا يمكن استعادته.';

  @override
  String get prayerCircleAdminDeleteAction => 'المسؤول: إزالة';

  @override
  String get prayerCircleAdminDeleted =>
      'تمت إزالة الطلب من قبل أحد المسؤولين.';

  @override
  String get prayerCircleCancel => 'إلغاء';

  @override
  String get prayerCircleSlowDown =>
      'تجري العمليات بسرعة كبيرة. حاول مرة أخرى بعد قليل.';

  @override
  String get prayerCircleContentRejected =>
      'راجع النص واحذف المعلومات الشخصية أو معلومات الاتصال أو الدفع.';

  @override
  String get prayerCircleExpired => 'ربما انتهت مدة طلب الدعاء هذا.';

  @override
  String get prayerCircleGenericError =>
      'تعذر إكمال العملية. تحقق من اتصالك وحاول مجددًا.';

  @override
  String get appTourNext => 'التالي';

  @override
  String get appTourSkip => 'تخطي';

  @override
  String get appTourLetsStart => 'هيا نبدأ!';

  @override
  String appTourProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get appTourHomeHeaderTitle => 'شاشتك الرئيسية';

  @override
  String get appTourHomeHeaderBody =>
      'التحية واسمك وعدّاد الصلاة التالية هنا. اضغط على الاسم لتغيير طريقة مخاطبتك.';

  @override
  String get appTourHomeWisdomTitle => 'حكمة اليوم';

  @override
  String get appTourHomeWisdomBody =>
      'حكمة عن الصلاة كل يوم. اسحب البطاقة للتحديث أو الحفظ.';

  @override
  String get appTourHomeNamazTitle => 'متابعة الصلاة';

  @override
  String get appTourHomeNamazBody =>
      'علّم الأوقات واحفظ سلسلتك. القضاء والتذكيرات هنا أيضًا.';

  @override
  String get appTourHomePrayerTimesTitle => 'مواقيت الصلاة';

  @override
  String get appTourHomePrayerTimesBody =>
      'المواقيت حسب منطقتك. يمكنك تغيير الموقع من الإعدادات.';

  @override
  String get appTourNavToolsTitle => 'الأدوات';

  @override
  String get appTourNavToolsBody =>
      'القبلة والذكر وحلقة الدعاء وبقية الأدوات الروحية في هذا التبويب.';

  @override
  String get appTourQiblaAssistantTitle => 'مساعد أرِن';

  @override
  String get appTourQiblaAssistantBody =>
      'أدِر الصلاة والإشعارات والتذكيرات عبر المحادثة.';

  @override
  String get appTourQiblaAiTitle => 'الذكاء الاصطناعي الإسلامي';

  @override
  String get appTourQiblaAiBody =>
      'إجابات مستندة إلى مصادر إسلامية. تُفتح مع Premium.';

  @override
  String get appTourQiblaCompassTitle => 'بوصلة القبلة';

  @override
  String get appTourQiblaCompassBody => 'تُظهر اتجاه الكعبة من موقعك.';

  @override
  String get appTourQiblaZikirTitle => 'عداد الذكر';

  @override
  String get appTourQiblaZikirBody =>
      'تسبيح رقمي مع الأهداف والجولات وملاحظات الذكر.';

  @override
  String get appTourQiblaHilalTitle => 'مبارزة المعرفة';

  @override
  String get appTourQiblaHilalBody =>
      'اختبر نفسك بأسئلة إسلامية وثبّت ما تعرفه.';

  @override
  String get appTourQiblaPrayerCircleTitle => 'حلقة الدعاء';

  @override
  String get appTourQiblaPrayerCircleBody =>
      'شارك نيتك دون اسم، وقل آمين لأدعية الآخرين.';

  @override
  String get appTourQiblaHealingTitle => 'ترددات الشفاء';

  @override
  String get appTourQiblaHealingBody => 'أصوات مهدئة لجمع نفسك وتركيزك.';

  @override
  String get appTourQiblaBreathingTitle => 'تمرين التنفس';

  @override
  String get appTourQiblaBreathingBody =>
      'استخدم دورة 4-7-8 للهدوء في لحظة توتر.';

  @override
  String get appTourNavWillpowerTitle => 'النمو والتزكية';

  @override
  String get appTourNavWillpowerBody =>
      'متابعة العادات وبرامج الترك في هذا المثلث.';

  @override
  String get appTourWillpowerTabsTitle => 'النمو والتزكية';

  @override
  String get appTourWillpowerTabsBody =>
      'النمو للعادات التي تريد تثبيتها، والتزكية لما تريد تركه.';

  @override
  String get appTourWillpowerBreathingTitle => 'التنفس';

  @override
  String get appTourWillpowerBreathingBody =>
      'في اللحظة الصعبة افتح تمرين التنفس من هنا.';

  @override
  String get appTourWillpowerAddTitle => 'برنامج جديد';

  @override
  String get appTourWillpowerAddBody =>
      'استخدم علامة الزائد لإضافة عادة نمو أو برنامج تزكية.';

  @override
  String get appTourNavExploreTitle => 'اكتشف';

  @override
  String get appTourNavExploreBody => 'آيات وأحاديث وكلمات — اسحب واحفظ وشارك.';

  @override
  String get appTourInspireSearchTitle => 'بحث';

  @override
  String get appTourInspireSearchBody =>
      'اكتب كلمة؛ البحث دون تشكيل يعمل أيضًا.';

  @override
  String get appTourInspireFilterTitle => 'تصفية';

  @override
  String get appTourInspireFilterBody => 'ضيّق التدفق إلى كلمة أو آية أو حديث.';

  @override
  String get appTourNavSettingsTitle => 'الإعدادات';

  @override
  String get appTourNavSettingsBody => 'الإشعارات واللغة والودجات وحسابك هنا.';

  @override
  String get appTourSettingsNotificationsTitle => 'الإشعارات';

  @override
  String get appTourSettingsNotificationsBody =>
      'أدِر تذكيرات الأذان والتزكية والذكر من هنا.';

  @override
  String get appTourSettingsWidgetsTitle => 'مركز الودجات';

  @override
  String get appTourSettingsWidgetsBody =>
      'افتح ودجات الشاشة الرئيسية وشاشة القفل من هنا.';

  @override
  String get appTourSettingsLanguageTitle => 'اللغة';

  @override
  String get appTourSettingsLanguageBody =>
      'اختر التركية أو الإنجليزية أو العربية.';

  @override
  String get appTourAssistantFabTitle => 'فقاعة المساعد';

  @override
  String get appTourAssistantFabBody =>
      'اختصار قابل للسحب يفتح المساعد في أي تبويب.';

  @override
  String get appTourFinaleTitle => 'أنت جاهز';

  @override
  String get appTourFinaleBody =>
      'انتهت الجولة. تابع من أي تبويب — سنذكّرك ونرافقك.';

  @override
  String get appTourWidgetPromptTitle => 'هل تريد إضافة ودجة؟';

  @override
  String get appTourWidgetPromptBody =>
      'لتبق آية قصيرة أو وقت صلاة على الشاشة الرئيسية وشاشة القفل. يمكننا إضافتها الآن من مركز الودجات.';

  @override
  String get appTourWidgetPromptYes => 'نعم';

  @override
  String get appTourWidgetPromptLater => 'لاحقاً';
}
