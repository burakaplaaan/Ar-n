import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kıble hub’da araç kökü (`/`) dışında bir ekran açıkken ana shell [PageView]
/// yatay kaydırması kapalı olur (zikirmatik / pusula iken yan sekme kayması olmaz).
final qiblaHubBlocksShellSwipeProvider = StateProvider<bool>((ref) => false);

/// Nested Bilgi Düellosu açıkken asistan FAB gizlenir. NavigatorObserver yazar;
/// initState içinde yazılmaz (build sırasında provider hatası).
final hilalDuelActiveProvider = StateProvider<bool>((ref) => false);
