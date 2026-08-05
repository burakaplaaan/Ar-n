// İyileştirici Frekanslar — çift AudioPlayer + uyku zamanlayıcısı.

import 'dart:async';
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart' hide AndroidAudioFocus;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analytics/arin_analytics.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../data/services/audio_session_coordinator.dart';
import 'healing_freq_catalog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kHz = 'healing_last_hz';
const _kAmb = 'healing_ambient_key';
const _kToneVol = 'healing_tone_vol';
const _kAmbVol = 'healing_amb_vol';

/// Son seçilen uyku dakikası (sheet varsayılanı).
const kHealingPrefLastSleepMin = 'healing_last_sleep_minutes';

const kHealingAmbientForest = 'forest';
const kHealingAmbientFire = 'fire';
const kHealingAmbientEvren = 'evren';
const kHealingAmbientInshirah = 'inshirah';

const _kInshirahFallbackAsset =
    'sounds/healing/ambi/ambi_inshirah_fallback.mp3';
const _kInshirahPlayDuration = Duration(seconds: 40);
const _kInshirahSilenceDuration = Duration(seconds: 1);

const kHealingSleepMinuteChoices = <int>[15, 30, 45, 60, 90, 120];

/// Sinüs tonu: düşük gain — yüksek değer tüm slider aralığını 1.0’a sıkıştırıp tonu gereksiz yüksek yapıyordu.
/// Slider 0–1, çıkış max 1.0.
const double _kHealingToneGain = 0.82;

double _healingToneVolumeOut(double stored01) {
  final x = stored01.clamp(0.0, 1.0);
  // Düşük slider’da da biraz “varlık” hissi (sonra gain ile tavana vurur).
  final shaped = math.pow(x, 0.82).toDouble();
  return (shaped * _kHealingToneGain).clamp(0.0, 1.0);
}

String healingAmbientAssetPath(String key) {
  switch (key) {
    case kHealingAmbientForest:
      return 'sounds/healing/ambi/ambi_forest.mp3';
    case kHealingAmbientFire:
      return 'sounds/healing/ambi/ambi_fire.mp3';
    case kHealingAmbientEvren:
      return 'sounds/healing/ambi/ambi_evren.mp3';
    case kHealingAmbientInshirah:
      return '';
    default:
      return '';
  }
}

enum HealingPreset { focus, relax, sleep }

@immutable
class HealingAudioState {
  const HealingAudioState({
    required this.isPlaying,
    required this.hz,
    required this.ambientKey,
    required this.toneVolume01,
    required this.ambientVolume01,
    required this.playWindowStart,
    required this.sleepEndsAt,
    required this.sleepDurationSelected,
    required this.sleepRemainingPaused,
    required this.inSleepFade,
    required this.tickCounter,
  });

  final bool isPlaying;
  final int hz;
  final String ambientKey;
  final double toneVolume01;
  final double ambientVolume01;

  /// İlerleme çubuğu başlangıcı (oturum veya uyku sıfırlaması).
  final DateTime? playWindowStart;

  /// Oynatılırken mutlak bitiş; duraklatınca temizlenir, kalan [sleepRemainingPaused].
  final DateTime? sleepEndsAt;

  /// Kullanıcının seçtiği uyku süresi (null = kapalı).
  final Duration? sleepDurationSelected;

  final Duration? sleepRemainingPaused;
  final bool inSleepFade;
  final int tickCounter;
  bool get isInshirahMode => ambientKey == kHealingAmbientInshirah;

  static HealingAudioState initial(SharedPreferences prefs) {
    final rawHz = prefs.getInt(_kHz);
    final hz = rawHz ?? HealingFreqCatalog.orderedHz.first;
    final safeHz = HealingFreqCatalog.orderedHz.contains(hz)
        ? hz
        : HealingFreqCatalog.orderedHz.first;
    var amb = prefs.getString(_kAmb) ?? kHealingAmbientForest;
    if (amb == 'minimal' || amb == 'huzur') {
      amb = kHealingAmbientEvren;
      unawaited(prefs.setString(_kAmb, kHealingAmbientEvren));
    } else if (amb == 'rain') {
      amb = kHealingAmbientForest;
      unawaited(prefs.setString(_kAmb, kHealingAmbientForest));
    } else if (amb == 'nature') {
      amb = kHealingAmbientFire;
      unawaited(prefs.setString(_kAmb, kHealingAmbientFire));
    } else if (amb == 'water' || amb == 'none') {
      amb = kHealingAmbientForest;
      unawaited(prefs.setString(_kAmb, kHealingAmbientForest));
    }
    final ambKey =
        <String>{
          kHealingAmbientForest,
          kHealingAmbientFire,
          kHealingAmbientEvren,
          kHealingAmbientInshirah,
        }.contains(amb)
        ? amb
        : kHealingAmbientForest;
    final tv = (prefs.getDouble(_kToneVol) ?? 0.88).clamp(0.0, 1.0);
    final av = (prefs.getDouble(_kAmbVol) ?? 0.45).clamp(0.0, 1.0);
    final savedMin = prefs.getInt(kHealingPrefLastSleepMin);
    final initSleep =
        savedMin != null && kHealingSleepMinuteChoices.contains(savedMin)
        ? Duration(minutes: savedMin)
        : null;
    return HealingAudioState(
      isPlaying: false,
      hz: safeHz,
      ambientKey: ambKey,
      toneVolume01: tv,
      ambientVolume01: av,
      playWindowStart: null,
      sleepEndsAt: null,
      sleepDurationSelected: initSleep,
      sleepRemainingPaused: null,
      inSleepFade: false,
      tickCounter: 0,
    );
  }

  HealingAudioState copyWith({
    bool? isPlaying,
    int? hz,
    String? ambientKey,
    double? toneVolume01,
    double? ambientVolume01,
    DateTime? playWindowStart,
    bool clearPlayWindowStart = false,
    DateTime? sleepEndsAt,
    bool clearSleepEndsAt = false,
    Duration? sleepDurationSelected,
    bool clearSleepDuration = false,
    Duration? sleepRemainingPaused,
    bool clearSleepRemainingPaused = false,
    bool? inSleepFade,
    int? tickCounter,
  }) {
    return HealingAudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      hz: hz ?? this.hz,
      ambientKey: ambientKey ?? this.ambientKey,
      toneVolume01: toneVolume01 ?? this.toneVolume01,
      ambientVolume01: ambientVolume01 ?? this.ambientVolume01,
      playWindowStart: clearPlayWindowStart
          ? null
          : (playWindowStart ?? this.playWindowStart),
      sleepEndsAt: clearSleepEndsAt ? null : (sleepEndsAt ?? this.sleepEndsAt),
      sleepDurationSelected: clearSleepDuration
          ? null
          : (sleepDurationSelected ?? this.sleepDurationSelected),
      sleepRemainingPaused: clearSleepRemainingPaused
          ? null
          : (sleepRemainingPaused ?? this.sleepRemainingPaused),
      inSleepFade: inSleepFade ?? this.inSleepFade,
      tickCounter: tickCounter ?? this.tickCounter,
    );
  }

  HealingPreset? get activePreset {
    if (hz == 285) return HealingPreset.focus;
    if (hz == 528) return HealingPreset.relax;
    if (hz == 174) return HealingPreset.sleep;
    return null;
  }

  int? get selectedSleepMinutes {
    final d = sleepDurationSelected;
    if (d == null) return null;
    return d.inMinutes;
  }
}

class HealingAudioNotifier extends StateNotifier<HealingAudioState> {
  HealingAudioNotifier(this._prefs) : super(HealingAudioState.initial(_prefs)) {
    _tone = AudioPlayer();
    _ambient = AudioPlayer();
    // Keşfet BGM sahneyi alırsa healing otomatik pause olur (state korunur,
    // user geri dönüp play'e dokununca kaldığı yerden devam eder).
    AudioSessionCoordinator.register(AudioSessionOwner.healing, pause);
  }

  final SharedPreferences _prefs;

  late final AudioPlayer _tone;
  late final AudioPlayer _ambient;
  bool _sessionReady = false;
  bool _disposed = false;
  Timer? _fadeTimer;
  int _fadeTicks = 0;
  int _playbackEpoch = 0;

  /// Oynatma süresi UI’si + uyku bitişi; sayfa kapalıyken de `tick()` çalışır.
  Timer? _playbackTicker;
  Timer? _inshirahCycleTimer;

  static const int _fadeLeadMs = 2800;
  static const int _fadeTickMs = 50;
  static const int _fadeTicksTotal = 2400 ~/ _fadeTickMs; // ~2.4s ramp

  Future<void> _prepareSession() async {
    if (_sessionReady) return;
    try {
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        // İki player aynı anda: iOS’ta diğer oturumlarla karışım; Android’de daha yumuşak focus.
        await session.configure(
          const AudioSessionConfiguration.music().copyWith(
            avAudioSessionCategoryOptions:
                AVAudioSessionCategoryOptions.mixWithOthers,
            androidAudioFocusGainType:
                AndroidAudioFocusGainType.gainTransientMayDuck,
          ),
        );
        await session.setActive(true);
      }
      await _ambient.setPlayerMode(PlayerMode.mediaPlayer);
      // Android: SoundPool sonsuz döngü, PCM sınırında genelde `MediaPlayer`/`seek` tığından daha temiz.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _tone.setPlayerMode(PlayerMode.lowLatency);
      } else {
        await _tone.setPlayerMode(PlayerMode.mediaPlayer);
      }
      await _tone.setReleaseMode(ReleaseMode.loop);
      await _ambient.setReleaseMode(ReleaseMode.loop);
      await _configureHealingAudioContexts();
    } catch (_) {}
    _sessionReady = true;
  }

  /// İki [AudioPlayer] aynı anda çalsın: Android’de ton `AUDIOFOCUS_NONE` ile ambiyansın
  /// odak talebini çalmaz (aksi halde tek kanal kalabiliyor).
  Future<void> _configureHealingAudioContexts() async {
    if (_disposed || kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _ambient.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              audioFocus: AndroidAudioFocus.gain,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
            ),
          ),
        );
        await _tone.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              audioFocus: AndroidAudioFocus.none,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
            ),
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ctx = AudioContext(
          iOS: AudioContextIOS(
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        );
        await _ambient.setAudioContext(ctx);
        await _tone.setAudioContext(ctx);
      }
    } catch (_) {}
  }

  void _persistUi() {
    unawaited(_prefs.setInt(_kHz, state.hz));
    unawaited(_prefs.setString(_kAmb, state.ambientKey));
    unawaited(_prefs.setDouble(_kToneVol, state.toneVolume01));
    unawaited(_prefs.setDouble(_kAmbVol, state.ambientVolume01));
    final m = state.selectedSleepMinutes;
    if (m != null) {
      unawaited(_prefs.setInt(kHealingPrefLastSleepMin, m));
    }
  }

  Future<void> _applyVolumesToPlayers() async {
    if (_disposed) return;
    try {
      final toneOut = state.isInshirahMode
          ? 0.0
          : _healingToneVolumeOut(state.toneVolume01);
      await _tone.setVolume(toneOut);
      final ambPath = healingAmbientAssetPath(state.ambientKey);
      if (state.isInshirahMode) {
        await _ambient.setVolume(state.ambientVolume01);
      } else if (ambPath.isEmpty) {
        await _ambient.setVolume(0);
      } else {
        await _ambient.setVolume(state.ambientVolume01);
      }
    } catch (_) {}
  }

  Future<void> _startTone() async {
    if (_disposed) return;
    if (state.isInshirahMode) {
      try {
        await _tone.stop();
        await _tone.setVolume(0.0);
      } catch (_) {}
      return;
    }
    await _prepareSession();
    final path = HealingFreqCatalog.toneAssetPath(state.hz);
    try {
      final vol = _healingToneVolumeOut(state.toneVolume01);
      await _tone.setVolume(vol);
      // `stop()` bazı cihazlarda ambiyans player’ını da kesiyormuş gibi davranabiliyor;
      // `play` kaynağı değiştirip devam ettirir.
      await _tone.play(AssetSource(path));
      await _tone.setVolume(vol);
    } catch (_) {}
  }

  /// Ton yenilendikten sonra ambiyansın gerçekten çaldığını doğrular (Hz değişimi sonrası).
  Future<void> _ensureAmbientAudible() async {
    if (_disposed || !state.isPlaying) return;
    if (state.isInshirahMode) return;
    final path = healingAmbientAssetPath(state.ambientKey);
    if (path.isEmpty) return;
    try {
      await _ambient.setVolume(state.ambientVolume01);
      final ambState = _ambient.state;
      if (ambState == PlayerState.playing) {
        await _ambient.resume();
        return;
      }
      if (ambState == PlayerState.paused) {
        await _ambient.resume();
        return;
      }
      await _ambient.play(AssetSource(path));
    } catch (_) {}
  }

  Future<void> _startOrStopAmbient() async {
    if (_disposed) return;
    if (state.isInshirahMode) {
      await _startInshirahCycle();
      return;
    }
    _cancelInshirahCycle();
    final path = healingAmbientAssetPath(state.ambientKey);
    try {
      await _ambient.setReleaseMode(ReleaseMode.loop);
      await _ambient.stop();
      if (path.isEmpty) return;
      await _ambient.setVolume(state.ambientVolume01);
      await _ambient.play(AssetSource(path));
    } catch (_) {}
  }

  Future<void> _startInshirahCycle() async {
    if (_disposed || !state.isPlaying || !state.isInshirahMode) return;
    _cancelInshirahCycle();
    try {
      await _ambient.setReleaseMode(ReleaseMode.stop);
      await _ambient.setVolume(state.ambientVolume01);
      // Başlangıç gecikmesini kaldırmak için İnşirah'ı yerel asset'ten anında başlat.
      await _ambient.play(AssetSource(_kInshirahFallbackAsset));
      if (kDebugMode) {
        debugPrint('[healing] Inshirah source=instant_asset');
      }
    } catch (_) {}
    _inshirahCycleTimer = Timer(_kInshirahPlayDuration, () {
      unawaited(_inshirahSilenceThenResume());
    });
  }

  Future<void> _inshirahSilenceThenResume() async {
    if (_disposed || !state.isPlaying || !state.isInshirahMode) return;
    try {
      await _ambient.pause();
    } catch (_) {}
    _inshirahCycleTimer = Timer(_kInshirahSilenceDuration, () {
      if (_disposed || !state.isPlaying || !state.isInshirahMode) return;
      unawaited(_startInshirahCycle());
    });
  }

  Future<void> play() async {
    if (_disposed) return;
    if (state.isPlaying) {
      await _applyVolumesToPlayers();
      _startPlaybackTicker();
      return;
    }
    final startEpoch = ++_playbackEpoch;
    // Sahneyi al — varsa Keşfet BGM'i otomatik pause olur.
    await AudioSessionCoordinator.claim(AudioSessionOwner.healing);
    if (_disposed || startEpoch != _playbackEpoch) {
      AudioSessionCoordinator.release(AudioSessionOwner.healing);
      return;
    }
    var sleepEnds = state.sleepEndsAt;
    var remaining = state.sleepRemainingPaused;
    final dur = state.sleepDurationSelected;
    final now = DateTime.now();

    DateTime? windowStart = state.playWindowStart ?? now;
    if (!state.isPlaying) {
      if (sleepEnds == null && dur != null) {
        if (remaining != null) {
          sleepEnds = now.add(remaining);
          remaining = null;
        } else {
          sleepEnds = now.add(dur);
        }
      }
      if (sleepEnds != null) {
        windowStart = now;
      } else if (state.playWindowStart == null) {
        windowStart = now;
      }
    }

    state = state.copyWith(
      isPlaying: true,
      playWindowStart: windowStart,
      sleepEndsAt: sleepEnds,
      clearSleepEndsAt: sleepEnds == null,
      clearSleepRemainingPaused: true,
      sleepRemainingPaused: remaining,
    );

    // Ambiyans odak alsın; ton Android’de AUDIOFOCUS_NONE ile üstüne eklenir.
    await _startOrStopAmbient();
    if (!await _continueOrAbortStalePlayStart(startEpoch)) return;
    await _ensureAmbientAudible();
    if (!await _continueOrAbortStalePlayStart(startEpoch)) return;
    await _startTone();
    if (!await _continueOrAbortStalePlayStart(startEpoch)) return;
    await _applyVolumesToPlayers();
    if (!await _continueOrAbortStalePlayStart(startEpoch)) return;
    await _ensureAmbientAudible();
    if (!await _continueOrAbortStalePlayStart(startEpoch)) return;
    _startPlaybackTicker();
    state = state.copyWith(tickCounter: state.tickCounter + 1);
    unawaited(ArinAnalytics.frekansPlay('${state.hz}hz_${state.ambientKey}'));
  }

  bool _isPlayStartCurrent(int startEpoch) {
    return !_disposed && state.isPlaying && startEpoch == _playbackEpoch;
  }

  Future<bool> _continueOrAbortStalePlayStart(int startEpoch) async {
    if (_isPlayStartCurrent(startEpoch)) return true;
    if (!_disposed && !state.isPlaying) {
      try {
        await _tone.pause();
        await _ambient.pause();
      } catch (_) {}
    }
    AudioSessionCoordinator.release(AudioSessionOwner.healing);
    return false;
  }

  void _startPlaybackTicker() {
    _stopPlaybackTicker();
    if (!state.isPlaying || _disposed) return;
    _playbackTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      tick();
    });
  }

  void _stopPlaybackTicker() {
    _playbackTicker?.cancel();
    _playbackTicker = null;
  }

  Future<void> pause() async {
    if (_disposed) return;
    _playbackEpoch++;
    _stopPlaybackTicker();
    _cancelInshirahCycle();
    _cancelFadeTimer();
    final now = DateTime.now();
    Duration? rem;
    final end = state.sleepEndsAt;
    if (end != null) {
      rem = end.difference(now);
      if (rem.isNegative) rem = Duration.zero;
    }
    state = state.copyWith(
      isPlaying: false,
      sleepEndsAt: null,
      clearSleepEndsAt: true,
      sleepRemainingPaused: rem,
      clearSleepRemainingPaused: rem == null,
      inSleepFade: false,
    );
    try {
      await _tone.pause();
      await _ambient.pause();
    } catch (_) {}
    // Sahneyi bırak (aktif sahibi biz değilsek no-op).
    AudioSessionCoordinator.release(AudioSessionOwner.healing);
    state = state.copyWith(tickCounter: state.tickCounter + 1);
    unawaited(ArinAnalytics.frekansPause());
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> setHz(int hz) async {
    if (!HealingFreqCatalog.orderedHz.contains(hz)) return;
    state = state.copyWith(hz: hz);
    _persistUi();
    await _syncToneAndAmbientPlayback();
    state = state.copyWith(tickCounter: state.tickCounter + 1);
  }

  /// Hz seçildiğinde çalıyorsa tonu yeniler. Çalmıyorken yalnızca seçim + tercih güncellenir (otomatik başlatmaz).
  Future<void> selectFrequency(int hz) async {
    if (state.isInshirahMode) return;
    if (!HealingFreqCatalog.orderedHz.contains(hz)) return;
    state = state.copyWith(hz: hz);
    _persistUi();
    await _syncToneAndAmbientPlayback();
    state = state.copyWith(tickCounter: state.tickCounter + 1);
  }

  Future<void> _syncToneAndAmbientPlayback() async {
    if (!state.isPlaying) return;
    await _ensureAmbientAudible();
    await _startTone();
    await _applyVolumesToPlayers();
    await _ensureAmbientAudible();
  }

  void setPreset(HealingPreset p) {
    if (state.isInshirahMode) return;
    final hz = switch (p) {
      HealingPreset.focus => 285,
      HealingPreset.relax => 528,
      HealingPreset.sleep => 174,
    };
    if (p == HealingPreset.sleep) {
      state = state.copyWith(hz: hz, toneVolume01: 0.15, ambientVolume01: 0.7);
      _persistUi();
      unawaited(_applyPresetPlayback());
    } else if (p == HealingPreset.focus) {
      state = state.copyWith(hz: hz, toneVolume01: 0.6, ambientVolume01: 0.9);
      _persistUi();
      unawaited(_applyPresetPlayback());
    } else {
      unawaited(selectFrequency(hz));
    }
  }

  Future<void> _applyPresetPlayback() async {
    await _syncToneAndAmbientPlayback();
    state = state.copyWith(tickCounter: state.tickCounter + 1);
  }

  Future<void> setAmbientKey(String key) async {
    var k = key;
    if (key == 'minimal' || key == 'huzur') {
      k = kHealingAmbientEvren;
    } else if (key == 'rain') {
      k = kHealingAmbientForest;
    } else if (key == 'nature') {
      k = kHealingAmbientFire;
    } else if (key == 'water' || key == 'none') {
      k = kHealingAmbientForest;
    }
    const allowed = <String>{
      kHealingAmbientForest,
      kHealingAmbientFire,
      kHealingAmbientEvren,
      kHealingAmbientInshirah,
    };
    if (!allowed.contains(k)) k = kHealingAmbientForest;
    if (state.ambientKey == k) return;
    state = state.copyWith(ambientKey: k);
    _persistUi();
    if (state.isPlaying) {
      await _startOrStopAmbient();
      if (state.isInshirahMode) {
        try {
          await _tone.stop();
        } catch (_) {}
      }
      await _syncToneAndAmbientPlayback();
    } else if (state.isInshirahMode) {
      try {
        await _tone.setVolume(0.0);
      } catch (_) {}
    }
    state = state.copyWith(tickCounter: state.tickCounter + 1);
  }

  void setToneVolume01(double v) {
    if (state.isInshirahMode) return;
    state = state.copyWith(toneVolume01: v.clamp(0.0, 1.0));
    _persistUi();
    unawaited(_tone.setVolume(_healingToneVolumeOut(state.toneVolume01)));
    state = state.copyWith(tickCounter: state.tickCounter + 1);
  }

  void setAmbientVolume01(double v) {
    state = state.copyWith(ambientVolume01: v.clamp(0.0, 1.0));
    _persistUi();
    unawaited(_applyVolumesToPlayers());
    state = state.copyWith(tickCounter: state.tickCounter + 1);
  }

  /// [minutes] null veya sıfır: uyku zamanlayıcıyı kapatır.
  void setSleepMinutes(int? minutes) {
    if (minutes == null || minutes <= 0) {
      state = state.copyWith(
        clearSleepDuration: true,
        clearSleepEndsAt: true,
        clearSleepRemainingPaused: true,
      );
      _persistUi();
      state = state.copyWith(tickCounter: state.tickCounter + 1);
      return;
    }
    final d = Duration(minutes: minutes);
    final now = DateTime.now();
    if (state.isPlaying) {
      final end = now.add(d);
      state = state.copyWith(
        sleepDurationSelected: d,
        sleepEndsAt: end,
        clearSleepEndsAt: false,
        playWindowStart: now,
        clearSleepRemainingPaused: true,
      );
    } else {
      state = state.copyWith(
        sleepDurationSelected: d,
        clearSleepEndsAt: true,
        clearSleepRemainingPaused: true,
      );
    }
    unawaited(_prefs.setInt(kHealingPrefLastSleepMin, minutes));
    state = state.copyWith(tickCounter: state.tickCounter + 1);
  }

  void tick() {
    if (_disposed) return;
    final now = DateTime.now();
    if (state.isPlaying && state.sleepEndsAt != null && !state.inSleepFade) {
      final left = state.sleepEndsAt!.difference(now).inMilliseconds;
      if (left <= 0) {
        unawaited(_finishSleepStop());
        return;
      }
      if (left <= _fadeLeadMs) {
        _beginSleepFade();
      }
    }
    state = state.copyWith(tickCounter: state.tickCounter + 1);
  }

  void _beginSleepFade() {
    if (_disposed || state.inSleepFade) return;
    state = state.copyWith(inSleepFade: true);
    _fadeTicks = 0;
    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(
      const Duration(milliseconds: _fadeTickMs),
      (_) => unawaited(_fadeTick()),
    );
  }

  Future<void> _fadeTick() async {
    if (_disposed) return;
    _fadeTicks++;
    final t = (_fadeTicks / _fadeTicksTotal).clamp(0.0, 1.0);
    final f = 1.0 - t;
    try {
      await _tone.setVolume(_healingToneVolumeOut(state.toneVolume01) * f);
      final path = healingAmbientAssetPath(state.ambientKey);
      if (path.isNotEmpty) {
        await _ambient.setVolume(state.ambientVolume01 * f);
      }
    } catch (_) {}
    if (_fadeTicks >= _fadeTicksTotal) {
      _cancelFadeTimer();
      await _finishSleepStop();
    }
  }

  void _cancelFadeTimer() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _fadeTicks = 0;
  }

  Future<void> _finishSleepStop() async {
    if (_disposed) return;
    _playbackEpoch++;
    _stopPlaybackTicker();
    _cancelInshirahCycle();
    _cancelFadeTimer();
    try {
      await _tone.stop();
      await _ambient.stop();
      await _tone.setVolume(_healingToneVolumeOut(state.toneVolume01));
      await _ambient.setVolume(state.ambientVolume01);
    } catch (_) {}
    state = state.copyWith(
      isPlaying: false,
      inSleepFade: false,
      clearSleepEndsAt: true,
      clearSleepRemainingPaused: true,
      clearPlayWindowStart: true,
    );
    state = state.copyWith(tickCounter: state.tickCounter + 1);
    AudioSessionCoordinator.release(AudioSessionOwner.healing);
  }

  void onAppResumed() {
    if (_disposed) return;
    final now = DateTime.now();
    final end = state.sleepEndsAt;
    if (state.isPlaying && end != null && !end.isAfter(now)) {
      unawaited(_finishSleepStop());
      return;
    }
    if (state.isPlaying) {
      tick();
    }
  }

  Future<void> disposePlayers() async {
    if (_disposed) return;
    _disposed = true;
    _stopPlaybackTicker();
    _cancelInshirahCycle();
    _cancelFadeTimer();
    AudioSessionCoordinator.unregister(AudioSessionOwner.healing);
    try {
      await _tone.stop();
      await _ambient.stop();
      await _tone.dispose();
      await _ambient.dispose();
    } catch (_) {}
  }

  void _cancelInshirahCycle() {
    _inshirahCycleTimer?.cancel();
    _inshirahCycleTimer = null;
  }
}

final healingAudioNotifierProvider =
    StateNotifierProvider.autoDispose<HealingAudioNotifier, HealingAudioState>((
      ref,
    ) {
      final prefs = ref.watch(sharedPreferencesProvider);
      final n = HealingAudioNotifier(prefs);
      ref.onDispose(n.disposePlayers);
      return n;
    });
