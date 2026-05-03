//
//  ARIN — iki widget (söz + namaz). Veri: App Group UserDefaults (home_widget / Flutter).
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
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
    if let timeline = loadScheduledTimeline() {
      completion(timeline)
      return
    }
    let e = loadEntry()
    let next = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(21_600)
    completion(Timeline(entries: [e], policy: .after(next)))
  }

  private func loadEntry() -> QuoteEntry {
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
    let emittedFuture = Array(future.prefix(kQuoteTimelineFutureLimit))
    entries.append(
      contentsOf: emittedFuture.map {
        QuoteEntry(
          date: $0.date,
          text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines),
          source: $0.source.trimmingCharacters(in: .whitespacesAndNewlines)
        )
      }
    )
    let refresh = emittedFuture.last?.date.addingTimeInterval(1_800) ?? now.addingTimeInterval(21_600)
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

  var body: some View {
    switch family {
    case .accessoryRectangular:
      quoteAccessory
    case .systemSmall:
      quoteCompact
    default:
      quoteExpanded
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
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    if let timeline = loadScheduledTimeline() {
      completion(timeline)
      return
    }
    let e = loadEntry()
    // iOS WidgetKit'te saniyelik zorlamadan kaçın: pil-dostu, dakikalık tazeleme.
    let nextFire = Date().addingTimeInterval(60)
    completion(Timeline(entries: [e], policy: .after(nextFire)))
  }

  private func loadEntry() -> PrayerEntry {
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
      return Timeline(entries: [stale], policy: .after(now.addingTimeInterval(21_600)))
    }

    var entries = [entry(at: now, next: sorted[firstNextIndex])]
    if firstNextIndex + 1 < sorted.count {
      let endExclusive = min(sorted.count, firstNextIndex + 1 + kPrayerTimelineFutureLimit)
      for index in (firstNextIndex + 1)..<endExclusive {
        entries.append(
          entry(
            at: sorted[index - 1].date.addingTimeInterval(1),
            next: sorted[index]
          )
        )
      }
    }
    let refresh = entries.last?.date.addingTimeInterval(3600) ?? now.addingTimeInterval(3600)
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

  var body: some View {
    switch family {
    case .accessoryRectangular, .systemSmall:
      prayerCompact
    default:
      prayerExpanded
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
      Text(entry.location)
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .foregroundStyle(secondaryTextColor)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
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
      Text(entry.location)
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(secondaryTextColor)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
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
    }
    .configurationDisplayName(localizedWidgetText(tr: "ARIN — Namaz"))
    .description(localizedWidgetText(tr: "Sıradaki vakit ve geri sayım."))
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

@main
struct ArinWidgetsBundle: WidgetBundle {
  var body: some Widget {
    ArinQuoteWidget()
    ArinPrayerWidget()
  }
}
