import 'package:hijri/hijri_calendar.dart';

/// Paylaşım teşviki: Cuma / kandil geceleri / bayram — öncelik: bayram > kandil > cuma.
String? exploreOccasionMessage(DateTime localNow) {
  final h = HijriCalendar.fromDate(localNow);
  final month = h.hMonth;
  final day = h.hDay;

  if (_isRamazanBayrami(month, day) || _isKurbanBayrami(month, day)) {
    return 'Hayırlı Bayramlar';
  }
  if (_isKandilApprox(month, day)) {
    return 'Hayırlı Kandiller';
  }
  if (localNow.weekday == DateTime.friday) {
    return 'Hayırlı Cumalar';
  }
  return null;
}

/// Şevval başı — Ramazan Bayramı (genellikle 1–3 gün).
bool _isRamazanBayrami(int hMonth, int hDay) {
  return hMonth == 10 && hDay >= 1 && hDay <= 3;
}

/// Zilhicce — Kurban Bayramı arefesi ve bayram günleri (yaklaşık).
bool _isKurbanBayrami(int hMonth, int hDay) {
  return hMonth == 12 && hDay >= 10 && hDay <= 13;
}

/// Türkiye’de kutlanan kandil gecelerine yaklaşık takvim (hicri gün/ay).
bool _isKandilApprox(int hMonth, int hDay) {
  // Mevlid (Rabiülevvel 12)
  if (hMonth == 3 && hDay == 12) return true;
  // İsra / Miraç (Recep 27)
  if (hMonth == 7 && hDay == 27) return true;
  // Berat (Şaban 15)
  if (hMonth == 8 && hDay == 15) return true;
  // Kadir gecesi (Ramazan 27)
  if (hMonth == 9 && hDay == 27) return true;
  // Regaib — ilk cuma gecesi değişir; Recep ayı içi ilk hafta kabaca işaret.
  if (hMonth == 7 && hDay >= 1 && hDay <= 7) return true;
  return false;
}
