import 'dart:async';

import 'package:flutter/widgets.dart';

/// Araçlar hub ikonları — decode boyutu kartta görünen 64px ile sınırlı.
abstract final class QiblaHubAssets {
  static const tilePaths = <String>[
    'assets/images/qibla_hub/qibla_hub_ai.png',
    'assets/images/qibla_hub/qibla_hub_compass.png',
    'assets/images/qibla_hub/qibla_hub_tasbeeh.png',
    'assets/images/qibla_hub/qibla_hub_quran.png',
    'assets/images/qibla_hub/qibla_hub_hilal.png',
    'assets/images/qibla_hub/qibla_hub_prayer.png',
    'assets/images/qibla_hub/qibla_hub_healing.png',
    'assets/images/qibla_hub/qibla_hub_breath.png',
  ];

  static const socialPreviewPaths = <String>[
    'assets/social/avatars/01.png',
    'assets/social/avatars/03.png',
    'assets/social/avatars/06.png',
  ];

  static bool _warming = false;

  static int glyphCacheWidth(double devicePixelRatio) {
    return (64 * devicePixelRatio).round().clamp(64, 192);
  }

  static int socialPreviewCacheWidth(double devicePixelRatio) {
    return (26 * devicePixelRatio).round().clamp(26, 80);
  }

  /// Hub PNG'lerini küçük boyutta ısıtır; Araçlar sekmesi açılmadan önce
  /// çağrılırsa ilk kare decode maliyeti düşer.
  static Future<void> precache(BuildContext context) async {
    if (_warming) return;
    _warming = true;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final tileW = glyphCacheWidth(dpr);
    final faceW = socialPreviewCacheWidth(dpr);
    try {
      for (final path in tilePaths) {
        if (!context.mounted) {
          _warming = false;
          return;
        }
        await precacheImage(
          ResizeImage(AssetImage(path), width: tileW),
          context,
        );
      }
      for (final path in socialPreviewPaths) {
        if (!context.mounted) {
          _warming = false;
          return;
        }
        await precacheImage(
          ResizeImage(AssetImage(path), width: faceW),
          context,
        );
      }
    } catch (_) {
      _warming = false;
    }
  }
}
