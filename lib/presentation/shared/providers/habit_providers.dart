// lib/presentation/shared/providers/habit_providers.dart
// Riverpod provider'ları — Alışkanlık ve Streak yönetimi.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/repositories/habit_repository.dart';

final habitRepositoryProvider = Provider<HabitRepository>(
  (_) => HabitRepository(),
);

/// Alışkanlık özeti (habit + streak + completedToday) state notifier'ı
class HabitSummaryNotifier
    extends StateNotifier<List<({HabitModel habit, int streak, bool completedToday})>> {
  final HabitRepository _repo;

  HabitSummaryNotifier(this._repo) : super([]) {
    _reload();
  }

  void _reload() {
    state = _repo.getSummary();
  }

  Future<void> addHabit({
    required String title,
    required HabitType type,
    required String emoji,
  }) async {
    await _repo.add(title: title, type: type, emoji: emoji);
    _reload();
  }

  Future<HabitModel> addCustomHabit({
    required String title,
    required HabitType type,
    required String emoji,
    String note = '',
    required int customTarget,
    required String customUnit,
    required int customTrackingKind,
    required bool customFlexible,
    required int customMinTarget,
    int customRepeatCycle = 0,
  }) async {
    final h = await _repo.addCustom(
      title: title,
      type: type,
      emoji: emoji,
      note: note,
      customTarget: customTarget,
      customUnit: customUnit,
      customTrackingKind: customTrackingKind,
      customFlexible: customFlexible,
      customMinTarget: customMinTarget,
      customRepeatCycle: customRepeatCycle,
    );
    _reload();
    return h;
  }

  Future<void> addProgressToday(String habitId, int delta) async {
    await _repo.addProgressToday(habitId, delta);
    _reload();
  }

  Future<void> fillProgressToday(String habitId) async {
    await _repo.fillProgressToday(habitId);
    _reload();
  }

  Future<void> updateHabitNote(String habitId, String note) async {
    await _repo.updateHabitNote(habitId, note);
    _reload();
  }

  Future<HabitModel> createFromTemplate({
    required String templateId,
    required String title,
    required HabitType type,
    required String emoji,
    String commitmentText = '',
    String? quitSubtype,
    String? quitMethod,
    bool onboardingCompleted = true,
  }) async {
    final h = await _repo.addFromTemplate(
      templateId: templateId,
      title: title,
      type: type,
      emoji: emoji,
      commitmentText: commitmentText,
      quitSubtype: quitSubtype,
      quitMethod: quitMethod,
      onboardingCompleted: onboardingCompleted,
    );
    _reload();
    return h;
  }

  Future<void> completeQuitOnboarding({
    required String habitId,
    required String commitmentText,
    String? quitMethod,
  }) async {
    await _repo.completeQuitOnboarding(
      habitId: habitId,
      commitmentText: commitmentText,
      quitMethod: quitMethod,
    );
    _reload();
  }

  Future<void> toggleToday(String habitId) async {
    await _repo.toggleToday(habitId);
    _reload();
  }

  Future<void> setQuitClockNow(String habitId, [DateTime? when]) async {
    await _repo.setQuitClockNow(habitId, when);
    _reload();
  }

  /// Onboarding'i tamamlamadan sadece sayacı başlat — kriz anı kısa yol.
  Future<void> quickStartQuitClock(String habitId) async {
    await _repo.quickStartQuitClock(habitId);
    _reload();
  }

  Future<void> restartQuitProgram(
    String habitId, {
    bool preserveHistory = false,
  }) async {
    await _repo.restartQuitProgram(
      habitId,
      preserveHistory: preserveHistory,
    );
    _reload();
  }

  Future<void> deleteHabitPermanently(String habitId) async {
    await _repo.deletePermanently(habitId);
    _reload();
  }

  void refresh() => _reload();
}

final habitSummaryProvider = StateNotifierProvider<HabitSummaryNotifier,
    List<({HabitModel habit, int streak, bool completedToday})>>(
  (ref) => HabitSummaryNotifier(ref.watch(habitRepositoryProvider)),
);
