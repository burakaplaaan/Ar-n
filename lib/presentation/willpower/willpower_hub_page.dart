// lib/presentation/willpower/willpower_hub_page.dart
// Alışkanlık takibi — modern yeşil/siyah tema, özet, dinamik ilham kartları, FAB.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/router/app_router.dart';
import '../../data/models/habit_model.dart';
import '../../data/services/habit_cloud_sync_service.dart';
import '../../data/willpower/habit_insights_catalog.dart';
import '../shared/providers/habit_insights_provider.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/providers/habit_providers.dart';
import '../shared/providers/prayer_time_providers.dart';
import '../shared/providers/willpower_hub_nav_provider.dart';
import '../shared/widgets/arin_shell_layout.dart';
import '../kaza/kaza_tracking_provider.dart';
import 'salat_celebration.dart';
import 'salat_providers.dart';
import 'widgets/quit_smoking_shared_widgets.dart';
import 'widgets/salat_prayer_row.dart';

const Color _kQuitAccent = Color(0xFFFF5252);
const Color _kCardSurface = Color(0xFF121814);
const Color _kInsightMedicalTint = Color(0xFF7EB8C9);

enum _HubResetChoice { cancel, keepHistory, wipeAll }

class _HubResetOptionTile extends StatelessWidget {
  const _HubResetOptionTile({
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
      child: Ink(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          color: color.withValues(alpha: 0.1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.creamBase,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textOnDarkMuted,
                      height: 1.3,
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

/// Sigara kartı — sayaç metni (daha sakin, elit görünüm).
const Color _kQuitHubTimerElite = Color(0xFF9DB0A8);

/// Arınma üst kartı yüzdesi: %100 = 365 gün temiz sayaç (24 saat değil).
const int _kQuitHubProgressYearSeconds = 86400 * 365;

String _formatQuitHubHmsLocalized({
  required int hours,
  required int minutes,
  required int seconds,
  required AppLocalizations l10n,
}) {
  final h = hours;
  final m = minutes;
  final s = seconds;
  if (h > 0) return l10n.quitProgramElapsedHms(h, m, s);
  if (m > 0) return l10n.quitProgramElapsedMs(m, s);
  return l10n.quitProgramElapsedS(s);
}

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

/// Gelişim / Arınma sekmelerinin üstünde — her iki sekmede görünür.
class _HubNefesEgzersiziRow extends StatelessWidget {
  const _HubNefesEgzersiziRow({required this.summary});

  final List<({HabitModel habit, int streak, bool completedToday})> summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? quitId;
    for (final e in summary) {
      if (e.habit.isArchived) continue;
      if (WillpowerTemplates.isFullQuitProgram(e.habit.templateId) &&
          _isArinmaReadyForHub(e.habit)) {
        quitId = e.habit.id;
        break;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ArinmaBreathingOrbButton(
            onTap: () {
              HapticFeedback.lightImpact();
              if (quitId != null) {
                context.push(AppRoutes.willBreathing(quitId));
              } else {
                context.push(AppRoutes.willBreathing());
              }
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.willpowerHubBreathingExerciseTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.shellOnCanvasPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.willpowerHubBreathingExerciseSubtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.shellOnCanvasSecondary(context),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 60.ms, duration: 320.ms);
  }
}

bool _hasQuitClockStarted(HabitModel h) =>
    h.quitClockStartedAtIso != null && h.quitClockStartedAtIso!.isNotEmpty;

/// Arınma kartının hub metriklerinde "aktif" sayılma kuralı:
/// - onboarding tamamlandıysa aktif
/// - hızlı başlat ile sayaç başladıysa da aktif
bool _isArinmaReadyForHub(HabitModel h) {
  if (!WillpowerTemplates.isFullQuitProgram(h.templateId)) {
    return h.onboardingCompleted;
  }
  return h.onboardingCompleted || _hasQuitClockStarted(h);
}

/// Sigara kartı — her saniye canlı, belirgin geçiş + hafif “vuruş” ölçeği.
/// Sayaç görüntüsü — kendi Timer'ını taşır; ana sayfa saniyede bir rebuild edilmez.
/// `clockStartedAt` null ise timer çalışmaz.
class _QuitHubLiveTimer extends StatefulWidget {
  const _QuitHubLiveTimer({
    required this.clockStartedAt,
    required this.format,
  });

  final DateTime? clockStartedAt;
  final String Function(Duration) format;

  @override
  State<_QuitHubLiveTimer> createState() => _QuitHubLiveTimerState();
}

class _QuitHubLiveTimerState extends State<_QuitHubLiveTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    if (widget.clockStartedAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(_updateElapsed);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _QuitHubLiveTimer old) {
    super.didUpdateWidget(old);
    if (old.clockStartedAt != widget.clockStartedAt) {
      _timer?.cancel();
      _updateElapsed();
      if (widget.clockStartedAt != null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(_updateElapsed);
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final start = widget.clockStartedAt;
    if (start == null) {
      _elapsed = Duration.zero;
      return;
    }
    final d = DateTime.now().difference(start);
    _elapsed = d.isNegative ? Duration.zero : d;
  }

  @override
  Widget build(BuildContext context) {
    final sec = _elapsed.inSeconds;
    final label = widget.format(_elapsed);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final t = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return ClipRect(
          child: FadeTransition(
            opacity: t,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(t),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.86, end: 1.0).animate(t),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Text(
        label,
        key: ValueKey<int>(sec),
        style: AppTextStyles.labelLarge.copyWith(
          color: _kQuitHubTimerElite,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: 0.55,
          fontSize: 15,
          fontFeatures: const [FontFeature.tabularFigures()],
          shadows: [
            Shadow(
              color: _kQuitHubTimerElite.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      )
          .animate(key: ValueKey<int>(sec))
          .scale(
            duration: 320.ms,
            begin: const Offset(1.1, 1.1),
            curve: Curves.easeOutBack,
          ),
    );
  }
}

/// Aynı `templateId` ile birden fazla Arınma kaydı varsa (eski hata / veri) tek satırda göster.
({HabitModel habit, int streak, bool completedToday}) _pickBetterQuitDuplicate(
  ({HabitModel habit, int streak, bool completedToday}) a,
  ({HabitModel habit, int streak, bool completedToday}) b,
) {
  if (a.habit.onboardingCompleted != b.habit.onboardingCompleted) {
    return a.habit.onboardingCompleted ? a : b;
  }
  final aClock = _hasQuitClockStarted(a.habit);
  final bClock = _hasQuitClockStarted(b.habit);
  if (aClock != bClock) return aClock ? a : b;
  return a.habit.createdAt.compareTo(b.habit.createdAt) >= 0 ? a : b;
}

List<({HabitModel habit, int streak, bool completedToday})>
_dedupeArinmaByTemplateId(
  List<({HabitModel habit, int streak, bool completedToday})> items,
) {
  final map = <String, ({HabitModel habit, int streak, bool completedToday})>{};
  final custom = <({HabitModel habit, int streak, bool completedToday})>[];
  for (final e in items) {
    final tid = e.habit.templateId;
    if (tid.isEmpty || tid == WillpowerTemplates.customTracked) {
      custom.add(e);
      continue;
    }
    final prev = map[tid];
    map[tid] = prev == null ? e : _pickBetterQuitDuplicate(prev, e);
  }
  return [...custom, ...map.values];
}

Future<void> _confirmDeleteHabitHub(
  BuildContext context,
  WidgetRef ref,
  String habitId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.anthraciteMid,
      title: Text(
        l10n.willpowerHubArchiveHabitDialogTitle,
        style: AppTextStyles.headlineSmall.copyWith(color: AppColors.creamBase),
      ),
      content: Text(
        l10n.willpowerHubArchiveHabitDialogBody,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textOnDarkMuted,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            l10n.commonCancel,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.creamBase,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: _kQuitAccent),
          child: Text(
            l10n.willpowerHubArchiveAction,
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await HabitCloudSyncService.rememberDeletedHabitId(habitId: habitId);
    await ref
        .read(habitSummaryProvider.notifier)
        .deleteHabitPermanently(habitId);
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid != null && uid.isNotEmpty) {
      await HabitCloudSyncService.deleteHabitCloudData(
        uid: uid,
        habitId: habitId,
      );
    }
  }
}

class WillpowerHubPage extends ConsumerStatefulWidget {
  const WillpowerHubPage({super.key});

  @override
  ConsumerState<WillpowerHubPage> createState() => _WillpowerHubPageState();
}

class _WillpowerHubPageState extends ConsumerState<WillpowerHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _willHubUriSynced;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trySalatWeekCelebrate();
    });
  }

  Future<void> _trySalatWeekCelebrate() async {
    if (!mounted) return;
    final summary = ref.read(habitSummaryProvider);
    for (final e in summary) {
      if (e.habit.templateId == WillpowerTemplates.salatDaily &&
          !e.habit.isArchived) {
        await SalatCelebration.tryShowForPreviousWeek(
          context: context,
          ref: ref,
          habit: e.habit,
        );
      }
    }
  }

  void _onTabTick() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      ref.read(willpowerHubReturnToArinmaProvider.notifier).state = false;
    }
    _syncHubQueryWithTab();
    setState(() {});
  }

  void _syncHubQueryWithTab() {
    if (!mounted) return;
    final route = GoRouterState.of(context);
    if (route.uri.path != AppRoutes.habits) return;
    final desired = _tabController.index == 1 ? 'arinma' : 'gelisim';
    if (route.uri.queryParameters['tab'] == desired) return;
    final target = _tabController.index == 1
        ? AppRoutes.habitsArinmaTab
        : AppRoutes.habitsGelisimTab;
    _willHubUriSynced = Uri.parse(target).toString();
    context.go(target);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabTick);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = GoRouterState.of(context);
    if (route.uri.path != AppRoutes.habits) return;
    final loc = route.uri.toString();
    if (loc == _willHubUriSynced) return;
    _willHubUriSynced = loc;
    if (route.uri.queryParameters['tab'] == 'arinma') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_tabController.index != 1) {
          _tabController.index = 1;
        }
      });
    } else if (route.uri.queryParameters['tab'] == 'gelisim') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_tabController.index != 0) {
          _tabController.index = 0;
        }
      });
    }
  }

  bool get _isBuildTab => _tabController.index == 0;

  Color get _tabAccent =>
      _isBuildTab ? AppColors.accentNeonGreen : _kQuitAccent;

  List<({HabitModel habit, int streak, bool completedToday})> _filtered(
    List<({HabitModel habit, int streak, bool completedToday})> summary,
  ) {
    return summary.where((e) {
      if (e.habit.isArchived) return false;
      if (_isBuildTab) return e.habit.type == HabitType.good;
      return e.habit.type == HabitType.bad;
    }).toList();
  }

  double _todayProgressPercent(
    WidgetRef ref,
    List<({HabitModel habit, int streak, bool completedToday})> filtered, {
    required bool buildTab,
    required DateTime salatStorageDay,
  }) {
    final active = filtered.where((e) {
      if (e.habit.type == HabitType.bad && !_isArinmaReadyForHub(e.habit)) {
        return false;
      }
      return true;
    }).toList();
    if (active.isEmpty) return 0;

    final salat = ref.read(salatLogRepositoryProvider);
    final repo = ref.read(habitRepositoryProvider);

    double progressFor(
      ({HabitModel habit, int streak, bool completedToday}) e,
    ) {
      if (buildTab) {
        if (e.habit.templateId == WillpowerTemplates.salatDaily) {
          final n = salat.countDone(e.habit.id, salatStorageDay);
          return (n / 5) * 100;
        }
        if (e.habit.isCustomTracked) {
          final p = repo.todayProgressValue(e.habit.id);
          final t = e.habit.effectiveDailyTarget;
          return (p / t * 100).clamp(0.0, 100.0);
        }
        return e.completedToday ? 100.0 : 0.0;
      }
      // Arınma: tam bırakma — günlük tik yok; sayaç süresine göre (365 günde %100).
      if (WillpowerTemplates.isFullQuitProgram(e.habit.templateId)) {
        final d = repo.quitElapsedSinceClock(e.habit.id);
        if (d == null) return 0.0;
        final sec = d.inSeconds.clamp(0, _kQuitHubProgressYearSeconds);
        return (sec / _kQuitHubProgressYearSeconds * 100).clamp(0.0, 100.0);
      }
      return e.completedToday ? 100.0 : 0.0;
    }

    final sum = active.fold<double>(0, (a, e) => a + progressFor(e));
    return sum / active.length;
  }

  int _activeCount(
    List<({HabitModel habit, int streak, bool completedToday})> filtered,
  ) {
    return filtered.where((e) {
      if (e.habit.type == HabitType.bad && !_isArinmaReadyForHub(e.habit)) {
        return false;
      }
      return true;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(habitSummaryProvider);
    final slice = _filtered(summary);
    final sliceForMetrics = _isBuildTab
        ? slice
        : _dedupeArinmaByTemplateId(slice);
    final pct = _todayProgressPercent(
      ref,
      sliceForMetrics,
      buildTab: _isBuildTab,
      salatStorageDay: ref
          .watch(prayerTimesProvider)
          .maybeWhen(
            data: (pt) => pt.salatTickCalendarDay(DateTime.now()),
            orElse: () {
              final now = DateTime.now();
              return DateTime(now.year, now.month, now.day);
            },
          ),
    );
    final active = _activeCount(sliceForMetrics);
    final good = summary.where((e) => e.habit.type == HabitType.good).toList();
    final bad = _dedupeArinmaByTemplateId(
      summary
          .where((e) => e.habit.type == HabitType.bad && !e.habit.isArchived)
          .toList(),
    );

    final hubFabBottom = ArinShellLayout.fabCornerBottomFromScreenBottom(
      context,
    );
    final hubScrollBottomPad = ArinShellLayout.willpowerHubScrollBottomPadding(
      context,
    );

    Widget hubFabButton() {
      return Material(
        elevation: 12,
        shadowColor: _tabAccent.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            if (_isBuildTab) {
              context.push(AppRoutes.habitManagement);
            } else {
              ref.read(willpowerHubReturnToArinmaProvider.notifier).state =
                  true;
              context.push(AppRoutes.willQuitTemplates);
            }
          },
          child: Ink(
            width: ArinShellLayout.willpowerHubFabSize,
            height: ArinShellLayout.willpowerHubFabSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_tabAccent, _tabAccent.withValues(alpha: 0.75)],
              ),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: ArinShellBackground.backdropLayer(context)),
          SafeArea(
            bottom: false,
            child: NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                    sliver: SliverAppBar(
                      pinned: true,
                      stretch: true,
                      stretchTriggerOffset: 100,
                      toolbarHeight: 0,
                      scrolledUnderElevation: 0,
                      surfaceTintColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      automaticallyImplyLeading: false,

                      /// Üst blok ≈ başlık + kart + nefes; alt pill `bottom` (~60).
                      /// Arınma: özet kartı + üçgen biraz daha yüksek; aksi halde pill Nefes üstüne biner.
                      expandedHeight: _isBuildTab ? 436 : 478,
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        centerTitle: false,
                        background: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    6,
                                    6,
                                    2,
                                    8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 3,
                                              ),
                                              child: _TriangleTrio(
                                                accent: _tabAccent,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                        l10n.willpowerHubHeaderTitle,
                                                        style: AppTextStyles
                                                            .headlineLarge
                                                            .copyWith(
                                                              color:
                                                                  AppColors.shellOnCanvasPrimary(
                                                                    context,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 21,
                                                              letterSpacing:
                                                                  -0.45,
                                                              height: 1.2,
                                                            ),
                                                      )
                                                      .animate()
                                                      .fadeIn(duration: 400.ms)
                                                      .slideY(begin: 0.04),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    active == 0
                                                        ? l10n.willpowerHubNoActiveHabits
                                                        : l10n.willpowerHubActiveHabits(
                                                            active,
                                                          ),
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                          color:
                                                              AppColors.shellOnCanvasSecondary(
                                                                context,
                                                              ),
                                                          fontSize: 13,
                                                          height: 1.35,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                  ).animate().fadeIn(
                                                    delay: 80.ms,
                                                    duration: 400.ms,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Tooltip(
                                        message: l10n
                                            .willpowerHubHabitCalendarTooltip,
                                        child: Material(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.black.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.white.withValues(
                                                  alpha: 0.09,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              context.push(
                                                AppRoutes.habitCalendar,
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(11),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color:
                                                      AppColors.shellOnCanvasPrimary(
                                                        context,
                                                      ).withValues(alpha: 0.2),
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.calendar_today_rounded,
                                                size: 20,
                                                color:
                                                    AppColors.shellOnCanvasPrimary(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    2,
                                    4,
                                    12,
                                  ),
                                  child: _SummaryProgressCard(
                                    percent: pct,
                                    accent: _tabAccent,
                                    // Dusuk yuzdelerde (%13 gibi) cizgi aninda
                                    // gorunsun: Gelişim kartinda da oransal dolum.
                                    smoothTriangle: true,
                                    quitTab: !_isBuildTab,
                                  ),
                                ).animate().fadeIn(
                                  delay: 80.ms,
                                  duration: 320.ms,
                                ),
                                _HubNefesEgzersiziRow(summary: summary),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(60),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: AnimatedBuilder(
                            animation:
                                _tabController.animation ?? _tabController,
                            builder: (context, _) {
                              final t =
                                  _tabController.animation?.value ??
                                  _tabController.index.toDouble();
                              return _HubPillTabs(
                                controller: _tabController,
                                dragPosition: t,
                                accent: _tabAccent,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: Stack(
                fit: StackFit.expand,
                children: [
                  TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Builder(
                        builder: (ctx) => _BuildTab(
                          items: good,
                          bottomPadding: hubScrollBottomPad,
                          segmentAccent: AppColors.accentNeonGreen,
                          onOpenHabitManagement: () =>
                              context.push(AppRoutes.habitManagement),
                          sliverPrefix: [
                            SliverOverlapInjector(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    ctx,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (ctx) => _QuitTab(
                          items: bad,
                          bottomPadding: hubScrollBottomPad,
                          segmentAccent: _kQuitAccent,
                          onPickTemplates: () {
                            ref
                                    .read(
                                      willpowerHubReturnToArinmaProvider
                                          .notifier,
                                    )
                                    .state =
                                true;
                            context.push(AppRoutes.willQuitTemplates);
                          },
                          sliverPrefix: [
                            SliverOverlapInjector(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    ctx,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const _HubScrollBottomFade(),
                ],
              ),
            ),
          ),
          Positioned(right: 16, bottom: hubFabBottom, child: hubFabButton()),
        ],
      ),
    );
  }
}

/// Liste kaydırılınca alt kenarın kabuk/gradient ile yumuşak kaybolması (şeffaf → zemin).
class _HubScrollBottomFade extends StatelessWidget {
  const _HubScrollBottomFade();

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 104,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: light
                    ? [
                        Colors.white.withValues(alpha: 0),
                        const Color(0xFFF4F6F3).withValues(alpha: 0.5),
                        const Color(0xFFE8ECE9).withValues(alpha: 0.88),
                      ]
                    : [
                        const Color(0xFF050A07).withValues(alpha: 0),
                        const Color(0xFF030806).withValues(alpha: 0.38),
                        const Color(0xFF050A07).withValues(alpha: 0.72),
                      ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// NOT: Eski `_HubBackground` ve `_SoftTriangleWatermarkPainter` sınıfları
// v3 "Hub Match" ile `ArinShellBackground.backdropLayer` içine taşındı.
// Shell ile piksel-eş olsun ve tek kaynaktan beslensin diye buradan silindi.
// Eski davranışa dönüş: `core/theme/arin_shell_background.dart` baş yorumundaki
// geri alma talimatlarına bak.

/// İki sekmeli pill kontrol; sürüklerken `TabController.animation` ile kayar vurgu.
class _HubPillTabs extends StatelessWidget {
  const _HubPillTabs({
    required this.controller,
    required this.dragPosition,
    required this.accent,
  });

  final TabController controller;
  final double dragPosition;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onLight = Theme.of(context).brightness == Brightness.light;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        const outerPad = 4.0;
        final innerW = maxW - outerPad * 2;
        final segW = innerW / 2;
        final t = dragPosition.clamp(0.0, 1.0);
        final dim = AppColors.shellOnCanvasSecondary(context);
        final hi = AppColors.shellOnCanvasPrimary(context);

        // Opak yüzey: kaydırınca alttaki kart/“Nefes” metni süzmeyle Gelişim/Arınma ile binmesin.
        return Material(
          elevation: onLight ? 2 : 6,
          shadowColor: Colors.black.withValues(alpha: onLight ? 0.12 : 0.45),
          borderRadius: BorderRadius.circular(22),
          color: onLight ? const Color(0xFFF4F6F3) : const Color(0xFF0D1812),
          child: Container(
            padding: const EdgeInsets.all(outerPad),
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: onLight
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: outerPad + t * segW,
                  top: 0,
                  bottom: 0,
                  width: segW,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: accent.withValues(alpha: 0.22),
                      border: Border.all(color: accent.withValues(alpha: 0.38)),
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
                            l10n.willpowerHubTabBuild,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.15,
                              color: Color.lerp(
                                dim.withValues(alpha: 0.55),
                                hi,
                                1 - t,
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
                            l10n.willpowerHubTabQuit,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.15,
                              color: Color.lerp(
                                dim.withValues(alpha: 0.55),
                                hi,
                                t,
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
          ),
        );
      },
    );
  }
}

/// Üç küçük üçgen — başlık ve ilham bölümünde ortak motif.
class _TriangleTrio extends StatelessWidget {
  const _TriangleTrio({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniTriangle(color: accent.withValues(alpha: 0.35)),
        const SizedBox(width: 5),
        _MiniTriangle(color: accent.withValues(alpha: 0.55)),
        const SizedBox(width: 5),
        _MiniTriangle(color: accent.withValues(alpha: 0.85)),
      ],
    );
  }
}

class _MiniTriangle extends StatelessWidget {
  const _MiniTriangle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(9, 10),
      painter: _FilledUpTrianglePainter(color: color),
    );
  }
}

class _FilledUpTrianglePainter extends CustomPainter {
  const _FilledUpTrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _FilledUpTrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// İç dolgu yok: üçgen sadece kontur. Çevre, 5 eşit parçada (≈ her vakit) parça parça yeşiller.
class _HubTriangleProgressPainter extends CustomPainter {
  _HubTriangleProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 2.6,
    this.smoothFill = false,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  /// true: çevre boyunca sürekli dolgu (Arınma / sayaç). false: 5 parça (Gelişim / namaz hissi).
  final bool smoothFill;

  Path _trianglePath(Size size) {
    final pad = strokeWidth * 0.5 + 3;
    final w = size.width - 2 * pad;
    final h = size.height - 2 * pad;
    if (w <= 4 || h <= 4) return Path();
    // Çevre ölçümü: taban soldan sağa → sağ kenar → sol kenar (kapanış).
    return Path()
      ..moveTo(pad, pad + h)
      ..lineTo(pad + w, pad + h)
      ..lineTo(pad + w / 2, pad)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _trianglePath(size);
    final p = progress.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    final litPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, trackPaint);

    for (final metric in path.computeMetrics()) {
      final len = metric.length;
      if (smoothFill) {
        final litLen = len * p;
        if (litLen > 0) {
          canvas.drawPath(metric.extractPath(0, litLen), litPaint);
        }
      } else {
        final steps = (p * 5).floor().clamp(0, 5);
        if (steps == 0) return;
        final litLen = len * (steps / 5.0);
        canvas.drawPath(metric.extractPath(0, litLen), litPaint);
      }
      break;
    }
  }

  @override
  bool shouldRepaint(covariant _HubTriangleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.smoothFill != smoothFill;
}

class _SummaryProgressCard extends StatelessWidget {
  const _SummaryProgressCard({
    required this.percent,
    required this.accent,
    this.smoothTriangle = false,
    this.quitTab = false,
  });

  final double percent;
  final Color accent;
  final bool smoothTriangle;
  final bool quitTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = (percent / 100).clamp(0.0, 1.0);
    final onLight = Theme.of(context).brightness == Brightness.light;
    final cta = quitTab
        ? (percent < 5
              ? l10n.willpowerHubQuitCtaEarly
              : l10n.willpowerHubQuitCtaOngoing)
        : (percent < 50
              ? l10n.willpowerHubBuildCtaEarly
              : l10n.willpowerHubBuildCtaOngoing);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: onLight
            ? Colors.black.withValues(alpha: 0.045)
            : Colors.white.withValues(alpha: 0.035),
        border: Border.all(
          color: onLight
              ? Colors.black.withValues(alpha: 0.09)
              : Colors.white.withValues(alpha: 0.065),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quitTab
                      ? l10n.willpowerHubSummaryQuitLabel
                      : l10n.willpowerHubSummaryTodayLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.shellOnCanvasSecondary(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${percent.round()}%',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.shellOnCanvasPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 40,
                    height: 1,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  quitTab
                      ? l10n.willpowerHubSummaryCounterProgress
                      : l10n.willpowerHubSummaryCompleted,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.shellOnCanvasSecondary(context),
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  cta,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.shellOnCanvasTertiary(context),
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            height: 98,
            child: CustomPaint(
              painter: _HubTriangleProgressPainter(
                progress: p,
                trackColor: onLight
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.09),
                progressColor: accent,
                strokeWidth: 2.6,
                smoothFill: smoothTriangle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitInsightsSection extends StatelessWidget {
  const _HabitInsightsSection({
    required this.bundle,
    required this.motifAccent,
    this.catalogLoading = false,
    this.loadingIndicatorColor,
  });

  final HabitInsightBundle bundle;
  final Color motifAccent;
  final bool catalogLoading;
  final Color? loadingIndicatorColor;

  @override
  Widget build(BuildContext context) {
    final onLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bundle.sectionTitle.trim().isNotEmpty ||
            bundle.contextSubtitle != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TriangleTrio(accent: motifAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bundle.sectionTitle.trim().isNotEmpty)
                      Text(
                        bundle.sectionTitle,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.shellOnCanvasPrimary(context),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.35,
                          height: 1.15,
                        ),
                      ),
                    if (bundle.contextSubtitle != null) ...[
                      if (bundle.sectionTitle.trim().isNotEmpty)
                        const SizedBox(height: 8),
                      Text(
                        bundle.contextSubtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.shellOnCanvasSecondary(context),
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ] else
          const SizedBox(height: 4),
        if (catalogLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: onLight
                    ? Colors.black.withValues(alpha: 0.06)
                    : const Color(0x18FFFFFF),
                color: loadingIndicatorColor ?? AppColors.accentNeonGreen,
              ),
            ),
          ),
        for (var i = 0; i < bundle.cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          _InsightCard(data: bundle.cards[i]),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.data});

  final HabitInsightCardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIslamic = data.isIslamic;
    final accent = isIslamic ? AppColors.goldAccent : _kInsightMedicalTint;
    final tag = isIslamic
        ? l10n.willpowerHubInsightTagSpiritual
        : l10n.willpowerHubInsightTagHealth;
    final onLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: onLight
            ? Colors.white.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: onLight
              ? Colors.black.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.065),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniTriangle(color: accent.withValues(alpha: 0.9)),
              const SizedBox(width: 10),
              Text(
                tag,
                style: AppTextStyles.labelSmall.copyWith(
                  color: accent.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.shellOnCanvasPrimary(context),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.shellOnCanvasSecondary(context),
                height: 1.55,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text: '“',
                  style: TextStyle(
                    color: onLight
                        ? AppColors.emeraldDark.withValues(alpha: 0.35)
                        : AppColors.creamBase.withValues(alpha: 0.28),
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: data.body),
                TextSpan(
                  text: '”',
                  style: TextStyle(
                    color: onLight
                        ? AppColors.emeraldDark.withValues(alpha: 0.35)
                        : AppColors.creamBase.withValues(alpha: 0.28),
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isIslamic && data.reference != null) ...[
            const SizedBox(height: 14),
            Text(
              data.reference!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.goldAccent.withValues(alpha: 0.65),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          if (data.isMedical) ...[
            const SizedBox(height: 14),
            Text(
              medicalFootnote(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.shellOnCanvasSecondary(
                  context,
                ).withValues(alpha: 0.85),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Boş gelişim alanı — kesik çizgili üçgen çerçeve.
class _DashedTriangleEmpty extends StatelessWidget {
  const _DashedTriangleEmpty({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onLight = Theme.of(context).brightness == Brightness.light;
    return CustomPaint(
      painter: _DashedTrianglePainter(
        color: AppColors.shellOnCanvasPrimary(
          context,
        ).withValues(alpha: onLight ? 0.28 : 0.22),
      ),
      child: SizedBox(width: 132, height: 118, child: Center(child: child)),
    );
  }
}

class _DashedTrianglePainter extends CustomPainter {
  _DashedTrianglePainter({required this.color});

  final Color color;

  static void _strokeDashes(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint,
    double dash,
    double gap,
  ) {
    final d = b - a;
    final len = d.distance;
    if (len < 0.001) return;
    final dir = d / len;
    var pos = 0.0;
    while (pos < len) {
      final seg = math.min(dash, len - pos);
      canvas.drawLine(a + dir * pos, a + dir * (pos + seg), paint);
      pos += dash + gap;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 5.0;
    final w = size.width - 2 * pad;
    final h = size.height - 2 * pad;
    final top = Offset(pad + w / 2, pad);
    final br = Offset(pad + w, pad + h);
    final bl = Offset(pad, pad + h);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 7.0;
    const gap = 5.0;
    _strokeDashes(canvas, top, br, paint, dash, gap);
    _strokeDashes(canvas, br, bl, paint, dash, gap);
    _strokeDashes(canvas, bl, top, paint, dash, gap);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GelisimEmptyCtaButton extends StatelessWidget {
  const _GelisimEmptyCtaButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = AppColors.accentNeonGreen;
    final labelC = AppColors.shellOnCanvasPrimary(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withValues(alpha: 0.15),
        highlightColor: accent.withValues(alpha: 0.08),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.5),
              width: 1.25,
            ),
            color: accent.withValues(alpha: 0.07),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(11, 12),
                painter: _FilledUpTrianglePainter(
                  color: accent.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.willpowerHubAddFirstBuild,
                style: AppTextStyles.labelLarge.copyWith(
                  color: labelC,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Boş arınma alanı CTA — gelişim CTA ile aynı çerçeve/his, kırmızı vurgu.
class _ArinmaEmptyCtaButton extends StatelessWidget {
  const _ArinmaEmptyCtaButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = _kQuitAccent;
    final labelC = AppColors.shellOnCanvasPrimary(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withValues(alpha: 0.15),
        highlightColor: accent.withValues(alpha: 0.08),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.5),
              width: 1.25,
            ),
            color: accent.withValues(alpha: 0.07),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(11, 12),
                painter: _FilledUpTrianglePainter(
                  color: accent.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.willpowerHubAddFirstQuit,
                style: AppTextStyles.labelLarge.copyWith(
                  color: labelC,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildTab extends ConsumerWidget {
  const _BuildTab({
    required this.items,
    required this.bottomPadding,
    required this.segmentAccent,
    required this.onOpenHabitManagement,
    this.sliverPrefix = const [],
  });

  final List<({HabitModel habit, int streak, bool completedToday})> items;
  final double bottomPadding;
  final Color segmentAccent;
  final VoidCallback onOpenHabitManagement;
  final List<Widget> sliverPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final catalogAsync = ref.watch(habitInsightsCatalogProvider);
    final catalog = catalogAsync.when(
      data: (c) => c,
      loading: () => HabitInsightsCatalog.embeddedSync(),
      error: (_, __) => HabitInsightsCatalog.embeddedSync(),
    );
    final quotePools = ref.watch(habitInsightQuotePoolsProvider).valueOrNull;
    final HabitInsightCardReplacer? insightCardReplacer =
        quotePools != null && quotePools.isUsable
        ? (bundleKey, _) =>
              quotePools.dailyPair(bundleKey, DateTime.now(), quitTab: false)
        : null;
    final insightBundle = resolveHabitInsights(
      catalog: catalog,
      quitTab: false,
      items: items,
      cardReplacer: insightCardReplacer,
    );

    final nonSalatItems = items
        .where((e) => e.habit.templateId != WillpowerTemplates.salatDaily)
        .toList();
    final salatItems = items
        .where((e) => e.habit.templateId == WillpowerTemplates.salatDaily)
        .toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        ...sliverPrefix,
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        // Yalnızca Rutin atölyesinde Kaza seçilip kurulunca (prefs bayrağı).
        if (ref.watch(kazaTrackingProvider).hubEnabled)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _KazaHubCompactCard(),
            ),
          ),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, 8, 28, bottomPadding),
              child:
                  Column(
                        children: [
                          _DashedTriangleEmpty(
                            child: Icon(
                              Icons.add_rounded,
                              size: 40,
                              color: AppColors.shellOnCanvasSecondary(
                                context,
                              ).withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.willpowerHubBuildEmptyTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.shellOnCanvasPrimary(context),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.willpowerHubBuildEmptySubtitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.shellOnCanvasSecondary(context),
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: _GelisimEmptyCtaButton(
                              onPressed: onOpenHabitManagement,
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 420.ms)
                      .scale(
                        begin: const Offset(0.97, 0.97),
                        curve: Curves.easeOutCubic,
                      ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                if (i < nonSalatItems.length) {
                  final e = nonSalatItems[i];
                  return _hubListTileEntrance(
                    index: i,
                    emphasis: e.habit.isCustomTracked,
                    child: _WillHabitTile(
                      item: e,
                      onToggle: () => ref
                          .read(habitSummaryProvider.notifier)
                          .toggleToday(e.habit.id),
                      onDelete: () =>
                          _confirmDeleteHabitHub(context, ref, e.habit.id),
                      onOpen: () {
                        if (e.habit.isCustomTracked) {
                          context.push(AppRoutes.customHabitDetail(e.habit.id));
                          return;
                        }
                        if (e.habit.templateId ==
                            WillpowerTemplates.quranDaily) {
                          context.push(AppRoutes.willBuildDetail(e.habit.id));
                        } else if (e.habit.templateId ==
                            WillpowerTemplates.salatDaily) {
                          context.push(AppRoutes.willNamaz(e.habit.id));
                        }
                      },
                    ),
                  );
                }
                final si = i - nonSalatItems.length;
                final e = salatItems[si];
                return _hubListTileEntrance(
                  index: i,
                  emphasis: e.habit.isCustomTracked,
                  child: _WillHabitTile(
                    item: e,
                    embedSalatPrayerRow: true,
                    gelisimHubCardHeight: _kHubKazaNamazCardHeight,
                    onToggle: () => ref
                        .read(habitSummaryProvider.notifier)
                        .toggleToday(e.habit.id),
                    onDelete: () =>
                        _confirmDeleteHabitHub(context, ref, e.habit.id),
                    onOpen: () {
                      context.push(AppRoutes.willNamaz(e.habit.id));
                    },
                  ),
                );
              }, childCount: nonSalatItems.length + salatItems.length),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 32, 20, bottomPadding),
            child: _HabitInsightsSection(
              bundle: insightBundle,
              motifAccent: segmentAccent,
              catalogLoading: catalogAsync.isLoading,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gelişim kartında 6 vakit — kısa başlık + sayı.
List<String> _kazaHubVakitShortLabels(AppLocalizations l10n) => [
  l10n.willpowerHubKazaLabelSabah,
  l10n.willpowerHubKazaLabelOgle,
  l10n.willpowerHubKazaLabelIkindi,
  l10n.willpowerHubKazaLabelAksam,
  l10n.willpowerHubKazaLabelYatsi,
  l10n.willpowerHubKazaLabelVitir,
];

/// Kaza hub kartı ile günlük namaz üst karosu (çerçeveli alan) aynı piksel yüksekliği.
/// Namaz kartında üst başlık + içte vakit satırı; kaza ile aynı yükseklik.
const double _kHubKazaNamazCardHeight = 142;

/// İki kartta da ana içerik (sayı / başlık bloğu) ile alt vakit satırı arası — Spacer yerine sabit.
const double _kHubKazaNamazMainToBottomGap = 8;

class _KazaHubCompactCard extends ConsumerWidget {
  const _KazaHubCompactCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final s = ref.watch(kazaTrackingProvider);
    final onLight = ArinShellBackground.isLight(context);
    final primary = AppColors.shellOnCanvasPrimary(context);
    final secondary = AppColors.shellOnCanvasSecondary(context);
    final trashColor = secondary.withValues(alpha: 0.55);

    return SizedBox(
          height: _kHubKazaNamazCardHeight,
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                final st = ref.read(kazaTrackingProvider);
                if (st.total > 0 || st.hasEverCalculated) {
                  context.push(AppRoutes.kazaTracker);
                } else {
                  context.push(AppRoutes.kazaCalculator);
                }
              },
              borderRadius: BorderRadius.circular(16),
              splashColor: AppColors.accentNeonGreen.withValues(alpha: 0.14),
              highlightColor: AppColors.accentNeonGreen.withValues(alpha: 0.07),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: onLight
                      ? Colors.white.withValues(alpha: 0.92)
                      : _kCardSurface.withValues(alpha: 0.72),
                  border: Border.all(
                    color: onLight
                        ? AppColors.emeraldDark.withValues(alpha: 0.38)
                        : AppColors.emeraldDark.withValues(alpha: 0.72),
                    width: 1.15,
                  ),
                  boxShadow: onLight
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.layers_rounded,
                        size: 22,
                        color: AppColors.accentNeonGreen.withValues(
                          alpha: 0.92,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.willpowerHubKazaTrackingTitle,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${s.total}',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                    letterSpacing: -0.6,
                                    color: AppColors.accentNeonGreen,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  l10n.willpowerHubKazaRemainingLabel,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: _kHubKazaNamazMainToBottomGap,
                            ),
                            Row(
                              children: List.generate(6, (i) {
                                final n = s.counts[i];
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: i == 0 ? 0 : 1,
                                      right: i == 5 ? 0 : 1,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _kazaHubVakitShortLabels(l10n)[i],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                fontSize: 8.5,
                                                height: 1.05,
                                                color: secondary.withValues(
                                                  alpha: 0.72,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.2,
                                              ),
                                        ),
                                        const SizedBox(height: 3),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '$n',
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.labelLarge
                                                .copyWith(
                                                  fontSize: 11,
                                                  height: 1.0,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors
                                                      .accentNeonGreen
                                                      .withValues(alpha: 0.96),
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.willpowerHubRemoveCardTooltip,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _confirmHideKazaHubCard(context, ref);
                        },
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: trashColor,
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
        .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.04, duration: 360.ms, curve: Curves.easeOutCubic);
  }
}

Future<void> _confirmHideKazaHubCard(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final onLight = ArinShellBackground.isLight(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: onLight
          ? const Color(0xFFF2F4F3)
          : AppColors.anthraciteMid,
      title: Text(
        l10n.willpowerHubHideKazaDialogTitle,
        style: AppTextStyles.titleSmall.copyWith(
          color: onLight ? AppColors.emeraldDark : AppColors.creamBase,
        ),
      ),
      content: Text(
        l10n.willpowerHubHideKazaDialogBody,
        style: AppTextStyles.bodySmall.copyWith(
          color: onLight
              ? AppColors.emeraldDark.withValues(alpha: 0.75)
              : AppColors.textOnDarkMuted,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            l10n.commonCancel,
            style: TextStyle(
              color: onLight
                  ? AppColors.emeraldDark.withValues(alpha: 0.65)
                  : AppColors.textOnDarkMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.willpowerHubRemoveAction,
            style: TextStyle(
              color: onLight
                  ? const Color(0xFFB85C5C)
                  : const Color(0xFFFF8A80),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await ref.read(kazaTrackingProvider.notifier).hideGelisimHubCard();
  }
}

/// Özel takip kartları için biraz daha belirgin giriş animasyonu.
Widget _hubListTileEntrance({
  required Widget child,
  required int index,
  required bool emphasis,
}) {
  if (emphasis) {
    return child
        .animate()
        .fadeIn(
          duration: 420.ms,
          delay: (index * 68).ms,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.08,
          duration: 460.ms,
          delay: (index * 68).ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.92, 0.92),
          duration: 520.ms,
          delay: (index * 52).ms,
          curve: Curves.easeOutBack,
        );
  }
  return child.animate().fadeIn(duration: 300.ms, delay: (index * 55).ms);
}

class _QuitTab extends ConsumerWidget {
  const _QuitTab({
    required this.items,
    required this.bottomPadding,
    required this.segmentAccent,
    required this.onPickTemplates,
    this.sliverPrefix = const [],
  });

  final List<({HabitModel habit, int streak, bool completedToday})> items;
  final double bottomPadding;
  final Color segmentAccent;
  final VoidCallback onPickTemplates;
  final List<Widget> sliverPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final catalogAsync = ref.watch(habitInsightsCatalogProvider);
    final catalog = catalogAsync.when(
      data: (c) => c,
      loading: () => HabitInsightsCatalog.embeddedSync(),
      error: (_, __) => HabitInsightsCatalog.embeddedSync(),
    );
    final quotePools = ref.watch(habitInsightQuotePoolsProvider).valueOrNull;
    final HabitInsightCardReplacer? insightCardReplacer =
        quotePools != null && quotePools.isUsable
        ? (bundleKey, _) =>
              quotePools.dailyPair(bundleKey, DateTime.now(), quitTab: true)
        : null;
    final insightBundle = resolveHabitInsights(
      catalog: catalog,
      quitTab: true,
      items: items,
      cardReplacer: insightCardReplacer,
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        ...sliverPrefix,
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, 8, 28, bottomPadding),
              child:
                  Column(
                        children: [
                          _DashedTriangleEmpty(
                            child: Icon(
                              Icons.add_rounded,
                              size: 40,
                              color: AppColors.shellOnCanvasSecondary(
                                context,
                              ).withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.willpowerHubQuitEmptyTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.shellOnCanvasPrimary(context),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.willpowerHubQuitEmptySubtitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.shellOnCanvasSecondary(context),
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: _ArinmaEmptyCtaButton(
                              onPressed: onPickTemplates,
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 420.ms)
                      .scale(
                        begin: const Offset(0.97, 0.97),
                        curve: Curves.easeOutCubic,
                      ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final e = items[i];
                return _hubListTileEntrance(
                  index: i,
                  emphasis: e.habit.isCustomTracked,
                  child: _WillHabitTile(
                    item: e,
                    onToggle: () => ref
                        .read(habitSummaryProvider.notifier)
                        .toggleToday(e.habit.id),
                    onDelete: () =>
                        _confirmDeleteHabitHub(context, ref, e.habit.id),
                    onOpen: () {
                      ref
                              .read(willpowerHubReturnToArinmaProvider.notifier)
                              .state =
                          true;
                      if (e.habit.isCustomTracked) {
                        context.push(AppRoutes.customHabitDetail(e.habit.id));
                        return;
                      }
                      if (WillpowerTemplates.isFullQuitProgram(
                        e.habit.templateId,
                      )) {
                        if (!_hasQuitClockStarted(e.habit) &&
                            !e.habit.onboardingCompleted) {
                          context.push(
                            AppRoutes.willQuitOnboarding(e.habit.id),
                          );
                        } else {
                          context.push(AppRoutes.willQuitHome(e.habit.id));
                        }
                      }
                    },
                  ),
                );
              }, childCount: items.length),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 32, 20, bottomPadding),
            child: _HabitInsightsSection(
              bundle: insightBundle,
              motifAccent: segmentAccent,
              catalogLoading: catalogAsync.isLoading,
              loadingIndicatorColor: _kQuitAccent,
            ),
          ),
        ),
      ],
    );
  }
}

/// İrade hub — özel takip kartı: dışarıdan tik yok; ilerleme özeti + animasyon.
class _CustomHabitHubProgress extends StatelessWidget {
  const _CustomHabitHubProgress({
    required this.habit,
    required this.progress,
    required this.target,
    required this.accent,
  });

  final HabitModel habit;
  final int progress;
  final int target;
  final Color accent;

  String _periodPrefix(AppLocalizations l10n) {
    switch (habit.customRepeatCycle.clamp(0, 2)) {
      case 1:
        return l10n.willpowerHubPeriodPrefixWeek;
      case 2:
        return l10n.willpowerHubPeriodPrefixMonth;
      default:
        return '';
    }
  }

  String _message(AppLocalizations l10n) {
    final p = _periodPrefix(l10n);
    final left = (target - progress).clamp(0, target);
    final u = habit.customUnit;

    if (habit.customTrackingKind == 2) {
      if (progress >= target) {
        return l10n.willpowerHubPercentTargetReached(p);
      }
      return l10n.willpowerHubPercentProgressStatus(p, progress, left);
    }

    if (habit.customTrackingKind == 1) {
      if (target <= 0) return l10n.willpowerHubTargetPending(p);
      if (progress <= 0) {
        return l10n.willpowerHubUnitTargetAddPrompt(p, target, u);
      }
      if (left <= 0) {
        return l10n.willpowerHubUnitProgressTargetFilled(p, progress, u);
      }
      return l10n.willpowerHubUnitProgressRemaining(p, progress, u, left);
    }

    if (target <= 0) return l10n.willpowerHubTargetPending(p);
    if (progress <= 0) {
      return l10n.willpowerHubUnitTargetAddPrompt(p, target, u);
    }
    if (left <= 0) {
      return l10n.willpowerHubUnitTargetDoneSuper(p, target, u);
    }
    return l10n.willpowerHubUnitProgressDidRemaining(p, progress, u, left);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final msg = _message(l10n);
    final frac = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey<String>('${progress}_$target'),
          tween: Tween(begin: 0, end: frac),
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              color: accent.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            );
          },
          child: Text(
            msg,
            key: ValueKey<String>(msg),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.creamBase.withValues(alpha: 0.9),
              height: 1.4,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ).animate().fadeIn(duration: 380.ms, curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 13,
              color: AppColors.textOnDarkMuted.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                l10n.willpowerHubAddEditHint,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textOnDarkMuted.withValues(alpha: 0.72),
                  fontSize: 10.5,
                  height: 1.25,
                  letterSpacing: 0.12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WillHabitTile extends ConsumerWidget {
  const _WillHabitTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onOpen,
    this.embedSalatPrayerRow = true,
    this.gelisimHubCardHeight,
  });

  final ({HabitModel habit, int streak, bool completedToday}) item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  /// Gelişim listesinde namaz kartı diğer alışkanlıklardan sonra; vakit satırı kartın dışında.
  final bool embedSalatPrayerRow;

  /// Kaza hub ile aynı yükseklikte üst karo (yalnızca Gelişim + günlük namaz + dış vakit satırı).
  final double? gelisimHubCardHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(habitSummaryProvider);
    final onLight = ArinShellBackground.isLight(context);
    final done = item.completedToday;
    final isBad = item.habit.type == HabitType.bad;
    final quitClockStarted = _hasQuitClockStarted(item.habit);
    final needsSetup =
        isBad && !item.habit.onboardingCompleted && !quitClockStarted;
    final isSalat = item.habit.templateId == WillpowerTemplates.salatDaily;
    final isFullQuit = WillpowerTemplates.isFullQuitProgram(
      item.habit.templateId,
    );
    final isCustom = item.habit.isCustomTracked;
    final repo = ref.read(habitRepositoryProvider);
    final customProgress = isCustom
        ? repo.todayProgressValue(item.habit.id)
        : 0;
    final customTarget = isCustom ? item.habit.effectiveDailyTarget : 1;
    final quitClockOn = isFullQuit && quitClockStarted;
    // quitElapsed artık _QuitHubLiveTimer içinde hesaplanıyor; burada yalnızca
    // başlangıç zamanını geçiyoruz, sayfa 1 Hz rebuild edilmiyor.
    final quitClockStartedAt = quitClockOn
        ? DateTime.tryParse(item.habit.quitClockStartedAtIso ?? '')
        : null;

    final useRichCard = (isFullQuit || isCustom) && !onLight;
    final useTallFooter =
        (isFullQuit && quitClockOn) || (isCustom && !needsSetup);

    final toggleAccent = isCustom
        ? (isBad ? _kQuitAccent : AppColors.accentNeonGreen)
        : AppColors.accentNeonGreen;
    final titleColor = isCustom
        ? (isBad
              ? _kQuitAccent.withValues(alpha: 0.96)
              : AppColors.accentNeonGreen.withValues(alpha: 0.96))
        : (onLight
              ? AppColors.shellOnCanvasPrimary(context)
              : AppColors.creamBase);

    final Color borderAccent;
    if (isCustom) {
      borderAccent = done
          ? (isBad
                ? _kQuitAccent.withValues(alpha: 0.48)
                : AppColors.accentNeonGreen.withValues(alpha: 0.45))
          : AppColors.creamBase.withValues(alpha: 0.14);
    } else if (isFullQuit && quitClockOn) {
      borderAccent = AppColors.creamBase.withValues(alpha: 0.14);
    } else {
      borderAccent = done
          ? AppColors.accentNeonGreen.withValues(alpha: 0.5)
          : (onLight
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.07));
    }

    final salatHubFixedCard = gelisimHubCardHeight != null && isSalat;

    final quitStatusLabel = isFullQuit
        ? (needsSetup
              ? l10n.willpowerHubQuitStatusSetupMissing
              : (quitClockOn ? null : l10n.willpowerHubQuitStatusProgramReady))
        : null;
    final quitStatusColor = needsSetup
        ? Colors.orange.shade300
        : (quitClockOn
              ? (onLight
                    ? AppColors.textSecondary.withValues(alpha: 0.82)
                    : AppColors.creamBase.withValues(alpha: 0.72))
              : AppColors.warning.withValues(alpha: 0.78));
    final fullQuitBadgeBg = onLight
        ? AppColors.emeraldDark.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.06);
    final fullQuitBadgeBorder = onLight
        ? AppColors.emeraldDark.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.1);
    final fullQuitBadgeIcon = onLight
        ? AppColors.emeraldDark.withValues(alpha: 0.5)
        : AppColors.creamBase.withValues(alpha: 0.48);
    final fullQuitHintColor = onLight
        ? AppColors.textSecondary.withValues(alpha: 0.82)
        : AppColors.textOnDarkMuted.withValues(alpha: 0.75);
    final fullQuitChevronColor = onLight
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : AppColors.creamBase.withValues(alpha: 0.28);
    final fullQuitRestartIconColor = onLight
        ? AppColors.textSecondary.withValues(alpha: 0.78)
        : AppColors.creamBase.withValues(alpha: 0.5);
    final fullQuitRestartLabelColor = onLight
        ? AppColors.textSecondary.withValues(alpha: 0.86)
        : AppColors.creamBase.withValues(alpha: 0.58);
    final fullQuitRestartBorderColor = onLight
        ? AppColors.emeraldDark.withValues(alpha: 0.18)
        : AppColors.creamBase.withValues(alpha: 0.26);

    /// Tam arınma + sayaç: “Yeniden başla” aynı satırda metni sıkıştırıyordu; ikinci satıra al.
    final quitHubTwoLine = isFullQuit && quitClockOn;
    final double cardBottomPadding = isSalat
        ? 4
        : (quitHubTwoLine ? 16 : (useTallFooter ? 40 : (isFullQuit ? 40 : 14)));

    final materialWidget = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: isSalat
            ? const BorderRadius.vertical(top: Radius.circular(16))
            : BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            useRichCard ? 20 : (isSalat ? 8 : 14),
            14,
            cardBottomPadding,
          ),
          child: quitHubTwoLine
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: fullQuitBadgeBg,
                            border: Border.all(color: fullQuitBadgeBorder),
                          ),
                          child:
                              item.habit.templateId ==
                                  WillpowerTemplates.quitSmoking
                              ? Icon(
                                  Icons.smoke_free_rounded,
                                  size: 30,
                                  color: fullQuitBadgeIcon,
                                )
                              : Text(
                                  item.habit.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
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
                                      _localizedHabitTitle(l10n, item.habit),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                  if (quitStatusLabel != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Transform.translate(
                                        offset: const Offset(0, -1.5),
                                        child: Text(
                                          quitStatusLabel,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: quitStatusColor
                                                    .withValues(alpha: 0.52),
                                                fontWeight: FontWeight.w400,
                                                fontSize: 9,
                                                letterSpacing: 0.05,
                                              ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _QuitHubLiveTimer(
                                clockStartedAt: quitClockStartedAt,
                                format: (d) => _formatQuitHubHmsLocalized(
                                  hours: d.inHours,
                                  minutes: d.inMinutes.remainder(60),
                                  seconds: d.inSeconds.remainder(60),
                                  l10n: l10n,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.willpowerHubTapCardForDetails,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: fullQuitHintColor,
                                  fontSize: 10.5,
                                  height: 1.2,
                                  letterSpacing: 0.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 26,
                            color: fullQuitChevronColor,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.willpowerHubArchiveAction,
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: onLight
                                ? AppColors.textSecondary
                                : AppColors.creamBase.withValues(alpha: 0.32),
                            size: 22,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 66, top: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final choice = await showDialog<_HubResetChoice>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.anthraciteMid,
                                title: Text(
                                  l10n.quitProgramRestartTitle,
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: AppColors.creamBase,
                                  ),
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
                                    _HubResetOptionTile(
                                      icon: Icons.history_rounded,
                                      title: l10n
                                          .quitProgramRestartKeepHistoryTitle,
                                      subtitle: l10n
                                          .quitProgramRestartKeepHistorySubtitle,
                                      color: _kQuitAccent,
                                      onTap: () => Navigator.pop(
                                        ctx,
                                        _HubResetChoice.keepHistory,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _HubResetOptionTile(
                                      icon: Icons.delete_sweep_rounded,
                                      title: l10n.quitProgramRestartWipeTitle,
                                      subtitle:
                                          l10n.quitProgramRestartWipeSubtitle,
                                      color: Colors.redAccent,
                                      onTap: () => Navigator.pop(
                                        ctx,
                                        _HubResetChoice.wipeAll,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                      ctx,
                                      _HubResetChoice.cancel,
                                    ),
                                    child: Text(
                                      l10n.commonCancel,
                                      style: const TextStyle(
                                        color: AppColors.creamBase,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (choice != null &&
                                choice != _HubResetChoice.cancel &&
                                context.mounted) {
                              await ref
                                  .read(habitSummaryProvider.notifier)
                                  .restartQuitProgram(
                                    item.habit.id,
                                    preserveHistory:
                                        choice == _HubResetChoice.keepHistory,
                                  );
                            }
                          },
                          icon: Icon(
                            Icons.restart_alt_rounded,
                            size: 17,
                            color: fullQuitRestartIconColor,
                          ),
                          label: Text(
                            l10n.quitProgramRestartTitle,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: fullQuitRestartLabelColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.15,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textOnDarkMuted
                                .withValues(alpha: 0.95),
                            side: BorderSide(
                              color: fullQuitRestartBorderColor,
                              width: 1.1,
                            ),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.055,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: isFullQuit
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    if (isFullQuit)
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fullQuitBadgeBg,
                          border: Border.all(color: fullQuitBadgeBorder),
                        ),
                        child:
                            item.habit.templateId ==
                                WillpowerTemplates.quitSmoking
                            ? Icon(
                                Icons.smoke_free_rounded,
                                size: 30,
                                color: fullQuitBadgeIcon,
                              )
                            : Text(
                                item.habit.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                      )
                    else
                      Text(
                        item.habit.emoji,
                        style: TextStyle(fontSize: isSalat ? 26 : 32),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _localizedHabitTitle(l10n, item.habit),
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: titleColor,
                                              letterSpacing: isCustom
                                                  ? -0.2
                                                  : 0,
                                            ),
                                      ),
                                    ),
                                    if (quitStatusLabel != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Transform.translate(
                                          offset: const Offset(0, -1.5),
                                          child: Text(
                                            quitStatusLabel,
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color: quitStatusColor
                                                      .withValues(alpha: 0.52),
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 9,
                                                  letterSpacing: 0.05,
                                                ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (needsSetup)
                                  Text(
                                    l10n.willpowerHubCompleteSetup,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.orangeAccent.shade100,
                                    ),
                                  )
                                else if (isFullQuit)
                                  !quitClockOn
                                      ? Text(
                                          l10n.willpowerHubStartClockHint,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: fullQuitHintColor,
                                                fontWeight: FontWeight.w400,
                                                height: 1.35,
                                              ),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _QuitHubLiveTimer(
                                              clockStartedAt: quitClockStartedAt,
                                              format: (d) =>
                                                  _formatQuitHubHmsLocalized(
                                                    hours: d.inHours,
                                                    minutes: d.inMinutes
                                                        .remainder(60),
                                                    seconds: d.inSeconds
                                                        .remainder(60),
                                                    l10n: l10n,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              l10n.willpowerHubTapCardForDetails,
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                    color: fullQuitHintColor,
                                                    fontSize: 10.5,
                                                    height: 1.2,
                                                    letterSpacing: 0.15,
                                                  ),
                                            ),
                                          ],
                                        )
                                else if (isCustom)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _CustomHabitHubProgress(
                                        habit: item.habit,
                                        progress: customProgress,
                                        target: customTarget,
                                        accent: toggleAccent,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_fire_department_rounded,
                                            size: 14,
                                            color: item.streak > 0
                                                ? AppColors.warning
                                                : (onLight
                                                      ? AppColors.textSecondary
                                                      : AppColors.textMuted),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${item.streak} ${item.habit.customRepeatCycle != 0 ? l10n.willpowerHubStreakSeriesLabel : l10n.willpowerHubStreakDaySeriesLabel}',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color: item.streak > 0
                                                      ? AppColors.warning
                                                      : (onLight
                                                            ? AppColors
                                                                  .textSecondary
                                                            : AppColors
                                                                  .textMuted),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_fire_department_rounded,
                                        size: 14,
                                        color: item.streak > 0
                                            ? AppColors.warning
                                            : (onLight
                                                  ? AppColors.textSecondary
                                                  : AppColors.textMuted),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.streak} ${l10n.willpowerHubStreakDaySeriesLabel}',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: item.streak > 0
                                                  ? AppColors.warning
                                                  : (onLight
                                                        ? AppColors
                                                              .textSecondary
                                                        : AppColors.textMuted),
                                            ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if ((isFullQuit && quitClockOn) ||
                              (isCustom && !needsSetup)) ...[
                            const SizedBox(width: 2),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 26,
                                color: fullQuitChevronColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isSalat && !isFullQuit && !isCustom) ...[
                      GestureDetector(
                        onTap: onToggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done
                                ? toggleAccent.withValues(alpha: 0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: done
                                  ? toggleAccent
                                  : (onLight
                                        ? Colors.black.withValues(alpha: 0.12)
                                        : AppColors.creamBase.withValues(
                                            alpha: 0.3,
                                          )),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            done ? Icons.check_rounded : Icons.circle_outlined,
                            color: done ? toggleAccent : AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    IconButton(
                      tooltip: l10n.willpowerHubArchiveAction,
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: (isFullQuit || isSalat)
                            ? (onLight
                                  ? AppColors.textSecondary
                                  : AppColors.creamBase.withValues(
                                      alpha: 0.32,
                                    ))
                            : AppColors.error,
                        size: 22,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        height: salatHubFixedCard ? gelisimHubCardHeight : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(salatHubFixedCard ? 16 : 18),
          gradient: useRichCard
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF161C18).withValues(alpha: 0.92),
                    const Color(0xFF0E1210).withValues(alpha: 0.88),
                  ],
                )
              : null,
          color: useRichCard
              ? null
              : (onLight
                    ? Colors.white.withValues(alpha: 0.9)
                    : _kCardSurface.withValues(alpha: 0.55)),
          border: Border.all(color: borderAccent, width: 1),
          boxShadow: useRichCard
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (salatHubFixedCard && embedSalatPrayerRow && isSalat)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    materialWidget,
                    const SizedBox(height: _kHubKazaNamazMainToBottomGap),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                      child: SalatPrayerRow(
                        habitId: item.habit.id,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              if (salatHubFixedCard)
                Expanded(child: materialWidget)
              else
                materialWidget,
              if (isSalat && embedSalatPrayerRow)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 9),
                  child: SalatPrayerRow(habitId: item.habit.id, compact: true),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
