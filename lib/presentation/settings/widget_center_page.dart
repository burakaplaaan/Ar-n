import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/router/app_router.dart';
import '../assistant/assistant_session.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../data/models/widget_theme.dart';
import '../../data/repositories/salat_log_repository.dart';
import '../../data/services/android_oem_settings_service.dart';
import '../../data/services/arin_lock_notification_service.dart';
import '../../data/services/local_notification_permission_gate.dart';
import '../../data/services/paywall_prompt_service.dart';
import '../../data/services/tracking_widget_service.dart';
import '../../data/services/widget_access_service.dart';
import '../../l10n/app_localizations.dart';
import '../kaza/kaza_tracking_provider.dart';
import '../shared/providers/habit_providers.dart';
import '../shared/providers/premium_providers.dart';
import '../shared/providers/widget_theme_providers.dart';
import '../shared/widgets/arin_shell_layout.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';

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
      showArinTopToast(context, targetId == null
                ? 'Takip widgetı kapatıldı.'
                : 'Takip widgetı güncellendi.');
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
                  onPressed: () {
                    if (popToAssistantIfNeeded(context)) return;
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.settings);
                    }
                  },
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
                    _WidgetThemeSection(onDark: onDark, muted: muted),
                    const SizedBox(height: 22),
                    _WidgetLockTextSection(onDark: onDark, muted: muted),
                    const SizedBox(height: 22),
                    if (Platform.isIOS) ...[
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
                            'Küçükte sıradaki vakte kalan süreyi, genişte bugünün 5 vaktini ve kıldıklarını gösterir.',
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
                      const SizedBox(height: 10),
                      _InfoTile(
                        onDark: onDark,
                        icon: Icons.auto_awesome_outlined,
                        title: 'Esma-ül Hüsna Widgetı',
                        subtitle:
                            'Her gün bir ism-i şerif. Ana ekrana küçük kare olarak eklenir.',
                      ),
                    ] else ...[
                      _SectionTitle(
                        'Kilit ekranı bildirimleri',
                        muted: muted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Android\'de kilit ekranına gerçek widget eklenemiyor; bunun yerine seçtiğin bilgiler kalıcı bir bildirim olarak kilit ekranında görünür. Xiaomi, Huawei ve benzeri cihazlarda ek otomatik başlat / pil ayarı gerekebilir.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.45,
                          color: muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _LockNotificationToggles(),
                      const SizedBox(height: 12),
                      const _OemLockScreenHelpCard(),
                    ],
                    if (!Platform.isIOS) ...[
                      const SizedBox(height: 22),
                      _SectionTitle('Ana ekran widgetları', muted: muted),
                      const SizedBox(height: 10),
                      _InfoTile(
                        onDark: onDark,
                        icon: Icons.access_time_rounded,
                        title: 'Namaz Vakti Widgetı',
                        subtitle:
                            'Küçükte sıradaki vakte kalan süre, genişte bugünün 5 namazı ve hicri tarih.',
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        onDark: onDark,
                        icon: Icons.auto_awesome_outlined,
                        title: 'Esma-ül Hüsna Widgetı',
                        subtitle: 'Her gün bir ism-i şerif.',
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        onDark: onDark,
                        icon: Icons.format_quote_rounded,
                        title: 'Günlük Söz Widgetı',
                        subtitle: 'Ayet ve hadisler otomatik yenilenir.',
                      ),
                      const SizedBox(height: 10),
                      _InfoTile(
                        onDark: onDark,
                        icon: Icons.fingerprint_rounded,
                        title: 'Zikirmatik Widgetı',
                        subtitle: 'Ana ekrandan zikir çek; sayaç uygulamayla eşleşir.',
                      ),
                    ],
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

class _WidgetThemeSection extends ConsumerWidget {
  const _WidgetThemeSection({required this.onDark, required this.muted});

  final bool onDark;
  final Color muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(isPremiumProvider);
    final selected = ref.watch(effectiveWidgetThemeProvider);
    final languageCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.widgetThemeSectionTitle, muted: muted),
        const SizedBox(height: 8),
        Text(
          l10n.widgetThemeSectionSubtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.42,
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final theme in ArinWidgetTheme.all)
              _ThemeChip(
                theme: theme,
                selected: selected.id == theme.id,
                locked: theme.premiumOnly && !isPremium,
                languageCode: languageCode,
                onDark: onDark,
                onTap: () async {
                  if (theme.premiumOnly && !isPremium) {
                    await PaywallPromptService.showForLockedFeature(context);
                    return;
                  }
                  await ref.read(widgetThemeServiceProvider).select(
                    themeId: theme.id,
                    isPremium: isPremium,
                  );
                  ref.invalidate(effectiveWidgetThemeProvider);
                  if (!context.mounted) return;
                  showArinTopToast(context, l10n.widgetThemeApplied);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _WidgetLockTextSection extends ConsumerWidget {
  const _WidgetLockTextSection({required this.onDark, required this.muted});

  final bool onDark;
  final Color muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(isPremiumProvider);
    final selected = ref.watch(effectiveWidgetLockTextProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.widgetLockTextSectionTitle, muted: muted),
        const SizedBox(height: 8),
        Text(
          l10n.widgetLockTextSectionSubtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.42,
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LockTextChip(
                title: l10n.widgetLockTextClear,
                preview: 'İmsak  1:24:10',
                textOpacity: 1,
                selected: selected.id == WidgetLockTextStyle.clearId,
                locked: !isPremium,
                onDark: onDark,
                onTap: () => _select(
                  context,
                  ref,
                  isPremium: isPremium,
                  styleId: WidgetLockTextStyle.clearId,
                  toast: l10n.widgetLockTextApplied,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LockTextChip(
                title: l10n.widgetLockTextSoft,
                preview: 'İmsak  1:24:10',
                textOpacity: 0.52,
                selected: selected.id == WidgetLockTextStyle.softId,
                locked: !isPremium,
                onDark: onDark,
                onTap: () => _select(
                  context,
                  ref,
                  isPremium: isPremium,
                  styleId: WidgetLockTextStyle.softId,
                  toast: l10n.widgetLockTextApplied,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref, {
    required bool isPremium,
    required String styleId,
    required String toast,
  }) async {
    if (!isPremium) {
      await PaywallPromptService.showForLockedFeature(context);
      return;
    }
    await ref.read(widgetThemeServiceProvider).selectLockText(
      styleId: styleId,
      isPremium: isPremium,
    );
    ref.invalidate(effectiveWidgetLockTextProvider);
    if (!context.mounted) return;
    showArinTopToast(context, toast);
  }
}

class _LockTextChip extends StatelessWidget {
  const _LockTextChip({
    required this.title,
    required this.preview,
    required this.textOpacity,
    required this.selected,
    required this.locked,
    required this.onDark,
    required this.onTap,
  });

  final String title;
  final String preview;
  final double textOpacity;
  final bool selected;
  final bool locked;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: textOpacity);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: onDark ? const Color(0xFF1A1F1C) : const Color(0xFF2F3A33),
            border: Border.all(
              color: selected
                  ? AppColors.goldAccent
                  : Colors.white.withValues(alpha: 0.12),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (locked)
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.theme,
    required this.selected,
    required this.locked,
    required this.languageCode,
    required this.onDark,
    required this.onTap,
  });

  final ArinWidgetTheme theme;
  final bool selected;
  final bool locked;
  final String languageCode;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = theme.id == ArinWidgetTheme.classicId
        ? (onDark ? const Color(0xFF1A1F1C) : const Color(0xFF2F3A33))
        : theme.previewBackground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 104,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: bg,
            border: Border.all(
              color: selected
                  ? AppColors.goldAccent
                  : Colors.white.withValues(alpha: 0.12),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      theme.localizedName(languageCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.previewForeground,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (locked)
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: theme.previewForeground.withValues(alpha: 0.85),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '“Sabır güzeldir.”',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.previewForeground.withValues(alpha: 0.88),
                  fontSize: 11,
                  height: 1.25,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
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

// ─── Kilit ekranı bildirim anahtarları (Android) ───────────────────────────

class _LockNotificationToggles extends StatefulWidget {
  const _LockNotificationToggles();

  @override
  State<_LockNotificationToggles> createState() =>
      _LockNotificationTogglesState();
}

class _LockNotificationTogglesState extends State<_LockNotificationToggles> {
  Map<ArinWidgetAccessKind, bool>? _states;
  final _busy = <ArinWidgetAccessKind>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final states = await ArinLockNotificationService.readAll();
    if (!mounted) return;
    setState(() => _states = states);
  }

  Future<void> _toggle(ArinWidgetAccessKind kind, bool value) async {
    final current = _states;
    if (current == null || _busy.contains(kind)) return;
    setState(() {
      _busy.add(kind);
      _states = {...current, kind: value};
    });
    HapticFeedback.selectionClick();
    try {
      final ok = await ArinLockNotificationService.setEnabled(kind, value);
      if (!ok && mounted) {
        // İzin reddedildi (veya yazma başarısız oldu) — anahtarı eski haline al.
        setState(() => _states = {...?_states, kind: !value});
        if (value) {
          showArinTopToast(context, 'Bildirim izni verilmeden kilit ekranı widget\'ı açılamaz.');
        }
      }
    } finally {
      if (mounted) setState(() => _busy.remove(kind));
    }
  }

  static const _order = [
    ArinWidgetAccessKind.prayer,
    ArinWidgetAccessKind.quote,
    ArinWidgetAccessKind.combo,
    ArinWidgetAccessKind.zikir,
    ArinWidgetAccessKind.tracking,
  ];

  (IconData, String, String) _meta(ArinWidgetAccessKind kind) {
    switch (kind) {
      case ArinWidgetAccessKind.prayer:
        return (
          Icons.access_time_rounded,
          'Namaz Vakti',
          'Sıradaki vakti ve geri sayımı kilit ekranında gösterir.',
        );
      case ArinWidgetAccessKind.quote:
        return (
          Icons.format_quote_rounded,
          'Günlük Söz',
          'Günün sözünü kilit ekranında gösterir.',
        );
      case ArinWidgetAccessKind.combo:
        return (
          Icons.widgets_outlined,
          'Söz + Namaz',
          'İkisini tek bildirimde birleştirir.',
        );
      case ArinWidgetAccessKind.zikir:
        return (
          Icons.fingerprint_rounded,
          'Zikirmatik',
          'Aktif zikri ve sayacı kilit ekranında gösterir.',
        );
      case ArinWidgetAccessKind.tracking:
        return (
          Icons.track_changes_rounded,
          'Takip',
          'Seçili gelişim/arınma takibini kilit ekranında gösterir.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final states = _states;
    if (states == null) {
      return _LoadingCard(onDark: onDark);
    }
    return Column(
      children: [
        for (int i = 0; i < _order.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _LockNotificationTile(
            onDark: onDark,
            meta: _meta(_order[i]),
            value: states[_order[i]] ?? false,
            busy: _busy.contains(_order[i]),
            onChanged: (v) => _toggle(_order[i], v),
          ),
        ],
      ],
    );
  }
}

class _LockNotificationTile extends StatelessWidget {
  const _LockNotificationTile({
    required this.onDark,
    required this.meta,
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  final bool onDark;
  final (IconData, String, String) meta;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = meta;
    return _BaseTile(
      onDark: onDark,
      icon: icon,
      title: title,
      subtitle: subtitle,
      selected: value,
      onTap: busy ? null : () => onChanged(!value),
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: ArinLoader(strokeWidth: 2),
            )
          : Switch.adaptive(
              value: value,
              activeThumbColor: AppColors.accentNeonGreen,
              onChanged: onChanged,
            ),
    );
  }
}

/// Xiaomi / Huawei vb. cihazlarda kilit bildiriminin görünmesi için
/// markaya özel adımlar + mümkünse ayar deep-link butonları.
class _OemLockScreenHelpCard extends StatefulWidget {
  const _OemLockScreenHelpCard();

  @override
  State<_OemLockScreenHelpCard> createState() => _OemLockScreenHelpCardState();
}

class _OemLockScreenHelpCardState extends State<_OemLockScreenHelpCard> {
  AndroidOemInfo? _info;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await AndroidOemSettingsService.getInfo();
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
  }

  Future<void> _runOpen(
    Future<AndroidOemOpenResult> Function() action,
    String failMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.selectionClick();
    try {
      final result = await action();
      if (!mounted) return;
      switch (result) {
        case AndroidOemOpenResult.oem:
          break;
        case AndroidOemOpenResult.fallback:
          showArinTopToast(context, 'Özel menü açılamadı; genel ayar sayfası açıldı. Listeden Arın\'ı bul.');
        case AndroidOemOpenResult.failed:
          showArinTopToast(context, failMessage);
      }
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runBool(
    Future<bool> Function() action,
    String failMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.selectionClick();
    try {
      final ok = await action();
      if (!mounted) return;
      if (!ok) {
        showArinTopToast(context, failMessage);
      }
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestBatteryExemption() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.selectionClick();
    try {
      if (_info?.batteryOptimizationsIgnored == true) {
        final r = await AndroidOemSettingsService.openOemBattery();
        if (!mounted) return;
        switch (r) {
          case AndroidOemOpenResult.oem:
            break;
          case AndroidOemOpenResult.fallback:
            showArinTopToast(context, 'Özel menü açılamadı; genel ayar sayfası açıldı. Listeden Arın\'ı bul.');
          case AndroidOemOpenResult.failed:
            showArinTopToast(context, 'Pil menüsü açılamadı.');
        }
      } else {
        final granted = await requestIgnoreBatteryOptimizations();
        if (!granted) {
          final r = await AndroidOemSettingsService.openOemBattery();
          if (!mounted) return;
          if (r == AndroidOemOpenResult.failed) {
            showArinTopToast(context, 'Pil menüsü açılamadı.');
          } else if (r == AndroidOemOpenResult.fallback) {
            showArinTopToast(context, 'Özel menü açılamadı; genel ayar sayfası açıldı. Listeden Arın\'ı bul.');
          }
        }
      }
      if (!mounted) return;
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final info = _info;
    if (info == null || !info.restricted) return const SizedBox.shrink();

    final onDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = onDark
        ? Colors.white.withValues(alpha: 0.96)
        : AppColors.emeraldDark;
    final muted = onDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    final steps = info.lockScreenSteps;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: onDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.72),
        border: Border.all(
          color: onDark
              ? Colors.amber.withValues(alpha: 0.28)
              : Colors.amber.shade700.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.phonelink_setup_rounded,
                size: 22,
                color: onDark
                    ? Colors.amber.shade200
                    : Colors.amber.shade800,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${info.displayName} cihazında kilit bildirimi için',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bu markada sistem arka planda uygulamayı kısıtlayabilir. Aşağıdaki adımları bir kez yapman yeterli.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              height: 1.4,
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: titleColor.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    steps[i],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      height: 1.35,
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (info.canOpenAutoStart)
                _OemActionChip(
                  onDark: onDark,
                  label: info.autoStartChipLabel,
                  icon: Icons.play_circle_outline_rounded,
                  enabled: !_busy,
                  onTap: () => _runOpen(
                    AndroidOemSettingsService.openAutoStart,
                    'Otomatik başlatma sayfası açılamadı. Uygulama ayarlarından dene.',
                  ),
                ),
              if (!info.batteryOptimizationsIgnored)
                _OemActionChip(
                  onDark: onDark,
                  label: 'Pil kısıtını kaldır',
                  icon: Icons.battery_charging_full_rounded,
                  enabled: !_busy,
                  emphasized: true,
                  onTap: _requestBatteryExemption,
                )
              else if (info.canOpenOemBattery ||
                  info.family == AndroidOemFamily.samsung ||
                  info.family == AndroidOemFamily.other)
                _OemActionChip(
                  onDark: onDark,
                  label: info.batteryChipLabel,
                  icon: Icons.settings_power_rounded,
                  enabled: !_busy,
                  onTap: () => _runOpen(
                    AndroidOemSettingsService.openOemBattery,
                    'Pil menüsü açılamadı.',
                  ),
                ),
              _OemActionChip(
                onDark: onDark,
                label: 'Uygulama ayarları',
                icon: Icons.settings_outlined,
                enabled: !_busy,
                onTap: () => _runBool(
                  AndroidOemSettingsService.openAppDetails,
                  'Uygulama ayarları açılamadı.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OemActionChip extends StatelessWidget {
  const _OemActionChip({
    required this.onDark,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.emphasized = false,
  });

  final bool onDark;
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final bg = emphasized
        ? AppColors.accentNeonGreen.withValues(alpha: onDark ? 0.22 : 0.18)
        : (onDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.creamDark.withValues(alpha: 0.55));
    final fg = emphasized
        ? (onDark ? AppColors.accentNeonGreen : AppColors.emeraldDark)
        : (onDark
              ? Colors.white.withValues(alpha: 0.9)
              : AppColors.emeraldDark.withValues(alpha: 0.9));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: emphasized
                  ? AppColors.accentNeonGreen.withValues(alpha: 0.45)
                  : (onDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.creamDark),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
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
        child: ArinLoader(strokeWidth: 2),
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
        ? const Color(0xFFFFF4E6)
        : const Color(0xFF4A2C1A);
    final muted = onDark ? const Color(0xFFD8C0A7) : const Color(0xFF79583D);
    final accent = onDark ? AppColors.ornamentGold : AppColors.ornamentGoldDeep;
    final badgeText = onDark
        ? const Color(0xFFFFE1A8)
        : const Color(0xFF4A2A16);
    final gradient = onDark
        ? const [Color(0xFF3A281D), Color(0xFF211914)]
        : const [Color(0xFFFFF2DF), Color(0xFFF1D7B5)];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF6B3F20,
                ).withValues(alpha: onDark ? 0.3 : 0.18),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                top: -24,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.08),
                    border: Border.all(color: accent.withValues(alpha: 0.12)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: accent.withValues(alpha: 0.16),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.52),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.smartphone_rounded,
                            size: 25,
                            color: accent,
                          ),
                          Positioned(
                            right: 7,
                            bottom: 7,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: onDark
                                    ? const Color(0xFF2B2018)
                                    : const Color(0xFFF8E7D0),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 10,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'ADIM ADIM REHBER',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: badgeText,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kilit ekranına nasıl eklenir?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            Platform.isIOS
                                ? 'iPhone için görselli kurulumu aç'
                                : 'Android için görselli kurulumu aç',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: accent,
                        size: 17,
                      ),
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
}

// ─── How-to bottom sheet ────────────────────────────────────────────────────

class _HowToSheet extends StatefulWidget {
  const _HowToSheet({required this.onDark});

  final bool onDark;

  @override
  State<_HowToSheet> createState() => _HowToSheetState();
}

class _HowToSheetState extends State<_HowToSheet> {
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
                  Expanded(
                    child: Text(
                      'Kilit ekranı widget rehberi',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _StepList(
                controller: controller,
                onDark: onDark,
                sections: Platform.isIOS
                    ? _iosLockScreenSteps
                    : _androidLockScreenSteps,
              ),
            ),
          ],
        ),
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

  final ScrollController? controller;
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
        title: 'Önce cihaz desteğini kontrol et',
        subtitle:
            'Android\'de üçüncü taraf kilit ekranı widgetları her sürüm ve markada desteklenmez. Ayarlarda "Kilit ekranı widgetları" seçeneği yoksa Arın\'ı ana ekrana ekleyebilirsin.',
        imagePath: 'assets/images/widget_guide/android_lock_1.png',
      ),
      _Step(
        icon: Icons.lock_outline_rounded,
        title: 'Destekleniyorsa kilit ekranı ayarlarını aç',
        subtitle:
            'Ayarlar > Kilit ekranı bölümündeki Widgetlar veya Araçlar seçeneğini kullan. Menü adı Samsung, Xiaomi, Pixel ve diğer cihazlarda değişebilir.',
        imagePath: 'assets/images/widget_guide/android_lock_2.png',
      ),
      _Step(
        icon: Icons.widgets_outlined,
        title: "Listede görünüyorsa Arın'ı seç",
        subtitle:
            "Cihazın üçüncü taraf widgetları destekliyorsa Arın'ı bul; söz, namaz veya takip widgetını seçip konumunu ayarla.",
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
