import Flutter
import CoreLocation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var compassStreamHandler: ArinCompassStreamHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    // ─────────────────────────────────────────────────────────────────
    // Keşfet derin Stories paylaşım kanalı.
    //
    // Genel paylaşım (share sheet) artık Flutter tarafında `share_plus`
    // ile yapılıyor. Bu kanal sadece:
    //   • shareToInstagramStories — instagram-stories://share URL scheme
    //     + com.instagram.sharedSticker.backgroundImage pasteboard item
    //   • shareToFacebookStories  — facebook-stories://share URL scheme
    //
    // Info.plist → LSApplicationQueriesSchemes içinde
    // "instagram-stories" ve "facebook-stories" tanımlı olmalı;
    // aksi halde canOpenURL her zaman false döner.
    // ─────────────────────────────────────────────────────────────────
    let storiesChannel = FlutterMethodChannel(
      name: "com.arin.arin/kesfet_share",
      binaryMessenger: messenger
    )
    storiesChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "shareToInstagramStories":
        guard let path = call.arguments as? String, !path.isEmpty else {
          result(FlutterError(code: "bad_args", message: "path missing", details: nil))
          return
        }
        Self.openStoriesUrl(
          path: path,
          scheme: "instagram-stories",
          stickerKey: "com.instagram.sharedSticker.backgroundImage",
          result: result
        )
      case "shareToFacebookStories":
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String, !path.isEmpty else {
          result(FlutterError(code: "bad_args", message: "path missing", details: nil))
          return
        }
        let appId = (args["appId"] as? String) ?? ""
        Self.openStoriesUrl(
          path: path,
          scheme: "facebook-stories",
          stickerKey: "com.facebook.sharedSticker.backgroundImage",
          appId: appId,
          result: result
        )
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let compassHandler = ArinCompassStreamHandler()
    compassStreamHandler = compassHandler
    FlutterEventChannel(
      name: "com.arin.arin/rotation_compass",
      binaryMessenger: messenger
    ).setStreamHandler(compassHandler)

    FlutterMethodChannel(
      name: "com.arin.arin/compass_geomagnetic",
      binaryMessenger: messenger
    ).setMethodCallHandler { call, result in
      switch call.method {
      case "update":
        // iOS CLLocationManager already exposes trueHeading when available;
        // Dart keeps this channel for Android parity.
        result(0.0)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // ─── Stories derin paylaşım helper ──────────────────────────────────
  private static func openStoriesUrl(
    path: String,
    scheme: String,
    stickerKey: String,
    appId: String = "",
    result: @escaping FlutterResult
  ) {
    guard FileManager.default.fileExists(atPath: path) else {
      result(FlutterError(code: "not_found", message: path, details: nil))
      return
    }

    var urlString = "\(scheme)://share"
    if !appId.isEmpty {
      urlString += "?source_application=\(appId)"
    }
    guard let url = URL(string: urlString) else {
      result(FlutterError(code: "share_failed", message: "bad_url", details: nil))
      return
    }

    let app = UIApplication.shared
    guard app.canOpenURL(url) else {
      result(FlutterError(code: "not_installed", message: scheme, details: nil))
      return
    }

    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
      result(FlutterError(code: "read_failed", message: path, details: nil))
      return
    }

    // Stories için standart pasteboard kontratı — Instagram & Facebook.
    let pasteboardItems: [[String: Any]] = [[
      stickerKey: data
    ]]
    let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
      .expirationDate: Date().addingTimeInterval(60 * 5)
    ]
    UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)

    DispatchQueue.main.async {
      app.open(url, options: [:]) { ok in
        result(ok)
      }
    }
  }
}

final class ArinCompassStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?

  override init() {
    super.init()
    manager.delegate = self
    manager.headingFilter = 1
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    guard CLLocationManager.headingAvailable() else {
      events(FlutterError(code: "heading_unavailable", message: "Compass heading is unavailable on this device.", details: nil))
      return nil
    }
    manager.startUpdatingHeading()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    sink = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    let trueHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    let normalized = fmod(trueHeading + 360.0, 360.0)
    sink?([
      "heading": normalized,
      "rawHeading": normalized,
      "pitch": 0.0,
      "roll": 0.0,
      "accuracy": Int(newHeading.headingAccuracy),
      "jitter": 0.0,
      "stable": newHeading.headingAccuracy >= 0 && newHeading.headingAccuracy <= 35,
      "guidance": (newHeading.headingAccuracy >= 0 && newHeading.headingAccuracy <= 35) ? "good" : "calibrate"
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    sink?(FlutterError(code: "heading_error", message: error.localizedDescription, details: nil))
  }
}
