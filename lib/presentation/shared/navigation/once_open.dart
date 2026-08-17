import 'package:flutter/foundation.dart';

/// Peş peşe tıklanınca aynı geçişin birden fazla kez açılmasını engeller.
class OnceOpen {
  OnceOpen({this.onBusyChanged});

  final ValueChanged<bool>? onBusyChanged;

  bool _busy = false;

  bool get isBusy => _busy;

  Future<T?> run<T>(Future<T> Function() action) async {
    if (_busy) return null;
    _busy = true;
    onBusyChanged?.call(true);
    try {
      return await action();
    } finally {
      _busy = false;
      onBusyChanged?.call(false);
    }
  }
}
