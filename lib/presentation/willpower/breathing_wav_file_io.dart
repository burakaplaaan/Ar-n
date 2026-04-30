import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> ensureHeartbeatWavOnDisk(Uint8List pcmWav) async {
  final base = await getApplicationSupportDirectory();
  final dir = Directory('${base.path}${Platform.pathSeparator}arin_audio');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final f = File('${dir.path}${Platform.pathSeparator}heartbeat_loud_v5.wav');
  try {
    if (!await f.exists() || await f.length() < 100) {
      await f.writeAsBytes(pcmWav, flush: true);
    }
  } catch (_) {
    return null;
  }
  return f.path;
}
