// lib/data/models/purchase_result.dart
//
// Satın alma işleminin sonucunu tipli olarak taşır.
// UI bu tip üzerinden switch yaparak dialog/snackbar gösterir.

sealed class PurchaseOutcome {
  const PurchaseOutcome();

  /// Satın alma başarıyla tamamlandı, entitlement aktif.
  const factory PurchaseOutcome.success() = _Success;

  /// Kullanıcı ödeme ekranını kapattı — hata mesajı gösterme.
  const factory PurchaseOutcome.cancelled() = _Cancelled;

  /// Geri yükleme yapıldı ama aktif abonelik bulunamadı.
  const factory PurchaseOutcome.notFound() = _NotFound;

  /// Teknik hata — [message] kullanıcıya gösterilebilir.
  const factory PurchaseOutcome.error(String message) = _Error;
}

final class _Success extends PurchaseOutcome {
  const _Success();
}

final class _Cancelled extends PurchaseOutcome {
  const _Cancelled();
}

final class _NotFound extends PurchaseOutcome {
  const _NotFound();
}

final class _Error extends PurchaseOutcome {
  const _Error(this.message);
  final String message;
}

// ─── Extension helpers ───────────────────────────────────────────────────────

extension PurchaseOutcomeX on PurchaseOutcome {
  bool get isSuccess => this is _Success;
  bool get isCancelled => this is _Cancelled;

  /// Kullanıcıya gösterilecek mesaj (null = sessiz kal).
  String? get userMessage => switch (this) {
        _Success() => null,
        _Cancelled() => null,
        _NotFound() => 'Aktif abonelik bulunamadı.',
        _Error(:final message) => message,
      };
}
