/// Shell sekmesinde [TickerMode] açık mı?
///
/// Görünür sekme ve kaydırma komşusu (±1) açık kalır; swipe sırasında
/// gelen sekme donmaz. Daha uzaktaki keep-alive sekmeler durur.
bool shellTabTickersEnabled({
  required int index,
  required int currentIndex,
}) {
  return (index - currentIndex).abs() <= 1;
}
