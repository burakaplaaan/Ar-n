// lib/presentation/onboarding/onboarding_survey_page.dart
// İsim → bildirim → (Android: kilit widget) → başlangıç özeti.
// Zümrüt tema, koşullu bildirim / widget adımı, animasyonlar.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
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
import '../../core/constants/profile_prefs_keys.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../data/services/arin_local_notifications_plugin.dart';
import '../../data/services/arin_lock_notification_service.dart';
import '../../data/services/fcm_token_service.dart';
import '../../data/services/local_notification_permission_gate.dart';
import '../../data/services/widget_access_service.dart';
import '../shared/providers/user_profile_providers.dart';
import '../shared/widgets/arin_permission_dialog.dart';

class OnboardingSurveyPage extends ConsumerStatefulWidget {
  const OnboardingSurveyPage({super.key});

  @override
  ConsumerState<OnboardingSurveyPage> createState() =>
      _OnboardingSurveyPageState();
}

class _OnboardingSurveyPageState extends ConsumerState<OnboardingSurveyPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  bool _surveyReady = false;
  bool _includeNotificationStep = true;
  bool _finishing = false;
  bool _notificationPermissionEnabled = false;
  bool _refreshPermissionAfterSettingsReturn = false;
  bool _lockWidgetsSaving = false;
  /// Varsayılan kapalı — kullanıcı onboarding'de açarsa yazılır.
  bool _lockPrayerEnabled = false;
  bool _lockQuoteEnabled = false;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  static const _surveyAccent = AppColors.emeraldMid;

  /// Kilit ekranı bildirim widget'ları yalnızca Android'de anlamlı (iOS hariç).
  bool get _includeLockWidgetsStep => !kIsWeb && Platform.isAndroid;

  int get _pageCount {
    var n = 2; // isim + özet
    if (_includeNotificationStep) n++;
    if (_includeLockWidgetsStep) n++;
    return n;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      // Bildirim adımını onboarding'de her zaman göster:
      // - Apple review ekranına karşı tutarlı görünüm
      // - Kullanıcı izin zaten açıksa bile neyin kontrol edildiğini görür.
      _includeNotificationStep = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameFocus.dispose();
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        !_refreshPermissionAfterSettingsReturn) {
      return;
    }
    _refreshPermissionAfterSettingsReturn = false;
    unawaited(_finishSettingsPermissionRefresh());
  }

  Future<void> _finishSettingsPermissionRefresh() async {
    await FcmTokenService.markBroadcastPermissionPromptHandled();
    await _refreshNotificationPermissionStatus();
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
    if (_notificationPermissionEnabled) {
      await FcmTokenService.markBroadcastPermissionPromptHandled();
      await FcmTokenService.resumeBroadcastSubscriptionIfAuthorized();
      if (!mounted) return;
      _nextPage();
      return;
    }
    setState(() => _permissionRequestInFlight = true);
    try {
      final ok = await requestLocalNotificationRuntimePermissions(
        arinLocalNotificationsPlugin,
        policy: LocalNotificationPermissionPolicy.full,
      );
      await FcmTokenService.markBroadcastPermissionPromptHandled();
      if (ok) {
        await FcmTokenService.resumeBroadcastSubscriptionIfAuthorized();
      }
      if (!mounted) return;

      // Battery optimization dialog'u (Android'de Samsung/Xiaomi için önemli).
      // Play Store şartı: Sistem popup'ından önce kullanıcıya bilgi ver.
      if (ok) {
        final confirmed = await showArinPermissionDialog(
          context: context,
          icon: Icons.battery_saver_rounded,
          title: l10n.notificationsBatteryRationaleTitle,
          body: l10n.notificationsBatteryRationaleBody,
          cancelLabel: l10n.notificationsBatteryRationaleCancel,
          confirmLabel: l10n.notificationsBatteryRationaleConfirm,
        );
        if (confirmed) {
          await requestIgnoreBatteryOptimizations();
        }
      }
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
            content: Text(l10n.onboardingNotificationPermissionDenied),
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
      final normalizedName = _nameController.text.trim();
      final hasCustomName = normalizedName.isNotEmpty;
      await ref
          .read(userProfileProvider.notifier)
          .saveProfile(
            name: hasCustomName ? normalizedName : null,
            gender: null,
            moodTags: const [],
            sectorTags: const [],
            needTags: const [],
          );

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(profileNameLockedByUserKey, hasCustomName);
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

  /// PageView.builder için: index → sayfa. Sırasıyla:
  /// isim → bildirim → (Android kilit widget) → özet.
  Widget _buildPageAt(int index) {
    final pages = <Widget Function()>[
      _buildNameStep,
      if (_includeNotificationStep) _buildNotificationStep,
      if (_includeLockWidgetsStep) _buildLockWidgetsStep,
      _buildSummaryStep,
    ];
    if (index < 0 || index >= pages.length) return const SizedBox.shrink();
    return pages[index]();
  }

  Future<void> _continueFromLockWidgets() async {
    if (_lockWidgetsSaving) return;
    setState(() => _lockWidgetsSaving = true);
    try {
      final prayerOk = await ArinLockNotificationService.setEnabled(
        ArinWidgetAccessKind.prayer,
        _lockPrayerEnabled,
      );
      final quoteOk = await ArinLockNotificationService.setEnabled(
        ArinWidgetAccessKind.quote,
        _lockQuoteEnabled,
      );
      if (!mounted) return;
      if ((_lockPrayerEnabled && !prayerOk) || (_lockQuoteEnabled && !quoteOk)) {
        setState(() {
          if (_lockPrayerEnabled && !prayerOk) _lockPrayerEnabled = false;
          if (_lockQuoteEnabled && !quoteOk) _lockQuoteEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bildirim izni verilmeden kilit ekranı widget\'ı açılamaz.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      if (!mounted) return;
      _nextPage();
    } finally {
      if (mounted) setState(() => _lockWidgetsSaving = false);
    }
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
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pageCount,
                  onPageChanged: (idx) {
                    setState(() => _currentIndex = idx);
                    // Onboarding funnel telemetrisi: hangi adımda drop
                    // olduğunu Firebase Console → Analytics → Funnel'da
                    // inceleyebilirsin.
                    unawaited(
                      ArinAnalytics.log('onboarding_step', {'step': idx}),
                    );
                  },
                  itemBuilder: (context, index) => _buildPageAt(index),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.surveyNameTitle,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 280.ms),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _nameController,
                    builder: (context, value, _) {
                      final name = value.text.trim();
                      if (name.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          '${l10n.surveyNameGreetingPrefix}, $name',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.emeraldLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.primaryFontFamily,
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
                  ).animate().fadeIn(delay: 80.ms),
                ],
              ),
            ),
          ),
          _buildNextButton(),
        ],
      ),
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
              _refreshPermissionAfterSettingsReturn = true;
              final opened = await openAppSettings();
              if (!opened) {
                _refreshPermissionAfterSettingsReturn = false;
                await _refreshNotificationPermissionStatus();
              }
            },
            child: Text(
              l10n.surveyNotificationOpenSettings,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () async {
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
              await FcmTokenService.markBroadcastPermissionPromptHandled();
              if (!mounted) return;
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

  Widget _buildLockWidgetsStep() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    l10n.surveyLockWidgetsTitle,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.lock_clock_rounded,
                    size: 72,
                    color: AppColors.emeraldLight,
                  ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 20),
                  Text(
                    l10n.surveyLockWidgetsLead,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 140.ms),
                  const SizedBox(height: 12),
                  Text(
                    l10n.surveyLockWidgetsSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.55,
                      fontSize: 14.5,
                    ),
                  ).animate().fadeIn(delay: 180.ms),
                  const SizedBox(height: 22),
                  _buildLockWidgetToggleCard(
                    icon: Icons.access_time_rounded,
                    title: l10n.surveyLockWidgetsPrayerTitle,
                    subtitle: l10n.surveyLockWidgetsPrayerSubtitle,
                    value: _lockPrayerEnabled,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _lockPrayerEnabled = v);
                    },
                  ).animate().fadeIn(delay: 220.ms),
                  const SizedBox(height: 10),
                  _buildLockWidgetToggleCard(
                    icon: Icons.format_quote_rounded,
                    title: l10n.surveyLockWidgetsQuoteTitle,
                    subtitle: l10n.surveyLockWidgetsQuoteSubtitle,
                    value: _lockQuoteEnabled,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _lockQuoteEnabled = v);
                    },
                  ).animate().fadeIn(delay: 260.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _lockWidgetsSaving ? null : _continueFromLockWidgets,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emeraldMid,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _lockWidgetsSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.surveyNext,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildLockWidgetToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: value
                  ? AppColors.emeraldLight.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emeraldLight.withValues(alpha: 0.14),
                ),
                child: Icon(icon, color: AppColors.emeraldLight, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.emeraldMid,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
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
    final displayName = name.isEmpty ? l10n.surveySummaryNotProvided : name;

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
              .scale(
                begin: const Offset(0.86, 0.86),
                curve: Curves.easeOutBack,
              ),
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
            child:
                Container(
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
                                  icon: Icons.notifications_none_rounded,
                                  label: l10n.surveyNotificationTitle,
                                  value: _notificationPermissionEnabled
                                      ? l10n.surveySummaryItemNotificationOn
                                      : l10n.surveySummaryItemNotificationOff,
                                  index: 1,
                                ),
                                if (_includeLockWidgetsStep) ...[
                                  _buildSummaryItem(
                                    icon: Icons.access_time_rounded,
                                    label: l10n.surveyLockWidgetsPrayerTitle,
                                    value: _lockPrayerEnabled
                                        ? l10n.surveySummaryItemNotificationOn
                                        : l10n.surveySummaryItemNotificationOff,
                                    index: 2,
                                  ),
                                  _buildSummaryItem(
                                    icon: Icons.format_quote_rounded,
                                    label: l10n.surveyLockWidgetsQuoteTitle,
                                    value: _lockQuoteEnabled
                                        ? l10n.surveySummaryItemNotificationOn
                                        : l10n.surveySummaryItemNotificationOff,
                                    index: 3,
                                  ),
                                ],
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
