// lib/presentation/onboarding/app_tour/app_tour_anchor.dart

import 'package:flutter/widgets.dart';

import 'app_tour_keys.dart';

class AppTourAnchor extends StatefulWidget {
  const AppTourAnchor({super.key, required this.id, required this.child});

  final AppTourTargetId id;
  final Widget child;

  @override
  State<AppTourAnchor> createState() => _AppTourAnchorState();
}

class _AppTourAnchorState extends State<AppTourAnchor> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppTourKeys.register(widget.id, context);
  }

  @override
  void didUpdateWidget(covariant AppTourAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      AppTourKeys.unregister(oldWidget.id, context);
      AppTourKeys.register(widget.id, context);
    }
  }

  @override
  void dispose() {
    AppTourKeys.unregister(widget.id, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
