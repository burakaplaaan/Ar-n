// iOS: UNNotificationSound yalnızca Library/Sounds veya ana bundle kökünde .wav arar;
// Flutter asset paketi kökte olmadığı için katalog WAV'ları buraya kopyalanır.
//
// Android katalog sesleri: android/app/src/main/res/raw/*.wav + RawResourceAndroidNotificationSound
// (dosya yolu / content:// yerine — bildirim kanallarında en güvenilir yol).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'prayer_notification_sounds.dart';

abstract final class PrayerCatalogSoundMaterializer {
  static Future<void> ensureMaterialized() async {
    if (kIsWeb || !Platform.isIOS) return;
    await _materializeIos();
  }

  static Future<void> _materializeIos() async {
    final lib = await getLibraryDirectory();
    final soundsDir = Directory('${lib.path}/Sounds');
    if (!await soundsDir.exists()) {
      await soundsDir.create(recursive: true);
    }
    for (var i = 1; i < PrayerNotificationSounds.options.length; i++) {
      final opt = PrayerNotificationSounds.options[i];
      final rel = opt.previewAssetRelativePath;
      final iosName = opt.iosWavFileName;
      if (rel == null || iosName == null) continue;
      final dest = File('${soundsDir.path}/$iosName');
      try {
        if (await dest.exists() && await dest.length() > 512) {
          continue;
        }
        final data = await rootBundle.load('assets/$rel');
        final bytes = data.buffer.asUint8List();
        if (bytes.isEmpty) continue;
        await dest.writeAsBytes(bytes, flush: true);
      } catch (e, st) {
        debugPrint('PrayerCatalogSoundMaterializer iOS: assets/$rel -> $e');
        debugPrint('$st');
      }
    }
  }
}
