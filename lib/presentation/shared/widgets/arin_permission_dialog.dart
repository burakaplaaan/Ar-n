import 'package:flutter/material.dart';

import 'arin_popup.dart';

/// Shows an ARIN-branded explanation before handing control to an OS
/// permission screen. Native Android/iOS permission dialogs themselves
/// cannot be styled by the application.
Future<bool> showArinPermissionDialog({
  required BuildContext context,
  required String title,
  required String body,
  required IconData icon,
  required String cancelLabel,
  required String confirmLabel,
  bool barrierDismissible = true,
}) {
  return showArinConfirm(
    context: context,
    title: title,
    message: body,
    icon: icon,
    cancelLabel: cancelLabel,
    confirmLabel: confirmLabel,
    barrierDismissible: barrierDismissible,
  );
}
