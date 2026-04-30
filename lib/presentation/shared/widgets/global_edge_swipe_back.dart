import 'package:flutter/material.dart';

/// iOS benzeri soldan-sağa "edge swipe back" davranışı.
///
/// - Yalnızca sol kenara yakın başlayan sürüklemelerde aktif olur.
/// - İçerik gesture'larını mümkün olduğunca bozmamak için `Listener` kullanır.
/// - O anki navigator geri dönebiliyorsa `maybePop()` çağırır.
class GlobalEdgeSwipeBack extends StatefulWidget {
  const GlobalEdgeSwipeBack({
    super.key,
    required this.child,
    required this.onBackRequested,
  });

  final Widget child;
  final Future<bool> Function() onBackRequested;

  @override
  State<GlobalEdgeSwipeBack> createState() => _GlobalEdgeSwipeBackState();
}

class _GlobalEdgeSwipeBackState extends State<GlobalEdgeSwipeBack> {
  static const double _edgeActivationWidth = 28;
  static const double _horizontalTriggerDelta = 72;
  static const double _dominanceRatio = 1.25;

  int? _activePointer;
  Offset? _startGlobalPos;
  bool _armed = false;
  bool _popTriggered = false;

  void _reset() {
    _activePointer = null;
    _startGlobalPos = null;
    _armed = false;
    _popTriggered = false;
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_activePointer != null) return;
    _activePointer = e.pointer;
    _startGlobalPos = e.position;
    _armed = e.position.dx <= _edgeActivationWidth;
    _popTriggered = false;
  }

  Future<void> _onPointerMove(PointerMoveEvent e) async {
    if (!_armed || _popTriggered) return;
    if (_activePointer != e.pointer) return;
    final start = _startGlobalPos;
    if (start == null) return;

    final dx = e.position.dx - start.dx;
    final dy = (e.position.dy - start.dy).abs();
    final horizontalDominant = dx.abs() > (dy * _dominanceRatio);
    final shouldBack = dx >= _horizontalTriggerDelta && horizontalDominant;
    if (!shouldBack) return;

    _popTriggered = true;
    await widget.onBackRequested();
  }

  void _onPointerUpOrCancel(PointerEvent e) {
    if (_activePointer == e.pointer) {
      _reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: (e) => _onPointerMove(e),
      onPointerUp: _onPointerUpOrCancel,
      onPointerCancel: _onPointerUpOrCancel,
      child: widget.child,
    );
  }
}
