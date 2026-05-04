import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/ads/admob_ids.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/widget_access_service.dart';
import '../providers/admob_providers.dart';
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
  bool _dialogOpen = false;

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
    if (kind != null) await _handleKind(kind);
  }

  Future<void> _handleKind(ArinWidgetAccessKind kind) async {
    if (!mounted || _dialogOpen) return;
    final service = ref.read(widgetAccessServiceProvider);
    final premium = await ref.read(premiumEntitlementProvider.future);
    final state = await service.stateFor(kind, isPremium: premium.isActive);
    if (!mounted || state.allowed) return;
    _dialogOpen = true;
    try {
      await _showUnlockDialog(kind);
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _showUnlockDialog(ArinWidgetAccessKind kind) async {
    final result = await showDialog<_WidgetUnlockAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${kind.title} kilitli'),
        content: const Text(
          'Bu widgetı 24 saat açmak için kısa bir reklam izleyebilirsin. '
          'Tüm widgetları sınırsız açmak için Premium’a geçebilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _WidgetUnlockAction.cancel),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _WidgetUnlockAction.premium),
            child: const Text('Premium'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _WidgetUnlockAction.rewarded),
            child: const Text('Reklam izle'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (result) {
      case _WidgetUnlockAction.rewarded:
        await _unlockWithRewarded(kind);
      case _WidgetUnlockAction.premium:
        context.push(AppRoutes.premium);
      case _WidgetUnlockAction.cancel:
      case null:
        return;
    }
  }

  Future<void> _unlockWithRewarded(ArinWidgetAccessKind kind) async {
    final ok = await ref
        .read(adMobServiceProvider)
        .showRewarded(ArinAdUnit.rewardedUnlock);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reklam şu an gösterilemedi.')),
      );
      return;
    }
    final service = ref.read(widgetAccessServiceProvider);
    await service.recordRewardedUnlock(kind);
    await service.syncAll(isPremium: false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${kind.title} 24 saat açıldı.')));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _WidgetUnlockAction { cancel, rewarded, premium }
