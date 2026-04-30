import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/willpower_templates.dart';
import '../../data/models/habit_model.dart';
import '../../data/willpower/willpower_content_loader.dart';
import '../shared/providers/habit_providers.dart';

class BuildProgramDetailPage extends ConsumerStatefulWidget {
  const BuildProgramDetailPage({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<BuildProgramDetailPage> createState() =>
      _BuildProgramDetailPageState();
}

class _BuildProgramDetailPageState extends ConsumerState<BuildProgramDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  QuranDailyContent? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    QuranDailyContent.load().then((c) {
      if (mounted) {
        setState(() {
          _content = c;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _daysSince(HabitModel h) {
    final start = DateTime.tryParse(h.startedAtIso) ?? DateTime.now();
    final now = DateTime.now();
    return now.difference(start).inDays.clamp(0, 99999);
  }

  double _milestoneDisplayPercent(List<WillMilestone> milestones, int days) {
    if (milestones.isEmpty) return 0;
    WillMilestone? best;
    for (final m in milestones) {
      if (days >= m.day && (best == null || m.day >= best.day)) {
        best = m;
      }
    }
    if (best != null) return best.percent;
    final first = milestones.first;
    if (first.day <= 0) return 0;
    return (days / first.day * first.percent).clamp(0.0, first.percent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(habitRepositoryProvider);
    final habit = repo.getById(widget.habitId);
    if (habit == null || habit.templateId != WillpowerTemplates.quranDaily) {
      return Scaffold(
        backgroundColor: AppColors.anthraciteDark,
        body: Center(
          child: Text(
            l10n.buildProgramDetailNotFound,
            style: const TextStyle(color: AppColors.creamBase),
          ),
        ),
      );
    }

    final summary = ref.watch(habitSummaryProvider);
    var completedToday = false;
    for (final e in summary) {
      if (e.habit.id == widget.habitId) {
        completedToday = e.completedToday;
        break;
      }
    }
    final days = _daysSince(habit);

    return Scaffold(
      backgroundColor: AppColors.anthraciteDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.creamBase),
          onPressed: () => context.pop(),
        ),
        title: Text(
          habit.title,
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.creamBase),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentNeonGreen,
          labelColor: AppColors.creamBase,
          unselectedLabelColor: AppColors.creamBase.withValues(alpha: 0.45),
          tabs: [
            Tab(text: l10n.buildProgramDetailTabGeneral),
            Tab(text: l10n.buildProgramDetailTabTips),
            Tab(text: l10n.buildProgramDetailTabProgress),
          ],
        ),
      ),
      body: _loading || _content == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.emeraldDark),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _GeneralTab(
                  habit: habit,
                  completedToday: completedToday,
                  onToggle: () => ref
                      .read(habitSummaryProvider.notifier)
                      .toggleToday(habit.id),
                ),
                _TipsTab(content: _content!),
                _ProgressTab(
                  milestones: _content!.milestones,
                  days: days,
                  displayPercent:
                      _milestoneDisplayPercent(_content!.milestones, days),
                ),
              ],
            ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({
    required this.habit,
    required this.completedToday,
    required this.onToggle,
  });

  final HabitModel habit;
  final bool completedToday;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.buildProgramDetailTodayQuestion,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.creamBase),
        ),
        const SizedBox(height: 16),
        Material(
          color: AppColors.anthraciteMid,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    completedToday
                        ? Icons.check_circle_rounded
                        : Icons.menu_book_rounded,
                    color: completedToday
                        ? AppColors.accentNeonGreen
                        : AppColors.creamBase,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      completedToday
                          ? l10n.buildProgramDetailTodayDone
                          : l10n.buildProgramDetailTodayPending,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.creamBase,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _TipsTab extends StatelessWidget {
  const _TipsTab({required this.content});

  final QuranDailyContent content;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: content.tips.length,
      itemBuilder: (ctx, i) {
        final t = content.tips[i];
        return Card(
          color: AppColors.anthraciteMid.withValues(alpha: 0.7),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    style: AppTextStyles.titleSmall
                        .copyWith(color: AppColors.accentNeonGreen)),
                if (t.quote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    t.quote,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.creamBase.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  t.body,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textOnDarkMuted, height: 1.45),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: (i * 80).ms);
      },
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({
    required this.milestones,
    required this.days,
    required this.displayPercent,
  });

  final List<WillMilestone> milestones;
  final int days;
  final double displayPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.buildProgramDetailDayCount(days),
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.creamBase),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.buildProgramDetailProgressIndicatorLabel,
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.textOnDarkMuted),
        ),
        const SizedBox(height: 20),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: displayPercent / 100),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.accentNeonGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.buildProgramDetailRoutinePercent((value * 100).round()),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.creamBase,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        ...milestones.map((m) {
          final reached = days >= m.day;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  reached ? Icons.flag_rounded : Icons.flag_outlined,
                  color: reached
                      ? AppColors.accentNeonGreen
                      : AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.buildProgramDetailMilestoneLabel(
                          m.day,
                          m.percent.toInt(),
                        ),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.creamBase,
                        ),
                      ),
                      Text(
                        m.message,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textOnDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        Text(
          l10n.buildProgramDetailDisclaimer,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }
}
