import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void socialLikeHaptic({required bool liking}) {
  if (liking) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.selectionClick();
  }
}

/// Tema yeşil çerçevesini kompozere sızdırmamak için çıplak alan.
InputDecoration socialPlainInputDecoration({
  String? hintText,
  TextStyle? hintStyle,
  bool isCollapsed = true,
  String counterText = '',
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: hintStyle,
    isCollapsed: isCollapsed,
    filled: false,
    fillColor: Colors.transparent,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    counterText: counterText,
    contentPadding: contentPadding,
  );
}

void socialUnfocusIfOutside({
  required FocusNode focus,
  required GlobalKey areaKey,
  required Offset globalPosition,
}) {
  if (!focus.hasFocus) return;
  final ctx = areaKey.currentContext;
  if (ctx == null) {
    focus.unfocus();
    return;
  }
  final box = ctx.findRenderObject();
  if (box is! RenderBox || !box.hasSize) {
    focus.unfocus();
    return;
  }
  final rect = box.localToGlobal(Offset.zero) & box.size;
  if (!rect.contains(globalPosition)) {
    focus.unfocus();
  }
}

void socialUnfocusOnUserScroll(ScrollNotification notification, FocusNode focus) {
  if (!focus.hasFocus) return;
  if (notification is UserScrollNotification &&
      notification.direction != ScrollDirection.idle) {
    focus.unfocus();
  }
}

void socialUnfocusFocusedFieldIfOutside(Offset globalPosition) {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null || !focus.hasFocus) return;
  final ctx = focus.context;
  if (ctx == null) {
    focus.unfocus();
    return;
  }
  final box = ctx.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  if (!rect.contains(globalPosition)) {
    focus.unfocus();
  }
}

/// Facebook / X: kısa fade + 6% yukarı kayma, 240ms.
class SocialOpenRoute<T> extends PageRouteBuilder<T> {
  SocialOpenRoute({required Widget page})
    : super(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.045),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}

class SocialSheetRoute<T> extends PageRouteBuilder<T> {
  SocialSheetRoute({required Widget page})
    : super(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.46),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      );
}
