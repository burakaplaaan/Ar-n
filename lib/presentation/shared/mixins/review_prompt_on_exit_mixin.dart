// lib/presentation/shared/mixins/review_prompt_on_exit_mixin.dart
// Belirli bir özellik ekranında anlamlı süre geçirip çıkan kullanıcıya
// mağaza değerlendirme sheet'i önermek için ortak `dispose` kancası.
//
// Zikirmatik, frekans, keşfet, kıble bulucu, gelişim gibi "kullanıcının
// keyif aldığı" ekranlarda kullanılır: sayfaya girişte zaman damgası
// alınır, çıkışta (`dispose`) geçen süre yeterliyse
// `ArinReviewPrompter.maybeAskAfterFeatureUse` tetiklenir. Native review
// çağrısı context gerektirmediğinden dispose sırasında tetiklemek güvenlidir.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/services/arin_review_prompter.dart';

mixin ReviewPromptOnExitMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  DateTime? _reviewPromptEnteredAt;

  /// `initState`'in başında çağrılmalı.
  void startReviewPromptTracking() {
    _reviewPromptEnteredAt = DateTime.now();
  }

  /// `dispose`'un başında (süper çağrılardan önce) çağrılmalı. `ref` henüz
  /// geçerliyken (widget tam olarak unmount olmadan) native isteği ateşler.
  void maybeRequestReviewOnExit() {
    final enteredAt = _reviewPromptEnteredAt;
    if (enteredAt == null) return;
    final usedFor = DateTime.now().difference(enteredAt);
    if (usedFor < ArinReviewPrompter.minFeatureUseDuration) return;
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(
      ArinReviewPrompter.maybeAskAfterFeatureUse(prefs, usedFor: usedFor),
    );
  }
}
