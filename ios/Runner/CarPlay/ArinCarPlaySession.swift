import CarPlay
import Foundation

/// CarPlay kökü: premium kilit, Hilal'de Bas konuş, iki satır ayar.
final class ArinCarPlaySession: NSObject {
  private let interface: CPInterfaceController
  private let voice = ArinCarPlayVoice()
  private var voiceTemplate: CPVoiceControlTemplate?
  private var lastStateAt = Date.distantPast

  init(interfaceController: CPInterfaceController) {
    interface = interfaceController
    super.init()
  }

  func start() {
    if ArinCarPlayStore.isPremium {
      presentTabs()
    } else {
      presentLock()
    }
  }

  func stop() {
    voice.shutdown()
    voiceTemplate = nil
  }

  private func presentLock() {
    let item = CPInformationItem(
      title: "Kilitli",
      detail: "Arabada Hilal yalnızca Premium ile konuşur."
    )
    let template = CPInformationTemplate(
      title: "Arın",
      layout: .leading,
      items: [item],
      actions: []
    )
    interface.setRootTemplate(template, animated: false, completion: nil)
  }

  private func presentTabs() {
    let tabs = CPTabBarTemplate(templates: [makeHilalTemplate(), makeSettingsTemplate()])
    tabs.delegate = self
    interface.setRootTemplate(tabs, animated: false) { [weak self] _, _ in
      if ArinCarPlayStore.autoListen {
        self?.pushVoiceAndListen()
      }
    }
  }

  private func makeHilalTemplate() -> CPInformationTemplate {
    let glance = CPInformationItem(
      title: "Hilal",
      detail: ArinCarPlayStore.glanceLine()
    )
    let talk = CPTextButton(title: "Bas konuş", textStyle: .confirm) { [weak self] _ in
      self?.pushVoiceAndListen()
    }
    let template = CPInformationTemplate(
      title: "Hilal",
      layout: .leading,
      items: [glance],
      actions: [talk]
    )
    template.tabTitle = "Hilal"
    template.tabImage = UIImage(systemName: "moon.stars")
    return template
  }

  private func makeVoiceTemplate() -> CPVoiceControlTemplate {
    let states: [CPVoiceControlState] = [
      CPVoiceControlState(
        identifier: ArinHilalOrb.State.idle.rawValue,
        titleVariants: ["Bas konuş", "Konuş"],
        image: ArinHilalOrb.image(for: .idle),
        repeats: true
      ),
      CPVoiceControlState(
        identifier: ArinHilalOrb.State.listening.rawValue,
        titleVariants: ["Dinliyorum", "Konuş"],
        image: ArinHilalOrb.image(for: .listening),
        repeats: true
      ),
      CPVoiceControlState(
        identifier: ArinHilalOrb.State.thinking.rawValue,
        titleVariants: ["Düşünüyorum", "Bir saniye"],
        image: ArinHilalOrb.image(for: .thinking),
        repeats: true
      ),
      CPVoiceControlState(
        identifier: ArinHilalOrb.State.speaking.rawValue,
        titleVariants: ["Hilal", "Dinle"],
        image: ArinHilalOrb.image(for: .speaking),
        repeats: true
      ),
    ]
    return CPVoiceControlTemplate(voiceControlStates: states)
  }

  private func makeSettingsTemplate() -> CPListTemplate {
    let speak = CPListItem(
      text: "Sesli cevap",
      detailText: ArinCarPlayStore.speakEnabled ? "Açık — Siri sesi" : "Kapalı"
    )
    speak.handler = { [weak self] _, done in
      ArinCarPlayStore.speakEnabled.toggle()
      self?.reloadSettings()
      done()
    }
    let auto = CPListItem(
      text: "Açılınca dinle",
      detailText: ArinCarPlayStore.autoListen ? "Açık" : "Kapalı — Bas konuş"
    )
    auto.handler = { [weak self] _, done in
      ArinCarPlayStore.autoListen.toggle()
      self?.reloadSettings()
      done()
    }
    let section = CPListSection(items: [speak, auto])
    let template = CPListTemplate(title: "Ayarlar", sections: [section])
    template.tabTitle = "Ayarlar"
    template.tabImage = UIImage(systemName: "slider.horizontal.3")
    return template
  }

  private func reloadSettings() {
    guard let tabs = interface.rootTemplate as? CPTabBarTemplate,
          tabs.templates.count > 1
    else { return }
    var all = tabs.templates
    all[1] = makeSettingsTemplate()
    tabs.updateTemplates(all)
  }

  private func pushVoiceAndListen() {
    guard ArinCarPlayStore.isPremium else {
      presentLock()
      return
    }
    if voiceTemplate != nil {
      listen()
      return
    }
    let next = makeVoiceTemplate()
    voiceTemplate = next
    interface.pushTemplate(next, animated: true) { [weak self] success, _ in
      if success {
        self?.listen()
      } else {
        self?.voiceTemplate = nil
      }
    }
  }

  private func listen() {
    applyState(.listening)
    voice.startListening { [weak self] partial in
      guard !partial.isEmpty else { return }
      self?.applyState(.listening)
    } onFinal: { [weak self] spoken in
      self?.handleSpoken(spoken)
    } onError: { [weak self] message in
      self?.say(message)
    }
  }

  private func handleSpoken(_ spoken: String) {
    let text = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty {
      applyState(.idle)
      return
    }
    applyState(.thinking)
    if let ask = ArinCarPlayBridge.ask {
      ask(text) { [weak self] reply in
        guard let self else { return }
        let spoken = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        self.say(spoken.isEmpty ? self.localFallback(for: text) : spoken)
      }
    } else {
      say(localFallback(for: text))
    }
  }

  private func say(_ reply: String) {
    let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else {
      applyState(.idle)
      return
    }
    applyState(.speaking)
    if ArinCarPlayStore.speakEnabled {
      voice.speak(text) { [weak self] in
        guard let self else { return }
        self.applyState(.idle)
        if ArinCarPlayStore.autoListen {
          self.listen()
        }
      }
    } else {
      applyState(.idle)
    }
  }

  private func localFallback(for text: String) -> String {
    let folded = text.lowercased(with: Locale(identifier: "tr_TR"))
    if folded.contains("ayet") || folded.contains("söz") {
      let verse = ArinCarPlayStore.quoteText
      let source = ArinCarPlayStore.quoteSource
      if !verse.isEmpty {
        return source.isEmpty ? verse : "\(source). \(verse)"
      }
    }
    return ArinCarPlayStore.glanceLine()
  }

  private func applyState(_ state: ArinHilalOrb.State) {
    let now = Date()
    if now.timeIntervalSince(lastStateAt) < 0.35 { return }
    lastStateAt = now
    voiceTemplate?.activateVoiceControlState(withIdentifier: state.rawValue)
  }
}

extension ArinCarPlaySession: CPTabBarTemplateDelegate {
  func tabBarTemplate(
    _ tabBarTemplate: CPTabBarTemplate,
    didSelect selectedTemplate: CPTemplate
  ) {
    if selectedTemplate is CPInformationTemplate {
      return
    }
    voice.stopListening()
    voice.stopSpeaking()
    if voiceTemplate != nil {
      voiceTemplate = nil
      interface.popTemplate(animated: true, completion: nil)
    }
  }
}
