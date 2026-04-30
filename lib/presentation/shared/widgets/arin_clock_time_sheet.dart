// Namaz hatırlatıcı tekerlekleriyle aynı alt sayfa stili — saat + dakika.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

const double _kItemExtent = 40;

/// [initialMinutesFromMidnight] için 0..1439; dönüş aynı aralıkta veya iptal.
Future<int?> showArinClockTimeSheet(
  BuildContext context, {
  required int initialMinutesFromMidnight,
  required String title,
  String? subtitle,
}) {
  final h = initialMinutesFromMidnight ~/ 60;
  final m = initialMinutesFromMidnight % 60;
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF161B17),
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _ArinClockTimeSheet(
      initialHour: h.clamp(0, 23),
      initialMinute: m.clamp(0, 59),
      title: title,
      subtitle: subtitle,
    ),
  );
}

class _ArinClockTimeSheet extends StatefulWidget {
  const _ArinClockTimeSheet({
    required this.initialHour,
    required this.initialMinute,
    required this.title,
    this.subtitle,
  });

  final int initialHour;
  final int initialMinute;
  final String title;
  final String? subtitle;

  @override
  State<_ArinClockTimeSheet> createState() => _ArinClockTimeSheetState();
}

class _ArinClockTimeSheetState extends State<_ArinClockTimeSheet> {
  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.creamBase,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textOnDarkMuted,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.creamBase.withValues(alpha: 0.85),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.clockPickerCancelAction),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentNeonGreen,
                    foregroundColor: const Color(0xFF0A0F0C),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.pop(context, _hour * 60 + _minute),
                  child: Text(l10n.clockPickerConfirmAction),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ClockWheelColumn(
                      title: l10n.clockPickerHourLabel,
                      controller: _hourCtrl,
                      itemCount: 24,
                      selectedIndex: _hour,
                      labelBuilder: (i) => i.toString().padLeft(2, '0'),
                      onChanged: (i) => setState(() => _hour = i),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ClockWheelColumn(
                      title: l10n.clockPickerMinuteLabel,
                      controller: _minuteCtrl,
                      itemCount: 60,
                      selectedIndex: _minute,
                      labelBuilder: (i) =>
                          i.toString().padLeft(2, '0'),
                      onChanged: (i) => setState(() => _minute = i),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 240.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.05, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

class _ClockWheelColumn extends StatelessWidget {
  const _ClockWheelColumn({
    required this.title,
    required this.controller,
    required this.itemCount,
    required this.labelBuilder,
    required this.selectedIndex,
    required this.onChanged,
  });

  final String title;
  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int i) labelBuilder;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.accentNeonGreen.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: _kItemExtent,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                diameterRatio: 1.25,
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: itemCount,
                  builder: (context, i) {
                    final sel = i == selectedIndex;
                    return Center(
                      child: Text(
                        labelBuilder(i),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: sel
                              ? AppColors.creamBase
                              : AppColors.textOnDarkMuted
                                  .withValues(alpha: 0.45),
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                          fontSize: sel ? 17 : 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: Container(
                  height: _kItemExtent + 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.accentNeonGreen.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    color: AppColors.accentNeonGreen.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
