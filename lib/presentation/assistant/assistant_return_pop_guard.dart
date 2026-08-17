import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assistant_session.dart';

/// Asistandan açılan sayfada kenar kaydırmanın sohbeti atlayıp
/// üst sekmeye inmesini engeller. [PopScope] sayfa ağacında olmalı ki
/// [ModalRoute.popGestureEnabled] kapansın.
class AssistantReturnPopGuard extends ConsumerWidget {
  const AssistantReturnPopGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(assistantReturnToolProvider);
    final intercept = pending != null && pending.isNotEmpty;
    return PopScope(
      canPop: !intercept,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        popToAssistantIfNeeded(context);
      },
      child: child,
    );
  }
}
