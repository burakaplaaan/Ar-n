import 'package:arin/data/services/feature_permission_gate.dart';
import 'package:arin/data/services/startup_permission_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

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

  test('app tour pending defers colliding system prompts', () {
    expect(
      shouldDeferSystemPromptsForAppTour(
        tourPending: true,
        tourCompleted: false,
      ),
      isTrue,
    );
    expect(
      shouldDeferSystemPromptsForAppTour(
        tourPending: false,
        tourCompleted: false,
      ),
      isFalse,
    );
    expect(
      shouldDeferSystemPromptsForAppTour(
        tourPending: true,
        tourCompleted: true,
      ),
      isFalse,
    );
  });

  test('FCM auto-prompt stays off so spotlight and feature screens own the ask', () {
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
      isFalse,
    );
    expect(
      shouldAutoRequestBroadcastPermission(
        onboardingCompleted: true,
        promptAlreadyHandled: true,
      ),
      isFalse,
    );
    expect(
      shouldAutoRequestBroadcastPermission(
        onboardingCompleted: true,
        promptAlreadyHandled: false,
        appTourBlockingPrompts: true,
      ),
      isFalse,
    );
  });

  test('granted location is not asked again', () {
    expect(locationPermissionGranted(LocationPermission.always), isTrue);
    expect(locationPermissionGranted(LocationPermission.whileInUse), isTrue);
    expect(locationPermissionGranted(LocationPermission.denied), isFalse);
    expect(locationPermissionGranted(LocationPermission.deniedForever), isFalse);
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
