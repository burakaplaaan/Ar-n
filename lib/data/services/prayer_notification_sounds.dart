// Namaz bildirimi ses seçenekleri — Android raw + iOS bundle + önizleme asset yolu.
// Kaynak: Freesound CC0 önizleme MP3’lerinden kırpılmış WAV (tool/audio_trim).

/// Tek seçenek: kanal kimliği (Android O+), ham kaynak adı, iOS dosya adı, önizleme.
class PrayerNtfSoundOption {
  const PrayerNtfSoundOption({
    required this.channelId,
    required this.titleKey,
    required this.channelName,
    this.androidRawBaseName,
    this.iosWavFileName,
    this.previewAssetRelativePath,
  });

  final String channelId;
  final String titleKey;
  final String channelName;

  /// `res/raw/prayer_ntf_xxx.wav` → `prayer_ntf_xxx` (uzantısız).
  final String? androidRawBaseName;

  final String? iosWavFileName;

  /// [AssetSource] için: `assets/` önefsiz.
  final String? previewAssetRelativePath;
}

abstract final class PrayerNotificationSounds {
  static const int systemSoundIndex = 0;

  /// Hiç tercih yokken kullanılacak ses: telefonun varsayılan bildirimi.
  /// Ezan / Arın sesleri kullanıcı özellikle seçerse çalar.
  static const int defaultCatalogSoundIndex = systemSoundIndex;

  /// Kanal kimliği sürümü — Android O+ kanalları ses için değiştirilemez; sürüm
  /// artırıldığında yeni kanal oluşur. [PrayerNotificationScheduler.init] eski
  /// v4–v6 kanallarını siler.
  static const List<PrayerNtfSoundOption> options = [
    PrayerNtfSoundOption(
      channelId: 'arin_ntf_s0',
      titleKey: 'system',
      channelName: 'Phone default notification sound',
    ),
    PrayerNtfSoundOption(
      channelId: 'arin_ntf_s1_v7',
      titleKey: 'adhanTurkish',
      channelName: 'Adhan Turkish tone',
      androidRawBaseName: 'prayer_ntf_adhan_turkish',
      iosWavFileName: 'prayer_ntf_adhan_turkish.wav',
      previewAssetRelativePath: 'sounds/prayer/prayer_ntf_adhan_turkish.wav',
    ),
    PrayerNtfSoundOption(
      channelId: 'arin_ntf_s2_v7',
      titleKey: 'adhanDubai',
      channelName: 'Adhan Dubai tone',
      androidRawBaseName: 'prayer_ntf_adhan_dubai',
      iosWavFileName: 'prayer_ntf_adhan_dubai.wav',
      previewAssetRelativePath: 'sounds/prayer/prayer_ntf_adhan_dubai.wav',
    ),
    PrayerNtfSoundOption(
      channelId: 'arin_ntf_s3_v7',
      titleKey: 'ambientFlute',
      channelName: 'Ambient flute tone',
      androidRawBaseName: 'prayer_ntf_ambient_flute',
      iosWavFileName: 'prayer_ntf_ambient_flute.wav',
      previewAssetRelativePath: 'sounds/prayer/prayer_ntf_ambient_flute.wav',
    ),
    PrayerNtfSoundOption(
      channelId: 'arin_ntf_s4_v7',
      titleKey: 'ambientPianoGuitar',
      channelName: 'Ambient piano guitar tone',
      androidRawBaseName: 'prayer_ntf_ambient_piano_guitar',
      iosWavFileName: 'prayer_ntf_ambient_piano_guitar.wav',
      previewAssetRelativePath:
          'sounds/prayer/prayer_ntf_ambient_piano_guitar.wav',
    ),
    PrayerNtfSoundOption(
      channelId: 'arin_ntf_s5_v7',
      titleKey: 'ambientEthereal',
      channelName: 'Ambient ethereal tone',
      androidRawBaseName: 'prayer_ntf_ambient_ethereal',
      iosWavFileName: 'prayer_ntf_ambient_ethereal.wav',
      previewAssetRelativePath: 'sounds/prayer/prayer_ntf_ambient_ethereal.wav',
    ),
  ];

  static PrayerNtfSoundOption optionForIndex(int index) {
    if (index < 0 || index >= options.length) {
      return options[systemSoundIndex];
    }
    return options[index];
  }

  static String localizedChannelName(
    PrayerNtfSoundOption option,
    String localeCode,
  ) {
    switch (option.titleKey) {
      case 'system':
        return localeCode == 'ar'
            ? 'الصوت الافتراضي للهاتف'
            : (localeCode == 'en' ? 'Phone default sound' : 'Telefonun varsayılan sesi');
      case 'adhanTurkish':
        return localeCode == 'ar'
            ? 'أذان تركي'
            : (localeCode == 'en' ? 'Adhan Turkish' : 'Ezan Türkçe');
      case 'adhanDubai':
        return localeCode == 'ar'
            ? 'أذان دبي'
            : (localeCode == 'en' ? 'Adhan Dubai' : 'Ezan Dubai');
      case 'ambientFlute':
        return localeCode == 'ar'
            ? 'هدوء فلوت'
            : (localeCode == 'en' ? 'Calm flute' : 'Huzur flute');
      case 'ambientPianoGuitar':
        return localeCode == 'ar'
            ? 'هدوء بيانو وغيتار'
            : (localeCode == 'en' ? 'Calm piano guitar' : 'Huzur piyano gitar');
      case 'ambientEthereal':
        return localeCode == 'ar'
            ? 'هدوء حالِم'
            : (localeCode == 'en' ? 'Calm ethereal' : 'Huzur ethereal');
      default:
        return option.channelName;
    }
  }
}
