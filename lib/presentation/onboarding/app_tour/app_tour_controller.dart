// lib/presentation/onboarding/app_tour/app_tour_controller.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/startup_permission_policy.dart';
import 'app_tour_step.dart';

export '../../../data/services/startup_permission_policy.dart'
    show
        kAppTourCompletedKey,
        kAppTourPendingKey,
        kAppTourWidgetPromptPendingKey;

class AppTourState {
  const AppTourState({this.active = false, this.stepIndex = 0});

  final bool active;
  final int stepIndex;

  AppTourStep? get step {
    if (!active) return null;
    if (stepIndex < 0 || stepIndex >= AppTourCatalog.steps.length) return null;
    return AppTourCatalog.steps[stepIndex];
  }

  bool get isLast => stepIndex >= AppTourCatalog.steps.length - 1;
}

class AppTourController extends Notifier<AppTourState> {
  @override
  AppTourState build() => const AppTourState();

  bool get isCompleted {
    return ref.read(sharedPreferencesProvider).getBool(kAppTourCompletedKey) ==
        true;
  }

  bool get isPending {
    return ref.read(sharedPreferencesProvider).getBool(kAppTourPendingKey) ==
        true;
  }

  void maybeStart() {
    if (state.active) return;
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool('onboarding_completed') != true) return;
    if (prefs.getBool(kAppTourCompletedKey) == true) return;
    if (prefs.getBool(kAppTourPendingKey) != true) return;
    state = const AppTourState(active: true, stepIndex: 0);
  }

  Future<void> next(BuildContext context) async {
    if (!state.active) return;
    if (state.isLast) {
      await finish(context);
      return;
    }
    final nextIndex = state.stepIndex + 1;
    final step = AppTourCatalog.steps[nextIndex];
    if (context.mounted && step.route.isNotEmpty) {
      final current = GoRouterState.of(context).uri.path;
      if (current != step.route) {
        context.go(step.route);
      }
    }
    state = AppTourState(active: true, stepIndex: nextIndex);
  }

  Future<void> finish(BuildContext context) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await persistAppTourFinished(prefs);
    state = const AppTourState();
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }
}

Future<void> persistAppTourFinished(SharedPreferences prefs) async {
  await prefs.setBool(kAppTourCompletedKey, true);
  await prefs.setBool(kAppTourPendingKey, false);
  await prefs.setBool(kAppTourWidgetPromptPendingKey, true);
}

final appTourControllerProvider =
    NotifierProvider<AppTourController, AppTourState>(AppTourController.new);
