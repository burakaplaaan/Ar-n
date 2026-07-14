// Namaz bildirimi için 32 kHz mono PCM WAV üretir (Android res/raw, iOS Runner).
// Çalıştır: dart run tool/generate_prayer_notification_wavs.dart
//
// Flutter MP3 önizlemeleri ve gerçek kayıtlar için:
// tool/audio_trim/trim_notification_assets.mjs (ffmpeg + aday MP3).

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  const sr = 32000;
  const seconds = 2;
  final root = Directory.current;

  final jobs = <({String file, double hz, double peak})>[
    (file: 'prayer_ntf_adhan_turkish', hz: 523.25, peak: 5200),
    (file: 'prayer_ntf_adhan_dubai', hz: 392.0, peak: 5000),
    (file: 'prayer_ntf_ambient_flute', hz: 880.0, peak: 3800),
    (file: 'prayer_ntf_ambient_piano_guitar', hz: 330.0, peak: 4200),
    (file: 'prayer_ntf_ambient_ethereal', hz: 659.25, peak: 3600),
  ];

  final rawDir = Directory('${root.path}/android/app/src/main/res/raw');
  final iosDir = Directory('${root.path}/ios/Runner');
  rawDir.createSync(recursive: true);
  iosDir.createSync(recursive: true);

  for (final j in jobs) {
    final bytes = _sineWav(sr: sr, seconds: seconds, hz: j.hz, peak: j.peak);
    final name = '${j.file}.wav';
    File('${rawDir.path}/$name').writeAsBytesSync(bytes);
    File('${iosDir.path}/$name').writeAsBytesSync(bytes);
    stderr.writeln('Wrote $name');
  }
}

Uint8List _sineWav({
  required int sr,
  required int seconds,
  required double hz,
  required double peak,
}) {
  final n = sr * seconds;
  final samples = Int16List(n);
  final w = 2 * math.pi * hz / sr;
  for (var i = 0; i < n; i++) {
    final env = 0.5 * (1.0 + math.sin(2 * math.pi * 0.5 * i / n));
    samples[i] = (peak * env * math.sin(w * i)).round().clamp(-32768, 32767);
  }
  return _pcmWavBytes(sr, samples);
}

Uint8List _pcmWavBytes(int sr, Int16List samples) {
  final dataBytes = samples.buffer.asUint8List(
    samples.offsetInBytes,
    samples.length * 2,
  );
  final dataSize = dataBytes.length;
  const headerSize = 44;
  final out = Uint8List(headerSize + dataSize);
  final bd = ByteData.sublistView(out);
  var o = 0;
  void writeStr(String s) {
    for (var i = 0; i < s.length; i++) {
      out[o++] = s.codeUnitAt(i);
    }
  }

  writeStr('RIFF');
  bd.setUint32(o, 36 + dataSize, Endian.little);
  o += 4;
  writeStr('WAVE');
  writeStr('fmt ');
  bd.setUint32(o, 16, Endian.little);
  o += 4;
  bd.setUint16(o, 1, Endian.little);
  o += 2;
  bd.setUint16(o, 1, Endian.little);
  o += 2;
  bd.setUint32(o, sr, Endian.little);
  o += 4;
  bd.setUint32(o, sr * 2, Endian.little);
  o += 4;
  bd.setUint16(o, 2, Endian.little);
  o += 2;
  bd.setUint16(o, 16, Endian.little);
  o += 2;
  writeStr('data');
  bd.setUint32(o, dataSize, Endian.little);
  o += 4;
  out.setRange(o, o + dataBytes.length, dataBytes);
  return out;
}
