// Özel alışkanlık — Gelişim (yeşil) / Arınma (kırmızı); hedef + döngü (çark), not.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/arin_shell_background.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../data/models/habit_model.dart';
import '../shared/providers/habit_providers.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';

const Color _kArinmaAccent = Color(0xFFFF5252);

class AddHabitPage extends ConsumerStatefulWidget {
  const AddHabitPage({super.key});

  @override
  ConsumerState<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends ConsumerState<AddHabitPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  bool _goalPickerOpen = false;
  /// 0 günlük, 1 haftalık, 2 aylık
  int _repeatCycle = 0;
  bool _saving = false;

  HabitType _type = HabitType.good;

  List<String> _getWheelUnits(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.addHabitUnitTimes,
      l10n.addHabitUnitMinutes,
      l10n.addHabitUnitHours,
      l10n.addHabitUnitPages,
      l10n.addHabitUnitGlasses,
      l10n.addHabitUnitSets,
      l10n.addHabitUnitLaps,
      '%',
    ];
  }

  late FixedExtentScrollController _amountController;
  late FixedExtentScrollController _unitController;

  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _amountController = FixedExtentScrollController(initialItem: 4);
    _unitController = FixedExtentScrollController(initialItem: 0);
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is HabitType) {
      if (_type != extra) {
        setState(() => _type = extra);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Color get _accent =>
      _type == HabitType.bad ? _kArinmaAccent : AppColors.accentNeonGreen;

  int get _amount => _amountController.hasClients
      ? _amountController.selectedItem + 1
      : 5;

  int get _unitIndex => _unitController.hasClients
      ? _unitController.selectedItem
      : 0;

  String _getUnit(BuildContext context) {
    final units = _getWheelUnits(context);
    return units[_unitIndex.clamp(0, units.length - 1)];
  }

  int get _maxAmountForUnit {
    if (!mounted) return 99;
    return _getUnit(context) == '%' ? 100 : 99;
  }

  int _trackingKindForUnit(String u, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (u == '%') return 2;
    if (u == l10n.addHabitUnitMinutes || u == l10n.addHabitUnitHours) return 1;
    return 0;
  }

  void _onUnitChanged(int index, BuildContext context) {
    final maxA = _getWheelUnits(context)[index] == '%' ? 100 : 99;
    final current = _amount;
    if (current > maxA && _amountController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_amountController.hasClients) return;
        _amountController.jumpToItem(maxA - 1);
      });
    }
  }

  List<String> _getRepeatLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [l10n.addHabitDaily, l10n.addHabitWeekly, l10n.addHabitMonthly];
  }

  String _goalSummaryLine(BuildContext context) {
    final unit = _getUnit(context);
    final l10n = AppLocalizations.of(context)!;
    switch (_repeatCycle.clamp(0, 2)) {
      case 1:
        return l10n.addHabitSummaryWeekly(_amount, unit);
      case 2:
        return l10n.addHabitSummaryMonthly(_amount, unit);
      default:
        return l10n.addHabitSummaryDaily(_amount, unit);
    }
  }

  Future<void> _openRepeatCycleSheet() async {
    HapticFeedback.selectionClick();
    var chosen = _repeatCycle.clamp(0, 2);
    final controller = FixedExtentScrollController(initialItem: chosen);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(ctx).bottom + 8,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF121814),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(color: _accent.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          AppLocalizations.of(context)!.addHabitCancel,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.creamBase.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() => _repeatCycle = chosen.clamp(0, 2));
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          AppLocalizations.of(context)!.addHabitOk,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: _accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListWheelScrollView.useDelegate(
                    controller: controller,
                    itemExtent: 44,
                    perspective: 0.003,
                    diameterRatio: 1.9,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => chosen = i,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 3,
                      builder: (_, i) => Center(
                        child: Text(
                          _getRepeatLabels(context)[i],
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.creamBase,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final target = _amount.clamp(1, _maxAmountForUnit);
    final unit = _getUnit(context);
    final kind = _trackingKindForUnit(unit, context);

    setState(() => _saving = true);
    try {
      final h = await ref.read(habitSummaryProvider.notifier).addCustomHabit(
            title: _titleController.text.trim(),
            type: _type,
            emoji: _type == HabitType.bad ? '◆' : '▲',
            note: _noteController.text.trim(),
            customTarget: target.clamp(1, 999999),
            customUnit: kind == 2 ? '%' : unit,
            customTrackingKind: kind,
            customFlexible: false,
            customMinTarget: 0,
            customRepeatCycle: _repeatCycle.clamp(0, 2),
          );
      if (mounted) {
        // Atölye ekranını stack'te bırakma: kayıt sonrası doğrudan detay
        // ekranına geçip geri akışını sadeleştir.
        context.go(AppRoutes.customHabitDetail(h.id));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGelisim = _type == HabitType.good;
    final l10n = AppLocalizations.of(context)!;
    final nameLabel = isGelisim ? l10n.addHabitGrowthName : l10n.addHabitPurificationName;
    final categoryLabel = isGelisim ? l10n.habitsGrowth : l10n.habitsPurification;
    final light = ArinShellBackground.isLight(context);

    return Scaffold(
      backgroundColor:
          light ? AppColors.creamMist : AppColors.anthraciteDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: _saving ? null : () => context.pop(),
          child: Text(
            l10n.addHabitCancel,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.shellOnCanvasPrimary(context)
                  .withValues(alpha: 0.88),
            ),
          ),
        ),
        leadingWidth: 72,
        title: Text(
          l10n.addHabitCustom,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.shellOnCanvasPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: ArinLoader(
                      strokeWidth: 2,
                      color: _accent,
                    ),
                  )
                : Text(
                    l10n.addHabitSave,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _FadeSlideIn(
              animation: CurvedAnimation(
                parent: _staggerController,
                curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.5),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.18),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    nameLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: _accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accent.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categoryLabel,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.shellOnCanvasSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _FadeSlideIn(
              animation: CurvedAnimation(
                parent: _staggerController,
                curve: const Interval(0.12, 0.55, curve: Curves.easeOutCubic),
              ),
              child: _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(icon: Icons.title_rounded, text: nameLabel),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.shellOnCanvasPrimary(context),
                      ),
                      decoration: _inputDeco(
                        context,
                        hint: isGelisim
                            ? l10n.addHabitGrowthHint
                            : l10n.addHabitPurificationHint,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.addHabitNameRequired;
                        }
                        if (v.trim().length > 60) {
                          return l10n.addHabitNameTooLong;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FadeSlideIn(
              animation: CurvedAnimation(
                parent: _staggerController,
                curve: const Interval(0.22, 0.68, curve: Curves.easeOutCubic),
              ),
              child: _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryExpandTile(
                      accent: _accent,
                      expanded: _goalPickerOpen,
                      summaryText: _goalSummaryLine(context),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _goalPickerOpen = !_goalPickerOpen);
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _goalPickerOpen
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: _DualWheelPicker(
                                accent: _accent,
                                amountController: _amountController,
                                unitController: _unitController,
                                maxAmount: _maxAmountForUnit,
                                units: _getWheelUnits(context),
                                onAmountChanged: (_) => setState(() {}),
                                onUnitChanged: (i) {
                                  setState(() => _onUnitChanged(i, context));
                                },
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: 18),
                    _RepeatCycleSummaryTile(
                      accent: _accent,
                      label: _getRepeatLabels(context)[_repeatCycle.clamp(0, 2)],
                      onTap: _openRepeatCycleSheet,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FadeSlideIn(
              animation: CurvedAnimation(
                parent: _staggerController,
                curve: const Interval(0.35, 0.88, curve: Curves.easeOutCubic),
              ),
              child: _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(
                      icon: Icons.note_outlined,
                      text: l10n.addHabitNoteOptional,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      maxLength: 500,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.shellOnCanvasPrimary(context),
                      ),
                      decoration:
                          _inputDeco(context, hint: l10n.addHabitNoteHint),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(BuildContext context, {required String hint}) {
    final light = ArinShellBackground.isLight(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: light
            ? AppColors.textSecondary.withValues(alpha: 0.65)
            : AppColors.textOnDarkMuted.withValues(alpha: 0.65),
      ),
      filled: true,
      fillColor: light
          ? Colors.white.withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: light
              ? Colors.black.withValues(alpha: 0.08)
              : AppColors.creamBase.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: light
              ? Colors.black.withValues(alpha: 0.06)
              : AppColors.creamBase.withValues(alpha: 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _accent.withValues(alpha: 0.45)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _SummaryExpandTile extends StatelessWidget {
  const _SummaryExpandTile({
    required this.accent,
    required this.expanded,
    required this.summaryText,
    required this.onTap,
  });

  final Color accent;
  final bool expanded;
  final String summaryText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: expanded
                ? accent.withValues(alpha: 0.1)
                : (light
                    ? Colors.black.withValues(alpha: 0.03)
                    : Colors.white.withValues(alpha: 0.05)),
            border: Border.all(
              color: expanded
                  ? accent.withValues(alpha: 0.42)
                  : (light
                      ? Colors.black.withValues(alpha: 0.08)
                      : AppColors.creamBase.withValues(alpha: 0.1)),
              width: expanded ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  summaryText,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.shellOnCanvasPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.expand_more_rounded,
                  color: accent.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Döngü seçimi — dokununca alttan çark (Günlük / Haftalık / Aylık).
class _RepeatCycleSummaryTile extends StatelessWidget {
  const _RepeatCycleSummaryTile({
    required this.accent,
    required this.label,
    required this.onTap,
  });

  final Color accent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: light
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: light
                  ? Colors.black.withValues(alpha: 0.08)
                  : AppColors.creamBase.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.shellOnCanvasPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                color: accent.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DualWheelPicker extends StatelessWidget {
  const _DualWheelPicker({
    required this.accent,
    required this.amountController,
    required this.unitController,
    required this.maxAmount,
    required this.units,
    required this.onAmountChanged,
    required this.onUnitChanged,
  });

  final Color accent;
  final FixedExtentScrollController amountController;
  final FixedExtentScrollController unitController;
  final int maxAmount;
  final List<String> units;
  final ValueChanged<int> onAmountChanged;
  final ValueChanged<int> onUnitChanged;

  static const double _itemExtent = 40;
  static const double _height = 196;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: const Color(0xFF0A100C).withValues(alpha: 0.92),
          border: Border.all(
            color: accent.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: amountController,
                    itemExtent: _itemExtent,
                    perspective: 0.0032,
                    diameterRatio: 1.85,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: onAmountChanged,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: maxAmount,
                      builder: (context, index) {
                        final n = index + 1;
                        return Center(
                          child: Text(
                            '$n',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.creamBase.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  color: AppColors.creamBase.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: unitController,
                    itemExtent: _itemExtent,
                    perspective: 0.0032,
                    diameterRatio: 1.85,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: onUnitChanged,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: units.length,
                      builder: (context, index) {
                        final u = units[index];
                        return Center(
                          child: Text(
                            u,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.creamBase
                                  .withValues(alpha: 0.88),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            IgnorePointer(
              child: Container(
                height: _itemExtent + 4,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.0),
                      accent.withValues(alpha: 0.07),
                      accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light = ArinShellBackground.isLight(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: light
            ? Colors.white.withValues(alpha: 0.88)
            : const Color(0xFF121814).withValues(alpha: 0.85),
        border: Border.all(
          color: light
              ? Colors.black.withValues(alpha: 0.08)
              : AppColors.creamBase.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.shellOnCanvasSecondary(context),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.shellOnCanvasPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
