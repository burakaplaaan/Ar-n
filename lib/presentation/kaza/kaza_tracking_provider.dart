// Kaza takibi — Riverpod + SharedPreferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/shared_preferences_provider.dart';
import '../../data/models/kaza_tracking_state.dart';
import '../../data/repositories/kaza_tracking_repository.dart';
import '../../data/repositories/salat_log_repository.dart';
import '../../data/services/kaza_calculator.dart';
import '../../data/services/tracking_widget_service.dart';
import '../shared/providers/habit_providers.dart';

final kazaTrackingRepositoryProvider = Provider<KazaTrackingRepository>((ref) {
  return KazaTrackingRepository(ref.watch(sharedPreferencesProvider));
});

final kazaTrackingProvider =
    NotifierProvider<KazaTrackingNotifier, KazaTrackingState>(
      KazaTrackingNotifier.new,
    );

class KazaTrackingNotifier extends Notifier<KazaTrackingState> {
  @override
  KazaTrackingState build() {
    return ref.read(kazaTrackingRepositoryProvider).load();
  }

  KazaTrackingRepository get _repo => ref.read(kazaTrackingRepositoryProvider);

  Future<void> _persist(KazaTrackingState s) async {
    state = s;
    await _repo.save(s);
    await TrackingWidgetService.refreshSelected(
      prefs: ref.read(sharedPreferencesProvider),
      habitRepo: ref.read(habitRepositoryProvider),
      salatRepo: SalatLogRepository(),
    );
  }

  /// Form alanları + dağıtılmış sayaçları tek yazımda kalıcıya alır (Hesapla).
  Future<void> commitKazaCalculation({
    required bool isFemale,
    required DateTime birthDate,
    required int pubertyAge,
    required int prayedDaysRecorded,
    required int remainingPrayers,
  }) async {
    final d = KazaCalculator.distributeAcrossSix(remainingPrayers);
    await _persist(
      state.copyWith(
        isFemale: isFemale,
        birthDate: birthDate,
        pubertyAge: pubertyAge,
        prayedDaysRecorded: prayedDaysRecorded,
        sabah: d[0],
        ogle: d[1],
        ikindi: d[2],
        aksam: d[3],
        yatsi: d[4],
        vitir: d[5],
        hasEverCalculated: true,
      ),
    );
  }

  Future<void> setSlot(int index, int value) async {
    final v = value < 0 ? 0 : value;
    switch (index) {
      case 0:
        await _persist(state.copyWith(sabah: v));
        return;
      case 1:
        await _persist(state.copyWith(ogle: v));
        return;
      case 2:
        await _persist(state.copyWith(ikindi: v));
        return;
      case 3:
        await _persist(state.copyWith(aksam: v));
        return;
      case 4:
        await _persist(state.copyWith(yatsi: v));
        return;
      case 5:
        await _persist(state.copyWith(vitir: v));
        return;
      default:
        return;
    }
  }

  Future<void> addToSlot(int index, int delta) async {
    final cur = state.counts[index];
    await setSlot(index, cur + delta);
  }

  Future<void> resetAllCounts() async {
    await _persist(
      state.copyWith(
        sabah: 0,
        ogle: 0,
        ikindi: 0,
        aksam: 0,
        yatsi: 0,
        vitir: 0,
      ),
    );
  }

  /// Rutin atölyesinde Kaza seçilip Devam denince — Gelişim kartı görünsün.
  Future<void> enableGelisimHubCard() async {
    if (state.hubEnabled) return;
    await _persist(state.copyWith(hubEnabled: true));
  }

  /// Gelişim’deki kaza kartını gizle (sayaç / hesap verisi silinmez).
  Future<void> hideGelisimHubCard() async {
    if (!state.hubEnabled) return;
    await _persist(state.copyWith(hubEnabled: false));
  }
}
