/// Platform [MethodChannel] / eklenti zamanlama kaynaklı `LateInitializationError` tespiti.
/// Ham İngilizce stack kullanıcıya gösterilmez.
bool isMethodChannelLateInitResultError(Object e) {
  if (e.runtimeType.toString() != 'LateInitializationError') {
    return false;
  }
  final s = e.toString();
  return s.contains("Local 'result'") || s.contains('Local \'result\'');
}

/// Kullanıcıya gösterilecek kısa Türkçe mesaj (tek tip).
String platformShareTransientErrorMessage() =>
    'Paylaşım şu an tamamlanamadı. Bir kez daha deneyin.';
