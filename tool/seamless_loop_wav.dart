// 60 sn (veya --seconds) kesip döngü birleşiminde raised-cosine crossfade uygular.
// Giriş: WAV (PCM 16 LE), MP3, AIFF/AIFC (PCM 16 BE, SSND). Çıkış: mono 16-bit WAV.
// Örnek (ortadan 60 sn, döngü 2 sn; ortada 30 sn birleşiminde ek yumuşatma):
//   dart run tool/seamless_loop_wav.dart --input=...aiff --output=.../ambi_fire.wav --seconds=60 --crossfade-ms=2000 --mid-crossfade-ms=2000 --skip-start-sec=0 --segment=center

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:minimp3_dart/minimp3.dart';

void main(List<String> args) {
  final opts = _parseArgs(args);
  final inputPath = opts['input'] ?? 'tool/incoming_evren.mp3';
  final outputPath =
      opts['output'] ?? 'assets/sounds/healing/ambi/ambi_evren.wav';
  final seconds = int.tryParse(opts['seconds'] ?? '60') ?? 60;
  final crossfadeMs = int.tryParse(opts['crossfade-ms'] ?? '2000') ?? 2000;
  final midCrossfadeMs = int.tryParse(opts['mid-crossfade-ms'] ?? '0') ?? 0;
  final skipStartSec =
      double.tryParse(opts['skip-start-sec'] ?? '0') ?? 0.0;
  final edgeMs = int.tryParse(opts['edge-ms'] ?? '0') ?? 0;
  final segment = (opts['segment'] ?? 'start').toLowerCase();

  final input = File(inputPath);
  if (!input.existsSync()) {
    stderr.writeln(
      'Dosya yok: $inputPath\n'
      'İndirdiğin dosyayı bu yola koy veya --input=yol kullan.',
    );
    exit(1);
  }

  final bytes = input.readAsBytesSync();
  final lower = inputPath.toLowerCase();
  late final Int16List mono;
  late final int sr;

  if (lower.endsWith('.mp3')) {
    final decoded = _decodeMp3ToMono(bytes);
    mono = decoded.samples;
    sr = decoded.sampleRate;
  } else if (lower.endsWith('.aiff') || lower.endsWith('.aif') || lower.endsWith('.aifc')) {
    final aiff = _parseAiff(bytes);
    if (aiff == null) {
      stderr.writeln('AIFF/AIFC okunamadı (PCM 16, SSND gerekir).');
      exit(1);
    }
    mono = aiff.samples;
    sr = aiff.sampleRate;
  } else {
    final wav = _parseWav(bytes);
    if (wav == null) {
      stderr.writeln('WAV okunamadı (PCM 16 bit desteklenir).');
      exit(1);
    }
    mono = _toMonoInt16Le(bytes, wav);
    sr = wav.sampleRate;
  }

  final skipSamples = (skipStartSec * sr)
      .round()
      .clamp(0, math.max(0, mono.length - 1))
      .toInt();
  final want = seconds * sr;
  final cfMid = (sr * midCrossfadeMs / 1000).round();
  final needLen = (cfMid > 0 && seconds >= 4) ? want + cfMid : want;
  final usableLen = mono.isEmpty ? 0 : (mono.length - skipSamples);
  if (usableLen <= 0) {
    stderr.writeln('Boş veya geçersiz ses verisi.');
    exit(1);
  }

  if (needLen > usableLen) {
    stderr.writeln(
      'Kaynak çok kısa: gerekli ~${(needLen / sr).toStringAsFixed(2)} sn, '
      'kullanılabilir ~${(usableLen / sr).toStringAsFixed(2)} sn '
      '(mid-crossfade için ek ${(cfMid / sr).toStringAsFixed(2)} sn gerekir).',
    );
    exit(1);
  }

  var startIdx = skipSamples;
  if (segment == 'center' && usableLen >= needLen) {
    startIdx = skipSamples + ((usableLen - needLen) ~/ 2);
  }

  final Int16List seg;
  if (cfMid > 0 && seconds >= 4) {
    seg = _buildTwoHalvesWithMidJoin(
      mono,
      startIdx,
      want,
      sr,
      seconds,
      cfMid,
    );
  } else {
    seg = Int16List(want);
    final available = mono.length - startIdx;
    if (available >= want) {
      for (var i = 0; i < want; i++) {
        seg[i] = mono[startIdx + i];
      }
    } else {
      for (var i = 0; i < want; i++) {
        seg[i] = mono[startIdx + (i % available)];
      }
    }
  }

  final cf = (sr * crossfadeMs / 1000).round().clamp(256, want ~/ 2);
  _raisedCosineLoopCrossfade(seg, cf);
  if (edgeMs > 0) {
    _microEdgeFade(seg, sr, edgeMs);
  }

  final outFile = File(outputPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsBytesSync(_pcmWavBytes(sr, seg));
  stderr.writeln(
    'Yazıldı: $outputPath (${seconds}s, loop crossfade=${crossfadeMs}ms, '
    'mid=${midCrossfadeMs}ms, skip=${skipStartSec}s, segment=$segment, '
    'startSample=$startIdx, mono, ${sr}Hz)',
  );
}

/// İki yarım (ör. 30+30 sn) birleşiminde ortada [cfMid] örnek raised-cosine (kaynak 2*half+cf).
Int16List _buildTwoHalvesWithMidJoin(
  Int16List mono,
  int startIdx,
  int want,
  int sr,
  int seconds,
  int cfMid,
) {
  final half = (seconds * sr) ~/ 2;
  if (half < 256 || want != seconds * sr || 2 * half != want) {
    return Int16List(want)..setRange(0, want, mono, startIdx);
  }
  var cf = cfMid.clamp(64, half - 1);
  final needSrc = 2 * half + cf;
  if (startIdx + needSrc > mono.length) {
    cf = math.min(cf, mono.length - startIdx - 2 * half);
    cf = cf.clamp(64, half - 1);
  }
  final out = Int16List(want);
  final s = startIdx;
  for (var i = 0; i < half - cf; i++) {
    out[i] = mono[s + i];
  }
  for (var i = 0; i < cf; i++) {
    final g = cf <= 1 ? 1.0 : 0.5 * (1 - math.cos(math.pi * i / (cf - 1)));
    final a = mono[s + half - cf + i].toDouble();
    final b = mono[s + half + i].toDouble();
    out[half - cf + i] = (a * (1 - g) + b * g).round().clamp(-32768, 32767);
  }
  for (var i = 0; i < half; i++) {
    out[half + i] = mono[s + half + i];
  }
  return out;
}

Map<String, String> _parseArgs(List<String> args) {
  final m = <String, String>{};
  for (final a in args) {
    if (a.startsWith('--')) {
      final eq = a.indexOf('=');
      if (eq > 0) {
        m[a.substring(2, eq)] = a.substring(eq + 1);
      }
    }
  }
  return m;
}

({Int16List samples, int sampleRate}) _decodeMp3ToMono(Uint8List bytes) {
  final dec = Mp3Decoder()..initialize();
  final out = <int>[];
  var byteOff = 0;
  var sr = 44100;
  var stuck = 0;
  while (byteOff < bytes.length) {
    final frame = dec.decodeFrame(bytes, offset: byteOff);
    if (frame == null) {
      stuck++;
      if (stuck > 4096) break;
      byteOff++;
      continue;
    }
    stuck = 0;
    byteOff = frame.nextOffset;
    if (frame.info.layer != 3) continue;
    sr = frame.info.sampleRateHz;
    final pcm = frame.pcm;
    final ch = frame.info.channels;
    final n = frame.samples;
    if (ch == 2) {
      for (var i = 0; i < n; i++) {
        final l = pcm[i * 2];
        final r = pcm[i * 2 + 1];
        out.add(((l + r) / 2).round().clamp(-32768, 32767));
      }
    } else {
      for (var i = 0; i < n; i++) {
        out.add(pcm[i]);
      }
    }
  }
  if (out.isEmpty) {
    stderr.writeln('MP3 çözülemedi (dosya bozuk veya ID3 sonrası senk bulunamadı).');
    exit(1);
  }
  return (samples: Int16List.fromList(out), sampleRate: sr);
}

/// Apple AIFF/IEEE 80-bit extended → double (örnek hız için).
double _aiffExt80ToDouble(Uint8List b, int o) {
  final expon = ((b[o] & 0x7f) << 8) | b[o + 1];
  final hiMant = _readBE32(b, o + 2).toUnsigned(32);
  final loMant = _readBE32(b, o + 6).toUnsigned(32);
  if (expon == 0 && hiMant == 0 && loMant == 0) return 0;
  if (expon == 0x7fff) return 44100;
  var e = expon - 16383 - 31;
  var f = hiMant * math.pow(2, e).toDouble();
  e -= 32;
  f += loMant * math.pow(2, e).toDouble();
  if ((b[o] & 0x80) != 0) f = -f;
  return f;
}

({Int16List samples, int sampleRate})? _parseAiff(Uint8List bytes) {
  if (bytes.length < 24) return null;
  if (String.fromCharCodes(bytes.sublist(0, 4)) != 'FORM') return null;
  final formType = String.fromCharCodes(bytes.sublist(8, 12));
  if (formType != 'AIFF' && formType != 'AIFC') return null;

  int? channels;
  int? numFrames;
  int? bits;
  double? sampleRate;
  int? ssndStart;
  int? ssndDataSize;

  var off = 12;
  while (off + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(off, off + 4));
    final size = _readBE32(bytes, off + 4);
    final content = off + 8;
    final next = content + size + (size.isOdd ? 1 : 0);

    if (id == 'COMM') {
      if (size < 18 || content + 18 > bytes.length) return null;
      channels = _readBE16(bytes, content);
      numFrames = _readBE32(bytes, content + 2);
      bits = _readBE16(bytes, content + 6);
      sampleRate = _aiffExt80ToDouble(bytes, content + 8);
    } else if (id == 'SSND') {
      if (size < 8 || content + 8 > bytes.length) return null;
      final pad = _readBE32(bytes, content);
      final pcmBytes = size - 8 - pad;
      if (pcmBytes <= 0) return null;
      ssndStart = content + 8 + pad;
      ssndDataSize = pcmBytes;
    }
    off = next;
  }

  if (channels == null ||
      numFrames == null ||
      bits == null ||
      sampleRate == null ||
      ssndStart == null ||
      ssndDataSize == null) {
    return null;
  }
  final ch = channels;
  final nf = numFrames;
  final bitsVal = bits;
  final rate = sampleRate;
  final ss0 = ssndStart;
  final ssz = ssndDataSize;
  if (bitsVal != 16 || ch < 1) return null;
  final sr = rate.round().clamp(8000, 192000);
  final frameBytes = ch * 2;
  final maxFrames = ssz ~/ frameBytes;
  final nFrames = math.min(nf, maxFrames);
  if (nFrames <= 0 || ss0 + nFrames * frameBytes > bytes.length) {
    return null;
  }

  final out = Int16List(nFrames);
  for (var f = 0; f < nFrames; f++) {
    var sum = 0;
    for (var c = 0; c < ch; c++) {
      final bi = ss0 + f * frameBytes + c * 2;
      sum += _readBE16(bytes, bi);
    }
    out[f] = (sum / ch).round().clamp(-32768, 32767);
  }
  return (samples: out, sampleRate: sr);
}

int _readBE16(Uint8List b, int o) =>
    ByteData.sublistView(b, o, o + 2).getInt16(0, Endian.big);

int _readBE32(Uint8List b, int o) =>
    ByteData.sublistView(b, o, o + 4).getUint32(0, Endian.big);

class _WavInfo {
  _WavInfo({
    required this.sampleRate,
    required this.channels,
    required this.bits,
    required this.dataOffset,
    required this.dataSize,
  });

  final int sampleRate;
  final int channels;
  final int bits;
  final int dataOffset;
  final int dataSize;
}

_WavInfo? _parseWav(Uint8List bytes) {
  if (bytes.length < 44) return null;
  if (String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF') return null;
  if (String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') return null;

  var off = 12;
  int? sampleRate;
  int? channels;
  int? bits;
  var dataOffset = 0;
  var dataSize = 0;

  while (off + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(off, off + 4));
    final size = ByteData.sublistView(bytes, off + 4, off + 8)
        .getUint32(0, Endian.little);
    final contentStart = off + 8;
    final next = contentStart + size + (size.isOdd ? 1 : 0);

    if (id == 'fmt ') {
      if (contentStart + 16 > bytes.length) return null;
      final bd = ByteData.sublistView(bytes, contentStart);
      final audioFormat = bd.getUint16(0, Endian.little);
      if (audioFormat != 1) return null;
      channels = bd.getUint16(2, Endian.little);
      sampleRate = bd.getUint32(4, Endian.little);
      bits = bd.getUint16(14, Endian.little);
      if (bits != 16) return null;
    } else if (id == 'data') {
      dataOffset = contentStart;
      dataSize = size;
      break;
    }
    off = next;
  }

  if (sampleRate == null ||
      channels == null ||
      bits == null ||
      dataSize == 0) {
    return null;
  }
  return _WavInfo(
    sampleRate: sampleRate,
    channels: channels,
    bits: bits,
    dataOffset: dataOffset,
    dataSize: dataSize,
  );
}

Int16List _toMonoInt16Le(Uint8List bytes, _WavInfo wav) {
  final frameBytes = wav.channels * 2;
  final nFrames = wav.dataSize ~/ frameBytes;
  final out = Int16List(nFrames);
  final bd = ByteData.sublistView(bytes, wav.dataOffset, wav.dataOffset + wav.dataSize);
  for (var f = 0; f < nFrames; f++) {
    var sum = 0;
    for (var c = 0; c < wav.channels; c++) {
      sum += bd.getInt16(f * frameBytes + c * 2, Endian.little);
    }
    out[f] = (sum / wav.channels).round().clamp(-32768, 32767);
  }
  return out;
}

void _raisedCosineLoopCrossfade(Int16List seg, int cf) {
  final n = seg.length;
  final c = cf.clamp(4, n ~/ 2);
  final copy = Int16List.fromList(seg);
  for (var i = 0; i < c; i++) {
    final g = 0.5 * (1 - math.cos(math.pi * i / (c - 1)));
    final a = copy[i].toDouble();
    final b = copy[n - c + i].toDouble();
    seg[i] = (a * (1 - g) + b * g).round().clamp(-32768, 32767);
  }
}

void _microEdgeFade(Int16List buf, int sr, int edgeMs) {
  final e = (sr * edgeMs / 1000).round().clamp(1, buf.length ~/ 4);
  for (var i = 0; i < e; i++) {
    final g = i / (e - 1);
    buf[i] = (buf[i] * g).round().clamp(-32768, 32767);
  }
  for (var i = 0; i < e; i++) {
    final g = i / (e - 1);
    final j = buf.length - 1 - i;
    buf[j] = (buf[j] * g).round().clamp(-32768, 32767);
  }
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
