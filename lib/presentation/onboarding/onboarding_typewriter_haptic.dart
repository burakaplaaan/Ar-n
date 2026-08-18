import 'dart:async';

import 'package:flutter/services.dart';

/// Oyun diyaloglarındaki gibi hızlı, kısa tıkırtı.
/// Yavaş yazımda her harf bir tık; hızlanınca titreşim harften daha sık gelir.
class OnboardingTypewriterHaptics {
  Timer? _pulse;

  void onChar({required bool fast}) {
    if (fast) {
      _startPulse();
      return;
    }
    stop();
    HapticFeedback.selectionClick();
  }

  void _startPulse() {
    if (_pulse != null) return;
    HapticFeedback.selectionClick();
    _pulse = Timer.periodic(const Duration(milliseconds: 5), (_) {
      HapticFeedback.selectionClick();
    });
  }

  void stop() {
    _pulse?.cancel();
    _pulse = null;
  }
}

void playOnboardingTypewriterHaptic() {
  HapticFeedback.selectionClick();
}
