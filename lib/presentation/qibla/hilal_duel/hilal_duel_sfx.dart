import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Bilgi Düellosu kısa SFX — tek player, düşük gecikme, sessiz hata yutar.
class HilalDuelSfx {
  HilalDuelSfx._();
  static final HilalDuelSfx instance = HilalDuelSfx._();

  static const _tap = 'sounds/quiz/tap.wav';
  static const _correct = 'sounds/quiz/correct.wav';
  static const _wrong = 'sounds/quiz/wrong.wav';
  static const _win = 'sounds/quiz/win.wav';
  static const _lose = 'sounds/quiz/lose.wav';

  AudioPlayer? _player;
  Future<void>? _playChain;
  Future<AudioPlayer>? _ensureFuture;

  Future<AudioPlayer> _ensurePlayer() {
    final existing = _player;
    if (existing != null) return Future<AudioPlayer>.value(existing);
    return _ensureFuture ??= () async {
      final player = AudioPlayer();
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setVolume(0.85);
        _player = player;
        return player;
      } catch (_) {
        _ensureFuture = null;
        await player.dispose();
        rethrow;
      }
    }();
  }

  void playTap() => unawaited(_enqueue(_tap));
  void playCorrect() => unawaited(_enqueue(_correct));
  void playWrong() => unawaited(_enqueue(_wrong));
  void playWin() => unawaited(_enqueue(_win));
  void playLose() => unawaited(_enqueue(_lose));

  Future<void> _enqueue(String asset) {
    final prev = _playChain ?? Future<void>.value();
    final next = prev.catchError((_) {}).then((_) => _play(asset));
    _playChain = next;
    return next;
  }

  Future<void> _play(String asset) async {
    try {
      final player = await _ensurePlayer();
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (error) {
      debugPrint('HilalDuelSfx play deferred: $error');
    }
  }

  Future<void> dispose() async {
    final player = _player;
    _player = null;
    _playChain = null;
    if (player == null) return;
    try {
      await player.dispose();
    } catch (_) {}
  }
}
