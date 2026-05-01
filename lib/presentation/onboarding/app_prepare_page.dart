// lib/presentation/onboarding/app_prepare_page.dart
// Onboarding bittiğinde ana ekrana gitmeden önce vakitler / sözler ısıtılır.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/quotes_providers.dart';

class AppPreparePage extends ConsumerStatefulWidget {
  const AppPreparePage({super.key});

  @override
  ConsumerState<AppPreparePage> createState() => _AppPreparePageState();
}

class _AppPreparePageState extends ConsumerState<AppPreparePage> {
  bool _exiting = false;
  static const _minimumVisibleDuration = Duration(milliseconds: 1100);
  static const _warmupTimeout = Duration(milliseconds: 1800);

  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action().timeout(_warmupTimeout);
    } catch (_) {
      // Hazırlık ekranı navigasyonu bloke etmez; bu veriler uygulama içinde
      // provider'lar tarafından tekrar yüklenir.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPrepare());
  }

  Future<void> _warmPrayerTimes() async {
    await _bestEffort(() async {
      await ref.read(prayerTimesProvider.future);
    });
  }

  Future<void> _warmQuotes() async {
    await _bestEffort(() async {
      await ref.read(quotesCloudRepositoryProvider).ensureSyncedToday();
    });
  }

  Future<void> _runPrepare() async {
    await Future.wait<void>([
      Future<void>.delayed(_minimumVisibleDuration),
      _warmPrayerTimes(),
      _warmQuotes(),
    ]);
    if (!mounted) return;
    setState(() => _exiting = true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.emeraldDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2A22), AppColors.emeraldDark],
          ),
        ),
        child: SafeArea(
          child: AnimatedOpacity(
            opacity: _exiting ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                      Icons.auto_awesome,
                      size: 56,
                      color: AppColors.emeraldLight.withValues(alpha: 0.92),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1.08, 1.08),
                      duration: 1800.ms,
                      curve: Curves.easeInOutCubic,
                    ),
                const SizedBox(height: 28),
                Text(
                  l10n.appPrepareTitle,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    l10n.appPrepareSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.45,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 128,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      color: AppColors.emeraldLight,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
