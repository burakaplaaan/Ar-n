# ARIN — Google Play .aab paketi (mağaza yüklemesi).
# Çıktı: build\app\outputs\bundle\release\app-release.aab
# Kullanım: .\tool\build_appbundle.ps1

Set-Location $PSScriptRoot\..
$cid = "746942620456-lm0rg914v26s3u2io9pif08vu24jfor0.apps.googleusercontent.com"
flutter build appbundle --release --dart-define=GOOGLE_OAUTH_WEB_CLIENT_ID=$cid
