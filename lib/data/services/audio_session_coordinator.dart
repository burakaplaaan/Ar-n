// lib/data/services/audio_session_coordinator.dart
//
// Uzun soluklu ses kaynakları (Healing Frequencies + Keşfet BGM) arasında
// mutual exclusion sağlar. Kullanıcı healing'i açıp Keşfet'e geçip BGM'i
// açtığında iki ses üst üste çalıyordu; şimdi bir oynatıcı "sahne"yi alınca
// önceki sahibinin `pause` callback'i çağrılıyor.
//
// Tasarım notları:
// - `register` / `unregister` notifier'ın yaşam döngüsüne bağlı
//   (Riverpod `ref.onDispose` veya explicit `disposePlayers`).
// - `claim` önceki sahibi varsa onun `onPause` callback'ini await eder ve
//   ardından aktif sahibi günceller. Concurrent `claim` çağrıları sıra takip
//   eder — ikinci claim birincinin pause'unu beklemez, sadece kendinden
//   önceki `_active` değerine bakar (rekabet varsa UI katmanında çözülmeli).
// - Kısa tetik sesler (nefes kalp vuruşu, ezan önizleme) koordinatörü
//   kullanmaz — birkaç saniyelik örtüşme UX açısından sorun değil ve
//   "sahne sahibi" kavramını değiştirmemeli.

import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// Koordinatörün tanıdığı uzun soluklu sahne sahipleri.
/// Genişletirken: kısa tetik sesler eklememeye dikkat (bkz. dosya başı notu).
enum AudioSessionOwner {
  healing,
  exploreBgm,
}

typedef AudioStopCallback = Future<void> Function();

abstract final class AudioSessionCoordinator {
  static AudioSessionOwner? _active;
  static final Map<AudioSessionOwner, AudioStopCallback> _stoppers = {};

  /// Sistem kesintileri (gelen çağrı, bildirim sesi) için tek dinleyici.
  /// `ensureInterruptionListener` ilk `register` çağrısında devreye alınır;
  /// birden fazla controller kaydedilse bile tek subscription kullanılır.
  static StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  static AudioSessionOwner? _suspendedByInterruption;

  static Future<void> _ensureInterruptionListener() async {
    if (_interruptionSub != null) return;
    try {
      final session = await AudioSession.instance;
      _interruptionSub =
          session.interruptionEventStream.listen((event) async {
        if (event.begin) {
          // Telefon çağrısı, başka bir müzik uygulaması, alarm vb.
          // Aktif oynatıcıyı duraklat; kullanıcı geri döndüğünde resume
          // kararını kullanıcıya bırakıyoruz (aşağıda `shouldResume` varsa
          // yine de bizim owner-kaydı çok şey varsayıyor — güvenli tercih
          // resume etmemek). Ama `_suspendedByInterruption` bayrağını tutup
          // UI tarafı "kısa kesinti oldu" ipucunu verebilir.
          final owner = _active;
          if (owner == null) return;
          _suspendedByInterruption = owner;
          final stop = _stoppers[owner];
          if (stop == null) return;
          try {
            await stop();
          } catch (e, st) {
            if (kDebugMode) {
              debugPrint(
                'AudioSessionCoordinator.interruption pause $owner: $e\n$st',
              );
            }
          }
        } else {
          // Kesinti sona erdi. iOS `shouldResume` gelirse otomatik devam,
          // aksi halde kullanıcı elle açsın. Arın'ın ambient/frekans
          // kullanım profili için otomatik resume riskli (metroda araba
          // sesiyle açılması hoş değil) → sadece bayrağı temizliyoruz.
          _suspendedByInterruption = null;
        }
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AudioSessionCoordinator.listener init: $e\n$st');
      }
    }
  }

  /// Kısa kesinti son oldusa, UI "Ses kesildi, devam et?" göstermek isterse.
  static bool get wasSuspendedByInterruptionForDebug =>
      _suspendedByInterruption != null;

  /// Sahip olunabilmek için her notifier kendi pause callback'ini kaydetmeli.
  /// Notifier her zaman `unregister` çağırarak temizlenmeli — aksi halde
  /// kaybolan bir notifier'a `onPause` fırlatmaya çalışırız.
  static void register(AudioSessionOwner owner, AudioStopCallback onPause) {
    _stoppers[owner] = onPause;
    // İlk register'da sistem interruption (gelen arama, vb.) dinleyicisini
    // ayağa kaldır. fire-and-forget: hazır değilse ilk interruption cache'e
    // düşer, ikinci olaya dinleriz.
    unawaited(_ensureInterruptionListener());
  }

  static void unregister(AudioSessionOwner owner) {
    _stoppers.remove(owner);
    if (_active == owner) {
      _active = null;
    }
  }

  /// Lifecycle veya görünürlük kaybında belirli bir uzun ses sahibini sustur.
  ///
  /// Callback tarafı kendi state'ini günceller; burada sadece aktif sahip kaydı
  /// temizlenir ki gizli ekranda kalan player tekrar "aktif" sayılmasın.
  static Future<void> pauseOwner(AudioSessionOwner owner) async {
    final stop = _stoppers[owner];
    if (stop == null) {
      if (_active == owner) {
        _active = null;
      }
      return;
    }
    try {
      await stop();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AudioSessionCoordinator.pauseOwner: $owner error: $e\n$st');
      }
    } finally {
      if (_active == owner) {
        _active = null;
      }
    }
  }

  /// Aktif uzun ses sahibini sustur; aktif owner yoksa no-op.
  static Future<void> pauseActive() async {
    final owner = _active;
    if (owner == null) return;
    await pauseOwner(owner);
  }

  /// "Sahneyi al" — şu an başka bir sahibi varsa onun pause callback'i
  /// önce beklenir, sonra `_active` güncellenir. Hata sessizce yutulur
  /// (callback'in notifier'ında zaten try/catch var).
  static Future<void> claim(AudioSessionOwner owner) async {
    if (_active == owner) return;
    final previous = _active;
    _active = owner;
    if (previous == null || previous == owner) return;
    final stop = _stoppers[previous];
    if (stop == null) return;
    try {
      await stop();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AudioSessionCoordinator.claim: $previous pause error: $e\n$st');
      }
    }
  }

  /// Sahneyi bırak — başka hiçbir sahip aktif olmaz. Başka bir owner zaten
  /// sahne sahibiyse dokunmayız (yarış koruması).
  static void release(AudioSessionOwner owner) {
    if (_active == owner) {
      _active = null;
    }
  }

  /// Test / lifecycle debug amaçlı.
  @visibleForTesting
  static AudioSessionOwner? get activeOwnerForDebug => _active;

  @visibleForTesting
  static void resetForTests() {
    _active = null;
    _stoppers.clear();
  }
}
