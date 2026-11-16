import CarPlay
import Flutter
import MediaPlayer
import UIKit

/// Araçta Kur'an: açılınca kaldığın ayet, başlatınca sırayla tilavet.
final class ArinCarPlaySession: NSObject {
  private let interface: CPInterfaceController
  private var tabs: CPTabBarTemplate?
  private var surahList: CPListTemplate?
  private var catalogReady = false
  private var greeted = false
  private var pending: [(String, Any?)] = []
  private var installed: [(MPRemoteCommand, Any)] = []
  private var artKey = ""
  private var artImage: UIImage?

  init(interfaceController: CPInterfaceController) {
    interface = interfaceController
    super.init()
  }

  func start() {
    ArinCarPlayBridge.session = self
    installCommands()
    presentRoot()
    publishPlaceholder()
    notifyDartIfNeeded()
  }

  func stop() {
    greeted = false
    pending.removeAll()
    uninstallCommands()
    if ArinCarPlayBridge.session === self {
      ArinCarPlayBridge.session = nil
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    ArinCarPlayBridge.emit("disconnected")
  }

  func notifyDartIfNeeded() {
    guard ArinCarPlayBridge.dartReady, ArinCarPlayBridge.channel != nil else { return }
    let first = !greeted
    greeted = true
    ArinCarPlayBridge.emit("connected") { [weak self] value in
      guard let map = value as? [String: Any] else { return }
      DispatchQueue.main.async {
        self?.apply(map)
      }
    }
    guard first else { return }
    let queued = pending
    pending.removeAll()
    for item in queued {
      ArinCarPlayBridge.emit(item.0, arguments: item.1)
    }
  }

  func apply(_ map: [String: Any]) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in self?.apply(map) }
      return
    }
    updateNowPlaying(map)
    if let title = map["listTitle"] as? String, !title.isEmpty {
      surahList?.tabTitle = title
    }
    if !catalogReady, map["surahs"] != nil {
      rebuildSurahs(map)
    }
  }

  private func presentRoot() {
    let now = CPNowPlayingTemplate.shared
    now.tabTitle = "Kur'an"
    now.tabImage = UIImage(systemName: "book.closed")

    let waiting = CPListItem(text: "Kur'an", detailText: nil)
    waiting.handler = { _, completion in completion() }
    let list = CPListTemplate(title: "Sureler", sections: [CPListSection(items: [waiting])])
    list.tabTitle = "Sureler"
    list.tabImage = UIImage(systemName: "list.bullet")
    surahList = list

    let bar = CPTabBarTemplate(templates: [now, list])
    tabs = bar
    interface.setRootTemplate(bar, animated: false, completion: nil)
  }

  private func publishPlaceholder() {
    let defaults = UserDefaults.standard
    var surah = defaults.integer(forKey: "flutter.quran_last_surah")
    var ayah = defaults.integer(forKey: "flutter.quran_last_ayah")
    if surah < 1 || surah > 114 { surah = 1 }
    if ayah < 1 { ayah = 1 }
    apply([
      "surah": surah,
      "ayah": ayah,
      "name": "Kur'an",
      "line": "Sure \(surah) · \(ayah). ayet",
      "ayahLine": "\(ayah). ayet",
      "reciter": "Mişari Raşid el-Afasi",
      "title": "Kur'an",
      "playing": false,
      "error": false,
    ])
  }

  private func updateNowPlaying(_ map: [String: Any]) {
    let surah = intValue(map["surah"]) ?? 1
    let ayah = intValue(map["ayah"]) ?? 1
    let name = (map["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let title = (name?.isEmpty == false ? name! : nil) ?? "Kur'an"
    let line = (map["line"] as? String) ?? "\(title) · \(ayah)"
    let playing = boolValue(map["playing"])
    let failed = boolValue(map["error"])
    let reciter = (map["reciter"] as? String) ?? "Kur'an"
    let album = (map["title"] as? String) ?? "Kur'an"
    let verse = (map["verse"] as? String) ?? ""
    let artist = failed ? ((map["errorText"] as? String) ?? reciter) : reciter

    let key = "\(surah)|\(ayah)|\(verse)"
    if artKey != key || artImage == nil {
      artKey = key
      artImage = renderCard(title: title, line: line, verse: verse)
    }

    var info: [String: Any] = [
      MPMediaItemPropertyTitle: line,
      MPMediaItemPropertyArtist: artist,
      MPMediaItemPropertyAlbumTitle: album,
      MPNowPlayingInfoPropertyPlaybackRate: (playing && !failed) ? 1.0 : 0.0,
    ]
    if let image = artImage {
      info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
        boundsSize: image.size
      ) { _ in image }
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  private func rebuildSurahs(_ map: [String: Any]) {
    guard let rows = map["surahs"] as? [[String: Any]], !rows.isEmpty else { return }
    guard let list = surahList else { return }
    var groups: [CPListItem] = []
    var index = 0
    let pageSize = 12
    while index < rows.count {
      let end = min(index + pageSize, rows.count)
      let slice = Array(rows[index..<end])
      let firstNumber = intValue(slice.first?["n"]) ?? (index + 1)
      let lastNumber = intValue(slice.last?["n"]) ?? end
      let firstName = (slice.first?["name"] as? String) ?? ""
      let lastName = (slice.last?["name"] as? String) ?? ""
      let item = CPListItem(
        text: "\(firstNumber)–\(lastNumber)",
        detailText: lastName.isEmpty ? firstName : "\(firstName) · \(lastName)"
      )
      item.handler = { [weak self] _, completion in
        self?.pushSurahs(slice)
        completion()
      }
      groups.append(item)
      index = end
    }
    guard !groups.isEmpty else { return }
    list.updateSections([CPListSection(items: groups)])
    catalogReady = true
  }

  private func pushSurahs(_ rows: [[String: Any]]) {
    var items: [CPListItem] = []
    items.reserveCapacity(rows.count)
    for row in rows {
      guard let number = intValue(row["n"]) else { continue }
      let name = (row["name"] as? String) ?? "\(number)"
      let countLabel = (row["countLabel"] as? String) ?? ""
      let arabic = (row["arabic"] as? String) ?? ""
      let detail = arabic.isEmpty ? countLabel : "\(arabic) · \(countLabel)"
      let item = CPListItem(text: "\(number). \(name)", detailText: detail)
      item.handler = { [weak self] _, completion in
        self?.send("playSurah", ["surah": number])
        self?.showNowPlaying()
        completion()
      }
      items.append(item)
    }
    guard !items.isEmpty else { return }
    let page = CPListTemplate(
      title: surahList?.tabTitle ?? "Sureler",
      sections: [CPListSection(items: items)]
    )
    interface.pushTemplate(page, animated: true, completion: nil)
  }

  private func showNowPlaying() {
    tabs?.selectedTemplate = CPNowPlayingTemplate.shared
  }

  private func renderCard(title: String, line: String, verse: String) -> UIImage {
    let size = CGSize(width: 600, height: 600)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
      UIColor(red: 0.07, green: 0.11, blue: 0.09, alpha: 1).setFill()
      UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

      let titleStyle = NSMutableParagraphStyle()
      titleStyle.alignment = .center
      let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 44, weight: .semibold),
        .foregroundColor: UIColor(red: 0.86, green: 0.74, blue: 0.46, alpha: 1),
        .paragraphStyle: titleStyle,
      ]
      let titleRect = CGRect(x: 36, y: 48, width: 528, height: 64)
      title.draw(in: titleRect, withAttributes: titleAttrs)

      let lineStyle = NSMutableParagraphStyle()
      lineStyle.alignment = .center
      let lineAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 26, weight: .medium),
        .foregroundColor: UIColor(white: 1, alpha: 0.82),
        .paragraphStyle: lineStyle,
      ]
      line.draw(in: CGRect(x: 36, y: 120, width: 528, height: 40), withAttributes: lineAttrs)

      if !verse.isEmpty {
        let verseStyle = NSMutableParagraphStyle()
        verseStyle.alignment = .center
        verseStyle.lineBreakMode = .byWordWrapping
        let verseAttrs: [NSAttributedString.Key: Any] = [
          .font: UIFont.systemFont(ofSize: 32, weight: .regular),
          .foregroundColor: UIColor.white,
          .paragraphStyle: verseStyle,
        ]
        verse.draw(
          in: CGRect(x: 40, y: 190, width: 520, height: 360),
          withAttributes: verseAttrs
        )
      }
    }
  }

  private func installCommands() {
    UIApplication.shared.beginReceivingRemoteControlEvents()
    let center = MPRemoteCommandCenter.shared()
    bind(center.playCommand, "play")
    bind(center.pauseCommand, "pause")
    bind(center.togglePlayPauseCommand, "toggle")
    bind(center.nextTrackCommand, "next")
    bind(center.previousTrackCommand, "previous")
  }

  private func bind(_ command: MPRemoteCommand, _ method: String) {
    command.isEnabled = true
    let token = command.addTarget { [weak self] _ in
      self?.send(method)
      return .success
    }
    installed.append((command, token))
  }

  private func uninstallCommands() {
    for (command, token) in installed {
      command.removeTarget(token)
      command.isEnabled = false
    }
    installed.removeAll()
    UIApplication.shared.endReceivingRemoteControlEvents()
  }

  private func send(_ method: String, _ args: Any? = nil) {
    guard greeted else {
      pending.append((method, args))
      return
    }
    ArinCarPlayBridge.emit(method, arguments: args)
  }

  private func intValue(_ any: Any?) -> Int? {
    if let value = any as? Int { return value }
    if let value = any as? NSNumber { return value.intValue }
    return nil
  }

  private func boolValue(_ any: Any?) -> Bool {
    if let value = any as? Bool { return value }
    if let value = any as? NSNumber { return value.boolValue }
    return false
  }
}

enum ArinCarPlayBridge {
  static var channel: FlutterMethodChannel?
  static var dartReady = false
  static weak var session: ArinCarPlaySession?

  static func emit(
    _ method: String,
    arguments: Any? = nil,
    result: FlutterResult? = nil
  ) {
    channel?.invokeMethod(method, arguments: arguments, result: result)
  }
}
