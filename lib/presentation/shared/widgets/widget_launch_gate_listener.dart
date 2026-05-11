import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/router/app_router.dart';
import '../../../data/services/widget_access_service.dart';
import '../providers/premium_providers.dart';
import '../providers/widget_access_providers.dart';

class WidgetLaunchGateListener extends ConsumerStatefulWidget {
  const WidgetLaunchGateListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<WidgetLaunchGateListener> createState() =>
      _WidgetLaunchGateListenerState();
}

class _WidgetLaunchGateListenerState
    extends ConsumerState<WidgetLaunchGateListener>
    with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _clickSub;
  bool _gatePageOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumeAndroidLaunch());
      unawaited(_consumeHomeWidgetLaunch());
    });
    _clickSub = HomeWidget.widgetClicked.listen((uri) {
      unawaited(_handleUri(uri));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clickSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_consumeAndroidLaunch());
    }
  }

  Future<void> _consumeAndroidLaunch() async {
    final kind = await ref
        .read(widgetAccessServiceProvider)
        .consumeLaunchedWidgetKind();
    if (kind != null) await _handleKind(kind);
  }

  Future<void> _consumeHomeWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    await _handleUri(uri);
  }

  Future<void> _handleUri(Uri? uri) async {
    if (uri == null) return;
    if (uri.scheme != 'arin' || uri.host != 'widget') return;
    final segment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    final kind = ArinWidgetAccessKind.fromId(segment);
    if (kind == null) return;

    // Native widget kilit overlay'inde "Açmak için dokunun"a tıklama: native
    // tarafça URL'ye `?lock=1` flag'i eklenir. State servisindeki olası
    // çelişkilere (premium/trial mismatch) güvenmeden doğrudan unlock akışına
    // gidilir; aksi halde kullanıcı kilit gördüğü halde ana sayfaya düşerdi.
    if (uri.queryParameters['lock'] == '1') {
      await _openUnlockPage(kind);
      return;
    }

    await _handleKind(kind);
  }

  Future<void> _handleKind(ArinWidgetAccessKind kind) async {
    if (!mounted || _gatePageOpen) return;
    final service = ref.read(widgetAccessServiceProvider);
    final premium = await ref.read(premiumEntitlementProvider.future);
    final state = await service.stateFor(kind, isPremium: premium.isActive);
    if (!mounted || state.allowed) return;
    await _openUnlockPage(kind);
  }

  Future<void> _openUnlockPage(ArinWidgetAccessKind kind) async {
    if (!mounted || _gatePageOpen) return;
    _gatePageOpen = true;
    try {
      // `WidgetLaunchGateListener`, `MaterialApp.router`'ın `builder` callback'i
      // içinde yer aldığından local `context` GoRouter ancestor'ını göremez;
      // `GoRouter.of(context)` null patlatır. Bu yüzden router instance'ını
      // doğrudan Riverpod provider'dan okuyup `push` ediyoruz.
      final router = ref.read(appRouterProvider);
      await router.push(AppRoutes.widgetUnlock(kind.id));
    } finally {
      _gatePageOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
