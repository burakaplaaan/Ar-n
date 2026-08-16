// lib/presentation/onboarding/app_tour/app_tour_step.dart

import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import 'app_tour_keys.dart';

class AppTourStep {
  const AppTourStep({
    required this.route,
    required this.title,
    required this.body,
    this.id,
    this.scroll = true,
    this.finale = false,
  });

  final AppTourTargetId? id;
  final String route;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) body;
  final bool scroll;
  final bool finale;
}

abstract final class AppTourCatalog {
  static const List<AppTourStep> steps = [
    AppTourStep(
      id: AppTourTargetId.homeHeader,
      route: AppRoutes.home,
      title: _homeHeaderTitle,
      body: _homeHeaderBody,
    ),
    AppTourStep(
      id: AppTourTargetId.homeWisdom,
      route: AppRoutes.home,
      title: _homeWisdomTitle,
      body: _homeWisdomBody,
    ),
    AppTourStep(
      id: AppTourTargetId.homeNamaz,
      route: AppRoutes.home,
      title: _homeNamazTitle,
      body: _homeNamazBody,
    ),
    AppTourStep(
      id: AppTourTargetId.homePrayerTimes,
      route: AppRoutes.home,
      title: _homePrayerTimesTitle,
      body: _homePrayerTimesBody,
    ),
    AppTourStep(
      id: AppTourTargetId.navTools,
      route: AppRoutes.home,
      title: _navToolsTitle,
      body: _navToolsBody,
      scroll: false,
    ),
    AppTourStep(
      id: AppTourTargetId.qiblaAi,
      route: AppRoutes.qibla,
      title: _qiblaAiTitle,
      body: _qiblaAiBody,
    ),
    AppTourStep(
      id: AppTourTargetId.qiblaCompass,
      route: AppRoutes.qibla,
      title: _qiblaCompassTitle,
      body: _qiblaCompassBody,
    ),
    AppTourStep(
      id: AppTourTargetId.qiblaZikir,
      route: AppRoutes.qibla,
      title: _qiblaZikirTitle,
      body: _qiblaZikirBody,
    ),
    AppTourStep(
      id: AppTourTargetId.qiblaHilal,
      route: AppRoutes.qibla,
      title: _qiblaHilalTitle,
      body: _qiblaHilalBody,
    ),
    AppTourStep(
      id: AppTourTargetId.qiblaPrayerCircle,
      route: AppRoutes.qibla,
      title: _qiblaPrayerCircleTitle,
      body: _qiblaPrayerCircleBody,
    ),
    AppTourStep(
      id: AppTourTargetId.qiblaHealing,
      route: AppRoutes.qibla,
      title: _qiblaHealingTitle,
      body: _qiblaHealingBody,
    ),
    AppTourStep(
      id: AppTourTargetId.qiblaBreathing,
      route: AppRoutes.qibla,
      title: _qiblaBreathingTitle,
      body: _qiblaBreathingBody,
    ),
    AppTourStep(
      id: AppTourTargetId.navWillpower,
      route: AppRoutes.qibla,
      title: _navWillpowerTitle,
      body: _navWillpowerBody,
      scroll: false,
    ),
    AppTourStep(
      id: AppTourTargetId.willpowerTabs,
      route: AppRoutes.habits,
      title: _willpowerTabsTitle,
      body: _willpowerTabsBody,
      scroll: false,
    ),
    AppTourStep(
      id: AppTourTargetId.willpowerBreathing,
      route: AppRoutes.habits,
      title: _willpowerBreathingTitle,
      body: _willpowerBreathingBody,
    ),
    AppTourStep(
      id: AppTourTargetId.willpowerAdd,
      route: AppRoutes.habits,
      title: _willpowerAddTitle,
      body: _willpowerAddBody,
      scroll: false,
    ),
    AppTourStep(
      id: AppTourTargetId.navExplore,
      route: AppRoutes.habits,
      title: _navExploreTitle,
      body: _navExploreBody,
      scroll: false,
    ),
    AppTourStep(
      id: AppTourTargetId.inspireSearch,
      route: AppRoutes.inspire,
      title: _inspireSearchTitle,
      body: _inspireSearchBody,
    ),
    AppTourStep(
      id: AppTourTargetId.inspireFilter,
      route: AppRoutes.inspire,
      title: _inspireFilterTitle,
      body: _inspireFilterBody,
    ),
    AppTourStep(
      id: AppTourTargetId.navSettings,
      route: AppRoutes.inspire,
      title: _navSettingsTitle,
      body: _navSettingsBody,
      scroll: false,
    ),
    AppTourStep(
      id: AppTourTargetId.settingsNotifications,
      route: AppRoutes.settings,
      title: _settingsNotificationsTitle,
      body: _settingsNotificationsBody,
    ),
    AppTourStep(
      id: AppTourTargetId.settingsWidgets,
      route: AppRoutes.settings,
      title: _settingsWidgetsTitle,
      body: _settingsWidgetsBody,
    ),
    AppTourStep(
      id: AppTourTargetId.settingsLanguage,
      route: AppRoutes.settings,
      title: _settingsLanguageTitle,
      body: _settingsLanguageBody,
    ),
    AppTourStep(
      id: AppTourTargetId.assistantFab,
      route: AppRoutes.home,
      title: _assistantFabTitle,
      body: _assistantFabBody,
      scroll: false,
    ),
    AppTourStep(
      route: AppRoutes.home,
      title: _finaleTitle,
      body: _finaleBody,
      scroll: false,
      finale: true,
    ),
  ];

  static String _homeHeaderTitle(AppLocalizations l) =>
      l.appTourHomeHeaderTitle;
  static String _homeHeaderBody(AppLocalizations l) => l.appTourHomeHeaderBody;
  static String _homeWisdomTitle(AppLocalizations l) =>
      l.appTourHomeWisdomTitle;
  static String _homeWisdomBody(AppLocalizations l) => l.appTourHomeWisdomBody;
  static String _homeNamazTitle(AppLocalizations l) => l.appTourHomeNamazTitle;
  static String _homeNamazBody(AppLocalizations l) => l.appTourHomeNamazBody;
  static String _homePrayerTimesTitle(AppLocalizations l) =>
      l.appTourHomePrayerTimesTitle;
  static String _homePrayerTimesBody(AppLocalizations l) =>
      l.appTourHomePrayerTimesBody;
  static String _navToolsTitle(AppLocalizations l) => l.appTourNavToolsTitle;
  static String _navToolsBody(AppLocalizations l) => l.appTourNavToolsBody;
  static String _qiblaAiTitle(AppLocalizations l) => l.appTourQiblaAiTitle;
  static String _qiblaAiBody(AppLocalizations l) => l.appTourQiblaAiBody;
  static String _qiblaCompassTitle(AppLocalizations l) =>
      l.appTourQiblaCompassTitle;
  static String _qiblaCompassBody(AppLocalizations l) =>
      l.appTourQiblaCompassBody;
  static String _qiblaZikirTitle(AppLocalizations l) =>
      l.appTourQiblaZikirTitle;
  static String _qiblaZikirBody(AppLocalizations l) => l.appTourQiblaZikirBody;
  static String _qiblaHilalTitle(AppLocalizations l) =>
      l.appTourQiblaHilalTitle;
  static String _qiblaHilalBody(AppLocalizations l) => l.appTourQiblaHilalBody;
  static String _qiblaPrayerCircleTitle(AppLocalizations l) =>
      l.appTourQiblaPrayerCircleTitle;
  static String _qiblaPrayerCircleBody(AppLocalizations l) =>
      l.appTourQiblaPrayerCircleBody;
  static String _qiblaHealingTitle(AppLocalizations l) =>
      l.appTourQiblaHealingTitle;
  static String _qiblaHealingBody(AppLocalizations l) =>
      l.appTourQiblaHealingBody;
  static String _qiblaBreathingTitle(AppLocalizations l) =>
      l.appTourQiblaBreathingTitle;
  static String _qiblaBreathingBody(AppLocalizations l) =>
      l.appTourQiblaBreathingBody;
  static String _navWillpowerTitle(AppLocalizations l) =>
      l.appTourNavWillpowerTitle;
  static String _navWillpowerBody(AppLocalizations l) =>
      l.appTourNavWillpowerBody;
  static String _willpowerTabsTitle(AppLocalizations l) =>
      l.appTourWillpowerTabsTitle;
  static String _willpowerTabsBody(AppLocalizations l) =>
      l.appTourWillpowerTabsBody;
  static String _willpowerBreathingTitle(AppLocalizations l) =>
      l.appTourWillpowerBreathingTitle;
  static String _willpowerBreathingBody(AppLocalizations l) =>
      l.appTourWillpowerBreathingBody;
  static String _willpowerAddTitle(AppLocalizations l) =>
      l.appTourWillpowerAddTitle;
  static String _willpowerAddBody(AppLocalizations l) =>
      l.appTourWillpowerAddBody;
  static String _navExploreTitle(AppLocalizations l) =>
      l.appTourNavExploreTitle;
  static String _navExploreBody(AppLocalizations l) => l.appTourNavExploreBody;
  static String _inspireSearchTitle(AppLocalizations l) =>
      l.appTourInspireSearchTitle;
  static String _inspireSearchBody(AppLocalizations l) =>
      l.appTourInspireSearchBody;
  static String _inspireFilterTitle(AppLocalizations l) =>
      l.appTourInspireFilterTitle;
  static String _inspireFilterBody(AppLocalizations l) =>
      l.appTourInspireFilterBody;
  static String _navSettingsTitle(AppLocalizations l) =>
      l.appTourNavSettingsTitle;
  static String _navSettingsBody(AppLocalizations l) =>
      l.appTourNavSettingsBody;
  static String _settingsNotificationsTitle(AppLocalizations l) =>
      l.appTourSettingsNotificationsTitle;
  static String _settingsNotificationsBody(AppLocalizations l) =>
      l.appTourSettingsNotificationsBody;
  static String _settingsWidgetsTitle(AppLocalizations l) =>
      l.appTourSettingsWidgetsTitle;
  static String _settingsWidgetsBody(AppLocalizations l) =>
      l.appTourSettingsWidgetsBody;
  static String _settingsLanguageTitle(AppLocalizations l) =>
      l.appTourSettingsLanguageTitle;
  static String _settingsLanguageBody(AppLocalizations l) =>
      l.appTourSettingsLanguageBody;
  static String _assistantFabTitle(AppLocalizations l) =>
      l.appTourAssistantFabTitle;
  static String _assistantFabBody(AppLocalizations l) =>
      l.appTourAssistantFabBody;
  static String _finaleTitle(AppLocalizations l) => l.appTourFinaleTitle;
  static String _finaleBody(AppLocalizations l) => l.appTourFinaleBody;
}
