// Bir kerelik: assets/sounds/prayer/ altına geçerli kısa WAV üretir (sinüs tonu, vakit başına farklı frekans).
// dart run tool/write_minimal_wav.dart

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/sounds/prayer');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final specs = <String, double>{
    'prayer_ntf_adhan_turkish': 523.25,
    'prayer_ntf_adhan_dubai': 440.0,
    'prayer_ntf_ambient_flute': 659.25,
    'prayer_ntf_ambient_piano_guitar': 392.0,
    'prayer_ntf_ambient_ethereal': 349.23,
  };
  for (final e in specs.entries) {
    final bytes = _pcm16WavMono(freqHz: e.value, durationSec: 2.4, sampleRate: 22050);
    File('${dir.path}/${e.key}.wav').writeAsBytesSync(bytes);
    stdout.writeln('Wrote ${e.key}.wav (${bytes.length} bytes)');
  }
}

Uint8List _pcm16WavMono({
  required double freqHz,
  required double durationSec,
  required int sampleRate,
}) {
  final n = (durationSec * sampleRate).round();
  final dataSize = n * 2;
  final buf = ByteData(44 + dataSize);
  var o = 0;
  void w4(String s) {
    for (var i = 0; i < 4; i++) {
      buf.setUint8(o++, s.codeUnitAt(i));
    }
  }

  w4('RIFF');
  buf.setUint32(o, 36 + dataSize, Endian.little);
  o += 4;
  w4('WAVE');
  w4('fmt ');
  buf.setUint32(o, 16, Endian.little);
  o += 4; // PCM chunk size
  buf.setUint16(o, 1, Endian.little);
  o += 2; // audio format PCM
  buf.setUint16(o, 1, Endian.little);
  o += 2; // channels
  buf.setUint32(o, sampleRate, Endian.little);
  o += 4;
  buf.setUint32(o, sampleRate * 2, Endian.little);
  o += 4; // byte rate
  buf.setUint16(o, 2, Endian.little);
  o += 2; // block align
  buf.setUint16(o, 16, Endian.little);
  o += 2; // bits per sample
  w4('data');
  buf.setUint32(o, dataSize, Endian.little);
  o += 4;

  const amp = 0.22;
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = 0.5 * (1 - math.cos(2 * math.pi * t / durationSec)); // fade in/out
    final s = amp * env * math.sin(2 * math.pi * freqHz * t);
    var v = (s * 32767.0).round().clamp(-32768, 32767);
    buf.setInt16(o, v, Endian.little);
    o += 2;
  }
  return buf.buffer.asUint8List();
}
