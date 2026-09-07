// lib/presentation/shared/mixins/review_prompt_on_exit_mixin.dart
// Belirli bir özellik ekranında anlamlı süre geçirip çıkan kullanıcıya
// mağaza değerlendirme sheet'i önermek için ortak `dispose` kancası.
//
// Zikirmatik, frekans, keşfet, kıble, namaz programı gibi ekranlarda
// kullanılır: girişte zaman damgası alınır, çıkışta süre yeterliyse
// `ArinReviewPrompter.maybeAskAfterFeatureUse` tetiklenir. Native review
// çağrısı context istemez; dispose sırasında güvenlidir.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/services/arin_review_prompter.dart';

mixin ReviewPromptOnExitMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  DateTime? _reviewPromptEnteredAt;
  SharedPreferences? _reviewPromptPreferences;

  DateTime reviewPromptNow() => DateTime.now();

  /// `initState`'in başında çağrılmalı.
  void startReviewPromptTracking() {
    _reviewPromptEnteredAt = reviewPromptNow();
    _reviewPromptPreferences = ref.read(sharedPreferencesProvider);
  }

  /// `dispose`'un başında (süper çağrılardan önce) çağrılmalı.
  void maybeRequestReviewOnExit() {
    final enteredAt = _reviewPromptEnteredAt;
    final prefs = _reviewPromptPreferences;
    if (enteredAt == null || prefs == null) return;
    final usedFor = reviewPromptNow().difference(enteredAt);
    if (usedFor < ArinReviewPrompter.minFeatureUseDuration) return;
    unawaited(
      ArinReviewPrompter.maybeAskAfterFeatureUse(prefs, usedFor: usedFor),
    );
  }
}
