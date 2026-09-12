import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// iOS: native kaydırma + kenar geri jesti.
/// Android: önceki rota parallax edilmez; yalnızca gelen sayfa kayar.
/// Fade yok — `opaque: true` iken fade alt rotayı karartabilir.
PageRoute<void> qiblaToolPageRoute({
  required RouteSettings settings,
  required WidgetBuilder builder,
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPageRoute<void>(settings: settings, builder: builder);
  }
  return _AndroidQiblaToolPageRoute<void>(
    settings: settings,
    builder: builder,
  );
}

class _AndroidQiblaToolPageRoute<T> extends MaterialPageRoute<T> {
  _AndroidQiblaToolPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Duration get transitionDuration => kQiblaToolAndroidTransition;

  @override
  Duration get reverseTransitionDuration => kQiblaToolAndroidReverseTransition;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      child: child,
    );
  }
}

@visibleForTesting
const Duration kQiblaToolAndroidTransition = Duration(milliseconds: 240);

@visibleForTesting
const Duration kQiblaToolAndroidReverseTransition = Duration(milliseconds: 200);
