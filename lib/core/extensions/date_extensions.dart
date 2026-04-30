// lib/core/extensions/date_extensions.dart
// DateTime sınıfına eklenen yardımcı uzantılar.

extension DateExtensions on DateTime {
  /// Sadece tarih bölümünü (saat olmadan) döndürür.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Bugün mü kontrolü
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Dün mü kontrolü
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Bu haftada mı kontrolü (Pazartesi başlangıçlı)
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// İki tarihin aynı gün olup olmadığını kontrol eder
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Türkçe kısa ay adı
  String get shortMonthTr {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return months[month - 1];
  }

  /// Türkçe tam ay adı
  String get fullMonthTr {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return months[month - 1];
  }

  /// Türkçe gün adı (kısa)
  String get shortDayTr {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday - 1];
  }

  /// "dd MMM yyyy" formatında Türkçe tarih
  String get displayDateTr => '$day $shortMonthTr $year';
}

extension DurationExtensions on Duration {
  /// "SS:DD:SS" formatında geri sayım metni üretir
  String get countdownText {
    final h = inHours;
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$m:$s';
    return '$m:$s';
  }
}
