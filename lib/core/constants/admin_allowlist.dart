// lib/core/constants/admin_allowlist.dart
// Admin yetki — hibrit:
//   1) E-posta, [kLegacyAdminEmails] içindeyse anında admin (ağ/Console gerekmez).
//   2) Aksi halde Firestore `admin_users/{uid}` dokümanı.
//
// Apple "Hide My Email" vb. e-posta gelmeyen hesaplarda sadece (2) geçerli
// — Console'da `admin_users/{uid}` aç.
//
// Uzun vadede yalnız `admin_users` kullanmak istersen e-posta listesini
// boş bırak veya kaldır; Firestore kuralları aynı hibriti kullanmalı.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_bootstrap.dart';

enum AdminRole {
  none,
  content,
  manager,
  developer;

  bool get isAdmin => this == content || this == manager || this == developer;
  bool get canEditContent => isAdmin;
  bool get canUseDiagnostics => this == manager || this == developer;
  bool get canSeedMissingPools => this == manager || this == developer;
  bool get canResetAllPools => this == developer;
  bool get canUseDeveloperTools => this == developer;
  bool get canManageAdmins => this == developer;

  String get labelTr {
    switch (this) {
      case AdminRole.none:
        return 'Yetkisiz';
      case AdminRole.content:
        return 'İçerik';
      case AdminRole.manager:
        return 'Yönetici';
      case AdminRole.developer:
        return 'Tam yetkili';
    }
  }

  static AdminRole fromWire(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return AdminRole.content;
    }
    switch (normalized) {
      case 'developer':
      case 'dev':
      case 'owner':
      case 'superadmin':
        return AdminRole.developer;
      case 'content':
      case 'editor':
      case 'content_editor':
        return AdminRole.content;
      case 'manager':
      case 'operation':
      case 'operator':
      case 'ops':
        return AdminRole.manager;
      case 'none':
      case 'disabled':
      case 'revoked':
        return AdminRole.none;
      default:
        return AdminRole.none;
    }
  }
}

abstract final class AdminAllowlist {
  /// Tam yetkili ekip e-postaları (küçük harf).
  ///
  /// Bu hesaplar içerik paneli + geliştirici araçlarının tamamını kullanır.
  /// Firestore `admin_users` dokümanı eksik/bozuk olsa bile uygulama içi tam
  /// yetki verir; Firestore kuralları da aynı listeyle senkron tutulmalıdır.
  static const Set<String> kFullAccessAdminEmails = {
    'burakmelihkuzi@gmail.com',
    'brkkpl5@gmail.com',
    'seyirteknikerr@gmail.com',
  };

  /// Eski isimle kullanan kod/yorumlar için geriye uyum.
  static const Set<String> kLegacyAdminEmails = kFullAccessAdminEmails;

  /// UID başına rol belleği. Uygulama ömrü boyunca korunur;
  /// kullanıcı çıkış yapıp tekrar girdiğinde yeni UID ile yeniden sorgulanır.
  static final Map<String, AdminRole> _cache = {};

  /// Asenkron admin kontrolü.
  ///
  /// Sıra: (1) e-posta eşleşmesi → (2) Firestore `admin_users/{uid}`.
  /// - Oturum yoksa → `false`
  /// - Firebase başlatılmadıysa → `false`
  /// - (2) ağ hatası → e-posta yolu eşleşmediyse `false`
  static Future<bool> isAdminUser(User? user) async {
    return (await adminRoleFor(user)).isAdmin;
  }

  static Future<AdminRole> adminRoleFor(User? user) async {
    if (user == null) return AdminRole.none;
    if (!isFirebaseReady) return AdminRole.none;
    final uid = user.uid;
    final em = _emailOf(user);
    if (em != null && kFullAccessAdminEmails.contains(em)) {
      _cache[uid] = AdminRole.developer;
      return AdminRole.developer;
    }

    final cached = _cache[uid];
    if (cached != null) return cached;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (snap.exists) {
        final role = AdminRole.fromWire(snap.data()?['role']?.toString());
        _cache[uid] = role;
        return role;
      }

      if (em != null) {
        final inviteSnap = await FirebaseFirestore.instance
            .collection('admin_invites')
            .doc(em)
            .get(const GetOptions(source: Source.server));
        if (inviteSnap.exists) {
          final role = AdminRole.fromWire(
            inviteSnap.data()?['role']?.toString(),
          );
          _cache[uid] = role;
          return role;
        }
      }

      _cache[uid] = AdminRole.none;
      return AdminRole.none;
    } catch (e) {
      // Ağ kapalı / kural reddi. E-posta eşleşmediyse false.
      debugPrint('AdminAllowlist: isAdminUser check failed: $e');
      return AdminRole.none;
    }
  }

  static String? _emailOf(User user) {
    final direct = user.email?.trim().toLowerCase();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final info in user.providerData) {
      final email = info.email?.trim().toLowerCase();
      if (email != null && email.isNotEmpty) return email;
    }
    return null;
  }

  /// Çıkış sonrası çağrılır — cache temizlenir.
  static void invalidateCache() {
    _cache.clear();
  }
}
