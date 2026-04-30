// Firestore `quote_pools/{poolId}` belge kimlikleri — tek kaynak.

abstract final class QuotePoolIds {
  static const String homeNamazWisdom = 'home_namaz_wisdom';
  static const String personalizedQuotes = 'personalized_quotes';
  static const String widgetQuote = 'widget_quote';
  static const String zikirDailyReflections = 'zikir_daily_reflections';
  static const String healingComfort = 'healing_comfort';
  static const String hubGelisimIslamic = 'hub_gelisim_islamic';
  static const String hubGelisimMedical = 'hub_gelisim_medical';
  static const String hubArinmaIslamic = 'hub_arinma_islamic';
  static const String hubArinmaMedical = 'hub_arinma_medical';
  static const String notificationArinmaBodies = 'notification_arinma_bodies';

  static const List<String> all = [
    homeNamazWisdom,
    personalizedQuotes,
    widgetQuote,
    zikirDailyReflections,
    healingComfort,
    hubGelisimIslamic,
    hubGelisimMedical,
    hubArinmaIslamic,
    hubArinmaMedical,
    notificationArinmaBodies,
  ];

  /// Ayarlar → İçerik yönetimi açılır listesi için Türkçe ad (teknik kimlik ayrı gösterilir).
  static String labelTr(String poolId) {
    switch (poolId) {
      case homeNamazWisdom:
        return 'Ana sayfa namaz kartı';
      case personalizedQuotes:
        return 'Kişiselleştirilmiş sözler';
      case widgetQuote:
        return 'Widget / ana ekran sözü';
      case zikirDailyReflections:
        return 'Namaz vakit kartı (zikir yansıması)';
      case healingComfort:
        return 'İyileşme / teselli sözleri';
      case hubGelisimIslamic:
        return 'Gelişim — İslami kart';
      case hubGelisimMedical:
        return 'Gelişim — sağlık kartı';
      case hubArinmaIslamic:
        return 'Arınma — İslami kart';
      case hubArinmaMedical:
        return 'Arınma — sağlık kartı';
      case notificationArinmaBodies:
        return 'Arınma bildirimi metinleri';
      default:
        return poolId;
    }
  }
}
