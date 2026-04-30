// lib/presentation/habits/habits_page.dart
// Alışkanlıklar sayfası — tam Riverpod entegrasyonu.
// İyi alışkanlıklar (yeşil) ve kötü bırakılacaklar (kırmızı tonu) ayrı bölümlerde.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/locale_text.dart';
import '../../core/router/app_router.dart';
import '../../data/models/habit_model.dart';
import '../../data/services/habit_cloud_sync_service.dart';
import '../shared/providers/auth_providers.dart';
import '../shared/providers/habit_providers.dart';

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t({
      required String tr,
      required String en,
      required String ar,
    }) => trEnAr(context, tr: tr, en: en, ar: ar);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = ref.watch(habitSummaryProvider);
    final goodHabits = summary.where((s) => s.habit.type == HabitType.good).toList();
    final badHabits = summary.where((s) => s.habit.type == HabitType.bad).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.anthraciteDark : AppColors.creamBase,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(24, 0, 0, 16),
              title: Text(t(
                      tr: 'Alışkanlıklarım',
                      en: 'My Habits',
                      ar: 'عاداتي'),
                  style: AppTextStyles.headlineLarge),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.emeraldDark, AppColors.emeraldMid],
                  ),
                ),
              ),
            ),
          ),
          if (summary.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.track_changes_rounded,
                          size: 72, color: AppColors.emeraldFaint),
                      const SizedBox(height: 20),
                      Text(
                        t(
                          tr: 'Henüz alışkanlık eklemedin.\nYeni bir başlangıç yapmaya hazır mısın?',
                          en: 'You have not added any habits yet.\nReady for a fresh start?',
                          ar: 'لم تضف أي عادة بعد.\nهل أنت مستعد لبداية جديدة؟',
                        ),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ].animate(interval: 100.ms).fadeIn(duration: 400.ms),
                  ),
                ),
              ),
            ),
          if (goodHabits.isNotEmpty) ...[
            _SectionHeader(
              title: t(tr: 'Gelişim', en: 'Growth', ar: 'التطوير'),
              icon: '✅',
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _HabitTile(
                    item: goodHabits[i],
                    onToggle: () => ref
                        .read(habitSummaryProvider.notifier)
                        .toggleToday(goodHabits[i].habit.id),
                    onDelete: () => _confirmDelete(
                      context,
                      ref,
                      goodHabits[i].habit.id,
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: (i * 60).ms),
                  childCount: goodHabits.length,
                ),
              ),
            ),
          ],
          if (badHabits.isNotEmpty) ...[
            _SectionHeader(
              title: t(tr: 'Arınma', en: 'Purification', ar: 'التزكية'),
              icon: '🚫',
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _HabitTile(
                    item: badHabits[i],
                    onToggle: () => ref
                        .read(habitSummaryProvider.notifier)
                        .toggleToday(badHabits[i].habit.id),
                    onDelete: () => _confirmDelete(
                      context,
                      ref,
                      badHabits[i].habit.id,
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: (i * 60).ms),
                  childCount: badHabits.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_bad',
            onPressed: () => context.push(AppRoutes.addHabit,
                extra: HabitType.bad),
            backgroundColor: const Color(0xFFC0392B),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: Text(t(
                    tr: 'Arınma hedefi ekle',
                    en: 'Add purification goal',
                    ar: 'أضف هدف تزكية',
                  ),
                style: AppTextStyles.labelMedium
                    .copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'add_good',
            onPressed: () => context.push(AppRoutes.addHabit,
                extra: HabitType.good),
            backgroundColor: AppColors.emeraldDark,
            foregroundColor: AppColors.creamBase,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text(t(
                    tr: 'Gelişim rutini ekle',
                    en: 'Add growth routine',
                    ar: 'أضف روتين تطوير',
                  ),
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.creamBase)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String habitId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            trEnAr(
              context,
              tr: 'Bu alışkanlığı silmek istiyor musun?',
              en: 'Do you want to delete this habit?',
              ar: 'هل تريد حذف هذه العادة؟',
            ),
            style: AppTextStyles.headlineSmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
                trEnAr(context,
                    tr: 'Vazgeç', en: 'Cancel', ar: 'إلغاء'),
                style:
                    AppTextStyles.labelLarge.copyWith(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: Text(
                trEnAr(context,
                    tr: 'Evet, Sil', en: 'Yes, Delete', ar: 'نعم، احذف'),
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
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
}

// ─── Bölüm Başlığı ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Text(icon),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.headlineSmall),
          ],
        ),
      ),
    );
  }
}

// ─── Alışkanlık Kartı ────────────────────────────────────────────────────────

class _HabitTile extends StatelessWidget {
  final ({HabitModel habit, int streak, bool completedToday}) item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBad = item.habit.type == HabitType.bad;
    final done = item.completedToday;
    final streakLabel = trEnAr(
      context,
      tr: 'gün serisi',
      en: 'day streak',
      ar: 'سلسلة أيام',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.anthraciteMid : AppColors.creamSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? AppColors.emeraldMid
              : isDark
                  ? AppColors.anthraciteLight
                  : AppColors.creamDark,
          width: done ? 1.5 : 0.8,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Text(item.habit.emoji,
            style: const TextStyle(fontSize: 30)),
        title: Text(
          item.habit.title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            decoration: done && !isBad
                ? TextDecoration.none
                : null,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.local_fire_department_rounded,
                size: 14,
                color: item.streak > 0
                    ? AppColors.warning
                    : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              '${item.streak} $streakLabel',
              style: AppTextStyles.labelSmall.copyWith(
                color: item.streak > 0
                    ? AppColors.warning
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tamamla / Geri al butonu
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppColors.emeraldDark
                      : Colors.transparent,
                  border: Border.all(
                    color: done
                        ? AppColors.emeraldDark
                        : AppColors.creamDark,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.circle_outlined,
                  color: done ? Colors.white : AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Sil butonu
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
