# FlutterFire CLI — PATH'e eklemeden çalıştırma (Windows).
# Kullanım: proje kökünde  .\tool\flutterfire_configure.ps1

Set-Location $PSScriptRoot\..
dart pub global run flutterfire_cli:flutterfire configure
