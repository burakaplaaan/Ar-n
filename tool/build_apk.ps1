# ARIN — APK derle (Windows’ta çalıştırılacak uygulama değil; telefona yüklenir).
# Çıktı: build\app\outputs\flutter-apk\app-release.apk
# Kullanım: .\tool\build_apk.ps1          → release APK
#           .\tool\build_apk.ps1 debug    → debug APK (daha hızlı test)

param(
  [string]$Mode = "release"
)

Set-Location $PSScriptRoot\..
$cid = "746942620456-lm0rg914v26s3u2io9pif08vu24jfor0.apps.googleusercontent.com"
$define = "--dart-define=GOOGLE_OAUTH_WEB_CLIENT_ID=$cid"

if ($Mode -eq "debug") {
  flutter build apk --debug $define
} else {
  flutter build apk --release --tree-shake-icons $define
}
