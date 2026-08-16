// lib/presentation/onboarding/app_tour/app_tour_anchor.dart

import 'package:flutter/widgets.dart';

import 'app_tour_keys.dart';

class AppTourAnchor extends StatelessWidget {
  const AppTourAnchor({super.key, required this.id, required this.child});

  final AppTourTargetId id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: AppTourKeys.of(id), child: child);
  }
}
