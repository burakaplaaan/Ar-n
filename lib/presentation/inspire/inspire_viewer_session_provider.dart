import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inspiration_search.dart';

/// `go_router` bazen [extra] taşıyamaz; Reels destesi burada yedeklenir.
/// Keşfet / Kaydedilenler açılışında push öncesi atanır; [InspireViewerPage] dispose’da temizlenir.
final inspireViewerDeckSessionProvider = StateProvider<InspireViewerDeckExtra?>(
  (ref) => null,
);

/// Shell sistem-geri’si viewer’ı anında pop etmesin; shrink animasyonu buradan tetiklenir.
final inspireViewerCloseRequestProvider = StateProvider<int>((ref) => 0);
