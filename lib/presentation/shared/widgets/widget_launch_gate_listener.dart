import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/router/app_router.dart';
import '../../../data/services/widget_access_service.dart';
import '../../qibla/qibla_hub_navigator_key.dart';
import '../../qibla/qibla_hub_page.dart';
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
  static const _pendingWidgetLaunchUriKey = 'arin_pending_widget_launch_uri';

  /// Şu anda açık olan kilit/reklam sayfasının widget türü. `null` ise açık
  /// sayfa yok. Eski tek `bool` bayrak, bir sayfa açıkken gelen ikinci widget
  /// dokunuşunu sessizce yutuyordu (yalnızca uygulama tamamen kapatılınca
  /// sıfırlanıyordu); bu yüzden ikinci widget reklam sayfasına gitmiyordu.
  ArinWidgetAccessKind? _openGateKind;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumeAndroidLaunch());
      unawaited(_consumePendingIntentLaunch());
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
      unawaited(_consumePendingIntentLaunch());
    }
  }

  Future<void> _consumeAndroidLaunch() async {
    final raw = await ref
        .read(widgetAccessServiceProvider)
        .consumeLaunchedWidgetKind();
    if (raw == null || raw.isEmpty) return;
    
    // Simulate URI parsing for lock flag like iOS
    final uri = Uri.tryParse('arin://widget/$raw');
    await _handleUri(uri);
  }

  Future<void> _consumeHomeWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    await _handleUri(uri);
  }

  /// iOS native `SceneDelegate` widget derin linkini (`arin://widget/...`) App
  /// Group'a `arin_pending_widget_launch_uri` olarak yazar. Bu uygulama UIScene
  /// tabanlı olduğundan `home_widget` plugin'inin URL yakalama yolu (eski
  /// `UIApplicationDelegate` metotları) hiç tetiklenmez; bu yüzden açma
  /// sinyalini bu App Group anahtarı üzerinden alıyoruz.
  ///
  /// KRİTİK: Açılışta App Group henüz `setAppGroupId` ile bağlanmamış olabilir
  /// (`primeAppGroup` fire-and-forget). O yüzden okumadan ÖNCE App Group'u
  /// garanti altına alıyoruz; ayrıca cold-launch yarışına karşı kısa retry.
  Future<void> _consumePendingIntentLaunch() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await HomeWidget.setAppGroupId('group.com.arin.arin');
    } catch (_) {
      // App Group bağlanamadıysa okuma zaten null döner; sessizce çık.
    }
    for (var attempt = 0; attempt < 6; attempt++) {
      final raw = await HomeWidget.getWidgetData<String>(
        _pendingWidgetLaunchUriKey,
      );
      if (raw != null && raw.isNotEmpty) {
        // Tekrar tetiklenmesin diye anahtarı hemen temizle.
        await HomeWidget.saveWidgetData<String>(_pendingWidgetLaunchUriKey, '');
        final uri = Uri.tryParse(raw);
        await _handleUri(uri);
        return;
      }
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
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
    if (!mounted) return;
    // Aynı widget'ın kilit sayfası zaten açıksa tekrar değerlendirme.
    if (_openGateKind == kind) return;
    final service = ref.read(widgetAccessServiceProvider);
    final premium = await ref.read(premiumEntitlementProvider.future);
    final state = await service.stateFor(kind, isPremium: premium.isActive);
    if (!mounted) return;
    if (!state.allowed) {
      await _openUnlockPage(kind);
      return;
    }
    // Erişim açık: Zikirmatik widget'ına dokunmak uygulamayı doğrudan
    // Zikirmatik sayfasına götürür (diğer widget'lar yalnızca uygulamayı açar).
    if (kind == ArinWidgetAccessKind.zikir) {
      _openZikirPage();
    }
  }

  /// Kıble sekmesine geçip iç Navigator üzerinden Zikirmatik aracını açar.
  void _openZikirPage() {
    final router = ref.read(appRouterProvider);
    router.go(AppRoutes.qibla);
    // Sekme kökü (QiblaHubPage) iç Navigator'ını kurana kadar (özellikle soğuk
    // başlangıçta) birkaç yüz ms gerekebilir; artan gecikmelerle retry ediyoruz.
    var attempts = 0;
    void tryPush() {
      if (!mounted) return;
      final nav = qiblaHubNavigatorKey.currentState;
      if (nav == null) {
        if (attempts < 25) {
          attempts++;
          Future<void>.delayed(const Duration(milliseconds: 120), tryPush);
        }
        return;
      }
      nav.popUntil((r) => r.isFirst);
      nav.pushNamed(QiblaHubRoutes.zikir);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryPush());
  }

  Future<void> _openUnlockPage(ArinWidgetAccessKind kind) async {
    if (!mounted) return;
    // Aynı widget için sayfa zaten açıksa hiçbir şey yapma.
    if (_openGateKind == kind) return;

    // `WidgetLaunchGateListener`, `MaterialApp.router`'ın `builder` callback'i
    // içinde yer aldığından local `context` GoRouter ancestor'ını göremez;
    // `GoRouter.of(context)` null patlatır. Bu yüzden router instance'ını
    // doğrudan Riverpod provider'dan okuyup `push` ediyoruz.
    final router = ref.read(appRouterProvider);

    // Başka bir widget'ın kilit sayfası açıkken yeni bir widget'a dokunulduysa
    // önce açık sayfayı kapat; aksi halde kullanıcı ikinci widget için reklam
    // sayfasını hiç göremiyordu (istek sessizce düşüyordu).
    //
    // Yalnızca EN ÜSTTEKİ rota gerçekten bir widget-unlock sayfasıysa pop
    // edilir. Aksi halde (örn. kullanıcı kilit sayfasından "Premium'a geç" ile
    // premium'a gitmişse) kör bir `pop()` yanlış sayfayı kapatırdı; bu durumda
    // yeni kilit sayfası mevcut yığının üzerine push edilir.
    if (_openGateKind != null &&
        router.canPop() &&
        _isWidgetUnlockTop(router)) {
      router.pop();
    }

    _openGateKind = kind;
    try {
      await router.push(AppRoutes.widgetUnlock(kind.id));
    } finally {
      // Yalnızca bu kind hâlâ açık görünüyorsa temizle. Araya farklı bir kind
      // push edildiyse (`_openGateKind` değişmişse) onun finally'si üstlenir.
      if (_openGateKind == kind) _openGateKind = null;
    }
  }

  /// Router yığınının en üstündeki rotanın bir widget-unlock sayfası olup
  /// olmadığını döndürür. Yanlış pop'ları (örn. üstte premium varken) önler.
  bool _isWidgetUnlockTop(GoRouter router) {
    final path = router.routeInformationProvider.value.uri.path;
    return path.startsWith('/widget-unlock/');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
