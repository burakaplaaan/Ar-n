import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Nefes ekranı: Taptic + (destekleniyorsa) motor titreşimi.
final class BreathingHaptics {
  BreathingHaptics._();

  static bool _inited = false;
  static bool _hasVibrator = false;
  static bool _hasAmplitude = false;

  static Future<void> init() async {
    if (kIsWeb || _inited) return;
    _inited = true;
    try {
      _hasVibrator = await Vibration.hasVibrator();
      if (_hasVibrator) {
        _hasAmplitude = await Vibration.hasAmplitudeControl();
      }
    } catch (_) {
      _hasVibrator = false;
      _hasAmplitude = false;
    }
  }

  static Future<void> _motor({int durationMs = 55, int amplitude = 220}) async {
    if (kIsWeb || !_hasVibrator) return;
    try {
      if (_hasAmplitude) {
        await Vibration.vibrate(
          duration: durationMs,
          amplitude: amplitude.clamp(1, 255),
        );
      } else {
        await Vibration.vibrate(duration: durationMs);
      }
    } catch (_) {}
  }

  /// Yalnızca nefes al fazı başında — tek kısa titreşim (motor veya Taptic, ikisi birden değil).
  static Future<void> inhaleStartOnce() async {
    if (kIsWeb) return;
    if (_hasVibrator) {
      await _motor(durationMs: 42, amplitude: 220);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static void lightTap() {
    HapticFeedback.lightImpact();
  }
}
