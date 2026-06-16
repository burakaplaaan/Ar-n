//
//  ARIN — söz, namaz ve karma widget. Veri: App Group UserDefaults (home_widget / Flutter).
//  Kilit ekranı: accessoryRectangular — iOS önizlemesine yakın kompakt düzen.
//

import SwiftUI
import WidgetKit

private let kGroupId = "group.com.arin.arin"
private let kQuoteTimelineFutureLimit = 28
private let kPrayerTimelineFutureLimit = 36

private func suite() -> UserDefaults? {
  UserDefaults(suiteName: kGroupId)
}

private func storedWidgetLocaleCode() -> String {
  let raw = suite()?.string(forKey: "arin_widget_locale")?
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .lowercased() ?? ""
  return raw
}

private func localizedWidgetText(tr: String) -> String {
  tr
}

private func containsArabic(_ text: String) -> Bool {
  text.range(of: #"\p{Script=Arabic}"#, options: .regularExpression) != nil
}

private func sanitizeCountdown(_ raw: String) -> String {
  let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
  if t.isEmpty || t == "—" { return t }
  let cleaned = t.hasPrefix("-") ? String(t.dropFirst()) : t
  let pattern = #"^\d+:\d{2}:\d{2}$"#
  if cleaned.range(of: pattern, options: .regularExpression) != nil {
    return cleaned
  }
  return "0:00:00"
}

private func turkishPrayerName(_ raw: String) -> String {
  let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmed.isEmpty { return "İmsak" }
  if containsArabic(trimmed) { return "İmsak" }
  switch trimmed.lowercased() {
  case "fajr": return "İmsak"
  case "sunrise": return "Güneş"
  case "dhuhr": return "Öğle"
  case "asr": return "İkindi"
  case "maghrib": return "Akşam"
  case "isha": return "Yatsı"
  case "imsak": return "İmsak"
  case "güneş": return "Güneş"
  case "öğle": return "Öğle"
  case "ikindi": return "İkindi"
  case "akşam": return "Akşam"
  case "yatsı": return "Yatsı"
  default: return "Vakit"
  }
}

/// Uygulama veri yazmadan önce widget önizlemesi / deneme (Android strings ile uyumlu).
private enum QuoteWidgetDefaults {
  static var source: String {
    localizedWidgetText(tr: "Tâhâ, 46")
  }
  static var text: String {
    localizedWidgetText(tr: "İşitirim ve görürüm.")
  }
}

private enum PrayerWidgetDefaults {
  static var location: String {
    localizedWidgetText(tr: "Konum ayarlanmadı")
  }
}

private struct QuoteSchedulePayload: Decodable {
  let entries: [QuoteScheduleItem]
}

private struct QuoteScheduleItem: Decodable {
  let epochMs: Double
  let text: String
  let source: String

  var date: Date {
    Date(timeIntervalSince1970: epochMs / 1000.0)
  }
}

private struct PrayerSchedulePayload: Decodable {
  let location: String?
  let entries: [PrayerScheduleItem]
}

private struct PrayerScheduleItem: Decodable {
  let epochMs: Double
  let name: String

  var date: Date {
    Date(timeIntervalSince1970: epochMs / 1000.0)
  }
}

private func decodeWidgetJson<T: Decodable>(_ key: String, as type: T.Type) -> T? {
  guard let raw = suite()?.string(forKey: key),
        !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        let data = raw.data(using: .utf8) else {
    return nil
  }
  return try? JSONDecoder().decode(T.self, from: data)
}

/// Trial süresi (24 saat). Bu sabit `AdGateService.widgetTrialDuration` ile
/// aynı tutulmalıdır; her iki taraf da aynı first-use zamanından itibaren
/// aynı sona ulaşsın diye senkron.
private let kWidgetTrialDurationMs: Double = 24 * 60 * 60 * 1000.0

/// Bir widget'ın home ekranda ilk render'ı yapıldığında, ilgili kind için
/// "kullanım başlangıcı" zaman damgasını App Group UserDefaults'a yazar.
/// Aynı kind için tekrar çağrı no-op'tur (idempotent). Bu, her widget'ın
/// trial sayacını yalnızca o widget kullanıma alındığında başlatır;
/// kullanılmayan widget'lar trial'a girmez.
private func recordWidgetFirstUse(_ kind: String) {
  let u = suite()
  let key = "arin_widget_first_use_ms_\(kind)"
  let existing = Double(u?.string(forKey: key) ?? "") ?? 0
  if existing > 0 { return }
  let nowMs = Date().timeIntervalSince1970 * 1000.0
  u?.set(String(nowMs), forKey: key)
}

private func widgetFirstUseMs(_ kind: String) -> Double {
  let u = suite()
  return Double(u?.string(forKey: "arin_widget_first_use_ms_\(kind)") ?? "") ?? 0
}

private func widgetLocked(_ kind: String) -> Bool {
  let u = suite()
  if u?.string(forKey: "arin_widget_gate_premium") == "1" { return false }
  let nowMs = Date().timeIntervalSince1970 * 1000.0
  let unlockUntilMs = Double(u?.string(forKey: "arin_widget_gate_\(kind)_unlock_until_ms") ?? "") ?? 0
  if unlockUntilMs > nowMs { return false }
  if u?.string(forKey: "arin_widget_gate_\(kind)_locked") == "1" { return true }
  let firstUseMs = widgetFirstUseMs(kind)
  if firstUseMs <= 0 { return false }
  let trialEndMs = firstUseMs + kWidgetTrialDurationMs
  return nowMs >= trialEndMs
}

private func widgetGateRefreshDate(_ kind: String) -> Date? {
  let u = suite()
  if u?.string(forKey: "arin_widget_gate_premium") == "1" { return nil }
  let nowMs = Date().timeIntervalSince1970 * 1000.0
  let firstUseMs = widgetFirstUseMs(kind)
  let trialEndMs = firstUseMs > 0 ? firstUseMs + kWidgetTrialDurationMs : 0
  let unlockUntilMs = Double(u?.string(forKey: "arin_widget_gate_\(kind)_unlock_until_ms") ?? "") ?? 0
  let next = [trialEndMs, unlockUntilMs].filter { $0 > nowMs }.min()
  guard let next else { return nil }
  return Date(timeIntervalSince1970: next / 1000.0).addingTimeInterval(1)
}

// MARK: - Shared chrome

private extension View {
  @ViewBuilder
  func arinTransparentWidgetSurface() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) { Color.clear }
    } else {
      self.background(Color.clear)
    }
  }
}

/// Tüm widget'larda kilitli durumda gösterilen ortak görsel.
/// `accessoryRectangular` (kilit ekranı): tek satır, kilit ikonu + kısa metin.
/// `systemSmall`/`systemMedium`: dikey, daha büyük kilit + altında metin.
///
/// `kindId`: kalan parametre — şu an sadece dökümantasyon amaçlı tutuluyor.
/// Tıklama URL'si (`arin://widget/<kindId>?homeWidget=true[&lock=1]`) widget'ın
/// `WidgetConfiguration` body'sinde, entry lock state'ine göre conditional
/// olarak set edilir. iOS `widgetURL` modifier'ını yalnızca configuration
/// düzeyinde tutarlı uygular; alt view'da set etmek override etmez. Ayrıca
/// `home_widget` plugin'i URL'i widget URL'i olarak kabul edebilmek için
/// query'de `homeWidget` parametresinin varlığını şart koştuğundan, tüm
/// widget URL'leri bu parametreyi taşımak zorundadır — yoksa Flutter tarafı
/// hiçbir tıklama olayını almaz.
struct LockedWidgetView: View {
  let family: WidgetFamily
  let kindId: String
  @Environment(\.colorScheme) private var colorScheme

  private var primaryTextColor: Color {
    colorScheme == .dark ? Color(red: 0.88, green: 0.90, blue: 0.93) : .white
  }

  private var textShadowOpacity: Double {
    colorScheme == .dark ? 0.34 : 0.52
  }

  var body: some View {
    Group {
      if family == .accessoryRectangular {
        compactLayout
      } else {
        expandedLayout
      }
    }
  }

  /// Kilit ekranı — küçük rectangular: yan yana kompakt.
  /// SF Symbol kullanmıyoruz çünkü emoji sembol hizalama kilit-ekran widget'larında
  /// iOS'a göre aşağı kayıyordu; sade lock.fill daha tutarlı.
  private var compactLayout: some View {
    HStack(spacing: 6) {
      Image(systemName: "lock.fill")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(primaryTextColor)
      Text("Açmak için dokunun")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(primaryTextColor)
        .lineLimit(2)
        .minimumScaleFactor(0.55)
        .multilineTextAlignment(.leading)
        .allowsTightening(true)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .padding(.horizontal, 6)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 2.0, x: 0, y: 1)
  }

  /// systemSmall / systemMedium: ortalanmış kilit + altında çağrı.
  private var expandedLayout: some View {
    VStack(spacing: 8) {
      Image(systemName: "lock.fill")
        .font(.system(size: family == .systemSmall ? 28 : 26, weight: .semibold))
        .foregroundStyle(primaryTextColor)
      Text("Açmak için dokunun")
        .font(.system(size: family == .systemSmall ? 14 : 13, weight: .semibold))
        .foregroundStyle(primaryTextColor)
        .lineLimit(2)
        .minimumScaleFactor(0.6)
        .multilineTextAlignment(.center)
        .allowsTightening(true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .padding(.horizontal, 10)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 2.4, x: 0, y: 1)
  }
}

// MARK: - Quote

struct QuoteEntry: TimelineEntry {
  let date: Date
  let text: String
  let source: String
}

struct QuoteProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuoteEntry {
    QuoteEntry(date: Date(), text: QuoteWidgetDefaults.text, source: QuoteWidgetDefaults.source)
  }

  func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
    // Widget galerisi / Smart Stack önerisi: kilit göstermeden örnek içerik dön.
    // `context.isPreview` true iken WidgetKit gerçek timeline'a değil sadece
    // tanıtıma ihtiyaç duyar; trial sayacı henüz başlamamış olsa bile
    // Flutter'ın yazdığı `arin_widget_gate_*_locked` flag'i preview'a sızmasın.
    if context.isPreview {
      completion(
        QuoteEntry(
          date: Date(),
          text: QuoteWidgetDefaults.text,
          source: QuoteWidgetDefaults.source
        )
      )
      return
    }
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
    recordWidgetFirstUse("quote")
    if widgetLocked("quote") {
      let next = widgetGateRefreshDate("quote") ?? Date().addingTimeInterval(3600)
      completion(
        Timeline(
          entries: [
            QuoteEntry(
              date: Date(),
              text: "🔒",
              source: ""
            )
          ],
          policy: .after(next)
        )
      )
      return
    }
    if let timeline = loadScheduledTimeline() {
      completion(timeline)
      return
    }
    let e = loadEntry()
    let contentNext = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(21_600)
    let next = [contentNext, widgetGateRefreshDate("quote")].compactMap { $0 }.min() ?? contentNext
    completion(Timeline(entries: [e], policy: .after(next)))
  }

  private func loadEntry() -> QuoteEntry {
    if widgetLocked("quote") {
      return QuoteEntry(
        date: Date(),
        text: "🔒",
        source: ""
      )
    }
    let u = suite()
    let rawText = u?.string(forKey: "arin_quote_text")?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let rawSource = u?.string(forKey: "arin_quote_source")?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let text = rawText.isEmpty ? QuoteWidgetDefaults.text : rawText
    let source = rawSource
    return QuoteEntry(
      date: Date(),
      text: text,
      source: source
    )
  }

  private func loadScheduledTimeline() -> Timeline<QuoteEntry>? {
    guard let payload = decodeWidgetJson("arin_quote_schedule_json", as: QuoteSchedulePayload.self) else {
      return nil
    }
    let sorted = payload.entries
      .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      .sorted { $0.date < $1.date }
    guard !sorted.isEmpty else { return nil }

    let now = Date()
    var current = sorted.first!
    var future = [QuoteScheduleItem]()
    for item in sorted {
      if item.date <= now {
        current = item
      } else {
        future.append(item)
      }
    }

    var entries = [
      QuoteEntry(
        date: now,
        text: current.text.trimmingCharacters(in: .whitespacesAndNewlines),
        source: current.source.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    ]
    let gateDate = widgetGateRefreshDate("quote")
    let gatedFuture: [QuoteScheduleItem]
    if let gateDate = gateDate {
      gatedFuture = future.filter { $0.date < gateDate }
    } else {
      gatedFuture = future
    }
    let emittedFuture = Array(gatedFuture.prefix(kQuoteTimelineFutureLimit))
    entries.append(
      contentsOf: emittedFuture.map {
        QuoteEntry(
          date: $0.date,
          text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines),
          source: $0.source.trimmingCharacters(in: .whitespacesAndNewlines)
        )
      }
    )
    let contentRefresh = emittedFuture.last?.date.addingTimeInterval(1_800) ?? now.addingTimeInterval(21_600)
    let refresh = [contentRefresh, gateDate].compactMap { $0 }.min() ?? contentRefresh
    return Timeline(entries: entries, policy: .after(refresh))
  }
}

struct QuoteWidgetView: View {
  var entry: QuoteProvider.Entry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme

  private var primaryTextColor: Color {
    colorScheme == .dark ? Color(red: 0.88, green: 0.90, blue: 0.93) : .white
  }

  private var secondaryTextColor: Color {
    primaryTextColor.opacity(0.9)
  }

  private var textShadowOpacity: Double {
    // Açık arkaplanda daha güçlü gölge, koyu arkaplanda daha yumuşak gölge.
    colorScheme == .dark ? 0.34 : 0.52
  }

  private var hasSource: Bool {
    !entry.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// Lock state: provider entry text'i 🔒 ise kilit görselini göster.
  private var isLocked: Bool {
    entry.text == "🔒"
  }

  var body: some View {
    if isLocked {
      LockedWidgetView(family: family, kindId: "quote")
    } else {
      switch family {
      case .accessoryRectangular:
        quoteAccessory
      case .systemSmall:
        quoteCompact
      default:
        quoteExpanded
      }
    }
  }

  private var quoteAccessory: some View {
    VStack(alignment: .leading, spacing: 2) {
      if hasSource {
        Text(entry.source)
          .font(.system(size: 12, weight: .bold, design: .default))
          .foregroundColor(primaryTextColor)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
      }
      Text(entry.text.isEmpty ? "ARIN" : entry.text)
        .font(.system(size: 13, weight: .regular, design: .serif))
        .foregroundColor(primaryTextColor)
        .lineSpacing(-1)
        .lineLimit(3)
        .minimumScaleFactor(0.48)
        .allowsTightening(true)
        .multilineTextAlignment(.leading)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 3)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 2.2, x: 0, y: 1)
  }

  /// Kilit ekranı / küçük: üstte kaynak + ay, altta metin (Talak 3 tarzı).
  private var quoteCompact: some View {
    VStack(alignment: .leading, spacing: 4) {
      if hasSource {
        HStack(alignment: .firstTextBaseline) {
          Text(entry.source)
            .font(.system(size: 15, weight: .bold, design: .default))
            .foregroundColor(primaryTextColor)
            .lineLimit(1)
          Spacer(minLength: 4)
          Image(systemName: "moon.stars.fill")
            .font(.system(size: 15, weight: .regular))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(secondaryTextColor)
        }
        .padding(.leading, 5)
      }
      Text(entry.text.isEmpty ? "ARIN" : entry.text)
        .font(.system(size: 15, weight: .regular, design: .serif))
        .foregroundColor(primaryTextColor)
        .lineSpacing(-1)
        .lineLimit(4)
        .minimumScaleFactor(0.50)
        .allowsTightening(true)
        .multilineTextAlignment(.leading)
    }
    .padding(.horizontal, 11)
    .padding(.vertical, 8)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 2.6, x: 0, y: 1)
  }

  private var quoteExpanded: some View {
    VStack(alignment: .leading, spacing: 5) {
      if hasSource {
        HStack(alignment: .firstTextBaseline) {
          Text(entry.source)
            .font(.system(size: 16, weight: .bold, design: .default))
            .foregroundColor(primaryTextColor)
            .lineLimit(1)
          Spacer(minLength: 4)
          Image(systemName: "moon.stars.fill")
            .font(.system(size: 16))
            .foregroundStyle(secondaryTextColor)
        }
        .padding(.leading, 5)
      }
      Text(entry.text.isEmpty ? "ARIN" : entry.text)
        .font(.system(size: 18, weight: .regular, design: .serif))
        .foregroundColor(primaryTextColor)
        .lineSpacing(0)
        .lineLimit(4)
        .minimumScaleFactor(0.54)
        .allowsTightening(true)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 2.8, x: 0, y: 1)
  }
}

struct ArinQuoteWidget: Widget {
  let kind: String = "ArinQuoteWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
      QuoteWidgetView(entry: entry)
        .arinTransparentWidgetSurface()
        .widgetURL(URL(string: entry.text == "🔒"
          ? "arin://widget/quote?homeWidget=true&lock=1"
          : "arin://widget/quote?homeWidget=true"))
    }
    .configurationDisplayName(localizedWidgetText(tr: "ARIN — Söz"))
    .description(localizedWidgetText(tr: "Günlük söz ve kaynak."))
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

// MARK: - Prayer

struct PrayerEntry: TimelineEntry {
  let date: Date
  let location: String
  let nextName: String
  let countdown: String
  let nextDate: Date?
}

struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    PrayerEntry(
      date: Date(),
      location: "—",
      nextName: localizedWidgetText(tr: "İmsak"),
      countdown: "0:15:00",
      nextDate: Date().addingTimeInterval(15 * 60)
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    // Galeri / Smart Stack önerisi: kilitsiz örnek geri sayım göster.
    if context.isPreview {
      completion(
        PrayerEntry(
          date: Date(),
          location: PrayerWidgetDefaults.location,
          nextName: localizedWidgetText(tr: "İmsak"),
          countdown: "0:15:00",
          nextDate: Date().addingTimeInterval(15 * 60)
        )
      )
      return
    }
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    recordWidgetFirstUse("prayer")
    if widgetLocked("prayer") {
      let next = widgetGateRefreshDate("prayer") ?? Date().addingTimeInterval(3600)
      completion(
        Timeline(
          entries: [
            PrayerEntry(
              date: Date(),
              location: "",
              nextName: "🔒",
              countdown: "—",
              nextDate: nil
            )
          ],
          policy: .after(next)
        )
      )
      return
    }
    if let timeline = loadScheduledTimeline() {
      completion(timeline)
      return
    }
    let e = loadEntry()
    // iOS WidgetKit'te saniyelik zorlamadan kaçın: pil-dostu, dakikalık tazeleme.
    let contentNext = Date().addingTimeInterval(60)
    let nextFire = [contentNext, widgetGateRefreshDate("prayer")].compactMap { $0 }.min() ?? contentNext
    completion(Timeline(entries: [e], policy: .after(nextFire)))
  }

  private func loadEntry() -> PrayerEntry {
    if widgetLocked("prayer") {
      return PrayerEntry(
        date: Date(),
        location: "",
        nextName: "🔒",
        countdown: "—",
        nextDate: nil
      )
    }
    let u = suite()
    let forceTurkish = !storedWidgetLocaleCode().hasPrefix("tr")
    let rawNextName = u?.string(forKey: "arin_prayer_next_name") ?? ""
    let nextName = forceTurkish ? "İmsak" : turkishPrayerName(rawNextName)
    let rawLocation = u?.string(forKey: "arin_prayer_location")?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let location = rawLocation.isEmpty ? PrayerWidgetDefaults.location : rawLocation
    var countdown = sanitizeCountdown(u?.string(forKey: "arin_prayer_countdown") ?? "—")
    var nextDate: Date? = nil
    if let epochStr = u?.string(forKey: "arin_prayer_next_epoch_ms"),
       let epochMs = Double(epochStr) {
      let target = Date(timeIntervalSince1970: epochMs / 1000.0)
      nextDate = target
      let rem = max(0, target.timeIntervalSince1970 - Date().timeIntervalSince1970)
      countdown = formatHMS(seconds: rem)
    }
    return PrayerEntry(
      date: Date(),
      location: location,
      nextName: nextName,
      countdown: countdown,
      nextDate: nextDate
    )
  }

  private func loadScheduledTimeline() -> Timeline<PrayerEntry>? {
    guard let payload = decodeWidgetJson("arin_prayer_schedule_json", as: PrayerSchedulePayload.self) else {
      return nil
    }
    let sorted = payload.entries.sorted { $0.date < $1.date }
    guard !sorted.isEmpty else { return nil }

    let now = Date()
    let locationRaw = payload.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let location = locationRaw.isEmpty ? PrayerWidgetDefaults.location : locationRaw

    func entry(at date: Date, next item: PrayerScheduleItem) -> PrayerEntry {
      let remaining = max(0, item.date.timeIntervalSince1970 - date.timeIntervalSince1970)
      return PrayerEntry(
        date: date,
        location: location,
        nextName: turkishPrayerName(item.name),
        countdown: formatHMS(seconds: remaining),
        nextDate: item.date
      )
    }

    guard let firstNextIndex = sorted.firstIndex(where: { $0.date > now }) else {
      let stale = PrayerEntry(
        date: now,
        location: location,
        nextName: localizedWidgetText(tr: "Güncelle"),
        countdown: localizedWidgetText(tr: "Uygulamayı aç"),
        nextDate: nil
      )
      let contentRefresh = now.addingTimeInterval(21_600)
      let refresh = [contentRefresh, widgetGateRefreshDate("prayer")].compactMap { $0 }.min() ?? contentRefresh
      return Timeline(entries: [stale], policy: .after(refresh))
    }

    var entries = [entry(at: now, next: sorted[firstNextIndex])]
    let gateDate = widgetGateRefreshDate("prayer")
    if firstNextIndex + 1 < sorted.count {
      let endExclusive = min(sorted.count, firstNextIndex + 1 + kPrayerTimelineFutureLimit)
      for index in (firstNextIndex + 1)..<endExclusive {
        if let gateDate = gateDate,
           sorted[index - 1].date.addingTimeInterval(1) >= gateDate {
          break
        }
        entries.append(
          entry(
            at: sorted[index - 1].date.addingTimeInterval(1),
            next: sorted[index]
          )
        )
      }
    }
    let contentRefresh = entries.last?.date.addingTimeInterval(3600) ?? now.addingTimeInterval(3600)
    let refresh = [contentRefresh, gateDate].compactMap { $0 }.min() ?? contentRefresh
    return Timeline(entries: entries, policy: .after(refresh))
  }

  private func formatHMS(seconds: Double) -> String {
    let s = max(0, Int(seconds))
    let h = s / 3600
    let m = (s % 3600) / 60
    let sec = s % 60
    return String(format: "%d:%02d:%02d", h, m, sec)
  }
}

struct PrayerWidgetView: View {
  var entry: PrayerProvider.Entry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme

  private var primaryTextColor: Color {
    colorScheme == .dark ? Color(red: 0.88, green: 0.90, blue: 0.93) : .white
  }

  private var secondaryTextColor: Color {
    primaryTextColor.opacity(0.78)
  }

  private var textShadowOpacity: Double {
    // Açık arkaplanda daha güçlü gölge, koyu arkaplanda daha yumuşak gölge.
    colorScheme == .dark ? 0.34 : 0.52
  }

  /// Lock state: provider entry nextName'i 🔒 ise kilit görselini göster.
  private var isLocked: Bool {
    entry.nextName == "🔒"
  }

  var body: some View {
    if isLocked {
      LockedWidgetView(family: family, kindId: "prayer")
    } else {
      switch family {
      case .accessoryRectangular, .systemSmall:
        prayerCompact
      default:
        prayerExpanded
      }
    }
  }

  /// Sade düzen: başlık + geri sayım + küçük konum.
  private var prayerCompact: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .center) {
        HStack(spacing: 5) {
          Image(systemName: "moon.stars.fill")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(secondaryTextColor)
          Text(headerTitle)
            .font(.system(size: 12, weight: .bold, design: .default))
            .foregroundStyle(primaryTextColor)
            .lineLimit(1)
        }
        Spacer(minLength: 4)
      }
      HStack(alignment: .firstTextBaseline, spacing: 7) {
        Image(systemName: "clock.fill")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(secondaryTextColor)
          .symbolRenderingMode(.hierarchical)
        countdownText(size: 21, minScale: 0.78)
      }
      if !entry.location.isEmpty {
        Text(entry.location)
          .font(.system(size: 10, weight: .medium, design: .rounded))
          .foregroundStyle(secondaryTextColor)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
    .padding(.horizontal, 11)
    .padding(.vertical, 10)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 2.6, x: 0, y: 1)
  }

  /// Sıradaki vakit adı: Flutter anahtarı; yoksa genel başlık.
  private var headerTitle: String {
    let n = entry.nextName.trimmingCharacters(in: .whitespacesAndNewlines)
    if !n.isEmpty { return n }
    return localizedWidgetText(tr: "Vakit")
  }

  private var prayerExpanded: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack(spacing: 5) {
        Image(systemName: "moon.stars.fill")
          .font(.system(size: 12))
          .foregroundStyle(secondaryTextColor)
        Text(headerTitle)
          .font(.system(size: 13, weight: .bold, design: .default))
          .foregroundStyle(primaryTextColor)
          .lineLimit(1)
        Spacer()
      }
      HStack(spacing: 8) {
        Image(systemName: "clock.fill")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(secondaryTextColor)
        countdownText(size: 26, minScale: 0.78)
      }
      if !entry.location.isEmpty {
        Text(entry.location)
          .font(.system(size: 11, weight: .medium, design: .rounded))
          .foregroundStyle(secondaryTextColor)
          .lineLimit(1)
          .minimumScaleFactor(0.82)
      }
    }
    .padding(14)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 3.0, x: 0, y: 1)
  }

  @ViewBuilder
  private func countdownText(size: CGFloat, minScale: CGFloat) -> some View {
    if let nextDate = entry.nextDate, nextDate > Date() {
      Text(timerInterval: Date()...nextDate, countsDown: true)
        .font(.system(size: size, weight: .semibold, design: .serif))
        .foregroundStyle(primaryTextColor)
        .monospacedDigit()
        .minimumScaleFactor(minScale)
    } else {
      Text(entry.countdown)
        .font(.system(size: size, weight: .semibold, design: .serif))
        .foregroundStyle(primaryTextColor)
        .monospacedDigit()
        .minimumScaleFactor(minScale)
    }
  }
}

struct ArinPrayerWidget: Widget {
  let kind: String = "ArinPrayerWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
      PrayerWidgetView(entry: entry)
        .arinTransparentWidgetSurface()
        .widgetURL(URL(string: entry.nextName == "🔒"
          ? "arin://widget/prayer?homeWidget=true&lock=1"
          : "arin://widget/prayer?homeWidget=true"))
    }
    .configurationDisplayName(localizedWidgetText(tr: "ARIN — Namaz"))
    .description(localizedWidgetText(tr: "Sıradaki vakit ve geri sayım."))
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

// MARK: - Combo

struct ComboEntry: TimelineEntry {
  let date: Date
  let nextName: String
  let countdown: String
  let nextDate: Date?
  let quoteText: String
  let quoteSource: String
}

struct ComboProvider: TimelineProvider {
  func placeholder(in context: Context) -> ComboEntry {
    ComboEntry(
      date: Date(),
      nextName: localizedWidgetText(tr: "Akşam"),
      countdown: "1:24:10",
      nextDate: Date().addingTimeInterval(84 * 60),
      quoteText: QuoteWidgetDefaults.text,
      quoteSource: QuoteWidgetDefaults.source
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (ComboEntry) -> Void) {
    // Galeri / Smart Stack önerisi: kilitsiz örnek karma içerik göster.
    if context.isPreview {
      completion(
        ComboEntry(
          date: Date(),
          nextName: localizedWidgetText(tr: "Akşam"),
          countdown: "1:24:10",
          nextDate: Date().addingTimeInterval(84 * 60),
          quoteText: QuoteWidgetDefaults.text,
          quoteSource: QuoteWidgetDefaults.source
        )
      )
      return
    }
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ComboEntry>) -> Void) {
    recordWidgetFirstUse("combo")
    let now = Date()
    if widgetLocked("combo") {
      let next = widgetGateRefreshDate("combo") ?? now.addingTimeInterval(3600)
      completion(
        Timeline(
          entries: [
            ComboEntry(
              date: Date(),
              nextName: "🔒",
              countdown: "—",
              nextDate: nil,
              quoteText: "",
              quoteSource: ""
            )
          ],
          policy: .after(next)
        )
      )
      return
    }
    if let scheduled = loadScheduledTimeline(now: now) {
      completion(scheduled)
      return
    }
    let loaded = loadEntry(at: now)
    let candidates = [loaded.prayerRefreshDate, loaded.quoteRefreshDate]
      .compactMap { $0 }
      .filter { $0 > now }
    let refresh = candidates.min()
      ?? Calendar.current.date(byAdding: .hour, value: 1, to: now)
      ?? now.addingTimeInterval(3600)
    let next = [refresh, widgetGateRefreshDate("combo")].compactMap { $0 }.min() ?? refresh
    completion(Timeline(entries: [loaded.entry], policy: .after(next)))
  }

  // Generates a multi-entry timeline from the prayer schedule JSON so WidgetKit
  // transitions between entries deterministically — avoiding the stuck-at-0:00 bug
  // that occurs when a single-entry timeline waits on a budget-throttled refresh.
  private func loadScheduledTimeline(now: Date) -> Timeline<ComboEntry>? {
    guard let payload = decodeWidgetJson("arin_prayer_schedule_json", as: PrayerSchedulePayload.self) else {
      return nil
    }
    let sorted = payload.entries.sorted { $0.date < $1.date }
    guard let firstNextIndex = sorted.firstIndex(where: { $0.date > now }) else {
      return nil
    }

    let gateDate = widgetGateRefreshDate("combo")

    func makeEntry(at date: Date, next item: PrayerScheduleItem) -> ComboEntry {
      let remaining = max(0, item.date.timeIntervalSince1970 - date.timeIntervalSince1970)
      let quote = loadQuote(now: date)
      return ComboEntry(
        date: date,
        nextName: turkishPrayerName(item.name),
        countdown: formatHMS(seconds: remaining),
        nextDate: item.date,
        quoteText: quote.text,
        quoteSource: quote.source
      )
    }

    var entries = [makeEntry(at: now, next: sorted[firstNextIndex])]
    if firstNextIndex + 1 < sorted.count {
      let endExclusive = min(sorted.count, firstNextIndex + 1 + kPrayerTimelineFutureLimit)
      for index in (firstNextIndex + 1)..<endExclusive {
        if let gateDate = gateDate,
           sorted[index - 1].date.addingTimeInterval(1) >= gateDate {
          break
        }
        entries.append(
          makeEntry(
            at: sorted[index - 1].date.addingTimeInterval(1),
            next: sorted[index]
          )
        )
      }
    }

    let contentRefresh = entries.last?.date.addingTimeInterval(3600) ?? now.addingTimeInterval(3600)
    let refresh = [contentRefresh, gateDate].compactMap { $0 }.min() ?? contentRefresh
    return Timeline(entries: entries, policy: .after(refresh))
  }

  private func loadEntry() -> ComboEntry {
    if widgetLocked("combo") {
      return ComboEntry(
        date: Date(),
        nextName: "🔒",
        countdown: "—",
        nextDate: nil,
        quoteText: "",
        quoteSource: ""
      )
    }
    return loadEntry(at: Date()).entry
  }

  private func loadEntry(at now: Date) -> (
    entry: ComboEntry,
    prayerRefreshDate: Date?,
    quoteRefreshDate: Date?
  ) {
    let prayer = loadPrayer(now: now)
    let quote = loadQuote(now: now)
    return (
      entry: ComboEntry(
        date: now,
        nextName: prayer.nextName,
        countdown: prayer.countdown,
        nextDate: prayer.nextDate,
        quoteText: quote.text,
        quoteSource: quote.source
      ),
      prayerRefreshDate: prayer.refreshDate,
      quoteRefreshDate: quote.refreshDate
    )
  }

  private func loadQuote(now: Date) -> (
    text: String,
    source: String,
    refreshDate: Date?
  ) {
    if let payload = decodeWidgetJson("arin_quote_schedule_json", as: QuoteSchedulePayload.self) {
      let sorted = payload.entries
        .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .sorted { $0.date < $1.date }
      if !sorted.isEmpty {
        var current = sorted.first!
        var nextDate: Date? = nil
        for item in sorted {
          if item.date <= now {
            current = item
          } else {
            nextDate = item.date
            break
          }
        }
        return (
          text: current.text.trimmingCharacters(in: .whitespacesAndNewlines),
          source: current.source.trimmingCharacters(in: .whitespacesAndNewlines),
          refreshDate: nextDate
        )
      }
    }

    let u = suite()
    let rawText = u?.string(forKey: "arin_quote_text")?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let rawSource = u?.string(forKey: "arin_quote_source")?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return (
      text: rawText.isEmpty ? QuoteWidgetDefaults.text : rawText,
      source: rawSource,
      refreshDate: nil
    )
  }

  private func loadPrayer(now: Date) -> (
    nextName: String,
    countdown: String,
    nextDate: Date?,
    refreshDate: Date?
  ) {
    if let payload = decodeWidgetJson("arin_prayer_schedule_json", as: PrayerSchedulePayload.self) {
      let sorted = payload.entries.sorted { $0.date < $1.date }
      if let next = sorted.first(where: { $0.date > now }) {
        let remaining = max(0, next.date.timeIntervalSince1970 - now.timeIntervalSince1970)
        let nextDate = next.date
        return (
          nextName: turkishPrayerName(next.name),
          countdown: formatHMS(seconds: remaining),
          nextDate: nextDate,
          refreshDate: nextDate.addingTimeInterval(1)
        )
      }
      return (
        nextName: localizedWidgetText(tr: "Güncelle"),
        countdown: localizedWidgetText(tr: "Uygulamayı aç"),
        nextDate: nil,
        refreshDate: now.addingTimeInterval(21_600)
      )
    }

    let u = suite()
    let forceTurkish = !storedWidgetLocaleCode().hasPrefix("tr")
    let rawNextName = u?.string(forKey: "arin_prayer_next_name") ?? ""
    let nextName = forceTurkish ? "İmsak" : turkishPrayerName(rawNextName)
    var countdown = sanitizeCountdown(u?.string(forKey: "arin_prayer_countdown") ?? "—")
    var nextDate: Date? = nil
    if let epochStr = u?.string(forKey: "arin_prayer_next_epoch_ms"),
       let epochMs = Double(epochStr) {
      let target = Date(timeIntervalSince1970: epochMs / 1000.0)
      nextDate = target
      let rem = max(0, target.timeIntervalSince1970 - now.timeIntervalSince1970)
      countdown = formatHMS(seconds: rem)
    }
    return (
      nextName: nextName,
      countdown: countdown,
      nextDate: nextDate,
      refreshDate: nextDate?.addingTimeInterval(1)
    )
  }

  private func formatHMS(seconds: Double) -> String {
    let s = max(0, Int(seconds))
    let h = s / 3600
    let m = (s % 3600) / 60
    let sec = s % 60
    return String(format: "%d:%02d:%02d", h, m, sec)
  }
}

struct ComboWidgetView: View {
  var entry: ComboProvider.Entry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme

  private var primaryTextColor: Color {
    colorScheme == .dark ? Color(red: 0.88, green: 0.90, blue: 0.93) : .white
  }

  private var secondaryTextColor: Color {
    primaryTextColor.opacity(0.82)
  }

  private var textShadowOpacity: Double {
    colorScheme == .dark ? 0.34 : 0.52
  }

  private var hasSource: Bool {
    !displayQuoteSource.isEmpty
  }

  private var displayQuoteSource: String {
    entry.quoteSource.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var title: String {
    let n = entry.nextName.trimmingCharacters(in: .whitespacesAndNewlines)
    if n == localizedWidgetText(tr: "Güncelle") { return n }
    let base = n.isEmpty ? localizedWidgetText(tr: "Vakit") : n
    return "\(base)'\(remainingSuffix(for: base)) kalan"
  }

  /// Lock state: combo entry nextName'i 🔒 ise kilit görselini göster.
  private var isLocked: Bool {
    entry.nextName == "🔒"
  }

  var body: some View {
    if isLocked {
      LockedWidgetView(family: family, kindId: "combo")
    } else if family == .accessoryRectangular {
      accessoryLayout
    } else {
      expandedLayout
    }
  }

  private var expandedLayout: some View {
    VStack(alignment: .leading, spacing: family == .accessoryRectangular ? 3 : 5) {
      prayerBlock
      quoteBlock
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, family == .accessoryRectangular ? 4 : 9)
    .padding(.vertical, family == .accessoryRectangular ? 3 : 7)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 2.8, x: 0, y: 1)
  }

  private var accessoryLayout: some View {
    VStack(alignment: .leading, spacing: 1) {
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(title)
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(primaryTextColor)
          .lineLimit(1)
          .minimumScaleFactor(0.58)
        Spacer(minLength: 2)
        countdownText(size: 12)
      }
      if !entry.quoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text(entry.quoteText)
          .font(.system(size: 15, weight: .regular, design: .serif))
          .foregroundStyle(primaryTextColor)
          .lineLimit(2)
          .minimumScaleFactor(0.38)
          .allowsTightening(true)
          .fixedSize(horizontal: false, vertical: false)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 4)
    .padding(.vertical, 2)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 2.4, x: 0, y: 1)
  }

  private var prayerBlock: some View {
    VStack(alignment: .leading, spacing: 3) {
      HStack(spacing: 5) {
        Image(systemName: "moon.stars.fill")
          .font(.system(size: family == .accessoryRectangular ? 11 : 13, weight: .semibold))
          .foregroundStyle(secondaryTextColor)
        Text(title)
          .font(.system(size: family == .accessoryRectangular ? 12 : 14, weight: .bold))
          .foregroundStyle(primaryTextColor)
          .lineLimit(1)
          .minimumScaleFactor(0.62)
      }
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Image(systemName: "clock.fill")
          .font(.system(size: family == .accessoryRectangular ? 12 : 15, weight: .semibold))
          .foregroundStyle(secondaryTextColor)
        countdownText(size: family == .accessoryRectangular ? 16 : 21)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var quoteBlock: some View {
    VStack(alignment: .leading, spacing: 3) {
      if !entry.quoteText.isEmpty {
        Text(entry.quoteText)
          .font(.system(size: family == .accessoryRectangular ? 15 : 27, weight: .regular, design: .serif))
          .foregroundStyle(primaryTextColor)
          .lineSpacing(-3)
          .lineLimit(family == .accessoryRectangular ? 2 : 2)
          .minimumScaleFactor(0.48)
          .allowsTightening(true)
      }
      if hasSource {
        Text(displayQuoteSource)
          .font(.system(size: family == .accessoryRectangular ? 11 : 15, weight: .bold))
          .foregroundStyle(secondaryTextColor)
          .lineLimit(1)
          .minimumScaleFactor(0.62)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func countdownText(size: CGFloat) -> some View {
    if let nextDate = entry.nextDate, nextDate > Date() {
      Text(timerInterval: Date()...nextDate, countsDown: true)
        .font(.system(size: size, weight: .semibold, design: .serif))
        .foregroundStyle(primaryTextColor)
        .monospacedDigit()
        .minimumScaleFactor(0.62)
    } else {
      Text(entry.countdown)
        .font(.system(size: size, weight: .semibold, design: .serif))
        .foregroundStyle(primaryTextColor)
        .monospacedDigit()
        .minimumScaleFactor(0.62)
    }
  }

  private func remainingSuffix(for raw: String) -> String {
    switch raw {
    case "Öğle", "İkindi": return "ye"
    case "Güneş", "Vakit": return "e"
    case "Yatsı": return "ya"
    default: return "a"
    }
  }
}

struct ArinComboWidget: Widget {
  let kind: String = "ArinComboWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ComboProvider()) { entry in
      ComboWidgetView(entry: entry)
        .arinTransparentWidgetSurface()
        .widgetURL(URL(string: entry.nextName == "🔒"
          ? "arin://widget/combo?homeWidget=true&lock=1"
          : "arin://widget/combo?homeWidget=true"))
    }
    .configurationDisplayName(localizedWidgetText(tr: "ARIN — Karma"))
    .description(localizedWidgetText(tr: "Sıradaki vakit ve günlük söz."))
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

// MARK: - Tracking

struct TrackingEntry: TimelineEntry {
  let date: Date
  let title: String
  let value: String
  let note: String
}

struct TrackingProvider: TimelineProvider {
  func placeholder(in context: Context) -> TrackingEntry {
    TrackingEntry(
      date: Date(),
      title: "Sigarasız gün sayacı",
      value: "Sigarasız 18. gün",
      note: "Kriz geçer, kararın kalır."
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (TrackingEntry) -> Void) {
    // Galeri / Smart Stack önerisi: kilitsiz örnek takip içeriği göster.
    if context.isPreview {
      completion(
        TrackingEntry(
          date: Date(),
          title: "Sigarasız gün sayacı",
          value: "Sigarasız 18. gün",
          note: "Kriz geçer, kararın kalır."
        )
      )
      return
    }
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TrackingEntry>) -> Void) {
    recordWidgetFirstUse("tracking")
    let entry = loadEntry()
    let now = Date()
    let nextDay = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
    let next = [nextDay, widgetGateRefreshDate("tracking")].compactMap { $0 }.min() ?? nextDay
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func loadEntry() -> TrackingEntry {
    if widgetLocked("tracking") {
      return TrackingEntry(
        date: Date(),
        title: "🔒",
        value: "",
        note: ""
      )
    }
    let u = suite()
    let enabled = u?.string(forKey: "arin_tracking_enabled") == "1"
    if !enabled {
      return TrackingEntry(
        date: Date(),
        title: "Takip seçilmedi",
        value: "",
        note: "Ayarlar > Widget Merkezi"
      )
    }

    let rawTitle = u?.string(forKey: "arin_tracking_title")?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let mode = u?.string(forKey: "arin_tracking_mode")?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let value: String
    if mode == "quit_days",
       let rawEpoch = u?.string(forKey: "arin_tracking_start_epoch_ms"),
       let epochMs = Double(rawEpoch),
       let prefix = u?.string(forKey: "arin_tracking_day_prefix")?
        .trimmingCharacters(in: .whitespacesAndNewlines),
       !prefix.isEmpty {
      let start = Date(timeIntervalSince1970: epochMs / 1000.0)
      // 1-tabanlı sayaç: başlanan ilk gün "1. gün". Android/Flutter
      // (TrackingWidgetService / ArinTrackingWidgetProvider) ile aynı olması
      // için +1 eklenir.
      let days = max(0, Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0) + 1
      value = "\(prefix) \(days). gün"
    } else {
      value = u?.string(forKey: "arin_tracking_value")?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    let note = dailyQuote(from: u?.string(forKey: "arin_tracking_quotes_json"))
      ?? u?.string(forKey: "arin_tracking_note")?
        .trimmingCharacters(in: .whitespacesAndNewlines)
      ?? ""

    return TrackingEntry(
      date: Date(),
      title: rawTitle.isEmpty ? "ARIN Takip" : rawTitle,
      value: value,
      note: note.isEmpty ? "Bugün küçük bir adım yeter." : note
    )
  }

  private func dailyQuote(from raw: String?) -> String? {
    guard let raw,
          let data = raw.data(using: .utf8),
          let items = try? JSONDecoder().decode([String].self, from: data),
          !items.isEmpty else {
      return nil
    }
    let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    let text = items[max(0, day - 1) % items.count].trimmingCharacters(in: .whitespacesAndNewlines)
    return text.isEmpty ? nil : text
  }
}

struct TrackingWidgetView: View {
  var entry: TrackingProvider.Entry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme

  private var primaryTextColor: Color {
    colorScheme == .dark ? Color(red: 0.88, green: 0.90, blue: 0.93) : .white
  }

  private var secondaryTextColor: Color {
    primaryTextColor.opacity(0.86)
  }

  /// Lock state: tracking entry title'ı 🔒 ise kilit görselini göster.
  private var isLocked: Bool {
    entry.title == "🔒"
  }

  var body: some View {
    if isLocked {
      LockedWidgetView(family: family, kindId: "tracking")
    } else {
      VStack(alignment: .leading, spacing: family == .accessoryRectangular ? 2 : 4) {
        Text(entry.title)
          .font(.system(size: family == .accessoryRectangular ? 11 : 13, weight: .bold))
          .foregroundStyle(secondaryTextColor)
          .lineLimit(1)
          .minimumScaleFactor(0.62)
        if !entry.value.isEmpty {
          Text(entry.value)
            .font(.system(size: family == .accessoryRectangular ? 15 : 20, weight: .bold, design: .serif))
            .foregroundStyle(primaryTextColor)
            .lineLimit(1)
            .minimumScaleFactor(0.58)
        }
        if !entry.note.isEmpty {
          Text(entry.note)
            .font(.system(size: family == .accessoryRectangular ? 12 : 15, weight: .regular, design: .serif))
            .foregroundStyle(primaryTextColor)
            .lineLimit(family == .accessoryRectangular ? 2 : 3)
            .minimumScaleFactor(0.50)
            .allowsTightening(true)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, family == .accessoryRectangular ? 5 : 10)
      .padding(.vertical, family == .accessoryRectangular ? 3 : 8)
      .shadow(color: .black.opacity(colorScheme == .dark ? 0.34 : 0.52), radius: 2.6, x: 0, y: 1)
    }
  }
}

struct ArinTrackingWidget: Widget {
  let kind: String = "ArinTrackingWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TrackingProvider()) { entry in
      TrackingWidgetView(entry: entry)
        .arinTransparentWidgetSurface()
        .widgetURL(URL(string: entry.title == "🔒"
          ? "arin://widget/tracking?homeWidget=true&lock=1"
          : "arin://widget/tracking?homeWidget=true"))
    }
    .configurationDisplayName(localizedWidgetText(tr: "ARIN — Takip"))
    .description(localizedWidgetText(tr: "Seçili gelişim veya arınma takibi."))
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

// MARK: - Zikirmatik

struct ZikirEntry: TimelineEntry {
  let date: Date
  let phrase: String
  let count: String
}

struct ZikirProvider: TimelineProvider {
  func placeholder(in context: Context) -> ZikirEntry {
    ZikirEntry(
      date: Date(),
      phrase: localizedWidgetText(tr: "Sübhanallah"),
      count: "33"
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (ZikirEntry) -> Void) {
    if context.isPreview {
      completion(
        ZikirEntry(
          date: Date(),
          phrase: localizedWidgetText(tr: "Sübhanallah"),
          count: "33"
        )
      )
      return
    }
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ZikirEntry>) -> Void) {
    recordWidgetFirstUse("zikir")
    let entry = loadEntry()
    let now = Date()
    // Zikir uygulamadan güncellenir.
    let next = [now.addingTimeInterval(3600), widgetGateRefreshDate("zikir")].compactMap { $0 }.min() ?? now.addingTimeInterval(3600)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func loadEntry() -> ZikirEntry {
    if widgetLocked("zikir") {
      return ZikirEntry(
        date: Date(),
        phrase: "🔒",
        count: ""
      )
    }
    
    let u = suite()
    let enabled = u?.string(forKey: "arin_zikir_enabled") == "1"
    if !enabled {
      return ZikirEntry(
        date: Date(),
        phrase: localizedWidgetText(tr: "Zikir seçilmedi"),
        count: ""
      )
    }

    let rawPhrase = u?.string(forKey: "arin_zikir_phrase")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let rawCount = u?.string(forKey: "arin_zikir_count")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"

    return ZikirEntry(
      date: Date(),
      phrase: rawPhrase.isEmpty ? localizedWidgetText(tr: "Zikir") : rawPhrase,
      count: rawCount
    )
  }
}

struct ZikirWidgetView: View {
  var entry: ZikirProvider.Entry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme

  private var primaryTextColor: Color {
    colorScheme == .dark ? Color(red: 0.88, green: 0.90, blue: 0.93) : .white
  }

  private var secondaryTextColor: Color {
    primaryTextColor.opacity(0.86)
  }

  private var textShadowOpacity: Double {
    colorScheme == .dark ? 0.34 : 0.52
  }

  private var isLocked: Bool {
    entry.phrase == "🔒"
  }

  var body: some View {
    if isLocked {
      LockedWidgetView(family: family, kindId: "zikir")
    } else {
      if family == .accessoryRectangular {
        accessoryLayout
      } else {
        expandedLayout
      }
    }
  }

  // Kilit ekranındaki (Lock Screen) çok dar yatay görünüm
  private var accessoryLayout: some View {
    HStack(spacing: 6) {
      Image(systemName: "circle.hexagonpath.fill")
        .font(.system(size: 20))
        .foregroundStyle(secondaryTextColor)
      
      VStack(alignment: .leading, spacing: 1) {
        if !entry.phrase.isEmpty {
          Text(entry.phrase)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(secondaryTextColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        if !entry.count.isEmpty {
          Text(entry.count)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(primaryTextColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(.horizontal, 4)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 2.0, x: 0, y: 1)
  }

  // Ana ekrandaki (Home Screen) normal şeffaf görünüm
  private var expandedLayout: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: "circle.hexagonpath.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 36, height: 36)
        .foregroundStyle(secondaryTextColor)

      VStack(alignment: .leading, spacing: 2) {
        if !entry.phrase.isEmpty {
          Text(entry.phrase)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(secondaryTextColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        
        if !entry.count.isEmpty {
          Text(entry.count)
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(primaryTextColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      
      // Sağdaki tıklama yuvarlağı
      Circle()
        .fill(Color(red: 0.24, green: 0.32, blue: 0.31).opacity(0.7))
        .frame(width: 44, height: 44)
        .overlay(
          Circle()
            .fill(Color.white.opacity(0.8))
            .frame(width: 10, height: 10)
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .padding(.horizontal, 10)
    .shadow(color: .black.opacity(textShadowOpacity), radius: 2.6, x: 0, y: 1)
  }
}

struct ArinZikirWidget: Widget {
  let kind: String = "ArinZikirWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ZikirProvider()) { entry in
      ZikirWidgetView(entry: entry)
        .arinTransparentWidgetSurface()
        .widgetURL(URL(string: entry.phrase == "🔒"
          ? "arin://widget/zikir?homeWidget=true&lock=1"
          : "arin://widget/zikir?homeWidget=true"))
    }
    .configurationDisplayName(localizedWidgetText(tr: "ARIN — Zikirmatik"))
    .description(localizedWidgetText(tr: "Aktif zikir ve sayaç."))
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

@main
struct ArinWidgetsBundle: WidgetBundle {
  var body: some Widget {
    ArinQuoteWidget()
    ArinPrayerWidget()
    ArinComboWidget()
    ArinTrackingWidget()
    ArinZikirWidget()
  }
}
