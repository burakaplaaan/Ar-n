import 'dart:async';
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'breathing_wav_file_stub.dart'
    if (dart.library.io) 'breathing_wav_file_io.dart'
    as wav_file;

/// Tut fazında yavaşlayan kalp ritmi — yüksek seviye PCM + mümkün olduğunca tam hız (ses şiddeti için).
final class BreathingHeartbeatAudio {
  BreathingHeartbeatAudio() : _player = AudioPlayer() {
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
  }

  final AudioPlayer _player;
  Timer? _timer;
  static const int _wavBuildId = 5;
  static Uint8List? _cachedWav;
  static int _loadedBuildId = -1;
  bool _prepareDone = false;
  Future<void>? _prepareFuture;
  String? _diskPath;
  bool _disposed = false;
  int _runToken = 0;

  static Uint8List get _lubDubWav {
    if (_loadedBuildId != _wavBuildId) {
      _cachedWav = _buildLubDubWav();
      _loadedBuildId = _wavBuildId;
    }
    return _cachedWav!;
  }

  Future<void> prepare() {
    if (_disposed) return Future.value();
    _prepareFuture ??= _prepareInner();
    return _prepareFuture!;
  }

  Future<void> _prepareInner() async {
    if (_prepareDone || _disposed) return;
    try {
      if (!kIsWeb) {
        if (_disposed) return;
        final session = await AudioSession.instance;
        if (_disposed) return;
        await session.configure(const AudioSessionConfiguration.music());
        if (_disposed) return;
        await session.setActive(true);
      }
      if (_disposed) return;
      if (!kIsWeb) {
        await _player.setPlayerMode(PlayerMode.mediaPlayer);
      } else {
        await _player.setPlayerMode(PlayerMode.lowLatency);
      }
      if (_disposed) return;
      await _player.setVolume(1.0);
      if (!kIsWeb) {
        if (_disposed) return;
        _diskPath = await wav_file.ensureHeartbeatWavOnDisk(_lubDubWav);
      }
    } catch (_) {
      // BytesSource yedek
    } finally {
      if (!_disposed) {
        _prepareDone = true;
      }
    }
  }

  void stop() {
    _runToken++;
    _timer?.cancel();
    _timer = null;
    if (_disposed) return;
    unawaited(_player.stop());
  }

  void dispose() {
    _disposed = true;
    _runToken++;
    _timer?.cancel();
    _timer = null;
    unawaited(_player.dispose());
  }

  void startSlowingRhythm({
    required int holdSeconds,
    required bool Function() shouldContinue,
    void Function()? onPulse,
  }) {
    final token = ++_runToken;
    unawaited(
      _runSlowingRhythm(
        holdSeconds,
        shouldContinue,
        token: token,
        onPulse: onPulse,
      ),
    );
  }

  Future<void> _runSlowingRhythm(
    int holdSeconds,
    bool Function() shouldContinue, {
    required int token,
    void Function()? onPulse,
  }) async {
    if (_disposed || token != _runToken) return;
    _timer?.cancel();
    _timer = null;
    if (!_disposed) {
      unawaited(_player.stop());
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (_disposed || token != _runToken) return;
    await prepare();
    if (_disposed || token != _runToken) return;

    final phaseStart = DateTime.now();
    final phaseEnd = phaseStart.add(Duration(seconds: holdSeconds));

    Future<void> playOnce(double slowT) async {
      if (_disposed || token != _runToken) return;
      await _player.setVolume(1.0);
      // Bazı cihaz/codec kombinasyonlarında playbackRate çağrısı hata verirse
      // sesi tamamen yutmasın; rate başarısız olsa da normal hızda çalsın.
      final rate = (0.86 - slowT * 0.16).clamp(0.62, 0.86);
      try {
        await _player.setPlaybackRate(rate);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('BreathingHeartbeatAudio.setPlaybackRate: $e\n$st');
        }
      }

      final path = _diskPath;
      if (path != null && path.isNotEmpty) {
        try {
          if (_disposed || token != _runToken) return;
          await _player.play(DeviceFileSource(path, mimeType: 'audio/wav'));
          return;
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('BreathingHeartbeatAudio.filePlay fallback: $e\n$st');
          }
        }
      }

      try {
        if (_disposed || token != _runToken) return;
        await _player.play(BytesSource(_lubDubWav, mimeType: 'audio/wav'));
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('BreathingHeartbeatAudio.bytesPlay failed: $e\n$st');
        }
      }
    }

    void beat() {
      if (_disposed || token != _runToken) return;
      if (!shouldContinue()) return;
      final now = DateTime.now();
      if (!now.isBefore(phaseEnd)) return;

      final elapsed = now.difference(phaseStart).inMilliseconds / 1000.0;
      final slowT = (elapsed / holdSeconds).clamp(0.0, 1.0);

      onPulse?.call();
      unawaited(playOnce(slowT));

      // Tut fazı 7sn olduğu için en az birkaç vuruş net duyulsun.
      // Başta daha sık, sona doğru yavaşlayan aralık.
      final gapMs = (1280 + slowT * 1650).round().clamp(1150, 3000);
      _timer = Timer(Duration(milliseconds: gapMs), beat);
    }

    _timer = Timer(Duration.zero, beat);
  }

  /// Yüksek kazanç + yumuşak kırpma; hoparlörde net duyulsun.
  static Uint8List _buildLubDubWav() {
    const sampleRate = 44100;
    const totalMs = 520;
    const nFrames = sampleRate * totalMs ~/ 1000;
    const dataSize = nFrames * 2;
    final out = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(out);

    void writeStr(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        bd.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    bd.setUint32(4, 36 + dataSize, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    bd.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < nFrames; i++) {
      final tSec = i / sampleRate;
      final tMs = tSec * 1000.0;
      var sample = 0.0;

      if (tMs >= 2 && tMs < 145) {
        final lt = (tMs - 2) / 143;
        final env = math.sin(lt * math.pi) * math.exp(-2.9 * lt);
        sample +=
            env *
            (1.12 * math.sin(2 * math.pi * 32 * tSec) +
                0.58 * math.sin(2 * math.pi * 64 * tSec) +
                0.32 * math.sin(2 * math.pi * 96 * tSec));
      }
      if (tMs >= 158 && tMs < 330) {
        final lt = (tMs - 158) / 172;
        final env = math.sin(lt * math.pi) * math.exp(-3.6 * lt);
        sample +=
            env *
            (1.02 * math.sin(2 * math.pi * 44 * tSec) +
                0.52 * math.sin(2 * math.pi * 88 * tSec));
      }

      final shaped = (sample * 2.35).clamp(-1.0, 1.0);
      final s = (shaped * 32767).round().clamp(-32768, 32767);
      bd.setInt16(44 + i * 2, s, Endian.little);
    }

    return out;
  }
}
