import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../data/repositories/salat_log_repository.dart';
import '../../data/services/tracking_widget_service.dart';
import '../kaza/kaza_tracking_provider.dart';
import '../shared/providers/habit_providers.dart';
import '../shared/widgets/arin_shell_layout.dart';

class WidgetCenterPage extends ConsumerStatefulWidget {
  const WidgetCenterPage({super.key});

  @override
  ConsumerState<WidgetCenterPage> createState() => _WidgetCenterPageState();
}

class _WidgetCenterPageState extends ConsumerState<WidgetCenterPage> {
  bool _saving = false;

  Future<List<TrackingWidgetOption>> _loadOptions() {
    return TrackingWidgetService.availableOptions(
      prefs: ref.read(sharedPreferencesProvider),
      habitRepo: ref.read(habitRepositoryProvider),
      salatRepo: SalatLogRepository(),
    );
  }

  Future<void> _select(String? targetId) async {
    setState(() => _saving = true);
    HapticFeedback.selectionClick();
    try {
      await TrackingWidgetService.selectTarget(
        prefs: ref.read(sharedPreferencesProvider),
        habitRepo: ref.read(habitRepositoryProvider),
        salatRepo: SalatLogRepository(),
        targetId: targetId,
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targetId == null
                ? 'Takip widgetı kapatıldı.'
                : 'Takip widgetı güncellendi.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(habitSummaryProvider);
    ref.watch(kazaTrackingProvider);

    final onDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = onDark
        ? Colors.white.withValues(alpha: 0.96)
        : AppColors.emeraldDark;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    final prefs = ref.watch(sharedPreferencesProvider);
    final selectedId = TrackingWidgetService.selectedTarget(prefs);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: ArinShellBackground.decoration(context)),
          ArinShellBackground.bubbleLayer(context),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: onDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.55),
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: titleColor.withValues(alpha: 0.88),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Widget Merkezi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  18,
                  22,
                  ArinShellLayout.bottomContentPadding(context),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroCard(onDark: onDark)
                        .animate()
                        .fadeIn(duration: 360.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 12),
                    _HowToAddBanner(onDark: onDark)
                        .animate()
                        .fadeIn(duration: 420.ms, delay: 80.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 22),
                    _SectionTitle('Mevcut widgetlar', muted: muted),
                    const SizedBox(height: 10),
                    _InfoTile(
                      onDark: onDark,
                      icon: Icons.format_quote_rounded,
                      title: 'Günlük Söz Widgetı',
                      subtitle:
                          'Ana ekrana veya kilit ekranına eklenir. Sözler otomatik yenilenir.',
                    ),
                    const SizedBox(height: 10),
                    _InfoTile(
                      onDark: onDark,
                      icon: Icons.access_time_rounded,
                      title: 'Namaz Vakti Widgetı',
                      subtitle:
                          'Konumuna göre sıradaki vakti gösterir. Konum değişirse uygulamayı açman yeterli.',
                    ),
                    const SizedBox(height: 10),
                    _InfoTile(
                      onDark: onDark,
                      icon: Icons.widgets_outlined,
                      title: 'Söz + Namaz Widgetı',
                      subtitle:
                          'Günlük söz ve sıradaki namaz vaktini aynı küçük alanda gösterir.',
                    ),
                    const SizedBox(height: 10),
                    _InfoTile(
                      onDark: onDark,
                      icon: Icons.fingerprint_rounded,
                      title: 'Zikirmatik Widgetı',
                      subtitle:
                          'Ana ekrandan "+" ile zikir çekersin; sayaç uygulamayla eş zamanlı. Tek dokunuş zikirmatik sayfasını açar.',
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle('Takip widgetı', muted: muted),
                    const SizedBox(height: 10),
                    Text(
                      'Kilit ekranında tek bir takip gösterilir. Kurmadığın takipler burada görünmez. Hassas takiplerde başlık nötr tutulur.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.45,
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<TrackingWidgetOption>>(
                      future: _loadOptions(),
                      builder: (context, snap) {
                        final options = snap.data ?? const [];
                        if (!snap.hasData) {
                          return _LoadingCard(onDark: onDark);
                        }
                        return Column(
                          children: [
                            _TrackingChoiceTile(
                              onDark: onDark,
                              selected: selectedId == null,
                              title: 'Gösterme',
                              subtitle: 'Takip widgetını boş bırak.',
                              icon: Icons.visibility_off_outlined,
                              saving: _saving,
                              onTap: () => _select(null),
                            ),
                            const SizedBox(height: 10),
                            if (options.isEmpty)
                              _EmptyTrackingCard(onDark: onDark)
                            else
                              for (final option in options) ...[
                                _TrackingChoiceTile(
                                  onDark: onDark,
                                  selected: selectedId == option.id,
                                  title: option.title,
                                  subtitle: option.snapshot.value,
                                  footnote: option.subtitle,
                                  icon: _iconForOption(option),
                                  saving: _saving,
                                  onTap: () => _select(option.id),
                                ),
                                const SizedBox(height: 10),
                              ],
                          ],
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForOption(TrackingWidgetOption option) {
    final text = '${option.title} ${option.subtitle}'.toLowerCase();
    if (text.contains('namaz')) return Icons.mosque_outlined;
    if (text.contains('sigara')) return Icons.air_rounded;
    if (text.contains('alkol')) return Icons.water_drop_outlined;
    if (text.contains('kaza')) return Icons.task_alt_rounded;
    if (text.contains('ekran')) return Icons.center_focus_strong_outlined;
    return Icons.track_changes_rounded;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark
        ? Colors.white.withValues(alpha: 0.96)
        : AppColors.emeraldDark;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onDark
              ? [
                  AppColors.cardSurface.withValues(alpha: 0.68),
                  AppColors.emeraldDark.withValues(alpha: 0.22),
                ]
              : [
                  Colors.white.withValues(alpha: 0.82),
                  AppColors.emeraldFaint.withValues(alpha: 0.42),
                ],
        ),
        border: Border.all(
          color: AppColors.accentNeonGreen.withValues(
            alpha: onDark ? 0.18 : 0.3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGlowGreen.withValues(
              alpha: onDark ? 0.1 : 0.08,
            ),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentNeonGreen.withValues(alpha: 0.14),
              border: Border.all(
                color: AppColors.accentNeonGreen.withValues(alpha: 0.28),
              ),
            ),
            child: Icon(
              Icons.lock_clock_rounded,
              color: AppColors.accentNeonGreen.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kilit ekranında sade takip',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Söz ve vakit widgetları otomatik çalışır. Burada sadece gelişim veya arınma takibinin kilit ekranında görünüp görünmeyeceğini seçersin.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.42,
                    color: muted,
                    fontWeight: FontWeight.w500,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.muted});

  final String text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: muted.withValues(alpha: 0.88),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.onDark,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final bool onDark;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      onDark: onDark,
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.info_outline_rounded, size: 18),
    );
  }
}

class _TrackingChoiceTile extends StatelessWidget {
  const _TrackingChoiceTile({
    required this.onDark,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.saving,
    required this.onTap,
    this.footnote,
  });

  final bool onDark;
  final bool selected;
  final String title;
  final String subtitle;
  final String? footnote;
  final IconData icon;
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      onDark: onDark,
      icon: icon,
      title: title,
      subtitle: footnote == null ? subtitle : '$subtitle\n$footnote',
      onTap: saving ? null : onTap,
      selected: selected,
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: selected
            ? Icon(
                Icons.check_circle_rounded,
                key: const ValueKey('on'),
                color: AppColors.accentNeonGreen.withValues(alpha: 0.95),
              )
            : Icon(
                Icons.radio_button_unchecked_rounded,
                key: const ValueKey('off'),
                color: onDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColors.textMuted.withValues(alpha: 0.75),
              ),
      ),
    );
  }
}

class _BaseTile extends StatelessWidget {
  const _BaseTile({
    required this.onDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  final bool onDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark
        ? Colors.white.withValues(alpha: 0.94)
        : AppColors.emeraldDark;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    final fill = selected
        ? AppColors.accentNeonGreen.withValues(alpha: onDark ? 0.11 : 0.16)
        : (onDark
              ? AppColors.cardSurface.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.68));
    final border = selected
        ? AppColors.accentNeonGreen.withValues(alpha: onDark ? 0.34 : 0.42)
        : (onDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.creamDark.withValues(alpha: 0.45));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(15, 14, 13, 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentNeonGreen.withValues(
                    alpha: selected ? 0.18 : 0.1,
                  ),
                ),
                child: Icon(icon, size: 22, color: AppColors.accentNeonGreen),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (trailing != null)
                IconTheme.merge(
                  data: IconThemeData(color: muted),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      onDark: onDark,
      icon: Icons.hourglass_empty_rounded,
      title: 'Takipler hazırlanıyor',
      subtitle: 'Kurulu takiplerin kontrol ediliyor.',
      trailing: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _EmptyTrackingCard extends StatelessWidget {
  const _EmptyTrackingCard({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      onDark: onDark,
      icon: Icons.add_task_rounded,
      title: 'Henüz takip yok',
      subtitle:
          'Arınma veya Gelişim bölümünde bir takip kurunca burada seçilebilir olacak.',
    );
  }
}

// ─── How-to banner ──────────────────────────────────────────────────────────

class _HowToAddBanner extends StatelessWidget {
  const _HowToAddBanner({required this.onDark});

  final bool onDark;

  void _open(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HowToSheet(onDark: onDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.emeraldDark;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    final fill = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.38)
        : Colors.white.withValues(alpha: 0.62);
    final border = onDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppColors.creamDark.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(15, 13, 13, 13),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.lock_clock_rounded,
                  size: 20,
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kilit ekranına nasıl eklenir?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Arın widgetını kilit ekranına yerleştirme',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: muted.withValues(alpha: 0.6),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── How-to bottom sheet ────────────────────────────────────────────────────

class _HowToSheet extends StatefulWidget {
  const _HowToSheet({required this.onDark});

  final bool onDark;

  @override
  State<_HowToSheet> createState() => _HowToSheetState();
}

class _HowToSheetState extends State<_HowToSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: Platform.isIOS ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onDark = widget.onDark;
    final bg = onDark ? const Color(0xFF111714) : const Color(0xFFF5F3EF);
    final handle = onDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.12);
    final titleColor = onDark
        ? Colors.white.withValues(alpha: 0.96)
        : AppColors.emeraldDark;

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.38,
      maxChildSize: 0.88,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentNeonGreen.withValues(alpha: 0.14),
                    ),
                    child: const Icon(
                      Icons.widgets_rounded,
                      size: 20,
                      color: AppColors.accentNeonGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kilit ekranı widget rehberi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _PlatformTabBar(
                controller: _tabs,
                onDark: onDark,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _StepList(
                    controller: controller,
                    onDark: onDark,
                    sections: _iosLockScreenSteps,
                  ),
                  _StepList(
                    controller: controller,
                    onDark: onDark,
                    sections: _androidLockScreenSteps,
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

// ─── Platform tab bar ────────────────────────────────────────────────────────

class _PlatformTabBar extends StatelessWidget {
  const _PlatformTabBar({
    required this.controller,
    required this.onDark,
  });

  final TabController controller;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bg = onDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);
    final selectedBg = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.95);
    final selectedColor = onDark
        ? Colors.white.withValues(alpha: 0.96)
        : AppColors.emeraldDark;
    final unselectedColor = onDark
        ? Colors.white.withValues(alpha: 0.38)
        : AppColors.textSecondary.withValues(alpha: 0.6);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: selectedBg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: onDark ? 0.25 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: selectedColor,
        unselectedLabelColor: unselectedColor,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'iOS'),
          Tab(text: 'Android'),
        ],
      ),
    );
  }
}

// ─── Step list ────────────────────────────────────────────────────────────────

class _StepList extends StatelessWidget {
  const _StepList({
    required this.controller,
    required this.onDark,
    required this.sections,
  });

  final ScrollController controller;
  final bool onDark;
  final List<_StepSection> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
        22,
        16,
        22,
        MediaQuery.of(context).padding.bottom + 28,
      ),
      children: [
        for (final section in sections) ...[
          _SectionLabel(text: section.label, onDark: onDark),
          const SizedBox(height: 10),
          for (int i = 0; i < section.steps.length; i++) ...[
            _StepCard(
              index: i + 1,
              step: section.steps[i],
              onDark: onDark,
              isLast: i == section.steps.length - 1,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.onDark});

  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: color.withValues(alpha: 0.75),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.step,
    required this.onDark,
    required this.isLast,
  });

  final int index;
  final _Step step;
  final bool onDark;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark
        ? Colors.white.withValues(alpha: 0.94)
        : AppColors.emeraldDark;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    final cardBg = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.72);
    final cardBorder = onDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppColors.creamDark.withValues(alpha: 0.4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentNeonGreen.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.accentNeonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentNeonGreen,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: step.imagePath != null ? 12 : 12,
                margin: const EdgeInsets.symmetric(vertical: 3),
                color: AppColors.accentNeonGreen.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step.imagePath != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                    child: Image.asset(
                      step.imagePath!,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        step.icon,
                        size: 22,
                        color: AppColors.accentNeonGreen,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                                height: 1.2,
                              ),
                            ),
                            if (step.subtitle != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                step.subtitle!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: muted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Step data ────────────────────────────────────────────────────────────────

class _Step {
  const _Step({
    required this.icon,
    required this.title,
    this.subtitle,
    this.imagePath,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? imagePath;
}

class _StepSection {
  const _StepSection({required this.label, required this.steps});

  final String label;
  final List<_Step> steps;
}

const _iosLockScreenSteps = [
  _StepSection(
    label: 'iPhone — kilit ekranı',
    steps: [
      _Step(
        icon: Icons.lock_outline_rounded,
        title: 'Kilit ekranında duvar kağıdına veya saate uzun bas',
        subtitle: '"Özelleştir" seçeneği görününceye kadar basılı tut.',
        imagePath: 'assets/images/widget_guide/ios_lock_1.png',
      ),
      _Step(
        icon: Icons.tune_rounded,
        title: '"Özelleştir"e dokun',
        subtitle: 'Kilit ekranı düzenleme moduna girersin.',
        imagePath: 'assets/images/widget_guide/ios_lock_2.png',
      ),
      _Step(
        icon: Icons.add_rounded,
        title: 'Widget alanına dokun ya da "+" işaretine bas',
        subtitle:
            'Üst veya alt şeritteki boş alanı seç; "Araç Takımı Ekleyin" listesi açılır.',
        imagePath: 'assets/images/widget_guide/ios_lock_3.png',
      ),
      _Step(
        icon: Icons.widgets_outlined,
        title: 'Listeden Arın\'ı seç',
        subtitle:
            'Söz, namaz vakti veya karma widgetından birini seç; önizlemeyi kaydırarak boyutu değiştirebilirsin.',
        imagePath: 'assets/images/widget_guide/ios_lock_4.png',
      ),
      _Step(
        icon: Icons.touch_app_rounded,
        title: 'Widgeta dokun veya sürükle',
        subtitle:
            'Yerleştirdikten sonra "Bitti" ile çık. Takip için hangi içeriğin görüneceğini Widget Merkezi\'nden seç.',
        imagePath: 'assets/images/widget_guide/ios_lock_5.png',
      ),
      _Step(
        icon: Icons.check_circle_outline_rounded,
        title: 'Kilit ekranında widgetlar görünür',
        subtitle:
            'Arın widgetları saatin hemen altında yan yana yerleşir. İstediğin zaman yeniden düzenleyebilirsin.',
        imagePath: 'assets/images/widget_guide/ios_lock_6.png',
      ),
    ],
  ),
];

const _androidLockScreenSteps = [
  _StepSection(
    label: 'Android — kilit ekranı',
    steps: [
      _Step(
        icon: Icons.info_outline_rounded,
        title: 'Kilit ekranı menüsü markaya göre değişir',
        subtitle:
            'Pixel, Samsung ve Xiaomi kilit ekranı araç takımı ekleme yolu farklı olabilir.',
        imagePath: 'assets/images/widget_guide/android_lock_1.png',
      ),
      _Step(
        icon: Icons.lock_outline_rounded,
        title: 'Kilit ekranına uzun bas, "Özelleştir"e dokun',
        subtitle:
            'Genelde kilit ekranında uzun basıp Düzenle veya benzeri seçeneği kullanırsın.',
        imagePath: 'assets/images/widget_guide/android_lock_2.png',
      ),
      _Step(
        icon: Icons.widgets_outlined,
        title: "Listeden Arın'ı seç ve ekle",
        subtitle:
            "Listeden Arın uygulamasını bul; söz, namaz veya takip widgetını seçip konumunu ayarla.",
        imagePath: 'assets/images/widget_guide/android_lock_3.png',
      ),
      _Step(
        icon: Icons.touch_app_rounded,
        title: 'Widget önizlemesine dokun veya Ekle',
        subtitle:
            "Widget kartını seç, önizlemeyi kaydırarak boyutu değiştir, ardından Ekle butonuna bas.",
        imagePath: 'assets/images/widget_guide/android_lock_3b.png',
      ),
      _Step(
        icon: Icons.center_focus_strong_outlined,
        title: 'Widget kilit ekranında görünür',
        subtitle:
            "Kilitte hangi takibin çıkacağını bu sayfadaki 'Takip widgetı' bölümünden seç.",
        imagePath: 'assets/images/widget_guide/android_lock_4.png',
      ),
    ],
  ),
];
