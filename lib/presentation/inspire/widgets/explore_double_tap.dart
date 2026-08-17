import 'package:flutter/painting.dart';

/// Keşfet kartında kaydırma ile çakışmayan çift tık algısı.
class ExploreDoubleTapTracker {
  ExploreDoubleTapTracker({
    this.maxInterval = const Duration(milliseconds: 280),
    this.maxDistance = 48,
  });

  final Duration maxInterval;
  final double maxDistance;

  DateTime? _firstAt;
  Offset? _firstPos;

  bool registerTap(Offset position, [DateTime? now]) {
    final t = now ?? DateTime.now();
    final firstAt = _firstAt;
    final firstPos = _firstPos;
    if (firstAt != null &&
        firstPos != null &&
        t.difference(firstAt) <= maxInterval &&
        (position - firstPos).distance <= maxDistance) {
      reset();
      return true;
    }
    _firstAt = t;
    _firstPos = position;
    return false;
  }

  void reset() {
    _firstAt = null;
    _firstPos = null;
  }
}
