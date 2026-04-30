// lib/core/constants/app_strings.dart
// Tüm Türkçe UI metinlerinin tek merkezi kaynağı.
// KESİN KURAL: Hiçbir UI metnini bu dosya dışında sabit olarak tanımlamayın.

abstract final class AppStrings {
  // ─── Uygulama Geneli ────────────────────────────────────────────────
  static const String appName = 'Arın';
  static const String appTagline = 'Arın. Büyü. Devam Et.';

  // ─── Onboarding (4 slayt) ───────────────────────────────────────────
  static const String onboardingSlide1Title = 'Gürültünün içinde bir nefes';
  static const String onboardingSlide1Subtitle =
      'Zihin koştururken iç sesin çoğu zaman fısıltıda kalır. Küçük duruşlar — bir nefes, bir anlık duraklama — '
      'manevi dengeyi yeşertir; dışarıda aradığın huzur, bazen önce içerde sessizce filizlenir.';

  static const String onboardingSlide2Title = 'Küçük başla, istikrarla büyü';
  static const String onboardingSlide2Subtitle =
      'Gelişim ve Arınma’da alışkanlıklarını kayıt altına al. Bir gün, bir nefes, bir seçim — '
      'zinciri kırmadan ilerle; arınma da merdiven çıkmak gibi, basamak basamak güçlenir.';

  static const String onboardingSlide3Title = 'Vakit, namaz ve günlük düzen';
  static const String onboardingSlide3Subtitle =
      'Namaz saatlerini yanında tut; nefes egzersizi ve güçlenme alanın zor anlarda yanında olsun. '
      'İbadetini, takibini ve iç sesini aynı ritimde topla.';

  static const String onboardingSlide4Title = 'Arın: tek uygulamada bir arada';
  static const String onboardingSlide4Subtitle =
      'İlhamdan günlük alışkanlığa, vakit bildiriminden arınma sayacına kadar yolculuğun burada. '
      'Hazırsan birlikte başlayalım — sen yürü, biz hatırlatır ve eşlik ederiz.';

  static const String onboardingGetStarted = 'Başlayalım';
  static const String onboardingSkip = 'Geç';
  static const String onboardingNext = 'İleri';

  // ─── Anket ve Onboarding V2 ─────────────────────────────────────────
  static const String surveyNameTitle = 'Sana nasıl hitap edelim?';
  static const String surveyNameHint = 'İsminiz';
  static const String surveyGenderTitle = 'Cinsiyetini öğrenebilir miyiz?';
  static const String surveyGenderSubtitle =
      'Sana daha iyi yardımcı olabilmek için...';
  static const String surveyGenderMale = 'Erkek';
  static const String surveyGenderFemale = 'Kadın';

  static const String surveyMoodTitle =
      'Şu an iç dünyanda hangi ton daha baskın?';
  static const String surveyMoodSubtitle =
      'Kendini tanımlayan işaretleri seç; içerik ve hatırlatmalar buna göre yumuşar.';

  /// Eski “meslek” sorusu yerine: günün akışı (yine sectorTags’a yazılır).
  static const String surveyDailyRhythmTitle =
      'Günün büyük kısmı genelde nerede akıyor?';
  static const String surveyDailyRhythmSubtitle =
      'Tempo ve ortam, sana uygun ritmi anlamamıza yardım eder.';
  static const String surveyInnerThemesTitle =
      'İç dünyanda öne çıkan temalar hangileri?';
  static const String surveySubtitle =
      'Cevapların içerikleri kişiselleştirmek için kullanılır.';
  static const String surveyInnerThemesSubtitle =
      'Birden fazla seçebilirsin; samimi işaretler bize seni daha iyi tanıtmaya yardım eder.';

  static const String surveyNotificationTitle = 'Bildirimler';
  static const String surveyNotificationLead =
      'Namaz hatırlatmaları ve günün mesajları zamanında ulaşsın.';
  static const String surveyNotificationSubtitle =
      'Vakit bildirimleri ile içerik önerilerinin kaçmaması için bildirim iznine ihtiyacımız var. '
      'İstediğin zaman ayarlardan kapatabilirsin.';
  static const String surveyNotificationAllow = 'Bildirimlere izin ver';
  static const String surveyNotificationSkip = 'Şimdilik geç';
  static const String surveyNotificationOpenSettings = 'Ayarlardan aç';

  static const String surveySealLabel =
      'Az önce paylaştığın işaretler ve adın bu başlangıcın parçası; basılı tutarak niyetini pekiştir.';

  /// Virgül yok: onboarding’de displayNameSuffix ", isim" ile birleşir.
  static const String surveySealTitle = 'Niyetini mühürle';
  static const String surveySealEncourage =
      'Hazır olduğunda dokun ve basılı tut.';
  static const String surveySealHold =
      'Ekrana dokun ve basılı tut\nDevam etmek için…';
  static const String surveySealEncourageHold =
      'Nefesini yavaşlat, niyetini hatırla.';
  static const String surveySealSuccess = 'Başlangıcın mühürlendi. Hoş geldin.';

  /// Mühür adımında başlık altı kısa yankı satırları (atmosfer).
  static const String surveySealEcho1 =
      'Paylaştığın işaretler, sana özel içerikleri şekillendirecek.';
  static const String surveySealEcho2 =
      'Bu mühür; küçük bir adım, net bir niyet.';
  static const String surveySealEcho3 =
      'Basılı tutarken nefesini yumuşat, kalbini hizala.';

  /// İbadet (namaz takibi) — uyarı adımı (bırakma programlarındaki “dikkat” ile aynı rol).
  static const String namazIbadetWarningTitle = 'Dikkat';
  static const String namazIbadetWarningSubtitle =
      'Namaz takibi bir gösteriş alanı değil; kalbini huşû ve dürüstlükle düzenlemek içindir.';
  static const String namazIbadetWarningBullet1 =
      'Tikleri yalnızca kendin için işaretle; riya veya başkasına baskı aracı olmasın.';
  static const String namazIbadetWarningBullet2 =
      'Vakit kaçırınca kendini küçümseme; her dönüş tövbe ve yeniden başlamaktır.';
  static const String namazIbadetWarningBullet3 =
      'Bildirimleri istediğin zaman sistem ayarlarından yönetebilirsin; takip yük olmamalı.';

  static const String namazIbadetCommitmentTitle = 'Kendine sözün';
  static const String namazIbadetCommitmentHint =
      'Namazına dair içten bir cümle yaz (en az 8 karakter).';
  static const String namazIbadetCommitmentFieldHint =
      'Kalbinden geçen bir cümle…';
  static const String namazIbadetCommitmentTooShort =
      'Lütfen kendine bir söz yaz (en az 8 karakter).';
  static const String namazIbadetSealTitlePrefix = 'Sözünü mühürle';
  static const String namazIbadetSealHoldHint = 'Parmağını basılı tut';
  static const String namazIbadetSealSuccess =
      'Sözün kaydedildi. İbadet ekranına geçiyorsun.';
  static const String namazIbadetPrepTitle = 'Hazırlık';

  /// Onboarding sonrası ana ekrana geçmeden önce veri ısıtma ekranı.
  static const String appPrepareTitle = 'Arına hazırlanıyoruz';
  static const String appPrepareSubtitle =
      'Namaz vakitleri ve günün sözleri senin için yükleniyor…';

  static const String surveySave = 'Başla ➔';
  static const String surveyNext = 'Devam Et';
  static const String surveyBack = 'Geri';
  static const String surveySkip = 'Atla ➔';
  static const String surveyGenderDecline = 'Paylaşmak istemiyorum';
  static const String surveyNameGreetingPrefix = 'Merhaba';
  static const String surveySummaryTitle = 'Hazırsın';
  static const String surveySummarySubtitle =
      'Temel tercihlerini kaydettik. Arın deneyimini bu işaretlere göre şekillendireceğiz.';
  static const String surveySummaryCardTitle = 'Başlangıç özeti';
  static const String surveySummaryItemName = 'Hitap';
  static const String surveySummaryItemMood = 'Ruh hali işaretlerin';
  static const String surveySummaryItemRhythm = 'Günlük akış işaretlerin';
  static const String surveySummaryItemThemes = 'İç tema işaretlerin';
  static const String surveySummaryItemNotificationOn = 'Açık';
  static const String surveySummaryItemNotificationOff = 'Kapalı';
  static const String surveySummaryNotProvided = 'Belirtilmedi';
  static const String surveySummaryAction = 'Ana ekrana geç';
  static const String surveySummarySaveError =
      'Başlangıç kaydedilemedi. Lütfen tekrar dene.';

  static const String surveyWeeklyTitle = 'Haftalık Değerlendirme';
  static const String surveyWeeklySubtitle =
      'Bu haftaki durumunu bizimle paylaş.';

  // ─── Ruh Hali Etiketleri ────────────────────────────────────────────
  static const String moodHappy = 'Mutlu';
  static const String moodCalm = 'Sakin';
  static const String moodStressed = 'Stresli';
  static const String moodSad = 'Üzgün';
  static const String moodGrateful = 'Şükrediyorum';
  static const String moodAnxious = 'Kaygılı';
  static const String moodMotivated = 'Motive';

  // ─── Meslek/Alan Etiketleri (Detaylı) ───────────────────────────────
  static const String sectorStudent = 'Lise / Üniversite / Hazırlık';
  static const String sectorPrivate = 'Özel Sektör';
  static const String sectorPublic = 'Kamu Personeli';
  static const String sectorBusiness = 'Kendi İşim / Serbest';
  static const String sectorTrade = 'Ticaret';
  static const String sectorHousehold = 'Ev Hanımı / Ev Erkeği';
  static const String sectorOther = 'Diğer';

  // ─── İhtiyaç Etiketleri ─────────────────────────────────────────────
  static const String needMotivation = 'Motivasyon';
  static const String needSabr = 'Sabır';
  static const String needShukr = 'Şükür';
  static const String needTawakkul = 'Tevekkül';
  static const String needFocus = 'Odaklanma';
  static const String needHealing = 'Şifa';
  static const String needRizq = 'Rızık & Bereket';

  // ─── Alt Navigasyon ─────────────────────────────────────────────────
  static const String navHome = 'Ana Ekran';
  static const String navHabits = 'Alışkanlıklar';
  static const String navExplore = 'Keşfet';
  static const String navSettings = 'Ayarlar';

  // ─── Kıble araçları (hub) ────────────────────────────────────────────
  static const String qiblaHubCompassTitle = 'Kıble yönünü bul';
  static const String qiblaHubCompassSubtitle =
      'Pusula ve konum ile Kâbe yönünü göster';
  static const String qiblaHubOpenAction = 'Aç';
  static const String qiblaHubZikirTitle = 'Zikirmatik';

  /// Boş: kullanıcı zikir seçene kadar üst kartta büyük metin gösterilmez.
  static const String qiblaHubZikirPhraseDefault = '';
  static const String zikirMatikPhraseEmptyHint = 'Zikir seçmek için dokun';
  static const String qiblaHubZikirRoundLabel = 'TUR';
  static const String qiblaHubZikirFeatureSubtitle =
      'Dijital sayaç; zikir bilgisi, tur geçmişi ve hedef (33/99)';
  static const String qiblaHubZikirSwipeHint =
      'Ortadaki düğmeye dokunarak sayın.';
  static const String qiblaHubZikirTesbihSemanticsLabel = 'Zikirmatik sayacı';
  static const String qiblaHubBreathingTitle = 'Nefes Egzersizi';
  static const String qiblaHubBreathingSubtitle =
      '4-7-8 nefes döngüsü ile sakinleş, odağını toparla';

  /// İyileştirici Frekanslar (kıble hub kartı + sayfa)
  static const String qiblaHubHealingTitle = 'İyileştirici Frekanslar';
  static const String qiblaHubHealingSubtitle =
      'Terapi tonları, ambiyans ve uyku zamanlayıcısı ile sakin bir oturum';
  static const String healingPageTitle = 'İyileştirici Frekanslar';
  static const String healingTherapyLabel = 'Terapi Frekansı';
  static const String healingAmbientRowLabel = 'Ambiyans Sesi';
  static const String healingAmbientPickHint = 'Seçiniz';
  static const String healingAmbientSheetTitle = 'Ambiyans Sesi Seçin';
  static const String healingPresetsLabel = 'ÖNAYARLAR';
  static const String healingPresetFocus = 'Focus';
  static const String healingPresetRelax = 'Relax';
  static const String healingPresetSleep = 'Sleep';
  static const String healingSliderFreq = 'Frekans tonu (Hz)';
  static const String healingSliderAmb = 'Ambiyans';
  static const String healingSleepTimerRow = 'Uyku Zamanlayıcı';

  /// Uyku satırı: zamanlayıcı kapalıyken (sheet’teki “kapalı”dan kısa).
  static const String healingSleepRowValueOff = 'Kapalı';
  static const String healingSleepRowRemainingPrefix = 'Kalan ';
  static const String healingAllFrequencies = 'Tüm Frekanslar';
  static const String healingSleepSheetTitle = 'Uyku Zamanlayıcı';
  static const String healingSleepSheetSubtitle =
      'Kaç dakika sonra durdurulsun?';
  static const String healingSleepOff = 'Zamanlayıcı kapalı';
  static const String healingCancel = 'İptal';
  static const String healingSleepMinutesLabel = 'Dakika';
  static const String healingInfoTitle = 'Bilgi';
  static const String healingInfoBody =
      'Bu bölüm rahatlama ve tefekkür için tasarlanmıştır; tıbbi tedavi yerine geçmez. '
      'Sesleri düşük seviyede dinlemeniz önerilir. Rahatsızlık hissederseniz durdurun.';
  static const String healingCatForest = 'Orman';
  static const String healingCatFire = 'Ateş';
  static const String healingCatEvren = 'Evren';
  static const String healingCatInshirah = 'İnşirah';

  static const String healingAmbDisplayForest = 'Orman Sesi';
  static const String healingAmbDisplayFire = 'Ateş Sesi';
  static const String healingAmbDisplayEvren = 'Evren Sesi';
  static const String healingAmbDisplayInshirah = 'İnşirah Suresi';
  static const String healingInshirahLocksFrequencyHint =
      'İnşirah modunda frekans kontrolleri kapalıdır.';

  static const String healingFreq174Short = 'Terapi Frekansı';
  static const String healingFreq174Heading = '174 Hz - Şifa ve Rahatlama';
  static const String healingFreq174Body =
      'Bedensel ve ruhsal yorgunlukta sükûnete yönelme; şifa Allah’tandır.';

  static const String healingFreq285Short = 'Direnç ve Metanet';
  static const String healingFreq285Heading = '285 Hz - Sabır ve Sebat';
  static const String healingFreq285Body =
      'Zorlukta kalbi yumuşatma; Allah’a tevekkül ile devam etme niyeti.';

  static const String healingFreq396Short = 'Yenilenme';
  static const String healingFreq396Heading = '396 Hz - Bereket ve Başlangıç';
  static const String healingFreq396Body =
      'Yeni bir sayfa açma; günahtan arınma ve affa yönelme duası.';

  static const String healingFreq417Short = 'İç güç';
  static const String healingFreq417Heading = '417 Hz - İç Güç ve İman';
  static const String healingFreq417Body =
      'Kalbi güçlendirme; imanı tazeleme ve istikamet hatırlaması.';

  static const String healingFreq528Short = 'Huzur';
  static const String healingFreq528Heading = '528 Hz - Huzur ve Sükûnet';
  static const String healingFreq528Body =
      'Gönül sükûneti; şükür ve teslimiyetle nefes alma.';

  static const String healingFreq639Short = 'Arınma';
  static const String healingFreq639Heading = '639 Hz - Arınma ve Temizlik';
  static const String healingFreq639Body =
      'Kalbi kirleten düşüncelerden uzaklaşma; bağışlanma dileği.';

  static const String healingFreq741Short = 'Tefekkür';
  static const String healingFreq741Heading = '741 Hz - Tefekkür ve Dikkat';
  static const String healingFreq741Body =
      'Ayete ve yaratılışa odaklanma; dağılan zihni toplama.';

  static const String healingFreq852Short = 'Sekîne';
  static const String healingFreq852Heading = '852 Hz - Sekîne (Derin Huzur)';
  static const String healingFreq852Body =
      'Kalbe ferahlık veren sükûnet; Allah’ın rahmetine sığınma.';

  static const String zikirMatikSave = 'Kaydet';
  static const String zikirMatikSavedOk = 'Kayıt listeye eklendi';
  static const String zikirMatikList = 'Zikir bilgisi';
  static const String zikirMatikReset = 'Sıfırla';
  static const String zikirMatikResetConfirmTitle = 'Sayacı sıfırla?';
  static const String zikirMatikResetConfirmBody =
      'Toplam sayı ve tur bilgisi sıfırlanır.';
  static const String zikirMatikCancel = 'Vazgeç';
  static const String zikirMatikConfirm = 'Tamam';
  static const String zikirMatikSaveTitle = 'Oturumu kaydet';
  static const String zikirMatikPhraseLabel = 'Zikir adı';
  static const String zikirMatikListTitle = 'Zikir bilgisi';
  static const String zikirMatikSectionDaily = 'Bugünün payı';
  static const String zikirMatikSectionAnalytics = 'Özet ve analiz';
  static const String zikirMatikSectionHistory = 'Tamamlanan turlar';
  static const String zikirMatikSectionArchive = 'Arşiv oturumları';
  static const String zikirMatikEmptyTurHistory =
      'Henüz tamamlanan tur kaydı yok. Hedefe ulaştığında buraya düşer.';
  static const String zikirMatikEmptyAnalytics =
      'Daha fazla tur tamamladıkça özet ve karşılaştırmalar burada oluşur.';
  static const String zikirMatikDeleteTurTitle = 'Bu tur kaydını sil?';
  static const String zikirMatikEmptyList = 'Arşivde kayıt yok.';
  static const String zikirMatikDelete = 'Sil';
  static const String zikirMatikShare = 'Paylaş';
  static const String zikirMatikDeleteConfirmTitle = 'Kaydı sil?';
  static const String zikirMatikTargetLabel = 'Hedef';
  static const String zikirMatikTarget33 = '33';
  static const String zikirMatikTarget99 = '99';
  static const String zikirMatikTargetCustom = 'Özel…';
  static const String zikirMatikThisRound = 'BU TUR';
  static const String zikirMatikSoundTick = 'Ses';
  static const String zikirMatikVibrateTarget =
      'Açıkken her sayımda titreşir; tur bitince ek güçlü titreşim';

  /// Alt araç: yuvarlak titreşim anahtarı altındaki kısa etiket.
  static const String zikirMatikVibrateShortLabel = 'Titreşim';
  static const String zikirMatikEditPhrase = 'Zikir adını düzenle';
  static const String zikirMatikPickPhrase = 'ZİKİR SEÇ';
  static const String zikirMatikCustomPhrase = 'KENDİ METNİNİ YAZ…';
  static const String zikirMatikRoundComplete = 'Tur tamamlandı';

  /// Sık kullanılan zikirler (zikirmatik hızlı seçim, büyük harf).
  static const List<String> zikirMatikPresetPhrases = <String>[
    'SÜBHANALLAH',
    'ELHAMDÜLİLLAH',
    'ALLAHU EKBER',
    'LAILAHEİLLALLAH',
    'ESTAĞFİRULLAH',
    'HASBÜNALLAH',
  ];

  /// Gün bazlı dönüşümlü kısa hatırlatmalar (zikir bilgisi üst kartı).
  static const List<String> zikirMatikDailyReflections = <String>[
    '“Rabbinizi çokça anın; umulur ki kurtuluşa eresiniz.”',
    'Kalbi diriltmek zikirdedir; her tekrar bir nefes.',
    'Rabbin seni terk etmez; sen O’nu an.',
    'Sükûnet, dili zikre verdiğinde gelir.',
    'Küçük ses, büyük huzur: Sübhanallah.',
    'Şükür kapısı: Elhamdülillah.',
    'Ufuk açan tekbir: Allahu ekber.',
    'Kalbin mührü: Lâ ilâhe illallah.',
    'Tövbe yumuşatır: Estağfirullah.',
    'Zikir, gönül evinin ışığıdır.',
    'Dağınık günleri toplayan tek cümle: Hasbünallah.',
    'Sade bir “Ya Allah” yeter bazen.',
    'Dil zikredince göz ferahlar.',
    'Hedefe varmak sabır ve devam ister.',
    'Her tur, bir adım daha yakınlık.',
    'Gürültüde kaybolma; zikir sana yol gösterir.',
    'Rabbine sığın; sonra nefes al.',
    'Kısa da olsa düzenli zikir, derin iz bırakır.',
    'Bugünü güzelleştiren: küçük bir hatırlama.',
    'Niyet temiz, sayım bereketli olsun.',
    'Kalp kırıksa zikir sargıdır.',
    'Yorulduğunda dur; sonra devam et.',
    'Allah’ı anan asla yalnız değildir.',
    'Zikir, zamanı kutsallaştırır.',
    'Ses çıkmasa da kalp duyar.',
    'Bir tur, bir bağ; Rabbinle kurduğun bağ.',
    'Sabah zikri, günü aydınlatır.',
    'Akşam zikri, günü huzurla kapatır.',
    'Hedef 33 mü 99 mu; ikisi de güzel.',
    'Kıyas etme; kendi yolunda ilerle.',
    'Bugünün sadakası: dilindeki zikir.',
    'Geçmişe takılma; bugünü an.',
    'Yarın için en güzel hazırlık: bugünkü niyet.',
    'Zikir listesi uzun değil; samimiyet derin olsun.',
    'Her “Sübhanallah” bir çiçek eker kalbe.',
    'Her “Elhamdülillah” bir şükür dalgası.',
    'Tekbir yükseltir umut.',
    'Kelime-i tevhid sadeleştirir hayatı.',
    'İstiğfar temizler; yeniden başlatır.',
    'Zikrullah: Allah’ı özlemek ve anmak.',
  ];

  // ─── Ana Ekran ──────────────────────────────────────────────────────
  static const String homeQiblaTriangleHint = 'Kıble yönünü bul';
  static const String homePrayerCardTitle = 'Sıradaki Namaz';
  static const String homePrayerCardRemaining = 'kaldı';
  static const String homeDailyContentTitle = 'Günün Mesajı';

  /// Günlük söz kartı — metin boş kalırsa (veri hatası).
  static const String homeDailyWisdomPlaceholder =
      'Hatırlatıcı metni yüklenemedi. Sayfayı yenilemeyi dene.';
  static const String homeHabitsTitle = 'Serilerim';
  static const String homeGreetingMorning = 'Hayırlı Sabahlar';
  static const String homeGreetingAfternoon = 'Hayırlı Günler';
  static const String homeGreetingEvening = 'Hayırlı Akşamlar';
  static const String homeGreetingNight = 'Hayırlı Geceler';

  // ─── Namaz bildirimi sesleri (sentez WAV — telif içermez) ────────────
  static const String prayerNtfChannelDesc =
      'Vakit hatırlatıcıları — seçtiğin bildirim sesi';
  static const String prayerNtfSoundPickerTitle = 'Bildirim sesi';
  static const String prayerNtfSoundQuickAllTitle =
      'Hızlı seçim (tüm vakitler)';
  static const String prayerNtfSoundQuickAllSubtitle =
      'Önce tek ses seç; istersen detaylı ayarda vakit bazında ayrılaştır.';
  static const String prayerNtfSoundApplyAllButton =
      'Seçtiğim sesi tüm vakitlere uygula';
  static const String prayerNtfSoundAdvancedToggle =
      'Detaylı ayar (vakit bazlı)';
  static const String prayerNtfSoundAppliedAllSuccess =
      'Seçilen ses tüm vakitlere uygulandı.';
  static const String prayerNtfSoundSystem = 'Telefonun varsayılan sesi';
  static const String prayerNtfSoundAdhanTurkish =
      'Ezan — Türkçe işleme (10 sn, baştan)';
  static const String prayerNtfSoundAdhanDubai =
      'Ezan — Dubai / Ramadan (9 sn, baştan)';
  static const String prayerNtfSoundAmbientFlute =
      'Huzur — flute doku (6 sn, baştan)';
  static const String prayerNtfSoundAmbientPianoGuitar =
      'Huzur — piyano & gitar (7 sn, baştan)';
  static const String prayerNtfSoundAmbientEthereal =
      'Huzur — ethereal voices (10 sn, baştan)';
  static const String prayerNtfSoundSectionDay =
      'Öğle, İkindi, Akşam, Yatsı (ve İmsak/Güneş varsayılanı)';
  static const String prayerNtfSoundSectionSabah = 'İmsak — kendi sesin';
  static const String prayerNtfSoundSectionImsak = 'Güneş — kendi sesin';
  static const String prayerNtfSoundPickFromPhone = 'Telefondan ses seç';
  static const String prayerNtfSoundClearUserFile = 'Kaldır';
  static const String prayerNtfSoundUserFromPhone = 'Telefondan seçilen ses';
  static const String prayerNtfSoundUserFileActiveHint =
      'Bu vakit için şu an telefondan seçilen dosya kullanılıyor. Katalogdan bir ses seçersen dosya kalkar.';
  static const String prayerNtfSoundSubtitlePerPrayer =
      'Her vakit için ayrı ayrı: telefonun varsayılan sesi, katalogdan ton veya telefondan kendi dosyan. '
      'Uygula ile kaydet.';
  static const String prayerNtfSoundImportFailed =
      'Ses dosyası alınamadı. Başka bir dosya veya format dene (WAV, M4A…).';
  static const String prayerNtfSoundPreviewSystem =
      'Önizleme yok — cihazının varsayılan bildirim sesi kullanılır.';
  static const String prayerNtfSoundPreviewTitle = 'Bildirim sesi önizleme';
  static const String prayerNtfSoundPreviewBody =
      '~10 sn boyunca telefonunun varsayılan bildirim sesi çalar.';

  // ─── Alışkanlıklar ──────────────────────────────────────────────────
  static const String habitsPageTitle = 'Alışkanlıklarım';
  static const String habitsAddGood = 'Gelişim rutini ekle';
  static const String habitsAddBad = 'Arınma hedefi ekle';
  static const String habitsTypeGood = 'Gelişim';
  static const String habitsTypeBad = 'Arınma';
  static const String habitsNameHint = 'Alışkanlık adı...';
  static const String habitsSave = 'Kaydet';
  static const String habitsStreakLabel = 'gün serisi';
  static const String habitsDone = 'Tamamlandı!';
  static const String habitsMarkDone = 'Bugünü Tamamla';
  static const String habitsDeleteConfirm =
      'Bu alışkanlığı silmek istiyor musun?';
  static const String habitsDeleteYes = 'Evet, Sil';
  static const String habitsDeleteNo = 'Vazgeç';
  static const String habitsEmpty =
      'Henüz alışkanlık eklemedin.\nYeni bir başlangıç yapmaya hazır mısın?';

  // ─── Ayarlar ────────────────────────────────────────────────────────
  static const String settingsPageTitle = 'Ayarlar';
  static const String settingsAppearance = 'Görünüm';
  static const String settingsDarkMode = 'Karanlık Mod';
  static const String settingsNotifications = 'Bildirimler';
  static const String settingsPrayerNotifications = 'Namaz Vakti Bildirimleri';
  static const String settingsHabitReminders = 'Alışkanlık Hatırlatıcıları';
  static const String settingsLocation = 'Konum';
  static const String settingsCity = 'Şehir';
  static const String settingsCountry = 'Ülke';
  static const String settingsAbout = 'Hakkında';
  static const String settingsVersion = 'Versiyon';
  static const String settingsPrivacy = 'Gizlilik Politikası';
  static const String settingsPrivacySubtitle =
      'Verilerinizi nasıl işlediğimiz';
  static const String settingsPrivacyPageTitle = 'Gizlilik Politikası';
  /// Politika içeriği değiştiğinde sürümle birlikte bu tarihi güncelleyin.
  static const String settingsPrivacyLastUpdated = 'Son güncelleme: 26.04.2026';
  static const String settingsPrivacyIntro =
      'Arin gizliliğinize saygı duyar. Bu metin, hangi verilerin işlendiğini, neden işlendiğini ve bu süreçleri nasıl yönetebileceğinizi açıklar.';
  static const String settingsPrivacyDataCollectedTitle = 'İşlenen veriler';
  static const String settingsPrivacyDataCollectedBody =
      'Kullanımınıza ve verdiğiniz izinlere bağlı olarak Arin; namaz vakti ve kıble özellikleri için konum verisi, bildirim tercihleri, giriş yaptığınızda hesap bilgileri ve uygulama tanılama verilerini işleyebilir.';
  static const String settingsPrivacyUsageTitle = 'Verileri neden işliyoruz';
  static const String settingsPrivacyUsageBody =
      'Veriler; namaz vakitlerini hesaplamak, kıble yönünü göstermek, hatırlatıcıları planlamak, ayarlarınızı korumak ve uygulama kararlılığını iyileştirmek amacıyla işlenir.';
  static const String settingsPrivacyStorageTitle = 'Saklama ve süre';
  static const String settingsPrivacyStorageBody =
      'Alışkanlık, zikir ve tercih verilerinin büyük kısmı cihazınızda tutulur. Hesapla giriş yaparsanız seçili veriler Firebase servisleriyle eşitlenebilir. Veriler, uygulama içinden silene veya hesabınızı kaldırana kadar saklanır.';
  static const String settingsPrivacyThirdPartyTitle = 'Üçüncü taraf servisler';
  static const String settingsPrivacyThirdPartyBody =
      'Arin; oturum açma, veri eşitleme, kullanım analizi ve çökme tanılama için Firebase Authentication, Cloud Firestore, Firebase Analytics ve Firebase Crashlytics kullanır.';
  static const String settingsPrivacyControlsTitle = 'Kullanıcı kontrolü';
  static const String settingsPrivacyControlsBody =
      'Konum ve bildirim izinlerini cihaz ayarlarından kapatabilir, Ayarlar ekranından çıkış yapabilir veya hesabınızı ve yerel verilerinizi silebilirsiniz.';
  static const String settingsPrivacyChildrenTitle = 'Çocukların gizliliği';
  static const String settingsPrivacyChildrenBody =
      'Arin, 13 yaş altı çocuklara yönelik olarak tasarlanmamıştır.';
  static const String settingsPrivacyContactTitle = 'İletişim';
  static const String settingsPrivacyContactBody =
      'Gizlilik ile ilgili sorularınız için: arinapphelp@gmail.com';

  // ─── Bildirim merkezi ───────────────────────────────────────────────
  static const String notificationsHubTitle = 'Bildirimler';
  static const String notificationsHubHeadline = 'Hatırlatıcı merkezi';
  static const String notificationsHubSubhead =
      'Namaz, arınma ve zikir — hepsi tek yerden.';
  static const String notificationsHubTagline =
      'Hatırlatmalar büyük ölçüde cihazında planlanır; gereksiz bildirim göndermeyiz.';
  static const String notificationsPermissionGranted = 'İzin verildi';
  static const String notificationsPermissionDenied = 'İzin kapalı';
  static const String notificationsPermissionLimited = 'Kısıtlı';
  static const String notificationsOpenOsSettings = 'Sistem bildirim ayarları';

  /// Zamanlanmış bildirimler için üç ayrı izin ekseni — birinin eksik olması
  /// "manuel çalışıyor, zamanlanan çalışmıyor" sorununun tipik sebebidir.
  static const String notificationsGateNotification = 'Bildirim';
  static const String notificationsGateExactAlarm = 'Tam zamanlayıcı';
  static const String notificationsGateBattery = 'Pil muafiyeti';
  static const String notificationsGateAllGood =
      'Hatırlatıcılar zamanında tetiklenir.';
  static const String notificationsGateMissing =
      'Bir veya daha fazla izin eksik — zamanlanan bildirimler gecikebilir ya da hiç gelmeyebilir.';
  static const String notificationsGateRequestExact =
      'Tam zamanlayıcı iznini aç';
  static const String notificationsGateRequestBattery =
      'Pil optimizasyonunu muaf tut';
  static const String notificationsDiagnosticsQueuedLabel =
      'Kuyruğa alınan zamanlı hatırlatıcı';

  static const String notificationsSectionGeneral = 'Genel';
  static const String notificationsSectionPrayer = 'Namaz vakitleri';
  static const String notificationsSectionArinma = 'Arınma ve alışkanlıklar';
  static const String notificationsSectionInspire = 'İçerik ve ilham';
  static const String notificationsPrayerRowTitle = 'Vakit ve ses';
  static const String notificationsPrayerOnSubtitle =
      'Vakit bildirimleri açık — dokunup düzenle';
  static const String notificationsPrayerOffSubtitle =
      'Vakit bildirimleri kapalı — dokunup açabilirsin';
  static const String notificationsPrayerDetailTitle = 'Namaz bildirimleri';
  static const String notificationsPrayerDetailSubtitle =
      'Her vakit için ayrı süre ve ses; ana anahtar aşağıda.';
  static const String notificationsArinmaDailyTitle = 'Günlük hatırlatıcı';
  static const String notificationsArinmaDailySubtitle =
      'Gün içinde 2 defa rastgele bir söz ya da kısa motivasyon.';
  static const String notificationsMilestoneTitle = 'Milestone bildirimleri';
  static const String notificationsMilestoneSubtitle =
      'Örn. bırakma yolculuğunda 24 saat, 1 hafta gibi seyrek mesajlar.';
  static const String notificationsTaskTitle = 'Görev hatırlatıcısı';
  static const String notificationsTaskSubtitle =
      'Tamamlanmamış görev için günde en fazla bir uyarı.';
  static const String notificationsWeeklyTitle = 'Haftalık özet';
  static const String notificationsWeeklySubtitle =
      'İlham ve ilerleme için haftada bir kısa özet.';
  static const String notificationsDailyWisdomTitle = 'Günün sözü (bildirim)';
  static const String notificationsDailyWisdomSubtitle =
      'Ana sayfadaki havuzdan hadis / âyet / söz; gün içinde rastgele saatte (vakitten ayrı).';
  static const String notificationsZikirTitle = 'Zikir hatırlatıcısı';
  static const String notificationsZikirSubtitle =
      'Seçtiğin saatte, son zikirindeki metinle kısa bir hatırlatma.';
  static const String notificationsZikirTimeLabel = 'Zikir saati';
  static const String notificationsZikirTimePickerTitle = 'Zikir saati';
  static const String notificationsZikirTimePickerSubtitle =
      'Her gün bu saatte son zikir metninle hatırlatma.';
  static const String notificationsHealthDisclaimer =
      'Sağlık ve arınma ile ilgili metinler genel bilgilendirme amaçlıdır; '
      'tedavi yerine geçmez. Rahatsızlığınız varsa doktorunuza danışın.';

  /// Yerel uygulama bildirim kanalları (açıklama metni).
  static const String appNtfChannelDesc =
      'Arınma, görev ve içerik hatırlatıcıları';
  static const String appNtfDailyArinmaTitle = 'Arınma hatırlatıcısı';
  static const String appNtfDailyWisdomTitle = 'Günün sözü';
  static const String appNtfMilestoneTitle = 'Yolculuğun';
  static const String appNtfMilestoneBody =
      'Alışkanlıklarına ve başarılarına göz atmayı unutma.';
  static const String appNtfTaskTitle = 'Görevler';
  static const String appNtfTaskBody = 'Bugünkü adımlarını tamamladın mı?';
  static const String appNtfWeeklyInspireTitle = 'Haftalık ilham';
  static const String appNtfWeeklyInspireBody =
      'Bu haftanın ilhamı için uygulamaya göz at.';
  static const String appNtfZikirTitle = 'Zikir';
  static const String appNtfZikirBodyFallback =
      'Zikir etmek için kısa bir mola.';

  // ─── Namaz Vakitleri ────────────────────────────────────────────────
  static const String prayerFajr = 'İmsak';
  static const String prayerSunrise = 'Güneş';
  static const String prayerDhuhr = 'Öğle';
  static const String prayerAsr = 'İkindi';
  static const String prayerMaghrib = 'Akşam';
  static const String prayerIsha = 'Yatsı';

  // ─── Genel ──────────────────────────────────────────────────────────
  static const String generalCancel = 'İptal';
  static const String generalOk = 'Tamam';
  static const String generalSave = 'Kaydet';
  static const String generalDelete = 'Sil';
  static const String generalEdit = 'Düzenle';
  static const String generalBack = 'Geri';
  static const String generalLoading = 'Yükleniyor...';
  static const String generalError = 'Bir hata oluştu.';
  static const String generalRetry = 'Tekrar Dene';
  static const String generalNoInternet = 'İnternet bağlantısı yok.';
}
