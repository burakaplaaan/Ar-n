import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumEntitlement {
  const PremiumEntitlement({
    required this.active,
    this.source,
    this.productId,
    this.platform,
    this.expiresAt,
    this.updatedAt,
  });

  final bool active;
  final String? source;
  final String? productId;
  final String? platform;
  final DateTime? expiresAt;
  final DateTime? updatedAt;

  bool get isActive {
    if (!active) return false;
    final expiry = expiresAt;
    if (expiry == null) return true;
    return expiry.isAfter(DateTime.now());
  }

  static const PremiumEntitlement inactive = PremiumEntitlement(active: false);

  factory PremiumEntitlement.fromMap(Map<String, dynamic>? data) {
    if (data == null) return inactive;
    return PremiumEntitlement(
      active: data['active'] == true,
      source: data['source']?.toString(),
      productId: data['productId']?.toString(),
      platform: data['platform']?.toString(),
      expiresAt: _date(data['expiresAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
