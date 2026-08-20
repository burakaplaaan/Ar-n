import 'package:arin/data/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isAuthProviderLinked', () {
    test('oturum yokken Google bağlı sayılmaz', () {
      expect(isAuthProviderLinked(const <String>[], 'google.com'), isFalse);
    });

    test('yalnızca yerel/custom oturumda Google yoktur', () {
      expect(
        isAuthProviderLinked(const ['firebase'], 'google.com'),
        isFalse,
      );
    });

    test('Google bağlıysa tekrar teklif edilmez', () {
      expect(
        isAuthProviderLinked(const ['google.com'], 'google.com'),
        isTrue,
      );
    });

    test('Apple bağlı olsa bile Google ayrı kalır', () {
      expect(
        isAuthProviderLinked(const ['apple.com'], 'google.com'),
        isFalse,
      );
    });
  });

  group('resolveAuthConnect', () {
    test('oturum yoksa giriş yapar', () {
      expect(
        resolveAuthConnect(
          hasCurrentUser: false,
          currentProviderIds: const <String>[],
          incomingProviderId: 'google.com',
        ),
        AuthConnectResolution.signIn,
      );
    });

    test('leftover custom/firebase oturumuna Google bağlar', () {
      expect(
        resolveAuthConnect(
          hasCurrentUser: true,
          currentProviderIds: const ['firebase'],
          incomingProviderId: 'google.com',
        ),
        AuthConnectResolution.link,
      );
    });

    test('leftover oturumda çakışınca mevcut UID yerine girişe düşer', () {
      expect(
        resolveAuthConnect(
          hasCurrentUser: true,
          currentProviderIds: const ['firebase'],
          incomingProviderId: 'google.com',
          linkCollision: true,
        ),
        AuthConnectResolution.signIn,
      );
    });

    test('Apple oturumuna Google bağlar', () {
      expect(
        resolveAuthConnect(
          hasCurrentUser: true,
          currentProviderIds: const ['apple.com'],
          incomingProviderId: 'google.com',
        ),
        AuthConnectResolution.link,
      );
    });

    test('Apple oturumunda Google çakışınca hesabı değiştirmez', () {
      expect(
        resolveAuthConnect(
          hasCurrentUser: true,
          currentProviderIds: const ['apple.com'],
          incomingProviderId: 'google.com',
          linkCollision: true,
        ),
        AuthConnectResolution.failClosed,
      );
    });

    test('aynı sağlayıcı zaten bağlıysa girişe düşer', () {
      expect(
        resolveAuthConnect(
          hasCurrentUser: true,
          currentProviderIds: const ['google.com'],
          incomingProviderId: 'google.com',
        ),
        AuthConnectResolution.signIn,
      );
    });

    test('Google oturumunda Apple çakışınca hesabı değiştirmez', () {
      expect(
        resolveAuthConnect(
          hasCurrentUser: true,
          currentProviderIds: const ['google.com'],
          incomingProviderId: 'apple.com',
          linkCollision: true,
        ),
        AuthConnectResolution.failClosed,
      );
    });
  });
}
