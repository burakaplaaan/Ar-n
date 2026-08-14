// Açılış izin / namaz yenileme kararları — UI ve servislerden bağımsız,
// test edilebilir kurallar.

/// Konum açıklama diyaloğu yalnız izin henüz verilmediyse, bu oturumda
/// reddedilmediyse ve çağıran gerçekten sormak istiyorsa gösterilir.
bool shouldShowLocationDisclosure({
  required bool permissionDenied,
  required bool promptIfNeeded,
  required bool sessionDeclined,
}) {
  return promptIfNeeded && permissionDenied && !sessionDeclined;
}

/// FCM sistem diyaloğu onboarding bitmeden açılmamalı; aksi halde
/// anket adımıyla üst üste biner.
bool shouldAutoRequestBroadcastPermission({
  required bool onboardingCompleted,
  required bool promptAlreadyHandled,
}) {
  return onboardingCompleted && !promptAlreadyHandled;
}

String calendarDateIso(DateTime now) {
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '${now.year}-$m-$d';
}

/// Resume'da her seferinde provider'ı silmek, Android GPS/ağ yarışında
/// "Vakitler yüklenemedi" üretir. Yalnız hata veya gün değişince yenile.
bool shouldInvalidatePrayerTimesOnResume({
  required bool isLoading,
  required bool hasError,
  required bool hasData,
  required String? cachedDateIso,
  required DateTime now,
}) {
  if (isLoading) return false;
  if (hasError) return true;
  if (!hasData) return true;
  final cached = cachedDateIso?.trim() ?? '';
  if (cached.isEmpty) return false;
  return cached != calendarDateIso(now);
}
