import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/arin_shell_background.dart';
import '../../data/services/ad_gate_service.dart';
import '../../data/services/session_ad_prompt.dart';
import '../shared/widgets/arin_loader.dart';

/// Kıble aracı açılır açılmaz Bilgi Düellosu gibi yükleme ekranı gösterir.
/// Reklam ve ilk kare bu örtünün altında biter; panel donmuş gibi kalmaz.
class QiblaToolOpeningGate extends ConsumerStatefulWidget {
  const QiblaToolOpeningGate({
    super.key,
    required this.child,
    this.adPlacement,
  });

  final Widget child;
  final AdGatePlacement? adPlacement;

  @override
  ConsumerState<QiblaToolOpeningGate> createState() =>
      _QiblaToolOpeningGateState();
}

class _QiblaToolOpeningGateState extends ConsumerState<QiblaToolOpeningGate> {
  bool _ready = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) return;
      _started = true;
      unawaited(_prepare());
    });
  }

  Future<void> _prepare() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final placement = widget.adPlacement;
      if (placement != null && mounted) {
        await SessionAdPrompt.maybeShow(ref: ref, placement: placement);
      }
    } finally {
      if (mounted) {
        setState(() => _ready = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return _OpeningLoader(onDark: !ArinShellBackground.isLight(context));
    }
    return widget.child;
  }
}

class _OpeningLoader extends StatelessWidget {
  const _OpeningLoader({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onDark
          ? const Color(0xFF0A1210)
          : const Color(0xFFF3F6F2),
      body: ArinShellBackground.buildLayered(
        context,
        child: const SafeArea(
          child: Center(child: ArinLoader()),
        ),
      ),
    );
  }
}
