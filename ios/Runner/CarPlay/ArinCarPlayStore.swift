import Foundation

enum ArinCarPlayStore {
  static let groupId = "group.com.arin.arin"
  static let speakKey = "arin_carplay_speak"
  static let autoListenKey = "arin_carplay_autolisten"

  private static var suite: UserDefaults? {
    UserDefaults(suiteName: groupId)
  }

  static var isPremium: Bool {
    suite?.string(forKey: "arin_widget_gate_premium") == "1"
  }

  static var speakEnabled: Bool {
    get { suite?.object(forKey: speakKey) as? Bool ?? true }
    set { suite?.set(newValue, forKey: speakKey) }
  }

  static var autoListen: Bool {
    get { suite?.object(forKey: autoListenKey) as? Bool ?? true }
    set { suite?.set(newValue, forKey: autoListenKey) }
  }

  static var nextPrayerName: String {
    (suite?.string(forKey: "arin_prayer_next_name") ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static var nextPrayerClock: String {
    (suite?.string(forKey: "arin_prayer_next_clock") ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static var quoteText: String {
    (suite?.string(forKey: "arin_quote_text") ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static var quoteSource: String {
    (suite?.string(forKey: "arin_quote_source") ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static func glanceLine() -> String {
    let name = nextPrayerName
    let clock = nextPrayerClock
    if !name.isEmpty, !clock.isEmpty {
      return "Sıradaki \(name), \(clock)."
    }
    if !name.isEmpty {
      return "Sıradaki \(name)."
    }
    if !quoteText.isEmpty {
      return quoteText
    }
    return "Selamün aleyküm."
  }
}
