import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @languageSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil ayarları'**
  String get languageSettingsTitle;

  /// No description provided for @languageSettingsSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dili'**
  String get languageSettingsSheetTitle;

  /// No description provided for @languageTurkishLabel.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get languageTurkishLabel;

  /// No description provided for @languageEnglishLabel.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get languageEnglishLabel;

  /// No description provided for @languageArabicLabel.
  ///
  /// In tr, this message translates to:
  /// **'Arapça'**
  String get languageArabicLabel;

  /// No description provided for @settingsPageHeader.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsPageHeader;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionPrayerTimes.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakitleri'**
  String get settingsSectionPrayerTimes;

  /// No description provided for @settingsSectionApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama'**
  String get settingsSectionApp;

  /// No description provided for @settingsSectionSession.
  ///
  /// In tr, this message translates to:
  /// **'Oturum'**
  String get settingsSectionSession;

  /// No description provided for @settingsMenuNotificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz, arınma ve zikir'**
  String get settingsMenuNotificationsSubtitle;

  /// No description provided for @settingsMenuNotificationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get settingsMenuNotificationsTitle;

  /// No description provided for @settingsMenuAboutTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get settingsMenuAboutTitle;

  /// No description provided for @settingsMenuAboutSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama bilgileri'**
  String get settingsMenuAboutSubtitle;

  /// No description provided for @settingsMenuPrivacyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get settingsMenuPrivacyTitle;

  /// No description provided for @settingsMenuPrivacySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Verilerinizi nasıl işlediğimiz'**
  String get settingsMenuPrivacySubtitle;

  /// No description provided for @settingsMenuSavedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilenler'**
  String get settingsMenuSavedTitle;

  /// No description provided for @settingsMenuSavedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet’te kaydettiğin sözler'**
  String get settingsMenuSavedSubtitle;

  /// No description provided for @settingsMenuAdminTitle.
  ///
  /// In tr, this message translates to:
  /// **'İçerik yönetimi'**
  String get settingsMenuAdminTitle;

  /// No description provided for @settingsMenuAdminSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Söz havuzları ve Keşfet'**
  String get settingsMenuAdminSubtitle;

  /// No description provided for @settingsMenuContactTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bize ulaşın'**
  String get settingsMenuContactTitle;

  /// No description provided for @settingsMenuContactSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Destek ve geri bildirim'**
  String get settingsMenuContactSubtitle;

  /// No description provided for @settingsMenuSupportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arın’a Destek Ol'**
  String get settingsMenuSupportTitle;

  /// No description provided for @settingsMenuSupportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tek seferlik destek paketleri'**
  String get settingsMenuSupportSubtitle;

  /// No description provided for @settingsMenuComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'E-posta ile direkt yaz'**
  String get settingsMenuComingSoon;

  /// No description provided for @settingsContactPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bize ulaşın'**
  String get settingsContactPageTitle;

  /// No description provided for @settingsContactSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Öneri, hata bildirimi veya destek talebini doğrudan bize e-posta ile iletebilirsin.'**
  String get settingsContactSubtitle;

  /// No description provided for @settingsContactOpenMailAction.
  ///
  /// In tr, this message translates to:
  /// **'Mail uygulamasını aç'**
  String get settingsContactOpenMailAction;

  /// No description provided for @settingsContactCopyMailAction.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresini kopyala'**
  String get settingsContactCopyMailAction;

  /// No description provided for @settingsContactEmailCopied.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi kopyalandı.'**
  String get settingsContactEmailCopied;

  /// No description provided for @settingsContactOpenFailed.
  ///
  /// In tr, this message translates to:
  /// **'Mail uygulaması açılamadı. Adresi kopyalayıp manuel gönderebilirsin.'**
  String get settingsContactOpenFailed;

  /// No description provided for @settingsContactCopyFailed.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi kopyalanamadı. Lütfen manuel olarak yazın: arinapphelp@gmail.com'**
  String get settingsContactCopyFailed;

  /// No description provided for @settingsContactMailSubject.
  ///
  /// In tr, this message translates to:
  /// **'Arın uygulaması geri bildirimi'**
  String get settingsContactMailSubject;

  /// No description provided for @settingsContactMailBody.
  ///
  /// In tr, this message translates to:
  /// **'Selam Arın ekibi,\n\n'**
  String get settingsContactMailBody;

  /// No description provided for @settingsGuestHint.
  ///
  /// In tr, this message translates to:
  /// **'Misafir — veriler bu cihazda. Buluta kaydetmek için giriş yapın.'**
  String get settingsGuestHint;

  /// No description provided for @settingsAccountFallback.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get settingsAccountFallback;

  /// No description provided for @settingsSignInGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile giriş'**
  String get settingsSignInGoogle;

  /// No description provided for @settingsSignInApple.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile giriş'**
  String get settingsSignInApple;

  /// No description provided for @settingsSessionHint.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı sıfırlamak veya hesabı kaldırmak için:'**
  String get settingsSessionHint;

  /// No description provided for @settingsSignOutAction.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get settingsSignOutAction;

  /// No description provided for @settingsDeleteAccountAction.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı ve verileri tamamen sil'**
  String get settingsDeleteAccountAction;

  /// No description provided for @settingsLightThemeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Açık tema'**
  String get settingsLightThemeTitle;

  /// No description provided for @settingsLightThemeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Daha kapalı açık zemin; okuması rahat'**
  String get settingsLightThemeSubtitle;

  /// No description provided for @settingsProvinceLabel.
  ///
  /// In tr, this message translates to:
  /// **'İl'**
  String get settingsProvinceLabel;

  /// No description provided for @settingsProvinceHint.
  ///
  /// In tr, this message translates to:
  /// **'Yazın; örn. \"ko\" → Kocaeli'**
  String get settingsProvinceHint;

  /// No description provided for @settingsProvinceInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Listeden bir il seçin veya yazmaya devam edin.'**
  String get settingsProvinceInvalid;

  /// No description provided for @settingsLocationUpdatedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Konum güncellendi: {city}'**
  String settingsLocationUpdatedMessage(Object city);

  /// No description provided for @settingsLocationFailedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı; izin veya GPS’i kontrol edin.'**
  String get settingsLocationFailedMessage;

  /// No description provided for @settingsProvinceUpdatedMessage.
  ///
  /// In tr, this message translates to:
  /// **'{province} — namaz vakitleri güncellendi'**
  String settingsProvinceUpdatedMessage(Object province);

  /// No description provided for @settingsSignOutDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get settingsSignOutDialogTitle;

  /// No description provided for @settingsSignOutDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Bilgilendirme slaytlarından başlayarak uygulama sıfırlanır. Bu cihazdaki tüm yerel veriler silinir; Firebase oturumunuz kapanır.'**
  String get settingsSignOutDialogBody;

  /// No description provided for @settingsDialogCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get settingsDialogCancel;

  /// No description provided for @settingsDeleteAllDataDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verileri sil'**
  String get settingsDeleteAllDataDialogTitle;

  /// No description provided for @settingsDeleteAllDataDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Misafir modundasınız. Bu cihazdaki tüm uygulama verileri kalıcı olarak silinir ve bilgilendirme ekranlarına dönersiniz.'**
  String get settingsDeleteAllDataDialogBody;

  /// No description provided for @settingsDeleteAction.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get settingsDeleteAction;

  /// No description provided for @settingsDeleteAccountDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı kalıcı sil'**
  String get settingsDeleteAccountDialogTitle;

  /// No description provided for @settingsDeleteAccountDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Bulut hesabınız silinir; bu cihazdaki tüm yerel veriler de temizlenir. Geri alınamaz.'**
  String get settingsDeleteAccountDialogBody;

  /// No description provided for @settingsDeleteProgressMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bulut ve cihaz verileriniz siliniyor…'**
  String get settingsDeleteProgressMessage;

  /// No description provided for @settingsCloudDeleteFailedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bulut verileriniz silinemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.'**
  String get settingsCloudDeleteFailedMessage;

  /// No description provided for @settingsAccountDeleteFailedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silinemedi.'**
  String get settingsAccountDeleteFailedMessage;

  /// No description provided for @settingsAccountDeleteRetryMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silinemedi. Lütfen biraz sonra tekrar deneyin.'**
  String get settingsAccountDeleteRetryMessage;

  /// No description provided for @settingsGoogleSignInSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Google ile giriş yapıldı.'**
  String get settingsGoogleSignInSuccess;

  /// No description provided for @settingsGoogleSignInCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Google ile giriş iptal edildi.'**
  String get settingsGoogleSignInCancelled;

  /// No description provided for @settingsGoogleSignInFailed.
  ///
  /// In tr, this message translates to:
  /// **'Google ile giriş yapılamadı. Lütfen tekrar deneyin.'**
  String get settingsGoogleSignInFailed;

  /// No description provided for @settingsAppleSignInSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile giriş yapıldı.'**
  String get settingsAppleSignInSuccess;

  /// No description provided for @settingsAppleSignInFailed.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile giriş yapılamadı. Lütfen tekrar deneyin.'**
  String get settingsAppleSignInFailed;

  /// No description provided for @settingsAuthServiceUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Giriş servisine şu anda ulaşılamıyor. Lütfen birazdan tekrar deneyin.'**
  String get settingsAuthServiceUnavailable;

  /// No description provided for @homeGreetingNight.
  ///
  /// In tr, this message translates to:
  /// **'Hayırlı Geceler'**
  String get homeGreetingNight;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In tr, this message translates to:
  /// **'Hayırlı Sabahlar'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingNoon.
  ///
  /// In tr, this message translates to:
  /// **'Hayırlı Öğlenler'**
  String get homeGreetingNoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In tr, this message translates to:
  /// **'Hayırlı Akşamlar'**
  String get homeGreetingEvening;

  /// No description provided for @homeGuestUser.
  ///
  /// In tr, this message translates to:
  /// **'Misafir'**
  String get homeGuestUser;

  /// No description provided for @homePrayerUrgentSemanticsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dikkat, imsak vakti çıkıyor. Güneş doğuşuna {remaining} kaldı'**
  String homePrayerUrgentSemanticsLabel(Object remaining);

  /// No description provided for @homePrayerNextSemanticsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki namaz {nextName}, kalan {remaining}'**
  String homePrayerNextSemanticsLabel(Object nextName, Object remaining);

  /// No description provided for @homePrayerUrgentBadge.
  ///
  /// In tr, this message translates to:
  /// **'Çıkıyor'**
  String get homePrayerUrgentBadge;

  /// No description provided for @homePrayerNextBadge.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki'**
  String get homePrayerNextBadge;

  /// No description provided for @homePrayerTimesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz Vakitleri'**
  String get homePrayerTimesTitle;

  /// No description provided for @homePrayerNextRowHint.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki vakit'**
  String get homePrayerNextRowHint;

  /// No description provided for @homePrayerLoadFailedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakitler yüklenemedi'**
  String get homePrayerLoadFailedTitle;

  /// No description provided for @homePrayerLoadFailedBody.
  ///
  /// In tr, this message translates to:
  /// **'İnternet, konum izni veya seçili ilçe nedeniyle vakitler alınamamış olabilir.'**
  String get homePrayerLoadFailedBody;

  /// No description provided for @homeRetryAction.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get homeRetryAction;

  /// No description provided for @homeChangeDistrictAction.
  ///
  /// In tr, this message translates to:
  /// **'İlçe değiştir'**
  String get homeChangeDistrictAction;

  /// No description provided for @homeOpenSettingsAction.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları aç'**
  String get homeOpenSettingsAction;

  /// No description provided for @homeRemainingPassed.
  ///
  /// In tr, this message translates to:
  /// **'geçti'**
  String get homeRemainingPassed;

  /// No description provided for @homeRemainingFewSeconds.
  ///
  /// In tr, this message translates to:
  /// **'birkaç saniye'**
  String get homeRemainingFewSeconds;

  /// No description provided for @homeRemainingHoursMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{hours} saat {minutes} dakika'**
  String homeRemainingHoursMinutes(int hours, int minutes);

  /// No description provided for @homeRemainingHoursOnly.
  ///
  /// In tr, this message translates to:
  /// **'{hours} saat'**
  String homeRemainingHoursOnly(int hours);

  /// No description provided for @homeRemainingMinutesOnly.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dakika'**
  String homeRemainingMinutesOnly(int minutes);

  /// No description provided for @homeLocationFreshNow.
  ///
  /// In tr, this message translates to:
  /// **'Konum güncel'**
  String get homeLocationFreshNow;

  /// No description provided for @homeLocationFreshMinutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk önce güncellendi'**
  String homeLocationFreshMinutesAgo(int minutes);

  /// No description provided for @homeLocationFreshHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa önce güncellendi'**
  String homeLocationFreshHoursAgo(int hours);

  /// No description provided for @homeLocationFreshDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce güncellendi'**
  String homeLocationFreshDaysAgo(int days);

  /// No description provided for @homeDailyReminderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün hatırlatıcısı'**
  String get homeDailyReminderTitle;

  /// No description provided for @homeNamazSetupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz takibini kur'**
  String get homeNamazSetupTitle;

  /// No description provided for @homeNamazSetupSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum Gelişim sekmesinden yapılır; kurduktan sonra kartın burada otomatik görünür.'**
  String get homeNamazSetupSubtitle;

  /// No description provided for @homeNamazTrackingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz takibi'**
  String get homeNamazTrackingTitle;

  /// No description provided for @homeNamazTrackingProgressLine.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {done}/5 · Detaylar için dokun'**
  String homeNamazTrackingProgressLine(Object done);

  /// No description provided for @onboardingNotificationPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim izni verilmedi. Ezan vakitleri için Ayarlar → Bildirimler\'den açabilirsin.'**
  String get onboardingNotificationPermissionDenied;

  /// No description provided for @onboardingGenderPromptWithName.
  ///
  /// In tr, this message translates to:
  /// **'{name}, cinsiyetinizi öğrenebilir miyiz?'**
  String onboardingGenderPromptWithName(Object name);

  /// No description provided for @onboardingNotificationSkippedWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler kapalı kaldı. Namaz vakitlerinde ezan hatırlatması gelmez — sonra Ayarlar → Bildirimler\'den açabilirsin.'**
  String get onboardingNotificationSkippedWarning;

  /// No description provided for @onboardingOpenNowAction.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi aç'**
  String get onboardingOpenNowAction;

  /// No description provided for @commonPreview.
  ///
  /// In tr, this message translates to:
  /// **'Önizle'**
  String get commonPreview;

  /// No description provided for @commonClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

  /// No description provided for @commonCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get commonCancel;

  /// No description provided for @commonDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get commonDone;

  /// No description provided for @commonBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get commonBack;

  /// No description provided for @prayerNameImsak.
  ///
  /// In tr, this message translates to:
  /// **'İmsak'**
  String get prayerNameImsak;

  /// No description provided for @prayerNameSunrise.
  ///
  /// In tr, this message translates to:
  /// **'Güneş'**
  String get prayerNameSunrise;

  /// No description provided for @prayerNameDhuhr.
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get prayerNameDhuhr;

  /// No description provided for @prayerNameAsr.
  ///
  /// In tr, this message translates to:
  /// **'İkindi'**
  String get prayerNameAsr;

  /// No description provided for @prayerNameMaghrib.
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get prayerNameMaghrib;

  /// No description provided for @prayerNameIsha.
  ///
  /// In tr, this message translates to:
  /// **'Yatsı'**
  String get prayerNameIsha;

  /// No description provided for @reminderOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get reminderOff;

  /// No description provided for @reminderAtExactTime.
  ///
  /// In tr, this message translates to:
  /// **'Tam vakitte'**
  String get reminderAtExactTime;

  /// No description provided for @reminderMinutesBefore.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk önce'**
  String reminderMinutesBefore(int minutes);

  /// No description provided for @reminderCardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her vakit ayrı · Süreleri düzenlemek için dokun'**
  String get reminderCardSubtitle;

  /// No description provided for @reminderFirstOff.
  ///
  /// In tr, this message translates to:
  /// **'1. kapalı'**
  String get reminderFirstOff;

  /// No description provided for @reminderFirstValue.
  ///
  /// In tr, this message translates to:
  /// **'1. {value}'**
  String reminderFirstValue(Object value);

  /// No description provided for @reminderPairSecondOff.
  ///
  /// In tr, this message translates to:
  /// **'{first} · 2. kapalı'**
  String reminderPairSecondOff(Object first);

  /// No description provided for @reminderPairSecondValue.
  ///
  /// In tr, this message translates to:
  /// **'{first} · 2. {second}'**
  String reminderPairSecondValue(Object first, Object second);

  /// No description provided for @reminderPermissionRequiredMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim izni gerekli. Ayarlardan açabilirsin.'**
  String get reminderPermissionRequiredMessage;

  /// No description provided for @reminderPrayerNotificationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakit bildirimi'**
  String get reminderPrayerNotificationTitle;

  /// No description provided for @reminderCardDisabledHint.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı · Anahtarı aç, vakitleri ayarla'**
  String get reminderCardDisabledHint;

  /// No description provided for @reminderLocalNotificationUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu ortamda yerel bildirim yok.'**
  String get reminderLocalNotificationUnavailable;

  /// No description provided for @reminderSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı'**
  String get reminderSectionTitle;

  /// No description provided for @reminderTwoAlertsPerPrayer.
  ///
  /// In tr, this message translates to:
  /// **'Vakit başına iki uyarı'**
  String get reminderTwoAlertsPerPrayer;

  /// No description provided for @reminderPerPrayerDifferentSounds.
  ///
  /// In tr, this message translates to:
  /// **'Vakitlere göre ayrı sesler'**
  String get reminderPerPrayerDifferentSounds;

  /// No description provided for @reminderCurrentSound.
  ///
  /// In tr, this message translates to:
  /// **'Şu an: {summary}'**
  String reminderCurrentSound(Object summary);

  /// No description provided for @reminderUsePhoneDefaultSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefon ayarlarındaki bildirim sesi kullanılır.'**
  String get reminderUsePhoneDefaultSubtitle;

  /// No description provided for @reminderChooseArinSoundsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arın seslerinden seç'**
  String get reminderChooseArinSoundsTitle;

  /// No description provided for @reminderChooseArinSoundsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ezan ve huzur tonlarını dinleyip uygula.'**
  String get reminderChooseArinSoundsSubtitle;

  /// No description provided for @reminderPhoneSoundActiveAllPrayers.
  ///
  /// In tr, this message translates to:
  /// **'Telefondan seçilen ses tüm vakitlerde aktif.'**
  String get reminderPhoneSoundActiveAllPrayers;

  /// No description provided for @reminderApplyOwnSoundAllPrayers.
  ///
  /// In tr, this message translates to:
  /// **'Kendi ses dosyanı tüm vakitlere uygula.'**
  String get reminderApplyOwnSoundAllPrayers;

  /// No description provided for @reminderSetPerPrayerDifferentSound.
  ///
  /// In tr, this message translates to:
  /// **'Vakitlere göre ayrı ses ayarla'**
  String get reminderSetPerPrayerDifferentSound;

  /// No description provided for @reminderAllPrayersSoundTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm vakitler için ses'**
  String get reminderAllPrayersSoundTitle;

  /// No description provided for @reminderAllPrayersSoundSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tek seçim yap; tüm vakitlerde aynı ses çalsın.'**
  String get reminderAllPrayersSoundSubtitle;

  /// No description provided for @reminderBackToSingleSoundSelection.
  ///
  /// In tr, this message translates to:
  /// **'Tek ses seçimine dön'**
  String get reminderBackToSingleSoundSelection;

  /// No description provided for @reminderPerPrayerSavedInstantly.
  ///
  /// In tr, this message translates to:
  /// **'Vakit bazlı seçimler anında kaydedilir.'**
  String get reminderPerPrayerSavedInstantly;

  /// No description provided for @reminderEnableNotificationsAction.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimleri aç'**
  String get reminderEnableNotificationsAction;

  /// No description provided for @reminderDurationsPerPrayerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Her vakit için süreler'**
  String get reminderDurationsPerPrayerTitle;

  /// No description provided for @reminderDurationsPerPrayerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Satıra dokun; 1. ve 2. uyarıyı ayrı seç.'**
  String get reminderDurationsPerPrayerSubtitle;

  /// No description provided for @reminderApplyDurationsAllButton.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğim süreleri tüm vakitlere uygula'**
  String get reminderApplyDurationsAllButton;

  /// No description provided for @reminderAllPrayersDurationTarget.
  ///
  /// In tr, this message translates to:
  /// **'Tüm vakitler'**
  String get reminderAllPrayersDurationTarget;

  /// No description provided for @reminderDurationsAppliedAllSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Süreler tüm vakitlere uygulandı.'**
  String get reminderDurationsAppliedAllSuccess;

  /// No description provided for @reminderDualAlertTitle.
  ///
  /// In tr, this message translates to:
  /// **'İki uyarı — {prayerTitle}'**
  String reminderDualAlertTitle(Object prayerTitle);

  /// No description provided for @reminderDualAlertSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'1. uyarı: Kapalı, tam vakit veya dakika önce. 2. uyarı: Kapalı veya dakika önce.'**
  String get reminderDualAlertSubtitle;

  /// No description provided for @reminderFirstAlertTitle.
  ///
  /// In tr, this message translates to:
  /// **'1. uyarı'**
  String get reminderFirstAlertTitle;

  /// No description provided for @reminderSecondAlertTitle.
  ///
  /// In tr, this message translates to:
  /// **'2. uyarı'**
  String get reminderSecondAlertTitle;

  /// No description provided for @prayerSoundPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim sesi'**
  String get prayerSoundPickerTitle;

  /// No description provided for @prayerSoundQuickAllSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Önce tek ses seç; istersen detaylı ayarda vakit bazında ayrılaştır.'**
  String get prayerSoundQuickAllSubtitle;

  /// No description provided for @prayerSoundApplyAllButton.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğim sesi tüm vakitlere uygula'**
  String get prayerSoundApplyAllButton;

  /// No description provided for @prayerSoundAdvancedToggle.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı ayar (vakit bazlı)'**
  String get prayerSoundAdvancedToggle;

  /// No description provided for @prayerSoundAppliedAllSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen ses tüm vakitlere uygulandı.'**
  String get prayerSoundAppliedAllSuccess;

  /// No description provided for @prayerSoundSystem.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun varsayılan sesi'**
  String get prayerSoundSystem;

  /// No description provided for @prayerSoundAdhanTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Ezan — Türkçe işleme (10 sn, baştan)'**
  String get prayerSoundAdhanTurkish;

  /// No description provided for @prayerSoundAdhanDubai.
  ///
  /// In tr, this message translates to:
  /// **'Ezan — Dubai / Ramadan (9 sn, baştan)'**
  String get prayerSoundAdhanDubai;

  /// No description provided for @prayerSoundAmbientFlute.
  ///
  /// In tr, this message translates to:
  /// **'Huzur — flute doku (6 sn, baştan)'**
  String get prayerSoundAmbientFlute;

  /// No description provided for @prayerSoundAmbientPianoGuitar.
  ///
  /// In tr, this message translates to:
  /// **'Huzur — piyano & gitar (7 sn, baştan)'**
  String get prayerSoundAmbientPianoGuitar;

  /// No description provided for @prayerSoundAmbientEthereal.
  ///
  /// In tr, this message translates to:
  /// **'Huzur — ethereal voices (10 sn, baştan)'**
  String get prayerSoundAmbientEthereal;

  /// No description provided for @prayerSoundPickFromPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefondan ses seç'**
  String get prayerSoundPickFromPhone;

  /// No description provided for @prayerSoundClearUserFile.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get prayerSoundClearUserFile;

  /// No description provided for @prayerSoundUserFromPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefondan seçilen ses'**
  String get prayerSoundUserFromPhone;

  /// No description provided for @prayerSoundUserFileActiveHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu vakit için şu an telefondan seçilen dosya kullanılıyor. Katalogdan bir ses seçersen dosya kalkar.'**
  String get prayerSoundUserFileActiveHint;

  /// No description provided for @prayerSoundSubtitlePerPrayer.
  ///
  /// In tr, this message translates to:
  /// **'Her vakit için ayrı ayrı: telefonun varsayılan sesi, katalogdan ton veya telefondan kendi dosyan. Uygula ile kaydet.'**
  String get prayerSoundSubtitlePerPrayer;

  /// No description provided for @prayerSoundImportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ses dosyası alınamadı. Başka bir dosya veya format dene (WAV, M4A…).'**
  String get prayerSoundImportFailed;

  /// No description provided for @prayerSoundPreviewSystem.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme yok — cihazının varsayılan bildirim sesi kullanılır.'**
  String get prayerSoundPreviewSystem;

  /// No description provided for @commonStart.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get commonStart;

  /// No description provided for @commonRestart.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden'**
  String get commonRestart;

  /// No description provided for @willpowerHabitNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlık bulunamadı'**
  String get willpowerHabitNotFound;

  /// No description provided for @namazProgramHomeHintActive.
  ///
  /// In tr, this message translates to:
  /// **'Namaz takibi aktif. Artık Anasayfa kartında da görünür.'**
  String get namazProgramHomeHintActive;

  /// No description provided for @namazProgramPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'İbadet'**
  String get namazProgramPageTitle;

  /// No description provided for @namazProgramVerseQuote.
  ///
  /// In tr, this message translates to:
  /// **'“Şüphesiz kalpler, Allah’ı anmakla huzur bulur.”\n(Ra’d suresi, 13:28 — meal)'**
  String get namazProgramVerseQuote;

  /// No description provided for @namazProgramBreathingBreak.
  ///
  /// In tr, this message translates to:
  /// **'Nefes molası'**
  String get namazProgramBreathingBreak;

  /// No description provided for @namazProgramTodayPrayersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün namazları'**
  String get namazProgramTodayPrayersTitle;

  /// No description provided for @namazProgramTodayProgress.
  ///
  /// In tr, this message translates to:
  /// **'{done}/5 tamam'**
  String namazProgramTodayProgress(int done);

  /// No description provided for @namazProgramPercentDone.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} tamamlandı'**
  String namazProgramPercentDone(int percent);

  /// No description provided for @namazProgramSystemNotificationSettings.
  ///
  /// In tr, this message translates to:
  /// **'Sistem bildirim ayarları'**
  String get namazProgramSystemNotificationSettings;

  /// No description provided for @namazProgramRecentDaysTitle.
  ///
  /// In tr, this message translates to:
  /// **'Son günler'**
  String get namazProgramRecentDaysTitle;

  /// No description provided for @namazProgramRecentDaysSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her kutu o gün kılınan vakit sayısı (ör. 3/5).'**
  String get namazProgramRecentDaysSubtitle;

  /// No description provided for @breathingPhaseInhale.
  ///
  /// In tr, this message translates to:
  /// **'Nefes al'**
  String get breathingPhaseInhale;

  /// No description provided for @breathingPhaseHold.
  ///
  /// In tr, this message translates to:
  /// **'Tut'**
  String get breathingPhaseHold;

  /// No description provided for @breathingPhaseExhale.
  ///
  /// In tr, this message translates to:
  /// **'Nefes ver'**
  String get breathingPhaseExhale;

  /// No description provided for @breathingCycleProgress.
  ///
  /// In tr, this message translates to:
  /// **'Döngü {current}/{total}'**
  String breathingCycleProgress(int current, int total);

  /// No description provided for @breathingFinishAction.
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get breathingFinishAction;

  /// No description provided for @breathingSecondsLabel.
  ///
  /// In tr, this message translates to:
  /// **'{seconds} sn'**
  String breathingSecondsLabel(int seconds);

  /// No description provided for @breathingIntroTitle.
  ///
  /// In tr, this message translates to:
  /// **'4-7-8 Nefes Terapisi'**
  String get breathingIntroTitle;

  /// No description provided for @breathingIntroSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Stres ve kaygıyı azaltan, yavaş tempolu nefes düzeni.'**
  String get breathingIntroSubtitle;

  /// No description provided for @breathingIntroCycles.
  ///
  /// In tr, this message translates to:
  /// **'{cycles} döngü'**
  String breathingIntroCycles(int cycles);

  /// No description provided for @breathingIntroApproxMinutes.
  ///
  /// In tr, this message translates to:
  /// **'~2 dk'**
  String get breathingIntroApproxMinutes;

  /// No description provided for @breathingPhaseHintInhale.
  ///
  /// In tr, this message translates to:
  /// **'saniye al'**
  String get breathingPhaseHintInhale;

  /// No description provided for @breathingPhaseHintHold.
  ///
  /// In tr, this message translates to:
  /// **'saniye tut'**
  String get breathingPhaseHintHold;

  /// No description provided for @breathingPhaseHintExhale.
  ///
  /// In tr, this message translates to:
  /// **'saniye ver'**
  String get breathingPhaseHintExhale;

  /// No description provided for @breathingSessionCompleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu seans tamam'**
  String get breathingSessionCompleteTitle;

  /// No description provided for @breathingSessionCompleteSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{cycles} döngü tamamlandı. İstersen bir tur daha yapabilir veya çıkabilirsin.'**
  String breathingSessionCompleteSubtitle(int cycles);

  /// No description provided for @breathingBottomHint.
  ///
  /// In tr, this message translates to:
  /// **'Tutarken kalp ritmi yavaşlar; rahat bir tempoda devam et. Baş dönmesi olursa dur.'**
  String get breathingBottomHint;

  /// No description provided for @quitProgramNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Program bulunamadı'**
  String get quitProgramNotFound;

  /// No description provided for @quitOnboardingCommitmentMinLengthError.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen kendine bir söz yaz (en az 8 karakter).'**
  String get quitOnboardingCommitmentMinLengthError;

  /// No description provided for @quitOnboardingQuickStartTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sayacı şimdi başlat'**
  String get quitOnboardingQuickStartTitle;

  /// No description provided for @quitOnboardingQuickStartBody.
  ///
  /// In tr, this message translates to:
  /// **'Sayacın bu andan itibaren çalışmaya başlar. Ahdini dilediğin zaman programdan tamamlayabilirsin.'**
  String get quitOnboardingQuickStartBody;

  /// No description provided for @quitOnboardingAbortAction.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get quitOnboardingAbortAction;

  /// No description provided for @quitOnboardingExitDraftTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlıktan çıkılsın mı?'**
  String get quitOnboardingExitDraftTitle;

  /// No description provided for @quitOnboardingExitDraftBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu hazırlık turundaki ilerlemen kaydedilmez. İstersen daha sonra yeniden başlayabilirsin.'**
  String get quitOnboardingExitDraftBody;

  /// No description provided for @quitOnboardingStayAction.
  ///
  /// In tr, this message translates to:
  /// **'Kal'**
  String get quitOnboardingStayAction;

  /// No description provided for @quitOnboardingExitAction.
  ///
  /// In tr, this message translates to:
  /// **'Çık'**
  String get quitOnboardingExitAction;

  /// No description provided for @quitOnboardingContentLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlık içeriği yüklenemedi. Lütfen tekrar deneyin.'**
  String get quitOnboardingContentLoadFailed;

  /// No description provided for @quitOnboardingAppBarTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlık'**
  String get quitOnboardingAppBarTitle;

  /// No description provided for @quitOnboardingSealTitlePrefix.
  ///
  /// In tr, this message translates to:
  /// **'Sözünü mühürle'**
  String get quitOnboardingSealTitlePrefix;

  /// No description provided for @quitOnboardingSealHoldHint.
  ///
  /// In tr, this message translates to:
  /// **'Parmağını basılı tut'**
  String get quitOnboardingSealHoldHint;

  /// No description provided for @quitOnboardingContinueAction.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get quitOnboardingContinueAction;

  /// No description provided for @quitOnboardingQuickStartInlineAction.
  ///
  /// In tr, this message translates to:
  /// **'Sayacı hemen başlat, programı sonra tamamla'**
  String get quitOnboardingQuickStartInlineAction;

  /// No description provided for @quitOnboardingCommitmentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kendine sözün'**
  String get quitOnboardingCommitmentTitle;

  /// No description provided for @quitOnboardingCommitmentSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kısa ve net yaz; mühürlemeden önce düzenleyebilirsin.'**
  String get quitOnboardingCommitmentSubtitle;

  /// No description provided for @quitOnboardingCommitmentHint.
  ///
  /// In tr, this message translates to:
  /// **'Bugünden itibaren…'**
  String get quitOnboardingCommitmentHint;

  /// No description provided for @quitOnboardingExamplesSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Örnek cümleler'**
  String get quitOnboardingExamplesSectionTitle;

  /// No description provided for @quitProgramRestartTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden başla'**
  String get quitProgramRestartTitle;

  /// No description provided for @quitProgramRestartPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Sayaç sıfırlanacak. Geçmişin ne olsun?'**
  String get quitProgramRestartPrompt;

  /// No description provided for @quitProgramRestartKeepHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçmişi sakla'**
  String get quitProgramRestartKeepHistoryTitle;

  /// No description provided for @quitProgramRestartKeepHistorySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sayaç sıfırdan başlar; önceki denemen, günlük işaretlerin ve istatistiklerin korunur.'**
  String get quitProgramRestartKeepHistorySubtitle;

  /// No description provided for @quitProgramRestartWipeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırdan başla'**
  String get quitProgramRestartWipeTitle;

  /// No description provided for @quitProgramRestartWipeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm geçmiş günlük işaretler de silinir. Geri alınamaz.'**
  String get quitProgramRestartWipeSubtitle;

  /// No description provided for @quitProgramElapsedHms.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa {minutes} dk {seconds} sn'**
  String quitProgramElapsedHms(int hours, int minutes, int seconds);

  /// No description provided for @quitProgramElapsedMs.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk {seconds} sn'**
  String quitProgramElapsedMs(int minutes, int seconds);

  /// No description provided for @quitProgramElapsedS.
  ///
  /// In tr, this message translates to:
  /// **'{seconds} sn'**
  String quitProgramElapsedS(int seconds);

  /// No description provided for @quitProgramTabProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get quitProgramTabProgress;

  /// No description provided for @quitProgramTabTips.
  ///
  /// In tr, this message translates to:
  /// **'İpuçları'**
  String get quitProgramTabTips;

  /// No description provided for @quitProgramTipsLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'İçerik yüklenemedi'**
  String get quitProgramTipsLoadFailed;

  /// No description provided for @quitProgramTipsWatermark.
  ///
  /// In tr, this message translates to:
  /// **'هِدَايَة'**
  String get quitProgramTipsWatermark;

  /// No description provided for @quitProgramTipsHeroTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hidayet'**
  String get quitProgramTipsHeroTitle;

  /// No description provided for @quitProgramTipsHeroSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Şuur, sabır ve pratik öneriler — yolunu yumuşatmak için.'**
  String get quitProgramTipsHeroSubtitle;

  /// No description provided for @quitProgramDaysUpper.
  ///
  /// In tr, this message translates to:
  /// **'GÜN'**
  String get quitProgramDaysUpper;

  /// No description provided for @quitProgramStartNowAction.
  ///
  /// In tr, this message translates to:
  /// **'Bu andan bıraktım'**
  String get quitProgramStartNowAction;

  /// No description provided for @quitProgramStatFullDays.
  ///
  /// In tr, this message translates to:
  /// **'Tam gün'**
  String get quitProgramStatFullDays;

  /// No description provided for @quitProgramDash.
  ///
  /// In tr, this message translates to:
  /// **'—'**
  String get quitProgramDash;

  /// No description provided for @quitProgramStatTimer.
  ///
  /// In tr, this message translates to:
  /// **'Sayaç'**
  String get quitProgramStatTimer;

  /// No description provided for @quitProgramElapsedSinceQuitDays.
  ///
  /// In tr, this message translates to:
  /// **'Geçen süre: {days} gün (bırakma anından)'**
  String quitProgramElapsedSinceQuitDays(int days);

  /// No description provided for @quitProgramTasksTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görevler'**
  String get quitProgramTasksTitle;

  /// No description provided for @quitProgramTasksSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Gün eşiklerini tamamladıkça ilerlersin.'**
  String get quitProgramTasksSubtitle;

  /// No description provided for @quitProgramUiCounterSubtitleGeneric.
  ///
  /// In tr, this message translates to:
  /// **'temiz kalış'**
  String get quitProgramUiCounterSubtitleGeneric;

  /// No description provided for @quitProgramUiMetricsSectionTitleGeneric.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme göstergeleri'**
  String get quitProgramUiMetricsSectionTitleGeneric;

  /// No description provided for @quitProgramUiDisclaimerGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Motivasyon amaçlı göstergelerdir.'**
  String get quitProgramUiDisclaimerGeneric;

  /// No description provided for @quitProgramUiEncouragementGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Her temiz gün değerlidir; sabit ve küçük adımlar büyük dönüşümler getirir.'**
  String get quitProgramUiEncouragementGeneric;

  /// No description provided for @quitProgramUiClockHintGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Tıkladığında süre ve göstergeler bu ana göre ilerler.'**
  String get quitProgramUiClockHintGeneric;

  /// No description provided for @quitProgramMotivationStageStart.
  ///
  /// In tr, this message translates to:
  /// **'İlk günün en değerli adımı: başlamak.'**
  String get quitProgramMotivationStageStart;

  /// No description provided for @quitProgramMotivationStageWeek.
  ///
  /// In tr, this message translates to:
  /// **'İlk hafta sabır; küçük adımlar büyük değişim getirir.'**
  String get quitProgramMotivationStageWeek;

  /// No description provided for @quitProgramMotivationStageMonth.
  ///
  /// In tr, this message translates to:
  /// **'Bir aya yaklaşırken sabırla devam.'**
  String get quitProgramMotivationStageMonth;

  /// No description provided for @quitProgramMotivationStageQuarter.
  ///
  /// In tr, this message translates to:
  /// **'Üç aylık süreçte sabır meyvesini gösterir.'**
  String get quitProgramMotivationStageQuarter;

  /// No description provided for @quitProgramMotivationStageLong.
  ///
  /// In tr, this message translates to:
  /// **'Uzun solukta her temiz gün değerlidir.'**
  String get quitProgramMotivationStageLong;

  /// No description provided for @quitMetricSmokingLung.
  ///
  /// In tr, this message translates to:
  /// **'Ciğer / solunum'**
  String get quitMetricSmokingLung;

  /// No description provided for @quitMetricSmokingHeart.
  ///
  /// In tr, this message translates to:
  /// **'Kalp-damar'**
  String get quitMetricSmokingHeart;

  /// No description provided for @quitMetricSmokingTeethMouth.
  ///
  /// In tr, this message translates to:
  /// **'Diş ve ağız'**
  String get quitMetricSmokingTeethMouth;

  /// No description provided for @quitMetricSmokingSmellTaste.
  ///
  /// In tr, this message translates to:
  /// **'Koku ve tat'**
  String get quitMetricSmokingSmellTaste;

  /// No description provided for @quitMetricScreenFocusDepth.
  ///
  /// In tr, this message translates to:
  /// **'Odak ve derinlik'**
  String get quitMetricScreenFocusDepth;

  /// No description provided for @quitMetricScreenSleepRhythm.
  ///
  /// In tr, this message translates to:
  /// **'Uyku düzeni'**
  String get quitMetricScreenSleepRhythm;

  /// No description provided for @quitMetricScreenAwareness.
  ///
  /// In tr, this message translates to:
  /// **'Ekran farkındalığı'**
  String get quitMetricScreenAwareness;

  /// No description provided for @quitMetricScreenInnerCalm.
  ///
  /// In tr, this message translates to:
  /// **'İç huzur'**
  String get quitMetricScreenInnerCalm;

  /// No description provided for @quitMetricAlcoholLiverRecovery.
  ///
  /// In tr, this message translates to:
  /// **'Karaciğer toparlanması'**
  String get quitMetricAlcoholLiverRecovery;

  /// No description provided for @quitMetricAlcoholSleepStability.
  ///
  /// In tr, this message translates to:
  /// **'Uyku istikrarı'**
  String get quitMetricAlcoholSleepStability;

  /// No description provided for @quitMetricAlcoholMoodBalance.
  ///
  /// In tr, this message translates to:
  /// **'Ruh hali dengesi'**
  String get quitMetricAlcoholMoodBalance;

  /// No description provided for @quitMetricAlcoholClarity.
  ///
  /// In tr, this message translates to:
  /// **'Zihin berraklığı'**
  String get quitMetricAlcoholClarity;

  /// No description provided for @quitMetricSubstanceBodyBalance.
  ///
  /// In tr, this message translates to:
  /// **'Beden dengesi'**
  String get quitMetricSubstanceBodyBalance;

  /// No description provided for @quitMetricSubstanceSleepRhythm.
  ///
  /// In tr, this message translates to:
  /// **'Uyku ritmi'**
  String get quitMetricSubstanceSleepRhythm;

  /// No description provided for @quitMetricSubstanceUrgeControl.
  ///
  /// In tr, this message translates to:
  /// **'İstek yönetimi'**
  String get quitMetricSubstanceUrgeControl;

  /// No description provided for @quitMetricSubstanceSupportTracking.
  ///
  /// In tr, this message translates to:
  /// **'Destek ve takip'**
  String get quitMetricSubstanceSupportTracking;

  /// No description provided for @quitMetricZinaDiscipline.
  ///
  /// In tr, this message translates to:
  /// **'Nefis disiplini'**
  String get quitMetricZinaDiscipline;

  /// No description provided for @quitMetricZinaBoundaryStrength.
  ///
  /// In tr, this message translates to:
  /// **'Sınır gücü'**
  String get quitMetricZinaBoundaryStrength;

  /// No description provided for @quitMetricZinaHeartCalm.
  ///
  /// In tr, this message translates to:
  /// **'Kalp sükûnu'**
  String get quitMetricZinaHeartCalm;

  /// No description provided for @quitMetricZinaTawbaDirection.
  ///
  /// In tr, this message translates to:
  /// **'Tövbe istikameti'**
  String get quitMetricZinaTawbaDirection;

  /// No description provided for @quitMilestone1Title.
  ///
  /// In tr, this message translates to:
  /// **'İlk nefes'**
  String get quitMilestone1Title;

  /// No description provided for @quitMilestone1Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir gün temiz'**
  String get quitMilestone1Subtitle;

  /// No description provided for @quitMilestone2Title.
  ///
  /// In tr, this message translates to:
  /// **'İlk seri'**
  String get quitMilestone2Title;

  /// No description provided for @quitMilestone2Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'48 saat'**
  String get quitMilestone2Subtitle;

  /// No description provided for @quitMilestone3Title.
  ///
  /// In tr, this message translates to:
  /// **'Üç gün'**
  String get quitMilestone3Title;

  /// No description provided for @quitMilestone3Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'İstek zirvesi geçiyor'**
  String get quitMilestone3Subtitle;

  /// No description provided for @quitMilestone5Title.
  ///
  /// In tr, this message translates to:
  /// **'Beş gün'**
  String get quitMilestone5Title;

  /// No description provided for @quitMilestone5Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Rutin kırılıyor'**
  String get quitMilestone5Subtitle;

  /// No description provided for @quitMilestone7Title.
  ///
  /// In tr, this message translates to:
  /// **'Bir hafta'**
  String get quitMilestone7Title;

  /// No description provided for @quitMilestone7Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'İlk hafta tamam'**
  String get quitMilestone7Subtitle;

  /// No description provided for @quitMilestone10Title.
  ///
  /// In tr, this message translates to:
  /// **'On gün'**
  String get quitMilestone10Title;

  /// No description provided for @quitMilestone10Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'İrade güçleniyor'**
  String get quitMilestone10Subtitle;

  /// No description provided for @quitMilestone14Title.
  ///
  /// In tr, this message translates to:
  /// **'İki hafta'**
  String get quitMilestone14Title;

  /// No description provided for @quitMilestone14Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Algı toparlanıyor'**
  String get quitMilestone14Subtitle;

  /// No description provided for @quitMilestone21Title.
  ///
  /// In tr, this message translates to:
  /// **'Üç hafta'**
  String get quitMilestone21Title;

  /// No description provided for @quitMilestone21Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlık döngüsü'**
  String get quitMilestone21Subtitle;

  /// No description provided for @quitMilestone30Title.
  ///
  /// In tr, this message translates to:
  /// **'Bir ay'**
  String get quitMilestone30Title;

  /// No description provided for @quitMilestone30Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Önemli eşik'**
  String get quitMilestone30Subtitle;

  /// No description provided for @quitMilestone45Title.
  ///
  /// In tr, this message translates to:
  /// **'Kırk beş gün'**
  String get quitMilestone45Title;

  /// No description provided for @quitMilestone45Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Düzen oturuyor'**
  String get quitMilestone45Subtitle;

  /// No description provided for @quitMilestone60Title.
  ///
  /// In tr, this message translates to:
  /// **'İki ay'**
  String get quitMilestone60Title;

  /// No description provided for @quitMilestone60Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Beden adapte'**
  String get quitMilestone60Subtitle;

  /// No description provided for @quitMilestone66Title.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlık ustası'**
  String get quitMilestone66Title;

  /// No description provided for @quitMilestone66Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'66 gün çizgisi'**
  String get quitMilestone66Subtitle;

  /// No description provided for @quitMilestone90Title.
  ///
  /// In tr, this message translates to:
  /// **'Üç ay'**
  String get quitMilestone90Title;

  /// No description provided for @quitMilestone90Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sağlıkta belirgin dönem'**
  String get quitMilestone90Subtitle;

  /// No description provided for @quitMilestone120Title.
  ///
  /// In tr, this message translates to:
  /// **'Dört ay'**
  String get quitMilestone120Title;

  /// No description provided for @quitMilestone120Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kararlılık nişanı'**
  String get quitMilestone120Subtitle;

  /// No description provided for @quitMilestone180Title.
  ///
  /// In tr, this message translates to:
  /// **'Altı ay'**
  String get quitMilestone180Title;

  /// No description provided for @quitMilestone180Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yarım yıl'**
  String get quitMilestone180Subtitle;

  /// No description provided for @quitMilestone270Title.
  ///
  /// In tr, this message translates to:
  /// **'Dokuz ay'**
  String get quitMilestone270Title;

  /// No description provided for @quitMilestone270Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uzun soluk'**
  String get quitMilestone270Subtitle;

  /// No description provided for @quitMilestone365Title.
  ///
  /// In tr, this message translates to:
  /// **'Bir yıl'**
  String get quitMilestone365Title;

  /// No description provided for @quitMilestone365Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Büyük müjde'**
  String get quitMilestone365Subtitle;

  /// No description provided for @quitMilestone500Title.
  ///
  /// In tr, this message translates to:
  /// **'Beş yüz gün'**
  String get quitMilestone500Title;

  /// No description provided for @quitMilestone500Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Azim tacı'**
  String get quitMilestone500Subtitle;

  /// No description provided for @quitMilestone730Title.
  ///
  /// In tr, this message translates to:
  /// **'İki yıl'**
  String get quitMilestone730Title;

  /// No description provided for @quitMilestone730Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kökten değişim'**
  String get quitMilestone730Subtitle;

  /// No description provided for @quitMilestone1000Title.
  ///
  /// In tr, this message translates to:
  /// **'Bin gün'**
  String get quitMilestone1000Title;

  /// No description provided for @quitMilestone1000Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Eşsiz seviye'**
  String get quitMilestone1000Subtitle;

  /// No description provided for @quitMilestoneInspiration365.
  ///
  /// In tr, this message translates to:
  /// **'\"Sabredenlere mükâfatları hesapsız verilir.\" (Zümer, 10)'**
  String get quitMilestoneInspiration365;

  /// No description provided for @quitMilestoneInspiration90.
  ///
  /// In tr, this message translates to:
  /// **'\"Allah ile beraber olan, asla yalnız kalmaz.\"'**
  String get quitMilestoneInspiration90;

  /// No description provided for @quitMilestoneInspiration30.
  ///
  /// In tr, this message translates to:
  /// **'\"Azmettin mi, artık Allah\'a tevekkül et.\" (Âl-i İmrân, 159)'**
  String get quitMilestoneInspiration30;

  /// No description provided for @quitMilestoneInspiration7.
  ///
  /// In tr, this message translates to:
  /// **'\"Zorlukla beraber bir kolaylık vardır.\" (İnşirâh, 6)'**
  String get quitMilestoneInspiration7;

  /// No description provided for @quitMilestoneInspiration1.
  ///
  /// In tr, this message translates to:
  /// **'\"Muhakkak her güçlüğün yanında bir kolaylık vardır.\" (İnşirâh, 5)'**
  String get quitMilestoneInspiration1;

  /// No description provided for @quitMilestoneElapsedSummary.
  ///
  /// In tr, this message translates to:
  /// **'{days} gündür temiz — {subtitle}'**
  String quitMilestoneElapsedSummary(int days, Object subtitle);

  /// No description provided for @quitMilestoneContinueAction.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get quitMilestoneContinueAction;

  /// No description provided for @quitProgramCompleteCommitmentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ahdini tamamla'**
  String get quitProgramCompleteCommitmentTitle;

  /// No description provided for @quitProgramCompleteCommitmentSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sayaç çalışıyor — programını kendine yazdığın sözle mühürle.'**
  String get quitProgramCompleteCommitmentSubtitle;

  /// No description provided for @willpowerHubBreathingExerciseTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nefes egzersizi'**
  String get willpowerHubBreathingExerciseTitle;

  /// No description provided for @willpowerHubBreathingExerciseSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yavaş nefes; stres anında bedenini yumuşatır.'**
  String get willpowerHubBreathingExerciseSubtitle;

  /// No description provided for @willpowerHubArchiveHabitDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlığı kalıcı sil'**
  String get willpowerHubArchiveHabitDialogTitle;

  /// No description provided for @willpowerHubArchiveHabitDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt ve ilişkili ilerleme verileri kalıcı olarak silinir. Geri alınamaz.'**
  String get willpowerHubArchiveHabitDialogBody;

  /// No description provided for @willpowerHubArchiveAction.
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı sil'**
  String get willpowerHubArchiveAction;

  /// No description provided for @willpowerHubHeaderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim & Arınma'**
  String get willpowerHubHeaderTitle;

  /// No description provided for @willpowerHubNoActiveHabits.
  ///
  /// In tr, this message translates to:
  /// **'Henüz aktif alışkanlık yok'**
  String get willpowerHubNoActiveHabits;

  /// No description provided for @willpowerHubActiveHabits.
  ///
  /// In tr, this message translates to:
  /// **'{count} aktif alışkanlık'**
  String willpowerHubActiveHabits(int count);

  /// No description provided for @willpowerHubHabitCalendarTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlık takvimi'**
  String get willpowerHubHabitCalendarTooltip;

  /// No description provided for @willpowerHubTabBuild.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim'**
  String get willpowerHubTabBuild;

  /// No description provided for @willpowerHubTabQuit.
  ///
  /// In tr, this message translates to:
  /// **'Arınma'**
  String get willpowerHubTabQuit;

  /// No description provided for @willpowerHubQuitCtaEarly.
  ///
  /// In tr, this message translates to:
  /// **'Her temiz dakika kalbine ve ciğerlerine oksijen olarak döner.'**
  String get willpowerHubQuitCtaEarly;

  /// No description provided for @willpowerHubQuitCtaOngoing.
  ///
  /// In tr, this message translates to:
  /// **'İlk günler zor; bedenin zaten iyileşmeye başladı.'**
  String get willpowerHubQuitCtaOngoing;

  /// No description provided for @willpowerHubBuildCtaEarly.
  ///
  /// In tr, this message translates to:
  /// **'Küçük adımlarla başlamak yeterli.'**
  String get willpowerHubBuildCtaEarly;

  /// No description provided for @willpowerHubBuildCtaOngoing.
  ///
  /// In tr, this message translates to:
  /// **'Düzenin sana iyi gidiyor; devam.'**
  String get willpowerHubBuildCtaOngoing;

  /// No description provided for @willpowerHubSummaryQuitLabel.
  ///
  /// In tr, this message translates to:
  /// **'ARINMA'**
  String get willpowerHubSummaryQuitLabel;

  /// No description provided for @willpowerHubSummaryTodayLabel.
  ///
  /// In tr, this message translates to:
  /// **'BUGÜN'**
  String get willpowerHubSummaryTodayLabel;

  /// No description provided for @willpowerHubSummaryCounterProgress.
  ///
  /// In tr, this message translates to:
  /// **'sayaç ilerlemesi'**
  String get willpowerHubSummaryCounterProgress;

  /// No description provided for @willpowerHubSummaryCompleted.
  ///
  /// In tr, this message translates to:
  /// **'tamamlandı'**
  String get willpowerHubSummaryCompleted;

  /// No description provided for @willpowerHubInsightTagSpiritual.
  ///
  /// In tr, this message translates to:
  /// **'MANEVİ'**
  String get willpowerHubInsightTagSpiritual;

  /// No description provided for @willpowerHubInsightTagHealth.
  ///
  /// In tr, this message translates to:
  /// **'SAĞLIK'**
  String get willpowerHubInsightTagHealth;

  /// No description provided for @willpowerHubAddFirstBuild.
  ///
  /// In tr, this message translates to:
  /// **'İlk gelişimini ekle'**
  String get willpowerHubAddFirstBuild;

  /// No description provided for @willpowerHubAddFirstQuit.
  ///
  /// In tr, this message translates to:
  /// **'İlk arınmanı ekle'**
  String get willpowerHubAddFirstQuit;

  /// No description provided for @willpowerHubBuildEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim alanın henüz boş'**
  String get willpowerHubBuildEmptyTitle;

  /// No description provided for @willpowerHubBuildEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hayır katan bir alışkanlığı sürdürmek, manevi gelişimin en sade yoludur.'**
  String get willpowerHubBuildEmptySubtitle;

  /// No description provided for @willpowerHubKazaLabelSabah.
  ///
  /// In tr, this message translates to:
  /// **'Sab'**
  String get willpowerHubKazaLabelSabah;

  /// No description provided for @willpowerHubKazaLabelOgle.
  ///
  /// In tr, this message translates to:
  /// **'Öğl'**
  String get willpowerHubKazaLabelOgle;

  /// No description provided for @willpowerHubKazaLabelIkindi.
  ///
  /// In tr, this message translates to:
  /// **'İkn'**
  String get willpowerHubKazaLabelIkindi;

  /// No description provided for @willpowerHubKazaLabelAksam.
  ///
  /// In tr, this message translates to:
  /// **'Akş'**
  String get willpowerHubKazaLabelAksam;

  /// No description provided for @willpowerHubKazaLabelYatsi.
  ///
  /// In tr, this message translates to:
  /// **'Yat'**
  String get willpowerHubKazaLabelYatsi;

  /// No description provided for @willpowerHubKazaLabelVitir.
  ///
  /// In tr, this message translates to:
  /// **'Vit'**
  String get willpowerHubKazaLabelVitir;

  /// No description provided for @willpowerHubKazaTrackingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaza takibi'**
  String get willpowerHubKazaTrackingTitle;

  /// No description provided for @willpowerHubKazaRemainingLabel.
  ///
  /// In tr, this message translates to:
  /// **'kalan'**
  String get willpowerHubKazaRemainingLabel;

  /// No description provided for @willpowerHubRemoveCardTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Kartı kaldır'**
  String get willpowerHubRemoveCardTooltip;

  /// No description provided for @willpowerHubHideKazaDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaza kartını kaldır?'**
  String get willpowerHubHideKazaDialogTitle;

  /// No description provided for @willpowerHubHideKazaDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu kart Gelişim ekranından gizlenir. Hesap ve sayaç verilerin cihazda kalır; Rutin atölyesinden tekrar ekleyebilirsin.'**
  String get willpowerHubHideKazaDialogBody;

  /// No description provided for @willpowerHubRemoveAction.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get willpowerHubRemoveAction;

  /// No description provided for @willpowerHubQuitEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arınma alanın henüz boş'**
  String get willpowerHubQuitEmptyTitle;

  /// No description provided for @willpowerHubQuitEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Zararlı bir alışkanlıktan vazgeçmek, nefsini terbiye etmenin güçlü bir yoludur.'**
  String get willpowerHubQuitEmptySubtitle;

  /// No description provided for @willpowerHubPeriodPrefixWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta '**
  String get willpowerHubPeriodPrefixWeek;

  /// No description provided for @willpowerHubPeriodPrefixMonth.
  ///
  /// In tr, this message translates to:
  /// **'Bu ay '**
  String get willpowerHubPeriodPrefixMonth;

  /// No description provided for @willpowerHubPercentTargetReached.
  ///
  /// In tr, this message translates to:
  /// **'{prefix}Hedef yüzdesine ulaştın.'**
  String willpowerHubPercentTargetReached(Object prefix);

  /// No description provided for @willpowerHubPercentProgressStatus.
  ///
  /// In tr, this message translates to:
  /// **'{prefix}%{progress} tamamlandı, %{left} kaldı.'**
  String willpowerHubPercentProgressStatus(
    Object prefix,
    int progress,
    int left,
  );

  /// No description provided for @willpowerHubTargetPending.
  ///
  /// In tr, this message translates to:
  /// **'{prefix}Hedef bekleniyor.'**
  String willpowerHubTargetPending(Object prefix);

  /// No description provided for @willpowerHubUnitTargetAddPrompt.
  ///
  /// In tr, this message translates to:
  /// **'{prefix}{target} {unit} hedef — eklemek için karta dokun.'**
  String willpowerHubUnitTargetAddPrompt(
    Object prefix,
    int target,
    Object unit,
  );

  /// No description provided for @willpowerHubUnitProgressTargetFilled.
  ///
  /// In tr, this message translates to:
  /// **'{prefix}{progress} {unit} tamam; hedef doldu.'**
  String willpowerHubUnitProgressTargetFilled(
    Object prefix,
    int progress,
    Object unit,
  );

  /// No description provided for @willpowerHubUnitProgressRemaining.
  ///
  /// In tr, this message translates to:
  /// **'{prefix}{progress} {unit} tamamladın, {left} {unit} kaldı.'**
  String willpowerHubUnitProgressRemaining(
    Object prefix,
    int progress,
    Object unit,
    int left,
  );

  /// No description provided for @willpowerHubUnitTargetDoneSuper.
  ///
  /// In tr, this message translates to:
  /// **'{prefix}{target} {unit} tamam — süper.'**
  String willpowerHubUnitTargetDoneSuper(
    Object prefix,
    int target,
    Object unit,
  );

  /// No description provided for @willpowerHubUnitProgressDidRemaining.
  ///
  /// In tr, this message translates to:
  /// **'{prefix}{progress} {unit} yaptın, {left} {unit} kaldı.'**
  String willpowerHubUnitProgressDidRemaining(
    Object prefix,
    int progress,
    Object unit,
    int left,
  );

  /// No description provided for @willpowerHubAddEditHint.
  ///
  /// In tr, this message translates to:
  /// **'Ekleme ve düzenleme için karta dokun'**
  String get willpowerHubAddEditHint;

  /// No description provided for @willpowerHubQuitStatusSetupMissing.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlık eksik'**
  String get willpowerHubQuitStatusSetupMissing;

  /// No description provided for @willpowerHubQuitStatusClockRunning.
  ///
  /// In tr, this message translates to:
  /// **'Sayaç açık'**
  String get willpowerHubQuitStatusClockRunning;

  /// No description provided for @willpowerHubQuitStatusProgramReady.
  ///
  /// In tr, this message translates to:
  /// **'Program hazır'**
  String get willpowerHubQuitStatusProgramReady;

  /// No description provided for @willpowerHubTapCardForDetails.
  ///
  /// In tr, this message translates to:
  /// **'Detaylar için karta dokun'**
  String get willpowerHubTapCardForDetails;

  /// No description provided for @willpowerHubCompleteSetup.
  ///
  /// In tr, this message translates to:
  /// **'Kurulumu tamamla'**
  String get willpowerHubCompleteSetup;

  /// No description provided for @willpowerHubStartClockHint.
  ///
  /// In tr, this message translates to:
  /// **'Programda “Bu andan bıraktım” ile sayacı başlat'**
  String get willpowerHubStartClockHint;

  /// No description provided for @willpowerHubStreakSeriesLabel.
  ///
  /// In tr, this message translates to:
  /// **'seri'**
  String get willpowerHubStreakSeriesLabel;

  /// No description provided for @willpowerHubStreakDaySeriesLabel.
  ///
  /// In tr, this message translates to:
  /// **'gün serisi'**
  String get willpowerHubStreakDaySeriesLabel;

  /// No description provided for @qiblaHubCompassTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kıble yönünü bul'**
  String get qiblaHubCompassTitle;

  /// No description provided for @qiblaHubCompassSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Pusula ve konum ile Kâbe yönünü göster'**
  String get qiblaHubCompassSubtitle;

  /// No description provided for @qiblaHubOpenAction.
  ///
  /// In tr, this message translates to:
  /// **'Aç'**
  String get qiblaHubOpenAction;

  /// No description provided for @qiblaHubZikirTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zikirmatik'**
  String get qiblaHubZikirTitle;

  /// No description provided for @qiblaHubZikirFeatureSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Dijital sayaç; zikir bilgisi, tur geçmişi ve hedef (33/99)'**
  String get qiblaHubZikirFeatureSubtitle;

  /// No description provided for @qiblaHubBreathingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nefes Egzersizi'**
  String get qiblaHubBreathingTitle;

  /// No description provided for @qiblaHubBreathingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'4-7-8 nefes döngüsü ile sakinleş, odağını toparla'**
  String get qiblaHubBreathingSubtitle;

  /// No description provided for @qiblaHubHealingTitle.
  ///
  /// In tr, this message translates to:
  /// **'İyileştirici Frekanslar'**
  String get qiblaHubHealingTitle;

  /// No description provided for @qiblaHubHealingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Terapi tonları, ambiyans ve uyku zamanlayıcısı ile sakin bir oturum'**
  String get qiblaHubHealingSubtitle;

  /// No description provided for @generalLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get generalLoading;

  /// No description provided for @settingsPrivacyPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get settingsPrivacyPageTitle;

  /// No description provided for @settingsPrivacyLastUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Son güncelleme: 26.04.2026'**
  String get settingsPrivacyLastUpdated;

  /// No description provided for @settingsPrivacyIntro.
  ///
  /// In tr, this message translates to:
  /// **'Arin gizliliğinize saygı duyar. Bu metin, hangi verilerin işlendiğini, neden işlendiğini ve bu süreçleri nasıl yönetebileceğinizi açıklar.'**
  String get settingsPrivacyIntro;

  /// No description provided for @settingsPrivacyDataCollectedTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşlenen veriler'**
  String get settingsPrivacyDataCollectedTitle;

  /// No description provided for @settingsPrivacyDataCollectedBody.
  ///
  /// In tr, this message translates to:
  /// **'Kullanımınıza ve verdiğiniz izinlere bağlı olarak Arin; namaz vakti ve kıble özellikleri için konum verisi, bildirim tercihleri, giriş yaptığınızda hesap bilgileri ve uygulama tanılama verilerini işleyebilir.'**
  String get settingsPrivacyDataCollectedBody;

  /// No description provided for @settingsPrivacyUsageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Verileri neden işliyoruz'**
  String get settingsPrivacyUsageTitle;

  /// No description provided for @settingsPrivacyUsageBody.
  ///
  /// In tr, this message translates to:
  /// **'Veriler; namaz vakitlerini hesaplamak, kıble yönünü göstermek, hatırlatıcıları planlamak, ayarlarınızı korumak ve uygulama kararlılığını iyileştirmek amacıyla işlenir.'**
  String get settingsPrivacyUsageBody;

  /// No description provided for @settingsPrivacyStorageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Saklama ve süre'**
  String get settingsPrivacyStorageTitle;

  /// No description provided for @settingsPrivacyStorageBody.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlık, zikir ve tercih verilerinin büyük kısmı cihazınızda tutulur. Hesapla giriş yaparsanız seçili veriler Firebase servisleriyle eşitlenebilir. Veriler, uygulama içinden silene veya hesabınızı kaldırana kadar saklanır.'**
  String get settingsPrivacyStorageBody;

  /// No description provided for @settingsPrivacyThirdPartyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Üçüncü taraf servisler'**
  String get settingsPrivacyThirdPartyTitle;

  /// No description provided for @settingsPrivacyThirdPartyBody.
  ///
  /// In tr, this message translates to:
  /// **'Arin; oturum açma, bildirimler ve veri eşitleme için Firebase servislerini (Authentication, Firestore), kullanım analizi ve çökme tanılama için Firebase Analytics/Crashlytics\'i, reklamlar için Google AdMob\'u, abonelik ve uygulama içi satın alma doğrulaması için RevenueCat\'i ve namaz vakitleri için Aladhan/Diyanet API\'lerini kullanır.'**
  String get settingsPrivacyThirdPartyBody;

  /// No description provided for @settingsPrivacyControlsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı kontrolü'**
  String get settingsPrivacyControlsTitle;

  /// No description provided for @settingsPrivacyControlsBody.
  ///
  /// In tr, this message translates to:
  /// **'Konum ve bildirim izinlerini cihaz ayarlarından kapatabilir, Ayarlar ekranından çıkış yapabilir veya hesabınızı ve yerel verilerinizi silebilirsiniz.'**
  String get settingsPrivacyControlsBody;

  /// No description provided for @settingsPrivacyChildrenTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çocukların gizliliği'**
  String get settingsPrivacyChildrenTitle;

  /// No description provided for @settingsPrivacyChildrenBody.
  ///
  /// In tr, this message translates to:
  /// **'Arin, 13 yaş altı çocuklara yönelik olarak tasarlanmamıştır.'**
  String get settingsPrivacyChildrenBody;

  /// No description provided for @settingsPrivacyContactTitle.
  ///
  /// In tr, this message translates to:
  /// **'İletişim'**
  String get settingsPrivacyContactTitle;

  /// No description provided for @settingsPrivacyContactBody.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik ile ilgili sorularınız için: arinapphelp@gmail.com'**
  String get settingsPrivacyContactBody;

  /// No description provided for @notificationsHubTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationsHubTitle;

  /// No description provided for @notificationsHubHeadline.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı merkezi'**
  String get notificationsHubHeadline;

  /// No description provided for @notificationsHubSubhead.
  ///
  /// In tr, this message translates to:
  /// **'Namaz, arınma ve zikir — hepsi tek yerden.'**
  String get notificationsHubSubhead;

  /// No description provided for @notificationsPermissionGranted.
  ///
  /// In tr, this message translates to:
  /// **'İzin verildi'**
  String get notificationsPermissionGranted;

  /// No description provided for @notificationsPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'İzin kapalı'**
  String get notificationsPermissionDenied;

  /// No description provided for @notificationsPermissionLimited.
  ///
  /// In tr, this message translates to:
  /// **'Kısıtlı'**
  String get notificationsPermissionLimited;

  /// No description provided for @notificationsOpenOsSettings.
  ///
  /// In tr, this message translates to:
  /// **'Sistem bildirim ayarları'**
  String get notificationsOpenOsSettings;

  /// No description provided for @notificationsGateNotification.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim'**
  String get notificationsGateNotification;

  /// No description provided for @notificationsGateExactAlarm.
  ///
  /// In tr, this message translates to:
  /// **'Tam zamanlayıcı'**
  String get notificationsGateExactAlarm;

  /// No description provided for @notificationsGateBattery.
  ///
  /// In tr, this message translates to:
  /// **'Pil muafiyeti'**
  String get notificationsGateBattery;

  /// No description provided for @notificationsGateAllGood.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılar zamanında tetiklenir.'**
  String get notificationsGateAllGood;

  /// No description provided for @notificationsGateMissing.
  ///
  /// In tr, this message translates to:
  /// **'Bir veya daha fazla izin eksik — zamanlanan bildirimler gecikebilir ya da hiç gelmeyebilir.'**
  String get notificationsGateMissing;

  /// No description provided for @notificationsGateRequestExact.
  ///
  /// In tr, this message translates to:
  /// **'Tam zamanlayıcı iznini aç'**
  String get notificationsGateRequestExact;

  /// No description provided for @notificationsGateRequestBattery.
  ///
  /// In tr, this message translates to:
  /// **'Pil optimizasyonunu muaf tut'**
  String get notificationsGateRequestBattery;

  /// No description provided for @notificationsBatteryRationaleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Pil muafiyeti neden gerekli?'**
  String get notificationsBatteryRationaleTitle;

  /// No description provided for @notificationsBatteryRationaleBody.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakti ve arınma bildirimleri, telefon uyku (Doze) modundayken bile tam saatinde gelebilmesi için pil optimizasyonundan muaf tutulmalıdır. Bu izin yalnızca zamanlanmış bildirimleri etkiler; arka planda sürekli çalışmaz.'**
  String get notificationsBatteryRationaleBody;

  /// No description provided for @notificationsBatteryRationaleConfirm.
  ///
  /// In tr, this message translates to:
  /// **'İzin ver'**
  String get notificationsBatteryRationaleConfirm;

  /// No description provided for @notificationsBatteryRationaleCancel.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get notificationsBatteryRationaleCancel;

  /// No description provided for @notificationsDiagnosticsQueuedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kuyruğa alınan zamanlı hatırlatıcı'**
  String get notificationsDiagnosticsQueuedLabel;

  /// No description provided for @notificationsSectionGeneral.
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get notificationsSectionGeneral;

  /// No description provided for @notificationsSectionPrayer.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakitleri'**
  String get notificationsSectionPrayer;

  /// No description provided for @notificationsSectionArinma.
  ///
  /// In tr, this message translates to:
  /// **'Arınma ve alışkanlıklar'**
  String get notificationsSectionArinma;

  /// No description provided for @notificationsPrayerRowTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakit ve ses'**
  String get notificationsPrayerRowTitle;

  /// No description provided for @notificationsPrayerOnSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakit bildirimleri açık — dokunup düzenle'**
  String get notificationsPrayerOnSubtitle;

  /// No description provided for @notificationsPrayerOffSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakit bildirimleri kapalı — dokunup açabilirsin'**
  String get notificationsPrayerOffSubtitle;

  /// No description provided for @notificationsPrayerDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz bildirimleri'**
  String get notificationsPrayerDetailTitle;

  /// No description provided for @notificationsPrayerDetailSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her vakit için ayrı süre ve ses; ana anahtar aşağıda.'**
  String get notificationsPrayerDetailSubtitle;

  /// No description provided for @notificationsArinmaDailyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hatırlatıcı'**
  String get notificationsArinmaDailyTitle;

  /// No description provided for @notificationsArinmaDailySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Gün içinde 2 defa rastgele bir söz ya da kısa motivasyon.'**
  String get notificationsArinmaDailySubtitle;

  /// No description provided for @notificationsMilestoneTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlık bildirimleri'**
  String get notificationsMilestoneTitle;

  /// No description provided for @notificationsMilestoneSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Örn. bırakma yolculuğunda 24 saat, 1 hafta gibi seyrek mesajlar.'**
  String get notificationsMilestoneSubtitle;

  /// No description provided for @notificationsTaskTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görev hatırlatıcısı'**
  String get notificationsTaskTitle;

  /// No description provided for @notificationsTaskSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanmamış görev için günde en fazla bir uyarı.'**
  String get notificationsTaskSubtitle;

  /// No description provided for @notificationsZikirTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zikir hatırlatıcısı'**
  String get notificationsZikirTitle;

  /// No description provided for @notificationsZikirSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğin saatte, son zikirindeki metinle kısa bir hatırlatma.'**
  String get notificationsZikirSubtitle;

  /// No description provided for @notificationsZikirTimeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Zikir saati'**
  String get notificationsZikirTimeLabel;

  /// No description provided for @notificationsZikirTimePickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zikir saati'**
  String get notificationsZikirTimePickerTitle;

  /// No description provided for @notificationsZikirTimePickerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her gün bu saatte son zikir metninle hatırlatma.'**
  String get notificationsZikirTimePickerSubtitle;

  /// No description provided for @notificationsHealthDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık ve arınma ile ilgili metinler genel bilgilendirme amaçlıdır; tedavi yerine geçmez. Rahatsızlığınız varsa doktorunuza danışın.'**
  String get notificationsHealthDisclaimer;

  /// No description provided for @notificationsNextReminderToday.
  ///
  /// In tr, this message translates to:
  /// **'bugün'**
  String get notificationsNextReminderToday;

  /// No description provided for @notificationsNextReminderTomorrow.
  ///
  /// In tr, this message translates to:
  /// **'yarın'**
  String get notificationsNextReminderTomorrow;

  /// No description provided for @notificationsNextReminderUnderMinute.
  ///
  /// In tr, this message translates to:
  /// **'< 1 dk'**
  String get notificationsNextReminderUnderMinute;

  /// No description provided for @notificationsNextReminderMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk'**
  String notificationsNextReminderMinutes(int minutes);

  /// No description provided for @notificationsNextReminderHoursOnly.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa'**
  String notificationsNextReminderHoursOnly(int hours);

  /// No description provided for @notificationsNextReminderHoursMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa {minutes} dk'**
  String notificationsNextReminderHoursMinutes(int hours, int minutes);

  /// No description provided for @notificationsNextReminderLine.
  ///
  /// In tr, this message translates to:
  /// **'Bir sonraki hatırlatıcı: {dayLabel} {clock} · {gap} sonra'**
  String notificationsNextReminderLine(
    Object dayLabel,
    Object clock,
    Object gap,
  );

  /// No description provided for @aboutArinHeadline.
  ///
  /// In tr, this message translates to:
  /// **'Yolun yanında'**
  String get aboutArinHeadline;

  /// No description provided for @aboutArinSubhead.
  ///
  /// In tr, this message translates to:
  /// **'Namazına, düzenine ve gününe yumuşak hatırlatmalar sunan küçük bir arkadaş'**
  String get aboutArinSubhead;

  /// No description provided for @aboutArinParagraph1.
  ///
  /// In tr, this message translates to:
  /// **'ARIN; namazını vaktinde tutmana, sana iyi gelen alışkanlıkları sürdürüp zorlayan huyları yavaşça geride bırakmana yardımcı olmak için var. Amacımız baskı kurmak değil; yoğun günlerde kaybolan küçük hatırlatmalarla yanında, sakin bir köşede durmak.'**
  String get aboutArinParagraph1;

  /// No description provided for @aboutArinParagraph2.
  ///
  /// In tr, this message translates to:
  /// **'Bazen yol uzun, bazen gün çok dolu olur. Bu yüzden sade bir düzen ve net hatırlatmalar sunuyoruz. Eksik veya yanlış hissettiren her noktayı duymak isteriz; birlikte düzeltmeye ve geliştirmeye açığız.'**
  String get aboutArinParagraph2;

  /// No description provided for @aboutArinParagraph3.
  ///
  /// In tr, this message translates to:
  /// **'Küçük adımlar, uzun vadede en çok işe yarayanlardır. ARIN’i acele ettirmeyen, yolunu yalnız bırakmayan huzurlu bir eşlik gibi düşünmeni dileriz; günün sana sakin ve hafif geçsin.'**
  String get aboutArinParagraph3;

  /// No description provided for @aboutArinClosingWish.
  ///
  /// In tr, this message translates to:
  /// **'Hayırlı kullanımlar dileriz'**
  String get aboutArinClosingWish;

  /// No description provided for @languageChangedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Dil değiştirildi: {languageName}'**
  String languageChangedMessage(Object languageName);

  /// No description provided for @adminIdentityBadge.
  ///
  /// In tr, this message translates to:
  /// **'ADMIN'**
  String get adminIdentityBadge;

  /// No description provided for @adminPoolsHint.
  ///
  /// In tr, this message translates to:
  /// **'Havuz seç, düzenle ve kaydet. İleri düzey işlemler altta toplanır.'**
  String get adminPoolsHint;

  /// No description provided for @adminPoolsDropdownLabel.
  ///
  /// In tr, this message translates to:
  /// **'Havuz ({count} öğe)'**
  String adminPoolsDropdownLabel(int count);

  /// No description provided for @adminAdvancedActionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş işlemler'**
  String get adminAdvancedActionsTitle;

  /// No description provided for @adminBackupCurrentPoolJson.
  ///
  /// In tr, this message translates to:
  /// **'Bu havuzu yedekle (JSON)'**
  String get adminBackupCurrentPoolJson;

  /// No description provided for @adminRestoreFromBackup.
  ///
  /// In tr, this message translates to:
  /// **'Yedekten geri yükle'**
  String get adminRestoreFromBackup;

  /// No description provided for @adminWritingInProgress.
  ///
  /// In tr, this message translates to:
  /// **'Yazılıyor…'**
  String get adminWritingInProgress;

  /// No description provided for @adminResetCompletely.
  ///
  /// In tr, this message translates to:
  /// **'Tamamen sıfırla'**
  String get adminResetCompletely;

  /// No description provided for @adminVersionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm: v{version}'**
  String adminVersionLabel(Object version);

  /// No description provided for @adminSearchInPoolHint.
  ///
  /// In tr, this message translates to:
  /// **'Havuz içinde ara ({count} kayıt)'**
  String adminSearchInPoolHint(int count);

  /// No description provided for @adminAddAction.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get adminAddAction;

  /// No description provided for @adminAddMissingRecords.
  ///
  /// In tr, this message translates to:
  /// **'Eksik kayıtları ekle'**
  String get adminAddMissingRecords;

  /// No description provided for @adminPoolLabelHomeNamazWisdom.
  ///
  /// In tr, this message translates to:
  /// **'Ana sayfa namaz kartı'**
  String get adminPoolLabelHomeNamazWisdom;

  /// No description provided for @adminPoolLabelPersonalizedQuotes.
  ///
  /// In tr, this message translates to:
  /// **'Kişiselleştirilmiş sözler'**
  String get adminPoolLabelPersonalizedQuotes;

  /// No description provided for @adminPoolLabelWidgetQuote.
  ///
  /// In tr, this message translates to:
  /// **'Widget / ana ekran sözü'**
  String get adminPoolLabelWidgetQuote;

  /// No description provided for @adminPoolLabelZikirDailyReflections.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakit kartı (zikir yansıması)'**
  String get adminPoolLabelZikirDailyReflections;

  /// No description provided for @adminPoolLabelHealingComfort.
  ///
  /// In tr, this message translates to:
  /// **'İyileşme / teselli sözleri'**
  String get adminPoolLabelHealingComfort;

  /// No description provided for @adminPoolLabelHubGelisimIslamic.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim — İslami kart'**
  String get adminPoolLabelHubGelisimIslamic;

  /// No description provided for @adminPoolLabelHubGelisimMedical.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim — sağlık kartı'**
  String get adminPoolLabelHubGelisimMedical;

  /// No description provided for @adminPoolLabelHubArinmaIslamic.
  ///
  /// In tr, this message translates to:
  /// **'Arınma — İslami kart'**
  String get adminPoolLabelHubArinmaIslamic;

  /// No description provided for @adminPoolLabelHubArinmaMedical.
  ///
  /// In tr, this message translates to:
  /// **'Arınma — sağlık kartı'**
  String get adminPoolLabelHubArinmaMedical;

  /// No description provided for @adminPoolLabelNotificationArinmaBodies.
  ///
  /// In tr, this message translates to:
  /// **'Arınma bildirimi metinleri'**
  String get adminPoolLabelNotificationArinmaBodies;

  /// No description provided for @adminPoolLabelNotificationNamazWisdom.
  ///
  /// In tr, this message translates to:
  /// **'Namaz bildirimi sözleri'**
  String get adminPoolLabelNotificationNamazWisdom;

  /// No description provided for @adminPoolLabelNotificationDailyNamazReminder.
  ///
  /// In tr, this message translates to:
  /// **'Günlük namaz hatırlatıcı metinleri'**
  String get adminPoolLabelNotificationDailyNamazReminder;

  /// No description provided for @adminSearchResultsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} sonuç'**
  String adminSearchResultsCount(int count);

  /// No description provided for @adminPoolEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu havuz boş — öğe ekleyebilirsin.'**
  String get adminPoolEmptyHint;

  /// No description provided for @adminSearchNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Aramana uyan sonuç yok.'**
  String get adminSearchNoResults;

  /// No description provided for @adminTapToEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenlemek için dokun'**
  String get adminTapToEdit;

  /// No description provided for @adminEditTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get adminEditTooltip;

  /// No description provided for @adminInspireHint.
  ///
  /// In tr, this message translates to:
  /// **'Kart ekle, metni doldur, sonra kaydet. Arka plan görselleri: {count} adet.'**
  String adminInspireHint(int count);

  /// No description provided for @adminInspireAddNewCard.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kart ekle'**
  String get adminInspireAddNewCard;

  /// No description provided for @adminRefreshFromFirestore.
  ///
  /// In tr, this message translates to:
  /// **'Firestore’dan yenile'**
  String get adminRefreshFromFirestore;

  /// No description provided for @adminInspireVersionCards.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm: v{version} · {count} kart'**
  String adminInspireVersionCards(Object version, int count);

  /// No description provided for @adminInspireNoCardsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Keşfet kartı yok'**
  String get adminInspireNoCardsYet;

  /// No description provided for @adminInspireAddFirstCard.
  ///
  /// In tr, this message translates to:
  /// **'İlk kartı ekle'**
  String get adminInspireAddFirstCard;

  /// No description provided for @adminInspireCardLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kart {index}'**
  String adminInspireCardLabel(int index);

  /// No description provided for @adminInspireEmptyTextBadge.
  ///
  /// In tr, this message translates to:
  /// **'Boş metin'**
  String get adminInspireEmptyTextBadge;

  /// No description provided for @adminInspireDuplicateTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get adminInspireDuplicateTooltip;

  /// No description provided for @adminInspireShuffleDesignTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Tasarımı yeniden karıştır'**
  String get adminInspireShuffleDesignTooltip;

  /// No description provided for @adminInspireEmptyTextPreview.
  ///
  /// In tr, this message translates to:
  /// **'(boş metin — #{index})'**
  String adminInspireEmptyTextPreview(int index);

  /// No description provided for @adminInspireImageNumberLabel.
  ///
  /// In tr, this message translates to:
  /// **'Görsel #{index}'**
  String adminInspireImageNumberLabel(Object index);

  /// No description provided for @adminInspireContentKindLabel.
  ///
  /// In tr, this message translates to:
  /// **'İçerik türü'**
  String get adminInspireContentKindLabel;

  /// No description provided for @adminInspireContentKindQuote.
  ///
  /// In tr, this message translates to:
  /// **'Özlü söz'**
  String get adminInspireContentKindQuote;

  /// No description provided for @adminInspireContentKindVerse.
  ///
  /// In tr, this message translates to:
  /// **'Âyet'**
  String get adminInspireContentKindVerse;

  /// No description provided for @adminInspireContentKindHadith.
  ///
  /// In tr, this message translates to:
  /// **'Hadis'**
  String get adminInspireContentKindHadith;

  /// No description provided for @adminInspireShowInMainFeedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ana akışta göster (Karma)'**
  String get adminInspireShowInMainFeedTitle;

  /// No description provided for @adminInspireShowInMainFeedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İşaretli değilse yalnızca Ayet veya Hadis filtresinden görünür.'**
  String get adminInspireShowInMainFeedSubtitle;

  /// No description provided for @adminInspireTurkishTextLabel.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe metin *'**
  String get adminInspireTurkishTextLabel;

  /// No description provided for @adminOptionalArabicLabel.
  ///
  /// In tr, this message translates to:
  /// **'Arapça (isteğe bağlı)'**
  String get adminOptionalArabicLabel;

  /// No description provided for @adminOptionalSourceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak (isteğe bağlı)'**
  String get adminOptionalSourceLabel;

  /// No description provided for @adminOptionalVerseRefLabel.
  ///
  /// In tr, this message translates to:
  /// **'Âyet / sure (isteğe bağlı)'**
  String get adminOptionalVerseRefLabel;

  /// No description provided for @adminInspireSaveAllChanges.
  ///
  /// In tr, this message translates to:
  /// **'Tüm kart değişikliklerini kaydet'**
  String get adminInspireSaveAllChanges;

  /// No description provided for @adminDiagnosticsHint.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik bildirim tanısı. Buradaki loglar planlama denemelerini kaydeder.'**
  String get adminDiagnosticsHint;

  /// No description provided for @adminDiagnosticsStatusSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Durum özeti'**
  String get adminDiagnosticsStatusSummaryTitle;

  /// No description provided for @adminDiagnosticsEnabled.
  ///
  /// In tr, this message translates to:
  /// **'açık'**
  String get adminDiagnosticsEnabled;

  /// No description provided for @adminDiagnosticsDisabled.
  ///
  /// In tr, this message translates to:
  /// **'kapalı'**
  String get adminDiagnosticsDisabled;

  /// No description provided for @adminDiagnosticsPrayerStatus.
  ///
  /// In tr, this message translates to:
  /// **'Namaz: {status}'**
  String adminDiagnosticsPrayerStatus(Object status);

  /// No description provided for @adminDiagnosticsDailyStatus.
  ///
  /// In tr, this message translates to:
  /// **'Günlük: {status}'**
  String adminDiagnosticsDailyStatus(Object status);

  /// No description provided for @adminDiagnosticsMilestoneStatus.
  ///
  /// In tr, this message translates to:
  /// **'Eşik: {status}'**
  String adminDiagnosticsMilestoneStatus(Object status);

  /// No description provided for @adminDiagnosticsTaskStatus.
  ///
  /// In tr, this message translates to:
  /// **'Görev: {status}'**
  String adminDiagnosticsTaskStatus(Object status);

  /// No description provided for @adminDiagnosticsZikirStatus.
  ///
  /// In tr, this message translates to:
  /// **'Zikir: {status}'**
  String adminDiagnosticsZikirStatus(Object status);

  /// No description provided for @adminDiagnosticsPendingQueue.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen kuyruk: {count}'**
  String adminDiagnosticsPendingQueue(int count);

  /// No description provided for @adminRefreshAction.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get adminRefreshAction;

  /// No description provided for @adminDiagnosticsExportLog.
  ///
  /// In tr, this message translates to:
  /// **'Log dışa aktar'**
  String get adminDiagnosticsExportLog;

  /// No description provided for @adminDiagnosticsClearLog.
  ///
  /// In tr, this message translates to:
  /// **'Log temizle'**
  String get adminDiagnosticsClearLog;

  /// No description provided for @adminDiagnosticsRecentEvents.
  ///
  /// In tr, this message translates to:
  /// **'Son olaylar ({count})'**
  String adminDiagnosticsRecentEvents(int count);

  /// No description provided for @adminDiagnosticsNoLogsHint.
  ///
  /// In tr, this message translates to:
  /// **'Henüz log yok. Uygulamayı yeniden açıp bir süre kullan, sonra yenile.'**
  String get adminDiagnosticsNoLogsHint;

  /// No description provided for @adminDiagnosticsOutcomeOk.
  ///
  /// In tr, this message translates to:
  /// **'başarılı'**
  String get adminDiagnosticsOutcomeOk;

  /// No description provided for @adminDiagnosticsOutcomeError.
  ///
  /// In tr, this message translates to:
  /// **'hata'**
  String get adminDiagnosticsOutcomeError;

  /// No description provided for @adminDiagnosticsOutcomeCooldownSkip.
  ///
  /// In tr, this message translates to:
  /// **'atlandı (bekleme süresi)'**
  String get adminDiagnosticsOutcomeCooldownSkip;

  /// No description provided for @adminDiagnosticsOutcomePendingGuardSkip.
  ///
  /// In tr, this message translates to:
  /// **'atlandı (bekleyen koruması)'**
  String get adminDiagnosticsOutcomePendingGuardSkip;

  /// No description provided for @adminDiagnosticsOutcomeDisabled.
  ///
  /// In tr, this message translates to:
  /// **'devre dışı'**
  String get adminDiagnosticsOutcomeDisabled;

  /// No description provided for @adminDiagnosticsOutcomeInvalidPayloadSkip.
  ///
  /// In tr, this message translates to:
  /// **'atlandı (geçersiz yük)'**
  String get adminDiagnosticsOutcomeInvalidPayloadSkip;

  /// No description provided for @adminDiagnosticsOutcomeUnknown.
  ///
  /// In tr, this message translates to:
  /// **'bilinmiyor ({outcome})'**
  String adminDiagnosticsOutcomeUnknown(Object outcome);

  /// No description provided for @adminDevOffsetSavedAndRescheduled.
  ///
  /// In tr, this message translates to:
  /// **'Kaydırma kaydedildi; bildirimler yenilendi.'**
  String get adminDevOffsetSavedAndRescheduled;

  /// No description provided for @adminDevOffsetReset.
  ///
  /// In tr, this message translates to:
  /// **'Kaydırma sıfırlandı.'**
  String get adminDevOffsetReset;

  /// No description provided for @adminDevOffsetDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı (API saatleri)'**
  String get adminDevOffsetDisabled;

  /// No description provided for @adminDevOffsetForwardMinutes.
  ///
  /// In tr, this message translates to:
  /// **'Öne: {minutes} dk'**
  String adminDevOffsetForwardMinutes(int minutes);

  /// No description provided for @adminDevOffsetBackwardMinutes.
  ///
  /// In tr, this message translates to:
  /// **'Geriye: {minutes} dk'**
  String adminDevOffsetBackwardMinutes(int minutes);

  /// No description provided for @adminDevPrayerOffsetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakit kaydırma (yalnızca bu cihazda)'**
  String get adminDevPrayerOffsetTitle;

  /// No description provided for @adminDevPrayerOffsetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Negatif = tüm vakitleri öne çeker (bildirim planı da buna göre). API / sunucu değişmez.'**
  String get adminDevPrayerOffsetSubtitle;

  /// No description provided for @adminDevResetAction.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get adminDevResetAction;

  /// No description provided for @adminDevSaveAndRescheduleAction.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet ve yeniden planla'**
  String get adminDevSaveAndRescheduleAction;

  /// No description provided for @adminDevNotificationTestsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim testleri'**
  String get adminDevNotificationTestsTitle;

  /// No description provided for @adminDevNotificationTestsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut kanal ve ses yollarını anında denemek için.'**
  String get adminDevNotificationTestsSubtitle;

  /// No description provided for @adminDevPrayerNotificationSent.
  ///
  /// In tr, this message translates to:
  /// **'Namaz bildirimi gönderildi.'**
  String get adminDevPrayerNotificationSent;

  /// No description provided for @adminDevPrayerNotificationNowAction.
  ///
  /// In tr, this message translates to:
  /// **'Namaz bildirimi (şimdi)'**
  String get adminDevPrayerNotificationNowAction;

  /// No description provided for @adminDevAppNotificationSent.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama bildirimi gönderildi.'**
  String get adminDevAppNotificationSent;

  /// No description provided for @adminDevAppNotificationNowAction.
  ///
  /// In tr, this message translates to:
  /// **'Arınma / uygulama bildirimi (şimdi)'**
  String get adminDevAppNotificationNowAction;

  /// No description provided for @adminDevCrashlyticsTestTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çökme raporu testi (Crashlytics)'**
  String get adminDevCrashlyticsTestTitle;

  /// No description provided for @adminDevCrashlyticsDebugHint.
  ///
  /// In tr, this message translates to:
  /// **'Debug build: toplama KAPALI. Test etmek için release APK kur.'**
  String get adminDevCrashlyticsDebugHint;

  /// No description provided for @adminDevCrashlyticsReleaseHint.
  ///
  /// In tr, this message translates to:
  /// **'Aşağıdaki butonlar Firebase Console → Crashlytics’e gerçek bir hata gönderir. Raporun göründüğünü doğruladıktan sonra kaldırabilirsin.'**
  String get adminDevCrashlyticsReleaseHint;

  /// No description provided for @adminFirebaseNotReady.
  ///
  /// In tr, this message translates to:
  /// **'Firebase hazır değil.'**
  String get adminFirebaseNotReady;

  /// No description provided for @adminDevCrashlyticsNonFatalSent.
  ///
  /// In tr, this message translates to:
  /// **'Non-fatal kayıt gönderildi. Console’da birkaç dakika içinde görünür.'**
  String get adminDevCrashlyticsNonFatalSent;

  /// No description provided for @adminErrorWithReason.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {reason}'**
  String adminErrorWithReason(Object reason);

  /// No description provided for @adminDevSendNonFatalTestAction.
  ///
  /// In tr, this message translates to:
  /// **'Test: non-fatal hata gönder'**
  String get adminDevSendNonFatalTestAction;

  /// No description provided for @adminDevCrashNowFatalAction.
  ///
  /// In tr, this message translates to:
  /// **'Test: uygulamayı ŞİMDİ çöktür (fatal)'**
  String get adminDevCrashNowFatalAction;

  /// No description provided for @adminDevCrashDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı çöktür?'**
  String get adminDevCrashDialogTitle;

  /// No description provided for @adminDevCrashDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama birkaç saniye içinde kapanacak. Telefonda tekrar açtığında rapor Firebase’e yüklenir (birkaç dakika sonra Console’da görünür).\n\nSadece Crashlytics testini doğrulamak için kullan.'**
  String get adminDevCrashDialogBody;

  /// No description provided for @adminDevCrashAction.
  ///
  /// In tr, this message translates to:
  /// **'Çöktür'**
  String get adminDevCrashAction;

  /// No description provided for @adminDiagnosticsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tanılama'**
  String get adminDiagnosticsTitle;

  /// No description provided for @adminDevPlatformLabel.
  ///
  /// In tr, this message translates to:
  /// **'Platform'**
  String get adminDevPlatformLabel;

  /// No description provided for @adminDevBuildLabel.
  ///
  /// In tr, this message translates to:
  /// **'Build'**
  String get adminDevBuildLabel;

  /// No description provided for @adminDevBuildModeRelease.
  ///
  /// In tr, this message translates to:
  /// **'release'**
  String get adminDevBuildModeRelease;

  /// No description provided for @adminDevBuildModeProfile.
  ///
  /// In tr, this message translates to:
  /// **'profile'**
  String get adminDevBuildModeProfile;

  /// No description provided for @adminDevBuildModeDebug.
  ///
  /// In tr, this message translates to:
  /// **'debug'**
  String get adminDevBuildModeDebug;

  /// No description provided for @adminDevPlatformWeb.
  ///
  /// In tr, this message translates to:
  /// **'web'**
  String get adminDevPlatformWeb;

  /// No description provided for @adminDevPlatformUnknown.
  ///
  /// In tr, this message translates to:
  /// **'bilinmiyor'**
  String get adminDevPlatformUnknown;

  /// No description provided for @adminDevUidLabel.
  ///
  /// In tr, this message translates to:
  /// **'UID'**
  String get adminDevUidLabel;

  /// No description provided for @adminDevPendingNotificationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen bildirim'**
  String get adminDevPendingNotificationLabel;

  /// No description provided for @adminDevTapToRefresh.
  ///
  /// In tr, this message translates to:
  /// **'yenilemek için dokun'**
  String get adminDevTapToRefresh;

  /// No description provided for @adminDiagnosticsError.
  ///
  /// In tr, this message translates to:
  /// **'hata'**
  String get adminDiagnosticsError;

  /// No description provided for @adminPoolDataUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Havuz verisi şu anda alınamıyor.'**
  String get adminPoolDataUnavailable;

  /// No description provided for @adminPoolChangeAction.
  ///
  /// In tr, this message translates to:
  /// **'Havuz değişikliği'**
  String get adminPoolChangeAction;

  /// No description provided for @adminReviewBeforeSaveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetmeden önce kontrol'**
  String get adminReviewBeforeSaveTitle;

  /// No description provided for @adminPoolSaved.
  ///
  /// In tr, this message translates to:
  /// **'Havuz kaydedildi.'**
  String get adminPoolSaved;

  /// No description provided for @adminPoolSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Havuz kaydedilemedi.'**
  String get adminPoolSaveFailed;

  /// No description provided for @adminUseSeedAllForPool.
  ///
  /// In tr, this message translates to:
  /// **'Bu havuz için “Tüm havuzları tohumla” kullanın.'**
  String get adminUseSeedAllForPool;

  /// No description provided for @adminNoBuiltInSeedForPool.
  ///
  /// In tr, this message translates to:
  /// **'Bu havuz için yerleşik tohumlama tanımlı değil.'**
  String get adminNoBuiltInSeedForPool;

  /// No description provided for @adminSeedSelectedPoolDefaults.
  ///
  /// In tr, this message translates to:
  /// **'Seçili havuzu varsayılanla yenile'**
  String get adminSeedSelectedPoolDefaults;

  /// No description provided for @adminPoolNotLoadedYet.
  ///
  /// In tr, this message translates to:
  /// **'Havuz henüz yüklenmedi.'**
  String get adminPoolNotLoadedYet;

  /// No description provided for @adminPoolBackupShareText.
  ///
  /// In tr, this message translates to:
  /// **'Arın havuz yedeği — {poolId} ({timestamp})'**
  String adminPoolBackupShareText(Object poolId, Object timestamp);

  /// No description provided for @adminPoolBackupShareSubject.
  ///
  /// In tr, this message translates to:
  /// **'Arın havuz yedeği'**
  String get adminPoolBackupShareSubject;

  /// No description provided for @adminBackupCreationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yedek oluşturulamadı: {error}'**
  String adminBackupCreationFailed(Object error);

  /// No description provided for @adminBackupInvalidJsonObject.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyası okunamadı: JSON nesnesi bekleniyor.'**
  String get adminBackupInvalidJsonObject;

  /// No description provided for @adminBackupPoolDocumentMissing.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyasında havuz belgesi bulunamadı.'**
  String get adminBackupPoolDocumentMissing;

  /// No description provided for @adminBackupItemsListMissing.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyasında \"items\" listesi yok.'**
  String get adminBackupItemsListMissing;

  /// No description provided for @adminBackupContainsUnreadableRecords.
  ///
  /// In tr, this message translates to:
  /// **'Yedekte okunamayan kayıt var; dosya değiştirilmemiş olmalı.'**
  String get adminBackupContainsUnreadableRecords;

  /// No description provided for @adminUnknownPool.
  ///
  /// In tr, this message translates to:
  /// **'bilinmeyen havuz'**
  String get adminUnknownPool;

  /// No description provided for @adminRestoreBackupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedeği geri yükle'**
  String get adminRestoreBackupTitle;

  /// No description provided for @adminRestoreBackupDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Dosya: {fileName}\nYedekteki havuz: {sourcePool}\nSeçili havuz: {selectedPool}\nKayıt sayısı: {itemCount}\n\n{warningText}Bu kayıtlar seçili havuza yazılacak. Devam edilsin mi?'**
  String adminRestoreBackupDialogBody(
    Object fileName,
    Object sourcePool,
    Object selectedPool,
    int itemCount,
    Object warningText,
  );

  /// No description provided for @adminRestoreBackupDifferentPoolWarning.
  ///
  /// In tr, this message translates to:
  /// **'Uyarı: Yedek farklı bir havuzdan geliyor.'**
  String get adminRestoreBackupDifferentPoolWarning;

  /// No description provided for @adminRestoreFromBackupAction.
  ///
  /// In tr, this message translates to:
  /// **'Yedekten geri yükleme ({fileName})'**
  String adminRestoreFromBackupAction(Object fileName);

  /// No description provided for @adminRestoreBackupFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyası geri yüklenemedi.'**
  String get adminRestoreBackupFailed;

  /// No description provided for @adminRequiresManagerOrFullAccessForMissingSeed.
  ///
  /// In tr, this message translates to:
  /// **'Eksik kayıt ekleme için manager veya tam yetki gerekir.'**
  String get adminRequiresManagerOrFullAccessForMissingSeed;

  /// No description provided for @adminRequiresFullAccessForReset.
  ///
  /// In tr, this message translates to:
  /// **'Tam sıfırlama için tam yetki gerekir.'**
  String get adminRequiresFullAccessForReset;

  /// No description provided for @adminBulkPreviewFailed.
  ///
  /// In tr, this message translates to:
  /// **'Toplu işlem ön izlemesi alınamadı.'**
  String get adminBulkPreviewFailed;

  /// No description provided for @adminSeedAllPoolsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm havuzları tohumla'**
  String get adminSeedAllPoolsTitle;

  /// No description provided for @adminMergeSeedPreview.
  ///
  /// In tr, this message translates to:
  /// **'Ön izleme:\n• Kontrol edilen havuz: {poolCount}\n• Değişecek havuz: {changedPoolCount}\n• Eklenecek kayıt: {addedItemCount}\n• İşlem sonrası toplam kayıt: {targetItemCount}\n\nMevcut manuel değişiklikler korunur. Devam edilsin mi?'**
  String adminMergeSeedPreview(
    int poolCount,
    int changedPoolCount,
    int addedItemCount,
    int targetItemCount,
  );

  /// No description provided for @adminResetSeedPreview.
  ///
  /// In tr, this message translates to:
  /// **'Ön izleme:\n• Kontrol edilen havuz: {poolCount}\n• Üzerine yazılacak havuz: {changedPoolCount}\n• Mevcut kayıt: {currentItemCount}\n• Yeni kayıt: {targetItemCount}\n\nMevcut içerik silinir. Önce yedek aldığından emin ol. Devam edilsin mi?'**
  String adminResetSeedPreview(
    int poolCount,
    int changedPoolCount,
    int currentItemCount,
    int targetItemCount,
  );

  /// No description provided for @adminOverwriteAction.
  ///
  /// In tr, this message translates to:
  /// **'Üzerine yaz'**
  String get adminOverwriteAction;

  /// No description provided for @adminMissingItemsAddedToPools.
  ///
  /// In tr, this message translates to:
  /// **'Eksik öğeler havuzlara eklendi.'**
  String get adminMissingItemsAddedToPools;

  /// No description provided for @adminAllPoolsOverwritten.
  ///
  /// In tr, this message translates to:
  /// **'Tüm havuzlar yeniden yazıldı.'**
  String get adminAllPoolsOverwritten;

  /// No description provided for @adminAuditAddMissingToAllPools.
  ///
  /// In tr, this message translates to:
  /// **'Tüm havuzlara eksikleri ekle'**
  String get adminAuditAddMissingToAllPools;

  /// No description provided for @adminAuditResetAllPools.
  ///
  /// In tr, this message translates to:
  /// **'Tüm havuzları sıfırla'**
  String get adminAuditResetAllPools;

  /// No description provided for @adminInspireCardsUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet kartları şu anda alınamıyor.'**
  String get adminInspireCardsUnavailable;

  /// No description provided for @adminRequiresManagerOrFullAccessForDiagnostics.
  ///
  /// In tr, this message translates to:
  /// **'Tanı işlemleri için manager veya tam yetki gerekir.'**
  String get adminRequiresManagerOrFullAccessForDiagnostics;

  /// No description provided for @adminNotificationLogsCleared.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim logları temizlendi.'**
  String get adminNotificationLogsCleared;

  /// No description provided for @adminNotificationLogsShareText.
  ///
  /// In tr, this message translates to:
  /// **'Arın bildirim logları ({timestamp})'**
  String adminNotificationLogsShareText(Object timestamp);

  /// No description provided for @adminNotificationLogsShareSubject.
  ///
  /// In tr, this message translates to:
  /// **'Arın bildirim tanısı'**
  String get adminNotificationLogsShareSubject;

  /// No description provided for @adminLogExportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Log dışa aktarımı başarısız: {error}'**
  String adminLogExportFailed(Object error);

  /// No description provided for @adminInspireCardHasEmptyTurkishText.
  ///
  /// In tr, this message translates to:
  /// **'Boş Türkçe metinli kart var; doldur veya sil.'**
  String get adminInspireCardHasEmptyTurkishText;

  /// No description provided for @adminReviewCardsBeforeSaveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kartları kaydetmeden önce kontrol'**
  String get adminReviewCardsBeforeSaveTitle;

  /// No description provided for @adminInspireCardsWillBeUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet kartları güncellenecek'**
  String get adminInspireCardsWillBeUpdated;

  /// No description provided for @adminInspireCardsSaved.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet kartları kaydedildi.'**
  String get adminInspireCardsSaved;

  /// No description provided for @adminInspireCardsSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet kartları kaydedilemedi.'**
  String get adminInspireCardsSaveFailed;

  /// No description provided for @adminAuditInspireCardsUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet kartları güncellendi'**
  String get adminAuditInspireCardsUpdated;

  /// No description provided for @adminCurrentRecordCount.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut kayıt: {count}'**
  String adminCurrentRecordCount(int count);

  /// No description provided for @adminRecordCountToSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilecek kayıt: {count}'**
  String adminRecordCountToSave(int count);

  /// No description provided for @adminChangedRowCount.
  ///
  /// In tr, this message translates to:
  /// **'Değişen satır: {count}'**
  String adminChangedRowCount(int count);

  /// No description provided for @adminConcurrentEditWarning.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir yönetici bu sırada kayıt yaptıysa sistem uyarı verir.'**
  String get adminConcurrentEditWarning;

  /// No description provided for @adminSaveAction.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get adminSaveAction;

  /// No description provided for @adminGrantsListFetchFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yetki listesi alınamadı.'**
  String get adminGrantsListFetchFailed;

  /// No description provided for @adminGrantAccessAction.
  ///
  /// In tr, this message translates to:
  /// **'Yetki ver'**
  String get adminGrantAccessAction;

  /// No description provided for @adminEditGrantAction.
  ///
  /// In tr, this message translates to:
  /// **'Yetkiyi düzenle'**
  String get adminEditGrantAction;

  /// No description provided for @adminEmailOrUidLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya UID'**
  String get adminEmailOrUidLabel;

  /// No description provided for @adminLevelLabel.
  ///
  /// In tr, this message translates to:
  /// **'Seviye'**
  String get adminLevelLabel;

  /// No description provided for @adminRoleContentLabel.
  ///
  /// In tr, this message translates to:
  /// **'content - içerik'**
  String get adminRoleContentLabel;

  /// No description provided for @adminRoleManagerLabel.
  ///
  /// In tr, this message translates to:
  /// **'manager - operasyon'**
  String get adminRoleManagerLabel;

  /// No description provided for @adminRoleDeveloperLabel.
  ///
  /// In tr, this message translates to:
  /// **'developer - tam yetki'**
  String get adminRoleDeveloperLabel;

  /// No description provided for @adminFullAccessRequiredForGrantManagement.
  ///
  /// In tr, this message translates to:
  /// **'Yetki yönetimi için tam yetki gerekir.'**
  String get adminFullAccessRequiredForGrantManagement;

  /// No description provided for @adminEmailOrUidCannotBeEmpty.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya UID boş olamaz.'**
  String get adminEmailOrUidCannotBeEmpty;

  /// No description provided for @adminAccountAlreadyFullAccess.
  ///
  /// In tr, this message translates to:
  /// **'Bu hesap uygulama içinde zaten tam yetkilidir.'**
  String get adminAccountAlreadyFullAccess;

  /// No description provided for @adminGrantSaved.
  ///
  /// In tr, this message translates to:
  /// **'Yetki kaydedildi.'**
  String get adminGrantSaved;

  /// No description provided for @adminGrantSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yetki kaydedilemedi.'**
  String get adminGrantSaveFailed;

  /// No description provided for @adminAuditGrantSaved.
  ///
  /// In tr, this message translates to:
  /// **'Admin yetkisi verildi/güncellendi'**
  String get adminAuditGrantSaved;

  /// No description provided for @adminFullAccessAccountCannotBeRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Bu hesap uygulama içinde tam yetkilidir; panelden kaldırılamaz.'**
  String get adminFullAccessAccountCannotBeRemoved;

  /// No description provided for @adminRemoveGrantTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yetkiyi kaldır'**
  String get adminRemoveGrantTitle;

  /// No description provided for @adminRemoveGrantMessage.
  ///
  /// In tr, this message translates to:
  /// **'{label} için yönetim yetkisi kaldırılacak.'**
  String adminRemoveGrantMessage(Object label);

  /// No description provided for @adminGrantRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Yetki kaldırıldı.'**
  String get adminGrantRemoved;

  /// No description provided for @adminGrantRemoveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yetki kaldırılamadı.'**
  String get adminGrantRemoveFailed;

  /// No description provided for @adminAuditGrantRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Admin yetkisi kaldırıldı'**
  String get adminAuditGrantRemoved;

  /// No description provided for @adminEditItemTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öğeyi düzenle'**
  String get adminEditItemTitle;

  /// No description provided for @adminAddItemTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öğe ekle'**
  String get adminAddItemTitle;

  /// No description provided for @adminWordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Söz'**
  String get adminWordLabel;

  /// No description provided for @adminTextLabel.
  ///
  /// In tr, this message translates to:
  /// **'Metin'**
  String get adminTextLabel;

  /// No description provided for @adminTurkishTextLabel.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe metin'**
  String get adminTurkishTextLabel;

  /// No description provided for @adminTurkishLabel.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get adminTurkishLabel;

  /// No description provided for @adminArabicLabel.
  ///
  /// In tr, this message translates to:
  /// **'Arapça'**
  String get adminArabicLabel;

  /// No description provided for @adminTypeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get adminTypeLabel;

  /// No description provided for @adminReferenceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Referans'**
  String get adminReferenceLabel;

  /// No description provided for @adminTitleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get adminTitleLabel;

  /// No description provided for @adminOptionalSourceReferenceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak / referans (isteğe bağlı)'**
  String get adminOptionalSourceReferenceLabel;

  /// No description provided for @adminWordCannotBeEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Söz boş olamaz.'**
  String get adminWordCannotBeEmpty;

  /// No description provided for @adminTextCannotBeEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Metin boş olamaz.'**
  String get adminTextCannotBeEmpty;

  /// No description provided for @adminTurkishTextCannotBeEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe metin boş olamaz.'**
  String get adminTurkishTextCannotBeEmpty;

  /// No description provided for @adminTurkishAndArabicRequired.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe ve Arapça alanları gerekli.'**
  String get adminTurkishAndArabicRequired;

  /// No description provided for @adminTurkishArabicReferenceRequired.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe, Arapça ve referans gerekli.'**
  String get adminTurkishArabicReferenceRequired;

  /// No description provided for @adminTitleAndTextRequired.
  ///
  /// In tr, this message translates to:
  /// **'Başlık ve metin gerekli.'**
  String get adminTitleAndTextRequired;

  /// No description provided for @adminPoolItemWillBeEdited.
  ///
  /// In tr, this message translates to:
  /// **'Havuz öğesi düzenlenecek'**
  String get adminPoolItemWillBeEdited;

  /// No description provided for @adminNewPoolItemWillBeAdded.
  ///
  /// In tr, this message translates to:
  /// **'Havuza yeni öğe eklenecek'**
  String get adminNewPoolItemWillBeAdded;

  /// No description provided for @adminVersionConflictError.
  ///
  /// In tr, this message translates to:
  /// **'Bu içerik başka bir yönetici tarafından güncellenmiş. Lütfen yenileyip tekrar dene.'**
  String get adminVersionConflictError;

  /// No description provided for @adminNoPermissionForOperation.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için yetkiniz yok.'**
  String get adminNoPermissionForOperation;

  /// No description provided for @adminNetworkOrServiceUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı zayıf veya servis geçici olarak kapalı.'**
  String get adminNetworkOrServiceUnavailable;

  /// No description provided for @adminOperationTimedOut.
  ///
  /// In tr, this message translates to:
  /// **'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.'**
  String get adminOperationTimedOut;

  /// No description provided for @adminSessionCouldNotBeVerified.
  ///
  /// In tr, this message translates to:
  /// **'Oturum doğrulanamadı. Lütfen tekrar giriş yapın.'**
  String get adminSessionCouldNotBeVerified;

  /// No description provided for @adminAuthorizationCouldNotBeVerified.
  ///
  /// In tr, this message translates to:
  /// **'Yetki doğrulanamadı'**
  String get adminAuthorizationCouldNotBeVerified;

  /// No description provided for @adminAuthorizationCheckUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Şu anda yetki kontrolü yapılamıyor.\nİnternet bağlantını kontrol edip tekrar dene.'**
  String get adminAuthorizationCheckUnavailable;

  /// No description provided for @adminBackToSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlara dön'**
  String get adminBackToSettings;

  /// No description provided for @adminNoAccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'Erişim yok'**
  String get adminNoAccessTitle;

  /// No description provided for @adminPageForAdminsOnly.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfa yalnızca yöneticiler içindir.'**
  String get adminPageForAdminsOnly;

  /// No description provided for @adminPanelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yönetim paneli'**
  String get adminPanelTitle;

  /// No description provided for @adminPoolsTab.
  ///
  /// In tr, this message translates to:
  /// **'Havuzlar'**
  String get adminPoolsTab;

  /// No description provided for @adminInspireCardsTab.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet kartları'**
  String get adminInspireCardsTab;

  /// No description provided for @adminDiagnosticsTab.
  ///
  /// In tr, this message translates to:
  /// **'Tanı & log'**
  String get adminDiagnosticsTab;

  /// No description provided for @adminDeveloperTab.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici'**
  String get adminDeveloperTab;

  /// No description provided for @adminGrantsTab.
  ///
  /// In tr, this message translates to:
  /// **'Yetkiler'**
  String get adminGrantsTab;

  /// No description provided for @adminSectionOnlyForFullAccess.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm yalnızca tam yetkiye açıktır.'**
  String get adminSectionOnlyForFullAccess;

  /// No description provided for @adminDeveloperToolsDeveloperOnly.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici araçlarını sadece developer seviyesi kullanabilir.'**
  String get adminDeveloperToolsDeveloperOnly;

  /// No description provided for @adminDeletePoolItemTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öğeyi havuzdan sil'**
  String get adminDeletePoolItemTitle;

  /// No description provided for @adminDeletePoolItemMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu öğe \"{poolId}\" havuzundan kalıcı olarak silinecek ve Firestore’a hemen yazılacak. Geri alınamaz.'**
  String adminDeletePoolItemMessage(Object poolId);

  /// No description provided for @adminPoolItemWillBeDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Havuzdan öğe silinecek'**
  String get adminPoolItemWillBeDeleted;

  /// No description provided for @adminRemoveCardFromListTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kartı listeden çıkar'**
  String get adminRemoveCardFromListTitle;

  /// No description provided for @adminRemoveCardFromListMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kart yerel listeden silinecek. Değişiklik Firestore’a yansımak için \"Kaydet\"e basman gerekir.'**
  String get adminRemoveCardFromListMessage;

  /// No description provided for @adminRemoveAction.
  ///
  /// In tr, this message translates to:
  /// **'Çıkar'**
  String get adminRemoveAction;

  /// No description provided for @adminDiagnosticsAccessDeniedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tanı ekranı manager ve tam yetkiye açıktır.'**
  String get adminDiagnosticsAccessDeniedTitle;

  /// No description provided for @adminDiagnosticsAccessDeniedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İçerik yöneticileri havuz ve Keşfet düzenleyebilir.'**
  String get adminDiagnosticsAccessDeniedSubtitle;

  /// No description provided for @adminRoleContentPlain.
  ///
  /// In tr, this message translates to:
  /// **'İçerik'**
  String get adminRoleContentPlain;

  /// No description provided for @adminRoleManagerPlain.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get adminRoleManagerPlain;

  /// No description provided for @adminRoleDeveloperPlain.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici'**
  String get adminRoleDeveloperPlain;

  /// No description provided for @adminRoleNonePlain.
  ///
  /// In tr, this message translates to:
  /// **'Yok'**
  String get adminRoleNonePlain;

  /// No description provided for @adminGrantManagementAccessDeniedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yetki yönetimi yalnızca tam yetkiye açıktır.'**
  String get adminGrantManagementAccessDeniedTitle;

  /// No description provided for @adminGrantManagementAccessDeniedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Admin seviyesi verme ve kaldırma işlemlerini developer yapar.'**
  String get adminGrantManagementAccessDeniedSubtitle;

  /// No description provided for @adminGrantHint.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya UID girip content, manager ya da developer seviyesi verebilirsin.'**
  String get adminGrantHint;

  /// No description provided for @adminFixedFullAccess.
  ///
  /// In tr, this message translates to:
  /// **'Sabit tam yetkililer: {emails}'**
  String adminFixedFullAccess(Object emails);

  /// No description provided for @adminDefinedGrants.
  ///
  /// In tr, this message translates to:
  /// **'Tanımlı yetkiler ({count})'**
  String adminDefinedGrants(int count);

  /// No description provided for @adminGrantsLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yetkiler yükleniyor...'**
  String get adminGrantsLoading;

  /// No description provided for @adminNoFirestoreGrantsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Firestore üzerinden eklenmiş yetki yok.'**
  String get adminNoFirestoreGrantsYet;

  /// No description provided for @surveyBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get surveyBack;

  /// No description provided for @surveyNext.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get surveyNext;

  /// No description provided for @namazIbadetWarningTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dikkat'**
  String get namazIbadetWarningTitle;

  /// No description provided for @namazIbadetWarningSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz takibi bir gösteriş alanı değil; kalbini huşû ve dürüstlükle düzenlemek içindir.'**
  String get namazIbadetWarningSubtitle;

  /// No description provided for @namazIbadetWarningBullet1.
  ///
  /// In tr, this message translates to:
  /// **'Tikleri yalnızca kendin için işaretle; riya veya başkasına baskı aracı olmasın.'**
  String get namazIbadetWarningBullet1;

  /// No description provided for @namazIbadetWarningBullet2.
  ///
  /// In tr, this message translates to:
  /// **'Vakit kaçırınca kendini küçümseme; her dönüş tövbe ve yeniden başlamaktır.'**
  String get namazIbadetWarningBullet2;

  /// No description provided for @namazIbadetWarningBullet3.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimleri istediğin zaman sistem ayarlarından yönetebilirsin; takip yük olmamalı.'**
  String get namazIbadetWarningBullet3;

  /// No description provided for @namazIbadetCommitmentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kendine sözün'**
  String get namazIbadetCommitmentTitle;

  /// No description provided for @namazIbadetCommitmentHint.
  ///
  /// In tr, this message translates to:
  /// **'Namazına dair içten bir cümle yaz (en az 8 karakter).'**
  String get namazIbadetCommitmentHint;

  /// No description provided for @namazIbadetCommitmentFieldHint.
  ///
  /// In tr, this message translates to:
  /// **'Kalbinden geçen bir cümle…'**
  String get namazIbadetCommitmentFieldHint;

  /// No description provided for @namazIbadetCommitmentTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen kendine bir söz yaz (en az 8 karakter).'**
  String get namazIbadetCommitmentTooShort;

  /// No description provided for @namazIbadetSealTitlePrefix.
  ///
  /// In tr, this message translates to:
  /// **'Sözünü mühürle'**
  String get namazIbadetSealTitlePrefix;

  /// No description provided for @namazIbadetSealHoldHint.
  ///
  /// In tr, this message translates to:
  /// **'Parmağını basılı tut'**
  String get namazIbadetSealHoldHint;

  /// No description provided for @namazIbadetSealSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Sözün kaydedildi. İbadet ekranına geçiyorsun.'**
  String get namazIbadetSealSuccess;

  /// No description provided for @namazIbadetSealEncourageNotHolding.
  ///
  /// In tr, this message translates to:
  /// **'Hazır olduğunda mührü basılı tutarak pekiştir.'**
  String get namazIbadetSealEncourageNotHolding;

  /// No description provided for @namazIbadetSealEncourageHolding.
  ///
  /// In tr, this message translates to:
  /// **'Nefesini yavaşlat, sözünü kalbine indir.'**
  String get namazIbadetSealEncourageHolding;

  /// No description provided for @namazIbadetPrepTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlık'**
  String get namazIbadetPrepTitle;

  /// No description provided for @namazIbadetExamplesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Örnekler'**
  String get namazIbadetExamplesTitle;

  /// No description provided for @closeAction.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get closeAction;

  /// No description provided for @saveAction.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get saveAction;

  /// No description provided for @selectAction.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get selectAction;

  /// No description provided for @quitPickerTemplateAlreadyExists.
  ///
  /// In tr, this message translates to:
  /// **'Bu program zaten listenizde; aynı şablondan yalnızca bir tane olabilir.'**
  String get quitPickerTemplateAlreadyExists;

  /// No description provided for @quitPickerOpenAction.
  ///
  /// In tr, this message translates to:
  /// **'Aç'**
  String get quitPickerOpenAction;

  /// No description provided for @quitPickerGoToListAction.
  ///
  /// In tr, this message translates to:
  /// **'Listeye git'**
  String get quitPickerGoToListAction;

  /// No description provided for @quitPickerTemplateScreenTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekrandan arınma'**
  String get quitPickerTemplateScreenTitle;

  /// No description provided for @quitPickerTemplateSmokingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sigaradan arınma'**
  String get quitPickerTemplateSmokingTitle;

  /// No description provided for @quitPickerTemplateAlcoholTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alkolden arınma'**
  String get quitPickerTemplateAlcoholTitle;

  /// No description provided for @quitPickerTemplateSubstanceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uyuşturucudan arınma'**
  String get quitPickerTemplateSubstanceTitle;

  /// No description provided for @quitPickerTemplateZinaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zinadan arınma'**
  String get quitPickerTemplateZinaTitle;

  /// No description provided for @quitPickerHeaderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kötü alışkanlıklardan arınma'**
  String get quitPickerHeaderTitle;

  /// No description provided for @quitPickerHeaderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kurtulmak istediğin alışkanlığı seç; özel bir hedef için alttaki kutuyu kullan.'**
  String get quitPickerHeaderSubtitle;

  /// No description provided for @quitPickerScreenLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ekran'**
  String get quitPickerScreenLabel;

  /// No description provided for @quitPickerScreenSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sınır ve dinginlik'**
  String get quitPickerScreenSubtitle;

  /// No description provided for @quitPickerSmokingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sigara'**
  String get quitPickerSmokingLabel;

  /// No description provided for @quitPickerAlcoholLabel.
  ///
  /// In tr, this message translates to:
  /// **'Alkol'**
  String get quitPickerAlcoholLabel;

  /// No description provided for @quitPickerSubstanceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Uyuşturucu'**
  String get quitPickerSubstanceLabel;

  /// No description provided for @quitPickerSubstanceSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Destek ve takip'**
  String get quitPickerSubstanceSubtitle;

  /// No description provided for @quitPickerZinaLabel.
  ///
  /// In tr, this message translates to:
  /// **'Zina'**
  String get quitPickerZinaLabel;

  /// No description provided for @quitPickerDefaultSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Arınma programı'**
  String get quitPickerDefaultSubtitle;

  /// No description provided for @quitPickerAlreadyAdded.
  ///
  /// In tr, this message translates to:
  /// **'Zaten ekli'**
  String get quitPickerAlreadyAdded;

  /// No description provided for @quitPickerAddCustomTitle.
  ///
  /// In tr, this message translates to:
  /// **'Özel ekle'**
  String get quitPickerAddCustomTitle;

  /// No description provided for @quitPickerAddCustomSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kendi arınma rutinini oluştur.'**
  String get quitPickerAddCustomSubtitle;

  /// No description provided for @buildProgramSetupQuranTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Kur\'an programı'**
  String get buildProgramSetupQuranTitle;

  /// No description provided for @buildProgramSetupDefaultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Program'**
  String get buildProgramSetupDefaultTitle;

  /// No description provided for @buildProgramSetupHeadlineQuran.
  ///
  /// In tr, this message translates to:
  /// **'Her güne bir sayfa'**
  String get buildProgramSetupHeadlineQuran;

  /// No description provided for @buildProgramSetupHeadlineDefault.
  ///
  /// In tr, this message translates to:
  /// **'Programını başlat'**
  String get buildProgramSetupHeadlineDefault;

  /// No description provided for @buildProgramSetupBadge.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlık adımı'**
  String get buildProgramSetupBadge;

  /// No description provided for @buildProgramSetupBodyQuran.
  ///
  /// In tr, this message translates to:
  /// **'En az bir sayfa — küçük ama süreklilik. İlerleme ve ipuçları bir sonraki ekranda seni bekliyor.'**
  String get buildProgramSetupBodyQuran;

  /// No description provided for @buildProgramSetupBodyDefault.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme ve ipuçları bir sonraki ekranda.'**
  String get buildProgramSetupBodyDefault;

  /// No description provided for @buildProgramSetupAlreadyActive.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Kur\'an programın zaten açık. Mevcut programa yönlendirildi.'**
  String get buildProgramSetupAlreadyActive;

  /// No description provided for @buildProgramSetupQuranHabitTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Kur\'an'**
  String get buildProgramSetupQuranHabitTitle;

  /// No description provided for @buildProgramSetupStartAction.
  ///
  /// In tr, this message translates to:
  /// **'Programı başlat'**
  String get buildProgramSetupStartAction;

  /// No description provided for @buildProgramSetupPrincipleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Azı sürekli, çoğu terkten hayırlı'**
  String get buildProgramSetupPrincipleTitle;

  /// No description provided for @buildProgramSetupPrincipleQuote.
  ///
  /// In tr, this message translates to:
  /// **'Hz. Peygamber (s.a.v.): \"Amellerin Allah\'a en sevimli olanı, az da olsa devamlı olanıdır.\"'**
  String get buildProgramSetupPrincipleQuote;

  /// No description provided for @buildProgramDetailNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Program bulunamadı'**
  String get buildProgramDetailNotFound;

  /// No description provided for @buildProgramDetailTabGeneral.
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get buildProgramDetailTabGeneral;

  /// No description provided for @buildProgramDetailTabTips.
  ///
  /// In tr, this message translates to:
  /// **'İpuçları'**
  String get buildProgramDetailTabTips;

  /// No description provided for @buildProgramDetailTabProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get buildProgramDetailTabProgress;

  /// No description provided for @buildProgramDetailTodayQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Bugün okuma hedefini tamamladın mı?'**
  String get buildProgramDetailTodayQuestion;

  /// No description provided for @buildProgramDetailTodayDone.
  ///
  /// In tr, this message translates to:
  /// **'Bugün tamamlandı'**
  String get buildProgramDetailTodayDone;

  /// No description provided for @buildProgramDetailTodayPending.
  ///
  /// In tr, this message translates to:
  /// **'Bugün henüz işaretlenmedi — dokun'**
  String get buildProgramDetailTodayPending;

  /// No description provided for @buildProgramDetailDayCount.
  ///
  /// In tr, this message translates to:
  /// **'{days}. gün'**
  String buildProgramDetailDayCount(int days);

  /// No description provided for @buildProgramDetailProgressIndicatorLabel.
  ///
  /// In tr, this message translates to:
  /// **'Motivasyonel ilerleme göstergesi'**
  String get buildProgramDetailProgressIndicatorLabel;

  /// No description provided for @buildProgramDetailRoutinePercent.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} rutin oturumu'**
  String buildProgramDetailRoutinePercent(int percent);

  /// No description provided for @buildProgramDetailMilestoneLabel.
  ///
  /// In tr, this message translates to:
  /// **'{day}. gün — %{percent}'**
  String buildProgramDetailMilestoneLabel(int day, int percent);

  /// No description provided for @buildProgramDetailDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bu göstergeler genel motivasyon içindir; bilimsel veya tıbbi ölçüm değildir.'**
  String get buildProgramDetailDisclaimer;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In tr, this message translates to:
  /// **'Gürültünün içinde bir nefes'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Zihin koştururken iç sesin çoğu zaman fısıltıda kalır. Küçük duruşlar — bir nefes, bir anlık duraklama — manevi dengeyi yeşertir; dışarıda aradığın huzur, bazen önce içerde sessizce filizlenir.'**
  String get onboardingSlide1Subtitle;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In tr, this message translates to:
  /// **'Küçük başla, istikrarla büyü'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim ve Arınma’da alışkanlıklarını kayıt altına al. Bir gün, bir nefes, bir seçim — zinciri kırmadan ilerle; arınma da merdiven çıkmak gibi, basamak basamak güçlenir.'**
  String get onboardingSlide2Subtitle;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In tr, this message translates to:
  /// **'Vakit, namaz ve günlük düzen'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz saatlerini yanında tut; nefes egzersizi ve güçlenme alanın zor anlarda yanında olsun. İbadetini, takibini ve iç sesini aynı ritimde topla.'**
  String get onboardingSlide3Subtitle;

  /// No description provided for @onboardingSlide4Title.
  ///
  /// In tr, this message translates to:
  /// **'Arın: tek uygulamada bir arada'**
  String get onboardingSlide4Title;

  /// No description provided for @onboardingSlide4Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'İlhamdan günlük alışkanlığa, vakit bildiriminden arınma sayacına kadar yolculuğun burada. Hazırsan birlikte başlayalım — sen yürü, biz hatırlatır ve eşlik ederiz.'**
  String get onboardingSlide4Subtitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingSkip.
  ///
  /// In tr, this message translates to:
  /// **'Geç'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get onboardingNext;

  /// No description provided for @surveyNameTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana nasıl hitap edelim?'**
  String get surveyNameTitle;

  /// No description provided for @surveyNameHint.
  ///
  /// In tr, this message translates to:
  /// **'İsminiz'**
  String get surveyNameHint;

  /// No description provided for @surveyGenderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyetini öğrenebilir miyiz?'**
  String get surveyGenderTitle;

  /// No description provided for @surveyGenderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana daha iyi yardımcı olabilmek için...'**
  String get surveyGenderSubtitle;

  /// No description provided for @surveyGenderMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get surveyGenderMale;

  /// No description provided for @surveyGenderFemale.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get surveyGenderFemale;

  /// No description provided for @surveyMoodTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şu an iç dünyanda hangi ton daha baskın?'**
  String get surveyMoodTitle;

  /// No description provided for @surveyMoodSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kendini tanımlayan işaretleri seç; içerik ve hatırlatmalar buna göre yumuşar.'**
  String get surveyMoodSubtitle;

  /// No description provided for @surveyDailyRhythmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günün büyük kısmı genelde nerede akıyor?'**
  String get surveyDailyRhythmTitle;

  /// No description provided for @surveyDailyRhythmSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tempo ve ortam, sana uygun ritmi anlamamıza yardım eder.'**
  String get surveyDailyRhythmSubtitle;

  /// No description provided for @surveyInnerThemesTitle.
  ///
  /// In tr, this message translates to:
  /// **'İç dünyanda öne çıkan temalar hangileri?'**
  String get surveyInnerThemesTitle;

  /// No description provided for @surveyInnerThemesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla seçebilirsin; samimi işaretler bize seni daha iyi tanıtmaya yardım eder.'**
  String get surveyInnerThemesSubtitle;

  /// No description provided for @surveyNotificationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get surveyNotificationTitle;

  /// No description provided for @surveyNotificationLead.
  ///
  /// In tr, this message translates to:
  /// **'Namaz hatırlatmaları ve günün mesajları zamanında ulaşsın.'**
  String get surveyNotificationLead;

  /// No description provided for @surveyNotificationSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakit bildirimleri ile içerik önerilerinin kaçmaması için bildirim iznine ihtiyacımız var. İstediğin zaman ayarlardan kapatabilirsin.'**
  String get surveyNotificationSubtitle;

  /// No description provided for @surveyNotificationAllow.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get surveyNotificationAllow;

  /// No description provided for @surveyNotificationSkip.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik geç'**
  String get surveyNotificationSkip;

  /// No description provided for @surveyNotificationOpenSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlardan aç'**
  String get surveyNotificationOpenSettings;

  /// No description provided for @surveySave.
  ///
  /// In tr, this message translates to:
  /// **'Başla ➔'**
  String get surveySave;

  /// No description provided for @surveyGenderDecline.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşmak istemiyorum'**
  String get surveyGenderDecline;

  /// No description provided for @surveyNameGreetingPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba'**
  String get surveyNameGreetingPrefix;

  /// No description provided for @surveySummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hazırsın'**
  String get surveySummaryTitle;

  /// No description provided for @surveySummarySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Temel tercihlerini kaydettik. Arın deneyimini bu işaretlere göre şekillendireceğiz.'**
  String get surveySummarySubtitle;

  /// No description provided for @surveySummaryCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç özeti'**
  String get surveySummaryCardTitle;

  /// No description provided for @surveySummaryItemName.
  ///
  /// In tr, this message translates to:
  /// **'Hitap'**
  String get surveySummaryItemName;

  /// No description provided for @surveySummaryItemMood.
  ///
  /// In tr, this message translates to:
  /// **'Ruh hali işaretlerin'**
  String get surveySummaryItemMood;

  /// No description provided for @surveySummaryItemRhythm.
  ///
  /// In tr, this message translates to:
  /// **'Günlük akış işaretlerin'**
  String get surveySummaryItemRhythm;

  /// No description provided for @surveySummaryItemThemes.
  ///
  /// In tr, this message translates to:
  /// **'İç tema işaretlerin'**
  String get surveySummaryItemThemes;

  /// No description provided for @surveySummaryItemNotificationOn.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get surveySummaryItemNotificationOn;

  /// No description provided for @surveySummaryItemNotificationOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get surveySummaryItemNotificationOff;

  /// No description provided for @surveySummaryNotProvided.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmedi'**
  String get surveySummaryNotProvided;

  /// No description provided for @surveySummaryAction.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekrana geç'**
  String get surveySummaryAction;

  /// No description provided for @surveySummarySaveError.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç kaydedilemedi. Lütfen tekrar dene.'**
  String get surveySummarySaveError;

  /// No description provided for @premiumLegalPrivacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get premiumLegalPrivacyPolicy;

  /// No description provided for @premiumLegalTermsOfUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Şartları'**
  String get premiumLegalTermsOfUse;

  /// No description provided for @premiumLinkOpenFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı açılamadı. Lütfen tekrar dene.'**
  String get premiumLinkOpenFailed;

  /// No description provided for @moodHappy.
  ///
  /// In tr, this message translates to:
  /// **'Mutlu'**
  String get moodHappy;

  /// No description provided for @moodCalm.
  ///
  /// In tr, this message translates to:
  /// **'Sakin'**
  String get moodCalm;

  /// No description provided for @moodStressed.
  ///
  /// In tr, this message translates to:
  /// **'Stresli'**
  String get moodStressed;

  /// No description provided for @moodSad.
  ///
  /// In tr, this message translates to:
  /// **'Üzgün'**
  String get moodSad;

  /// No description provided for @moodGrateful.
  ///
  /// In tr, this message translates to:
  /// **'Şükrediyorum'**
  String get moodGrateful;

  /// No description provided for @moodAnxious.
  ///
  /// In tr, this message translates to:
  /// **'Kaygılı'**
  String get moodAnxious;

  /// No description provided for @moodMotivated.
  ///
  /// In tr, this message translates to:
  /// **'Motive'**
  String get moodMotivated;

  /// No description provided for @sectorStudent.
  ///
  /// In tr, this message translates to:
  /// **'Lise / Üniversite / Hazırlık'**
  String get sectorStudent;

  /// No description provided for @sectorPrivate.
  ///
  /// In tr, this message translates to:
  /// **'Özel Sektör'**
  String get sectorPrivate;

  /// No description provided for @sectorPublic.
  ///
  /// In tr, this message translates to:
  /// **'Kamu Personeli'**
  String get sectorPublic;

  /// No description provided for @sectorBusiness.
  ///
  /// In tr, this message translates to:
  /// **'Kendi İşim / Serbest'**
  String get sectorBusiness;

  /// No description provided for @sectorTrade.
  ///
  /// In tr, this message translates to:
  /// **'Ticaret'**
  String get sectorTrade;

  /// No description provided for @sectorHousehold.
  ///
  /// In tr, this message translates to:
  /// **'Ev Hanımı / Ev Erkeği'**
  String get sectorHousehold;

  /// No description provided for @sectorOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get sectorOther;

  /// No description provided for @needMotivation.
  ///
  /// In tr, this message translates to:
  /// **'Motivasyon'**
  String get needMotivation;

  /// No description provided for @needSabr.
  ///
  /// In tr, this message translates to:
  /// **'Sabır'**
  String get needSabr;

  /// No description provided for @needShukr.
  ///
  /// In tr, this message translates to:
  /// **'Şükür'**
  String get needShukr;

  /// No description provided for @needTawakkul.
  ///
  /// In tr, this message translates to:
  /// **'Tevekkül'**
  String get needTawakkul;

  /// No description provided for @needFocus.
  ///
  /// In tr, this message translates to:
  /// **'Odaklanma'**
  String get needFocus;

  /// No description provided for @needHealing.
  ///
  /// In tr, this message translates to:
  /// **'Şifa'**
  String get needHealing;

  /// No description provided for @needRizq.
  ///
  /// In tr, this message translates to:
  /// **'Rızık & Bereket'**
  String get needRizq;

  /// No description provided for @appPrepareTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arına hazırlanıyoruz'**
  String get appPrepareTitle;

  /// No description provided for @appPrepareSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakitleri ve günün sözleri senin için yükleniyor…'**
  String get appPrepareSubtitle;

  /// No description provided for @shellExitConfirmBackTwice.
  ///
  /// In tr, this message translates to:
  /// **'Çıkmak için geri tuşuna bir kez daha basın'**
  String get shellExitConfirmBackTwice;

  /// No description provided for @inspireExploreTitle.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get inspireExploreTitle;

  /// No description provided for @inspireSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get inspireSearchHint;

  /// No description provided for @inspireFilterTooltip.
  ///
  /// In tr, this message translates to:
  /// **'İçerik türü'**
  String get inspireFilterTooltip;

  /// No description provided for @inspireFilterMainFeed.
  ///
  /// In tr, this message translates to:
  /// **'Ana akış'**
  String get inspireFilterMainFeed;

  /// No description provided for @inspireFilterQuote.
  ///
  /// In tr, this message translates to:
  /// **'Söz'**
  String get inspireFilterQuote;

  /// No description provided for @inspireFilterVerse.
  ///
  /// In tr, this message translates to:
  /// **'Ayet'**
  String get inspireFilterVerse;

  /// No description provided for @inspireFilterHadith.
  ///
  /// In tr, this message translates to:
  /// **'Hadis'**
  String get inspireFilterHadith;

  /// No description provided for @inspireSearchNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Bu aramaya uygun içerik yok.\nFarklı kelime veya\nşekilsiz yazım deneyin\n(ör. karde, kardes → kardeş).'**
  String get inspireSearchNoResults;

  /// No description provided for @inspireEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz içerik yok'**
  String get inspireEmptyTitle;

  /// No description provided for @inspireEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Görseller: assets/inspiration/ (1.jpg, 2.jpg, …).\nİçerik: assets/data/inspiration/*.json veya Firestore app_public/inspiration_cards.'**
  String get inspireEmptySubtitle;

  /// No description provided for @inspirePullToRefreshHint.
  ///
  /// In tr, this message translates to:
  /// **'Yenilemek için aşağı çekin.'**
  String get inspirePullToRefreshHint;

  /// No description provided for @inspireLoadFailedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yüklenemedi'**
  String get inspireLoadFailedTitle;

  /// No description provided for @inspirePullToRetryHint.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar denemek için aşağı çekin.'**
  String get inspirePullToRetryHint;

  /// No description provided for @viewerBackAction.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get viewerBackAction;

  /// No description provided for @viewerNoCard.
  ///
  /// In tr, this message translates to:
  /// **'Kart yok'**
  String get viewerNoCard;

  /// No description provided for @asyncErrorDefaultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti'**
  String get asyncErrorDefaultTitle;

  /// No description provided for @asyncErrorDefaultMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantın zayıf olabilir ya da hizmete şu an ulaşamıyoruz. Az sonra tekrar dene.'**
  String get asyncErrorDefaultMessage;

  /// No description provided for @asyncErrorRetryAction.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get asyncErrorRetryAction;

  /// No description provided for @asyncErrorTechnicalDetailsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Teknik ayrıntı'**
  String get asyncErrorTechnicalDetailsTitle;

  /// No description provided for @asyncErrorCopiedToClipboard.
  ///
  /// In tr, this message translates to:
  /// **'Hata panoya kopyalandı.'**
  String get asyncErrorCopiedToClipboard;

  /// No description provided for @savedInspirationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilenler'**
  String get savedInspirationTitle;

  /// No description provided for @savedInspirationLoadFailedPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Yüklenemedi'**
  String get savedInspirationLoadFailedPrefix;

  /// No description provided for @savedInspirationEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kalp defterin boş'**
  String get savedInspirationEmptyTitle;

  /// No description provided for @savedInspirationEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet\'te sana dokunan sözü kaydet; burada toplanıp sana dönüş olsun.'**
  String get savedInspirationEmptySubtitle;

  /// No description provided for @savedInspirationGoExploreAction.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet\'e git'**
  String get savedInspirationGoExploreAction;

  /// No description provided for @clockPickerCancelAction.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get clockPickerCancelAction;

  /// No description provided for @clockPickerConfirmAction.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get clockPickerConfirmAction;

  /// No description provided for @clockPickerHourLabel.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get clockPickerHourLabel;

  /// No description provided for @clockPickerMinuteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dakika'**
  String get clockPickerMinuteLabel;

  /// No description provided for @salatWeekCelebrationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Haftayı tamamladın'**
  String get salatWeekCelebrationTitle;

  /// No description provided for @salatWeekCelebrationAction.
  ///
  /// In tr, this message translates to:
  /// **'Elhamdülillah'**
  String get salatWeekCelebrationAction;

  /// No description provided for @adminEmailInviteLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta daveti'**
  String get adminEmailInviteLabel;

  /// No description provided for @offlineBannerOffline.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışısın'**
  String get offlineBannerOffline;

  /// No description provided for @offlineBannerReconnected.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar bağlandın'**
  String get offlineBannerReconnected;

  /// No description provided for @premiumRestorePurchasesLabel.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükle'**
  String get premiumRestorePurchasesLabel;

  /// No description provided for @premiumActivePlanLabel.
  ///
  /// In tr, this message translates to:
  /// **'Aktif planınız'**
  String get premiumActivePlanLabel;

  /// No description provided for @premiumPlanMonthlyLaunch.
  ///
  /// In tr, this message translates to:
  /// **'Lansman Fiyatıyla Başla'**
  String get premiumPlanMonthlyLaunch;

  /// No description provided for @premiumPlanYearlySwitch.
  ///
  /// In tr, this message translates to:
  /// **'Yıllığa geç'**
  String get premiumPlanYearlySwitch;

  /// No description provided for @premiumFeatureNoAds.
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız kullanım'**
  String get premiumFeatureNoAds;

  /// No description provided for @premiumFeatureWidgets.
  ///
  /// In tr, this message translates to:
  /// **'Widget kilidi yok'**
  String get premiumFeatureWidgets;

  /// No description provided for @premiumFeatureReels.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet akışı kesintisiz'**
  String get premiumFeatureReels;

  /// No description provided for @premiumFeatureSecondAlarm.
  ///
  /// In tr, this message translates to:
  /// **'2. ezan alarmı açık'**
  String get premiumFeatureSecondAlarm;

  /// No description provided for @premiumFeatureExtras.
  ///
  /// In tr, this message translates to:
  /// **'Zikir, pusula ve frekanslarda reklam yok'**
  String get premiumFeatureExtras;

  /// No description provided for @premiumSignInRequired.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma için giriş zorunlu değil. Premiumu bu cihazda hemen kullanabilir, istersen daha sonra hesabını bağlayarak diğer cihazlarında da erişebilirsin.'**
  String get premiumSignInRequired;

  /// No description provided for @premiumSignInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Premium için hesabını bağla'**
  String get premiumSignInTitle;

  /// No description provided for @premiumSignInSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Satın aldığın premium cihaz değiştirince kaybolmasın diye önce hesabına bağlanır. Fiyatları görmek için giriş gerekmez.'**
  String get premiumSignInSubtitle;

  /// No description provided for @premiumSignInGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile devam et'**
  String get premiumSignInGoogle;

  /// No description provided for @premiumSignInApple.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile devam et'**
  String get premiumSignInApple;

  /// No description provided for @premiumSignInCancel.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik vazgeç'**
  String get premiumSignInCancel;

  /// No description provided for @locationPermissionRequiredTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum İzni Gerekli'**
  String get locationPermissionRequiredTitle;

  /// No description provided for @locationPermissionRequiredBody.
  ///
  /// In tr, this message translates to:
  /// **'Arın, namaz vakitlerini ve kıble yönünü doğru hesaplayabilmek için konumunuza erişim izni gerektirir. Konum verileriniz yalnızca bu amaçlar için kullanılır ve cihazınızda işlenir.'**
  String get locationPermissionRequiredBody;

  /// No description provided for @locationPermissionNotNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Değil'**
  String get locationPermissionNotNow;

  /// No description provided for @locationPermissionContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get locationPermissionContinue;

  /// No description provided for @errorScreenTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti'**
  String get errorScreenTitle;

  /// No description provided for @errorScreenBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm şu an açılamadı. Uygulamayı kapatıp tekrar açmayı deneyebilirsin.'**
  String get errorScreenBody;

  /// No description provided for @errorScreenDebugTitle.
  ///
  /// In tr, this message translates to:
  /// **'ARIN — widget hatası (debug)'**
  String get errorScreenDebugTitle;

  /// No description provided for @errorScreenDebugBody.
  ///
  /// In tr, this message translates to:
  /// **'Debug moddasınız. Aşağıdaki metni kopyalayın.'**
  String get errorScreenDebugBody;

  /// No description provided for @widgetUnlockQuoteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Söz Widgetı'**
  String get widgetUnlockQuoteTitle;

  /// No description provided for @widgetUnlockPrayerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz Vakti Widgetı'**
  String get widgetUnlockPrayerTitle;

  /// No description provided for @widgetUnlockComboTitle.
  ///
  /// In tr, this message translates to:
  /// **'Söz + Namaz Widgetı'**
  String get widgetUnlockComboTitle;

  /// No description provided for @widgetUnlockTrackingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takip Widgetı'**
  String get widgetUnlockTrackingTitle;

  /// No description provided for @widgetUnlockZikirTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zikirmatik Widgetı'**
  String get widgetUnlockZikirTitle;

  /// No description provided for @widgetUnlockAdLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Reklam şu an yüklenemedi, daha sonra tekrar dene.'**
  String get widgetUnlockAdLoadFailed;

  /// No description provided for @widgetUnlockSuccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'{hours, plural, =1{{title} 1 saat açıldı! 🎉} other{{title} {hours} saat açıldı! 🎉}}'**
  String widgetUnlockSuccessTitle(Object title, int hours);

  /// No description provided for @widgetUnlockPremiumSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Premium aktif! Tüm widgetlar açıldı. 🎉'**
  String get widgetUnlockPremiumSuccess;

  /// No description provided for @widgetUnlockDescription.
  ///
  /// In tr, this message translates to:
  /// **'{hours, plural, =1{Bu widgetı 1 saat açmak için kısa bir reklam izleyebilirsin. Kalıcı erişim için Premium\'a geç.} other{Bu widgetı {hours} saat açmak için kısa bir reklam izleyebilirsin. Kalıcı erişim için Premium\'a geç.}}'**
  String widgetUnlockDescription(int hours);

  /// No description provided for @widgetUnlockAdButton.
  ///
  /// In tr, this message translates to:
  /// **'{hours, plural, =1{Reklam izle — 1 saat aç} other{Reklam izle — {hours} saat aç}}'**
  String widgetUnlockAdButton(int hours);

  /// No description provided for @widgetUnlockPremiumButton.
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a geç'**
  String get widgetUnlockPremiumButton;

  /// No description provided for @widgetUnlockCancelButton.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get widgetUnlockCancelButton;

  /// No description provided for @purchaseErrorNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Ürün bulunamadı. İnternet bağlantınızı kontrol edin.'**
  String get purchaseErrorNotFound;

  /// No description provided for @purchaseErrorUnexpected.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmedik hata: {error}'**
  String purchaseErrorUnexpected(Object error);

  /// No description provided for @purchaseErrorNotSupported.
  ///
  /// In tr, this message translates to:
  /// **'Bu platformda satın alma desteklenmiyor.'**
  String get purchaseErrorNotSupported;

  /// No description provided for @audioPermissionRequiredTitle.
  ///
  /// In tr, this message translates to:
  /// **'Medya İzni Gerekli'**
  String get audioPermissionRequiredTitle;

  /// No description provided for @audioPermissionRequiredBody.
  ///
  /// In tr, this message translates to:
  /// **'Arın, kendi cihazınızdan özel ezan veya bildirim sesi seçebilmeniz için ses dosyalarınıza erişim izni gerektirir. Bu dosyalar sadece uygulama içinde bildirim olarak kullanılır.'**
  String get audioPermissionRequiredBody;

  /// No description provided for @audioPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ses dosyası seç'**
  String get audioPickerTitle;

  /// No description provided for @mgmtDailyPrayers.
  ///
  /// In tr, this message translates to:
  /// **'Günlük namaz'**
  String get mgmtDailyPrayers;

  /// No description provided for @mgmtRoutineWorkshop.
  ///
  /// In tr, this message translates to:
  /// **'Rutin atölyesi'**
  String get mgmtRoutineWorkshop;

  /// No description provided for @mgmtChooseGrowth.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim seç'**
  String get mgmtChooseGrowth;

  /// No description provided for @mgmtPickPrayerOrMakeup.
  ///
  /// In tr, this message translates to:
  /// **'Namaz veya kaza takibini işaretle; özel bir gelişim için alttaki alanı kullan.'**
  String get mgmtPickPrayerOrMakeup;

  /// No description provided for @mgmtCountingAndCompensation.
  ///
  /// In tr, this message translates to:
  /// **'Sayım ve telafi'**
  String get mgmtCountingAndCompensation;

  /// No description provided for @mgmtPrayer.
  ///
  /// In tr, this message translates to:
  /// **'Namaz'**
  String get mgmtPrayer;

  /// No description provided for @mgmtTimeAndKhushu.
  ///
  /// In tr, this message translates to:
  /// **'Vakit ve huşû'**
  String get mgmtTimeAndKhushu;

  /// No description provided for @mgmtCustomRoutine.
  ///
  /// In tr, this message translates to:
  /// **'Özel rutin'**
  String get mgmtCustomRoutine;

  /// No description provided for @mgmtChooseYourOwnTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlık, emoji ve hatırlatmayı sen belirle.'**
  String get mgmtChooseYourOwnTitle;

  /// No description provided for @mgmtSelect.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get mgmtSelect;

  /// No description provided for @habitsMyHabits.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlıklarım'**
  String get habitsMyHabits;

  /// No description provided for @habitsNoHabitsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz alışkanlık eklemedin.\nYeni bir başlangıç yapmaya hazır mısın?'**
  String get habitsNoHabitsYet;

  /// No description provided for @habitsGrowth.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim'**
  String get habitsGrowth;

  /// No description provided for @habitsPurification.
  ///
  /// In tr, this message translates to:
  /// **'Arınma'**
  String get habitsPurification;

  /// No description provided for @habitsAddPurificationGoal.
  ///
  /// In tr, this message translates to:
  /// **'Arınma hedefi ekle'**
  String get habitsAddPurificationGoal;

  /// No description provided for @habitsAddGrowthRoutine.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim rutini ekle'**
  String get habitsAddGrowthRoutine;

  /// No description provided for @habitsDeleteConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu alışkanlığı silmek istiyor musun?'**
  String get habitsDeleteConfirmTitle;

  /// No description provided for @habitsCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get habitsCancel;

  /// No description provided for @habitsYesDelete.
  ///
  /// In tr, this message translates to:
  /// **'Evet, Sil'**
  String get habitsYesDelete;

  /// No description provided for @habitsDayStreak.
  ///
  /// In tr, this message translates to:
  /// **'gün serisi'**
  String get habitsDayStreak;

  /// No description provided for @customHabitThisWeekGoal.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftanın hedefi'**
  String get customHabitThisWeekGoal;

  /// No description provided for @customHabitThisMonthGoal.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayın hedefi'**
  String get customHabitThisMonthGoal;

  /// No description provided for @customHabitDailyGoal.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hedef'**
  String get customHabitDailyGoal;

  /// No description provided for @customHabitThisWeekGoalComplete.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftanın hedefi tamam.'**
  String get customHabitThisWeekGoalComplete;

  /// No description provided for @customHabitThisMonthGoalComplete.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayın hedefi tamam.'**
  String get customHabitThisMonthGoalComplete;

  /// No description provided for @customHabitTodayGoalComplete.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü hedef tamam.'**
  String get customHabitTodayGoalComplete;

  /// No description provided for @customHabitLetsStart.
  ///
  /// In tr, this message translates to:
  /// **'Haydi başla!'**
  String get customHabitLetsStart;

  /// No description provided for @customHabitDoingWell.
  ///
  /// In tr, this message translates to:
  /// **'İyi gidiyorsun.'**
  String get customHabitDoingWell;

  /// No description provided for @customHabitAlmostThere.
  ///
  /// In tr, this message translates to:
  /// **'Neredeyse.'**
  String get customHabitAlmostThere;

  /// No description provided for @customHabitOneLastStep.
  ///
  /// In tr, this message translates to:
  /// **'Son bir adım.'**
  String get customHabitOneLastStep;

  /// No description provided for @customHabitRecordNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı'**
  String get customHabitRecordNotFound;

  /// No description provided for @customHabitStreak.
  ///
  /// In tr, this message translates to:
  /// **'Seri'**
  String get customHabitStreak;

  /// No description provided for @customHabitDayStreak.
  ///
  /// In tr, this message translates to:
  /// **'Gün serisi'**
  String get customHabitDayStreak;

  /// No description provided for @customHabitBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get customHabitBack;

  /// No description provided for @customHabitRemove.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get customHabitRemove;

  /// No description provided for @customHabitBackToTracker.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlık takibine dön'**
  String get customHabitBackToTracker;

  /// No description provided for @customHabitGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get customHabitGoal;

  /// No description provided for @customHabitCompletedToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün hedefi tamamladın.'**
  String get customHabitCompletedToday;

  /// No description provided for @customHabitCompletedPeriod.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönem hedefi tamamladın.'**
  String get customHabitCompletedPeriod;

  /// No description provided for @customHabitFinish.
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get customHabitFinish;

  /// No description provided for @addHabitUnitTimes.
  ///
  /// In tr, this message translates to:
  /// **'kez'**
  String get addHabitUnitTimes;

  /// No description provided for @addHabitUnitMinutes.
  ///
  /// In tr, this message translates to:
  /// **'dakika'**
  String get addHabitUnitMinutes;

  /// No description provided for @addHabitUnitHours.
  ///
  /// In tr, this message translates to:
  /// **'saat'**
  String get addHabitUnitHours;

  /// No description provided for @addHabitUnitPages.
  ///
  /// In tr, this message translates to:
  /// **'sayfa'**
  String get addHabitUnitPages;

  /// No description provided for @addHabitUnitGlasses.
  ///
  /// In tr, this message translates to:
  /// **'bardak'**
  String get addHabitUnitGlasses;

  /// No description provided for @addHabitUnitSets.
  ///
  /// In tr, this message translates to:
  /// **'set'**
  String get addHabitUnitSets;

  /// No description provided for @addHabitUnitLaps.
  ///
  /// In tr, this message translates to:
  /// **'tur'**
  String get addHabitUnitLaps;

  /// No description provided for @addHabitDaily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get addHabitDaily;

  /// No description provided for @addHabitWeekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get addHabitWeekly;

  /// No description provided for @addHabitMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get addHabitMonthly;

  /// No description provided for @addHabitSummaryWeekly.
  ///
  /// In tr, this message translates to:
  /// **'{amount} {unit} haftalık'**
  String addHabitSummaryWeekly(Object amount, Object unit);

  /// No description provided for @addHabitSummaryMonthly.
  ///
  /// In tr, this message translates to:
  /// **'{amount} {unit} aylık'**
  String addHabitSummaryMonthly(Object amount, Object unit);

  /// No description provided for @addHabitSummaryDaily.
  ///
  /// In tr, this message translates to:
  /// **'{amount} {unit} günlük'**
  String addHabitSummaryDaily(Object amount, Object unit);

  /// No description provided for @addHabitCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get addHabitCancel;

  /// No description provided for @addHabitOk.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get addHabitOk;

  /// No description provided for @addHabitCustom.
  ///
  /// In tr, this message translates to:
  /// **'Özel'**
  String get addHabitCustom;

  /// No description provided for @addHabitSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get addHabitSave;

  /// No description provided for @addHabitGrowthName.
  ///
  /// In tr, this message translates to:
  /// **'Gelişim Adı'**
  String get addHabitGrowthName;

  /// No description provided for @addHabitPurificationName.
  ///
  /// In tr, this message translates to:
  /// **'Arınma Adı'**
  String get addHabitPurificationName;

  /// No description provided for @addHabitGrowthHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: 30 dakika kitap okuma'**
  String get addHabitGrowthHint;

  /// No description provided for @addHabitPurificationHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Gereksiz ekran süresini azalt'**
  String get addHabitPurificationHint;

  /// No description provided for @addHabitNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'İsim gerekli'**
  String get addHabitNameRequired;

  /// No description provided for @addHabitNameTooLong.
  ///
  /// In tr, this message translates to:
  /// **'En fazla 60 karakter'**
  String get addHabitNameTooLong;

  /// No description provided for @addHabitNoteOptional.
  ///
  /// In tr, this message translates to:
  /// **'Not (isteğe bağlı)'**
  String get addHabitNoteOptional;

  /// No description provided for @addHabitNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Kendine kısa bir not…'**
  String get addHabitNoteHint;

  /// No description provided for @habitCalendarToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün: {date}'**
  String habitCalendarToday(Object date);

  /// No description provided for @habitCalendarTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlık takvimi'**
  String get habitCalendarTitle;

  /// No description provided for @habitCalendarMonth.
  ///
  /// In tr, this message translates to:
  /// **'Ay'**
  String get habitCalendarMonth;

  /// No description provided for @habitCalendarMonthNote.
  ///
  /// In tr, this message translates to:
  /// **'Ay notu · {month} {year}'**
  String habitCalendarMonthNote(Object month, Object year);

  /// No description provided for @habitCalendarNoRecords.
  ///
  /// In tr, this message translates to:
  /// **'Bu ay için henüz kayıt yok veya alışkanlık eklemedin.'**
  String get habitCalendarNoRecords;

  /// No description provided for @habitCalendarQuitInsight.
  ///
  /// In tr, this message translates to:
  /// **'“{title}”: bu ay {n} gün Arınma sayacı takvimde (başlangıçtan itibaren).'**
  String habitCalendarQuitInsight(Object n, Object title);

  /// No description provided for @habitCalendarPrayerInsight.
  ///
  /// In tr, this message translates to:
  /// **'“{title}”: {anyPrayer} günde en az bir vakit işaretlendi; {fullFive} günde 5/5 tamamlandı.'**
  String habitCalendarPrayerInsight(
    Object anyPrayer,
    Object fullFive,
    Object title,
  );

  /// No description provided for @habitCalendarCustomInsightPeriod.
  ///
  /// In tr, this message translates to:
  /// **'“{title}”: bu ay {n} {periodLabel} hedefine ulaşıldı.'**
  String habitCalendarCustomInsightPeriod(
    Object n,
    Object periodLabel,
    Object title,
  );

  /// No description provided for @habitCalendarWeekLabel.
  ///
  /// In tr, this message translates to:
  /// **'hafta'**
  String get habitCalendarWeekLabel;

  /// No description provided for @habitCalendarMonthLabel.
  ///
  /// In tr, this message translates to:
  /// **'ay'**
  String get habitCalendarMonthLabel;

  /// No description provided for @habitCalendarCustomInsightDays.
  ///
  /// In tr, this message translates to:
  /// **'“{title}”: bu ay toplam {completedDays} gün tamamlandı olarak işaretlendi.'**
  String habitCalendarCustomInsightDays(Object completedDays, Object title);

  /// No description provided for @habitCalendarLegend.
  ///
  /// In tr, this message translates to:
  /// **'Hücredeki gri simgeler: o gün için kayıt var demektir. Arınma simgesi özellikle sayacın aktif olduğu günleri gösterir; namaz/rutin simgeleri ilgili günün tamamlanan kayıtlarını gösterir.'**
  String get habitCalendarLegend;

  /// No description provided for @kazaPrayerFajr.
  ///
  /// In tr, this message translates to:
  /// **'Sabah namazı'**
  String get kazaPrayerFajr;

  /// No description provided for @kazaPrayerDhuhr.
  ///
  /// In tr, this message translates to:
  /// **'Öğle namazı'**
  String get kazaPrayerDhuhr;

  /// No description provided for @kazaPrayerAsr.
  ///
  /// In tr, this message translates to:
  /// **'İkindi namazı'**
  String get kazaPrayerAsr;

  /// No description provided for @kazaPrayerMaghrib.
  ///
  /// In tr, this message translates to:
  /// **'Akşam namazı'**
  String get kazaPrayerMaghrib;

  /// No description provided for @kazaPrayerIsha.
  ///
  /// In tr, this message translates to:
  /// **'Yatsı namazı'**
  String get kazaPrayerIsha;

  /// No description provided for @kazaPrayerWitr.
  ///
  /// In tr, this message translates to:
  /// **'Vitir namazı'**
  String get kazaPrayerWitr;

  /// No description provided for @kazaReset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get kazaReset;

  /// No description provided for @kazaResetConfirmDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tüm kaza sayıları sıfırlanacak. Emin misin?'**
  String get kazaResetConfirmDesc;

  /// No description provided for @kazaCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get kazaCancel;

  /// No description provided for @kazaTrackerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaza takibi'**
  String get kazaTrackerTitle;

  /// No description provided for @kazaClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get kazaClose;

  /// No description provided for @kazaTrackerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaza namazı takibi'**
  String get kazaTrackerSubtitle;

  /// No description provided for @kazaTrackerDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kaza namazlarını vakit namazları kılındıktan sonra kılmaya özen göster. Eksik (+) ile borç ekleyebilir, kıldığın her rekat için (−) ile sayacı azaltabilirsin.'**
  String get kazaTrackerDesc;

  /// No description provided for @kazaCalcBirthDate.
  ///
  /// In tr, this message translates to:
  /// **'Doğum tarihi'**
  String get kazaCalcBirthDate;

  /// No description provided for @kazaCalcApply.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get kazaCalcApply;

  /// No description provided for @kazaCalcUpdateCounters.
  ///
  /// In tr, this message translates to:
  /// **'Sayaçları güncelle?'**
  String get kazaCalcUpdateCounters;

  /// No description provided for @kazaCalcUpdateDesc.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut kaza sayıların silinip hesaplanan değerlerle değiştirilecek.'**
  String get kazaCalcUpdateDesc;

  /// No description provided for @kazaCalcCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get kazaCalcCancel;

  /// No description provided for @kazaCalcContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get kazaCalcContinue;

  /// No description provided for @kazaCalcErrorPubertyFuture.
  ///
  /// In tr, this message translates to:
  /// **'Buluğ tarihi bugünden sonra olamaz. Doğum tarihini veya buluğ yaşını kontrol et.'**
  String get kazaCalcErrorPubertyFuture;

  /// No description provided for @kazaCalcErrorZeroRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Kalan namaz 0: tam kılınan gün, borçlu güne eşit veya fazlaysa üst sınıra çekilir; 6 vakit sayacı da buna göre sıfır kalır.'**
  String get kazaCalcErrorZeroRemaining;

  /// No description provided for @kazaCalcTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaza takibi'**
  String get kazaCalcTitle;

  /// No description provided for @kazaCalcSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaza namazı takibi'**
  String get kazaCalcSubtitle;

  /// No description provided for @kazaCalcDesc.
  ///
  /// In tr, this message translates to:
  /// **'Farz namazlar buluğ çağından itibaren başlar. Tam yaşını bilmiyorsan erkeklerde 12, kadınlarda 9 yaşını referans alabilirsin. Bu ekran tahmini bir sayı üretir; kaza namazlarını vakit namazlarından sonra kılmaya devam et.'**
  String get kazaCalcDesc;

  /// No description provided for @kazaCalcFemaleNote.
  ///
  /// In tr, this message translates to:
  /// **'Kadınlar için: buluğdan bugüne kadar geçen her takvim ayı için yaklaşık 6 gün namazdan muaf sayılır (toplam günü geçmez).'**
  String get kazaCalcFemaleNote;

  /// No description provided for @kazaCalcFormula.
  ///
  /// In tr, this message translates to:
  /// **'Formül: borçlu gün = takvim günü − hayız muafiyeti; toplam namaz = borçlu gün × 6 − (tam kılınan gün × 6). Kılınan gün sayısı borçlu günü aşamaz.'**
  String get kazaCalcFormula;

  /// No description provided for @kazaCalcCalculateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaza namazı hesapla'**
  String get kazaCalcCalculateTitle;

  /// No description provided for @kazaCalcGender.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyetiniz'**
  String get kazaCalcGender;

  /// No description provided for @kazaCalcMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get kazaCalcMale;

  /// No description provided for @kazaCalcFemale.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get kazaCalcFemale;

  /// No description provided for @kazaCalcBirthDateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğum tarihiniz'**
  String get kazaCalcBirthDateTitle;

  /// No description provided for @kazaCalcPubertyAge.
  ///
  /// In tr, this message translates to:
  /// **'Buluğ çaşına girdiğiniz yaş'**
  String get kazaCalcPubertyAge;

  /// No description provided for @kazaCalcPubertyNote.
  ///
  /// In tr, this message translates to:
  /// **'Alt sınır: erkek 12, kadın 9 yaş (daha küçük girilirse hesapta {minPuberty} kullanılır).'**
  String kazaCalcPubertyNote(Object minPuberty);

  /// No description provided for @kazaCalcPrayedDays.
  ///
  /// In tr, this message translates to:
  /// **'Kaç gün namaz kıldınız?'**
  String get kazaCalcPrayedDays;

  /// No description provided for @kazaCalcPrayedDaysNote.
  ///
  /// In tr, this message translates to:
  /// **'Bugüne kadar, o gün içinde bütün vakitleri kıldığın toplam gün sayısı.'**
  String get kazaCalcPrayedDaysNote;

  /// No description provided for @kazaCalcCalculate.
  ///
  /// In tr, this message translates to:
  /// **'Hesapla'**
  String get kazaCalcCalculate;

  /// No description provided for @kazaCalcLiveError.
  ///
  /// In tr, this message translates to:
  /// **'Buluğ tarihi bugünden sonra olamaz; doğum ve buluğ yaşını kontrol et.'**
  String get kazaCalcLiveError;

  /// No description provided for @kazaCalcLiveHayiz.
  ///
  /// In tr, this message translates to:
  /// **'Hayız muafiyeti: −{days} gün\n'**
  String kazaCalcLiveHayiz(Object days);

  /// No description provided for @kazaCalcLiveApplied.
  ///
  /// In tr, this message translates to:
  /// **'\n(Tam kılınan gün üst sınır: {applied})'**
  String kazaCalcLiveApplied(Object applied);

  /// No description provided for @kazaCalcLiveSummary.
  ///
  /// In tr, this message translates to:
  /// **'Canlı özet'**
  String get kazaCalcLiveSummary;

  /// No description provided for @kazaCalcLiveCalendarDays.
  ///
  /// In tr, this message translates to:
  /// **'Takvim günü: {days}\n'**
  String kazaCalcLiveCalendarDays(Object days);

  /// No description provided for @kazaCalcLiveLiableDays.
  ///
  /// In tr, this message translates to:
  /// **'Borçlu gün: {days}\n'**
  String kazaCalcLiveLiableDays(Object days);

  /// No description provided for @kazaCalcLiveOwed.
  ///
  /// In tr, this message translates to:
  /// **'Namaz borcu (borçlu gün × {perDay}): {total}\n'**
  String kazaCalcLiveOwed(Object perDay, Object total);

  /// No description provided for @kazaCalcLiveCredited.
  ///
  /// In tr, this message translates to:
  /// **'Düşülen (tam gün × {perDay}): {credited}{appliedNote}\n'**
  String kazaCalcLiveCredited(
    Object appliedNote,
    Object credited,
    Object perDay,
  );

  /// No description provided for @kazaCalcLiveRemaining.
  ///
  /// In tr, this message translates to:
  /// **'—\nKalan toplam: {remaining} namaz'**
  String kazaCalcLiveRemaining(Object remaining);

  /// No description provided for @kazaCalcLiveZeroNote.
  ///
  /// In tr, this message translates to:
  /// **'Hesapla sonrası sayaç: kalan toplam 6 vakte bölünür; kalan 0 ise her vakit 0 kalır.'**
  String get kazaCalcLiveZeroNote;

  /// No description provided for @dailyNamazWisdomFallback.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı metni yüklenemedi. Sayfayı yenilemeyi dene.'**
  String get dailyNamazWisdomFallback;

  /// No description provided for @momentVerseError.
  ///
  /// In tr, this message translates to:
  /// **'Yüklenemedi. Lütfen tekrar dene.'**
  String get momentVerseError;

  /// No description provided for @momentVerseEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir an yok'**
  String get momentVerseEmptyTitle;

  /// No description provided for @momentVerseEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bir sonraki bildirimi bekle.'**
  String get momentVerseEmptyDesc;

  /// No description provided for @momentVerseExpiredTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu vakit geçti'**
  String get momentVerseExpiredTitle;

  /// No description provided for @momentVerseExpiredDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bazı anlar yalnızca bir kez gelir.\nBelki bir sonrakinde buluşuruz.'**
  String get momentVerseExpiredDesc;

  /// No description provided for @momentVerseExpiredNote.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimleri açık tut,\nbir sonraki an kaçmasın.'**
  String get momentVerseExpiredNote;

  /// No description provided for @momentVerseActiveWhisper.
  ///
  /// In tr, this message translates to:
  /// **'Saatin sana fısıldadığı ayet'**
  String get momentVerseActiveWhisper;

  /// No description provided for @momentVerseSurah.
  ///
  /// In tr, this message translates to:
  /// **'Sure'**
  String get momentVerseSurah;

  /// No description provided for @momentVerseVerse.
  ///
  /// In tr, this message translates to:
  /// **'Ayet'**
  String get momentVerseVerse;

  /// No description provided for @momentVerseOneVerse.
  ///
  /// In tr, this message translates to:
  /// **'bir ayet'**
  String get momentVerseOneVerse;

  /// No description provided for @momentVerseClock.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get momentVerseClock;

  /// No description provided for @momentVerseMeaningDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu tesadüf değil; zamanın rakamları Kur\'an\'da bir adrese dönüşür. Bu bildirimi tam vaktinde açman ve bu ayetin önüne geçmen de öyle.'**
  String get momentVerseMeaningDesc;

  /// No description provided for @momentVerseDisappear.
  ///
  /// In tr, this message translates to:
  /// **'sonra bu an kaybolacak'**
  String get momentVerseDisappear;

  /// No description provided for @momentVerseReturnHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfaya Dön'**
  String get momentVerseReturnHome;

  /// No description provided for @momentVerseClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get momentVerseClose;

  /// No description provided for @surveyDictMoodHappy.
  ///
  /// In tr, this message translates to:
  /// **'Mutlu'**
  String get surveyDictMoodHappy;

  /// No description provided for @surveyDictMoodCalm.
  ///
  /// In tr, this message translates to:
  /// **'Sakin'**
  String get surveyDictMoodCalm;

  /// No description provided for @surveyDictMoodStressed.
  ///
  /// In tr, this message translates to:
  /// **'Stresli'**
  String get surveyDictMoodStressed;

  /// No description provided for @surveyDictMoodSad.
  ///
  /// In tr, this message translates to:
  /// **'Üzgün'**
  String get surveyDictMoodSad;

  /// No description provided for @surveyDictMoodGrateful.
  ///
  /// In tr, this message translates to:
  /// **'Şükrediyorum'**
  String get surveyDictMoodGrateful;

  /// No description provided for @surveyDictMoodAnxious.
  ///
  /// In tr, this message translates to:
  /// **'Kaygılı'**
  String get surveyDictMoodAnxious;

  /// No description provided for @surveyDictMoodMotivated.
  ///
  /// In tr, this message translates to:
  /// **'Motive'**
  String get surveyDictMoodMotivated;

  /// No description provided for @surveyDictSectorStudent.
  ///
  /// In tr, this message translates to:
  /// **'Lise / Üniversite / Hazırlık'**
  String get surveyDictSectorStudent;

  /// No description provided for @surveyDictSectorPrivate.
  ///
  /// In tr, this message translates to:
  /// **'Özel Sektör'**
  String get surveyDictSectorPrivate;

  /// No description provided for @surveyDictSectorPublic.
  ///
  /// In tr, this message translates to:
  /// **'Kamu Personeli'**
  String get surveyDictSectorPublic;

  /// No description provided for @surveyDictSectorBusiness.
  ///
  /// In tr, this message translates to:
  /// **'Kendi İşim / Serbest'**
  String get surveyDictSectorBusiness;

  /// No description provided for @surveyDictSectorTrade.
  ///
  /// In tr, this message translates to:
  /// **'Ticaret'**
  String get surveyDictSectorTrade;

  /// No description provided for @surveyDictSectorHousehold.
  ///
  /// In tr, this message translates to:
  /// **'Ev Hanımı / Ev Erkeği'**
  String get surveyDictSectorHousehold;

  /// No description provided for @surveyDictSectorOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get surveyDictSectorOther;

  /// No description provided for @surveyDictNeedMotivation.
  ///
  /// In tr, this message translates to:
  /// **'Motivasyon'**
  String get surveyDictNeedMotivation;

  /// No description provided for @surveyDictNeedSabr.
  ///
  /// In tr, this message translates to:
  /// **'Sabır'**
  String get surveyDictNeedSabr;

  /// No description provided for @surveyDictNeedShukr.
  ///
  /// In tr, this message translates to:
  /// **'Şükür'**
  String get surveyDictNeedShukr;

  /// No description provided for @surveyDictNeedTawakkul.
  ///
  /// In tr, this message translates to:
  /// **'Tevekkül'**
  String get surveyDictNeedTawakkul;

  /// No description provided for @surveyDictNeedFocus.
  ///
  /// In tr, this message translates to:
  /// **'Odaklanma'**
  String get surveyDictNeedFocus;

  /// No description provided for @surveyDictNeedHealing.
  ///
  /// In tr, this message translates to:
  /// **'Şifa'**
  String get surveyDictNeedHealing;

  /// No description provided for @surveyDictNeedRizq.
  ///
  /// In tr, this message translates to:
  /// **'Rızık & Bereket'**
  String get surveyDictNeedRizq;

  /// No description provided for @surveyDictGenderMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get surveyDictGenderMale;

  /// No description provided for @surveyDictGenderFemale.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get surveyDictGenderFemale;

  /// No description provided for @premiumProductNotReadyError.
  ///
  /// In tr, this message translates to:
  /// **'Ürün bilgisi henüz hazır değil. Lütfen tekrar deneyin.'**
  String get premiumProductNotReadyError;

  /// No description provided for @premiumAccountLinkError.
  ///
  /// In tr, this message translates to:
  /// **'Hesap eşlemesi tamamlanamadı. Lütfen tekrar deneyin.'**
  String get premiumAccountLinkError;

  /// No description provided for @premiumWelcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'🌿 Hoş geldin!'**
  String get premiumWelcomeTitle;

  /// No description provided for @premiumWelcomeMessage.
  ///
  /// In tr, this message translates to:
  /// **'ARIN Premium aktif. Reklamsız, kilitsiz deneyimin açık.\n\nİstediğin zaman mağaza hesabından aboneliğini yönetebilirsin.'**
  String get premiumWelcomeMessage;

  /// No description provided for @premiumWelcomeButton.
  ///
  /// In tr, this message translates to:
  /// **'Harika!'**
  String get premiumWelcomeButton;

  /// No description provided for @premiumRestoreSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Premium geri yüklendi!'**
  String get premiumRestoreSuccess;

  /// No description provided for @premiumNoActiveSubscription.
  ///
  /// In tr, this message translates to:
  /// **'Aktif abonelik bulunamadı.'**
  String get premiumNoActiveSubscription;

  /// No description provided for @premiumSignInErrorPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Giriş tamamlanamadı: '**
  String get premiumSignInErrorPrefix;

  /// No description provided for @premiumActiveTitle.
  ///
  /// In tr, this message translates to:
  /// **'ARIN Premium aktif'**
  String get premiumActiveTitle;

  /// No description provided for @premiumTitle.
  ///
  /// In tr, this message translates to:
  /// **'ARIN Premium'**
  String get premiumTitle;

  /// No description provided for @premiumActiveSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız ve kilitsiz deneyimin açık.'**
  String get premiumActiveSubtitle;

  /// No description provided for @premiumSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız, kesintisiz ve kilitsiz manevi rutin.'**
  String get premiumSubtitle;

  /// No description provided for @premiumYearlyPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık Premium'**
  String get premiumYearlyPlanTitle;

  /// No description provided for @premiumMostAdvantageousBadge.
  ///
  /// In tr, this message translates to:
  /// **'EN AVANTAJLI'**
  String get premiumMostAdvantageousBadge;

  /// No description provided for @premiumYearlyPlanSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık Abonelik'**
  String get premiumYearlyPlanSubtitle;

  /// No description provided for @premiumSwitchToYearly.
  ///
  /// In tr, this message translates to:
  /// **'Yıllığa geç'**
  String get premiumSwitchToYearly;

  /// No description provided for @premiumMonthlyPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Premium'**
  String get premiumMonthlyPlanTitle;

  /// No description provided for @premiumMonthlyPlanSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Abonelik'**
  String get premiumMonthlyPlanSubtitle;

  /// No description provided for @premiumFooterText1.
  ///
  /// In tr, this message translates to:
  /// **'Lansman fiyatları sınırlı süre geçerlidir. Abonelik mağaza hesabın üzerinden yönetilir ve istediğin zaman iptal edilebilir.'**
  String get premiumFooterText1;

  /// No description provided for @premiumFooterText2.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik, dönem bitiminden en az 24 saat önce iptal edilmezse otomatik yenilenir. Yenileme ücreti dönem bitimine 24 saat kala mağaza hesabından tahsil edilir. Aboneliklerini App Store/Play hesap ayarlarından yönetebilirsin.'**
  String get premiumFooterText2;

  /// No description provided for @premiumLaunchBadge.
  ///
  /// In tr, this message translates to:
  /// **'LANSMANA ÖZEL'**
  String get premiumLaunchBadge;

  /// No description provided for @premiumCountdownNotice.
  ///
  /// In tr, this message translates to:
  /// **'Bu fiyat sınırlı süre geçerli. Lansman bitmeden premiumu en avantajlı fiyatla aç.'**
  String get premiumCountdownNotice;

  /// No description provided for @premiumBenefitAdFree.
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız kullanım'**
  String get premiumBenefitAdFree;

  /// No description provided for @premiumBenefitWidgets.
  ///
  /// In tr, this message translates to:
  /// **'Widget kilidi yok'**
  String get premiumBenefitWidgets;

  /// No description provided for @premiumBenefitExplore.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet akışı kesintisiz'**
  String get premiumBenefitExplore;

  /// No description provided for @premiumBenefitAdhan.
  ///
  /// In tr, this message translates to:
  /// **'2. ezan alarmı açık'**
  String get premiumBenefitAdhan;

  /// No description provided for @premiumSignInRequiredNotice.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma için giriş zorunlu değil. Premiumu bu cihazda hemen kullanabilirsin; istersen sonrasında hesabını bağlayıp diğer cihazlarda da erişebilirsin.'**
  String get premiumSignInRequiredNotice;

  /// No description provided for @premiumSignInSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Premium için hesabını bağla'**
  String get premiumSignInSheetTitle;

  /// No description provided for @premiumSignInSheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabını bağlarsan premiumun diğer cihazlarında da daha kolay geri yüklenir. Satın alma için giriş zorunlu değildir.'**
  String get premiumSignInSheetSubtitle;

  /// No description provided for @premiumContinueWithGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile devam et'**
  String get premiumContinueWithGoogle;

  /// No description provided for @premiumContinueWithApple.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile devam et'**
  String get premiumContinueWithApple;

  /// No description provided for @premiumCancelForNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik vazgeç'**
  String get premiumCancelForNow;

  /// No description provided for @premiumPostPurchaseLinkTitle.
  ///
  /// In tr, this message translates to:
  /// **'Premium aktif'**
  String get premiumPostPurchaseLinkTitle;

  /// No description provided for @premiumPostPurchaseLinkBody.
  ///
  /// In tr, this message translates to:
  /// **'Premium bu cihazda aktif. Başka cihazlarda da kolayca kullanmak için hesabını şimdi bağlamak ister misin?'**
  String get premiumPostPurchaseLinkBody;

  /// No description provided for @premiumPostPurchaseLinkLater.
  ///
  /// In tr, this message translates to:
  /// **'Daha sonra'**
  String get premiumPostPurchaseLinkLater;

  /// No description provided for @premiumPostPurchaseLinkNow.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı bağla'**
  String get premiumPostPurchaseLinkNow;

  /// No description provided for @premiumPostPurchaseLinkSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Hesap bağlandı. Premium cihazların arasında senkronize edilebilir.'**
  String get premiumPostPurchaseLinkSuccess;

  /// No description provided for @premiumActivePlanBadge.
  ///
  /// In tr, this message translates to:
  /// **'Aktif planınız ✓'**
  String get premiumActivePlanBadge;

  /// No description provided for @premiumActivePlanButton.
  ///
  /// In tr, this message translates to:
  /// **'Aktif planınız'**
  String get premiumActivePlanButton;

  /// No description provided for @premiumStartWithLaunchPrice.
  ///
  /// In tr, this message translates to:
  /// **'Lansman Fiyatıyla Başla'**
  String get premiumStartWithLaunchPrice;

  /// No description provided for @premiumIsActiveButton.
  ///
  /// In tr, this message translates to:
  /// **'Premium aktif'**
  String get premiumIsActiveButton;

  /// No description provided for @qiblaCompassTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kıble Pusulası'**
  String get qiblaCompassTitle;

  /// No description provided for @qiblaCompassQibla.
  ///
  /// In tr, this message translates to:
  /// **'Kıble'**
  String get qiblaCompassQibla;

  /// No description provided for @qiblaCompassGettingLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınıyor…'**
  String get qiblaCompassGettingLocation;

  /// No description provided for @qiblaCompassInitError.
  ///
  /// In tr, this message translates to:
  /// **'Konum veya pusula\nbaşlatılamadı'**
  String get qiblaCompassInitError;

  /// No description provided for @qiblaCompassRetry.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden dene'**
  String get qiblaCompassRetry;

  /// No description provided for @qiblaCompassAligned.
  ///
  /// In tr, this message translates to:
  /// **'Yönünüz Kâbe\'ye dönük'**
  String get qiblaCompassAligned;

  /// No description provided for @qiblaCompassDeviation.
  ///
  /// In tr, this message translates to:
  /// **'sapma'**
  String get qiblaCompassDeviation;

  /// No description provided for @qiblaCompassDistanceKm.
  ///
  /// In tr, this message translates to:
  /// **'Kâbe\'ye {distance} km'**
  String qiblaCompassDistanceKm(Object distance);

  /// No description provided for @qiblaCompassDistanceM.
  ///
  /// In tr, this message translates to:
  /// **'Kâbe\'ye {distance} m'**
  String qiblaCompassDistanceM(Object distance);

  /// No description provided for @qiblaCompassProximityFar.
  ///
  /// In tr, this message translates to:
  /// **'Kalbin yönü hiç şaşmaz'**
  String get qiblaCompassProximityFar;

  /// No description provided for @qiblaCompassProximityApproaching.
  ///
  /// In tr, this message translates to:
  /// **'Her adım O\'na bir davettir'**
  String get qiblaCompassProximityApproaching;

  /// No description provided for @qiblaCompassProximityMecca.
  ///
  /// In tr, this message translates to:
  /// **'Haremeyn topraklarındasınız, Rabbim kabul etsin'**
  String get qiblaCompassProximityMecca;

  /// No description provided for @qiblaCompassProximityHaram.
  ///
  /// In tr, this message translates to:
  /// **'Kâbe\'nin huzurundasınız, dualarınız kabul olsun'**
  String get qiblaCompassProximityHaram;

  /// No description provided for @qiblaCompassStabilizing.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm sabitleniyor'**
  String get qiblaCompassStabilizing;

  /// No description provided for @qiblaCompassGuidanceTiltTitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefonu düz tut'**
  String get qiblaCompassGuidanceTiltTitle;

  /// No description provided for @qiblaCompassGuidanceTiltBody.
  ///
  /// In tr, this message translates to:
  /// **'Pusulayı yatay kullan. Dik, yan veya ters tutuşta yön kilitlenmez.'**
  String get qiblaCompassGuidanceTiltBody;

  /// No description provided for @qiblaCompassGuidanceCalibrateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Pusulayı kalibre et'**
  String get qiblaCompassGuidanceCalibrateTitle;

  /// No description provided for @qiblaCompassGuidanceCalibrateBody.
  ///
  /// In tr, this message translates to:
  /// **'Telefonu birkaç kez 8 çizerek çevir, sonra metalden uzak tut.'**
  String get qiblaCompassGuidanceCalibrateBody;

  /// No description provided for @qiblaCompassGuidanceUnstableTitle.
  ///
  /// In tr, this message translates to:
  /// **'Manyetik alan kararsız'**
  String get qiblaCompassGuidanceUnstableTitle;

  /// No description provided for @qiblaCompassGuidanceUnstableBody.
  ///
  /// In tr, this message translates to:
  /// **'Laptop, mıknatıs, metal masa ve manyetik kılıftan uzaklaş.'**
  String get qiblaCompassGuidanceUnstableBody;

  /// No description provided for @qiblaCompassGuidanceGoodTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm hazır'**
  String get qiblaCompassGuidanceGoodTitle;

  /// No description provided for @qiblaCompassGuidanceGoodBody.
  ///
  /// In tr, this message translates to:
  /// **'Telefonu yatay tut, kıbleye yavaşça dön. Hizalanınca altın ışık yanar.'**
  String get qiblaCompassGuidanceGoodBody;

  /// No description provided for @qiblaCompassNorth.
  ///
  /// In tr, this message translates to:
  /// **'K'**
  String get qiblaCompassNorth;

  /// No description provided for @qiblaCompassEast.
  ///
  /// In tr, this message translates to:
  /// **'D'**
  String get qiblaCompassEast;

  /// No description provided for @qiblaCompassSouth.
  ///
  /// In tr, this message translates to:
  /// **'G'**
  String get qiblaCompassSouth;

  /// No description provided for @qiblaCompassWest.
  ///
  /// In tr, this message translates to:
  /// **'B'**
  String get qiblaCompassWest;

  /// No description provided for @qiblaCompassQiblaText.
  ///
  /// In tr, this message translates to:
  /// **'KIBLE'**
  String get qiblaCompassQiblaText;

  /// No description provided for @zikirmatikCounterSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Zikirmatik sayacı'**
  String get zikirmatikCounterSemantics;

  /// No description provided for @zikirmatikRound.
  ///
  /// In tr, this message translates to:
  /// **'TUR'**
  String get zikirmatikRound;

  /// No description provided for @zikirmatikRoundCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tur tamamlandı'**
  String get zikirmatikRoundCompleted;

  /// No description provided for @zikirmatikResetCounter.
  ///
  /// In tr, this message translates to:
  /// **'Sayacı sıfırla?'**
  String get zikirmatikResetCounter;

  /// No description provided for @zikirmatikResetCounterDesc.
  ///
  /// In tr, this message translates to:
  /// **'Toplam sayı ve tur bilgisi sıfırlanır.'**
  String get zikirmatikResetCounterDesc;

  /// No description provided for @zikirmatikCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get zikirmatikCancel;

  /// No description provided for @zikirmatikReset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get zikirmatikReset;

  /// No description provided for @zikirmatikEditPhraseTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zikir adını düzenle'**
  String get zikirmatikEditPhraseTitle;

  /// No description provided for @zikirmatikUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullan'**
  String get zikirmatikUse;

  /// No description provided for @zikirmatikSaveAndUse.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet ve Kullan'**
  String get zikirmatikSaveAndUse;

  /// No description provided for @zikirmatikThisRound.
  ///
  /// In tr, this message translates to:
  /// **'BU TUR'**
  String get zikirmatikThisRound;

  /// No description provided for @zikirmatikTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get zikirmatikTarget;

  /// No description provided for @zikirmatikCounterSemanticsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Zikir sayacı. {round} / {target}, toplam {total}'**
  String zikirmatikCounterSemanticsLabel(
    Object round,
    Object target,
    Object total,
  );

  /// No description provided for @zikirmatikCounterSemanticsHint.
  ///
  /// In tr, this message translates to:
  /// **'Dokunarak sayıyı bir artır'**
  String get zikirmatikCounterSemanticsHint;

  /// No description provided for @zikirmatikVibration.
  ///
  /// In tr, this message translates to:
  /// **'Titreşim'**
  String get zikirmatikVibration;

  /// No description provided for @zikirmatikVibrationTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Açıkken her sayımda titreşir; tur bitince ek güçlü titreşim'**
  String get zikirmatikVibrationTooltip;

  /// No description provided for @zikirmatikInfo.
  ///
  /// In tr, this message translates to:
  /// **'Zikir bilgisi'**
  String get zikirmatikInfo;

  /// No description provided for @zikirmatikTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zikirmatik'**
  String get zikirmatikTitle;

  /// No description provided for @zikirmatikTapToChoose.
  ///
  /// In tr, this message translates to:
  /// **'Zikir seçmek için dokun'**
  String get zikirmatikTapToChoose;

  /// No description provided for @zikirmatikPickDhikr.
  ///
  /// In tr, this message translates to:
  /// **'ZİKİR SEÇ'**
  String get zikirmatikPickDhikr;

  /// No description provided for @zikirmatikSaved.
  ///
  /// In tr, this message translates to:
  /// **'KAYDETTİKLERİM'**
  String get zikirmatikSaved;

  /// No description provided for @zikirmatikDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get zikirmatikDelete;

  /// No description provided for @zikirmatikWriteOwnText.
  ///
  /// In tr, this message translates to:
  /// **'KENDİ METNİNİ YAZ…'**
  String get zikirmatikWriteOwnText;

  /// No description provided for @zikirmatikCustomTarget.
  ///
  /// In tr, this message translates to:
  /// **'Özel…'**
  String get zikirmatikCustomTarget;

  /// No description provided for @zikirmatikTargetOk.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get zikirmatikTargetOk;

  /// No description provided for @zikirmatikDeleteRoundRecord.
  ///
  /// In tr, this message translates to:
  /// **'Bu tur kaydını sil?'**
  String get zikirmatikDeleteRoundRecord;

  /// No description provided for @zikirmatikDhikr.
  ///
  /// In tr, this message translates to:
  /// **'zikir'**
  String get zikirmatikDhikr;

  /// No description provided for @zikirmatikShareError.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım açılamadı. Tekrar deneyin.'**
  String get zikirmatikShareError;

  /// No description provided for @zikirmatikDeleteRecord.
  ///
  /// In tr, this message translates to:
  /// **'Kaydı sil?'**
  String get zikirmatikDeleteRecord;

  /// No description provided for @zikirmatikCompletedRounds.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan turlar'**
  String get zikirmatikCompletedRounds;

  /// No description provided for @zikirmatikNoCompletedRounds.
  ///
  /// In tr, this message translates to:
  /// **'Henüz tamamlanan tur kaydı yok. Hedefe ulaştığında buraya düşer.'**
  String get zikirmatikNoCompletedRounds;

  /// No description provided for @zikirmatikArchivedSessions.
  ///
  /// In tr, this message translates to:
  /// **'Arşiv oturumları'**
  String get zikirmatikArchivedSessions;

  /// No description provided for @zikirmatikTodaysReflection.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün payı'**
  String get zikirmatikTodaysReflection;

  /// No description provided for @zikirmatikCompareLine.
  ///
  /// In tr, this message translates to:
  /// **'“{first}” zikrini “{second}”e göre {diff} tur daha çok tamamladın.'**
  String zikirmatikCompareLine(Object diff, Object first, Object second);

  /// No description provided for @zikirmatikOnlyOneRecord.
  ///
  /// In tr, this message translates to:
  /// **'Şu an yalnızca “{first}” için tur kaydın var.'**
  String zikirmatikOnlyOneRecord(Object first);

  /// No description provided for @zikirmatikSummaryAndAnalytics.
  ///
  /// In tr, this message translates to:
  /// **'Özet ve analiz'**
  String get zikirmatikSummaryAndAnalytics;

  /// No description provided for @zikirmatikAnalyticsNoLogs.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla tur tamamladıkça özet ve karşılaştırmalar burada oluşur.'**
  String get zikirmatikAnalyticsNoLogs;

  /// No description provided for @zikirmatikTotalRoundsCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Toplam {total} tur tamamladın.'**
  String zikirmatikTotalRoundsCompleted(Object total);

  /// No description provided for @zikirmatikActiveDays.
  ///
  /// In tr, this message translates to:
  /// **'{days} farklı günde zikir kaydın var.'**
  String zikirmatikActiveDays(Object days);

  /// No description provided for @zikirmatikLast7Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 günde {rounds} tur tamamlandı.'**
  String zikirmatikLast7Days(Object rounds);

  /// No description provided for @zikirmatikMostCompleted.
  ///
  /// In tr, this message translates to:
  /// **'En çok tamamlanan: “{phrase}” ({rounds} tur).'**
  String zikirmatikMostCompleted(Object phrase, Object rounds);

  /// No description provided for @zikirmatikCompleted.
  ///
  /// In tr, this message translates to:
  /// **'tamamlandı'**
  String get zikirmatikCompleted;

  /// No description provided for @zikirmatikTotalCounter.
  ///
  /// In tr, this message translates to:
  /// **'toplam sayaç'**
  String get zikirmatikTotalCounter;

  /// No description provided for @healingAmbientForest.
  ///
  /// In tr, this message translates to:
  /// **'Orman Sesi'**
  String get healingAmbientForest;

  /// No description provided for @healingAmbientFire.
  ///
  /// In tr, this message translates to:
  /// **'Ateş Sesi'**
  String get healingAmbientFire;

  /// No description provided for @healingAmbientCosmic.
  ///
  /// In tr, this message translates to:
  /// **'Evren Sesi'**
  String get healingAmbientCosmic;

  /// No description provided for @healingAmbientInshirah.
  ///
  /// In tr, this message translates to:
  /// **'İnşirah Suresi'**
  String get healingAmbientInshirah;

  /// No description provided for @healingSleepOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get healingSleepOff;

  /// No description provided for @healingSleepRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Kalan '**
  String get healingSleepRemaining;

  /// No description provided for @healingSleepMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{m} dakika'**
  String healingSleepMinutes(Object m);

  /// No description provided for @healingInfoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi'**
  String get healingInfoTitle;

  /// No description provided for @healingInfoBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm rahatlama ve tefekkür için tasarlanmıştır; tıbbi tedavi yerine geçmez. Sesleri düşük seviyede dinlemeniz önerilir. Rahatsızlık hissederseniz durdurun.'**
  String get healingInfoBody;

  /// No description provided for @healingInfoOk.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get healingInfoOk;

  /// No description provided for @healingFrequenciesTitle.
  ///
  /// In tr, this message translates to:
  /// **'İyileştirici Frekanslar'**
  String get healingFrequenciesTitle;

  /// No description provided for @healingAmbientSound.
  ///
  /// In tr, this message translates to:
  /// **'Ambiyans Sesi'**
  String get healingAmbientSound;

  /// No description provided for @healingPresets.
  ///
  /// In tr, this message translates to:
  /// **'ÖNAYARLAR'**
  String get healingPresets;

  /// No description provided for @healingFrequencyTone.
  ///
  /// In tr, this message translates to:
  /// **'Frekans tonu (Hz)'**
  String get healingFrequencyTone;

  /// No description provided for @healingAmbient.
  ///
  /// In tr, this message translates to:
  /// **'Ambiyans'**
  String get healingAmbient;

  /// No description provided for @healingSleepTimer.
  ///
  /// In tr, this message translates to:
  /// **'Uyku Zamanlayıcı'**
  String get healingSleepTimer;

  /// No description provided for @healingInshirahLocked.
  ///
  /// In tr, this message translates to:
  /// **'İnşirah modunda frekans kontrolleri kapalıdır.'**
  String get healingInshirahLocked;

  /// No description provided for @healingAllFrequencies.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Frekanslar'**
  String get healingAllFrequencies;

  /// No description provided for @healingPresetFocus.
  ///
  /// In tr, this message translates to:
  /// **'Odak'**
  String get healingPresetFocus;

  /// No description provided for @healingPresetSleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get healingPresetSleep;

  /// No description provided for @healingAmbientForestShort.
  ///
  /// In tr, this message translates to:
  /// **'Orman'**
  String get healingAmbientForestShort;

  /// No description provided for @healingAmbientFireShort.
  ///
  /// In tr, this message translates to:
  /// **'Ateş'**
  String get healingAmbientFireShort;

  /// No description provided for @healingAmbientCosmicShort.
  ///
  /// In tr, this message translates to:
  /// **'Evren'**
  String get healingAmbientCosmicShort;

  /// No description provided for @healingAmbientInshirahShort.
  ///
  /// In tr, this message translates to:
  /// **'İnşirah'**
  String get healingAmbientInshirahShort;

  /// No description provided for @healingAmbientChoose.
  ///
  /// In tr, this message translates to:
  /// **'Ambiyans Sesi Seçin'**
  String get healingAmbientChoose;

  /// No description provided for @healingSleepCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get healingSleepCancel;

  /// No description provided for @healingSleepStopAfter.
  ///
  /// In tr, this message translates to:
  /// **'Kaç dakika sonra durdurulsun?'**
  String get healingSleepStopAfter;

  /// No description provided for @healingSleepTimerOff.
  ///
  /// In tr, this message translates to:
  /// **'Zamanlayıcı kapalı'**
  String get healingSleepTimerOff;

  /// No description provided for @healingFreq174Short.
  ///
  /// In tr, this message translates to:
  /// **'Terapi Frekansı'**
  String get healingFreq174Short;

  /// No description provided for @healingFreq285Short.
  ///
  /// In tr, this message translates to:
  /// **'Direnç ve Metanet'**
  String get healingFreq285Short;

  /// No description provided for @healingFreq396Short.
  ///
  /// In tr, this message translates to:
  /// **'Yenilenme'**
  String get healingFreq396Short;

  /// No description provided for @healingFreq417Short.
  ///
  /// In tr, this message translates to:
  /// **'İç güç'**
  String get healingFreq417Short;

  /// No description provided for @healingFreq528Short.
  ///
  /// In tr, this message translates to:
  /// **'Huzur'**
  String get healingFreq528Short;

  /// No description provided for @healingFreq639Short.
  ///
  /// In tr, this message translates to:
  /// **'Arınma'**
  String get healingFreq639Short;

  /// No description provided for @healingFreq741Short.
  ///
  /// In tr, this message translates to:
  /// **'Tefekkür'**
  String get healingFreq741Short;

  /// No description provided for @healingFreq852Short.
  ///
  /// In tr, this message translates to:
  /// **'Sekîne'**
  String get healingFreq852Short;

  /// No description provided for @healingFreq174Heading.
  ///
  /// In tr, this message translates to:
  /// **'174 Hz - Şifa ve Rahatlama'**
  String get healingFreq174Heading;

  /// No description provided for @healingFreq285Heading.
  ///
  /// In tr, this message translates to:
  /// **'285 Hz - Sabır ve Sebat'**
  String get healingFreq285Heading;

  /// No description provided for @healingFreq396Heading.
  ///
  /// In tr, this message translates to:
  /// **'396 Hz - Bereket ve Başlangıç'**
  String get healingFreq396Heading;

  /// No description provided for @healingFreq417Heading.
  ///
  /// In tr, this message translates to:
  /// **'417 Hz - İç Güç ve İman'**
  String get healingFreq417Heading;

  /// No description provided for @healingFreq528Heading.
  ///
  /// In tr, this message translates to:
  /// **'528 Hz - Huzur ve Sükûnet'**
  String get healingFreq528Heading;

  /// No description provided for @healingFreq639Heading.
  ///
  /// In tr, this message translates to:
  /// **'639 Hz - Arınma ve Temizlik'**
  String get healingFreq639Heading;

  /// No description provided for @healingFreq741Heading.
  ///
  /// In tr, this message translates to:
  /// **'741 Hz - Tefekkür ve Dikkat'**
  String get healingFreq741Heading;

  /// No description provided for @healingFreq852Heading.
  ///
  /// In tr, this message translates to:
  /// **'852 Hz - Sekîne (Derin Huzur)'**
  String get healingFreq852Heading;

  /// No description provided for @healingFreq174Body.
  ///
  /// In tr, this message translates to:
  /// **'Bedensel ve ruhsal yorgunlukta sükûnete yönelme; şifa Allah’tandır.'**
  String get healingFreq174Body;

  /// No description provided for @healingFreq285Body.
  ///
  /// In tr, this message translates to:
  /// **'Zorlukta kalbi yumuşatma; Allah’a tevekkül ile devam etme niyeti.'**
  String get healingFreq285Body;

  /// No description provided for @healingFreq396Body.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir sayfa açma; günahtan arınma ve affa yönelme duası.'**
  String get healingFreq396Body;

  /// No description provided for @healingFreq417Body.
  ///
  /// In tr, this message translates to:
  /// **'Kalbi güçlendirme; imanı tazeleme ve istikamet hatırlaması.'**
  String get healingFreq417Body;

  /// No description provided for @healingFreq528Body.
  ///
  /// In tr, this message translates to:
  /// **'Gönül sükûneti; şükür ve teslimiyetle nefes alma.'**
  String get healingFreq528Body;

  /// No description provided for @healingFreq639Body.
  ///
  /// In tr, this message translates to:
  /// **'Kalbi kirleten düşüncelerden uzaklaşma; bağışlanma dileği.'**
  String get healingFreq639Body;

  /// No description provided for @healingFreq741Body.
  ///
  /// In tr, this message translates to:
  /// **'Ayete ve yaratılışa odaklanma; dağılan zihni toplama.'**
  String get healingFreq741Body;

  /// No description provided for @healingFreq852Body.
  ///
  /// In tr, this message translates to:
  /// **'Kalbe ferahlık veren sükûnet; Allah’ın rahmetine sığınma.'**
  String get healingFreq852Body;

  /// No description provided for @appleSignInCanceled.
  ///
  /// In tr, this message translates to:
  /// **'Apple girişi iptal edildi.'**
  String get appleSignInCanceled;

  /// No description provided for @appleSignInNotAuthorized.
  ///
  /// In tr, this message translates to:
  /// **'Apple hesabı yetki vermedi. iPhone Ayarları > Apple Kimliği > Giriş Yapma ve Güvenlik bölümünden Apple ile giriş iznini kontrol edin.'**
  String get appleSignInNotAuthorized;

  /// No description provided for @appleSignInProviderDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Firebase konsolunda Apple giriş sağlayıcısı kapalı görünüyor.'**
  String get appleSignInProviderDisabled;

  /// No description provided for @appleSignInInvalidCredential.
  ///
  /// In tr, this message translates to:
  /// **'Apple kimlik doğrulama bilgisi geçersiz geldi. Bundle ID ve Apple Sign In yetkisini Xcode/Firebase tarafında kontrol edin.'**
  String get appleSignInInvalidCredential;

  /// No description provided for @appleSignInNetworkFailed.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yüzünden Apple girişi tamamlanamadı.'**
  String get appleSignInNetworkFailed;

  /// No description provided for @settingsMenuPremiumTitle.
  ///
  /// In tr, this message translates to:
  /// **'ARIN Premium'**
  String get settingsMenuPremiumTitle;

  /// No description provided for @settingsMenuPremiumSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Lansman fiyatları ve reklamsız deneyim'**
  String get settingsMenuPremiumSubtitle;

  /// No description provided for @settingsMenuWidgetsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Widget Merkezi'**
  String get settingsMenuWidgetsTitle;

  /// No description provided for @settingsMenuWidgetsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım bilgileri ve takip widgetı'**
  String get settingsMenuWidgetsSubtitle;

  /// No description provided for @supportProductNotReady.
  ///
  /// In tr, this message translates to:
  /// **'Ürün bilgisi henüz hazır değil. Lütfen tekrar deneyin.'**
  String get supportProductNotReady;

  /// No description provided for @supportThanksTitle.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler! 🙏'**
  String get supportThanksTitle;

  /// No description provided for @supportThanksBody.
  ///
  /// In tr, this message translates to:
  /// **'Desteğin Arın için çok değerli. Bu katkıyla daha güzel bir deneyim sunmaya devam edeceğiz.'**
  String get supportThanksBody;

  /// No description provided for @commonOk.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get commonOk;

  /// No description provided for @supportPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arın\'a Destek Ol'**
  String get supportPageTitle;

  /// No description provided for @supportTierSmallTitle.
  ///
  /// In tr, this message translates to:
  /// **'Küçük Destek'**
  String get supportTierSmallTitle;

  /// No description provided for @supportTierSmallDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bir kahve desteğiyle geliştirmeye katkı ver.'**
  String get supportTierSmallDesc;

  /// No description provided for @supportTierMediumTitle.
  ///
  /// In tr, this message translates to:
  /// **'Orta Destek'**
  String get supportTierMediumTitle;

  /// No description provided for @supportTierMediumDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yeni içerik ve özelliklerin gelişmesini hızlandır.'**
  String get supportTierMediumDesc;

  /// No description provided for @supportTierLargeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Büyük Destek'**
  String get supportTierLargeTitle;

  /// No description provided for @supportTierLargeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Arın\'ın uzun vadeli gelişimine güçlü katkı ver.'**
  String get supportTierLargeDesc;

  /// No description provided for @supportPackagesDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Destek paketleri tek seferlik mağaza ürünleri olarak çalışır. Premium abonelikten ayrıdır.'**
  String get supportPackagesDisclaimer;

  /// No description provided for @supportHeaderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arın\'ın yanında ol'**
  String get supportHeaderTitle;

  /// No description provided for @supportHeaderDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bağış değil, mağaza kurallarına uygun tek seferlik destek paketleri. Uygulamanın reklamsız ve premium deneyimini büyütmemize yardımcı olur.'**
  String get supportHeaderDesc;

  /// No description provided for @languageChangeFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dil değiştirilemedi. Lütfen tekrar dene.'**
  String get languageChangeFailed;

  /// No description provided for @differentLocation.
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir konumdasın'**
  String get differentLocation;

  /// No description provided for @updatePrayerTimesForCity.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakitlerini {city}\'a göre güncelleyelim mi?'**
  String updatePrayerTimesForCity(Object city);

  /// No description provided for @rememberThisChoice.
  ///
  /// In tr, this message translates to:
  /// **'Bu tercihi hatırla, bir daha sorma'**
  String get rememberThisChoice;

  /// No description provided for @keepCurrentLocation.
  ///
  /// In tr, this message translates to:
  /// **'Kalsın'**
  String get keepCurrentLocation;

  /// No description provided for @updateLocation.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get updateLocation;

  /// No description provided for @settingsBackgroundLocationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda otomatik güncelle'**
  String get settingsBackgroundLocationTitle;

  /// No description provided for @settingsBackgroundLocationSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Açıksa uygulamayı hiç açmadan, şehir değişince namaz vakitleri kendiliğinden güncellenir.'**
  String get settingsBackgroundLocationSubtitle;

  /// No description provided for @settingsBackgroundLocationPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda güncelleme için telefon ayarlarından konum iznini \"Her Zaman İzin Ver\" yapmalısın.'**
  String get settingsBackgroundLocationPermissionDenied;

  /// No description provided for @settingsBackgroundLocationEnabledMessage.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda otomatik güncelleme açıldı.'**
  String get settingsBackgroundLocationEnabledMessage;

  /// No description provided for @settingsBackgroundLocationDisabledMessage.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda otomatik güncelleme kapatıldı.'**
  String get settingsBackgroundLocationDisabledMessage;

  /// No description provided for @backgroundLocationDisclosureTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arka Planda Konum Kullanımı'**
  String get backgroundLocationDisclosureTitle;

  /// No description provided for @backgroundLocationDisclosureBody.
  ///
  /// In tr, this message translates to:
  /// **'\"Her Zaman İzin Ver\"i onaylarsan Arın, konumunu uygulama kapalıyken bile arka planda düşük sıklıkla kontrol eder. Bu sayede şehir değiştiğinde namaz vakitlerin, kıble yönün ve namaz bildirimlerin uygulamayı açmana gerek kalmadan otomatik güncellenir. Konum verin yalnızca cihazında işlenir; reklam veya analiz için asla kullanılmaz.'**
  String get backgroundLocationDisclosureBody;

  /// No description provided for @backgroundLocationDisclosureDecline.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get backgroundLocationDisclosureDecline;

  /// No description provided for @backgroundLocationDisclosureAccept.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get backgroundLocationDisclosureAccept;

  /// No description provided for @sealYourIntention.
  ///
  /// In tr, this message translates to:
  /// **'Niyetini mühürle'**
  String get sealYourIntention;

  /// No description provided for @sealIntentionInfo.
  ///
  /// In tr, this message translates to:
  /// **'Az önce paylaştığın işaretler ve adın bu başlangıcın parçası; basılı tutarak niyetini pekiştir.'**
  String get sealIntentionInfo;

  /// No description provided for @touchAndHoldWhenReady.
  ///
  /// In tr, this message translates to:
  /// **'Hazır olduğunda dokun ve basılı tut.'**
  String get touchAndHoldWhenReady;

  /// No description provided for @youAreAlmostThere.
  ///
  /// In tr, this message translates to:
  /// **'Çok yaklaştın!'**
  String get youAreAlmostThere;

  /// No description provided for @promiseSealed.
  ///
  /// In tr, this message translates to:
  /// **'Tebrikler, Sözün Mühürlendi!'**
  String get promiseSealed;

  /// No description provided for @touchAndHoldToContinue.
  ///
  /// In tr, this message translates to:
  /// **'Ekrana dokun ve basılı tut\nDevam etmek için…'**
  String get touchAndHoldToContinue;

  /// No description provided for @skipWithArrow.
  ///
  /// In tr, this message translates to:
  /// **'Atla ➔'**
  String get skipWithArrow;

  /// No description provided for @redirecting.
  ///
  /// In tr, this message translates to:
  /// **'Yönlendiriliyorsun...'**
  String get redirecting;

  /// No description provided for @keepGoing.
  ///
  /// In tr, this message translates to:
  /// **'Devam et...'**
  String get keepGoing;

  /// No description provided for @premiumLoadingWait.
  ///
  /// In tr, this message translates to:
  /// **'Premium durumu yükleniyor. Lütfen kısa bir süre sonra tekrar deneyin.'**
  String get premiumLoadingWait;

  /// No description provided for @secondAlarmPremiumFeature.
  ///
  /// In tr, this message translates to:
  /// **'2. alarm premium özelliği'**
  String get secondAlarmPremiumFeature;

  /// No description provided for @secondAlarmAdWatchText.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz kullanımda 2. ezan alarmını 2 gün açmak için kısa reklam izlenir. Premium kullanıcılar bu kilidi görmez.'**
  String get secondAlarmAdWatchText;

  /// No description provided for @giveUp.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get giveUp;

  /// No description provided for @openAfterAd.
  ///
  /// In tr, this message translates to:
  /// **'Reklam sonrası aç'**
  String get openAfterAd;

  /// No description provided for @reflection.
  ///
  /// In tr, this message translates to:
  /// **'Yansıma'**
  String get reflection;

  /// No description provided for @yesterdayPrayerSummary.
  ///
  /// In tr, this message translates to:
  /// **'Dün · {weekday} · {yDone}/5  ·  Son 7 gün ort. {avg}/5'**
  String yesterdayPrayerSummary(Object avg, Object weekday, Object yDone);

  /// No description provided for @weeklyView.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık görünüm'**
  String get weeklyView;

  /// No description provided for @daysDoneSummary.
  ///
  /// In tr, this message translates to:
  /// **'{done}/7 gün'**
  String daysDoneSummary(Object done);

  /// No description provided for @inspirationAndAwareness.
  ///
  /// In tr, this message translates to:
  /// **'İlham ve farkındalık'**
  String get inspirationAndAwareness;

  /// No description provided for @shortBreaksForTruth.
  ///
  /// In tr, this message translates to:
  /// **'Hakikat ve şuur için kısa molalar'**
  String get shortBreaksForTruth;

  /// No description provided for @insightCommentStrong.
  ///
  /// In tr, this message translates to:
  /// **'Son günlerde ritmin çok güçlü; kalbin düzenle hizalanmış görünüyor. Böyle devam.'**
  String get insightCommentStrong;

  /// No description provided for @insightCommentPerfect.
  ///
  /// In tr, this message translates to:
  /// **'Dün beş vakit tamam — Rabb’ine yakın bir gün geçirmişsin. Bugün de aynı niyetle devam edebilirsin.'**
  String get insightCommentPerfect;

  /// No description provided for @insightCommentZero.
  ///
  /// In tr, this message translates to:
  /// **'Dün kayıt düşmemiş olabilir veya henüz işaretlenmemiş. Bugün tek bir vakitle bile çizgiyi yeniden çizebilirsin.'**
  String get insightCommentZero;

  /// No description provided for @insightCommentLow.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta ortalama düşük; bu normal — tefekkür ve küçük adımlarla yükselir. Bir vakit fazlası büyük fark yaratır.'**
  String get insightCommentLow;

  /// No description provided for @insightCommentGood.
  ///
  /// In tr, this message translates to:
  /// **'Dün {count}/5 vakit işaretli; bugün bir iki vakitle dengeyi tamamlamak mümkün.'**
  String insightCommentGood(Object count);

  /// No description provided for @insightCommentDefault.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş günler verisi senin için bir ayna: eksik kalan yerlerde merhamet, tamamlananlarda şükür.'**
  String get insightCommentDefault;

  /// No description provided for @qiblaHubPrayerCircleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dua Halkası'**
  String get qiblaHubPrayerCircleTitle;

  /// No description provided for @qiblaHubPrayerCircleSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Dua talebini paylaş, gönülden eşlik et'**
  String get qiblaHubPrayerCircleSubtitle;

  /// No description provided for @prayerCircleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dua Halkası'**
  String get prayerCircleTitle;

  /// No description provided for @prayerCircleHeroTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir duaya gönülden eşlik et'**
  String get prayerCircleHeroTitle;

  /// No description provided for @prayerCircleHeroBody.
  ///
  /// In tr, this message translates to:
  /// **'İsimsiz dua talepleri burada buluşur. Birbirimizin niyetine sessizce “âmin” diyelim.'**
  String get prayerCircleHeroBody;

  /// No description provided for @prayerCircleTwentyFourHours.
  ///
  /// In tr, this message translates to:
  /// **'Her talep 24 saat halkada kalır'**
  String get prayerCircleTwentyFourHours;

  /// No description provided for @prayerCircleAll.
  ///
  /// In tr, this message translates to:
  /// **'Dua halkası'**
  String get prayerCircleAll;

  /// No description provided for @prayerCircleMine.
  ///
  /// In tr, this message translates to:
  /// **'Dualarım'**
  String get prayerCircleMine;

  /// No description provided for @prayerCircleCreate.
  ///
  /// In tr, this message translates to:
  /// **'Dua talebi gönder'**
  String get prayerCircleCreate;

  /// No description provided for @prayerCircleEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Halka yeni bir duayı bekliyor'**
  String get prayerCircleEmptyTitle;

  /// No description provided for @prayerCircleEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'İlk dua talebini paylaşarak bu iyilik halkasını başlatabilirsin.'**
  String get prayerCircleEmptyBody;

  /// No description provided for @prayerCircleMineEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir dua talebin yok'**
  String get prayerCircleMineEmptyTitle;

  /// No description provided for @prayerCircleMineEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Kalbindeki niyeti isimsiz olarak paylaş; talebin 24 saat burada kalsın.'**
  String get prayerCircleMineEmptyBody;

  /// No description provided for @prayerCircleLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dua halkası yüklenemedi'**
  String get prayerCircleLoadFailed;

  /// No description provided for @prayerCircleTryAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get prayerCircleTryAgain;

  /// No description provided for @prayerCircleComposeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dua talebini yaz'**
  String get prayerCircleComposeTitle;

  /// No description provided for @prayerCircleComposeBody.
  ///
  /// In tr, this message translates to:
  /// **'Kısa, içten ve kişisel bilgi içermeyen bir niyet paylaş.'**
  String get prayerCircleComposeBody;

  /// No description provided for @prayerCircleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Ailem için sağlık ve huzur duası rica ediyorum…'**
  String get prayerCircleHint;

  /// No description provided for @prayerCircleCategory.
  ///
  /// In tr, this message translates to:
  /// **'Niyet konusu'**
  String get prayerCircleCategory;

  /// No description provided for @prayerCircleCategoryGeneral.
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get prayerCircleCategoryGeneral;

  /// No description provided for @prayerCircleCategoryHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get prayerCircleCategoryHealth;

  /// No description provided for @prayerCircleCategoryFamily.
  ///
  /// In tr, this message translates to:
  /// **'Aile'**
  String get prayerCircleCategoryFamily;

  /// No description provided for @prayerCircleCategoryPeace.
  ///
  /// In tr, this message translates to:
  /// **'Huzur'**
  String get prayerCircleCategoryPeace;

  /// No description provided for @prayerCircleCategoryEducation.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim'**
  String get prayerCircleCategoryEducation;

  /// No description provided for @prayerCircleCategoryWork.
  ///
  /// In tr, this message translates to:
  /// **'İş ve rızık'**
  String get prayerCircleCategoryWork;

  /// No description provided for @prayerCirclePrivacyNote.
  ///
  /// In tr, this message translates to:
  /// **'Güvenliğin için ad, telefon, sosyal medya, ödeme bilgisi veya bağlantı paylaşma. Otomatik kontroller ve kullanıcı bildirimleri uygulanır; kişisel bilgi paylaşmama sorumluluğu sana aittir.'**
  String get prayerCirclePrivacyNote;

  /// No description provided for @prayerCircleContinue.
  ///
  /// In tr, this message translates to:
  /// **'Göndermeye devam et'**
  String get prayerCircleContinue;

  /// No description provided for @prayerCircleTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Dua talebin en az 8 karakter olmalı.'**
  String get prayerCircleTooShort;

  /// No description provided for @prayerCircleAdGateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Duanı halkaya ekle'**
  String get prayerCircleAdGateTitle;

  /// No description provided for @prayerCircleAdGateBody.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz kullanımda her dua talebi için kısa bir ödüllü reklam izlenir. Premium’da reklam gösterilmez.'**
  String get prayerCircleAdGateBody;

  /// No description provided for @prayerCircleWatchAd.
  ///
  /// In tr, this message translates to:
  /// **'Reklam izle ve gönder'**
  String get prayerCircleWatchAd;

  /// No description provided for @prayerCirclePremiumOption.
  ///
  /// In tr, this message translates to:
  /// **'Premium ile reklamsız gönder'**
  String get prayerCirclePremiumOption;

  /// No description provided for @prayerCircleAdFailed.
  ///
  /// In tr, this message translates to:
  /// **'Reklam şu an hazırlanamadı. Lütfen biraz sonra tekrar dene.'**
  String get prayerCircleAdFailed;

  /// No description provided for @prayerCircleSent.
  ///
  /// In tr, this message translates to:
  /// **'Dua talebin halkaya eklendi. Hayra vesile olsun.'**
  String get prayerCircleSent;

  /// No description provided for @prayerCirclePray.
  ///
  /// In tr, this message translates to:
  /// **'Dua ettim'**
  String get prayerCirclePray;

  /// No description provided for @prayerCirclePrayed.
  ///
  /// In tr, this message translates to:
  /// **'Eşlik ettin'**
  String get prayerCirclePrayed;

  /// No description provided for @prayerCircleOwnRequest.
  ///
  /// In tr, this message translates to:
  /// **'Senin duan'**
  String get prayerCircleOwnRequest;

  /// No description provided for @prayerCircleYours.
  ///
  /// In tr, this message translates to:
  /// **'Senin talebin'**
  String get prayerCircleYours;

  /// No description provided for @prayerCirclePrayedThanks.
  ///
  /// In tr, this message translates to:
  /// **'Âmin. Bu duaya gönülden eşlik ettin.'**
  String get prayerCirclePrayedThanks;

  /// No description provided for @prayerCircleAlreadyPrayed.
  ///
  /// In tr, this message translates to:
  /// **'Bu duaya daha önce eşlik ettin.'**
  String get prayerCircleAlreadyPrayed;

  /// No description provided for @prayerCirclePrayerCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Henüz dua eden yok} =1{1 kişi dua etti} other{{count} kişi dua etti}}'**
  String prayerCirclePrayerCount(int count);

  /// No description provided for @prayerCircleHoursLeft.
  ///
  /// In tr, this message translates to:
  /// **'{hours, plural, =1{1 saat kaldı} other{{hours} saat kaldı}}'**
  String prayerCircleHoursLeft(int hours);

  /// No description provided for @prayerCircleMinutesLeft.
  ///
  /// In tr, this message translates to:
  /// **'{minutes, plural, =1{1 dk kaldı} other{{minutes} dk kaldı}}'**
  String prayerCircleMinutesLeft(int minutes);

  /// No description provided for @prayerCircleLoadMore.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla göster'**
  String get prayerCircleLoadMore;

  /// No description provided for @prayerCircleReportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu dua talebi bildirilsin mi?'**
  String get prayerCircleReportTitle;

  /// No description provided for @prayerCircleReportBody.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler halkanın güvenli kalmasına yardımcı olur. Talep incelenecektir.'**
  String get prayerCircleReportBody;

  /// No description provided for @prayerCircleReportAction.
  ///
  /// In tr, this message translates to:
  /// **'Bildir'**
  String get prayerCircleReportAction;

  /// No description provided for @prayerCircleReported.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler. Talep bildirildi.'**
  String get prayerCircleReported;

  /// No description provided for @prayerCircleAcceptRulesLabel.
  ///
  /// In tr, this message translates to:
  /// **'Talebin isimsiz paylaşılır ve topluluk kurallarına uygun olmalı.'**
  String get prayerCircleAcceptRulesLabel;

  /// No description provided for @prayerCircleAcceptRulesRequired.
  ///
  /// In tr, this message translates to:
  /// **'Göndermeden önce topluluk kurallarını onayla.'**
  String get prayerCircleAcceptRulesRequired;

  /// No description provided for @prayerCircleMoreActions.
  ///
  /// In tr, this message translates to:
  /// **'Diğer işlemler'**
  String get prayerCircleMoreActions;

  /// No description provided for @prayerCircleDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dua talebini kaldır?'**
  String get prayerCircleDeleteTitle;

  /// No description provided for @prayerCircleDeleteBody.
  ///
  /// In tr, this message translates to:
  /// **'Talep halkadan hemen kaldırılır ve geri alınamaz.'**
  String get prayerCircleDeleteBody;

  /// No description provided for @prayerCircleDeleteAction.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get prayerCircleDeleteAction;

  /// No description provided for @prayerCircleAdminDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu talep yönetici tarafından kaldırılsın mı?'**
  String get prayerCircleAdminDeleteTitle;

  /// No description provided for @prayerCircleAdminDeleteBody.
  ///
  /// In tr, this message translates to:
  /// **'Uygunsuz içerik olarak kalıcı biçimde kaldırılır ve geri alınamaz.'**
  String get prayerCircleAdminDeleteBody;

  /// No description provided for @prayerCircleAdminDeleteAction.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici: Kaldır'**
  String get prayerCircleAdminDeleteAction;

  /// No description provided for @prayerCircleAdminDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Talep yönetici tarafından kaldırıldı.'**
  String get prayerCircleAdminDeleted;

  /// No description provided for @prayerCircleCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get prayerCircleCancel;

  /// No description provided for @prayerCircleSlowDown.
  ///
  /// In tr, this message translates to:
  /// **'Çok hızlı işlem yaptın. Kısa süre sonra tekrar dene.'**
  String get prayerCircleSlowDown;

  /// No description provided for @prayerCircleContentRejected.
  ///
  /// In tr, this message translates to:
  /// **'Metni kontrol et; kişisel, iletişim veya ödeme bilgisi paylaşma.'**
  String get prayerCircleContentRejected;

  /// No description provided for @prayerCircleExpired.
  ///
  /// In tr, this message translates to:
  /// **'Bu dua talebinin süresi dolmuş olabilir.'**
  String get prayerCircleExpired;

  /// No description provided for @prayerCircleGenericError.
  ///
  /// In tr, this message translates to:
  /// **'İşlem tamamlanamadı. Bağlantını kontrol edip tekrar dene.'**
  String get prayerCircleGenericError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
