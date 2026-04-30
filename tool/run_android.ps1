# ARIN — Android cihaz veya emülatörde Google ile giriş için.
# Önce: Android Studio → Device Manager → emülatör başlat VEYA USB ile telefon bağla.
# Kullanım: .\tool\run_android.ps1

Set-Location $PSScriptRoot\..
$cid = "746942620456-lm0rg914v26s3u2io9pif08vu24jfor0.apps.googleusercontent.com"
flutter devices
flutter run -d android --dart-define=GOOGLE_OAUTH_WEB_CLIENT_ID=$cid
