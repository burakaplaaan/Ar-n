import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../models/premium_entitlement.dart';
import '../services/purchase_service.dart';

class PremiumEntitlementRepository {
  PremiumEntitlementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<PremiumEntitlement> loadForCurrentUser() async {
    if (!isFirebaseReady) return PremiumEntitlement.inactive;
    final user = _auth.currentUser;
    if (user == null) return PremiumEntitlement.inactive;
    final uid = user.uid;

    final direct = await _loadDocument('premium_entitlements', uid);
    if (direct.isActive) return direct;

    final email = _emailOf(user);
    if (email == null) {
      final localEntitlement = await PurchaseService().getLocalPremiumEntitlement(
        expectedFirebaseUid: uid,
      );
      return (localEntitlement != null && localEntitlement.isActive)
          ? localEntitlement
          : direct;
    }
    final invite = await _loadDocument('premium_invites', email);
    if (invite.isActive) return invite;

    // Webhook gecikmesi / geçici Firestore erişim sorunlarında, cihazdaki güncel
    // RevenueCat sonucu premium false-negative'i önler.
    var localEntitlement = await PurchaseService().getLocalPremiumEntitlement(
      expectedFirebaseUid: uid,
    );
    if (localEntitlement == null) {
      // Bazı cihazlarda auth restore sonrası RC login yarışına düşebiliyor.
      // Eşleşme yapılamadıysa bir kez login deneyip local entitlement'ı tekrar oku.
      try {
        await PurchaseService.loginUser(uid);
        localEntitlement = await PurchaseService().getLocalPremiumEntitlement(
          expectedFirebaseUid: uid,
        );
      } catch (e) {
        debugPrint('PremiumEntitlementRepository: rc relogin fallback failed: $e');
      }
    }
    if (localEntitlement != null && localEntitlement.isActive) {
      return localEntitlement;
    }
    return direct;
  }

  Future<PremiumEntitlement> _loadDocument(
    String collection,
    String id,
  ) async {
    try {
      final snap = await _firestore.collection(collection).doc(id).get(
            const GetOptions(source: Source.server),
          );
      return PremiumEntitlement.fromMap(
        snap.data(),
      );
    } catch (e) {
      debugPrint('PremiumEntitlementRepository: load failed: $e');
      return PremiumEntitlement.inactive;
    }
  }

  String? _emailOf(User user) {
    final direct = user.email?.trim().toLowerCase();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final info in user.providerData) {
      final email = info.email?.trim().toLowerCase();
      if (email != null && email.isNotEmpty) return email;
    }
    return null;
  }
}
