// Kaza namazı — bilgi ve tahmini hesap ekranı.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../data/models/kaza_tracking_state.dart';
import '../../data/services/kaza_calculator.dart';
import 'kaza_tracking_provider.dart';
import 'kaza_widgets.dart';
import 'package:arin/presentation/shared/widgets/arin_popup.dart';
import 'package:arin/presentation/shared/widgets/arin_top_toast.dart';

class KazaCalculatorPage extends ConsumerStatefulWidget {
  const KazaCalculatorPage({super.key});

  @override
  ConsumerState<KazaCalculatorPage> createState() =>
      _KazaCalculatorPageState();
}

class _KazaCalculatorPageState extends ConsumerState<KazaCalculatorPage> {
  final _pubertyCtl = TextEditingController();
  final _prayedCtl = TextEditingController();
  bool _seeded = false;
  bool _isFemale = false;
  DateTime _birthDate = DateTime.now();

  void _onFormFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _pubertyCtl.addListener(_onFormFieldChanged);
    _prayedCtl.addListener(_onFormFieldChanged);
  }

  @override
  void dispose() {
    _pubertyCtl.removeListener(_onFormFieldChanged);
    _prayedCtl.removeListener(_onFormFieldChanged);
    _pubertyCtl.dispose();
    _prayedCtl.dispose();
    super.dispose();
  }

  static DateTime _todayOnly() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Gelecek veya çok eski tarih showDatePicker / hesabı bozar.
  static DateTime _clampBirthDate(DateTime d) {
    final t = _todayOnly();
    final first = DateTime(1940, 1, 1);
    var x = DateTime(d.year, d.month, d.day);
    if (x.isAfter(t)) x = t;
    if (x.isBefore(first)) x = first;
    return x;
  }

  void _seedFromState(KazaTrackingState s) {
    if (_seeded) return;
    _seeded = true;
    _isFemale = s.isFemale;
    _birthDate = _clampBirthDate(s.birthDate ?? DateTime.now());
    // Kutucuklar varsayılan boş; yalnızca daha önce kayıtlı pozitif değer varsa doldur.
    if (s.pubertyAge > 0) {
      _pubertyCtl.text = '${s.pubertyAge}';
    }
    if (s.prayedDaysRecorded > 0) {
      _prayedCtl.text = '${s.prayedDaysRecorded}';
    }
  }

  Future<void> _pickBirthDate() async {
    final today = _todayOnly();
    final firstDate = DateTime(1940, 1, 1);
    final initial = _clampBirthDate(_birthDate);
    var selected = initial;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
      builder: (ctx) {
        final pad = MediaQuery.paddingOf(ctx);
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: pad.bottom),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.anthraciteDark,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppLocalizations.of(context)!.kazaCalcBirthDate,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.creamBase,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMMd('tr_TR').format(selected),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textOnDarkMuted,
                      ),
                    ),
                    SizedBox(
                      height: 216,
                      child: CupertinoTheme(
                        data: const CupertinoThemeData(
                          brightness: Brightness.dark,
                          primaryColor: AppColors.accentNeonGreen,
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                              color: AppColors.creamBase,
                              fontSize: 21,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: initial,
                          minimumDate: firstDate,
                          maximumDate: today,
                          dateOrder: DatePickerDateOrder.mdy,
                          onDateTimeChanged: (d) {
                            selected = d;
                            setModalState(() {});
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (mounted) {
                              setState(
                                () => _birthDate = _clampBirthDate(selected),
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentNeonGreen,
                            foregroundColor: const Color(0xFF052E16),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.kazaCalcApply,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: const Color(0xFF052E16),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmOverwrite() async {
    final l10n = AppLocalizations.of(context)!;
    final r = await showArinConfirm(
      context: context,
      title: l10n.kazaCalcUpdateCounters,
      message: l10n.kazaCalcUpdateDesc,
      cancelLabel: l10n.kazaCalcCancel,
      confirmLabel: l10n.kazaCalcContinue,
      icon: Icons.sync_rounded,
    );
    return r;
  }

  Future<void> _onCalculate() async {
    final puberty = int.tryParse(_pubertyCtl.text.trim()) ?? 0;
    final prayed = int.tryParse(_prayedCtl.text.trim()) ?? 0;

    final r = KazaCalculator.compute(
      birthDate: _birthDate,
      pubertyAgeInput: puberty,
      isFemale: _isFemale,
      prayedFullDays: prayed,
    );

    // Canlı özet ile aynı: buluğ bugünden sonraysa kalan namaz 0; kullanıcı yine de
    // Hesapla’ya basmasın diye erken çık.
    if (r.inclusiveCalendarDays == 0) {
      if (!mounted) return;
      showArinTopToast(context, AppLocalizations.of(context)!.kazaCalcErrorPubertyFuture);
      return;
    }

    final cur = ref.read(kazaTrackingProvider);
    if (cur.total > 0) {
      final ok = await _confirmOverwrite();
      if (!ok) return;
    }

    await ref.read(kazaTrackingProvider.notifier).commitKazaCalculation(
          isFemale: _isFemale,
          birthDate: _birthDate,
          pubertyAge: puberty,
          // Hesapta kullanılan üst sınır (borçlu günü aşan girişler kesilir).
          prayedDaysRecorded: r.prayedFullDaysApplied,
          remainingPrayers: r.remainingPrayers,
        );
    ref.invalidate(kazaTrackingProvider);

    if (!mounted) return;
    if (r.remainingPrayers == 0) {
      showArinTopToast(context, AppLocalizations.of(context)!.kazaCalcErrorZeroRemaining);
    }
    if (mounted) context.push(AppRoutes.kazaTracker);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(kazaTrackingProvider);
    _seedFromState(s);

    final dateLabel = DateFormat.yMMMMd('tr_TR').format(_birthDate);
    final minPuberty = KazaCalculator.minPubertyAge(isFemale: _isFemale);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KazaPageBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.creamBase.withValues(alpha: 0.9),
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.kazaCalcTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.creamBase,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    KazaSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.kazaCalcSubtitle,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.creamBase,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppLocalizations.of(context)!.kazaCalcDesc,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textOnDarkMuted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.kazaCalcFemaleNote,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.accentNeonGreen
                                  .withValues(alpha: 0.85),
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppLocalizations.of(context)!.kazaCalcFormula,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textOnDarkMuted
                                  .withValues(alpha: 0.88),
                              height: 1.42,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 380.ms, curve: Curves.easeOutCubic)
                        .slideY(
                          begin: 0.06,
                          duration: 420.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 16),
                    KazaSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.kazaCalcCalculateTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.creamBase,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppLocalizations.of(context)!.kazaCalcGender,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textOnDarkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _GenderChip(
                                  label: AppLocalizations.of(context)!.kazaCalcMale,
                                  selected: !_isFemale,
                                  onTap: () =>
                                      setState(() => _isFemale = false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _GenderChip(
                                  label: AppLocalizations.of(context)!.kazaCalcFemale,
                                  selected: _isFemale,
                                  onTap: () =>
                                      setState(() => _isFemale = true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            AppLocalizations.of(context)!.kazaCalcBirthDateTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textOnDarkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickBirthDate,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.black.withValues(alpha: 0.28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Text(
                                  dateLabel,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: AppColors.creamBase,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            AppLocalizations.of(context)!.kazaCalcPubertyAge,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textOnDarkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.kazaCalcPubertyNote(minPuberty),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textOnDarkMuted
                                  .withValues(alpha: 0.75),
                              fontSize: 10.5,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          KazaNumberField(
                            controller: _pubertyCtl,
                            hint: '',
                            compact: true,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            AppLocalizations.of(context)!.kazaCalcPrayedDays,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textOnDarkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.kazaCalcPrayedDaysNote,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textOnDarkMuted
                                  .withValues(alpha: 0.75),
                              fontSize: 10.5,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          KazaNumberField(
                            controller: _prayedCtl,
                            hint: '',
                            compact: true,
                          ),
                          const SizedBox(height: 18),
                          _LiveCalculationSummary(
                            birthDate: _birthDate,
                            isFemale: _isFemale,
                            pubertyText: _pubertyCtl.text,
                            prayedText: _prayedCtl.text,
                          ),
                          const SizedBox(height: 22),
                          KazaPrimaryButton(
                            label: AppLocalizations.of(context)!.kazaCalcCalculate,
                            onPressed: _onCalculate,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(
                          duration: 420.ms,
                          delay: 80.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(
                          begin: 0.07,
                          duration: 460.ms,
                          delay: 80.ms,
                          curve: Curves.easeOutCubic,
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

class _LiveCalculationSummary extends StatelessWidget {
  const _LiveCalculationSummary({
    required this.birthDate,
    required this.isFemale,
    required this.pubertyText,
    required this.prayedText,
  });

  final DateTime birthDate;
  final bool isFemale;
  final String pubertyText;
  final String prayedText;

  @override
  Widget build(BuildContext context) {
    final puberty = int.tryParse(pubertyText.trim()) ?? 0;
    final prayed = int.tryParse(prayedText.trim()) ?? 0;
    final r = KazaCalculator.compute(
      birthDate: birthDate,
      pubertyAgeInput: puberty,
      isFemale: isFemale,
      prayedFullDays: prayed,
    );

    if (r.inclusiveCalendarDays == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.kazaCalcLiveError,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textOnDarkMuted,
            height: 1.4,
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final hayizLine = r.hayizExemptDays > 0
        ? l10n.kazaCalcLiveHayiz(r.hayizExemptDays)
        : '';
    final appliedNote = r.prayedFullDaysInput != r.prayedFullDaysApplied
        ? l10n.kazaCalcLiveApplied(r.prayedFullDaysApplied)
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.accentNeonGreen.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.accentNeonGreen.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.kazaCalcLiveSummary,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accentNeonGreen,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.kazaCalcLiveCalendarDays(r.inclusiveCalendarDays) +
            hayizLine +
            l10n.kazaCalcLiveLiableDays(r.effectiveLiableDays) +
            l10n.kazaCalcLiveOwed(
              KazaCalculator.prayersPerLiableDay,
              r.totalPrayersOwed,
            ) +
            l10n.kazaCalcLiveCredited(
              KazaCalculator.prayersPerLiableDay,
              r.prayersCredited,
              appliedNote,
            ) +
            l10n.kazaCalcLiveRemaining(r.remainingPrayers),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.creamBase.withValues(alpha: 0.92),
              height: 1.48,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (r.remainingPrayers == 0) ...[
            const SizedBox(height: 10),
            Text(
              l10n.kazaCalcLiveZeroNote,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textOnDarkMuted.withValues(alpha: 0.95),
                height: 1.42,
                fontSize: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? AppColors.accentNeonGreen.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.22),
            border: Border.all(
              color: selected
                  ? AppColors.accentNeonGreen.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: selected
                  ? AppColors.creamBase
                  : AppColors.textOnDarkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
