İyileştirici Frekanslar — ses varlıkları
========================================

**Ses çıkmıyorsa:** `assets/sounds/healing/tones/` ve `ambi/` klasörlerinde `.wav` olmalı.
Proje kökünde çalıştır: `dart run tool/generate_healing_assets.dart`
  (Bu komut `ambi_forest.wav`, `ambi_fire.wav` ve `ambi_evren.wav` dahil tüm ambiyansları yer tutucuyla yeniden yazar;
   özel kayıtlarınızı `seamless_loop_wav.dart` ile tekrar üretin.)

tones/tone_*Hz.wav
  Yerel üretim: `dart run tool/generate_healing_assets.dart`
  16 kHz mono PCM kısa sinüs döngüleri. Bu örnekleme hızı en yüksek 852 Hz tonu kayıpsız temsil eder,
  kesintisiz WAV döngüsünü korur ve 44.1 kHz'e göre dosya boyutunu azaltır.
  `generate_healing_assets.dart` içindeki ton seviyesi ambiyansla birlikte duyulacak şekilde ayarlanır;
  uzun süre dinlerken kulak rahatlığı için uygulama içi “Frekans tonu” slider’ını düşük tutun.

ambi/ambi_*.wav
  22.05 kHz mono PCM döngüler: orman, ateş, evren (pad yer tutucu).
  Gerçek ambiyans için `tool/seamless_loop_wav.dart` ile WAV veya MP3 kaynağından 60 sn döngü üretin.

Gerçek kayıt nereden? (telif / lisans)
  - Yapay zekâ ile üretilen ses: aracın kullanım şartlarına bakın; “telifsiz” varsaymayın.
  - GitHub’daki projeler (ör. ambiyans uygulamaları) genelde CC BY veya benzeri; her dosyanın LICENSE/README
    satırını okuyun; CC0 değilse atıf veya ek kısıt gerekebilir.
  - Wikimedia Commons — “Sounds of rain” kategorisi; çoğu dosyada sayfada lisans kutusu vardır (PD/CC0/CC BY…).
    https://commons.wikimedia.org/wiki/Category:Sounds_of_rain
  - Freesound — arama sonrası sol filtrede lisansı seçin; indirdiğiniz sayfadaki lisans metnini kaydedin.

Evren ambiyansı (ör. Freesound CC BY 4.0 — atıf zorunlu)
  Kaynak: Freed — “IGing_46b_The Peace.mp3”
  https://freesound.org/people/Freed/sounds/93239/
  1) Freesound’a giriş yapıp MP3’ü indirin → `tool/incoming_evren.mp3`
  2) Uygulama içi kullanım için atıf metnini (ör. Ayarlar / kredi bölümü) saklayın; CC BY 4.0 gerektirir.
  3) Ortadan 60 sn + 2 sn döngü crossfade:
     dart run tool/seamless_loop_wav.dart --input=tool/incoming_evren.mp3 --output=assets/sounds/healing/ambi/ambi_evren.wav --sample-rate=22050 --seconds=60 --crossfade-ms=2000 --skip-start-sec=0 --segment=center

`seamless_loop_wav.dart` parametreleri
  --input=...        WAV (PCM 16 LE), MP3 veya AIFF/AIFC (PCM 16 BE, SSND)
  --output=...       Çıkış mono WAV
  --sample-rate=22050   Çıkış örnekleme hızı; boyut optimizasyonunu korumak için varsayılan 22050
  --seconds=60       Kesit süresi
  --crossfade-ms=2000   Döngü başı/sonu birleşiminde raised-cosine (önerilen 2000)
  --mid-crossfade-ms=0  >0 ise: çıktıyı iki yarıya böler (ör. 30+30 sn), ortada bu süreyle yumuşak birleştirir
  --skip-start-sec=0    Kaynak başından atlanacak süre (saniye)
  --segment=start|center   center: mümkünse ortadan [seconds]+mid-crossfade kadar kesit
  --edge-ms=0        İsteğe bağlı uç rampa

Ateş (şömine) — ör. Freesound silencyo CC … (sayfadan lisansı doğrulayın)
  https://freesound.org/people/silencyo/sounds/81801/
  Ortadan 60 sn, döngü 2 sn, ortada (≈30 sn) ek 2 sn geçiş:
     dart run tool/seamless_loop_wav.dart --input=tool/incoming_fire.aiff --output=assets/sounds/healing/ambi/ambi_fire.wav --sample-rate=22050 --seconds=60 --crossfade-ms=2000 --mid-crossfade-ms=2000 --skip-start-sec=0 --segment=center

Orman ambiyansı (örnek: Freesound audiomirage — 850140; sayfada lisansı kontrol edin; NC ise ticari uygulamada kullanılamaz)
  https://freesound.org/people/audiomirage/sounds/850140/
  Ortadan 60 sn + 2 sn döngü:
     dart run tool/seamless_loop_wav.dart --input=tool/incoming_forest.wav --output=assets/sounds/healing/ambi/ambi_forest.wav --sample-rate=22050 --seconds=60 --crossfade-ms=2000 --skip-start-sec=0 --segment=center

Tıbbi iddia yoktur; bu özellik rahatlama amaçlıdır.
