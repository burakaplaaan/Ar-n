// Sigara bırakma — uyarı, listeler, söz metni, mühür (PageView).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/willpower_templates.dart';
import '../../core/router/app_router.dart';
import '../../core/willpower/quit_commitment_chips.dart';
import '../../data/willpower/willpower_content_loader.dart';
import '../shared/providers/habit_providers.dart';
import '../shared/providers/willpower_hub_nav_provider.dart';
import '../shared/widgets/arin_shell_layout.dart';
import '../shared/widgets/commitment_seal_widget.dart';
import 'widgets/commitment_example_chips.dart';
import 'widgets/commitment_input_tokens.dart';

class QuitOnboardingFlowPage extends ConsumerStatefulWidget {
  const QuitOnboardingFlowPage({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<QuitOnboardingFlowPage> createState() =>
      _QuitOnboardingFlowPageState();
}

class _QuitOnboardingFlowPageState
    extends ConsumerState<QuitOnboardingFlowPage> {
  final PageController _page = PageController();
  final TextEditingController _commitment = TextEditingController();
  QuitProgramOnboardingContent? _content;
  bool _loading = true;
  int _pageIndex = 0;
  String? _loadedLocaleCode;

  void _loadOnboarding() {
    final localeCode = Localizations.localeOf(context).languageCode;
    _loadedLocaleCode = localeCode;
    final repo = ref.read(habitRepositoryProvider);
    final h = repo.getById(widget.habitId);
    final tid = h?.templateId;
    if (tid == null || !WillpowerTemplates.isFullQuitProgram(tid)) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    QuitProgramOnboardingContent.loadForTemplate(
      tid,
      localeCode: localeCode,
    )
        .then((c) {
          if (mounted) {
            setState(() {
              _content = c;
              _loading = false;
            });
          }
        })
        .catchError((_) {
          if (mounted) {
            setState(() {
              _content = null;
              _loading = false;
            });
          }
        });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOnboarding());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocaleCode = Localizations.localeOf(context).languageCode;
    if (_loadedLocaleCode != null &&
        _loadedLocaleCode != currentLocaleCode &&
        !_loading) {
      setState(() {
        _loading = true;
        _content = null;
      });
      _loadOnboarding();
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _commitment.dispose();
    super.dispose();
  }

  IconData _icon(String k) {
    switch (k) {
      case 'psychology':
        return Icons.psychology_outlined;
      case 'favorite':
        return Icons.favorite_border_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'mosque':
        return Icons.mosque_outlined;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  int _segmentFilled() {
    if (_pageIndex >= 4) return 5;
    return (_pageIndex + 1).clamp(1, 5);
  }

  Future<void> _next() async {
    final l10n = AppLocalizations.of(context)!;
    if (_pageIndex == 3) {
      final t = _commitment.text.trim();
      if (t.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.quitOnboardingCommitmentMinLengthError),
          ),
        );
        return;
      }
    }
    await _page.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _back() async {
    if (_pageIndex == 0) {
      if (!mounted) return;
      await _exitFlowToArinma();
      return;
    }
    await _page.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Kriz anı kısa yolu: ahdini yazmadan sayacı başlat, program home'a geç.
  /// Kullanıcı dilediği zaman oradaki "Ahdini tamamla" banner'ıyla buraya
  /// geri dönüp onboarding'i tamamlayabilir.
  Future<void> _onQuickStart() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.anthraciteMid,
        title: Text(
          l10n.quitOnboardingQuickStartTitle,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.creamBase),
        ),
        content: Text(
          l10n.quitOnboardingQuickStartBody,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.quitOnboardingAbortAction,
              style: const TextStyle(color: AppColors.creamBase),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonStart),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref
        .read(habitSummaryProvider.notifier)
        .quickStartQuitClock(widget.habitId);
    final habit = ref.read(habitRepositoryProvider).getById(widget.habitId);
    unawaited(
      ArinAnalytics.arinmaStart(
        habit?.quitSubtype ?? habit?.templateId ?? 'quit',
      ),
    );
    if (mounted) {
      context.go(AppRoutes.willQuitHome(widget.habitId));
    }
  }

  /// [ArinShell] alt çubuğu + extendBody gövdeyi kapladığı için gerçek içerik bu kadar yukarıda bitmeli.
  double _shellBottomReserve(BuildContext context) {
    return ArinShellLayout.bottomContentPadding(context);
  }

  double _actionBottomInset(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return (bottom + 10).clamp(10, 26).toDouble();
  }

  bool get _hasDraftProgress =>
      _pageIndex > 0 || _commitment.text.trim().isNotEmpty;

  Future<void> _exitFlowToArinma() async {
    final l10n = AppLocalizations.of(context)!;
    if (_hasDraftProgress) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.anthraciteMid,
          title: Text(
            l10n.quitOnboardingExitDraftTitle,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.creamBase,
            ),
          ),
          content: Text(
            l10n.quitOnboardingExitDraftBody,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l10n.quitOnboardingStayAction,
                style: const TextStyle(color: AppColors.creamBase),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.quitOnboardingExitAction),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    ref.read(willpowerHubReturnToArinmaProvider.notifier).state = true;
    popOrGoWillpowerHub(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final repo = ref.watch(habitRepositoryProvider);
    final habit = repo.getById(widget.habitId);
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

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.anthraciteDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentNeonGreen),
        ),
      );
    }
    if (_content == null) {
      return Scaffold(
        backgroundColor: AppColors.anthraciteDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.creamBase,
            ),
            onPressed: () {
              ref.read(willpowerHubReturnToArinmaProvider.notifier).state =
                  true;
              popOrGoWillpowerHub(context);
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.quitOnboardingContentLoadFailed,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnDarkMuted,
              ),
            ),
          ),
        ),
      );
    }
    final c = _content!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_back());
      },
      child: Scaffold(
        backgroundColor: AppColors.anthraciteDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.creamBase,
            ),
            onPressed: _back,
          ),
          title: Text(
            l10n.quitOnboardingAppBarTitle,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.creamBase,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: List.generate(5, (i) {
                  final filled = i < _segmentFilled();
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 4 ? 6 : 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: filled
                              ? Colors.orange.shade600
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _pageIndex = i),
                children: [
                  _WarningPage(content: c),
                  _ListInfoPage(
                    title: c.physicalTitle,
                    items: c.physicalItems,
                    iconBuilder: _icon,
                  ),
                  _SpiritualPage(content: c, iconBuilder: _icon),
                  _CommitmentInputPage(
                    controller: _commitment,
                    chips: quitCommitmentChipsFor(
                      habit.templateId,
                      localeCode: localeCode,
                    ),
                    templateId: habit.templateId,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: _shellBottomReserve(context),
                    ),
                    child: CommitmentSealWidget(
                      displayNameSuffix: '',
                      titlePrefix: l10n.quitOnboardingSealTitlePrefix,
                      infoBannerText: _commitment.text.trim().length > 120
                          ? '${_commitment.text.trim().substring(0, 120)}…'
                          : _commitment.text.trim(),
                      accentColor: Colors.amber.shade600,
                      progressTrackColor: Colors.white.withValues(alpha: 0.12),
                      showSkip: false,
                      holdHint: l10n.quitOnboardingSealHoldHint,
                      onCompleted: () async {
                        await ref
                            .read(habitSummaryProvider.notifier)
                            .completeQuitOnboarding(
                              habitId: widget.habitId,
                              commitmentText: _commitment.text.trim(),
                            );
                        final habit = ref
                            .read(habitRepositoryProvider)
                            .getById(widget.habitId);
                        unawaited(
                          ArinAnalytics.arinmaStart(
                            habit?.quitSubtype ?? habit?.templateId ?? 'quit',
                          ),
                        );
                        if (context.mounted) {
                          context.go(AppRoutes.willQuitHome(widget.habitId));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_pageIndex < 4)
              SafeArea(
                top: false,
                minimum: EdgeInsets.fromLTRB(
                  14,
                  8,
                  14,
                  _actionBottomInset(context),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _back,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: AppColors.creamBase,
                            ),
                            label: Text(
                              l10n.commonBack,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.creamBase,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _next,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            label: Text(l10n.quitOnboardingContinueAction),
                          ),
                        ],
                      ),
                      if (_pageIndex == 0) ...[
                        const SizedBox(height: 2),
                        TextButton.icon(
                          onPressed: _onQuickStart,
                          icon: Icon(
                            Icons.flash_on_rounded,
                            size: 18,
                            color: Colors.orange.shade300,
                          ),
                          label: Text(
                            l10n.quitOnboardingQuickStartInlineAction,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.orange.shade200,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WarningPage extends StatelessWidget {
  const _WarningPage({required this.content});

  final QuitProgramOnboardingContent content;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.warning_amber_rounded,
      size: 56,
      color: Colors.orange.shade400,
    );
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        Center(child: icon.animate().shake(hz: 2, duration: 400.ms)),
        const SizedBox(height: 20),
        Text(
          content.warningTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.creamBase,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content.warningSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
        const SizedBox(height: 24),
        ...content.warningBody.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '• ${e.value}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.creamBase.withValues(alpha: 0.9),
                height: 1.45,
              ),
            ).animate().fadeIn(delay: (80 * e.key).ms),
          ),
        ),
      ],
    );
  }
}

class _ListInfoPage extends StatelessWidget {
  const _ListInfoPage({
    required this.title,
    required this.items,
    required this.iconBuilder,
  });

  final String title;
  final List<QuitItem> items;
  final IconData Function(String) iconBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.creamBase,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...items.asMap().entries.map(
          (e) => ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withValues(alpha: 0.25),
                    Colors.deepOrange.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Icon(
                iconBuilder(e.value.iconKey),
                color: Colors.orange.shade200,
              ),
            ),
            title: Text(
              e.value.title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.creamBase,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              e.value.subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textOnDarkMuted,
              ),
            ),
          ).animate().fadeIn(delay: (80 * e.key).ms),
        ),
      ],
    );
  }
}

class _SpiritualPage extends StatelessWidget {
  const _SpiritualPage({required this.content, required this.iconBuilder});

  final QuitProgramOnboardingContent content;
  final IconData Function(String) iconBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Text(
          content.spiritualTitle,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.creamBase,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...content.spiritualItems.asMap().entries.map(
          (e) => ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withValues(alpha: 0.2),
                    Colors.lightGreen.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.27)),
              ),
              child: Icon(
                iconBuilder(e.value.iconKey),
                color: Colors.amber.shade300,
              ),
            ),
            title: Text(
              e.value.title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.creamBase,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              e.value.subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textOnDarkMuted,
              ),
            ),
          ).animate().fadeIn(delay: (80 * e.key).ms),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.verseText,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.creamBase,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 8),
              Text(
                content.verseRef,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommitmentInputPage extends StatelessWidget {
  const _CommitmentInputPage({
    required this.controller,
    required this.chips,
    required this.templateId,
  });

  final TextEditingController controller;
  final Map<String, String> chips;
  final String templateId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Row(
          children: [
            Icon(Icons.mosque_rounded, size: 20, color: Colors.orange.shade300),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.quitOnboardingCommitmentTitle,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.creamBase,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.quitOnboardingCommitmentSubtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLength: 280,
            maxLines: 4,
            cursorColor: AppColors.accentNeonGreen,
            style: commitmentInputTextStyle(color: AppColors.creamBase),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.quitOnboardingCommitmentHint,
              hintStyle: commitmentInputHintStyle(),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.orange.shade300.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
              counterStyle: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textOnDarkMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        CommitmentExampleChips(
          chips: chips,
          controller: controller,
          insertMode: CommitmentChipInsertMode.appendWithSpace,
          sectionTitle: AppLocalizations.of(context)!.quitOnboardingExamplesSectionTitle,
          accentColor: templateId == WillpowerTemplates.quitSmoking
              ? const Color(0xFFFF8A65)
              : AppColors.accentNeonGreen,
        ),
      ],
    );
  }
}
