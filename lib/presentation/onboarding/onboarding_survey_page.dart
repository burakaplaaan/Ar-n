// lib/presentation/onboarding/onboarding_survey_page.dart
// İsim → cinsiyet → ruh hali → alan → iç temalar → (bildirim, izin yoksa) → başlangıç özeti.
// Zümrüt tema, koşullu bildirim adımı, animasyonlar.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:arin/l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../data/services/arin_local_notifications_plugin.dart';
import '../../data/services/local_notification_permission_gate.dart';
import '../shared/providers/user_profile_providers.dart';

class OnboardingSurveyPage extends ConsumerStatefulWidget {
  const OnboardingSurveyPage({super.key});

  @override
  ConsumerState<OnboardingSurveyPage> createState() =>
      _OnboardingSurveyPageState();
}

class _OnboardingSurveyPageState extends ConsumerState<OnboardingSurveyPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  bool _surveyReady = false;
  bool _includeNotificationStep = true;
  bool _finishing = false;
  bool _notificationPermissionEnabled = false;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  bool _nameFocused = false;

  String? _selectedGender;
  final Set<String> _selectedMoods = {};
  final Set<String> _selectedSectors = {};
  final Set<String> _selectedNeeds = {};

  static const _surveyAccent = AppColors.emeraldMid;

  int get _pageCount => _includeNotificationStep ? 7 : 6;

  List<String> _moodOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.moodHappy,
      l10n.moodCalm,
      l10n.moodStressed,
      l10n.moodSad,
      l10n.moodGrateful,
      l10n.moodAnxious,
      l10n.moodMotivated,
    ];
  }

  List<String> _sectorOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.sectorStudent,
      l10n.sectorPrivate,
      l10n.sectorPublic,
      l10n.sectorBusiness,
      l10n.sectorTrade,
      l10n.sectorHousehold,
      l10n.sectorOther,
    ];
  }

  List<String> _innerThemeOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.needMotivation,
      l10n.needSabr,
      l10n.needShukr,
      l10n.needTawakkul,
      l10n.needFocus,
      l10n.needHealing,
      l10n.needRizq,
    ];
  }

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      if (mounted) setState(() => _nameFocused = _nameFocus.hasFocus);
    });
    _nameController.addListener(() {
      if (mounted) setState(() {});
    });
    unawaited(_bootstrapSurvey());
  }

  Future<void> _bootstrapSurvey() async {
    await _refreshNotificationPermissionStatus();
    if (!mounted) return;
    setState(() => _surveyReady = true);
  }

  Future<void> _refreshNotificationPermissionStatus() async {
    final status = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _notificationPermissionEnabled = status.isGranted || status.isLimited;
      _includeNotificationStep = !_notificationPermissionEnabled;
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_currentIndex < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.pop();
    }
  }

  bool _permissionRequestInFlight = false;

  /// Namaz bildiriminin gerçekten çalışması için 3 katman gerekli:
  ///   1) Notification (Android 13+ POST_NOTIFICATIONS, iOS alert+badge+sound)
  ///   2) Exact alarm (Android 12+ SCHEDULE_EXACT_ALARM) — ezan dakikası
  ///   3) Battery optimization whitelist (Doze / OEM) — cihaz uyusa da çalsın
  ///
  /// Hepsini ZİNCİR hâlinde sorarız; kullanıcı "İzin Ver"e tek tuşla tıklayıp
  /// sistem dialog'larını sırayla görür. Exact alarm / battery için reddederse
  /// kritik değil — scheduler gerektiğinde tekrar ister; ama ilk onboarding'de
  /// kapıyı açabiliyorsak Samsung/Xiaomi cihazlarda "bildirim geç geliyor"
  /// şikayetini en azından yarısı engelleriz.
  Future<void> _requestNotificationPermission() async {
    final l10n = AppLocalizations.of(context)!;
    if (_permissionRequestInFlight) return;
    setState(() => _permissionRequestInFlight = true);
    try {
      final ok = await requestLocalNotificationRuntimePermissions(
        arinLocalNotificationsPlugin,
        policy: LocalNotificationPermissionPolicy.full,
      );
      if (!mounted) return;

      // Battery optimization dialog'u (Android'de Samsung/Xiaomi için önemli).
      // İzin reddedilirse akış tıkanmasın — yine next page.
      await requestIgnoreBatteryOptimizations();
      if (!mounted) return;

      if (ok) {
        setState(() => _notificationPermissionEnabled = true);
        _nextPage();
      } else {
        setState(() => _notificationPermissionEnabled = false);
        // Reddedildi → skip olarak davran ama kullanıcı "Sistem ayarları" ile
        // sonradan açabileceğini bilsin.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.onboardingNotificationPermissionDenied,
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        _nextPage();
      }
    } finally {
      if (mounted) setState(() => _permissionRequestInFlight = false);
    }
  }

  Future<void> _saveAndFinish() async {
    final l10n = AppLocalizations.of(context)!;
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await ref.read(userProfileProvider.notifier).saveProfile(
            name: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : null,
            gender: _selectedGender,
            moodTags: _selectedMoods.toList(),
            sectorTags: _selectedSectors.toList(),
            needTags: _selectedNeeds.toList(),
          );

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('onboarding_completed', true);
      // Funnel bitti — tamamlananlar için kritik ölçü.
      unawaited(ArinAnalytics.log('onboarding_complete'));
      if (!mounted) return;
      ref.read(appRouterProvider).go(AppRoutes.appPrepare);
    } catch (e) {
      debugPrint('Onboarding kayit hatasi: $e');
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.surveySummarySaveError),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  List<Widget> _buildPages() {
    final l10n = AppLocalizations.of(context)!;
    return [
      _buildNameStep(),
      _buildGenderStep(),
      _buildSelectionStep(
        title: l10n.surveyMoodTitle,
        subtitle: l10n.surveyMoodSubtitle,
        options: _moodOptions(context),
        selected: _selectedMoods,
      ),
      _buildSelectionStep(
        title: l10n.surveyDailyRhythmTitle,
        subtitle: l10n.surveyDailyRhythmSubtitle,
        options: _sectorOptions(context),
        selected: _selectedSectors,
      ),
      _buildSelectionStep(
        title: l10n.surveyInnerThemesTitle,
        subtitle: l10n.surveyInnerThemesSubtitle,
        options: _innerThemeOptions(context),
        selected: _selectedNeeds,
      ),
      if (_includeNotificationStep) _buildNotificationStep(),
      _buildSummaryStep(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_surveyReady) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.homeGradientTop,
                AppColors.anthraciteDark,
                Color(0xFF0A0F0C),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.emeraldLight,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.homeGradientTop,
              AppColors.anthraciteDark,
              Color(0xFF0A0F0C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (idx) {
                    setState(() => _currentIndex = idx);
                    // Onboarding funnel telemetrisi: hangi adımda drop
                    // olduğunu Firebase Console → Analytics → Funnel'da
                    // inceleyebilirsin. Adım ismi yok çünkü sıra
                    // _buildPages() içinde kodla belirleniyor; index
                    // yeterli sinyal.
                    unawaited(ArinAnalytics.log(
                      'onboarding_step',
                      {'step': idx},
                    ));
                  },
                  children: _buildPages(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _prevPage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              children: List.generate(_pageCount, (index) {
                final isActive = index <= _currentIndex;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? _surveyAccent
                          : Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                offset: _nameFocused ? const Offset(0, -0.14) : Offset.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.surveyNameTitle,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.06),
                    if (name.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${l10n.surveyNameGreetingPrefix}, $name',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.emeraldLight,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                          .animate(key: ValueKey(name))
                          .fadeIn()
                          .slideX(begin: -0.03),
                    ],
                    const SizedBox(height: 28),
                    AnimatedScale(
                      scale: _nameFocused ? 1.03 : 1.0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _nameFocused
                              ? [
                                  BoxShadow(
                                    color: AppColors.emeraldLight
                                        .withValues(alpha: 0.22),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: TextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.surveyNameHint,
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.07),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: AppColors.emeraldLight,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.05),
                  ],
                ),
              ),
            ),
          ),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildGenderStep() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final title = name.isNotEmpty
        ? l10n.onboardingGenderPromptWithName(name)
        : l10n.surveyGenderTitle;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
          ).animate().fadeIn().slideY(begin: 0.08),
          const SizedBox(height: 8),
          Text(
            l10n.surveyGenderSubtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 36),
          _genderCard(
            label: l10n.surveyGenderMale,
            icon: Icons.man,
            isSelected: _selectedGender == l10n.surveyGenderMale,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedGender = l10n.surveyGenderMale);
            },
            animDelay: 180,
          ),
          const SizedBox(height: 14),
          _genderCard(
            label: l10n.surveyGenderFemale,
            icon: Icons.woman,
            isSelected: _selectedGender == l10n.surveyGenderFemale,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedGender = l10n.surveyGenderFemale);
            },
            animDelay: 260,
          ),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() => _selectedGender = null);
                _nextPage();
              },
              child: Text(
                l10n.surveyGenderDecline,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
              ),
            ),
          ),
          _buildNextButton(text: l10n.surveySave),
        ],
      ),
    );
  }

  Widget _genderCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required int animDelay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _surveyAccent : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _surveyAccent.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.emeraldLight : Colors.white70,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.emeraldLight),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: animDelay.ms)
        .slideX(begin: -0.04, curve: Curves.easeOutCubic);
  }

  Widget _buildSelectionStep({
    required String title,
    required String subtitle,
    required List<String> options,
    required Set<String> selected,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              height: 1.2,
            ),
          )
              .animate(key: ValueKey(title))
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.06, curve: Curves.easeOutCubic),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              height: 1.45,
              fontSize: 14.5,
            ),
          )
              .animate(key: ValueKey('$title-sub'))
              .fadeIn(delay: 70.ms, duration: 400.ms)
              .slideY(begin: 0.04),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              itemBuilder: (context, i) {
                final opt = options[i];
                final isOn = selected.contains(opt);
                return _buildSurveyOptionCard(
                  label: opt,
                  isSelected: isOn,
                  index: i,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (isOn) {
                        selected.remove(opt);
                      } else {
                        selected.add(opt);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildSurveyOptionCard({
    required String label,
    required bool isSelected,
    required int index,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: isSelected ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                width: isSelected ? 1.5 : 1,
                color: isSelected
                    ? AppColors.emeraldLight.withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        AppColors.emeraldBase.withValues(alpha: 0.55),
                        AppColors.emeraldDark.withValues(alpha: 0.42),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.09),
                        Colors.white.withValues(alpha: 0.04),
                      ],
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.emeraldLight.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: isSelected ? 5 : 0,
                    child: const ColoredBox(
                      color: AppColors.emeraldLight,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.emeraldLight
                                  : Colors.white.withValues(alpha: 0.35),
                              width: 2,
                            ),
                            color: isSelected
                                ? AppColors.emeraldLight.withValues(alpha: 0.25)
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: isSelected ? 1 : 0.9,
                              ),
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 15,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: (90 + index * 58).ms,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.14,
          end: 0,
          delay: (90 + index * 58).ms,
          duration: 480.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildNotificationStep() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            l10n.surveyNotificationTitle,
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 28),
          const Icon(
            Icons.notifications_active_rounded,
            size: 88,
            color: AppColors.emeraldLight,
          ).animate().scale(delay: 120.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 28),
          Text(
            l10n.surveyNotificationLead,
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 160.ms),
          const SizedBox(height: 14),
          Text(
            l10n.surveyNotificationSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.55,
              fontSize: 15,
            ),
          ).animate().fadeIn(delay: 220.ms),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _permissionRequestInFlight
                  ? null
                  : _requestNotificationPermission,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emeraldMid,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _permissionRequestInFlight
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.surveyNotificationAllow,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ).animate().fadeIn(delay: 280.ms),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              await _refreshNotificationPermissionStatus();
            },
            child: Text(
              l10n.surveyNotificationOpenSettings,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              // "Atla" sessizce geçersiz: Arın'ın ana özelliği namaz ezanı
              // bildirimleri. Kullanıcı farkına varmadan geçip uygulamayı
              // "bozuk" sanmasın diye uzun bir snackbar + aksiyon tuşu.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.onboardingNotificationSkippedWarning),
                  duration: const Duration(seconds: 6),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: l10n.onboardingOpenNowAction,
                    textColor: AppColors.accentNeonGreen,
                    onPressed: _requestNotificationPermission,
                  ),
                ),
              );
              setState(() => _notificationPermissionEnabled = false);
              _nextPage();
            },
            child: Text(
              l10n.surveyNotificationSkip,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.42)),
            ),
          ).animate().fadeIn(delay: 320.ms),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _selectionCountLabel(int count) {
    final l10n = AppLocalizations.of(context)!;
    if (count <= 0) return l10n.surveySummaryNotProvided;
    return '$count';
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.emeraldLight.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (120 + index * 70).ms, duration: 350.ms)
        .slideY(begin: 0.08, curve: Curves.easeOutCubic);
  }

  Widget _buildSummaryStep() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final displayName =
        name.isEmpty ? l10n.surveySummaryNotProvided : name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emeraldLight.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.emeraldLight.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emeraldLight.withValues(alpha: 0.2),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 44,
              color: AppColors.emeraldLight,
            ),
          )
              .animate()
              .fadeIn(duration: 420.ms)
              .scale(begin: const Offset(0.86, 0.86), curve: Curves.easeOutBack),
          const SizedBox(height: 22),
          Text(
            l10n.surveySummaryTitle,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.05),
          const SizedBox(height: 8),
          Text(
            l10n.surveySummarySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              height: 1.45,
              fontSize: 14.5,
            ),
          ).animate().fadeIn(delay: 140.ms),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: AppColors.emeraldLight.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.surveySummaryCardTitle,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(delay: 180.ms),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildSummaryItem(
                          icon: Icons.person_outline_rounded,
                          label: l10n.surveySummaryItemName,
                          value: displayName,
                          index: 0,
                        ),
                        _buildSummaryItem(
                          icon: Icons.favorite_border_rounded,
                          label: l10n.surveySummaryItemMood,
                          value: _selectionCountLabel(_selectedMoods.length),
                          index: 1,
                        ),
                        _buildSummaryItem(
                          icon: Icons.timeline_rounded,
                          label: l10n.surveySummaryItemRhythm,
                          value: _selectionCountLabel(_selectedSectors.length),
                          index: 2,
                        ),
                        _buildSummaryItem(
                          icon: Icons.lightbulb_outline_rounded,
                          label: l10n.surveySummaryItemThemes,
                          value: _selectionCountLabel(_selectedNeeds.length),
                          index: 3,
                        ),
                        _buildSummaryItem(
                          icon: Icons.notifications_none_rounded,
                          label: l10n.surveyNotificationTitle,
                          value: _notificationPermissionEnabled
                              ? l10n.surveySummaryItemNotificationOn
                              : l10n.surveySummaryItemNotificationOff,
                          index: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 120.ms, duration: 380.ms)
                .slideY(begin: 0.04),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _finishing ? null : _saveAndFinish,
              style: FilledButton.styleFrom(
                backgroundColor: _surveyAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _finishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.surveySummaryAction,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ).animate().fadeIn(delay: 260.ms),
        ],
      ),
    );
  }

  Widget _buildNextButton({String? text}) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _nextPage,
        style: FilledButton.styleFrom(
          backgroundColor: _surveyAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text ?? l10n.surveyNext,
          style: AppTextStyles.labelLarge.copyWith(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 40.ms);
  }
}
