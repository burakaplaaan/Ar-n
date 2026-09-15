import AVFoundation
import Foundation
import Speech

/// Arabada dinle / Siri sesiyle konuş. Ses dosyası sunucuya gitmez.
final class ArinCarPlayVoice: NSObject, SFSpeechRecognizerDelegate {
  private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
    ?? SFSpeechRecognizer()
  private let synthesizer = AVSpeechSynthesizer()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private let engine = AVAudioEngine()
  private var speakDone: (() -> Void)?

  override init() {
    super.init()
    synthesizer.delegate = self
    recognizer?.delegate = self
  }

  func startListening(
    onPartial: @escaping (String) -> Void,
    onFinal: @escaping (String) -> Void,
    onError: @escaping (String) -> Void
  ) {
    stopListening()
    SFSpeechRecognizer.requestAuthorization { [weak self] status in
      DispatchQueue.main.async {
        guard let self else { return }
        guard status == .authorized, let recognizer = self.recognizer, recognizer.isAvailable else {
          onError("Mikrofon izni gerekli.")
          return
        }
        self.beginEngine(onPartial: onPartial, onFinal: onFinal, onError: onError)
      }
    }
  }

  func stopListening() {
    if engine.isRunning {
      engine.stop()
      engine.inputNode.removeTap(onBus: 0)
    }
    request?.endAudio()
    task?.cancel()
    task = nil
    request = nil
  }

  func speak(_ text: String, completion: @escaping () -> Void) {
    stopSpeaking()
    let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !clean.isEmpty else {
      completion()
      return
    }
    speakDone = completion
    activateSession(record: false)
    let utterance = AVSpeechUtterance(string: clean)
    utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
      ?? AVSpeechSynthesisVoice(language: "tr")
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.94
    utterance.pitchMultiplier = 0.98
    synthesizer.speak(utterance)
  }

  func stopSpeaking() {
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }
    speakDone = nil
  }

  func shutdown() {
    stopListening()
    stopSpeaking()
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func beginEngine(
    onPartial: @escaping (String) -> Void,
    onFinal: @escaping (String) -> Void,
    onError: @escaping (String) -> Void
  ) {
    do {
      activateSession(record: true)
      let request = SFSpeechAudioBufferRecognitionRequest()
      request.shouldReportPartialResults = true
      if recognizer?.supportsOnDeviceRecognition == true {
        request.requiresOnDeviceRecognition = true
      }
      self.request = request

      let input = engine.inputNode
      let format = input.outputFormat(forBus: 0)
      input.removeTap(onBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
        self?.request?.append(buffer)
      }

      task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
        guard let self else { return }
        if let result {
          let spoken = result.bestTranscription.formattedString
            .trimmingCharacters(in: .whitespacesAndNewlines)
          if result.isFinal {
            self.stopListening()
            onFinal(spoken)
          } else {
            onPartial(spoken)
          }
          return
        }
        if error != nil {
          self.stopListening()
          onError("Seni duyamadım.")
        }
      }

      engine.prepare()
      try engine.start()
    } catch {
      onError("Mikrofon açılamadı.")
    }
  }

  private func activateSession(record: Bool) {
    let session = AVAudioSession.sharedInstance()
    do {
      if record {
        try session.setCategory(.playAndRecord, mode: .default, options: [])
      } else {
        try session.setCategory(.playback, mode: .spokenAudio, options: [])
      }
      try session.setActive(true, options: [])
    } catch {
      // CarPlay oturumu yine de denensin.
    }
  }
}

extension ArinCarPlayVoice: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didFinish utterance: AVSpeechUtterance
  ) {
    let done = speakDone
    speakDone = nil
    done?()
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didCancel utterance: AVSpeechUtterance
  ) {
    speakDone = nil
  }
}

enum ArinCarPlayBridge {
  static var ask: ((String, @escaping (String) -> Void) -> Void)?
}
