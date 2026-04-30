// Alışkanlık takvimi — günlük işaretler (gri ikonlar) + ay özeti.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/extensions/date_extensions.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/salat_log_repository.dart';
import '../shared/providers/habit_providers.dart';
import '../willpower/salat_providers.dart';

const Color _kMarkerGrey = Color(0xFF7A8580);

class HabitCalendarPage extends ConsumerStatefulWidget {
  const HabitCalendarPage({super.key});

  @override
  ConsumerState<HabitCalendarPage> createState() => _HabitCalendarPageState();
}

class _HabitCalendarPageState extends ConsumerState<HabitCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _periodKeyForDay(HabitModel h, DateTime day) {
    final d = _dayOnly(day);
    switch (h.customRepeatCycle.clamp(0, 2)) {
      case 1:
        final fromMon = d.weekday - DateTime.monday;
        final mon = d.subtract(Duration(days: fromMon));
        return '${mon.year}-${mon.month.toString().padLeft(2, '0')}-${mon.day.toString().padLeft(2, '0')}';
      case 2:
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-01';
      default:
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  bool _isCustomCompletedForDay(
    HabitModel h,
    DateTime day,
    HabitRepository repo,
  ) {
    final periodKey = _periodKeyForDay(h, day);
    final log = repo.logForDay(h.id, periodKey);
    if (log == null) return false;
    if (log.isCompleted) return true;
    return log.progressValue >= h.effectiveDailyTarget;
  }

  static IconData _quitProgramCalendarIcon(String templateId) {
    switch (templateId) {
      case WillpowerTemplates.quitSmoking:
        return Icons.smoke_free_rounded;
      case WillpowerTemplates.quitScreen:
        return Icons.smartphone_rounded;
      case WillpowerTemplates.quitAlcohol:
        return Icons.local_bar_outlined;
      case WillpowerTemplates.quitSubstance:
        return Icons.medication_outlined;
      case WillpowerTemplates.quitZina:
        return Icons.shield_outlined;
      default:
        return Icons.self_improvement_rounded;
    }
  }

  List<_DayMarker> _markersForDay(
    DateTime day,
    List<HabitModel> habits,
    HabitRepository repo,
    SalatLogRepository salat,
  ) {
    final d0 = _dayOnly(day);
    final today = _dayOnly(DateTime.now());
    if (d0.isAfter(today)) return [];

    final out = <_DayMarker>[];
    for (final h in habits) {
      if (h.isArchived) continue;

      if (WillpowerTemplates.isFullQuitProgram(h.templateId)) {
        final hasClock = h.quitClockStartedAtIso != null &&
            h.quitClockStartedAtIso!.isNotEmpty;
        if (!h.onboardingCompleted && !hasClock) continue;
        final iso = h.quitClockStartedAtIso;
        if (iso == null || iso.isEmpty) continue;
        final start = DateTime.tryParse(iso);
        if (start == null) continue;
        final sd = _dayOnly(start);
        if (!d0.isBefore(sd)) {
          out.add(_DayMarker(
              icon: _quitProgramCalendarIcon(h.templateId), label: ''));
        }
        continue;
      }

      if (h.templateId == WillpowerTemplates.salatDaily) {
        if (salat.countDone(h.id, day) >= 1) {
          out.add(const _DayMarker(icon: Icons.mosque_outlined, label: ''));
        }
        continue;
      }

      final completed = h.isCustomTracked && h.customRepeatCycle != 0
          ? _isCustomCompletedForDay(h, day, repo)
          : repo.isCompletedOnDay(h.id, day);
      if (completed) {
        IconData ic = Icons.check_rounded;
        if (h.templateId == WillpowerTemplates.quranDaily) {
          ic = Icons.menu_book_rounded;
        } else if (h.type == HabitType.good) {
          ic = Icons.star_outline_rounded;
        }
        out.add(_DayMarker(icon: ic, label: ''));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final summary = ref.watch(habitSummaryProvider);
    final habits = summary.map((e) => e.habit).toList();
    final repo = ref.watch(habitRepositoryProvider);
    final salat = ref.watch(salatLogRepositoryProvider);

    final firstDay = DateTime.utc(2023, 1, 1);
    final lastDay = DateTime.now().add(const Duration(days: 365));

    final insights = _monthInsights(
      _focusedDay,
      habits,
      repo,
      salat,
    );

    return Scaffold(
      backgroundColor:
          light ? AppColors.creamMist : AppColors.anthraciteDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.shellOnCanvasPrimary(context),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Alışkanlık takvimi',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.shellOnCanvasPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Bugün: ${DateTime.now().displayDateTr}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.shellOnCanvasSecondary(context),
                  letterSpacing: 0.2,
                ),
              ),
            ).animate().fadeIn(duration: 320.ms),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: light
                      ? Colors.white.withValues(alpha: 0.78)
                      : AppColors.anthraciteMid.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: light
                        ? Colors.black.withValues(alpha: 0.08)
                        : AppColors.creamBase.withValues(alpha: 0.08),
                  ),
                ),
                child: TableCalendar<void>(
                  firstDay: firstDay,
                  lastDay: lastDay,
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) =>
                      _selectedDay != null && _selectedDay!.isSameDay(d),
                  onDaySelected: (sel, foc) {
                    setState(() {
                      _selectedDay = sel;
                      _focusedDay = foc;
                    });
                  },
                  onPageChanged: (f) => setState(() => _focusedDay = f),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
                  locale: 'tr_TR',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.shellOnCanvasPrimary(context),
                      fontWeight: FontWeight.w700,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.shellOnCanvasPrimary(context)
                          .withValues(alpha: 0.75),
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.shellOnCanvasPrimary(context)
                          .withValues(alpha: 0.75),
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.shellOnCanvasSecondary(context),
                    ),
                    weekendStyle: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.shellOnCanvasSecondary(context)
                          .withValues(alpha: 0.88),
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(3),
                    defaultDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    todayDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accentNeonGreen.withValues(alpha: 0.55),
                        width: 1.2,
                      ),
                    ),
                    selectedDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.accentNeonGreen.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.accentNeonGreen.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (ctx, day, _) => _CalendarDayCell(
                      day: day,
                      markers: _markersForDay(day, habits, repo, salat),
                      isToday: day.isToday,
                      isSelected:
                          _selectedDay != null && _selectedDay!.isSameDay(day),
                      lightShell: light,
                    ),
                    todayBuilder: (ctx, day, _) => _CalendarDayCell(
                      day: day,
                      markers: _markersForDay(day, habits, repo, salat),
                      isToday: true,
                      isSelected: false,
                      lightShell: light,
                    ),
                    selectedBuilder: (ctx, day, _) => _CalendarDayCell(
                      day: day,
                      markers: _markersForDay(day, habits, repo, salat),
                      isToday: day.isToday,
                      isSelected: true,
                      lightShell: light,
                    ),
                    outsideBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 40.ms).slideY(
                  begin: 0.04,
                  curve: Curves.easeOutCubic,
                ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        size: 22,
                        color: AppColors.accentNeonGreen.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ay notu · ${_focusedDay.fullMonthTr} ${_focusedDay.year}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.shellOnCanvasPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (insights.isEmpty)
                    Text(
                      'Bu ay için henüz kayıt yok veya alışkanlık eklemedin.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.shellOnCanvasSecondary(context),
                        height: 1.45,
                      ),
                    ).animate().fadeIn(duration: 450.ms)
                  else
                    ...insights.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.shellOnCanvasPrimary(
                                              context)
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.shellOnCanvasPrimary(
                                          context),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(
                                duration: 420.ms,
                                delay: (80 + e.key * 70).ms,
                              ).slideX(
                                begin: 0.03,
                                curve: Curves.easeOutCubic,
                              ),
                        ),
                  const SizedBox(height: 8),
                  Text(
                    'Hücredeki gri simgeler: o gün için kayıt var demektir. '
                    'Arınma simgesi özellikle sayacın aktif olduğu günleri gösterir; '
                    'namaz/rutin simgeleri ilgili günün tamamlanan kayıtlarını gösterir.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.shellOnCanvasSecondary(context),
                      height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  List<String> _monthInsights(
    DateTime month,
    List<HabitModel> habits,
    HabitRepository repo,
    SalatLogRepository salat,
  ) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final today = _dayOnly(DateTime.now());
    final lines = <String>[];

    for (final h in habits) {
      if (h.isArchived) continue;

      if (WillpowerTemplates.isFullQuitProgram(h.templateId)) {
        final hasClock = h.quitClockStartedAtIso != null &&
            h.quitClockStartedAtIso!.isNotEmpty;
        if (!h.onboardingCompleted && !hasClock) continue;
        final iso = h.quitClockStartedAtIso;
        if (iso == null || iso.isEmpty) continue;
        final st = DateTime.tryParse(iso);
        if (st == null) continue;
        final sd = _dayOnly(st);
        var n = 0;
        for (var d = start;
            !d.isAfter(end);
            d = d.add(const Duration(days: 1))) {
          final d0 = _dayOnly(d);
          if (d0.isAfter(today)) break;
          if (!d0.isBefore(sd)) n++;
        }
        if (n > 0) {
          lines.add(
            '“${h.title}”: bu ay $n gün Arınma sayacı takvimde (başlangıçtan itibaren).',
          );
        }
        continue;
      }

      if (h.templateId == WillpowerTemplates.salatDaily) {
        var anyPrayer = 0;
        var fullFive = 0;
        for (var d = start;
            !d.isAfter(end);
            d = d.add(const Duration(days: 1))) {
          final d0 = _dayOnly(d);
          if (d0.isAfter(today)) break;
          final c = salat.countDone(h.id, d);
          if (c >= 1) anyPrayer++;
          if (c >= 5) fullFive++;
        }
        if (anyPrayer > 0) {
          lines.add(
            '“${h.title}”: $anyPrayer günde en az bir vakit işaretlendi; $fullFive günde 5/5 tamamlandı.',
          );
        }
        continue;
      }

      var completedDays = 0;
      final completedPeriods = <String>{};
      for (var d = start;
          !d.isAfter(end);
          d = d.add(const Duration(days: 1))) {
        final d0 = _dayOnly(d);
        if (d0.isAfter(today)) break;
        if (h.isCustomTracked && h.customRepeatCycle != 0) {
          if (_isCustomCompletedForDay(h, d, repo)) {
            completedPeriods.add(_periodKeyForDay(h, d));
          }
        } else if (repo.isCompletedOnDay(h.id, d)) {
          completedDays++;
        }
      }
      if (h.isCustomTracked && h.customRepeatCycle != 0) {
        final n = completedPeriods.length;
        if (n > 0) {
          final periodLabel = h.customRepeatCycle == 1 ? 'hafta' : 'ay';
          lines.add(
            '“${h.title}”: bu ay $n $periodLabel hedefine ulaşıldı.',
          );
        }
      } else if (completedDays > 0) {
        lines.add(
          '“${h.title}”: bu ay toplam $completedDays gün tamamlandı olarak işaretlendi.',
        );
      }
    }

    return lines;
  }
}

class _DayMarker {
  const _DayMarker({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.markers,
    required this.isToday,
    required this.isSelected,
    required this.lightShell,
  });

  final DateTime day;
  final List<_DayMarker> markers;
  final bool isToday;
  final bool isSelected;
  final bool lightShell;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isSelected
            ? AppColors.accentNeonGreen.withValues(alpha: 0.08)
            : Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: AppTextStyles.labelSmall.copyWith(
              color: isToday
                  ? AppColors.accentNeonGreen
                  : (lightShell
                      ? AppColors.emeraldDark.withValues(alpha: 0.88)
                      : AppColors.creamBase.withValues(alpha: 0.92)),
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 14,
            child: markers.isEmpty
                ? const SizedBox.shrink()
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: markers
                          .take(5)
                          .map(
                            (m) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: Icon(
                                m.icon,
                                size: 11,
                                color: _kMarkerGrey.withValues(alpha: 0.85),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
