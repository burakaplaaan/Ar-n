import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Arınma akışından çıkınca irade köküne (`/habits`) dönüşte Arınma sekmesini seçmek için.
final willpowerHubReturnToArinmaProvider = StateProvider<bool>((ref) => false);
