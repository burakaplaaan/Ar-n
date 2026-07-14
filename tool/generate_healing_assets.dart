// Üretir: sinüs tonları + ambiyans (orman, ateş, evren) mono WAV döngüleri.
// Çalıştır: dart run tool/generate_healing_assets.dart
// Sadece Hz tonları (ambiyansa dokunma): dart run tool/generate_healing_assets.dart --tones-only

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main(List<String> args) {
  final tonesOnly = args.contains('--tones-only');
  final root = Directory.current;
  final tonesDir = Directory('${root.path}/assets/sounds/healing/tones');
  final ambiDir = Directory('${root.path}/assets/sounds/healing/ambi');
  tonesDir.createSync(recursive: true);
  ambiDir.createSync(recursive: true);

  // Tonların en yükseği 852 Hz; 16 kHz PCM, dalga biçimini ve kesintisiz
  // döngüyü korurken 44.1 kHz'e göre dosya boyutunu %64 azaltır.
  const toneSr = 16000;

  /// Tam saniye × tam Hz ⇒ tam sayıda sinüs periyodu; döngü sınırı daha seyrek (özellikle iOS’ta
  /// `seek(0)` ile yeniden başlama tıklaması daha az duyulur). ~10 sn mono ≈ 0.88 MB (SoundPool üst sınırına yakın).
  const toneSec = 10;
  for (final hz in [174, 285, 396, 417, 528, 639, 741, 852]) {
    final path = File('${tonesDir.path}/tone_${hz}hz.wav');
    path.writeAsBytesSync(
      _sineWav(
        sr: toneSr,
        hz: hz.toDouble(),
        seconds: toneSec,
        peak: _tonePeakForHz(hz),
      ),
    );
    stderr.writeln('Wrote ${path.path}');
  }

  if (tonesOnly) return;

  // Ambiyanslarda 22.05 kHz, telefon hoparlörü/kulaklık kullanımı için yeterli
  // bant genişliği sunar ve PCM döngü davranışını değiştirmeden boyutu yarılar.
  const ambiSr = 22050;
  const ambiSec = 4;
  _writeAmbi(ambiDir, 'forest', _rainAmbience(ambiSr, ambiSec), ambiSr);
  _writeAmbi(ambiDir, 'fire', _natureAmbience(ambiSr, ambiSec), ambiSr);
  _writeAmbi(ambiDir, 'evren', _huzurPad(ambiSr, ambiSec), ambiSr);

  // Eski dosyalar.
  final legacy = File('${ambiDir.path}/ambi_minimal.wav');
  if (legacy.existsSync()) {
    legacy.deleteSync();
    stderr.writeln('Removed legacy ${legacy.path}');
  }
  final legacyHuzur = File('${ambiDir.path}/ambi_huzur.wav');
  if (legacyHuzur.existsSync()) {
    legacyHuzur.deleteSync();
    stderr.writeln('Removed legacy ${legacyHuzur.path}');
  }
  final legacyRain = File('${ambiDir.path}/ambi_rain.wav');
  if (legacyRain.existsSync()) {
    legacyRain.deleteSync();
    stderr.writeln('Removed legacy ${legacyRain.path}');
  }
  final legacyNature = File('${ambiDir.path}/ambi_nature.wav');
  if (legacyNature.existsSync()) {
    legacyNature.deleteSync();
    stderr.writeln('Removed legacy ${legacyNature.path}');
  }
  final legacyWater = File('${ambiDir.path}/ambi_water.wav');
  if (legacyWater.existsSync()) {
    legacyWater.deleteSync();
    stderr.writeln('Removed legacy ${legacyWater.path}');
  }
}

void _writeAmbi(Directory ambiDir, String name, Int16List samples, int sr) {
  final path = File('${ambiDir.path}/ambi_$name.wav');
  path.writeAsBytesSync(_pcmWavBytes(sr, samples));
  stderr.writeln('Wrote ${path.path}');
}

/// Yağmur: yüksek frekanslı gürültü + düzensiz damla vurguları (çıkışta hafif LP ile daha az “cızırtı”).
Int16List _rainAmbience(int sr, int seconds) {
  final n = sr * seconds;
  final out = Int16List(n);
  final rnd = math.Random(0xC0FFEE);
  var hp = 0.0;
  var prevIn = 0.0;
  var lp = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final raw = rnd.nextDouble() * 2 - 1;
    hp = 0.94 * hp + 0.06 * (raw - prevIn);
    prevIn = raw;
    var v = hp * 5200;
    if (rnd.nextDouble() < 0.0075) {
      v += (rnd.nextDouble() * 2 - 1) * 6800;
    }
    final wind = 0.14 * math.sin(2 * math.pi * 0.31 * t);
    v *= 1.0 + wind;
    lp = 0.86 * lp + 0.14 * v;
    out[i] = lp.round().clamp(-32768, 32767);
  }
  return out;
}

/// Ateş yer tutucu (eski doğa sentezi): yumuşak gürültü + seyrek cıvıltı.
Int16List _natureAmbience(int sr, int seconds) {
  final n = sr * seconds;
  final out = Int16List(n);
  final rnd = math.Random(0x51DE);
  var g = 0.0;
  var chirpLeft = 0;
  var chirpFreq = 2400.0;
  var chirpEnv = 0.0;
  for (var i = 0; i < n; i++) {
    final x = rnd.nextDouble() * 2 - 1;
    g = g * 0.992 + x * 0.008;
    var v = g * 4300;
    if (chirpLeft <= 0 && rnd.nextDouble() < 0.00055) {
      chirpLeft = (sr * (0.04 + rnd.nextDouble() * 0.09)).round();
      chirpFreq = 1800 + rnd.nextDouble() * 2200;
      chirpEnv = 0;
    }
    if (chirpLeft > 0) {
      chirpEnv = (chirpEnv * 0.92 + 0.08).clamp(0.0, 1.0);
      final ph = 2 * math.pi * chirpFreq * i / sr;
      v += math.sin(ph) * 3200 * chirpEnv * chirpEnv;
      chirpLeft--;
    }
    final rustle = math.sin(2 * math.pi * 380 * i / sr) * 180 * g.abs();
    v += rustle;
    out[i] = v.round().clamp(-32768, 32767);
  }
  return out;
}

/// Evren (yer tutucu): düşük genlikli çoklu sinüs — gerçek ambiyans için bkz. README.
Int16List _huzurPad(int sr, int seconds) {
  final n = sr * seconds;
  final out = Int16List(n);
  const freqs = <double>[130.8, 164.81, 196.0, 220.0];
  const amps = <double>[0.22, 0.2, 0.18, 0.16];
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    var s = 0.0;
    for (var k = 0; k < freqs.length; k++) {
      final det = 1.0 + 0.008 * math.sin(2 * math.pi * (0.03 + k * 0.01) * t);
      s += amps[k] * math.sin(2 * math.pi * freqs[k] * det * t);
    }
    final env = 0.88 + 0.12 * math.sin(2 * math.pi * 0.07 * t);
    out[i] = (s * 7200 * env).round().clamp(-32768, 32767);
  }
  return out;
}

/// 174 Hz referans zirve; diğer tüm butonlu Hz’ler önce aynı güce getirilir, sonra listede
/// soldan sağa (285→852) çok hafif artan ince fark (~±0.2% toplam yayılım).
double _tonePeakForHz(int hz) {
  // Üçüncü kademe: ~2500 → ~1000.
  const base = 1000.0;
  if (hz == 174) return base;
  const rel = <int, double>{
    285: 0.9988,
    396: 0.9992,
    417: 0.9996,
    528: 1.0000,
    639: 1.0004,
    741: 1.0008,
    852: 1.0012,
  };
  return base * (rel[hz] ?? 1.0);
}

Uint8List _sineWav({
  required int sr,
  required double hz,
  required int seconds,
  required double peak,
}) {
  final n = sr * seconds;
  final samples = Int16List(n);
  final w = 2 * math.pi * hz / sr;
  for (var i = 0; i < n; i++) {
    samples[i] = (peak * math.sin(w * i)).round().clamp(-32768, 32767);
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
