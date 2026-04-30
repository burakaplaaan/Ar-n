//
//  ARIN — iki widget (söz + namaz). Veri: App Group UserDefaults (home_widget / Flutter).
//  Kilit ekranı: accessoryRectangular — iOS önizlemesine yakın kompakt düzen.
//

import SwiftUI
import WidgetKit

private let kGroupId = "group.com.arin.arin"

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
    QuoteEntry(
      date: Date(),
      text: text,
      source: source
    )
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
    case .accessoryRectangular, .systemSmall:
      quoteCompact
    default:
      quoteExpanded
    }
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
        .lineSpacing(0)
        .lineLimit(2)
        .minimumScaleFactor(0.78)
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
        .lineSpacing(1)
        .lineLimit(2)
        .minimumScaleFactor(0.82)
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
}

struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    PrayerEntry(
      date: Date(),
      location: "—",
      nextName: localizedWidgetText(tr: "İmsak"),
      countdown: "0:15:00"
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
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
    var countdown = sanitizeCountdown(u?.string(forKey: "arin_prayer_countdown") ?? "—")
    if let epochStr = u?.string(forKey: "arin_prayer_next_epoch_ms"),
       let epochMs = Double(epochStr) {
      let rem = max(0, epochMs / 1000.0 - Date().timeIntervalSince1970)
      countdown = formatHMS(seconds: rem)
    }
    return PrayerEntry(
      date: Date(),
      location: "Konum",
      nextName: nextName,
      countdown: countdown
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
        Text(entry.countdown)
          .font(.system(size: 21, weight: .semibold, design: .serif))
          .foregroundStyle(primaryTextColor)
          .monospacedDigit()
          .minimumScaleFactor(0.85)
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
        Text(entry.countdown)
          .font(.system(size: 26, weight: .semibold, design: .serif))
          .foregroundStyle(primaryTextColor)
          .monospacedDigit()
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
