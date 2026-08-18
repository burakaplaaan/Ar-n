// lib/presentation/shared/widgets/location_change_listener.dart
//
// Uygulama açılışında GPS konumunu kaydedilen şehirle karşılaştırır.
// Farklıysa kullanıcıya onay diyaloğu gösterir — güncelleme veya
// "bir daha sorma" (her zaman güncelle / hiç güncelleme) tercihiyle.
//
// Yalnızca `locationUpdatePref == ask` olduğunda tetiklenir.
// `always_update` → sessiz otomatik güncelleme (syncPrayerLocation üstlenir).
// `never_update`  → hiçbir şey yapılmaz.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/turkey_provinces.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/startup_permission_policy.dart';
import '../../onboarding/app_tour/app_tour_controller.dart';
import '../providers/prayer_time_providers.dart';
import 'package:arin/presentation/shared/widgets/arin_loader.dart';

class LocationChangeListener extends ConsumerStatefulWidget {
  const LocationChangeListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LocationChangeListener> createState() =>
      _LocationChangeListenerState();
}

class _LocationChangeListenerState extends ConsumerState<LocationChangeListener>
    with WidgetsBindingObserver {
  /// Oturum içi son kontrol zamanı — resume throttle için.
  DateTime? _lastCheck;

  /// Resume'lar arasındaki minimum GPS kontrol aralığı.
  static const _resumeThrottle = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkLocation());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    final last = _lastCheck;
    if (last == null || now.difference(last) >= _resumeThrottle) {
      unawaited(_checkLocation());
    }
  }

  Future<void> _checkLocation() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
    if (!onboardingDone) return;
    if (shouldDeferSystemPromptsForAppTour(
      tourPending: prefs.getBool(kAppTourPendingKey) == true,
      tourCompleted: prefs.getBool(kAppTourCompletedKey) == true,
    )) {
      return;
    }

    final location = ref.read(locationServiceProvider);
    final pref = location.locationUpdatePref;
    if (pref == LocationUpdatePref.neverUpdate) return;
    if (location.isManualPrayerLocation) return;

    _lastCheck = DateTime.now();

    // GPS + reverse geocoding (arka planda — UI'ı bloklamaz).
    final change = await location.detectLocationChange();
    if (change == null || !mounted) return;
    if (location.isManualPrayerLocation) return;

    // İlk açılışta (savedCity boş) veya alwaysUpdate: diyalogsuz sessiz güncelle.
    final isFirstTime = location.savedCity.isEmpty;
    if (isFirstTime || pref == LocationUpdatePref.alwaysUpdate) {
      await location.applyLocationChange(change);
      if (mounted) ref.invalidate(prayerTimesProvider);
      return;
    }

    // ask: kullanıcıya onay diyaloğu göster.
    if (!mounted) return;
    final oldCity =
        matchTurkeyProvinceExact(location.savedCity) ?? location.savedCity;
    final newCity =
        matchTurkeyProvinceExact(change.newCity) ?? change.newCity;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LocationChangeDialog(
        oldCity: oldCity,
        newCity: newCity,
        onConfirm: (remember) async {
          await location.applyLocationChange(change);
          if (remember) {
            await location.setLocationUpdatePref(LocationUpdatePref.alwaysUpdate);
          }
          ref.invalidate(prayerTimesProvider);
        },
        onDecline: (remember) async {
          if (remember) {
            await location.setLocationUpdatePref(LocationUpdatePref.neverUpdate);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appTourControllerProvider, (previous, next) {
      if (previous?.active == true && !next.active) {
        unawaited(_checkLocation());
      }
    });
    return widget.child;
  }
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class _LocationChangeDialog extends StatefulWidget {
  const _LocationChangeDialog({
    required this.oldCity,
    required this.newCity,
    required this.onConfirm,
    required this.onDecline,
  });

  final String oldCity;
  final String newCity;
  final Future<void> Function(bool remember) onConfirm;
  final Future<void> Function(bool remember) onDecline;

  @override
  State<_LocationChangeDialog> createState() => _LocationChangeDialogState();
}

class _LocationChangeDialogState extends State<_LocationChangeDialog> {
  bool _remember = false;
  bool _busy = false;

  Future<void> _handle(bool confirmed) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (confirmed) {
        await widget.onConfirm(_remember);
      } else {
        await widget.onDecline(_remember);
      }
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? const Color(0xFF142A22) : AppColors.creamSurface;
    final borderColor =
        isDark ? AppColors.emeraldMid.withValues(alpha: 0.35) : AppColors.creamDark;
    final titleColor =
        isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final bodyColor =
        isDark ? AppColors.textOnDarkMuted : AppColors.textSecondary;
    final accentColor =
        isDark ? AppColors.accentNeonGreen : AppColors.accentGreenOnLight;
    final checkboxFill =
        isDark ? AppColors.emeraldMid : AppColors.emeraldLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.differentLocation,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Şehir geçiş satırı
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CityChip(city: widget.oldCity, isDark: isDark, faded: true),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: bodyColor,
                  ),
                ),
                _CityChip(city: widget.newCity, isDark: isDark, faded: false),
              ],
            ),

            const SizedBox(height: 14),

            // Açıklama
            Text(
              AppLocalizations.of(context)!.updatePrayerTimesForCity(widget.newCity),
              style: TextStyle(
                color: bodyColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // "Bir daha sorma" seçeneği
            GestureDetector(
              onTap: () => setState(() => _remember = !_remember),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _remember ? checkboxFill : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _remember ? checkboxFill : borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: _remember
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.rememberThisChoice,
                      style: TextStyle(
                        color: bodyColor,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Butonlar
            if (_busy)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: ArinLoader(strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: AppLocalizations.of(context)!.keepCurrentLocation,
                      onPressed: () => _handle(false),
                      primary: false,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogButton(
                      label: AppLocalizations.of(context)!.updateLocation,
                      onPressed: () => _handle(true),
                      primary: true,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({
    required this.city,
    required this.isDark,
    required this.faded,
  });

  final String city;
  final bool isDark;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? (faded
            ? AppColors.emeraldDark.withValues(alpha: 0.35)
            : AppColors.emeraldDark.withValues(alpha: 0.75))
        : (faded ? AppColors.creamDark : AppColors.emeraldFaint);
    final text = isDark
        ? (faded ? AppColors.textOnDarkMuted : AppColors.textOnDark)
        : (faded ? AppColors.textSecondary : AppColors.emeraldDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        city,
        style: TextStyle(
          color: text,
          fontSize: 13,
          fontWeight: faded ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onPressed,
    required this.primary,
    required this.isDark,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor:
              isDark ? AppColors.emeraldMid : AppColors.accentGreenOnLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isDark ? AppColors.textOnDarkMuted : AppColors.textSecondary,
        side: BorderSide(
          color: isDark
              ? AppColors.emeraldMid.withValues(alpha: 0.4)
              : AppColors.creamDark,
        ),
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    );
  }
}
