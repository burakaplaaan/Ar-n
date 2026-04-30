// Arınma tam program — İlerleme + İpuçları sekmeleri, manevi mükâfatlar, animasyonlu çubuklar.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/willpower/quit_program_metrics.dart';
import '../../data/models/habit_model.dart';
import '../../data/willpower/willpower_content_loader.dart';
import '../shared/providers/habit_providers.dart';
import '../shared/providers/willpower_hub_nav_provider.dart';
import 'widgets/quit_smoking_shared_widgets.dart';

class QuitProgramHomePage extends ConsumerStatefulWidget {
  const QuitProgramHomePage({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<QuitProgramHomePage> createState() =>
      _QuitProgramHomePageState();
}

class _QuitProgramHomePageState extends ConsumerState<QuitProgramHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  QuitProgramHomeContent? _homeContent;
  bool _loadingTips = true;
  Timer? _liveClock;
  String? _homeLoadScheduledForKey;

  /// Son kutlama kontrolünün yapıldığı tam gün.
  /// Her saniye tetiklemeyi engeller, ancak gün değişince yeniden kontrol eder.
  int _lastMilestoneEvalDays = -1;

  static const _tabAccent = Color(0xFFE53935);
  static const _gold = Color(0xFFC9A962);

  String _localizedHabitTitle(AppLocalizations l10n, HabitModel habit) {
    switch (habit.templateId) {
      case WillpowerTemplates.salatDaily:
        return l10n.homeNamazTrackingTitle;
      case WillpowerTemplates.quitScreen:
        return l10n.quitPickerTemplateScreenTitle;
      case WillpowerTemplates.quitSmoking:
        return l10n.quitPickerTemplateSmokingTitle;
      case WillpowerTemplates.quitAlcohol:
        return l10n.quitPickerTemplateAlcoholTitle;
      case WillpowerTemplates.quitSubstance:
        return l10n.quitPickerTemplateSubstanceTitle;
      case WillpowerTemplates.quitZina:
        return l10n.quitPickerTemplateZinaTitle;
      default:
        return habit.title;
    }
  }

  @override
  void initState() {
    super.initState();
    _liveClock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _liveClock?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  String _milestonePrefsKey() =>
      'quit_milestone_last_celebrated_${widget.habitId}';

  /// `elapsedDays` ile `_mukafatlar` tablosu karşılaştırılır. Henüz
  /// kutlanmamış (prefs'te son kutlanan günden büyük) en yüksek milestone
  /// tetiklenir. Aynı oturum içinde yalnızca bir sheet açılır.
  Future<void> _maybeShowMilestoneCelebration(int elapsedDays) async {
    if (elapsedDays <= 0) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final lastCelebrated = prefs.getInt(_milestonePrefsKey()) ?? 0;

    _Muk? due;
    final l10n = AppLocalizations.of(context)!;
    for (final m in _mukafatlar(l10n)) {
      if (m.days <= elapsedDays && m.days > lastCelebrated) {
        due = m;
      }
    }
    if (due == null) return;
    await prefs.setInt(_milestonePrefsKey(), due.days);
    unawaited(ArinAnalytics.arinmaMilestone(due.days));
    if (!mounted) return;
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (ctx) => _MilestoneCelebrationSheet(
        milestone: due!,
        elapsedDays: elapsedDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final isTurkish = localeCode == 'tr';
    final summary = ref.watch(habitSummaryProvider);
    HabitModel? habit;
    for (final e in summary) {
      if (e.habit.id == widget.habitId) {
        habit = e.habit;
        break;
      }
    }

    if (habit == null ||
        !WillpowerTemplates.isFullQuitProgram(habit.templateId)) {
      return Scaffold(
        backgroundColor: AppColors.anthraciteDark,
        body: Center(
          child: Text(
            l10n.quitProgramNotFound,
            style: const TextStyle(color: AppColors.creamBase),
          ),
        ),
      );
    }

    // Kriz anı "Hızlı başla" akışı: onboarding tamamlanmamış olsa bile sayaç
    // kurulmuşsa (quickStartQuitClock) program home'a izin ver; kullanıcı
    // ahdini sonradan tamamlayabilir. Sadece sayaç da kurulmamışsa onboarding
    // zorunluluğu devam eder.
    final hasClockStarted = habit.quitClockStartedAtIso != null &&
        habit.quitClockStartedAtIso!.isNotEmpty;
    if (!habit.onboardingCompleted && !hasClockStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRoutes.willQuitOnboarding(widget.habitId));
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.anthraciteDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentNeonGreen),
        ),
      );
    }

    final repo = ref.read(habitRepositoryProvider);
    final elapsed = repo.elapsedQuitDays(widget.habitId);
    final clockOn = habit.quitClockStartedAtIso != null &&
        habit.quitClockStartedAtIso!.isNotEmpty;
    final elapsedLive = repo.quitElapsedSinceClock(widget.habitId);

    // Kutlama: onboarding tamam + sayaç açıkken her yeni tam günde bir kez kontrol et.
    if (clockOn &&
        habit.onboardingCompleted &&
        elapsed != _lastMilestoneEvalDays) {
      _lastMilestoneEvalDays = elapsed;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeShowMilestoneCelebration(elapsed);
      });
    }

    final loadKey = '${habit.templateId}|$localeCode';
    if (_homeLoadScheduledForKey != loadKey) {
      _homeLoadScheduledForKey = loadKey;
      final tid = habit.templateId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        QuitProgramHomeContent.loadForTemplate(
          tid,
          localeCode: localeCode,
        ).then((c) {
          if (mounted && _homeLoadScheduledForKey == loadKey) {
            setState(() {
              _homeContent = c;
              _loadingTips = false;
            });
          }
        }).catchError((_) {
          if (mounted && _homeLoadScheduledForKey == loadKey) {
            setState(() {
              _homeContent = QuitProgramHomeContent(
                tips: const [],
                wisdom: const [],
                ui: QuitProgramUiCopy.merge(
                  tid,
                  null,
                  localeCode: localeCode,
                ),
              );
              _loadingTips = false;
            });
          }
        });
      });
    }

    final rawUi = _homeContent?.ui ??
        QuitProgramUiCopy.merge(
          habit.templateId,
          null,
          localeCode: localeCode,
        );
    final ui = _uiCopyForLocale(
      l10n: l10n,
      isTurkish: isTurkish,
      fallback: rawUi,
    );
    final metricRows = _metricRowsForLocale(
      l10n: l10n,
      templateId: habit.templateId,
      elapsedDays: elapsed,
      tabAccent: _tabAccent,
      isTurkish: isTurkish,
    );
    final localizedTips = isTurkish ? (_homeContent?.tips ?? const []) : const <QuitHomeTip>[];
    final localizedWisdom =
        isTurkish ? (_homeContent?.wisdom ?? const []) : const <QuitWisdomItem>[];
    final motivation = _motivationForLocale(
      l10n: l10n,
      templateId: habit.templateId,
      elapsedDays: elapsed,
      isTurkish: isTurkish,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF14192C),
              Color(0xFF1A1F1C),
              Color(0xFF0F1418),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        ref.read(willpowerHubReturnToArinmaProvider.notifier).state =
                            true;
                        popOrGoWillpowerHub(context);
                      },
                      child: Text(
                        l10n.commonClose,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.creamBase.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _localizedHabitTitle(l10n, habit),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.creamBase,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              if (!habit.onboardingCompleted && clockOn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: _CompleteOnboardingBanner(
                    onTap: () => context.push(
                      AppRoutes.willQuitOnboarding(widget.habitId),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                child: _QuitDualTabBar(
                  controller: _tabs,
                  accent: _tabAccent,
                  l10n: l10n,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _TerakkiTab(
                      ui: ui,
                      wisdomItems: localizedWisdom,
                      metricRows: metricRows,
                      elapsedDays: elapsed,
                      clockStarted: clockOn,
                      elapsedLive: elapsedLive,
                      motivationText: motivation,
                      commitmentPreview: habit.commitmentText,
                      onStartClock: () => ref
                          .read(habitSummaryProvider.notifier)
                          .setQuitClockNow(widget.habitId),
                      onRestart: () => _confirmRestart(context),
                      tabAccent: _tabAccent,
                      gold: _gold,
                    ),
                    _loadingTips
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentNeonGreen,
                            ),
                          )
                        : _HidayetTab(
                            tips: localizedTips,
                            gold: _gold,
                            l10n: l10n,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRestart(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // 2 seçenekli reset dialog: "Geçmişi sakla" (önerilen, güvenli) ve
    // "Sıfırdan başla" (kırmızı, geri alınmaz). Kullanıcı 87 gün sonra kazara
    // "sıfırla" basıp tüm istatistiklerini kaybetmesin diye yumuşak default.
    final choice = await showDialog<_ResetChoice>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.anthraciteMid,
        title: Text(
          l10n.quitProgramRestartTitle,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.creamBase),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.quitProgramRestartPrompt,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnDarkMuted,
              ),
            ),
            const SizedBox(height: 14),
            _ResetOptionTile(
              icon: Icons.history_rounded,
              title: l10n.quitProgramRestartKeepHistoryTitle,
              subtitle: l10n.quitProgramRestartKeepHistorySubtitle,
              color: _tabAccent,
              onTap: () => Navigator.pop(ctx, _ResetChoice.keepHistory),
            ),
            const SizedBox(height: 8),
            _ResetOptionTile(
              icon: Icons.delete_sweep_rounded,
              title: l10n.quitProgramRestartWipeTitle,
              subtitle: l10n.quitProgramRestartWipeSubtitle,
              color: Colors.redAccent,
              onTap: () => Navigator.pop(ctx, _ResetChoice.wipeAll),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ResetChoice.cancel),
            child: Text(
              l10n.quitOnboardingAbortAction,
              style: const TextStyle(color: AppColors.creamBase),
            ),
          ),
        ],
      ),
    );
    if (choice == null || choice == _ResetChoice.cancel) return;
    if (!context.mounted) return;

    await ref.read(habitSummaryProvider.notifier).restartQuitProgram(
          widget.habitId,
          preserveHistory: choice == _ResetChoice.keepHistory,
        );
    final habit =
        ref.read(habitRepositoryProvider).getById(widget.habitId);
    unawaited(
      ArinAnalytics.arinmaReset(
        habit?.quitSubtype ?? habit?.templateId ?? 'quit',
      ),
    );
    // Milestone prefs sıfırlansın → yeni sayaçta kutlama tetiklenebilsin.
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_milestonePrefsKey());
    _lastMilestoneEvalDays = -1;
  }

}

QuitProgramUiCopy _uiCopyForLocale({
  required AppLocalizations l10n,
  required bool isTurkish,
  required QuitProgramUiCopy fallback,
}) {
  if (isTurkish) return fallback;
  return QuitProgramUiCopy(
    counterSubtitle: l10n.quitProgramUiCounterSubtitleGeneric,
    metricsSectionTitle: l10n.quitProgramUiMetricsSectionTitleGeneric,
    disclaimer: l10n.quitProgramUiDisclaimerGeneric,
    encouragementBox: l10n.quitProgramUiEncouragementGeneric,
    clockHint: l10n.quitProgramUiClockHintGeneric,
  );
}

List<QuitMetricRowUi> _metricRowsForLocale({
  required AppLocalizations l10n,
  required String templateId,
  required int elapsedDays,
  required Color tabAccent,
  required bool isTurkish,
}) {
  final base = quitMetricRowsFor(
    templateId: templateId,
    elapsedDays: elapsedDays,
    tabAccent: tabAccent,
  );
  if (isTurkish) return base;
  final labels = _metricLabelsForTemplate(l10n, templateId);
  return List.generate(base.length, (index) {
    final row = base[index];
    return QuitMetricRowUi(
      icon: row.icon,
      label: index < labels.length ? labels[index] : row.label,
      percent: row.percent,
      barColor: row.barColor,
    );
  });
}

List<String> _metricLabelsForTemplate(AppLocalizations l10n, String templateId) {
  switch (templateId) {
    case WillpowerTemplates.quitSmoking:
      return [
        l10n.quitMetricSmokingLung,
        l10n.quitMetricSmokingHeart,
        l10n.quitMetricSmokingTeethMouth,
        l10n.quitMetricSmokingSmellTaste,
      ];
    case WillpowerTemplates.quitScreen:
      return [
        l10n.quitMetricScreenFocusDepth,
        l10n.quitMetricScreenSleepRhythm,
        l10n.quitMetricScreenAwareness,
        l10n.quitMetricScreenInnerCalm,
      ];
    case WillpowerTemplates.quitAlcohol:
      return [
        l10n.quitMetricAlcoholLiverRecovery,
        l10n.quitMetricAlcoholSleepStability,
        l10n.quitMetricAlcoholMoodBalance,
        l10n.quitMetricAlcoholClarity,
      ];
    case WillpowerTemplates.quitSubstance:
      return [
        l10n.quitMetricSubstanceBodyBalance,
        l10n.quitMetricSubstanceSleepRhythm,
        l10n.quitMetricSubstanceUrgeControl,
        l10n.quitMetricSubstanceSupportTracking,
      ];
    case WillpowerTemplates.quitZina:
      return [
        l10n.quitMetricZinaDiscipline,
        l10n.quitMetricZinaBoundaryStrength,
        l10n.quitMetricZinaHeartCalm,
        l10n.quitMetricZinaTawbaDirection,
      ];
    default:
      return const [];
  }
}

String _motivationForLocale({
  required AppLocalizations l10n,
  required String templateId,
  required int elapsedDays,
  required bool isTurkish,
}) {
  if (isTurkish) {
    return quitMotivationForTemplate(templateId, elapsedDays);
  }
  if (elapsedDays <= 0) return l10n.quitProgramMotivationStageStart;
  if (elapsedDays < 7) return l10n.quitProgramMotivationStageWeek;
  if (elapsedDays < 30) return l10n.quitProgramMotivationStageMonth;
  if (elapsedDays < 90) return l10n.quitProgramMotivationStageQuarter;
  return l10n.quitProgramMotivationStageLong;
}

enum _ResetChoice { cancel, keepHistory, wipeAll }

class _ResetOptionTile extends StatelessWidget {
  const _ResetOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatQuitHms(Duration d, AppLocalizations l10n) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return l10n.quitProgramElapsedHms(h, m, s);
  }
  if (m > 0) {
    return l10n.quitProgramElapsedMs(m, s);
  }
  return l10n.quitProgramElapsedS(s);
}

/// İki sekmeli animasyonlu üst çubuk.
class _QuitDualTabBar extends StatelessWidget {
  const _QuitDualTabBar({
    required this.controller,
    required this.accent,
    required this.l10n,
  });

  final TabController controller;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            const pad = 4.0;
            final inner = w - pad * 2;
            final seg = inner / 2;
            final idx = controller.index.clamp(0, 1);
            return Container(
              height: 46,
              padding: const EdgeInsets.all(pad),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.055),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: pad + idx * seg,
                    top: 0,
                    width: seg,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.35),
                            accent.withValues(alpha: 0.18),
                          ],
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => controller.animateTo(0),
                          child: Center(
                            child: Text(
                              l10n.quitProgramTabProgress,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.3,
                                color: Color.lerp(
                                  AppColors.creamBase.withValues(alpha: 0.5),
                                  AppColors.creamBase,
                                  idx == 0 ? 1.0 : 0.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => controller.animateTo(1),
                          child: Center(
                            child: Text(
                              l10n.quitProgramTabTips,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.3,
                                color: Color.lerp(
                                  AppColors.creamBase.withValues(alpha: 0.5),
                                  AppColors.creamBase,
                                  idx == 1 ? 1.0 : 0.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HidayetTab extends StatelessWidget {
  const _HidayetTab({
    required this.tips,
    required this.gold,
    required this.l10n,
  });

  final List<QuitHomeTip> tips;
  final Color gold;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      children: [
        _HidayetHero(gold: gold, l10n: l10n),
        const SizedBox(height: 22),
        ...tips.asMap().entries.map((e) {
          return _HidayetInsightCard(
            tip: e.value,
            index: e.key,
            gold: gold,
          );
        }),
        if (tips.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                l10n.quitProgramTipsLoadFailed,
                style: const TextStyle(color: AppColors.textOnDarkMuted),
              ),
            ),
          ),
      ],
    );
  }
}

/// Hidayet sekmesi için zengin başlık kartı — düz "İpuçları" başlığı yerine
/// altın haloli hero ikon + Arapça "hidâyet" kelimesi watermark + hiyerarşik
/// başlık/açıklama. Sekme açıldığında kullanıcı "bu manevi rehberlik alanı"
/// hissini anında alır.
class _HidayetHero extends StatelessWidget {
  const _HidayetHero({required this.gold, required this.l10n});

  final Color gold;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gold.withValues(alpha: 0.14),
            gold.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: gold.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          // Locale-aware watermark for spiritual guidance theme.
          Positioned(
            right: -6,
            top: -12,
            child: Text(
              l10n.quitProgramTipsWatermark,
              style: GoogleFonts.scheherazadeNew(
                fontSize: 64,
                color: gold.withValues(alpha: 0.1),
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gold.withValues(alpha: 0.35),
                      gold.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: gold.withValues(alpha: 0.5)),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quitProgramTipsHeroTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.creamBase,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.quitProgramTipsHeroSubtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnDarkMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 420.ms)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 480.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _HidayetInsightCard extends StatefulWidget {
  const _HidayetInsightCard({
    required this.tip,
    required this.index,
    required this.gold,
  });

  final QuitHomeTip tip;
  final int index;
  final Color gold;

  @override
  State<_HidayetInsightCard> createState() => _HidayetInsightCardState();
}

class _HidayetInsightCardState extends State<_HidayetInsightCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: _open ? 0.07 : 0.045),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(
                color: widget.gold.withValues(alpha: _open ? 0.42 : 0.22),
                width: 1,
              ),
              boxShadow: [
                if (_open)
                  BoxShadow(
                    color: widget.gold.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.gold.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: widget.gold.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.tip.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.creamBase,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.creamBase.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 280),
                  crossFadeState: _open
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(left: 48, top: 12),
                    child: Text(
                      widget.tip.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnDarkMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 + widget.index * 45),
          duration: 420.ms,
        )
        .slideY(
          begin: 0.07,
          delay: Duration(milliseconds: 50 + widget.index * 45),
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

typedef _Muk = ({int days, String title, String subtitle, IconData icon, Color achievedTint});

List<_Muk> _mukafatlar(AppLocalizations l10n) => [
  (days: 1, title: l10n.quitMilestone1Title, subtitle: l10n.quitMilestone1Subtitle, icon: Icons.wb_twilight_rounded, achievedTint: const Color(0xFF90CAF9)),
  (days: 2, title: l10n.quitMilestone2Title, subtitle: l10n.quitMilestone2Subtitle, icon: Icons.bolt_rounded, achievedTint: const Color(0xFFFFB74D)),
  (days: 3, title: l10n.quitMilestone3Title, subtitle: l10n.quitMilestone3Subtitle, icon: Icons.water_drop_outlined, achievedTint: const Color(0xFF4FC3F7)),
  (days: 5, title: l10n.quitMilestone5Title, subtitle: l10n.quitMilestone5Subtitle, icon: Icons.auto_awesome_outlined, achievedTint: const Color(0xFFCE93D8)),
  (days: 7, title: l10n.quitMilestone7Title, subtitle: l10n.quitMilestone7Subtitle, icon: Icons.flag_rounded, achievedTint: const Color(0xFF81C784)),
  (days: 10, title: l10n.quitMilestone10Title, subtitle: l10n.quitMilestone10Subtitle, icon: Icons.trending_up_rounded, achievedTint: const Color(0xFFA5D6A7)),
  (days: 14, title: l10n.quitMilestone14Title, subtitle: l10n.quitMilestone14Subtitle, icon: Icons.visibility_outlined, achievedTint: const Color(0xFF64B5F6)),
  (days: 21, title: l10n.quitMilestone21Title, subtitle: l10n.quitMilestone21Subtitle, icon: Icons.psychology_outlined, achievedTint: const Color(0xFFFFCC80)),
  (days: 30, title: l10n.quitMilestone30Title, subtitle: l10n.quitMilestone30Subtitle, icon: Icons.star_rounded, achievedTint: const Color(0xFFFFD54F)),
  (days: 45, title: l10n.quitMilestone45Title, subtitle: l10n.quitMilestone45Subtitle, icon: Icons.shield_outlined, achievedTint: const Color(0xFFA1887F)),
  (days: 60, title: l10n.quitMilestone60Title, subtitle: l10n.quitMilestone60Subtitle, icon: Icons.favorite_outline_rounded, achievedTint: const Color(0xFFEF9A9A)),
  (days: 66, title: l10n.quitMilestone66Title, subtitle: l10n.quitMilestone66Subtitle, icon: Icons.emoji_events_rounded, achievedTint: const Color(0xFFFFD700)),
  (days: 90, title: l10n.quitMilestone90Title, subtitle: l10n.quitMilestone90Subtitle, icon: Icons.spa_outlined, achievedTint: const Color(0xFF69F0AE)),
  (days: 120, title: l10n.quitMilestone120Title, subtitle: l10n.quitMilestone120Subtitle, icon: Icons.military_tech_outlined, achievedTint: const Color(0xFFB0BEC5)),
  (days: 180, title: l10n.quitMilestone180Title, subtitle: l10n.quitMilestone180Subtitle, icon: Icons.workspace_premium_outlined, achievedTint: const Color(0xFFFFAB40)),
  (days: 270, title: l10n.quitMilestone270Title, subtitle: l10n.quitMilestone270Subtitle, icon: Icons.nightlight_round, achievedTint: const Color(0xFF7986CB)),
  (days: 365, title: l10n.quitMilestone365Title, subtitle: l10n.quitMilestone365Subtitle, icon: Icons.celebration_outlined, achievedTint: const Color(0xFFFF4081)),
  (days: 500, title: l10n.quitMilestone500Title, subtitle: l10n.quitMilestone500Subtitle, icon: Icons.diamond_outlined, achievedTint: const Color(0xFFE1BEE7)),
  (days: 730, title: l10n.quitMilestone730Title, subtitle: l10n.quitMilestone730Subtitle, icon: Icons.volunteer_activism_outlined, achievedTint: const Color(0xFF80CBC4)),
  (days: 1000, title: l10n.quitMilestone1000Title, subtitle: l10n.quitMilestone1000Subtitle, icon: Icons.auto_fix_high_rounded, achievedTint: const Color(0xFFFFF59D)),
];

class _TerakkiTab extends StatelessWidget {
  const _TerakkiTab({
    required this.ui,
    required this.wisdomItems,
    required this.motivationText,
    required this.metricRows,
    required this.elapsedDays,
    required this.clockStarted,
    required this.elapsedLive,
    required this.commitmentPreview,
    required this.onStartClock,
    required this.onRestart,
    required this.tabAccent,
    required this.gold,
  });

  final QuitProgramUiCopy ui;
  final List<QuitWisdomItem> wisdomItems;
  final String motivationText;
  final List<QuitMetricRowUi> metricRows;
  final int elapsedDays;
  final bool clockStarted;
  final Duration? elapsedLive;
  final String commitmentPreview;
  final VoidCallback onStartClock;
  final VoidCallback onRestart;
  final Color tabAccent;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayDays = clockStarted ? elapsedDays : 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Center(
          child: Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1B5E3A).withValues(alpha: 0.95),
                  const Color(0xFF0D2818),
                ],
              ),
              border: Border.all(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.12),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$displayDays',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 52,
                    height: 1,
                  ),
                ),
                Text(
                  l10n.quitProgramDaysUpper,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ui.counterSubtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                if (clockStarted && elapsedLive != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _formatQuitHms(elapsedLive!, l10n),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 450.ms)
            .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOutBack),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF0F2A18).withValues(alpha: 0.9),
            border: Border.all(
              color: AppColors.accentNeonGreen.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            motivationText,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.creamBase,
              height: 1.45,
            ),
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        if (!clockStarted) ...[
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onStartClock,
            style: FilledButton.styleFrom(
              backgroundColor: tabAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.quitProgramStartNowAction,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          Text(
            ui.clockHint,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textOnDarkMuted,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today_rounded,
                value: '$elapsedDays',
                label: l10n.quitProgramStatFullDays,
                borderColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.schedule_rounded,
                value: elapsedLive != null
                    ? _formatQuitHms(elapsedLive!, l10n)
                    : l10n.quitProgramDash,
                label: l10n.quitProgramStatTimer,
                borderColor: AppColors.accentNeonGreen,
                smallValue: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        QuitWisdomCarousel(items: wisdomItems),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gold.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(color: gold.withValues(alpha: 0.28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                size: 22,
                color: AppColors.creamBase.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ui.encouragementBox,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.creamBase.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (commitmentPreview.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: gold.withValues(alpha: 0.22)),
            ),
            child: Text(
              '“$commitmentPreview”',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.creamBase.withValues(alpha: 0.92),
                height: 1.45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          ui.metricsSectionTitle,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.creamBase,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.quitProgramElapsedSinceQuitDays(elapsedDays),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
        const SizedBox(height: 12),
        ...metricRows.asMap().entries.map((e) {
          final row = e.value;
          return QuitMetricBarTile(
            icon: row.icon,
            label: row.label,
            percent: row.percent,
            delayMs: e.key * 80,
            barColor: row.barColor,
          );
        }),
        Text(
          ui.disclaimer,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textOnDarkMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.quitProgramTasksTitle,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.creamBase,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.quitProgramTasksSubtitle,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textOnDarkMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        ..._mukafatlar(l10n).asMap().entries.map((e) {
          return _ManeviMukafatRow(
            def: e.value,
            currentDays: elapsedDays,
            index: e.key,
          );
        }),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: onRestart,
          style: OutlinedButton.styleFrom(
            foregroundColor: tabAccent,
            side: BorderSide(color: tabAccent),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(l10n.quitProgramRestartTitle),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.borderColor,
    this.smallValue = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color borderColor;
  final bool smallValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.anthraciteMid.withValues(alpha: 0.5),
        border: Border.all(color: borderColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Icon(icon, color: borderColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.creamBase,
              fontWeight: FontWeight.w800,
              fontSize: smallValue ? 15 : null,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManeviMukafatRow extends StatelessWidget {
  const _ManeviMukafatRow({
    required this.def,
    required this.currentDays,
    required this.index,
  });

  final _Muk def;
  final int currentDays;
  final int index;

  @override
  Widget build(BuildContext context) {
    final achieved = currentDays >= def.days;
    final p = def.days <= 0 ? 0.0 : (currentDays / def.days).clamp(0.0, 1.0);
    final iconColor = achieved
        ? def.achievedTint
        : AppColors.creamBase.withValues(alpha: 0.28);
    final borderC = achieved
        ? def.achievedTint.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: achieved
              ? LinearGradient(
                  colors: [
                    def.achievedTint.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                )
              : null,
          color: achieved ? null : Colors.white.withValues(alpha: 0.045),
          border: Border.all(color: borderC, width: achieved ? 1.2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: achieved
                        ? def.achievedTint.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: achieved
                          ? def.achievedTint.withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    boxShadow: achieved
                        ? [
                            BoxShadow(
                              color: def.achievedTint.withValues(alpha: 0.35),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(def.icon, color: iconColor, size: achieved ? 26 : 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              def.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.creamBase,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (achieved)
                            Icon(
                              Icons.verified_rounded,
                              size: 20,
                              color: def.achievedTint,
                            ),
                        ],
                      ),
                      Text(
                        def.subtitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textOnDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: p),
                duration: Duration(milliseconds: 500 + index * 12),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) {
                  return LinearProgressIndicator(
                    value: val,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achieved
                          ? def.achievedTint
                          : const Color(0xFFFFA726).withValues(alpha: 0.85),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 30 + index * 25),
          duration: 350.ms,
        )
        .slideX(
          begin: 0.03,
          delay: Duration(milliseconds: 30 + index * 25),
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Gün kilometre taşı kutlaması — tek seferlik (prefs ile tetiklenir).
/// Tasarım: koyu zeminde milestone rengi aurası, büyük ikon, tebrik, kısa
/// manevi söz, tek CTA ("Devam et"). Uzun metinler yok — anlık dopamin.
class _MilestoneCelebrationSheet extends StatelessWidget {
  const _MilestoneCelebrationSheet({
    required this.milestone,
    required this.elapsedDays,
  });

  final _Muk milestone;
  final int elapsedDays;

  /// Milestone'a göre kısa manevi söz (rotasyon gerek yok — tek kez görülür).
  /// Uzun metinlerden kaçınıyoruz, kutlama "büyük an" olarak kalmalı.
  String _inspirationalLine(AppLocalizations l10n) {
    if (milestone.days >= 365) {
      return l10n.quitMilestoneInspiration365;
    }
    if (milestone.days >= 90) {
      return l10n.quitMilestoneInspiration90;
    }
    if (milestone.days >= 30) {
      return l10n.quitMilestoneInspiration30;
    }
    if (milestone.days >= 7) {
      return l10n.quitMilestoneInspiration7;
    }
    return l10n.quitMilestoneInspiration1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tint = milestone.achievedTint;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14192C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: tint.withValues(alpha: 0.45), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 14, 24, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  tint.withValues(alpha: 0.38),
                  tint.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: tint.withValues(alpha: 0.55), width: 1.4),
            ),
            child: Icon(
              milestone.icon,
              size: 44,
              color: tint,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1, 1),
                duration: 520.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 380.ms),
          const SizedBox(height: 18),
          Text(
            milestone.title,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.creamBase,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ).animate().fadeIn(delay: 180.ms, duration: 360.ms),
          const SizedBox(height: 6),
          Text(
            l10n.quitMilestoneElapsedSummary(elapsedDays, milestone.subtitle),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkMuted,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 240.ms, duration: 360.ms),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: tint.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              _inspirationalLine(l10n),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.creamBase.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
            ),
          ).animate().fadeIn(delay: 320.ms, duration: 380.ms),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: tint.withValues(alpha: 0.9),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.quitMilestoneContinueAction,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ).animate().fadeIn(delay: 420.ms, duration: 320.ms),
        ],
      ),
    );
  }
}

/// "Hızlı başla" ile gelen kullanıcılar için nazik bir davet: ahdini yaz ve
/// programa manevi boyut kat. Dismissable değil — sadece onboarding
/// tamamlanınca kendiliğinden kaybolur (state-driven).
class _CompleteOnboardingBanner extends StatelessWidget {
  const _CompleteOnboardingBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFC9A962).withValues(alpha: 0.16),
                const Color(0xFFC9A962).withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFC9A962).withValues(alpha: 0.38),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: const Color(0xFFC9A962).withValues(alpha: 0.9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.quitProgramCompleteCommitmentTitle,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.creamBase,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!
                          .quitProgramCompleteCommitmentSubtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textOnDarkMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: const Color(0xFFC9A962).withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 380.ms)
        .slideY(begin: -0.15, end: 0, duration: 420.ms, curve: Curves.easeOut);
  }
}
