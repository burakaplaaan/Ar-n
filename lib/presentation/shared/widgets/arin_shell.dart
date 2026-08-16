// lib/presentation/shared/widgets/arin_shell.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:arin/l10n/app_localizations.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/audio_session_coordinator.dart';
import '../../home/home_page.dart';
import '../../inspire/inspire_explore_page.dart';
import '../../inspire/inspire_viewer_session_provider.dart';
import '../../qibla/qibla_hub_back_dispatcher.dart';
import '../../qibla/qibla_hub_page.dart';
import '../../qibla/qibla_shell_swipe_provider.dart';
import '../../settings/settings_page.dart';
import '../../assistant/assistant_session.dart';
import '../../assistant/widgets/assistant_fab_host.dart';
import '../../onboarding/app_tour/app_tour_anchor.dart';
import '../../onboarding/app_tour/app_tour_controller.dart';
import '../../onboarding/app_tour/app_tour_keys.dart';
import '../../onboarding/app_tour/app_tour_overlay.dart';
import '../../willpower/breathing_bottom_nav_provider.dart';
import '../../willpower/willpower_hub_page.dart';
import 'arin_pressable.dart';
import 'offline_banner.dart';
import 'prayer_schedule_listener.dart';

/// Shell sekme sayfaları — sabit liste; PageView.builder bunu index ile çağırır.
const List<Widget> _kShellPages = [
  HomePage(),
  QiblaHubPage(),
  WillpowerHubPage(),
  InspireExplorePage(shellTab: true),
  SettingsPage(),
];

/// Bir sekme sayfasını lazy build ederken state'ini korur.
/// PageView.builder ile kullanılır; ziyaret edilmemiş sekmeler hiç build edilmez,
/// daha önce açılmış sekmeler AutomaticKeepAlive sayesinde ağaçta kalır.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});
  final Widget child;
  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class ArinShell extends StatefulWidget {
  const ArinShell({super.key, required this.child});

  final Widget child;

  @override
  State<ArinShell> createState() => _ArinShellState();
}

class _ArinShellState extends State<ArinShell> {
  PageController? _pageController;
  String? _prevShellPath;
  bool _keepPageViewMounted = false;

  /// Ana sekmede (`/home`) çıkmayı iki adıma bölmek için son geri zamanı.
  DateTime? _lastExitBackPressAt;
  static const Duration _exitConfirmWindow = Duration(seconds: 2);

  /// 1.0 = tam opak; kayd' ile ValueNotifier -- sadece _ArinBottomNav rebuild edilir.
  final ValueNotifier<double> _navBarSolidity = ValueNotifier(1.0);
  String? _lastPathForNavSolidity;
  String? _lastPathForAudioVisibility;

  static bool _isShellSwipeRoot(String path) {
    return path == AppRoutes.home ||
        path == AppRoutes.qibla ||
        path == AppRoutes.habits ||
        path == AppRoutes.inspire ||
        path == AppRoutes.settings;
  }

  static int _shellIndexFromPath(String path) {
    if (path == AppRoutes.home) return 0;
    if (path == AppRoutes.qibla) return 1;
    if (path == AppRoutes.habits) return 2;
    if (path == AppRoutes.inspire) return 3;
    if (path == AppRoutes.settings) return 4;
    return 0;
  }

  static String _shellPathForIndex(int i) {
    switch (i) {
      case 0:
        return AppRoutes.home;
      case 1:
        return AppRoutes.qibla;
      case 2:
        return AppRoutes.habits;
      case 3:
        return AppRoutes.inspire;
      case 4:
        return AppRoutes.settings;
      default:
        return AppRoutes.home;
    }
  }

  static bool _isQiblaStackPath(String path) {
    return path == AppRoutes.qibla || path.startsWith('${AppRoutes.qibla}/');
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/qibla')) return 1;
    if (location.startsWith('/habits')) return 2;
    if (location.startsWith('/inspire')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  bool _onShellScrollNotification(ScrollNotification notification) {
    final m = notification.metrics;
    if (m.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      final p = m.pixels.clamp(0.0, 260.0);
      final solid = 1.0 - (p / 260.0) * 0.78;
      if ((solid - _navBarSolidity.value).abs() > 0.02) {
        // Yalnızca ValueNotifier güncellenir; shell tree rebuild edilmez.
        _navBarSolidity.value = solid.clamp(0.18, 1.0);
      }
    } else if (notification is ScrollEndNotification) {
      if (m.pixels < 24) {
        _navBarSolidity.value = 1.0;
      }
    }
    return false;
  }

  void _onTabTap(BuildContext context, int index) {
    clearAssistantReturnPending(context);
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.qibla);
        break;
      case 2:
        context.go(AppRoutes.habits);
        break;
      case 3:
        context.go(AppRoutes.inspire);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  /// PageView ile görünen sekme; animasyon sırasında küresel yol henüz güncellenmemiş olabilir.
  int? _visibleShellPageIndex() {
    final c = _pageController;
    if (c == null || !c.hasClients) return null;
    final p = c.page;
    if (p == null) return null;
    return p.round().clamp(0, 4);
  }

  void _onSystemBack(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;
    final tourActive = ProviderScope.containerOf(context, listen: false)
        .read(appTourControllerProvider)
        .active;
    if (tourActive) return;
    final path = GoRouterState.of(context).uri.path;
    final visible = _visibleShellPageIndex();
    if (dispatchQiblaHubBack(currentPath: path, isQiblaVisible: visible == 1)) {
      _lastExitBackPressAt = null;
      return;
    }
    if (popToAssistantIfNeeded(context)) {
      _lastExitBackPressAt = null;
      return;
    }
    final router = GoRouter.of(context);
    if (path.contains('/inspire/view')) {
      _lastExitBackPressAt = null;
      ProviderScope.containerOf(
        context,
      ).read(inspireViewerCloseRequestProvider.notifier).state++;
      return;
    }
    if (router.canPop()) {
      _lastExitBackPressAt = null;
      router.pop();
      return;
    }
    final shellRoot = _isShellSwipeRoot(path);

    // Bildirim/deep-link Dua Halkası / Bilgi Düellosu nested hub yerine
    // doğrudan GoRouter ile açılabilir. Geri → Kıble paneli.
    if (path == AppRoutes.prayerCircle || path == AppRoutes.hilalDuel) {
      _lastExitBackPressAt = null;
      context.go(AppRoutes.qibla);
      return;
    }
    if (path == AppRoutes.assistant) {
      _lastExitBackPressAt = null;
      context.go(AppRoutes.home);
      return;
    }

    // Parmakla sekme kaydırıldıysa path bazen /home kalır; geri önce gerçek sekmeye göre ana sayfaya gitsin.
    if (shellRoot && visible != null && visible != 0) {
      _lastExitBackPressAt = null;
      context.go(AppRoutes.home);
      return;
    }
    if (!shellRoot && path != AppRoutes.home) {
      _lastExitBackPressAt = null;
      context.go(AppRoutes.home);
      return;
    }
    if (shellRoot && path != AppRoutes.home) {
      _lastExitBackPressAt = null;
      context.go(AppRoutes.home);
      return;
    }
    final now = DateTime.now();
    if (_lastExitBackPressAt != null &&
        now.difference(_lastExitBackPressAt!) < _exitConfirmWindow) {
      _lastExitBackPressAt = null;
      SystemNavigator.pop();
      return;
    }
    _lastExitBackPressAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.shellExitConfirmBackTwice),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _syncPageToRoute(String path) {
    final idx = _shellIndexFromPath(path);
    _pageController ??= PageController(initialPage: idx);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pageController == null || !_pageController!.hasClients) {
        return;
      }
      final cur = _pageController!.page;
      if (cur == null) return;
      if ((cur - idx).abs() < 0.05) return;
      // Ara sekmelerden (ör. pusula) geçmeden hedef sekmeye git — nested /habits/... sonrası yanlış ekran görünmesin.
      if ((cur - idx).abs() > 1.01) {
        _pageController!.jumpToPage(idx);
      } else {
        _pageController!.animateToPage(
          idx,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _navBarSolidity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final swipeRoot = _isShellSwipeRoot(path);
    final onInspireView = path.contains('/inspire/view');
    final keepPageView = swipeRoot || onInspireView;
    final currentIndex = _currentIndex(context);

    if (keepPageView) {
      final idx = onInspireView ? 3 : _shellIndexFromPath(path);
      if (_pageController == null) {
        _pageController = PageController(initialPage: idx);
      } else if (!_keepPageViewMounted) {
        _pageController!.dispose();
        _pageController = PageController(initialPage: idx);
      }
      _keepPageViewMounted = true;
      if (swipeRoot && _prevShellPath != path) {
        _prevShellPath = path;
        _syncPageToRoute(path);
      }
    } else {
      _prevShellPath = null;
      _keepPageViewMounted = false;
    }

    return Consumer(
      builder: (context, ref, _) {
        ref.watch(themeModeProvider);
        if (_lastPathForNavSolidity != path) {
          _lastPathForNavSolidity = path;
          _navBarSolidity.value = 1.0;
        }
        final blockShellSwipeOnQibla = ref.watch(
          qiblaHubBlocksShellSwipeProvider,
        );
        final previousAudioPath = _lastPathForAudioVisibility;
        if (previousAudioPath != path) {
          _lastPathForAudioVisibility = path;
          if (previousAudioPath != null &&
              _isQiblaStackPath(previousAudioPath) &&
              !_isQiblaStackPath(path)) {
            unawaited(
              AudioSessionCoordinator.pauseOwner(AudioSessionOwner.healing),
            );
          }
        }
        final tourActive = ref.watch(
          appTourControllerProvider.select((s) => s.active),
        );
        if (tourActive) {
          _navBarSolidity.value = 1.0;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final controller = ref.read(appTourControllerProvider.notifier);
          controller.maybeStart();
          final started = ref.read(appTourControllerProvider);
          if (started.active && started.step != null && path != started.step!.route) {
            context.go(started.step!.route);
          }
        });
        final pagePhysics =
            onInspireView ||
                tourActive ||
                (currentIndex == 1 && blockShellSwipeOnQibla)
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics();

        // PageView aynı Stack yuvasında kalsın; aksi halde kapanışta
        // initialPage=0 (Home) ile yeniden kurulup bir kare flaşlar.
        final Widget innerBody;
        if (keepPageView) {
          innerBody = Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController!,
                physics: pagePhysics,
                itemCount: 5,
                onPageChanged: (i) {
                  if (onInspireView) return;
                  HapticFeedback.selectionClick();
                  _navBarSolidity.value = 1.0;
                  final next = _shellPathForIndex(i);
                  if (path != next) {
                    context.go(next);
                  }
                },
                itemBuilder: (context, index) {
                  return _KeepAlivePage(child: _kShellPages[index]);
                },
              ),
              if (!swipeRoot) widget.child,
            ],
          );
        } else {
          innerBody = SizedBox.expand(child: widget.child);
        }

        final body = NotificationListener<ScrollNotification>(
          onNotification: _onShellScrollNotification,
          child: innerBody,
        );

        final light = Theme.of(context).brightness == Brightness.light;
        final hideBreathing = ref.watch(breathingBottomNavHiddenProvider);
        final hideBottomBar =
            path.contains('/habits/custom/') ||
            (path.contains('/habits/will/breathing') && hideBreathing) ||
            path.contains('/inspire/view');
        final overlay = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: light
              ? Brightness.dark
              : Brightness.light,
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _onSystemBack(context);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              body: AssistantFabHost(
                child: Stack(
                children: [
                  body,
                  const Positioned.fill(
                    child: IgnorePointer(child: PrayerScheduleListener()),
                  ),
                  // Çevrimdışı şeridi — üst kenarda, SafeArea üstünde kalır.
                  // Pointer event'leri engellemesin diye status bar seviyesine
                  // sabitlenmiş; kendisi küçük (icon + yazı) dokunuşu "yutmaz".
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      // Banner sadece bilgilendirme amaçlı; üstteki geri/kapama
                      // ve diğer kontrollerin dokunuşunu engellemesin.
                      child: OfflineBanner(),
                    ),
                  ),
                ],
              ),
              ),
              bottomNavigationBar: hideBottomBar
                  ? null
                  : Directionality(
                      // Keep shell chrome stable in Arabic: don't mirror bottom bar.
                      textDirection: TextDirection.ltr,
                      child: Transform.translate(
                        offset: const Offset(0, 8),
                        // ValueListenableBuilder: scroll olayları yalnızca
                        // _ArinBottomNav'ı rebuild eder, shell gövdesi dokunulmaz.
                        child: ValueListenableBuilder<double>(
                          valueListenable: _navBarSolidity,
                          builder: (_, solidity, __) => _ArinBottomNav(
                            currentIndex: currentIndex,
                            isLightShell: light,
                            navBarSolidity: solidity,
                            onTap: (i) {
                              _navBarSolidity.value = 1.0;
                              _onTabTap(context, i);
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ),
              const AppTourOverlay(),
            ],
          ),
        );
      },
    );
  }
}

// ─── Alt navigasyon ────────────────────────────────────────────────────────

Color _navIconColor(bool lightShell, bool selected) {
  if (!lightShell) {
    return selected ? Colors.white : Colors.white.withValues(alpha: 0.32);
  }
  return selected ? AppColors.emeraldDark : AppColors.textSecondary;
}

/// Ayarlar sekmesi — dişli yerine yatay „kontrol çubuğu“ çizgileri + seçimde hafif yayılma.
class _SettingsHubIcon extends StatelessWidget {
  const _SettingsHubIcon({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, t, _) {
        final scale = 1.0 + 0.14 * t;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 26,
            height: 22,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hubBar(color, 0.92, t),
                _hubBar(color, 0.65, t * 0.85),
                _hubBar(color, 0.78, t * 0.92),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _hubBar(Color c, double widthFactor, double emphasis) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 3.2,
        width: 24 * widthFactor + 4 * emphasis,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(99),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: 0.35),
                    blurRadius: 4 + 4 * emphasis,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _ArinBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isLightShell;

  /// 1.0 = opak; düşük = daha şeffaf (kaydırma ile azalır).
  final double navBarSolidity;

  const _ArinBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.isLightShell,
    required this.navBarSolidity,
  });

  static Color _withSolidity(Color c, double solidity) {
    final t = (0.34 + 0.66 * solidity).clamp(0.2, 1.0);
    return c.withValues(alpha: (c.a * t).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final s = navBarSolidity.clamp(0.0, 1.0);
    final borderBase = isLightShell
        ? AppColors.creamDark.withValues(alpha: 0.55)
        : AppColors.accentNeonGreen.withValues(alpha: 0.08);
    final barBase = isLightShell
        ? AppColors.creamSurface.withValues(alpha: 0.94)
        : AppColors.shellBarBg.withValues(alpha: 0.86);
    final borderColor = _withSolidity(borderBase, s);
    final barColor = _withSolidity(barBase, s);
    final shadowA = ((isLightShell ? 0.09 : 0.28) * (0.45 + 0.55 * s)).clamp(
      0.02,
      0.35,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: barColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowA),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIconButton(
                // Anasayfa — günün genel paneli (selam, wisdom, namaz, vakit).
                // "Ev" semantiği en doğrudan eşleşme.
                customIcon: Icon(
                  Icons.home_rounded,
                  size: 26,
                  color: _navIconColor(isLightShell, currentIndex == 0),
                ),
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              AppTourAnchor(
                id: AppTourTargetId.navTools,
                child: _NavIconButton(
                // "Araçlar" sekmesi — pusula + zikirmatik + rahatlatıcı
                // frekansları aynı hub altında topluyor. Tek araçla (pusula)
                // sınırlı bir ikon yerine ızgara metaforu kullanıyoruz:
                // `Icons.apps_rounded` kullanıcının "birden çok araç var"
                // sezgisini 24×24 alanında net verir.
                customIcon: Icon(
                  Icons.apps_rounded,
                  size: 26,
                  color: _navIconColor(isLightShell, currentIndex == 1),
                ),
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              ),
              AppTourAnchor(
                id: AppTourTargetId.navWillpower,
                child: _CenterFab(
                  onTap: () => onTap(2),
                  isSelected: currentIndex == 2,
                ),
              ),
              AppTourAnchor(
                id: AppTourTargetId.navExplore,
                child: _NavIconButton(
                customIcon: Icon(
                  Icons.search_rounded,
                  size: 26,
                  color: _navIconColor(isLightShell, currentIndex == 3),
                ),
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              ),
              AppTourAnchor(
                id: AppTourTargetId.navSettings,
                child: _NavIconButton(
                customIcon: _SettingsHubIcon(
                  color: _navIconColor(isLightShell, currentIndex == 4),
                  active: currentIndex == 4,
                ),
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatefulWidget {
  const _NavIconButton({
    this.icon,
    this.customIcon,
    required this.isSelected,
    required this.onTap,
  }) : assert(icon != null || customIcon != null);

  final IconData? icon;
  final Widget? customIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

/// Alt bar ikonlarına, tıklama anı ile seçim değişimi anında tek seferlik
/// hafif "kıpraşma" verir (rotation-based wiggle). Scale animasyonu ise
/// mevcut seçim durumuna göre [AnimatedScale] ile süregelir.
class _NavIconButtonState extends State<_NavIconButton>
    with SingleTickerProviderStateMixin, _NavWiggleMixin {
  @override
  void didUpdateWidget(covariant _NavIconButton old) {
    super.didUpdateWidget(old);
    // Sekme swipe ile (tap olmadan) değişirse de ikon kıpraşsın.
    if (!old.isSelected && widget.isSelected) {
      triggerWiggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.32);
    final Widget mark =
        widget.customIcon ?? Icon(widget.icon!, color: color, size: 23);

    return ArinPressable(
      scale: 0.88,
      sink: 1.0,
      haptic: false,
      onTap: () {
        triggerWiggle();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: widget.isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedBuilder(
            animation: wiggleAnimation,
            builder: (context, child) =>
                Transform.rotate(angle: wiggleAnimation.value, child: child),
            child: mark,
          ),
        ),
      ),
    );
  }
}

/// Hem `_NavIconButton` hem `_CenterFab` aynı "wiggle" jestini kullansın diye
/// küçük bir mixin. ~360 ms'lik yumuşayan bir sin dalgası üretir:
/// -4° → +3° → -2° → 0 şeklinde tatlı bir sallanma.
///
/// - `triggerWiggle()` her tıklama / her seçim girişinde çağrılır.
/// - Controller zaten çalışıyorken tekrar tetiklenirse baştan alır → kullanıcı
///   hızlı hızlı tap atsa bile tek, tutarlı hareket görür.
mixin _NavWiggleMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  late final AnimationController _wiggleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  late final Animation<double> wiggleAnimation = _wiggleCtrl.drive(
    const _WiggleTween(),
  );

  void triggerWiggle() {
    if (!mounted) return;
    _wiggleCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _wiggleCtrl.dispose();
    super.dispose();
  }
}

/// Sönümlü sinüsoid: t∈[0,1] için amplitüdü zamanla zayıflayan bir dalga.
/// Maks genlik ~0.07 rad (~4°) — görsel olarak fark edilir ama dikkat
/// dağıtmaz. Dalganın 2 tam salınımı 360 ms'de tamamlanır.
class _WiggleTween extends Animatable<double> {
  const _WiggleTween();

  static const double _amplitude = 0.07;
  static const double _cycles = 2.0;

  @override
  double transform(double t) {
    if (t <= 0 || t >= 1) return 0;
    final decay = 1 - t; // sondan başa doğru zayıflar
    return math.sin(t * _cycles * 2 * math.pi) * _amplitude * decay;
  }
}

/// Yukarı bakan üçgen — alışkanlık takibi orta sekme.
class _UpTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width - 2, size.height - 2)
      ..lineTo(2, size.height - 2)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TriangleGlowPainter extends CustomPainter {
  const _TriangleGlowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width - 2, size.height - 2)
      ..lineTo(2, size.height - 2)
      ..close();
    canvas.drawPath(
      path.shift(const Offset(0, 5)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _TriangleGlowPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TriangleBorderPainter extends CustomPainter {
  _TriangleBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width - 2, size.height - 2)
      ..lineTo(2, size.height - 2)
      ..close();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CenterFab extends StatefulWidget {
  final VoidCallback onTap;
  final bool isSelected;

  const _CenterFab({required this.onTap, required this.isSelected});

  static const double _w = 56;
  static const double _h = 50;

  @override
  State<_CenterFab> createState() => _CenterFabState();
}

class _CenterFabState extends State<_CenterFab>
    with SingleTickerProviderStateMixin, _NavWiggleMixin {
  @override
  void didUpdateWidget(covariant _CenterFab old) {
    super.didUpdateWidget(old);
    if (!old.isSelected && widget.isSelected) {
      triggerWiggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: ArinPressable(
        scale: 0.92,
        sink: 1.2,
        haptic: false,
        onTap: () {
          triggerWiggle();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: wiggleAnimation,
          builder: (context, child) =>
              Transform.rotate(angle: wiggleAnimation.value, child: child),
          child: AnimatedScale(
            scale: widget.isSelected ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: _CenterFab._w,
              height: _CenterFab._h,
              child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: const Size(_CenterFab._w, _CenterFab._h),
                      painter: _TriangleGlowPainter(
                        color: AppColors.accentGlowGreen.withValues(alpha: 0.42),
                      ),
                    ),
                    ClipPath(
                      clipper: _UpTriangleClipper(),
                      child: Container(
                        width: _CenterFab._w,
                        height: _CenterFab._h,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.accentNeonGreen,
                              AppColors.accentGlowGreen,
                              AppColors.emeraldMid,
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    if (widget.isSelected)
                      CustomPaint(
                        size: const Size(_CenterFab._w, _CenterFab._h),
                        painter: _TriangleBorderPainter(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.task_alt_rounded,
                        color: Colors.white.withValues(alpha: 0.98),
                        size: 26,
                        shadows: const [
                          Shadow(
                            color: Color(0x40000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ),
      ),
    );
  }
}
