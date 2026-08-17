// Şablon kimlikleri — Hive HabitModel.templateId ile eşleşir.

abstract final class WillpowerTemplates {
  static const String quranDaily = 'quran_daily';
  static const String quitSmoking = 'quit_smoking';
  static const String salatDaily = 'salat_daily';

  /// Otomatik kurulumda boş niyet yüzünden onboarding'e düşülmesin.
  static const String defaultSalatCommitment =
      'Beş vakit namazı takip edeceğim.';

  static const String salatVisibleOnHomePrefKey =
      'salat_tracking_visible_on_home';
  static const String salatPreinstalledPrefKey =
      'salat_tracking_preinstalled_v1';

  /// Özel sayaç / süre / yüzde alışkanlığı (Gelişim veya Arınma).
  static const String customTracked = 'custom_tracked';

  /// Arınma — tam program (onboarding + ana sayfa + sayaç).
  static const String quitScreen = 'quit_screen';
  static const String quitAlcohol = 'quit_alcohol';
  static const String quitSubstance = 'quit_substance';
  static const String quitZina = 'quit_zina';

  /// Özel hedef (`custom` / boş templateId) dahil değildir.
  static const Set<String> fullQuitProgramTemplateIds = {
    quitSmoking,
    quitScreen,
    quitAlcohol,
    quitSubstance,
    quitZina,
  };

  static bool isFullQuitProgram(String? templateId) =>
      templateId != null && fullQuitProgramTemplateIds.contains(templateId);
}
