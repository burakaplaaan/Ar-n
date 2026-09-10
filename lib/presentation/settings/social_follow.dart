// Ayarlar: Arın sosyal profilleri (Instagram / TikTok).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics/arin_analytics.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../shared/widgets/arin_pressable.dart';
import '../shared/widgets/arin_top_toast.dart';

const kArinSocialHandle = 'arinapptr';

enum ArinSocialNetwork { instagram, tiktok }

typedef ArinSocialUrlLaunch = Future<bool> Function(Uri uri);

/// Profil aday URI'leri: önce uygulama şeması (varsa), sonra https.
List<Uri> arinSocialProfileUris(ArinSocialNetwork network) {
  switch (network) {
    case ArinSocialNetwork.instagram:
      return [
        Uri.parse('instagram://user?username=$kArinSocialHandle'),
        Uri.parse('https://www.instagram.com/$kArinSocialHandle/'),
      ];
    case ArinSocialNetwork.tiktok:
      return [
        Uri.parse('https://www.tiktok.com/@$kArinSocialHandle'),
      ];
  }
}

String arinSocialHandleLabel() => '@$kArinSocialHandle';

String arinSocialNetworkAnalyticsName(ArinSocialNetwork network) {
  switch (network) {
    case ArinSocialNetwork.instagram:
      return 'instagram';
    case ArinSocialNetwork.tiktok:
      return 'tiktok';
  }
}

bool _isHttpUri(Uri uri) => uri.scheme == 'https' || uri.scheme == 'http';

Future<bool> openArinSocialProfile(
  ArinSocialNetwork network, {
  ArinSocialUrlLaunch? launch,
  Future<bool> Function(Uri uri)? canLaunch,
}) async {
  final launcher =
      launch ??
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
  final canOpen = canLaunch ?? canLaunchUrl;
  for (final uri in arinSocialProfileUris(network)) {
    try {
      // instagram:// yüklü değilken iOS sistem hatası göstermesin;
      // https yedeğine geç. Yalnız launch enjekte edildiyse (birim test)
      // canLaunchUrl çağrılmaz.
      final shouldProbeScheme = canLaunch != null || launch == null;
      if (shouldProbeScheme && !_isHttpUri(uri)) {
        final supported = await canOpen(uri);
        if (!supported) continue;
      }
      if (await launcher(uri)) return true;
    } catch (_) {
      // Sonraki aday.
    }
  }
  return false;
}

class SettingsSocialFollowCard extends StatefulWidget {
  const SettingsSocialFollowCard({
    super.key,
    required this.onDark,
    this.launch,
  });

  final bool onDark;
  final ArinSocialUrlLaunch? launch;

  @override
  State<SettingsSocialFollowCard> createState() =>
      _SettingsSocialFollowCardState();
}

class _SettingsSocialFollowCardState extends State<SettingsSocialFollowCard> {
  bool _opening = false;

  Future<void> _open(ArinSocialNetwork network) async {
    if (_opening) return;
    setState(() => _opening = true);
    unawaited(
      ArinAnalytics.log(
        'settings_follow_tap',
        {'network': arinSocialNetworkAnalyticsName(network)},
      ),
    );
    var opened = false;
    try {
      opened = await openArinSocialProfile(
        network,
        launch: widget.launch,
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
    if (!mounted || opened) return;
    showArinTopToast(
      context,
      AppLocalizations.of(context)!.settingsFollowOpenFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = widget.onDark;
    final border = onDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.creamDark.withValues(alpha: 0.55);
    final fill = onDark
        ? AppColors.cardSurface.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.72);
    final divider = onDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.creamDark.withValues(alpha: 0.55);

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: onDark ? 0.22 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _FollowRow(
            onDark: onDark,
            enabled: !_opening,
            icon: const _InstagramMark(size: 40),
            title: l10n.settingsFollowInstagramTitle,
            subtitle: arinSocialHandleLabel(),
            onTap: () => _open(ArinSocialNetwork.instagram),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 68),
            child: Divider(height: 1, thickness: 0.6, color: divider),
          ),
          _FollowRow(
            onDark: onDark,
            enabled: !_opening,
            icon: const _TikTokMark(size: 40),
            title: l10n.settingsFollowTikTokTitle,
            subtitle: arinSocialHandleLabel(),
            onTap: () => _open(ArinSocialNetwork.tiktok),
          ),
        ],
      ),
    );
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({
    required this.onDark,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool onDark;
  final bool enabled;
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = (onDark ? Colors.white : AppColors.emeraldDark)
        .withValues(alpha: enabled ? 0.96 : 0.5);
    final subtitleColor = (onDark
            ? AppColors.textOnDarkMuted
            : AppColors.textMuted)
        .withValues(alpha: enabled ? 1 : 0.7);
    final arrowColor = onDark
        ? Colors.white.withValues(alpha: enabled ? 0.38 : 0.2)
        : AppColors.textMuted.withValues(alpha: enabled ? 0.85 : 0.45);

    return Semantics(
      button: true,
      enabled: enabled,
      label: '$title $subtitle',
      child: ArinPressable(
        enabled: enabled,
        haptic: false,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.north_east_rounded, size: 18, color: arrowColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstagramMark extends StatelessWidget {
  const _InstagramMark({required this.size});

  final double size;

  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <defs>
    <radialGradient id="igFill" cx="30%" cy="107%" r="150%">
      <stop offset="0%" stop-color="#FDF497"/>
      <stop offset="45%" stop-color="#FD5949"/>
      <stop offset="60%" stop-color="#D6249F"/>
      <stop offset="90%" stop-color="#285AEB"/>
    </radialGradient>
  </defs>
  <rect width="48" height="48" rx="12" fill="url(#igFill)"/>
  <rect x="12.2" y="12.2" width="23.6" height="23.6" rx="7" fill="none" stroke="#FFFFFF" stroke-width="2.5"/>
  <circle cx="24" cy="24" r="5.8" fill="none" stroke="#FFFFFF" stroke-width="2.5"/>
  <circle cx="31.7" cy="16.4" r="1.55" fill="#FFFFFF"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }
}

class _TikTokMark extends StatelessWidget {
  const _TikTokMark({required this.size});

  final double size;

  static const String _note = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final noteSize = size * 0.52;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: noteSize + 3,
        height: noteSize + 3,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(-1.15, 0.55),
              child: SvgPicture.string(
                _note,
                width: noteSize,
                height: noteSize,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF25F4EE),
                  BlendMode.srcIn,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(1.15, -0.35),
              child: SvgPicture.string(
                _note,
                width: noteSize,
                height: noteSize,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFFE2C55),
                  BlendMode.srcIn,
                ),
              ),
            ),
            SvgPicture.string(
              _note,
              width: noteSize,
              height: noteSize,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
