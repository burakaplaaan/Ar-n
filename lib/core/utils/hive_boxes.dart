// lib/core/utils/hive_boxes.dart
// Tüm Hive box isimlerinin merkezi sabiti.
// Box açma/kapama işlemlerinde bu sabitler kullanılmalıdır.

abstract final class HiveBoxes {
  /// Kullanıcı profili ve anket cevapları
  static const String userProfile = 'arin_user_profile';

  /// Alışkanlık tanımları
  static const String habits = 'arin_habits';

  /// Alışkanlık günlük tamamlama kayıtları
  static const String habitLogs = 'arin_habit_logs';

  /// Eski Günlük (Journal) kutusunun adı. Özellik tamamen kaldırıldı;
  /// eski kurulumlarda disk'te kalmış olabilecek kutunun tek sefer
  /// silinmesi için `main.dart` içindeki migration tarafından kullanılır.
  static const String legacyJournalEntries = 'arin_journal_entries';

  /// Namaz vakitleri önbelleği (günlük)
  static const String prayerTimesCache = 'arin_prayer_cache';

  /// Genel uygulama tercihleri
  static const String preferences = 'arin_preferences';

  /// Günlük 5 vakit tik durumu (String: "10101")
  static const String salatLogs = 'arin_salat_logs';

  /// Firestore'dan günde bir kez çekilen söz paketi (JSON string)
  static const String quotesCache = 'arin_quotes_cache';
}

/// Hive type ID'leri — çakışma olmaması için merkezi yönetim
abstract final class HiveTypeIds {
  static const int userProfile = 0;
  static const int habit = 1;
  static const int habitLog = 2;
  // 3 → eski journalEntry tipi (özellik kaldırıldı). ID rezerve; tekrar
  // kullanılmamalı — aksi halde eski cihazlardaki kutu (henüz
  // temizlenmemişse) yanlış adapter ile deserialize edilebilir.
  static const int prayerTimesCache = 4;
  static const int habitType = 10; // enum adapter
}
