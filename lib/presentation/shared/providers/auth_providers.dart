// lib/presentation/shared/providers/auth_providers.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/admin_allowlist.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Firebase yoksa veya hazır değilse [AsyncData(null)].
final authUserProvider = StreamProvider<User?>((ref) {
  if (!isFirebaseReady) {
    return Stream<User?>.value(null);
  }
  return ref.read(authServiceProvider).authStateChanges;
});

/// "Bu kullanıcı admin mi?" — Firestore `/admin_users/{uid}` varlığına
/// bakar. Oturum kapalıysa veya Firebase hazır değilse `false`.
///
/// Auth durumu değiştikçe otomatik yeniden hesaplanır. Sonuç
/// `AdminAllowlist._cache` içinde UID başına cache'lenir, böylece
/// birden fazla dinleyici aynı Firestore okumasına neden olmaz.
final isCurrentUserAdminProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(currentAdminRoleProvider.future);
  return role.isAdmin;
});

final currentAdminRoleProvider = FutureProvider<AdminRole>((ref) async {
  final authAsync = ref.watch(authUserProvider);
  final user = authAsync.asData?.value;
  if (user == null) {
    AdminAllowlist.invalidateCache();
    return AdminRole.none;
  }
  return AdminAllowlist.adminRoleFor(user);
});
