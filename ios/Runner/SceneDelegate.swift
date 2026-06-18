import Flutter
import UIKit

/// UIScene tabanlı uygulamada widget derin linklerini yakalar.
///
/// `home_widget` plugin'i widget URL'lerini yalnızca eski `UIApplicationDelegate`
/// metotları (`application(_:open:)` / `didFinishLaunchingWithOptions`) üzerinden
/// okur. Bu uygulama UIScene yaşam döngüsü kullandığından o metotlar HİÇ
/// çağrılmaz; dolayısıyla `widgetURL`/`Link` ile gelen `arin://widget/...`
/// derin linkleri plugin'e ulaşmaz ve uygulama yalnızca ana sayfada açılırdı.
///
/// Çözüm: widget URL'sini burada (doğru scene callback'lerinde) yakalayıp App
/// Group UserDefaults'a yazıyoruz. Flutter tarafı (`WidgetLaunchGateListener`)
/// açılış/resume'da bu anahtarı okuyup ilgili sayfaya (Zikirmatik vb.)
/// yönlendiriyor.
class SceneDelegate: FlutterSceneDelegate {
  private static let appGroupId = "group.com.arin.arin"
  private static let pendingUriKey = "arin_pending_widget_launch_uri"

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    capture(connectionOptions.urlContexts)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    capture(URLContexts)
  }

  private func capture(_ contexts: Set<UIOpenURLContext>) {
    for context in contexts {
      let url = context.url
      guard url.scheme == "arin", url.host == "widget" else { continue }
      UserDefaults(suiteName: Self.appGroupId)?
        .set(url.absoluteString, forKey: Self.pendingUriKey)
    }
  }
}
