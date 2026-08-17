import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../assistant/assistant_session.dart';

/// Kıble hub içi sayfalar: sistem geri / özel [onBack] / asistan dönüşü.
///
/// Normal çıkışta [canPop] açıktır; [CupertinoPageRoute] sayfayı Instagram
/// gibi sağa kaydırarak kapatır. Özel kaydırma jesti yok — o jest rotayı
/// parmağa bağlı animasyon olmadan kapatıyordu.
class QiblaNestedSwipeBack extends ConsumerWidget {
  const QiblaNestedSwipeBack({super.key, required this.child, this.onBack});

  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(assistantReturnToolProvider);
    final intercept = onBack != null || (pending != null && pending.isNotEmpty);
    return PopScope(
      canPop: !intercept,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (popToAssistantIfNeeded(context)) return;
        final customBack = onBack;
        if (customBack != null) {
          customBack();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
