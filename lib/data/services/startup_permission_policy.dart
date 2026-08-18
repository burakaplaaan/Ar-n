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

/// İlk-kurulum tanıtımı bitene kadar sistem izin kutuları spotlight ile
/// çakışmasın. Mevcut kurulumlarda pending yoksa erteleme yok.
const String kAppTourPendingKey = 'app_tour_pending';
const String kAppTourCompletedKey = 'app_tour_completed';

bool shouldDeferSystemPromptsForAppTour({
  required bool tourPending,
  required bool tourCompleted,
}) {
  return tourPending && !tourCompleted;
}

/// FCM sistem diyaloğu açılışta veya tanıtım sonrası otomatik açılmamalı.
/// İzin ritim ekranında veya ayet bildirimi açılırken istenir.
bool shouldAutoRequestBroadcastPermission({
  required bool onboardingCompleted,
  required bool promptAlreadyHandled,
  bool appTourBlockingPrompts = false,
}) {
  if (!onboardingCompleted ||
      promptAlreadyHandled ||
      appTourBlockingPrompts) {
    return false;
  }
  return false;
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
