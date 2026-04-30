import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
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
