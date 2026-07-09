// Meta (Facebook) App Events kimlikleri.
// App ID: Events Manager / developers.facebook.com → Uygulama ayarları.
// Client Token: developers.facebook.com → Uygulama → Ayarlar → Gelişmiş → Client Token.
//
// Client Token boş bırakılırsa Meta SDK başlatılmaz (reklam ölçümü çalışmaz).

abstract final class MetaAdsIds {
  static const String appId = '4451380661797719';

  /// developers.facebook.com → Arın uygulaması → Ayarlar → Gelişmiş → Client Token
  /// Değer geldiğinde buraya yapıştır; boşsa Meta App Events no-op kalır.
  static const String clientToken = 'c150203bf357ef5e115b4012e9c55b98';

  static const String displayName = 'Arın';

  static bool get isConfigured =>
      appId.isNotEmpty && clientToken.trim().isNotEmpty;
}
