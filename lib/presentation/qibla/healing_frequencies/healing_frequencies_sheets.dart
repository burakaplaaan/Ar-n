// Ambiyans ve uyku zamanlayıcı bottom sheet’leri.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/locale_text.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import 'healing_audio_notifier.dart';

import 'package:arin/l10n/app_localizations.dart';

Future<void> showHealingAmbientSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final selected = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
    builder: (ctx) => _AmbientSheet(
      initialKey: ref.read(healingAudioNotifierProvider).ambientKey,
    ),
  );
  if (selected != null && context.mounted) {
    await ref.read(healingAudioNotifierProvider.notifier).setAmbientKey(selected);
  }
}

class _AmbientSheet extends StatefulWidget {
  const _AmbientSheet({required this.initialKey});

  final String initialKey;

  @override
  State<_AmbientSheet> createState() => _AmbientSheetState();
}

class _AmbientSheetState extends State<_AmbientSheet> {
  late String _category;
  late String _previewKey;

  List<({String key, String label})> _chips(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return <({String key, String label})>[
      (key: kHealingAmbientForest, label: l10n.healingAmbientForestShort),
      (key: kHealingAmbientFire, label: l10n.healingAmbientFireShort),
      (key: kHealingAmbientEvren, label: l10n.healingAmbientCosmicShort),
      (key: kHealingAmbientInshirah, label: l10n.healingAmbientInshirahShort),
    ];
  }

  @override
  void initState() {
    super.initState();
    _category = widget.initialKey;
    _previewKey = widget.initialKey;
  }

  String _displayFor(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case kHealingAmbientForest:
        return l10n.healingAmbientForest;
      case kHealingAmbientFire:
        return l10n.healingAmbientFire;
      case kHealingAmbientEvren:
        return l10n.healingAmbientCosmic;
      case kHealingAmbientInshirah:
        return l10n.healingAmbientInshirah;
      default:
        return l10n.healingAmbientForest;
    }
  }

  IconData _iconFor(String key) {
    switch (key) {
      case kHealingAmbientForest:
        return Icons.forest_outlined;
      case kHealingAmbientFire:
        return Icons.local_fire_department_outlined;
      case kHealingAmbientEvren:
        return Icons.auto_awesome_outlined;
      case kHealingAmbientInshirah:
        return Icons.menu_book_rounded;
      default:
        return Icons.forest_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final chips = _chips(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottom + 8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                l10n.healingAmbientChoose,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = chips[i];
                  final sel = c.key == _category;
                  return ChoiceChip(
                    label: Text(c.label),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      _category = c.key;
                      _previewKey = c.key;
                    }),
                    selectedColor: const Color(0xFF42A5F5),
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: const Color(0xFF2C2C2E),
                    side: BorderSide(
                      color: sel
                          ? const Color(0xFF42A5F5)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Material(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(context, _previewKey),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A237E).withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconFor(_previewKey), color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _displayFor(_previewKey),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.healingTeal.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
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

/// Dönüş: `null` = vazgeç, `0` = kapalı, pozitif = dakika.
Future<void> showHealingSleepSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final fromState = ref.read(healingAudioNotifierProvider).selectedSleepMinutes;
  final fromPrefs = prefs.getInt(kHealingPrefLastSleepMin) ?? 30;
  final initial = fromState ??
      (kHealingSleepMinuteChoices.contains(fromPrefs) ? fromPrefs : 30);
  final picked = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
    builder: (ctx) => _SleepTimerSheet(initialMinutes: initial),
  );
  if (picked != null && context.mounted) {
    if (picked == 0) {
      ref.read(healingAudioNotifierProvider.notifier).setSleepMinutes(null);
    } else {
      ref.read(healingAudioNotifierProvider.notifier).setSleepMinutes(picked);
    }
  }
}

class _SleepTimerSheet extends StatelessWidget {
  const _SleepTimerSheet({required this.initialMinutes});

  final int initialMinutes;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom + 8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      l10n.healingSleepCancel,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.healingSleepTimer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 72),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                l10n.healingSleepStopAfter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(context, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_off_outlined,
                          color: Colors.white.withValues(alpha: 0.75),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.healingSleepTimerOff,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ...kHealingSleepMinuteChoices.map((m) {
              final sel = m == initialMinutes;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Material(
                  color: sel
                      ? const Color(0x26FF9500)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context, m),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.nightlight_round,
                            color: AppColors.healingOrange.withValues(alpha: 0.95),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.healingSleepMinutes(m),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (sel)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.healingOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
