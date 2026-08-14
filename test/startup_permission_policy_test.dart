import 'package:arin/data/services/startup_permission_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('location disclosure is shown only once per session', () {
    expect(
      shouldShowLocationDisclosure(
        permissionDenied: true,
        promptIfNeeded: true,
        sessionDeclined: false,
      ),
      isTrue,
    );
    expect(
      shouldShowLocationDisclosure(
        permissionDenied: true,
        promptIfNeeded: true,
        sessionDeclined: true,
      ),
      isFalse,
    );
    expect(
      shouldShowLocationDisclosure(
        permissionDenied: true,
        promptIfNeeded: false,
        sessionDeclined: false,
      ),
      isFalse,
    );
    expect(
      shouldShowLocationDisclosure(
        permissionDenied: false,
        promptIfNeeded: true,
        sessionDeclined: false,
      ),
      isFalse,
    );
  });

  test('FCM auto-prompt waits for onboarding and respects skip', () {
    expect(
      shouldAutoRequestBroadcastPermission(
        onboardingCompleted: false,
        promptAlreadyHandled: false,
      ),
      isFalse,
    );
    expect(
      shouldAutoRequestBroadcastPermission(
        onboardingCompleted: true,
        promptAlreadyHandled: false,
      ),
      isTrue,
    );
    expect(
      shouldAutoRequestBroadcastPermission(
        onboardingCompleted: true,
        promptAlreadyHandled: true,
      ),
      isFalse,
    );
  });

  test('resume does not wipe healthy same-day prayer times', () {
    final now = DateTime(2026, 8, 14, 23, 50);
    expect(
      shouldInvalidatePrayerTimesOnResume(
        isLoading: false,
        hasError: false,
        hasData: true,
        cachedDateIso: '2026-08-14',
        now: now,
      ),
      isFalse,
    );
    expect(
      shouldInvalidatePrayerTimesOnResume(
        isLoading: false,
        hasError: true,
        hasData: false,
        cachedDateIso: '2026-08-14',
        now: now,
      ),
      isTrue,
    );
    expect(
      shouldInvalidatePrayerTimesOnResume(
        isLoading: false,
        hasError: false,
        hasData: true,
        cachedDateIso: '2026-08-13',
        now: now,
      ),
      isTrue,
    );
    expect(
      shouldInvalidatePrayerTimesOnResume(
        isLoading: true,
        hasError: false,
        hasData: false,
        cachedDateIso: null,
        now: now,
      ),
      isFalse,
    );
  });
}
