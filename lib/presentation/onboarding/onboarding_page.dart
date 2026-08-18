// lib/presentation/onboarding/onboarding_page.dart
// İlk açılış: karşılama + widget tanıtımı, ardından 4 slayt.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/analytics/meta_app_events.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/profile_prefs_keys.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/arin_local_notifications_plugin.dart';
import '../../data/services/fcm_token_service.dart';
import '../../data/services/local_notification_permission_gate.dart';
import '../../data/services/feature_permission_gate.dart';
import '../../data/services/location_service.dart';
import '../../data/services/startup_permission_policy.dart';
import '../shared/providers/user_profile_providers.dart';
import '../shared/widgets/arin_top_toast.dart';
import '../shared/widgets/arin_pressable.dart';
import 'onboarding_choice_screen.dart';
import 'onboarding_dua_screen.dart';
import 'onboarding_entry_screens.dart';
import 'onboarding_heart_screen.dart';
import 'onboarding_info_screen.dart';
import 'onboarding_prepare_screen.dart';
import 'onboarding_name_screen.dart';
import 'onboarding_story_screen.dart';
import 'onboarding_struggle_copy.dart';
import 'onboarding_struggle_note_screen.dart';
import 'onboarding_tone_screen.dart';
import 'onboarding_verse_hold_screen.dart';

enum _OnboardingPhase {
  landing,
  welcome,
  story,
  name,
  greeting,
  intent,
  heart,
  verseHold,
  struggle,
  note,
  tone,
  turn,
  shape,
  prayer,
  waswasa,
  pathVerse,
  path,
  rhythm,
  location,
  prepare,
  dua,
  slides,
}

class _SlideData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final GlobalKey<OnboardingStruggleNoteScreenState> _noteKey =
      GlobalKey<OnboardingStruggleNoteScreenState>();
  int _currentPage = 0;
  _OnboardingPhase _phase = _OnboardingPhase.landing;
  bool _goingForward = true;
  String _displayName = '';
  String? _intentId;
  int _heartPercent = 58;
  String? _struggleId;
  String _struggleNote = '';
  int _toneLevel = 3;
  String? _turnId;
  String? _prayerId;
  String? _waswasaId;
  bool _prepareReady = false;
  bool _finishing = false;
  bool _permissionBusy = false;

  static const _phaseSlideDuration = Duration(milliseconds: 380);

  void _goTo(_OnboardingPhase phase, {required bool forward}) {
    if (_phase == phase) return;
    setState(() {
      _goingForward = forward;
      _phase = phase;
    });
  }

  bool get _isLastPage => _currentPage == 3;

  void _nextPage() {
    if (_isLastPage) {
      context.go(AppRoutes.onboardingSurvey);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skip() => context.go(AppRoutes.onboardingSurvey);

  bool _handleBack() {
    switch (_phase) {
      case _OnboardingPhase.landing:
        return false;
      case _OnboardingPhase.welcome:
        _goTo(_OnboardingPhase.landing, forward: false);
        return true;
      case _OnboardingPhase.story:
        _goTo(_OnboardingPhase.welcome, forward: false);
        return true;
      case _OnboardingPhase.name:
        _goTo(_OnboardingPhase.story, forward: false);
        return true;
      case _OnboardingPhase.greeting:
        _goTo(_OnboardingPhase.name, forward: false);
        return true;
      case _OnboardingPhase.intent:
        _goTo(_OnboardingPhase.greeting, forward: false);
        return true;
      case _OnboardingPhase.heart:
        _goTo(_OnboardingPhase.intent, forward: false);
        return true;
      case _OnboardingPhase.verseHold:
        _goTo(_OnboardingPhase.heart, forward: false);
        return true;
      case _OnboardingPhase.struggle:
        _goTo(_OnboardingPhase.verseHold, forward: false);
        return true;
      case _OnboardingPhase.note:
        if (_noteKey.currentState?.consumeBack() ?? false) return true;
        _goTo(_OnboardingPhase.struggle, forward: false);
        return true;
      case _OnboardingPhase.tone:
        _goTo(_OnboardingPhase.note, forward: false);
        return true;
      case _OnboardingPhase.turn:
        _goTo(_OnboardingPhase.tone, forward: false);
        return true;
      case _OnboardingPhase.shape:
        _goTo(_OnboardingPhase.turn, forward: false);
        return true;
      case _OnboardingPhase.prayer:
        _goTo(_OnboardingPhase.shape, forward: false);
        return true;
      case _OnboardingPhase.waswasa:
        _goTo(_OnboardingPhase.prayer, forward: false);
        return true;
      case _OnboardingPhase.pathVerse:
        _goTo(_OnboardingPhase.waswasa, forward: false);
        return true;
      case _OnboardingPhase.path:
        _goTo(_OnboardingPhase.pathVerse, forward: false);
        return true;
      case _OnboardingPhase.rhythm:
        _goTo(_OnboardingPhase.path, forward: false);
        return true;
      case _OnboardingPhase.location:
        _goTo(_OnboardingPhase.rhythm, forward: false);
        return true;
      case _OnboardingPhase.prepare:
        _goTo(_OnboardingPhase.location, forward: false);
        return true;
      case _OnboardingPhase.dua:
        _goTo(_OnboardingPhase.prepare, forward: false);
        return true;
      case _OnboardingPhase.slides:
        if (_currentPage > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
          );
          return true;
        }
        _goTo(_OnboardingPhase.rhythm, forward: false);
        return true;
    }
  }

  Future<void> _onNameEntered(String name) async {
    _displayName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kOnboardingDisplayNameKey, name);
    if (!mounted) return;
    _goTo(_OnboardingPhase.greeting, forward: true);
  }

  Future<void> _persistChoice(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _persistFlag(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _requestNotificationsThenContinue() async {
    if (_permissionBusy) return;
    _permissionBusy = true;
    try {
      await requestLocalNotificationRuntimePermissions(
        arinLocalNotificationsPlugin,
        policy: LocalNotificationPermissionPolicy.notificationOnly,
      );
      await FcmTokenService.markBroadcastPermissionPromptHandled();
      await FcmTokenService.resumeBroadcastSubscriptionIfAuthorized();
    } catch (_) {
      await FcmTokenService.markBroadcastPermissionPromptHandled();
    } finally {
      _permissionBusy = false;
    }
    if (!mounted) return;
    _goTo(_OnboardingPhase.location, forward: true);
  }

  Future<void> _requestLocationThenContinue() async {
    if (_permissionBusy) return;
    _permissionBusy = true;
    try {
      final location = LocationService();
      final permission = await location.requestSystemLocationPermission();
      if (locationPermissionGranted(permission)) {
        unawaited(
          location.requestCurrentPosition(
            showDisclosure: false,
            promptIfNeeded: false,
          ),
        );
      }
    } catch (_) {
      // İzin reddedilse bile kurulum devam eder; özellik kullanırken tekrar istenir.
    } finally {
      _permissionBusy = false;
    }
    if (!mounted) return;
    _goTo(_OnboardingPhase.prepare, forward: true);
  }

  void _onPrepareAnswer(OnboardingPrepareQuestion question, bool yes) {
    switch (question) {
      case OnboardingPrepareQuestion.lock:
        unawaited(_persistFlag(kOnboardingLockVerseSimpleKey, yes));
      case OnboardingPrepareQuestion.verses:
        unawaited(_persistFlag(kOnboardingPrioritizeVersesKey, yes));
      case OnboardingPrepareQuestion.shortcuts:
        unawaited(_persistFlag(kOnboardingShortcutsPromoteKey, yes));
    }
  }

  Future<void> _finishToTour() async {
    if (_finishing || !mounted) return;
    _finishing = true;
    final l10n = AppLocalizations.of(context)!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = _displayName.trim().isNotEmpty
          ? _displayName.trim()
          : (prefs.getString(kOnboardingDisplayNameKey)?.trim() ?? '');
      await prefs.setBool(profileNameLockedByUserKey, name.isNotEmpty);
      await prefs.setBool(kAppTourPendingKey, true);
      await prefs.setBool(kAppTourCompletedKey, false);
      await FcmTokenService.markBroadcastPermissionPromptHandled();
      if (!mounted) return;
      final container = ProviderScope.containerOf(context);
      await container
          .read(userProfileProvider.notifier)
          .saveProfile(
            name: name.isEmpty ? null : name,
            gender: null,
            moodTags: const [],
            sectorTags: const [],
            needTags: const [],
          );
      await prefs.setBool('onboarding_completed', true);
      unawaited(ArinAnalytics.log('onboarding_complete'));
      if (!mounted) return;
      context.go(AppRoutes.appPrepare);
    } catch (e) {
      _finishing = false;
      if (!mounted) return;
      showArinTopToast(
        context,
        l10n.surveySummarySaveError,
        duration: const Duration(seconds: 3),
      );
    }
  }

  List<OnboardingChoiceOption> _intentOptions(AppLocalizations l10n) {
    return [
      OnboardingChoiceOption(
        id: 'lock',
        label: l10n.onboardingIntentLock,
        icon: Icons.lock_rounded,
      ),
      OnboardingChoiceOption(
        id: 'faith',
        label: l10n.onboardingIntentFaith,
        icon: Icons.favorite_rounded,
      ),
      OnboardingChoiceOption(
        id: 'calm',
        label: l10n.onboardingIntentCalm,
        icon: Icons.spa_rounded,
      ),
      OnboardingChoiceOption(
        id: 'daily',
        label: l10n.onboardingIntentDaily,
        icon: Icons.wb_twilight_rounded,
      ),
      OnboardingChoiceOption(
        id: 'prayer',
        label: l10n.onboardingIntentPrayer,
        icon: Icons.schedule_rounded,
      ),
    ];
  }

  List<OnboardingChoiceOption> _struggleOptions(AppLocalizations l10n) {
    return [
      OnboardingChoiceOption(
        id: 'anxiety',
        label: l10n.onboardingStruggleAnxiety,
        icon: Icons.air_rounded,
      ),
      OnboardingChoiceOption(
        id: 'delay',
        label: l10n.onboardingStruggleDelay,
        icon: Icons.hourglass_bottom_rounded,
      ),
      OnboardingChoiceOption(
        id: 'lonely',
        label: l10n.onboardingStruggleLonely,
        icon: Icons.person_outline_rounded,
      ),
      OnboardingChoiceOption(
        id: 'impatience',
        label: l10n.onboardingStruggleImpatience,
        icon: Icons.local_fire_department_rounded,
      ),
      OnboardingChoiceOption(
        id: 'regret',
        label: l10n.onboardingStruggleRegret,
        icon: Icons.replay_rounded,
      ),
    ];
  }

  List<OnboardingChoiceOption> _turnOptions(AppLocalizations l10n) {
    return [
      OnboardingChoiceOption(
        id: 'always',
        label: l10n.onboardingTurnAlways,
        icon: Icons.volunteer_activism_rounded,
      ),
      OnboardingChoiceOption(
        id: 'sometimes',
        label: l10n.onboardingTurnSometimes,
        icon: Icons.self_improvement_rounded,
      ),
      OnboardingChoiceOption(
        id: 'rarely',
        label: l10n.onboardingTurnRarely,
        icon: Icons.auto_awesome_rounded,
      ),
      OnboardingChoiceOption(
        id: 'starting',
        label: l10n.onboardingTurnStarting,
        icon: Icons.eco_rounded,
      ),
    ];
  }

  List<OnboardingChoiceOption> _prayerOptions(AppLocalizations l10n) {
    return [
      OnboardingChoiceOption(
        id: 'regular',
        label: l10n.onboardingPrayerRegular,
        icon: Icons.check_circle_rounded,
      ),
      OnboardingChoiceOption(
        id: 'occasional',
        label: l10n.onboardingPrayerOccasional,
        icon: Icons.schedule_rounded,
      ),
      OnboardingChoiceOption(
        id: 'struggling',
        label: l10n.onboardingPrayerStruggling,
        icon: Icons.favorite_border_rounded,
      ),
      OnboardingChoiceOption(
        id: 'starting',
        label: l10n.onboardingPrayerStarting,
        icon: Icons.spa_rounded,
      ),
      OnboardingChoiceOption(
        id: 'begin_here',
        label: l10n.onboardingPrayerBeginHere,
        icon: Icons.play_circle_outline_rounded,
      ),
    ];
  }

  List<OnboardingChoiceOption> _waswasaOptions(AppLocalizations l10n) {
    return [
      OnboardingChoiceOption(
        id: 'pray',
        label: l10n.onboardingWaswasaPray,
        icon: Icons.volunteer_activism_rounded,
      ),
      OnboardingChoiceOption(
        id: 'read',
        label: l10n.onboardingWaswasaRead,
        icon: Icons.menu_book_rounded,
      ),
      OnboardingChoiceOption(
        id: 'ask',
        label: l10n.onboardingWaswasaAsk,
        icon: Icons.chat_bubble_outline_rounded,
      ),
      OnboardingChoiceOption(
        id: 'carry',
        label: l10n.onboardingWaswasaCarry,
        icon: Icons.nightlight_round,
      ),
    ];
  }

  OnboardingChoiceScreen _autoChoice({
    required String title,
    required String subtitle,
    required List<OnboardingChoiceOption> options,
    required double progress,
    required String? initialId,
    required ValueChanged<String> onContinue,
  }) {
    return OnboardingChoiceScreen(
      title: title,
      subtitle: subtitle,
      options: options,
      progress: progress,
      initialId: initialId,
      autoAdvance: true,
      centered: true,
      onBack: () {
        _handleBack();
      },
      onContinue: onContinue,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: _phaseSlideDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return _OnboardingPhaseSlide(
              animation: animation,
              forward: _goingForward,
              incoming: child.key == ValueKey(_phase),
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_phase),
            child: _buildPhase(context, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context, AppLocalizations l10n) {
    return switch (_phase) {
      _OnboardingPhase.landing => Scaffold(
        body: OnboardingLandingScreen(
          onStart: () => _goTo(_OnboardingPhase.welcome, forward: true),
        ),
      ),
      _OnboardingPhase.welcome => Scaffold(
        body: OnboardingWelcomeScreen(
          onContinue: () => _goTo(_OnboardingPhase.story, forward: true),
        ),
      ),
      _OnboardingPhase.story => Scaffold(
        body: OnboardingStoryScreen(
          title: l10n.onboardingWelcomeTitle,
          body: l10n.onboardingStoryBody,
          progress: 0.22,
          onBack: () {
            _handleBack();
          },
          onContinue: () => _goTo(_OnboardingPhase.name, forward: true),
        ),
      ),
      _OnboardingPhase.name => Scaffold(
        resizeToAvoidBottomInset: true,
        body: OnboardingNameScreen(
          initialName: _displayName,
          onBack: () {
            _handleBack();
          },
          onContinue: (name) => unawaited(_onNameEntered(name)),
        ),
      ),
      _OnboardingPhase.greeting => Scaffold(
        body: OnboardingStoryScreen(
          title: l10n.onboardingGreetingTitle(_displayName),
          body: l10n.onboardingGreetingBody,
          progress: 0.52,
          typewriterKey: 'onboarding_greeting_typewriter',
          onBack: () {
            _handleBack();
          },
          onContinue: () => _goTo(_OnboardingPhase.intent, forward: true),
        ),
      ),
      _OnboardingPhase.intent => Scaffold(
        body: OnboardingChoiceScreen(
          title: l10n.onboardingIntentTitle(_displayName),
          subtitle: l10n.onboardingIntentSubtitle,
          options: _intentOptions(l10n),
          progress: 0.58,
          initialId: _intentId,
          onBack: () {
            _handleBack();
          },
          onContinue: (id) {
            _intentId = id;
            unawaited(_persistChoice(kOnboardingIntentKey, id));
            _goTo(_OnboardingPhase.heart, forward: true);
          },
        ),
      ),
      _OnboardingPhase.heart => Scaffold(
        body: OnboardingHeartScreen(
          title: l10n.onboardingHeartTitle(_displayName),
          progress: 0.68,
          initialPercent: _heartPercent,
          onBack: () {
            _handleBack();
          },
          onContinue: (percent) async {
            _heartPercent = percent;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(kOnboardingHeartPercentKey, percent);
            if (!mounted) return;
            _goTo(_OnboardingPhase.verseHold, forward: true);
          },
        ),
      ),
      _OnboardingPhase.verseHold => Scaffold(
        body: OnboardingVerseHoldScreen(
          name: _displayName,
          progress: 0.76,
          onBack: () {
            _handleBack();
          },
          onFinished: () {
            if (!mounted) return;
            _goTo(_OnboardingPhase.struggle, forward: true);
          },
        ),
      ),
      _OnboardingPhase.struggle => Scaffold(
        body: OnboardingChoiceScreen(
          title: l10n.onboardingStruggleTitle(_displayName),
          subtitle: l10n.onboardingStruggleSubtitle,
          options: _struggleOptions(l10n),
          progress: 0.78,
          initialId: _struggleId,
          onBack: () {
            _handleBack();
          },
          onContinue: (id) {
            _struggleId = id;
            unawaited(_persistChoice(kOnboardingStruggleKey, id));
            _goTo(_OnboardingPhase.note, forward: true);
          },
        ),
      ),
      _OnboardingPhase.note => Scaffold(
        resizeToAvoidBottomInset: true,
        body: OnboardingStruggleNoteScreen(
          key: _noteKey,
          copy: OnboardingStruggleNoteCopy.resolve(
            l10n: l10n,
            name: _displayName,
            struggleId: _struggleId ?? 'anxiety',
          ),
          progress: 0.86,
          initialNote: _struggleNote,
          onBack: () {
            _handleBack();
          },
          onNoteReady: (note) {
            _struggleNote = note;
            unawaited(_persistChoice(kOnboardingStruggleNoteKey, note));
          },
          onContinue: (note) {
            _struggleNote = note;
            _goTo(_OnboardingPhase.tone, forward: true);
          },
        ),
      ),
      _OnboardingPhase.tone => Scaffold(
        body: OnboardingToneScreen(
          title: l10n.onboardingToneTitle(_displayName),
          progress: 0.70,
          initialLevel: _toneLevel,
          onBack: () {
            _handleBack();
          },
          onContinue: (level) async {
            _toneLevel = level;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(kOnboardingToneLevelKey, level);
            if (!mounted) return;
            _goTo(_OnboardingPhase.turn, forward: true);
          },
        ),
      ),
      _OnboardingPhase.turn => Scaffold(
        body: _autoChoice(
          title: l10n.onboardingTurnTitle(_displayName),
          subtitle: l10n.onboardingTurnSubtitle,
          options: _turnOptions(l10n),
          progress: 0.74,
          initialId: _turnId,
          onContinue: (id) {
            _turnId = id;
            unawaited(_persistChoice(kOnboardingTurnKey, id));
            _goTo(_OnboardingPhase.shape, forward: true);
          },
        ),
      ),
      _OnboardingPhase.shape => Scaffold(
        body: OnboardingInfoScreen(
          title: l10n.onboardingShapeTitle,
          subtitle: l10n.onboardingShapeSubtitle,
          progress: 0.78,
          heroIcon: Icons.auto_awesome_rounded,
          cards: [
            OnboardingInfoCardData(
              icon: Icons.tune_rounded,
              title: l10n.onboardingShapeCard1Title,
              body: l10n.onboardingShapeCard1Body,
            ),
            OnboardingInfoCardData(
              icon: Icons.favorite_rounded,
              title: l10n.onboardingShapeCard2Title,
              body: l10n.onboardingShapeCard2Body,
            ),
            OnboardingInfoCardData(
              icon: Icons.menu_book_rounded,
              title: l10n.onboardingShapeCard3Title,
              body: l10n.onboardingShapeCard3Body,
            ),
          ],
          onBack: () {
            _handleBack();
          },
          onContinue: () => _goTo(_OnboardingPhase.prayer, forward: true),
        ),
      ),
      _OnboardingPhase.prayer => Scaffold(
        body: _autoChoice(
          title: l10n.onboardingPrayerTitle(_displayName),
          subtitle: l10n.onboardingPrayerSubtitle,
          options: _prayerOptions(l10n),
          progress: 0.82,
          initialId: _prayerId,
          onContinue: (id) {
            _prayerId = id;
            unawaited(_persistChoice(kOnboardingPrayerKey, id));
            _goTo(_OnboardingPhase.waswasa, forward: true);
          },
        ),
      ),
      _OnboardingPhase.waswasa => Scaffold(
        body: _autoChoice(
          title: l10n.onboardingWaswasaTitle(_displayName),
          subtitle: l10n.onboardingWaswasaSubtitle,
          options: _waswasaOptions(l10n),
          progress: 0.86,
          initialId: _waswasaId,
          onContinue: (id) {
            _waswasaId = id;
            unawaited(_persistChoice(kOnboardingWaswasaKey, id));
            _goTo(_OnboardingPhase.pathVerse, forward: true);
          },
        ),
      ),
      _OnboardingPhase.pathVerse => Scaffold(
        body: OnboardingVerseHoldScreen(
          name: _displayName,
          progress: 0.89,
          verseArabic: l10n.onboardingPathVerseArabic,
          verseTranslation: l10n.onboardingPathVerseTranslation,
          verseSource: l10n.onboardingPathVerseSource,
          footer: l10n.onboardingPathVerseFooter(_displayName),
          onBack: () {
            _handleBack();
          },
          onFinished: () {
            if (!mounted) return;
            _goTo(_OnboardingPhase.path, forward: true);
          },
        ),
      ),
      _OnboardingPhase.path => Scaffold(
        body: OnboardingInfoScreen(
          title: l10n.onboardingPathTitle,
          subtitle: l10n.onboardingPathSubtitle,
          progress: 0.92,
          heroIcon: Icons.auto_awesome_rounded,
          cards: [
            OnboardingInfoCardData(
              icon: Icons.tune_rounded,
              title: l10n.onboardingPathCard1Title,
              body: l10n.onboardingPathCard1Body,
            ),
            OnboardingInfoCardData(
              icon: Icons.schedule_rounded,
              title: l10n.onboardingPathCard2Title,
              body: l10n.onboardingPathCard2Body,
            ),
            OnboardingInfoCardData(
              icon: Icons.widgets_rounded,
              title: l10n.onboardingPathCard3Title,
              body: l10n.onboardingPathCard3Body,
            ),
          ],
          onBack: () {
            _handleBack();
          },
          onContinue: () => _goTo(_OnboardingPhase.rhythm, forward: true),
        ),
      ),
      _OnboardingPhase.rhythm => Scaffold(
        body: OnboardingInfoScreen(
          title: l10n.onboardingRhythmTitle,
          subtitle: l10n.onboardingRhythmSubtitle,
          progress: 0.9,
          featured: OnboardingInfoCardData(
            icon: Icons.notifications_active_rounded,
            title: l10n.onboardingRhythmFeaturedTitle,
            body: l10n.onboardingRhythmFeaturedBody,
          ),
          cards: [
            OnboardingInfoCardData(
              icon: Icons.notifications_none_rounded,
              title: l10n.onboardingRhythmCard1Title,
              body: l10n.onboardingRhythmCard1Body,
            ),
            OnboardingInfoCardData(
              icon: Icons.lock_rounded,
              title: l10n.onboardingRhythmCard2Title,
              body: l10n.onboardingRhythmCard2Body,
            ),
            OnboardingInfoCardData(
              icon: Icons.favorite_rounded,
              title: l10n.onboardingRhythmCard3Title,
              body: l10n.onboardingRhythmCard3Body,
            ),
          ],
          onBack: () {
            _handleBack();
          },
          onContinue: () => unawaited(_requestNotificationsThenContinue()),
        ),
      ),
      _OnboardingPhase.location => Scaffold(
        body: OnboardingInfoScreen(
          title: l10n.onboardingLocationTitle,
          subtitle: l10n.onboardingLocationSubtitle,
          progress: 0.95,
          featured: OnboardingInfoCardData(
            icon: Icons.location_on_rounded,
            title: l10n.onboardingLocationFeaturedTitle,
            body: l10n.onboardingLocationFeaturedBody,
          ),
          cards: [
            OnboardingInfoCardData(
              icon: Icons.schedule_rounded,
              title: l10n.onboardingLocationCard1Title,
              body: l10n.onboardingLocationCard1Body,
            ),
            OnboardingInfoCardData(
              icon: Icons.explore_rounded,
              title: l10n.onboardingLocationCard2Title,
              body: l10n.onboardingLocationCard2Body,
            ),
            OnboardingInfoCardData(
              icon: Icons.lock_rounded,
              title: l10n.onboardingLocationCard3Title,
              body: l10n.onboardingLocationCard3Body,
            ),
          ],
          onBack: () {
            _handleBack();
          },
          onContinue: () => unawaited(_requestLocationThenContinue()),
        ),
      ),
      _OnboardingPhase.prepare => Scaffold(
        body: OnboardingPrepareScreen(
          name: _displayName,
          startAsReady: _prepareReady,
          onReady: () => _prepareReady = true,
          onRequestAtt: MetaAppEvents.requestTrackingAuthorization,
          onAnswer: _onPrepareAnswer,
          onContinue: () => _goTo(_OnboardingPhase.dua, forward: true),
        ),
      ),
      _OnboardingPhase.dua => Scaffold(
        body: OnboardingDuaScreen(
          name: _displayName,
          onFinished: () => unawaited(_finishToTour()),
        ),
      ),
      _OnboardingPhase.slides => _buildSlides(context, l10n),
    };
  }

  Widget _buildSlides(BuildContext context, AppLocalizations l10n) {
    final slides = [
      _SlideData(
        title: l10n.onboardingSlide1Title,
        subtitle: l10n.onboardingSlide1Subtitle,
        icon: Icons.wb_twilight_rounded,
        accentColor: AppColors.emeraldMid,
      ),
      _SlideData(
        title: l10n.onboardingSlide2Title,
        subtitle: l10n.onboardingSlide2Subtitle,
        icon: Icons.trending_up_rounded,
        accentColor: AppColors.emeraldDark,
      ),
      _SlideData(
        title: l10n.onboardingSlide3Title,
        subtitle: l10n.onboardingSlide3Subtitle,
        icon: Icons.schedule_rounded,
        accentColor: AppColors.anthraciteLight,
      ),
      _SlideData(
        title: l10n.onboardingSlide4Title,
        subtitle: l10n.onboardingSlide4Subtitle,
        icon: Icons.layers_rounded,
        accentColor: AppColors.emeraldMid,
      ),
    ];
    final isLastPage = _currentPage == slides.length - 1;
    return Scaffold(
      body: Stack(
        children: [
          _GradientBackground(pageIndex: _currentPage),
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: slides.length,
            itemBuilder: (context, i) =>
                _SlideContent(data: slides[i], isActive: _currentPage == i),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: AnimatedOpacity(
              opacity: isLastPage ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  l10n.onboardingSkip,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 28,
            right: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    slides.length,
                    (i) => _DotIndicator(isActive: i == _currentPage),
                  ),
                ),
                ArinPressable(
                  scale: 0.955,
                  sink: 2.4,
                  onTap: _nextPage,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.creamBase,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      child: Text(
                        isLastPage
                            ? l10n.onboardingGetStarted
                            : l10n.onboardingNext,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.emeraldDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  final int pageIndex;

  const _GradientBackground({required this.pageIndex});

  static const _gradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B4D3E), Color(0xFF2D7A5F), Color(0xFF1A1F1C)],
    ),
    LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF1A1F1C), Color(0xFF1B4D3E), Color(0xFF242B26)],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF242B26), Color(0xFF1B4D3E), Color(0xFF1A1F1C)],
    ),
    LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [Color(0xFF1B4D3E), Color(0xFF2A5C4A), Color(0xFF1A1F1C)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(gradient: _gradients[pageIndex]),
    );
  }
}

class _SlideContent extends StatelessWidget {
  final _SlideData data;
  final bool isActive;

  const _SlideContent({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            style: GlassPresets.prayerCard,
            padding: const EdgeInsets.all(32),
            child: Icon(data.icon, size: 72, color: AppColors.creamBase),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms, delay: 100.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          const SizedBox(height: 48),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.textOnDark,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textOnDarkMuted,
              height: 1.65,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms, delay: 320.ms)
              .slideY(begin: 0.15, end: 0),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool isActive;

  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.creamBase
            : AppColors.creamBase.withAlpha(77),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingPhaseSlide extends StatelessWidget {
  const _OnboardingPhaseSlide({
    required this.animation,
    required this.forward,
    required this.incoming,
    required this.child,
  });

  final Animation<double> animation;
  final bool forward;
  final bool incoming;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = incoming
        ? (forward ? const Offset(1, 0) : const Offset(-1, 0))
        : (forward ? const Offset(-1, 0) : const Offset(1, 0));
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: child,
    );
  }
}
