// lib/presentation/shared/providers/prayer_time_providers.dart
// Riverpod provider'ları — Namaz vakitleri ve geri sayım.
//
// Veri kaynağı: `PrayerServiceResolver` kararı (TR → Diyanet, aksi halde
// Aladhan). Bu katman eskiden doğrudan `AladhanService`'i çağırıyordu;
// artık resolver'ı çağırıyor, consumer'lar (UI + scheduler) değişmez.

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/services/admin_dev_prefs.dart';
import '../../../data/services/aladhan_service.dart';
import '../../../data/services/prayer_service_resolver.dart';

final aladhanServiceProvider = Provider<AladhanService>(
  (_) => AladhanService(),
);

/// Kaynak seçimi ve offline fallback `PrayerServiceResolver`'da yapılır.
/// Admin test kaydırması [AdminDevPrefs] ile uygulanır (API yanıtı değişmez).
final prayerTimesProvider = FutureProvider<PrayerTimesModel>((ref) async {
  final resolver = ref.read(prayerServiceResolverProvider);
  
  resolver.onCacheInvalidated = () {
    ref.invalidateSelf();
  };

  final prefs = ref.read(sharedPreferencesProvider);

  var result = await resolver.fetchToday();
  if (result.model == null) {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    result = await resolver.fetchToday();
  }
  final raw = result.model;
  if (raw == null) {
    throw Exception(
      'Namaz vakitleri alınamadı (kaynak: ${result.source.name})',
    );
  }
  return AdminDevPrefs.applyPrayerOffset(prefs, raw);
});

/// Son fetch'in hangi kaynaktan geldiğini UI'da göstermek için.
final lastPrayerSourceProvider = StateProvider<PrayerSource>((_) {
  return PrayerSource.unavailable;
});

/// Sıradaki namaz vakti geri sayımı — her saniye güncellenir.
///
/// Lifecycle-aware: uygulama arka plana alındığında (`paused` / `hidden` /
/// `detached`) timer durdurulur; kullanıcı geri döndüğünde (`resumed`)
/// tekrar başlatılır. Aksi halde her saniye `setState` çağrısı Doze dışında
/// cihazı sessizce uyandırır ve pil tüketimi olarak gözlemlenir. UI tarafında
/// tek değişiklik: resume anında anlık güncel değer görülür (zaten
/// `ArinApp.didChangeAppLifecycleState` `prayerTimesProvider`'ı invalidate
/// ediyor → _update yeniden çağrıldığında en güncel kalan süreye oturur).
///
/// `inactive` state'inde (iOS'ta notification center, control center, app
/// switcher kısa süreli) timer durdurulmaz; aksi halde kullanıcı uygulamaya
/// dönünce 1 sn donukluk yaşardı.
class CountdownNotifier extends StateNotifier<Duration>
    with WidgetsBindingObserver {
  Timer? _timer;
  final Ref _ref;
  bool _disposed = false;

  CountdownNotifier(this._ref) : super(Duration.zero) {
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _update();
    });
    _update();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _update() {
    try {
      final prayerAsync = _ref.read(prayerTimesProvider);
      prayerAsync.whenData((pt) {
        final next = pt.nextPrayer(DateTime.now());
        if (next != null) state = next.remaining;
      });
    } catch (_) {
      // Emülatör / ağ / provider yarışı: geri sayımı sessizce atla
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _startTimer();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _stopTimer();
      case AppLifecycleState.inactive:
        // Geçici — timer açık kalsın.
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final countdownProvider = StateNotifierProvider<CountdownNotifier, Duration>(
  (ref) => CountdownNotifier(ref),
);

/// Sıradaki namaz adı — [countdownProvider] ile birlikte her saniye yenilenir;
/// aksi halde vakit geçince isim eski kalıp geri sayımla çelişebilirdi.
final nextPrayerNameProvider = Provider<String>((ref) {
  ref.watch(countdownProvider);
  final prayerAsync = ref.watch(prayerTimesProvider);
  return prayerAsync.when(
    data: (pt) => pt.nextPrayer(DateTime.now())?.name ?? '—',
    loading: () => '...',
    error: (_, __) => '—',
  );
});

/// İmsak vakti girmiş olup henüz güneş doğmadıysa true döner. Home sayfası
/// namaz sayacını kırmızı vurguyla gösterip kullanıcıyı ikaz eder — yoksa
/// sabah namazı kolayca kaçırılır.
final nextPrayerUrgentFajrProvider = Provider<bool>((ref) {
  ref.watch(countdownProvider);
  final prayerAsync = ref.watch(prayerTimesProvider);
  return prayerAsync.when(
    data: (pt) => pt.nextPrayer(DateTime.now())?.isUrgentFajr ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});
