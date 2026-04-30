// lib/presentation/shared/widgets/offline_banner.dart
// Üstten sliding "çevrimdışısın" şeridi. Bağlantı geri gelince 2 sn
// görünür kalıp kaybolur (kullanıcı "geri döndü" bilsin).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/connectivity_provider.dart';

/// [ArinShell]'in üst kenarına, SafeArea altına yerleştirilen banner.
/// Bağlıyken 0 yükseklik; çevrimdışı → kırmızımsı amber şerit. Bağlantı geri
/// gelince 2 sn kısa yeşil "tekrar bağlandın" mesajı, sonra gizlenir.
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool? _prevOnline;
  bool _showReconnected = false;
  Timer? _hideReconnectedTimer;
  late final ProviderSubscription<AsyncValue<bool>> _connectivitySub;

  @override
  void initState() {
    super.initState();
    _connectivitySub = ref.listenManual<AsyncValue<bool>>(
      connectivityStatusProvider,
      (_, next) {
        if (!next.hasValue || next.isLoading || next.hasError) return;
        final online = next.value == true;

        if (_prevOnline != null && _prevOnline == false && online) {
          _hideReconnectedTimer?.cancel();
          if (!_showReconnected && mounted) {
            setState(() => _showReconnected = true);
          } else {
            _showReconnected = true;
          }
          _hideReconnectedTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showReconnected = false);
          });
        } else if (!online && _showReconnected) {
          _hideReconnectedTimer?.cancel();
          if (mounted) {
            setState(() => _showReconnected = false);
          } else {
            _showReconnected = false;
          }
        }
        _prevOnline = online;
      },
    );
  }

  @override
  void dispose() {
    _hideReconnectedTimer?.cancel();
    _connectivitySub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(connectivityStatusProvider);

    // İlk data gelene kadar (loading) hiçbir banner gösterme.
    if (status.isLoading || status.hasError) {
      return const SizedBox.shrink();
    }

    final online = status.value == true;

    final showOffline = !online;
    final showReconnected = online && _showReconnected;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        axisAlignment: -1,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: showOffline
          ? const _BannerBody(
              key: ValueKey('offline'),
              text: 'Çevrimdışısın',
              bgColor: Color(0xFFB45309),
              fgColor: Colors.white,
            )
          : showReconnected
              ? const _BannerBody(
                  key: ValueKey('reconnected'),
                  icon: Icons.wifi_rounded,
                  text: 'Tekrar bağlandın',
                  bgColor: AppColors.emeraldMid,
                  fgColor: Colors.white,
                )
              : const SizedBox.shrink(key: ValueKey('none')),
    );
  }
}

class _BannerBody extends StatelessWidget {
  const _BannerBody({
    super.key,
    required this.text,
    required this.bgColor,
    required this.fgColor,
    this.icon,
  });

  final IconData? icon;
  final String text;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Align(
          alignment: Alignment.topCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.26),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fgColor, size: 11),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: fgColor.withValues(alpha: 0.96),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                      shadows: const [
                        Shadow(
                          color: Color(0x55000000),
                          blurRadius: 4,
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
