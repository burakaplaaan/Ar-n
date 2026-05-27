// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get languageSettingsTitle => 'Dil ayarları';

  @override
  String get languageSettingsSheetTitle => 'Uygulama dili';

  @override
  String get languageTurkishLabel => 'Türkçe';

  @override
  String get languageEnglishLabel => 'İngilizce';

  @override
  String get languageArabicLabel => 'Arapça';

  @override
  String get settingsPageHeader => 'Ayarlar';

  @override
  String get settingsSectionAccount => 'Hesabınız';

  @override
  String get settingsSectionAppearance => 'Görünüm';

  @override
  String get settingsSectionPrayerTimes => 'Namaz vakitleri';

  @override
  String get settingsSectionApp => 'Uygulama';

  @override
  String get settingsSectionSession => 'Oturum';

  @override
  String get settingsMenuNotificationsSubtitle => 'Namaz, arınma ve zikir';

  @override
  String get settingsMenuNotificationsTitle => 'Bildirimler';

  @override
  String get settingsMenuAboutTitle => 'Hakkında';

  @override
  String get settingsMenuAboutSubtitle => 'Uygulama bilgileri';

  @override
  String get settingsMenuPrivacyTitle => 'Gizlilik Politikası';

  @override
  String get settingsMenuPrivacySubtitle => 'Verilerinizi nasıl işlediğimiz';

  @override
  String get settingsMenuSavedTitle => 'Kaydedilenler';

  @override
  String get settingsMenuSavedSubtitle => 'Keşfet’te kaydettiğin sözler';

  @override
  String get settingsMenuAdminTitle => 'İçerik yönetimi';

  @override
  String get settingsMenuAdminSubtitle => 'Söz havuzları ve Keşfet';

  @override
  String get settingsMenuContactTitle => 'Bize ulaşın';

  @override
  String get settingsMenuContactSubtitle => 'Destek ve geri bildirim';

  @override
  String get settingsMenuSupportTitle => 'Arın’a Destek Ol';

  @override
  String get settingsMenuSupportSubtitle => 'Tek seferlik destek paketleri';

  @override
  String get settingsMenuComingSoon => 'E-posta ile direkt yaz';

  @override
  String get settingsContactPageTitle => 'Bize ulaşın';

  @override
  String get settingsContactSubtitle =>
      'Öneri, hata bildirimi veya destek talebini doğrudan bize e-posta ile iletebilirsin.';

  @override
  String get settingsContactOpenMailAction => 'Mail uygulamasını aç';

  @override
  String get settingsContactCopyMailAction => 'E-posta adresini kopyala';

  @override
  String get settingsContactEmailCopied => 'E-posta adresi kopyalandı.';

  @override
  String get settingsContactOpenFailed =>
      'Mail uygulaması açılamadı. Adresi kopyalayıp manuel gönderebilirsin.';

  @override
  String get settingsContactCopyFailed =>
      'E-posta adresi kopyalanamadı. Lütfen manuel olarak yazın: arinapphelp@gmail.com';

  @override
  String get settingsContactMailSubject => 'Arın uygulaması geri bildirimi';

  @override
  String get settingsContactMailBody => 'Selam Arın ekibi,\n\n';

  @override
  String get settingsGuestHint =>
      'Misafir — veriler bu cihazda. Buluta kaydetmek için giriş yapın.';

  @override
  String get settingsAccountFallback => 'Hesap';

  @override
  String get settingsSignInGoogle => 'Google ile giriş';

  @override
  String get settingsSignInApple => 'Apple ile giriş';

  @override
  String get settingsSessionHint =>
      'Uygulamayı sıfırlamak veya hesabı kaldırmak için:';

  @override
  String get settingsSignOutAction => 'Çıkış yap';

  @override
  String get settingsDeleteAccountAction => 'Hesabı ve verileri tamamen sil';

  @override
  String get settingsLightThemeTitle => 'Açık tema';

  @override
  String get settingsLightThemeSubtitle =>
      'Daha kapalı açık zemin; okuması rahat';

  @override
  String get settingsProvinceLabel => 'İl';

  @override
  String get settingsProvinceHint => 'Yazın; örn. \"ko\" → Kocaeli';

  @override
  String get settingsProvinceInvalid =>
      'Listeden bir il seçin veya yazmaya devam edin.';

  @override
  String settingsLocationUpdatedMessage(Object city) {
    return 'Konum güncellendi: $city';
  }

  @override
  String get settingsLocationFailedMessage =>
      'Konum alınamadı; izin veya GPS’i kontrol edin.';

  @override
  String settingsProvinceUpdatedMessage(Object province) {
    return '$province — namaz vakitleri güncellendi';
  }

  @override
  String get settingsSignOutDialogTitle => 'Çıkış yap';

  @override
  String get settingsSignOutDialogBody =>
      'Bilgilendirme slaytlarından başlayarak uygulama sıfırlanır. Bu cihazdaki tüm yerel veriler silinir; Firebase oturumunuz kapanır.';

  @override
  String get settingsDialogCancel => 'İptal';

  @override
  String get settingsDeleteAllDataDialogTitle => 'Tüm verileri sil';

  @override
  String get settingsDeleteAllDataDialogBody =>
      'Misafir modundasınız. Bu cihazdaki tüm uygulama verileri kalıcı olarak silinir ve bilgilendirme ekranlarına dönersiniz.';

  @override
  String get settingsDeleteAction => 'Sil';

  @override
  String get settingsDeleteAccountDialogTitle => 'Hesabı kalıcı sil';

  @override
  String get settingsDeleteAccountDialogBody =>
      'Bulut hesabınız silinir; bu cihazdaki tüm yerel veriler de temizlenir. Geri alınamaz.';

  @override
  String get settingsDeleteProgressMessage =>
      'Bulut ve cihaz verileriniz siliniyor…';

  @override
  String get settingsCloudDeleteFailedMessage =>
      'Bulut verileriniz silinemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get settingsAccountDeleteFailedMessage => 'Hesap silinemedi.';

  @override
  String get settingsAccountDeleteRetryMessage =>
      'Hesap silinemedi. Lütfen biraz sonra tekrar deneyin.';

  @override
  String get settingsGoogleSignInSuccess => 'Google ile giriş yapıldı.';

  @override
  String get settingsGoogleSignInCancelled => 'Google ile giriş iptal edildi.';

  @override
  String get settingsGoogleSignInFailed =>
      'Google ile giriş yapılamadı. Lütfen tekrar deneyin.';

  @override
  String get settingsAppleSignInSuccess => 'Apple ile giriş yapıldı.';

  @override
  String get settingsAppleSignInFailed =>
      'Apple ile giriş yapılamadı. Lütfen tekrar deneyin.';

  @override
  String get settingsAuthServiceUnavailable =>
      'Giriş servisine şu anda ulaşılamıyor. Lütfen birazdan tekrar deneyin.';

  @override
  String get homeGreetingNight => 'Hayırlı Geceler';

  @override
  String get homeGreetingMorning => 'Hayırlı Sabahlar';

  @override
  String get homeGreetingNoon => 'Hayırlı Öğlenler';

  @override
  String get homeGreetingEvening => 'Hayırlı Akşamlar';

  @override
  String get homeGuestUser => 'Misafir';

  @override
  String homePrayerUrgentSemanticsLabel(Object remaining) {
    return 'Dikkat, imsak vakti çıkıyor. Güneş doğuşuna $remaining kaldı';
  }

  @override
  String homePrayerNextSemanticsLabel(Object nextName, Object remaining) {
    return 'Sıradaki namaz $nextName, kalan $remaining';
  }

  @override
  String get homePrayerUrgentBadge => 'Çıkıyor';

  @override
  String get homePrayerNextBadge => 'Sıradaki';

  @override
  String get homePrayerTimesTitle => 'Namaz Vakitleri';

  @override
  String get homePrayerNextRowHint => 'Sıradaki vakit';

  @override
  String get homePrayerLoadFailedTitle => 'Vakitler yüklenemedi';

  @override
  String get homePrayerLoadFailedBody =>
      'İnternet, konum izni veya seçili ilçe nedeniyle vakitler alınamamış olabilir.';

  @override
  String get homeRetryAction => 'Tekrar dene';

  @override
  String get homeChangeDistrictAction => 'İlçe değiştir';

  @override
  String get homeOpenSettingsAction => 'Ayarları aç';

  @override
  String get homeRemainingPassed => 'geçti';

  @override
  String get homeRemainingFewSeconds => 'birkaç saniye';

  @override
  String homeRemainingHoursMinutes(int hours, int minutes) {
    return '$hours saat $minutes dakika';
  }

  @override
  String homeRemainingHoursOnly(int hours) {
    return '$hours saat';
  }

  @override
  String homeRemainingMinutesOnly(int minutes) {
    return '$minutes dakika';
  }

  @override
  String get homeLocationFreshNow => 'Konum güncel';

  @override
  String homeLocationFreshMinutesAgo(int minutes) {
    return '$minutes dk önce güncellendi';
  }

  @override
  String homeLocationFreshHoursAgo(int hours) {
    return '$hours sa önce güncellendi';
  }

  @override
  String homeLocationFreshDaysAgo(int days) {
    return '$days gün önce güncellendi';
  }

  @override
  String get homeDailyReminderTitle => 'Bugünün hatırlatıcısı';

  @override
  String get homeNamazSetupTitle => 'Namaz takibini kur';

  @override
  String get homeNamazSetupSubtitle =>
      'Kurulum Gelişim sekmesinden yapılır; kurduktan sonra kartın burada otomatik görünür.';

  @override
  String get homeNamazTrackingTitle => 'Namaz takibi';

  @override
  String homeNamazTrackingProgressLine(Object done) {
    return 'Bugün $done/5 · Detaylar için dokun';
  }

  @override
  String get onboardingNotificationPermissionDenied =>
      'Bildirim izni verilmedi. Ezan vakitleri için Ayarlar → Bildirimler\'den açabilirsin.';

  @override
  String onboardingGenderPromptWithName(Object name) {
    return '$name, cinsiyetinizi öğrenebilir miyiz?';
  }

  @override
  String get onboardingNotificationSkippedWarning =>
      'Bildirimler kapalı kaldı. Namaz vakitlerinde ezan hatırlatması gelmez — sonra Ayarlar → Bildirimler\'den açabilirsin.';

  @override
  String get onboardingOpenNowAction => 'Şimdi aç';

  @override
  String get commonPreview => 'Önizle';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonDone => 'Tamam';

  @override
  String get commonBack => 'Geri';

  @override
  String get prayerNameImsak => 'İmsak';

  @override
  String get prayerNameSunrise => 'Güneş';

  @override
  String get prayerNameDhuhr => 'Öğle';

  @override
  String get prayerNameAsr => 'İkindi';

  @override
  String get prayerNameMaghrib => 'Akşam';

  @override
  String get prayerNameIsha => 'Yatsı';

  @override
  String get reminderOff => 'Kapalı';

  @override
  String get reminderAtExactTime => 'Tam vakitte';

  @override
  String reminderMinutesBefore(int minutes) {
    return '$minutes dk önce';
  }

  @override
  String get reminderCardSubtitle =>
      'Her vakit ayrı · Süreleri düzenlemek için dokun';

  @override
  String get reminderFirstOff => '1. kapalı';

  @override
  String reminderFirstValue(Object value) {
    return '1. $value';
  }

  @override
  String reminderPairSecondOff(Object first) {
    return '$first · 2. kapalı';
  }

  @override
  String reminderPairSecondValue(Object first, Object second) {
    return '$first · 2. $second';
  }

  @override
  String get reminderPermissionRequiredMessage =>
      'Bildirim izni gerekli. Ayarlardan açabilirsin.';

  @override
  String get reminderPrayerNotificationTitle => 'Vakit bildirimi';

  @override
  String get reminderCardDisabledHint =>
      'Kapalı · Anahtarı aç, vakitleri ayarla';

  @override
  String get reminderLocalNotificationUnavailable =>
      'Bu ortamda yerel bildirim yok.';

  @override
  String get reminderSectionTitle => 'Hatırlatıcı';

  @override
  String get reminderTwoAlertsPerPrayer => 'Vakit başına iki uyarı';

  @override
  String get reminderPerPrayerDifferentSounds => 'Vakitlere göre ayrı sesler';

  @override
  String reminderCurrentSound(Object summary) {
    return 'Şu an: $summary';
  }

  @override
  String get reminderUsePhoneDefaultSubtitle =>
      'Telefon ayarlarındaki bildirim sesi kullanılır.';

  @override
  String get reminderChooseArinSoundsTitle => 'Arın seslerinden seç';

  @override
  String get reminderChooseArinSoundsSubtitle =>
      'Ezan ve huzur tonlarını dinleyip uygula.';

  @override
  String get reminderPhoneSoundActiveAllPrayers =>
      'Telefondan seçilen ses tüm vakitlerde aktif.';

  @override
  String get reminderApplyOwnSoundAllPrayers =>
      'Kendi ses dosyanı tüm vakitlere uygula.';

  @override
  String get reminderSetPerPrayerDifferentSound =>
      'Vakitlere göre ayrı ses ayarla';

  @override
  String get reminderAllPrayersSoundTitle => 'Tüm vakitler için ses';

  @override
  String get reminderAllPrayersSoundSubtitle =>
      'Tek seçim yap; tüm vakitlerde aynı ses çalsın.';

  @override
  String get reminderBackToSingleSoundSelection => 'Tek ses seçimine dön';

  @override
  String get reminderPerPrayerSavedInstantly =>
      'Vakit bazlı seçimler anında kaydedilir.';

  @override
  String get reminderEnableNotificationsAction => 'Bildirimleri aç';

  @override
  String get reminderDurationsPerPrayerTitle => 'Her vakit için süreler';

  @override
  String get reminderDurationsPerPrayerSubtitle =>
      'Satıra dokun; 1. ve 2. uyarıyı ayrı seç.';

  @override
  String get reminderApplyDurationsAllButton =>
      'Seçtiğim süreleri tüm vakitlere uygula';

  @override
  String get reminderAllPrayersDurationTarget => 'Tüm vakitler';

  @override
  String get reminderDurationsAppliedAllSuccess =>
      'Süreler tüm vakitlere uygulandı.';

  @override
  String reminderDualAlertTitle(Object prayerTitle) {
    return 'İki uyarı — $prayerTitle';
  }

  @override
  String get reminderDualAlertSubtitle =>
      '1. uyarı: Kapalı, tam vakit veya dakika önce. 2. uyarı: Kapalı veya dakika önce.';

  @override
  String get reminderFirstAlertTitle => '1. uyarı';

  @override
  String get reminderSecondAlertTitle => '2. uyarı';

  @override
  String get prayerSoundPickerTitle => 'Bildirim sesi';

  @override
  String get prayerSoundQuickAllSubtitle =>
      'Önce tek ses seç; istersen detaylı ayarda vakit bazında ayrılaştır.';

  @override
  String get prayerSoundApplyAllButton => 'Seçtiğim sesi tüm vakitlere uygula';

  @override
  String get prayerSoundAdvancedToggle => 'Detaylı ayar (vakit bazlı)';

  @override
  String get prayerSoundAppliedAllSuccess =>
      'Seçilen ses tüm vakitlere uygulandı.';

  @override
  String get prayerSoundSystem => 'Telefonun varsayılan sesi';

  @override
  String get prayerSoundAdhanTurkish => 'Ezan — Türkçe işleme (10 sn, baştan)';

  @override
  String get prayerSoundAdhanDubai => 'Ezan — Dubai / Ramadan (9 sn, baştan)';

  @override
  String get prayerSoundAmbientFlute => 'Huzur — flute doku (6 sn, baştan)';

  @override
  String get prayerSoundAmbientPianoGuitar =>
      'Huzur — piyano & gitar (7 sn, baştan)';

  @override
  String get prayerSoundAmbientEthereal =>
      'Huzur — ethereal voices (10 sn, baştan)';

  @override
  String get prayerSoundPickFromPhone => 'Telefondan ses seç';

  @override
  String get prayerSoundClearUserFile => 'Kaldır';

  @override
  String get prayerSoundUserFromPhone => 'Telefondan seçilen ses';

  @override
  String get prayerSoundUserFileActiveHint =>
      'Bu vakit için şu an telefondan seçilen dosya kullanılıyor. Katalogdan bir ses seçersen dosya kalkar.';

  @override
  String get prayerSoundSubtitlePerPrayer =>
      'Her vakit için ayrı ayrı: telefonun varsayılan sesi, katalogdan ton veya telefondan kendi dosyan. Uygula ile kaydet.';

  @override
  String get prayerSoundImportFailed =>
      'Ses dosyası alınamadı. Başka bir dosya veya format dene (WAV, M4A…).';

  @override
  String get prayerSoundPreviewSystem =>
      'Önizleme yok — cihazının varsayılan bildirim sesi kullanılır.';

  @override
  String get commonStart => 'Başla';

  @override
  String get commonRestart => 'Yeniden';

  @override
  String get willpowerHabitNotFound => 'Alışkanlık bulunamadı';

  @override
  String get namazProgramHomeHintActive =>
      'Namaz takibi aktif. Artık Anasayfa kartında da görünür.';

  @override
  String get namazProgramPageTitle => 'İbadet';

  @override
  String get namazProgramVerseQuote =>
      '“Şüphesiz kalpler, Allah’ı anmakla huzur bulur.”\n(Ra’d suresi, 13:28 — meal)';

  @override
  String get namazProgramBreathingBreak => 'Nefes molası';

  @override
  String get namazProgramTodayPrayersTitle => 'Bugünün namazları';

  @override
  String namazProgramTodayProgress(int done) {
    return '$done/5 tamam';
  }

  @override
  String namazProgramPercentDone(int percent) {
    return '%$percent tamamlandı';
  }

  @override
  String get namazProgramSystemNotificationSettings =>
      'Sistem bildirim ayarları';

  @override
  String get namazProgramRecentDaysTitle => 'Son günler';

  @override
  String get namazProgramRecentDaysSubtitle =>
      'Her kutu o gün kılınan vakit sayısı (ör. 3/5).';

  @override
  String get breathingPhaseInhale => 'Nefes al';

  @override
  String get breathingPhaseHold => 'Tut';

  @override
  String get breathingPhaseExhale => 'Nefes ver';

  @override
  String breathingCycleProgress(int current, int total) {
    return 'Döngü $current/$total';
  }

  @override
  String get breathingFinishAction => 'Bitir';

  @override
  String breathingSecondsLabel(int seconds) {
    return '$seconds sn';
  }

  @override
  String get breathingIntroTitle => '4-7-8 Nefes Terapisi';

  @override
  String get breathingIntroSubtitle =>
      'Stres ve kaygıyı azaltan, yavaş tempolu nefes düzeni.';

  @override
  String breathingIntroCycles(int cycles) {
    return '$cycles döngü';
  }

  @override
  String get breathingIntroApproxMinutes => '~2 dk';

  @override
  String get breathingPhaseHintInhale => 'saniye al';

  @override
  String get breathingPhaseHintHold => 'saniye tut';

  @override
  String get breathingPhaseHintExhale => 'saniye ver';

  @override
  String get breathingSessionCompleteTitle => 'Bu seans tamam';

  @override
  String breathingSessionCompleteSubtitle(int cycles) {
    return '$cycles döngü tamamlandı. İstersen bir tur daha yapabilir veya çıkabilirsin.';
  }

  @override
  String get breathingBottomHint =>
      'Tutarken kalp ritmi yavaşlar; rahat bir tempoda devam et. Baş dönmesi olursa dur.';

  @override
  String get quitProgramNotFound => 'Program bulunamadı';

  @override
  String get quitOnboardingCommitmentMinLengthError =>
      'Lütfen kendine bir söz yaz (en az 8 karakter).';

  @override
  String get quitOnboardingQuickStartTitle => 'Sayacı şimdi başlat';

  @override
  String get quitOnboardingQuickStartBody =>
      'Sayacın bu andan itibaren çalışmaya başlar. Ahdini dilediğin zaman programdan tamamlayabilirsin.';

  @override
  String get quitOnboardingAbortAction => 'Vazgeç';

  @override
  String get quitOnboardingExitDraftTitle => 'Hazırlıktan çıkılsın mı?';

  @override
  String get quitOnboardingExitDraftBody =>
      'Bu hazırlık turundaki ilerlemen kaydedilmez. İstersen daha sonra yeniden başlayabilirsin.';

  @override
  String get quitOnboardingStayAction => 'Kal';

  @override
  String get quitOnboardingExitAction => 'Çık';

  @override
  String get quitOnboardingContentLoadFailed =>
      'Hazırlık içeriği yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get quitOnboardingAppBarTitle => 'Hazırlık';

  @override
  String get quitOnboardingSealTitlePrefix => 'Sözünü mühürle';

  @override
  String get quitOnboardingSealHoldHint => 'Parmağını basılı tut';

  @override
  String get quitOnboardingContinueAction => 'Devam';

  @override
  String get quitOnboardingQuickStartInlineAction =>
      'Sayacı hemen başlat, programı sonra tamamla';

  @override
  String get quitOnboardingCommitmentTitle => 'Kendine sözün';

  @override
  String get quitOnboardingCommitmentSubtitle =>
      'Kısa ve net yaz; mühürlemeden önce düzenleyebilirsin.';

  @override
  String get quitOnboardingCommitmentHint => 'Bugünden itibaren…';

  @override
  String get quitOnboardingExamplesSectionTitle => 'Örnek cümleler';

  @override
  String get quitProgramRestartTitle => 'Yeniden başla';

  @override
  String get quitProgramRestartPrompt =>
      'Sayaç sıfırlanacak. Geçmişin ne olsun?';

  @override
  String get quitProgramRestartKeepHistoryTitle => 'Geçmişi sakla';

  @override
  String get quitProgramRestartKeepHistorySubtitle =>
      'Sayaç sıfırdan başlar; önceki denemen, günlük işaretlerin ve istatistiklerin korunur.';

  @override
  String get quitProgramRestartWipeTitle => 'Sıfırdan başla';

  @override
  String get quitProgramRestartWipeSubtitle =>
      'Tüm geçmiş günlük işaretler de silinir. Geri alınamaz.';

  @override
  String quitProgramElapsedHms(int hours, int minutes, int seconds) {
    return '$hours sa $minutes dk $seconds sn';
  }

  @override
  String quitProgramElapsedMs(int minutes, int seconds) {
    return '$minutes dk $seconds sn';
  }

  @override
  String quitProgramElapsedS(int seconds) {
    return '$seconds sn';
  }

  @override
  String get quitProgramTabProgress => 'İlerleme';

  @override
  String get quitProgramTabTips => 'İpuçları';

  @override
  String get quitProgramTipsLoadFailed => 'İçerik yüklenemedi';

  @override
  String get quitProgramTipsWatermark => 'هِدَايَة';

  @override
  String get quitProgramTipsHeroTitle => 'Hidayet';

  @override
  String get quitProgramTipsHeroSubtitle =>
      'Şuur, sabır ve pratik öneriler — yolunu yumuşatmak için.';

  @override
  String get quitProgramDaysUpper => 'GÜN';

  @override
  String get quitProgramStartNowAction => 'Bu andan bıraktım';

  @override
  String get quitProgramStatFullDays => 'Tam gün';

  @override
  String get quitProgramDash => '—';

  @override
  String get quitProgramStatTimer => 'Sayaç';

  @override
  String quitProgramElapsedSinceQuitDays(int days) {
    return 'Geçen süre: $days gün (bırakma anından)';
  }

  @override
  String get quitProgramTasksTitle => 'Görevler';

  @override
  String get quitProgramTasksSubtitle =>
      'Gün eşiklerini tamamladıkça ilerlersin.';

  @override
  String get quitProgramUiCounterSubtitleGeneric => 'temiz kalış';

  @override
  String get quitProgramUiMetricsSectionTitleGeneric => 'İlerleme göstergeleri';

  @override
  String get quitProgramUiDisclaimerGeneric =>
      'Motivasyon amaçlı göstergelerdir.';

  @override
  String get quitProgramUiEncouragementGeneric =>
      'Her temiz gün değerlidir; sabit ve küçük adımlar büyük dönüşümler getirir.';

  @override
  String get quitProgramUiClockHintGeneric =>
      'Tıkladığında süre ve göstergeler bu ana göre ilerler.';

  @override
  String get quitProgramMotivationStageStart =>
      'İlk günün en değerli adımı: başlamak.';

  @override
  String get quitProgramMotivationStageWeek =>
      'İlk hafta sabır; küçük adımlar büyük değişim getirir.';

  @override
  String get quitProgramMotivationStageMonth =>
      'Bir aya yaklaşırken sabırla devam.';

  @override
  String get quitProgramMotivationStageQuarter =>
      'Üç aylık süreçte sabır meyvesini gösterir.';

  @override
  String get quitProgramMotivationStageLong =>
      'Uzun solukta her temiz gün değerlidir.';

  @override
  String get quitMetricSmokingLung => 'Ciğer / solunum';

  @override
  String get quitMetricSmokingHeart => 'Kalp-damar';

  @override
  String get quitMetricSmokingTeethMouth => 'Diş ve ağız';

  @override
  String get quitMetricSmokingSmellTaste => 'Koku ve tat';

  @override
  String get quitMetricScreenFocusDepth => 'Odak ve derinlik';

  @override
  String get quitMetricScreenSleepRhythm => 'Uyku düzeni';

  @override
  String get quitMetricScreenAwareness => 'Ekran farkındalığı';

  @override
  String get quitMetricScreenInnerCalm => 'İç huzur';

  @override
  String get quitMetricAlcoholLiverRecovery => 'Karaciğer toparlanması';

  @override
  String get quitMetricAlcoholSleepStability => 'Uyku istikrarı';

  @override
  String get quitMetricAlcoholMoodBalance => 'Ruh hali dengesi';

  @override
  String get quitMetricAlcoholClarity => 'Zihin berraklığı';

  @override
  String get quitMetricSubstanceBodyBalance => 'Beden dengesi';

  @override
  String get quitMetricSubstanceSleepRhythm => 'Uyku ritmi';

  @override
  String get quitMetricSubstanceUrgeControl => 'İstek yönetimi';

  @override
  String get quitMetricSubstanceSupportTracking => 'Destek ve takip';

  @override
  String get quitMetricZinaDiscipline => 'Nefis disiplini';

  @override
  String get quitMetricZinaBoundaryStrength => 'Sınır gücü';

  @override
  String get quitMetricZinaHeartCalm => 'Kalp sükûnu';

  @override
  String get quitMetricZinaTawbaDirection => 'Tövbe istikameti';

  @override
  String get quitMilestone1Title => 'İlk nefes';

  @override
  String get quitMilestone1Subtitle => 'Bir gün temiz';

  @override
  String get quitMilestone2Title => 'İlk seri';

  @override
  String get quitMilestone2Subtitle => '48 saat';

  @override
  String get quitMilestone3Title => 'Üç gün';

  @override
  String get quitMilestone3Subtitle => 'İstek zirvesi geçiyor';

  @override
  String get quitMilestone5Title => 'Beş gün';

  @override
  String get quitMilestone5Subtitle => 'Rutin kırılıyor';

  @override
  String get quitMilestone7Title => 'Bir hafta';

  @override
  String get quitMilestone7Subtitle => 'İlk hafta tamam';

  @override
  String get quitMilestone10Title => 'On gün';

  @override
  String get quitMilestone10Subtitle => 'İrade güçleniyor';

  @override
  String get quitMilestone14Title => 'İki hafta';

  @override
  String get quitMilestone14Subtitle => 'Algı toparlanıyor';

  @override
  String get quitMilestone21Title => 'Üç hafta';

  @override
  String get quitMilestone21Subtitle => 'Alışkanlık döngüsü';

  @override
  String get quitMilestone30Title => 'Bir ay';

  @override
  String get quitMilestone30Subtitle => 'Önemli eşik';

  @override
  String get quitMilestone45Title => 'Kırk beş gün';

  @override
  String get quitMilestone45Subtitle => 'Düzen oturuyor';

  @override
  String get quitMilestone60Title => 'İki ay';

  @override
  String get quitMilestone60Subtitle => 'Beden adapte';

  @override
  String get quitMilestone66Title => 'Alışkanlık ustası';

  @override
  String get quitMilestone66Subtitle => '66 gün çizgisi';

  @override
  String get quitMilestone90Title => 'Üç ay';

  @override
  String get quitMilestone90Subtitle => 'Sağlıkta belirgin dönem';

  @override
  String get quitMilestone120Title => 'Dört ay';

  @override
  String get quitMilestone120Subtitle => 'Kararlılık nişanı';

  @override
  String get quitMilestone180Title => 'Altı ay';

  @override
  String get quitMilestone180Subtitle => 'Yarım yıl';

  @override
  String get quitMilestone270Title => 'Dokuz ay';

  @override
  String get quitMilestone270Subtitle => 'Uzun soluk';

  @override
  String get quitMilestone365Title => 'Bir yıl';

  @override
  String get quitMilestone365Subtitle => 'Büyük müjde';

  @override
  String get quitMilestone500Title => 'Beş yüz gün';

  @override
  String get quitMilestone500Subtitle => 'Azim tacı';

  @override
  String get quitMilestone730Title => 'İki yıl';

  @override
  String get quitMilestone730Subtitle => 'Kökten değişim';

  @override
  String get quitMilestone1000Title => 'Bin gün';

  @override
  String get quitMilestone1000Subtitle => 'Eşsiz seviye';

  @override
  String get quitMilestoneInspiration365 =>
      '\"Sabredenlere mükâfatları hesapsız verilir.\" (Zümer, 10)';

  @override
  String get quitMilestoneInspiration90 =>
      '\"Allah ile beraber olan, asla yalnız kalmaz.\"';

  @override
  String get quitMilestoneInspiration30 =>
      '\"Azmettin mi, artık Allah\'a tevekkül et.\" (Âl-i İmrân, 159)';

  @override
  String get quitMilestoneInspiration7 =>
      '\"Zorlukla beraber bir kolaylık vardır.\" (İnşirâh, 6)';

  @override
  String get quitMilestoneInspiration1 =>
      '\"Muhakkak her güçlüğün yanında bir kolaylık vardır.\" (İnşirâh, 5)';

  @override
  String quitMilestoneElapsedSummary(int days, Object subtitle) {
    return '$days gündür temiz — $subtitle';
  }

  @override
  String get quitMilestoneContinueAction => 'Devam et';

  @override
  String get quitProgramCompleteCommitmentTitle => 'Ahdini tamamla';

  @override
  String get quitProgramCompleteCommitmentSubtitle =>
      'Sayaç çalışıyor — programını kendine yazdığın sözle mühürle.';

  @override
  String get willpowerHubBreathingExerciseTitle => 'Nefes egzersizi';

  @override
  String get willpowerHubBreathingExerciseSubtitle =>
      'Yavaş nefes; stres anında bedenini yumuşatır.';

  @override
  String get willpowerHubArchiveHabitDialogTitle => 'Alışkanlığı kalıcı sil';

  @override
  String get willpowerHubArchiveHabitDialogBody =>
      'Bu kayıt ve ilişkili ilerleme verileri kalıcı olarak silinir. Geri alınamaz.';

  @override
  String get willpowerHubArchiveAction => 'Kalıcı sil';

  @override
  String get willpowerHubHeaderTitle => 'Gelişim & Arınma';

  @override
  String get willpowerHubNoActiveHabits => 'Henüz aktif alışkanlık yok';

  @override
  String willpowerHubActiveHabits(int count) {
    return '$count aktif alışkanlık';
  }

  @override
  String get willpowerHubHabitCalendarTooltip => 'Alışkanlık takvimi';

  @override
  String get willpowerHubTabBuild => 'Gelişim';

  @override
  String get willpowerHubTabQuit => 'Arınma';

  @override
  String get willpowerHubQuitCtaEarly =>
      'Her temiz dakika kalbine ve ciğerlerine oksijen olarak döner.';

  @override
  String get willpowerHubQuitCtaOngoing =>
      'İlk günler zor; bedenin zaten iyileşmeye başladı.';

  @override
  String get willpowerHubBuildCtaEarly => 'Küçük adımlarla başlamak yeterli.';

  @override
  String get willpowerHubBuildCtaOngoing => 'Düzenin sana iyi gidiyor; devam.';

  @override
  String get willpowerHubSummaryQuitLabel => 'ARINMA';

  @override
  String get willpowerHubSummaryTodayLabel => 'BUGÜN';

  @override
  String get willpowerHubSummaryCounterProgress => 'sayaç ilerlemesi';

  @override
  String get willpowerHubSummaryCompleted => 'tamamlandı';

  @override
  String get willpowerHubInsightTagSpiritual => 'MANEVİ';

  @override
  String get willpowerHubInsightTagHealth => 'SAĞLIK';

  @override
  String get willpowerHubAddFirstBuild => 'İlk gelişimini ekle';

  @override
  String get willpowerHubAddFirstQuit => 'İlk arınmanı ekle';

  @override
  String get willpowerHubBuildEmptyTitle => 'Gelişim alanın henüz boş';

  @override
  String get willpowerHubBuildEmptySubtitle =>
      'Hayır katan bir alışkanlığı sürdürmek, manevi gelişimin en sade yoludur.';

  @override
  String get willpowerHubKazaLabelSabah => 'Sab';

  @override
  String get willpowerHubKazaLabelOgle => 'Öğl';

  @override
  String get willpowerHubKazaLabelIkindi => 'İkn';

  @override
  String get willpowerHubKazaLabelAksam => 'Akş';

  @override
  String get willpowerHubKazaLabelYatsi => 'Yat';

  @override
  String get willpowerHubKazaLabelVitir => 'Vit';

  @override
  String get willpowerHubKazaTrackingTitle => 'Kaza takibi';

  @override
  String get willpowerHubKazaRemainingLabel => 'kalan';

  @override
  String get willpowerHubRemoveCardTooltip => 'Kartı kaldır';

  @override
  String get willpowerHubHideKazaDialogTitle => 'Kaza kartını kaldır?';

  @override
  String get willpowerHubHideKazaDialogBody =>
      'Bu kart Gelişim ekranından gizlenir. Hesap ve sayaç verilerin cihazda kalır; Rutin atölyesinden tekrar ekleyebilirsin.';

  @override
  String get willpowerHubRemoveAction => 'Kaldır';

  @override
  String get willpowerHubQuitEmptyTitle => 'Arınma alanın henüz boş';

  @override
  String get willpowerHubQuitEmptySubtitle =>
      'Zararlı bir alışkanlıktan vazgeçmek, nefsini terbiye etmenin güçlü bir yoludur.';

  @override
  String get willpowerHubPeriodPrefixWeek => 'Bu hafta ';

  @override
  String get willpowerHubPeriodPrefixMonth => 'Bu ay ';

  @override
  String willpowerHubPercentTargetReached(Object prefix) {
    return '${prefix}Hedef yüzdesine ulaştın.';
  }

  @override
  String willpowerHubPercentProgressStatus(
    Object prefix,
    int progress,
    int left,
  ) {
    return '$prefix%$progress tamamlandı, %$left kaldı.';
  }

  @override
  String willpowerHubTargetPending(Object prefix) {
    return '${prefix}Hedef bekleniyor.';
  }

  @override
  String willpowerHubUnitTargetAddPrompt(
    Object prefix,
    int target,
    Object unit,
  ) {
    return '$prefix$target $unit hedef — eklemek için karta dokun.';
  }

  @override
  String willpowerHubUnitProgressTargetFilled(
    Object prefix,
    int progress,
    Object unit,
  ) {
    return '$prefix$progress $unit tamam; hedef doldu.';
  }

  @override
  String willpowerHubUnitProgressRemaining(
    Object prefix,
    int progress,
    Object unit,
    int left,
  ) {
    return '$prefix$progress $unit tamamladın, $left $unit kaldı.';
  }

  @override
  String willpowerHubUnitTargetDoneSuper(
    Object prefix,
    int target,
    Object unit,
  ) {
    return '$prefix$target $unit tamam — süper.';
  }

  @override
  String willpowerHubUnitProgressDidRemaining(
    Object prefix,
    int progress,
    Object unit,
    int left,
  ) {
    return '$prefix$progress $unit yaptın, $left $unit kaldı.';
  }

  @override
  String get willpowerHubAddEditHint => 'Ekleme ve düzenleme için karta dokun';

  @override
  String get willpowerHubQuitStatusSetupMissing => 'Hazırlık eksik';

  @override
  String get willpowerHubQuitStatusClockRunning => 'Sayaç açık';

  @override
  String get willpowerHubQuitStatusProgramReady => 'Program hazır';

  @override
  String get willpowerHubTapCardForDetails => 'Detaylar için karta dokun';

  @override
  String get willpowerHubCompleteSetup => 'Kurulumu tamamla';

  @override
  String get willpowerHubStartClockHint =>
      'Programda “Bu andan bıraktım” ile sayacı başlat';

  @override
  String get willpowerHubStreakSeriesLabel => 'seri';

  @override
  String get willpowerHubStreakDaySeriesLabel => 'gün serisi';

  @override
  String get qiblaHubCompassTitle => 'Kıble yönünü bul';

  @override
  String get qiblaHubCompassSubtitle =>
      'Pusula ve konum ile Kâbe yönünü göster';

  @override
  String get qiblaHubOpenAction => 'Aç';

  @override
  String get qiblaHubZikirTitle => 'Zikirmatik';

  @override
  String get qiblaHubZikirFeatureSubtitle =>
      'Dijital sayaç; zikir bilgisi, tur geçmişi ve hedef (33/99)';

  @override
  String get qiblaHubBreathingTitle => 'Nefes Egzersizi';

  @override
  String get qiblaHubBreathingSubtitle =>
      '4-7-8 nefes döngüsü ile sakinleş, odağını toparla';

  @override
  String get qiblaHubHealingTitle => 'İyileştirici Frekanslar';

  @override
  String get qiblaHubHealingSubtitle =>
      'Terapi tonları, ambiyans ve uyku zamanlayıcısı ile sakin bir oturum';

  @override
  String get generalLoading => 'Yükleniyor...';

  @override
  String get settingsPrivacyPageTitle => 'Gizlilik Politikası';

  @override
  String get settingsPrivacyLastUpdated => 'Son güncelleme: 26.04.2026';

  @override
  String get settingsPrivacyIntro =>
      'Arin gizliliğinize saygı duyar. Bu metin, hangi verilerin işlendiğini, neden işlendiğini ve bu süreçleri nasıl yönetebileceğinizi açıklar.';

  @override
  String get settingsPrivacyDataCollectedTitle => 'İşlenen veriler';

  @override
  String get settingsPrivacyDataCollectedBody =>
      'Kullanımınıza ve verdiğiniz izinlere bağlı olarak Arin; namaz vakti ve kıble özellikleri için konum verisi, bildirim tercihleri, giriş yaptığınızda hesap bilgileri ve uygulama tanılama verilerini işleyebilir.';

  @override
  String get settingsPrivacyUsageTitle => 'Verileri neden işliyoruz';

  @override
  String get settingsPrivacyUsageBody =>
      'Veriler; namaz vakitlerini hesaplamak, kıble yönünü göstermek, hatırlatıcıları planlamak, ayarlarınızı korumak ve uygulama kararlılığını iyileştirmek amacıyla işlenir.';

  @override
  String get settingsPrivacyStorageTitle => 'Saklama ve süre';

  @override
  String get settingsPrivacyStorageBody =>
      'Alışkanlık, zikir ve tercih verilerinin büyük kısmı cihazınızda tutulur. Hesapla giriş yaparsanız seçili veriler Firebase servisleriyle eşitlenebilir. Veriler, uygulama içinden silene veya hesabınızı kaldırana kadar saklanır.';

  @override
  String get settingsPrivacyThirdPartyTitle => 'Üçüncü taraf servisler';

  @override
  String get settingsPrivacyThirdPartyBody =>
      'Arin; oturum açma, veri eşitleme, kullanım analizi ve çökme tanılama için Firebase Authentication, Cloud Firestore, Firebase Analytics ve Firebase Crashlytics kullanır.';

  @override
  String get settingsPrivacyControlsTitle => 'Kullanıcı kontrolü';

  @override
  String get settingsPrivacyControlsBody =>
      'Konum ve bildirim izinlerini cihaz ayarlarından kapatabilir, Ayarlar ekranından çıkış yapabilir veya hesabınızı ve yerel verilerinizi silebilirsiniz.';

  @override
  String get settingsPrivacyChildrenTitle => 'Çocukların gizliliği';

  @override
  String get settingsPrivacyChildrenBody =>
      'Arin, 13 yaş altı çocuklara yönelik olarak tasarlanmamıştır.';

  @override
  String get settingsPrivacyContactTitle => 'İletişim';

  @override
  String get settingsPrivacyContactBody =>
      'Gizlilik ile ilgili sorularınız için: arinapphelp@gmail.com';

  @override
  String get notificationsHubTitle => 'Bildirimler';

  @override
  String get notificationsHubHeadline => 'Hatırlatıcı merkezi';

  @override
  String get notificationsHubSubhead =>
      'Namaz, arınma ve zikir — hepsi tek yerden.';

  @override
  String get notificationsPermissionGranted => 'İzin verildi';

  @override
  String get notificationsPermissionDenied => 'İzin kapalı';

  @override
  String get notificationsPermissionLimited => 'Kısıtlı';

  @override
  String get notificationsOpenOsSettings => 'Sistem bildirim ayarları';

  @override
  String get notificationsGateNotification => 'Bildirim';

  @override
  String get notificationsGateExactAlarm => 'Tam zamanlayıcı';

  @override
  String get notificationsGateBattery => 'Pil muafiyeti';

  @override
  String get notificationsGateAllGood => 'Hatırlatıcılar zamanında tetiklenir.';

  @override
  String get notificationsGateMissing =>
      'Bir veya daha fazla izin eksik — zamanlanan bildirimler gecikebilir ya da hiç gelmeyebilir.';

  @override
  String get notificationsGateRequestExact => 'Tam zamanlayıcı iznini aç';

  @override
  String get notificationsGateRequestBattery => 'Pil optimizasyonunu muaf tut';

  @override
  String get notificationsBatteryRationaleTitle =>
      'Pil muafiyeti neden gerekli?';

  @override
  String get notificationsBatteryRationaleBody =>
      'Namaz vakti ve arınma bildirimleri, telefon uyku (Doze) modundayken bile tam saatinde gelebilmesi için pil optimizasyonundan muaf tutulmalıdır. Bu izin yalnızca zamanlanmış bildirimleri etkiler; arka planda sürekli çalışmaz.';

  @override
  String get notificationsBatteryRationaleConfirm => 'İzin ver';

  @override
  String get notificationsBatteryRationaleCancel => 'Şimdi değil';

  @override
  String get notificationsDiagnosticsQueuedLabel =>
      'Kuyruğa alınan zamanlı hatırlatıcı';

  @override
  String get notificationsSectionGeneral => 'Genel';

  @override
  String get notificationsSectionPrayer => 'Namaz vakitleri';

  @override
  String get notificationsSectionArinma => 'Arınma ve alışkanlıklar';

  @override
  String get notificationsPrayerRowTitle => 'Vakit ve ses';

  @override
  String get notificationsPrayerOnSubtitle =>
      'Vakit bildirimleri açık — dokunup düzenle';

  @override
  String get notificationsPrayerOffSubtitle =>
      'Vakit bildirimleri kapalı — dokunup açabilirsin';

  @override
  String get notificationsPrayerDetailTitle => 'Namaz bildirimleri';

  @override
  String get notificationsPrayerDetailSubtitle =>
      'Her vakit için ayrı süre ve ses; ana anahtar aşağıda.';

  @override
  String get notificationsArinmaDailyTitle => 'Günlük hatırlatıcı';

  @override
  String get notificationsArinmaDailySubtitle =>
      'Gün içinde 2 defa rastgele bir söz ya da kısa motivasyon.';

  @override
  String get notificationsMilestoneTitle => 'Alışkanlık bildirimleri';

  @override
  String get notificationsMilestoneSubtitle =>
      'Örn. bırakma yolculuğunda 24 saat, 1 hafta gibi seyrek mesajlar.';

  @override
  String get notificationsTaskTitle => 'Görev hatırlatıcısı';

  @override
  String get notificationsTaskSubtitle =>
      'Tamamlanmamış görev için günde en fazla bir uyarı.';

  @override
  String get notificationsZikirTitle => 'Zikir hatırlatıcısı';

  @override
  String get notificationsZikirSubtitle =>
      'Seçtiğin saatte, son zikirindeki metinle kısa bir hatırlatma.';

  @override
  String get notificationsZikirTimeLabel => 'Zikir saati';

  @override
  String get notificationsZikirTimePickerTitle => 'Zikir saati';

  @override
  String get notificationsZikirTimePickerSubtitle =>
      'Her gün bu saatte son zikir metninle hatırlatma.';

  @override
  String get notificationsHealthDisclaimer =>
      'Sağlık ve arınma ile ilgili metinler genel bilgilendirme amaçlıdır; tedavi yerine geçmez. Rahatsızlığınız varsa doktorunuza danışın.';

  @override
  String get notificationsNextReminderToday => 'bugün';

  @override
  String get notificationsNextReminderTomorrow => 'yarın';

  @override
  String get notificationsNextReminderUnderMinute => '< 1 dk';

  @override
  String notificationsNextReminderMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String notificationsNextReminderHoursOnly(int hours) {
    return '$hours sa';
  }

  @override
  String notificationsNextReminderHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String notificationsNextReminderLine(
    Object dayLabel,
    Object clock,
    Object gap,
  ) {
    return 'Bir sonraki hatırlatıcı: $dayLabel $clock · $gap sonra';
  }

  @override
  String get aboutArinHeadline => 'Yolun yanında';

  @override
  String get aboutArinSubhead =>
      'Namazına, düzenine ve gününe yumuşak hatırlatmalar sunan küçük bir arkadaş';

  @override
  String get aboutArinParagraph1 =>
      'ARIN; namazını vaktinde tutmana, sana iyi gelen alışkanlıkları sürdürüp zorlayan huyları yavaşça geride bırakmana yardımcı olmak için var. Amacımız baskı kurmak değil; yoğun günlerde kaybolan küçük hatırlatmalarla yanında, sakin bir köşede durmak.';

  @override
  String get aboutArinParagraph2 =>
      'Bazen yol uzun, bazen gün çok dolu olur. Bu yüzden sade bir düzen ve net hatırlatmalar sunuyoruz. Eksik veya yanlış hissettiren her noktayı duymak isteriz; birlikte düzeltmeye ve geliştirmeye açığız.';

  @override
  String get aboutArinParagraph3 =>
      'Küçük adımlar, uzun vadede en çok işe yarayanlardır. ARIN’i acele ettirmeyen, yolunu yalnız bırakmayan huzurlu bir eşlik gibi düşünmeni dileriz; günün sana sakin ve hafif geçsin.';

  @override
  String get aboutArinClosingWish => 'Hayırlı kullanımlar dileriz';

  @override
  String languageChangedMessage(Object languageName) {
    return 'Dil değiştirildi: $languageName';
  }

  @override
  String get adminIdentityBadge => 'ADMIN';

  @override
  String get adminPoolsHint =>
      'Havuz seç, düzenle ve kaydet. İleri düzey işlemler altta toplanır.';

  @override
  String adminPoolsDropdownLabel(int count) {
    return 'Havuz ($count öğe)';
  }

  @override
  String get adminAdvancedActionsTitle => 'Gelişmiş işlemler';

  @override
  String get adminBackupCurrentPoolJson => 'Bu havuzu yedekle (JSON)';

  @override
  String get adminRestoreFromBackup => 'Yedekten geri yükle';

  @override
  String get adminWritingInProgress => 'Yazılıyor…';

  @override
  String get adminResetCompletely => 'Tamamen sıfırla';

  @override
  String adminVersionLabel(Object version) {
    return 'Sürüm: v$version';
  }

  @override
  String adminSearchInPoolHint(int count) {
    return 'Havuz içinde ara ($count kayıt)';
  }

  @override
  String get adminAddAction => 'Ekle';

  @override
  String get adminAddMissingRecords => 'Eksik kayıtları ekle';

  @override
  String get adminPoolLabelHomeNamazWisdom => 'Ana sayfa namaz kartı';

  @override
  String get adminPoolLabelPersonalizedQuotes => 'Kişiselleştirilmiş sözler';

  @override
  String get adminPoolLabelWidgetQuote => 'Widget / ana ekran sözü';

  @override
  String get adminPoolLabelZikirDailyReflections =>
      'Namaz vakit kartı (zikir yansıması)';

  @override
  String get adminPoolLabelHealingComfort => 'İyileşme / teselli sözleri';

  @override
  String get adminPoolLabelHubGelisimIslamic => 'Gelişim — İslami kart';

  @override
  String get adminPoolLabelHubGelisimMedical => 'Gelişim — sağlık kartı';

  @override
  String get adminPoolLabelHubArinmaIslamic => 'Arınma — İslami kart';

  @override
  String get adminPoolLabelHubArinmaMedical => 'Arınma — sağlık kartı';

  @override
  String get adminPoolLabelNotificationArinmaBodies =>
      'Arınma bildirimi metinleri';

  @override
  String get adminPoolLabelNotificationNamazWisdom => 'Namaz bildirimi sözleri';

  @override
  String get adminPoolLabelNotificationDailyNamazReminder =>
      'Günlük namaz hatırlatıcı metinleri';

  @override
  String adminSearchResultsCount(int count) {
    return '$count sonuç';
  }

  @override
  String get adminPoolEmptyHint => 'Bu havuz boş — öğe ekleyebilirsin.';

  @override
  String get adminSearchNoResults => 'Aramana uyan sonuç yok.';

  @override
  String get adminTapToEdit => 'Düzenlemek için dokun';

  @override
  String get adminEditTooltip => 'Düzenle';

  @override
  String adminInspireHint(int count) {
    return 'Kart ekle, metni doldur, sonra kaydet. Arka plan görselleri: $count adet.';
  }

  @override
  String get adminInspireAddNewCard => 'Yeni kart ekle';

  @override
  String get adminRefreshFromFirestore => 'Firestore’dan yenile';

  @override
  String adminInspireVersionCards(Object version, int count) {
    return 'Sürüm: v$version · $count kart';
  }

  @override
  String get adminInspireNoCardsYet => 'Henüz Keşfet kartı yok';

  @override
  String get adminInspireAddFirstCard => 'İlk kartı ekle';

  @override
  String adminInspireCardLabel(int index) {
    return 'Kart $index';
  }

  @override
  String get adminInspireEmptyTextBadge => 'Boş metin';

  @override
  String get adminInspireDuplicateTooltip => 'Kopyala';

  @override
  String get adminInspireShuffleDesignTooltip => 'Tasarımı yeniden karıştır';

  @override
  String adminInspireEmptyTextPreview(int index) {
    return '(boş metin — #$index)';
  }

  @override
  String adminInspireImageNumberLabel(Object index) {
    return 'Görsel #$index';
  }

  @override
  String get adminInspireContentKindLabel => 'İçerik türü';

  @override
  String get adminInspireContentKindQuote => 'Özlü söz';

  @override
  String get adminInspireContentKindVerse => 'Âyet';

  @override
  String get adminInspireContentKindHadith => 'Hadis';

  @override
  String get adminInspireShowInMainFeedTitle => 'Ana akışta göster (Karma)';

  @override
  String get adminInspireShowInMainFeedSubtitle =>
      'İşaretli değilse yalnızca Ayet veya Hadis filtresinden görünür.';

  @override
  String get adminInspireTurkishTextLabel => 'Türkçe metin *';

  @override
  String get adminOptionalArabicLabel => 'Arapça (isteğe bağlı)';

  @override
  String get adminOptionalSourceLabel => 'Kaynak (isteğe bağlı)';

  @override
  String get adminOptionalVerseRefLabel => 'Âyet / sure (isteğe bağlı)';

  @override
  String get adminInspireSaveAllChanges => 'Tüm kart değişikliklerini kaydet';

  @override
  String get adminDiagnosticsHint =>
      'Otomatik bildirim tanısı. Buradaki loglar planlama denemelerini kaydeder.';

  @override
  String get adminDiagnosticsStatusSummaryTitle => 'Durum özeti';

  @override
  String get adminDiagnosticsEnabled => 'açık';

  @override
  String get adminDiagnosticsDisabled => 'kapalı';

  @override
  String adminDiagnosticsPrayerStatus(Object status) {
    return 'Namaz: $status';
  }

  @override
  String adminDiagnosticsDailyStatus(Object status) {
    return 'Günlük: $status';
  }

  @override
  String adminDiagnosticsMilestoneStatus(Object status) {
    return 'Eşik: $status';
  }

  @override
  String adminDiagnosticsTaskStatus(Object status) {
    return 'Görev: $status';
  }

  @override
  String adminDiagnosticsZikirStatus(Object status) {
    return 'Zikir: $status';
  }

  @override
  String adminDiagnosticsPendingQueue(int count) {
    return 'Bekleyen kuyruk: $count';
  }

  @override
  String get adminRefreshAction => 'Yenile';

  @override
  String get adminDiagnosticsExportLog => 'Log dışa aktar';

  @override
  String get adminDiagnosticsClearLog => 'Log temizle';

  @override
  String adminDiagnosticsRecentEvents(int count) {
    return 'Son olaylar ($count)';
  }

  @override
  String get adminDiagnosticsNoLogsHint =>
      'Henüz log yok. Uygulamayı yeniden açıp bir süre kullan, sonra yenile.';

  @override
  String get adminDiagnosticsOutcomeOk => 'başarılı';

  @override
  String get adminDiagnosticsOutcomeError => 'hata';

  @override
  String get adminDiagnosticsOutcomeCooldownSkip => 'atlandı (bekleme süresi)';

  @override
  String get adminDiagnosticsOutcomePendingGuardSkip =>
      'atlandı (bekleyen koruması)';

  @override
  String get adminDiagnosticsOutcomeDisabled => 'devre dışı';

  @override
  String get adminDiagnosticsOutcomeInvalidPayloadSkip =>
      'atlandı (geçersiz yük)';

  @override
  String adminDiagnosticsOutcomeUnknown(Object outcome) {
    return 'bilinmiyor ($outcome)';
  }

  @override
  String get adminDevOffsetSavedAndRescheduled =>
      'Kaydırma kaydedildi; bildirimler yenilendi.';

  @override
  String get adminDevOffsetReset => 'Kaydırma sıfırlandı.';

  @override
  String get adminDevOffsetDisabled => 'Kapalı (API saatleri)';

  @override
  String adminDevOffsetForwardMinutes(int minutes) {
    return 'Öne: $minutes dk';
  }

  @override
  String adminDevOffsetBackwardMinutes(int minutes) {
    return 'Geriye: $minutes dk';
  }

  @override
  String get adminDevPrayerOffsetTitle =>
      'Vakit kaydırma (yalnızca bu cihazda)';

  @override
  String get adminDevPrayerOffsetSubtitle =>
      'Negatif = tüm vakitleri öne çeker (bildirim planı da buna göre). API / sunucu değişmez.';

  @override
  String get adminDevResetAction => 'Sıfırla';

  @override
  String get adminDevSaveAndRescheduleAction => 'Kaydet ve yeniden planla';

  @override
  String get adminDevNotificationTestsTitle => 'Bildirim testleri';

  @override
  String get adminDevNotificationTestsSubtitle =>
      'Mevcut kanal ve ses yollarını anında denemek için.';

  @override
  String get adminDevPrayerNotificationSent => 'Namaz bildirimi gönderildi.';

  @override
  String get adminDevPrayerNotificationNowAction => 'Namaz bildirimi (şimdi)';

  @override
  String get adminDevAppNotificationSent => 'Uygulama bildirimi gönderildi.';

  @override
  String get adminDevAppNotificationNowAction =>
      'Arınma / uygulama bildirimi (şimdi)';

  @override
  String get adminDevCrashlyticsTestTitle => 'Çökme raporu testi (Crashlytics)';

  @override
  String get adminDevCrashlyticsDebugHint =>
      'Debug build: toplama KAPALI. Test etmek için release APK kur.';

  @override
  String get adminDevCrashlyticsReleaseHint =>
      'Aşağıdaki butonlar Firebase Console → Crashlytics’e gerçek bir hata gönderir. Raporun göründüğünü doğruladıktan sonra kaldırabilirsin.';

  @override
  String get adminFirebaseNotReady => 'Firebase hazır değil.';

  @override
  String get adminDevCrashlyticsNonFatalSent =>
      'Non-fatal kayıt gönderildi. Console’da birkaç dakika içinde görünür.';

  @override
  String adminErrorWithReason(Object reason) {
    return 'Hata: $reason';
  }

  @override
  String get adminDevSendNonFatalTestAction => 'Test: non-fatal hata gönder';

  @override
  String get adminDevCrashNowFatalAction =>
      'Test: uygulamayı ŞİMDİ çöktür (fatal)';

  @override
  String get adminDevCrashDialogTitle => 'Uygulamayı çöktür?';

  @override
  String get adminDevCrashDialogBody =>
      'Uygulama birkaç saniye içinde kapanacak. Telefonda tekrar açtığında rapor Firebase’e yüklenir (birkaç dakika sonra Console’da görünür).\n\nSadece Crashlytics testini doğrulamak için kullan.';

  @override
  String get adminDevCrashAction => 'Çöktür';

  @override
  String get adminDiagnosticsTitle => 'Tanılama';

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
  String get adminDevPlatformUnknown => 'bilinmiyor';

  @override
  String get adminDevUidLabel => 'UID';

  @override
  String get adminDevPendingNotificationLabel => 'Bekleyen bildirim';

  @override
  String get adminDevTapToRefresh => 'yenilemek için dokun';

  @override
  String get adminDiagnosticsError => 'hata';

  @override
  String get adminPoolDataUnavailable => 'Havuz verisi şu anda alınamıyor.';

  @override
  String get adminPoolChangeAction => 'Havuz değişikliği';

  @override
  String get adminReviewBeforeSaveTitle => 'Kaydetmeden önce kontrol';

  @override
  String get adminPoolSaved => 'Havuz kaydedildi.';

  @override
  String get adminPoolSaveFailed => 'Havuz kaydedilemedi.';

  @override
  String get adminUseSeedAllForPool =>
      'Bu havuz için “Tüm havuzları tohumla” kullanın.';

  @override
  String get adminNoBuiltInSeedForPool =>
      'Bu havuz için yerleşik tohumlama tanımlı değil.';

  @override
  String get adminSeedSelectedPoolDefaults =>
      'Seçili havuzu varsayılanla yenile';

  @override
  String get adminPoolNotLoadedYet => 'Havuz henüz yüklenmedi.';

  @override
  String adminPoolBackupShareText(Object poolId, Object timestamp) {
    return 'Arın havuz yedeği — $poolId ($timestamp)';
  }

  @override
  String get adminPoolBackupShareSubject => 'Arın havuz yedeği';

  @override
  String adminBackupCreationFailed(Object error) {
    return 'Yedek oluşturulamadı: $error';
  }

  @override
  String get adminBackupInvalidJsonObject =>
      'Yedek dosyası okunamadı: JSON nesnesi bekleniyor.';

  @override
  String get adminBackupPoolDocumentMissing =>
      'Yedek dosyasında havuz belgesi bulunamadı.';

  @override
  String get adminBackupItemsListMissing =>
      'Yedek dosyasında \"items\" listesi yok.';

  @override
  String get adminBackupContainsUnreadableRecords =>
      'Yedekte okunamayan kayıt var; dosya değiştirilmemiş olmalı.';

  @override
  String get adminUnknownPool => 'bilinmeyen havuz';

  @override
  String get adminRestoreBackupTitle => 'Yedeği geri yükle';

  @override
  String adminRestoreBackupDialogBody(
    Object fileName,
    Object sourcePool,
    Object selectedPool,
    int itemCount,
    Object warningText,
  ) {
    return 'Dosya: $fileName\nYedekteki havuz: $sourcePool\nSeçili havuz: $selectedPool\nKayıt sayısı: $itemCount\n\n${warningText}Bu kayıtlar seçili havuza yazılacak. Devam edilsin mi?';
  }

  @override
  String get adminRestoreBackupDifferentPoolWarning =>
      'Uyarı: Yedek farklı bir havuzdan geliyor.';

  @override
  String adminRestoreFromBackupAction(Object fileName) {
    return 'Yedekten geri yükleme ($fileName)';
  }

  @override
  String get adminRestoreBackupFailed => 'Yedek dosyası geri yüklenemedi.';

  @override
  String get adminRequiresManagerOrFullAccessForMissingSeed =>
      'Eksik kayıt ekleme için manager veya tam yetki gerekir.';

  @override
  String get adminRequiresFullAccessForReset =>
      'Tam sıfırlama için tam yetki gerekir.';

  @override
  String get adminBulkPreviewFailed => 'Toplu işlem ön izlemesi alınamadı.';

  @override
  String get adminSeedAllPoolsTitle => 'Tüm havuzları tohumla';

  @override
  String adminMergeSeedPreview(
    int poolCount,
    int changedPoolCount,
    int addedItemCount,
    int targetItemCount,
  ) {
    return 'Ön izleme:\n• Kontrol edilen havuz: $poolCount\n• Değişecek havuz: $changedPoolCount\n• Eklenecek kayıt: $addedItemCount\n• İşlem sonrası toplam kayıt: $targetItemCount\n\nMevcut manuel değişiklikler korunur. Devam edilsin mi?';
  }

  @override
  String adminResetSeedPreview(
    int poolCount,
    int changedPoolCount,
    int currentItemCount,
    int targetItemCount,
  ) {
    return 'Ön izleme:\n• Kontrol edilen havuz: $poolCount\n• Üzerine yazılacak havuz: $changedPoolCount\n• Mevcut kayıt: $currentItemCount\n• Yeni kayıt: $targetItemCount\n\nMevcut içerik silinir. Önce yedek aldığından emin ol. Devam edilsin mi?';
  }

  @override
  String get adminOverwriteAction => 'Üzerine yaz';

  @override
  String get adminMissingItemsAddedToPools => 'Eksik öğeler havuzlara eklendi.';

  @override
  String get adminAllPoolsOverwritten => 'Tüm havuzlar yeniden yazıldı.';

  @override
  String get adminAuditAddMissingToAllPools => 'Tüm havuzlara eksikleri ekle';

  @override
  String get adminAuditResetAllPools => 'Tüm havuzları sıfırla';

  @override
  String get adminInspireCardsUnavailable =>
      'Keşfet kartları şu anda alınamıyor.';

  @override
  String get adminRequiresManagerOrFullAccessForDiagnostics =>
      'Tanı işlemleri için manager veya tam yetki gerekir.';

  @override
  String get adminNotificationLogsCleared => 'Bildirim logları temizlendi.';

  @override
  String adminNotificationLogsShareText(Object timestamp) {
    return 'Arın bildirim logları ($timestamp)';
  }

  @override
  String get adminNotificationLogsShareSubject => 'Arın bildirim tanısı';

  @override
  String adminLogExportFailed(Object error) {
    return 'Log dışa aktarımı başarısız: $error';
  }

  @override
  String get adminInspireCardHasEmptyTurkishText =>
      'Boş Türkçe metinli kart var; doldur veya sil.';

  @override
  String get adminReviewCardsBeforeSaveTitle =>
      'Kartları kaydetmeden önce kontrol';

  @override
  String get adminInspireCardsWillBeUpdated => 'Keşfet kartları güncellenecek';

  @override
  String get adminInspireCardsSaved => 'Keşfet kartları kaydedildi.';

  @override
  String get adminInspireCardsSaveFailed => 'Keşfet kartları kaydedilemedi.';

  @override
  String get adminAuditInspireCardsUpdated => 'Keşfet kartları güncellendi';

  @override
  String adminCurrentRecordCount(int count) {
    return 'Mevcut kayıt: $count';
  }

  @override
  String adminRecordCountToSave(int count) {
    return 'Kaydedilecek kayıt: $count';
  }

  @override
  String adminChangedRowCount(int count) {
    return 'Değişen satır: $count';
  }

  @override
  String get adminConcurrentEditWarning =>
      'Başka bir yönetici bu sırada kayıt yaptıysa sistem uyarı verir.';

  @override
  String get adminSaveAction => 'Kaydet';

  @override
  String get adminGrantsListFetchFailed => 'Yetki listesi alınamadı.';

  @override
  String get adminGrantAccessAction => 'Yetki ver';

  @override
  String get adminEditGrantAction => 'Yetkiyi düzenle';

  @override
  String get adminEmailOrUidLabel => 'E-posta veya UID';

  @override
  String get adminLevelLabel => 'Seviye';

  @override
  String get adminRoleContentLabel => 'content - içerik';

  @override
  String get adminRoleManagerLabel => 'manager - operasyon';

  @override
  String get adminRoleDeveloperLabel => 'developer - tam yetki';

  @override
  String get adminFullAccessRequiredForGrantManagement =>
      'Yetki yönetimi için tam yetki gerekir.';

  @override
  String get adminEmailOrUidCannotBeEmpty => 'E-posta veya UID boş olamaz.';

  @override
  String get adminAccountAlreadyFullAccess =>
      'Bu hesap uygulama içinde zaten tam yetkilidir.';

  @override
  String get adminGrantSaved => 'Yetki kaydedildi.';

  @override
  String get adminGrantSaveFailed => 'Yetki kaydedilemedi.';

  @override
  String get adminAuditGrantSaved => 'Admin yetkisi verildi/güncellendi';

  @override
  String get adminFullAccessAccountCannotBeRemoved =>
      'Bu hesap uygulama içinde tam yetkilidir; panelden kaldırılamaz.';

  @override
  String get adminRemoveGrantTitle => 'Yetkiyi kaldır';

  @override
  String adminRemoveGrantMessage(Object label) {
    return '$label için yönetim yetkisi kaldırılacak.';
  }

  @override
  String get adminGrantRemoved => 'Yetki kaldırıldı.';

  @override
  String get adminGrantRemoveFailed => 'Yetki kaldırılamadı.';

  @override
  String get adminAuditGrantRemoved => 'Admin yetkisi kaldırıldı';

  @override
  String get adminEditItemTitle => 'Öğeyi düzenle';

  @override
  String get adminAddItemTitle => 'Öğe ekle';

  @override
  String get adminWordLabel => 'Söz';

  @override
  String get adminTextLabel => 'Metin';

  @override
  String get adminTurkishTextLabel => 'Türkçe metin';

  @override
  String get adminTurkishLabel => 'Türkçe';

  @override
  String get adminArabicLabel => 'Arapça';

  @override
  String get adminTypeLabel => 'Tür';

  @override
  String get adminReferenceLabel => 'Referans';

  @override
  String get adminTitleLabel => 'Başlık';

  @override
  String get adminOptionalSourceReferenceLabel =>
      'Kaynak / referans (isteğe bağlı)';

  @override
  String get adminWordCannotBeEmpty => 'Söz boş olamaz.';

  @override
  String get adminTextCannotBeEmpty => 'Metin boş olamaz.';

  @override
  String get adminTurkishTextCannotBeEmpty => 'Türkçe metin boş olamaz.';

  @override
  String get adminTurkishAndArabicRequired =>
      'Türkçe ve Arapça alanları gerekli.';

  @override
  String get adminTurkishArabicReferenceRequired =>
      'Türkçe, Arapça ve referans gerekli.';

  @override
  String get adminTitleAndTextRequired => 'Başlık ve metin gerekli.';

  @override
  String get adminPoolItemWillBeEdited => 'Havuz öğesi düzenlenecek';

  @override
  String get adminNewPoolItemWillBeAdded => 'Havuza yeni öğe eklenecek';

  @override
  String get adminVersionConflictError =>
      'Bu içerik başka bir yönetici tarafından güncellenmiş. Lütfen yenileyip tekrar dene.';

  @override
  String get adminNoPermissionForOperation => 'Bu işlem için yetkiniz yok.';

  @override
  String get adminNetworkOrServiceUnavailable =>
      'İnternet bağlantısı zayıf veya servis geçici olarak kapalı.';

  @override
  String get adminOperationTimedOut =>
      'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';

  @override
  String get adminSessionCouldNotBeVerified =>
      'Oturum doğrulanamadı. Lütfen tekrar giriş yapın.';

  @override
  String get adminAuthorizationCouldNotBeVerified => 'Yetki doğrulanamadı';

  @override
  String get adminAuthorizationCheckUnavailable =>
      'Şu anda yetki kontrolü yapılamıyor.\nİnternet bağlantını kontrol edip tekrar dene.';

  @override
  String get adminBackToSettings => 'Ayarlara dön';

  @override
  String get adminNoAccessTitle => 'Erişim yok';

  @override
  String get adminPageForAdminsOnly => 'Bu sayfa yalnızca yöneticiler içindir.';

  @override
  String get adminPanelTitle => 'Yönetim paneli';

  @override
  String get adminPoolsTab => 'Havuzlar';

  @override
  String get adminInspireCardsTab => 'Keşfet kartları';

  @override
  String get adminDiagnosticsTab => 'Tanı & log';

  @override
  String get adminDeveloperTab => 'Geliştirici';

  @override
  String get adminGrantsTab => 'Yetkiler';

  @override
  String get adminSectionOnlyForFullAccess =>
      'Bu bölüm yalnızca tam yetkiye açıktır.';

  @override
  String get adminDeveloperToolsDeveloperOnly =>
      'Geliştirici araçlarını sadece developer seviyesi kullanabilir.';

  @override
  String get adminDeletePoolItemTitle => 'Öğeyi havuzdan sil';

  @override
  String adminDeletePoolItemMessage(Object poolId) {
    return 'Bu öğe \"$poolId\" havuzundan kalıcı olarak silinecek ve Firestore’a hemen yazılacak. Geri alınamaz.';
  }

  @override
  String get adminPoolItemWillBeDeleted => 'Havuzdan öğe silinecek';

  @override
  String get adminRemoveCardFromListTitle => 'Kartı listeden çıkar';

  @override
  String get adminRemoveCardFromListMessage =>
      'Kart yerel listeden silinecek. Değişiklik Firestore’a yansımak için \"Kaydet\"e basman gerekir.';

  @override
  String get adminRemoveAction => 'Çıkar';

  @override
  String get adminDiagnosticsAccessDeniedTitle =>
      'Tanı ekranı manager ve tam yetkiye açıktır.';

  @override
  String get adminDiagnosticsAccessDeniedSubtitle =>
      'İçerik yöneticileri havuz ve Keşfet düzenleyebilir.';

  @override
  String get adminRoleContentPlain => 'İçerik';

  @override
  String get adminRoleManagerPlain => 'Yönetici';

  @override
  String get adminRoleDeveloperPlain => 'Geliştirici';

  @override
  String get adminRoleNonePlain => 'Yok';

  @override
  String get adminGrantManagementAccessDeniedTitle =>
      'Yetki yönetimi yalnızca tam yetkiye açıktır.';

  @override
  String get adminGrantManagementAccessDeniedSubtitle =>
      'Admin seviyesi verme ve kaldırma işlemlerini developer yapar.';

  @override
  String get adminGrantHint =>
      'E-posta veya UID girip content, manager ya da developer seviyesi verebilirsin.';

  @override
  String adminFixedFullAccess(Object emails) {
    return 'Sabit tam yetkililer: $emails';
  }

  @override
  String adminDefinedGrants(int count) {
    return 'Tanımlı yetkiler ($count)';
  }

  @override
  String get adminGrantsLoading => 'Yetkiler yükleniyor...';

  @override
  String get adminNoFirestoreGrantsYet =>
      'Henüz Firestore üzerinden eklenmiş yetki yok.';

  @override
  String get surveyBack => 'Geri';

  @override
  String get surveyNext => 'Devam Et';

  @override
  String get namazIbadetWarningTitle => 'Dikkat';

  @override
  String get namazIbadetWarningSubtitle =>
      'Namaz takibi bir gösteriş alanı değil; kalbini huşû ve dürüstlükle düzenlemek içindir.';

  @override
  String get namazIbadetWarningBullet1 =>
      'Tikleri yalnızca kendin için işaretle; riya veya başkasına baskı aracı olmasın.';

  @override
  String get namazIbadetWarningBullet2 =>
      'Vakit kaçırınca kendini küçümseme; her dönüş tövbe ve yeniden başlamaktır.';

  @override
  String get namazIbadetWarningBullet3 =>
      'Bildirimleri istediğin zaman sistem ayarlarından yönetebilirsin; takip yük olmamalı.';

  @override
  String get namazIbadetCommitmentTitle => 'Kendine sözün';

  @override
  String get namazIbadetCommitmentHint =>
      'Namazına dair içten bir cümle yaz (en az 8 karakter).';

  @override
  String get namazIbadetCommitmentFieldHint => 'Kalbinden geçen bir cümle…';

  @override
  String get namazIbadetCommitmentTooShort =>
      'Lütfen kendine bir söz yaz (en az 8 karakter).';

  @override
  String get namazIbadetSealTitlePrefix => 'Sözünü mühürle';

  @override
  String get namazIbadetSealHoldHint => 'Parmağını basılı tut';

  @override
  String get namazIbadetSealSuccess =>
      'Sözün kaydedildi. İbadet ekranına geçiyorsun.';

  @override
  String get namazIbadetSealEncourageNotHolding =>
      'Hazır olduğunda mührü basılı tutarak pekiştir.';

  @override
  String get namazIbadetSealEncourageHolding =>
      'Nefesini yavaşlat, sözünü kalbine indir.';

  @override
  String get namazIbadetPrepTitle => 'Hazırlık';

  @override
  String get namazIbadetExamplesTitle => 'Örnekler';

  @override
  String get closeAction => 'Kapat';

  @override
  String get saveAction => 'Kaydet';

  @override
  String get selectAction => 'Seç';

  @override
  String get quitPickerTemplateAlreadyExists =>
      'Bu program zaten listenizde; aynı şablondan yalnızca bir tane olabilir.';

  @override
  String get quitPickerOpenAction => 'Aç';

  @override
  String get quitPickerGoToListAction => 'Listeye git';

  @override
  String get quitPickerTemplateScreenTitle => 'Ekrandan arınma';

  @override
  String get quitPickerTemplateSmokingTitle => 'Sigaradan arınma';

  @override
  String get quitPickerTemplateAlcoholTitle => 'Alkolden arınma';

  @override
  String get quitPickerTemplateSubstanceTitle => 'Uyuşturucudan arınma';

  @override
  String get quitPickerTemplateZinaTitle => 'Zinadan arınma';

  @override
  String get quitPickerHeaderTitle => 'Kötü alışkanlıklardan arınma';

  @override
  String get quitPickerHeaderSubtitle =>
      'Kurtulmak istediğin alışkanlığı seç; özel bir hedef için alttaki kutuyu kullan.';

  @override
  String get quitPickerScreenLabel => 'Ekran';

  @override
  String get quitPickerScreenSubtitle => 'Sınır ve dinginlik';

  @override
  String get quitPickerSmokingLabel => 'Sigara';

  @override
  String get quitPickerAlcoholLabel => 'Alkol';

  @override
  String get quitPickerSubstanceLabel => 'Uyuşturucu';

  @override
  String get quitPickerSubstanceSubtitle => 'Destek ve takip';

  @override
  String get quitPickerZinaLabel => 'Zina';

  @override
  String get quitPickerDefaultSubtitle => 'Arınma programı';

  @override
  String get quitPickerAlreadyAdded => 'Zaten ekli';

  @override
  String get quitPickerAddCustomTitle => 'Özel ekle';

  @override
  String get quitPickerAddCustomSubtitle => 'Kendi arınma rutinini oluştur.';

  @override
  String get buildProgramSetupQuranTitle => 'Günlük Kur\'an programı';

  @override
  String get buildProgramSetupDefaultTitle => 'Program';

  @override
  String get buildProgramSetupHeadlineQuran => 'Her güne bir sayfa';

  @override
  String get buildProgramSetupHeadlineDefault => 'Programını başlat';

  @override
  String get buildProgramSetupBadge => 'Hazırlık adımı';

  @override
  String get buildProgramSetupBodyQuran =>
      'En az bir sayfa — küçük ama süreklilik. İlerleme ve ipuçları bir sonraki ekranda seni bekliyor.';

  @override
  String get buildProgramSetupBodyDefault =>
      'İlerleme ve ipuçları bir sonraki ekranda.';

  @override
  String get buildProgramSetupAlreadyActive =>
      'Günlük Kur\'an programın zaten açık. Mevcut programa yönlendirildi.';

  @override
  String get buildProgramSetupQuranHabitTitle => 'Günlük Kur\'an';

  @override
  String get buildProgramSetupStartAction => 'Programı başlat';

  @override
  String get buildProgramSetupPrincipleTitle =>
      'Azı sürekli, çoğu terkten hayırlı';

  @override
  String get buildProgramSetupPrincipleQuote =>
      'Hz. Peygamber (s.a.v.): \"Amellerin Allah\'a en sevimli olanı, az da olsa devamlı olanıdır.\"';

  @override
  String get buildProgramDetailNotFound => 'Program bulunamadı';

  @override
  String get buildProgramDetailTabGeneral => 'Genel';

  @override
  String get buildProgramDetailTabTips => 'İpuçları';

  @override
  String get buildProgramDetailTabProgress => 'İlerleme';

  @override
  String get buildProgramDetailTodayQuestion =>
      'Bugün okuma hedefini tamamladın mı?';

  @override
  String get buildProgramDetailTodayDone => 'Bugün tamamlandı';

  @override
  String get buildProgramDetailTodayPending =>
      'Bugün henüz işaretlenmedi — dokun';

  @override
  String buildProgramDetailDayCount(int days) {
    return '$days. gün';
  }

  @override
  String get buildProgramDetailProgressIndicatorLabel =>
      'Motivasyonel ilerleme göstergesi';

  @override
  String buildProgramDetailRoutinePercent(int percent) {
    return '%$percent rutin oturumu';
  }

  @override
  String buildProgramDetailMilestoneLabel(int day, int percent) {
    return '$day. gün — %$percent';
  }

  @override
  String get buildProgramDetailDisclaimer =>
      'Bu göstergeler genel motivasyon içindir; bilimsel veya tıbbi ölçüm değildir.';

  @override
  String get onboardingSlide1Title => 'Gürültünün içinde bir nefes';

  @override
  String get onboardingSlide1Subtitle =>
      'Zihin koştururken iç sesin çoğu zaman fısıltıda kalır. Küçük duruşlar — bir nefes, bir anlık duraklama — manevi dengeyi yeşertir; dışarıda aradığın huzur, bazen önce içerde sessizce filizlenir.';

  @override
  String get onboardingSlide2Title => 'Küçük başla, istikrarla büyü';

  @override
  String get onboardingSlide2Subtitle =>
      'Gelişim ve Arınma’da alışkanlıklarını kayıt altına al. Bir gün, bir nefes, bir seçim — zinciri kırmadan ilerle; arınma da merdiven çıkmak gibi, basamak basamak güçlenir.';

  @override
  String get onboardingSlide3Title => 'Vakit, namaz ve günlük düzen';

  @override
  String get onboardingSlide3Subtitle =>
      'Namaz saatlerini yanında tut; nefes egzersizi ve güçlenme alanın zor anlarda yanında olsun. İbadetini, takibini ve iç sesini aynı ritimde topla.';

  @override
  String get onboardingSlide4Title => 'Arın: tek uygulamada bir arada';

  @override
  String get onboardingSlide4Subtitle =>
      'İlhamdan günlük alışkanlığa, vakit bildiriminden arınma sayacına kadar yolculuğun burada. Hazırsan birlikte başlayalım — sen yürü, biz hatırlatır ve eşlik ederiz.';

  @override
  String get onboardingGetStarted => 'Başlayalım';

  @override
  String get onboardingSkip => 'Geç';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get surveyNameTitle => 'Sana nasıl hitap edelim?';

  @override
  String get surveyNameHint => 'İsminiz';

  @override
  String get surveyGenderTitle => 'Cinsiyetini öğrenebilir miyiz?';

  @override
  String get surveyGenderSubtitle => 'Sana daha iyi yardımcı olabilmek için...';

  @override
  String get surveyGenderMale => 'Erkek';

  @override
  String get surveyGenderFemale => 'Kadın';

  @override
  String get surveyMoodTitle => 'Şu an iç dünyanda hangi ton daha baskın?';

  @override
  String get surveyMoodSubtitle =>
      'Kendini tanımlayan işaretleri seç; içerik ve hatırlatmalar buna göre yumuşar.';

  @override
  String get surveyDailyRhythmTitle =>
      'Günün büyük kısmı genelde nerede akıyor?';

  @override
  String get surveyDailyRhythmSubtitle =>
      'Tempo ve ortam, sana uygun ritmi anlamamıza yardım eder.';

  @override
  String get surveyInnerThemesTitle =>
      'İç dünyanda öne çıkan temalar hangileri?';

  @override
  String get surveyInnerThemesSubtitle =>
      'Birden fazla seçebilirsin; samimi işaretler bize seni daha iyi tanıtmaya yardım eder.';

  @override
  String get surveyNotificationTitle => 'Bildirimler';

  @override
  String get surveyNotificationLead =>
      'Namaz hatırlatmaları ve günün mesajları zamanında ulaşsın.';

  @override
  String get surveyNotificationSubtitle =>
      'Vakit bildirimleri ile içerik önerilerinin kaçmaması için bildirim iznine ihtiyacımız var. İstediğin zaman ayarlardan kapatabilirsin.';

  @override
  String get surveyNotificationAllow => 'Devam Et';

  @override
  String get surveyNotificationSkip => 'Şimdilik geç';

  @override
  String get surveyNotificationOpenSettings => 'Ayarlardan aç';

  @override
  String get surveySave => 'Başla ➔';

  @override
  String get surveyGenderDecline => 'Paylaşmak istemiyorum';

  @override
  String get surveyNameGreetingPrefix => 'Merhaba';

  @override
  String get surveySummaryTitle => 'Hazırsın';

  @override
  String get surveySummarySubtitle =>
      'Temel tercihlerini kaydettik. Arın deneyimini bu işaretlere göre şekillendireceğiz.';

  @override
  String get surveySummaryCardTitle => 'Başlangıç özeti';

  @override
  String get surveySummaryItemName => 'Hitap';

  @override
  String get surveySummaryItemMood => 'Ruh hali işaretlerin';

  @override
  String get surveySummaryItemRhythm => 'Günlük akış işaretlerin';

  @override
  String get surveySummaryItemThemes => 'İç tema işaretlerin';

  @override
  String get surveySummaryItemNotificationOn => 'Açık';

  @override
  String get surveySummaryItemNotificationOff => 'Kapalı';

  @override
  String get surveySummaryNotProvided => 'Belirtilmedi';

  @override
  String get surveySummaryAction => 'Ana ekrana geç';

  @override
  String get surveySummarySaveError =>
      'Başlangıç kaydedilemedi. Lütfen tekrar dene.';

  @override
  String get premiumLegalPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get premiumLegalTermsOfUse => 'Kullanım Şartları';

  @override
  String get premiumLinkOpenFailed => 'Bağlantı açılamadı. Lütfen tekrar dene.';

  @override
  String get moodHappy => 'Mutlu';

  @override
  String get moodCalm => 'Sakin';

  @override
  String get moodStressed => 'Stresli';

  @override
  String get moodSad => 'Üzgün';

  @override
  String get moodGrateful => 'Şükrediyorum';

  @override
  String get moodAnxious => 'Kaygılı';

  @override
  String get moodMotivated => 'Motive';

  @override
  String get sectorStudent => 'Lise / Üniversite / Hazırlık';

  @override
  String get sectorPrivate => 'Özel Sektör';

  @override
  String get sectorPublic => 'Kamu Personeli';

  @override
  String get sectorBusiness => 'Kendi İşim / Serbest';

  @override
  String get sectorTrade => 'Ticaret';

  @override
  String get sectorHousehold => 'Ev Hanımı / Ev Erkeği';

  @override
  String get sectorOther => 'Diğer';

  @override
  String get needMotivation => 'Motivasyon';

  @override
  String get needSabr => 'Sabır';

  @override
  String get needShukr => 'Şükür';

  @override
  String get needTawakkul => 'Tevekkül';

  @override
  String get needFocus => 'Odaklanma';

  @override
  String get needHealing => 'Şifa';

  @override
  String get needRizq => 'Rızık & Bereket';

  @override
  String get appPrepareTitle => 'Arına hazırlanıyoruz';

  @override
  String get appPrepareSubtitle =>
      'Namaz vakitleri ve günün sözleri senin için yükleniyor…';

  @override
  String get shellExitConfirmBackTwice =>
      'Çıkmak için geri tuşuna bir kez daha basın';

  @override
  String get inspireExploreTitle => 'Keşfet';

  @override
  String get inspireSearchHint => 'Ara';

  @override
  String get inspireFilterTooltip => 'İçerik türü';

  @override
  String get inspireFilterMainFeed => 'Ana akış';

  @override
  String get inspireFilterQuote => 'Söz';

  @override
  String get inspireFilterVerse => 'Ayet';

  @override
  String get inspireFilterHadith => 'Hadis';

  @override
  String get inspireSearchNoResults =>
      'Bu aramaya uygun içerik yok.\nFarklı kelime veya\nşekilsiz yazım deneyin\n(ör. karde, kardes → kardeş).';

  @override
  String get inspireEmptyTitle => 'Henüz içerik yok';

  @override
  String get inspireEmptySubtitle =>
      'Görseller: assets/inspiration/ (1.jpg, 2.jpg, …).\nİçerik: assets/data/inspiration/*.json veya Firestore app_public/inspiration_cards.';

  @override
  String get inspirePullToRefreshHint => 'Yenilemek için aşağı çekin.';

  @override
  String get inspireLoadFailedTitle => 'Yüklenemedi';

  @override
  String get inspirePullToRetryHint => 'Tekrar denemek için aşağı çekin.';

  @override
  String get viewerBackAction => 'Geri';

  @override
  String get viewerNoCard => 'Kart yok';

  @override
  String get asyncErrorDefaultTitle => 'Bir şeyler ters gitti';

  @override
  String get asyncErrorDefaultMessage =>
      'Bağlantın zayıf olabilir ya da hizmete şu an ulaşamıyoruz. Az sonra tekrar dene.';

  @override
  String get asyncErrorRetryAction => 'Tekrar dene';

  @override
  String get asyncErrorTechnicalDetailsTitle => 'Teknik ayrıntı';

  @override
  String get asyncErrorCopiedToClipboard => 'Hata panoya kopyalandı.';

  @override
  String get savedInspirationTitle => 'Kaydedilenler';

  @override
  String get savedInspirationLoadFailedPrefix => 'Yüklenemedi';

  @override
  String get savedInspirationEmptyTitle => 'Kalp defterin boş';

  @override
  String get savedInspirationEmptySubtitle =>
      'Keşfet\'te sana dokunan sözü kaydet; burada toplanıp sana dönüş olsun.';

  @override
  String get savedInspirationGoExploreAction => 'Keşfet\'e git';

  @override
  String get clockPickerCancelAction => 'İptal';

  @override
  String get clockPickerConfirmAction => 'Tamam';

  @override
  String get clockPickerHourLabel => 'Saat';

  @override
  String get clockPickerMinuteLabel => 'Dakika';

  @override
  String get salatWeekCelebrationTitle => 'Haftayı tamamladın';

  @override
  String get salatWeekCelebrationAction => 'Elhamdülillah';

  @override
  String get adminEmailInviteLabel => 'E-posta daveti';
}
