# Dua Halkası yayın kontrol listesi

Dua Halkası güvenlik nedeniyle eksik yapılandırmada **fail-closed** çalışır:
ücretsiz talep SSV doğrulanmadan oluşturulmaz ve sunucunun kurulum için ürettiği
Firebase özel oturumu kurulmadan hiçbir topluluk çağrısı kabul edilmez.

## Zorunlu konsol ayarları

1. Aşağıdaki Dua Halkası Cloud Function'larının tamamı yayınlanmalı:
   `createPrayerSession`, `checkPrayerPremium`, `beginPrayerSubmission`,
   `createPrayerRequest`,
   `listPrayerRequests`, `prayForRequest`, `deletePrayerRequest`,
   `reportPrayerRequest`, `registerPrayerDevice`, `rewardedAdSsv`,
   `deliverPrayerNotifications` ve `cleanupExpiredPrayerRequests`.
   Anonim giriş sağlayıcısını açmak gerekmez; oturum sunucuda imzalı custom
   token ile oluşturulur.
2. 2. nesil Functions servis hesabına
   `roles/iam.serviceAccountTokenCreator` verilmelidir:
   `746942620456-compute@developer.gserviceaccount.com`.
3. App Check'te Android Play Integrity ve iOS App Attest aktif olmalıdır.
   Kod release/profile build'lerinde debug provider kullanımını engeller.
4. AdMob Console'da Android ve iOS ödüllü reklam birimlerinin
   Server-side verification callback URL alanına şu adres yazılmalı:

   `https://europe-west1-arinapp-7b136.cloudfunctions.net/rewardedAdSsv`

5. AdMob callback ayarında kullanıcı kimliği zorunlu değildir. Uygulama,
   kısa ömürlü ve tek kullanımlık `custom_data` kanıtını gönderir.
6. Functions, Firestore rules, indexes ve güncel gizlilik metni birlikte
   yayınlanmalıdır:

   `npx firebase-tools deploy --only functions,firestore:rules,firestore:indexes,hosting`

7. Firebase Console'da Dua Halkası koleksiyonlarının `expiresAt` alanı için
   Firestore TTL politikalarının etkin olduğu ayrıca doğrulanmalıdır. Index
   deploy edilmesi tek başına TTL temizliğinin aktif olduğunu garanti etmez.
8. `deliverPrayerNotifications` (her dakika) ve
   `cleanupExpiredPrayerRequests` (15 dakikada bir) scheduler kayıtları Cloud
   Scheduler'da etkin görünmelidir.

## Yayın öncesi doğrulama

- `functions` klasöründe `npm test` çalışmalı.
- `flutter analyze` yeni Dua Halkası dosyalarında hata vermemeli.
- Premium hesap talebi reklamsız gönderebilmeli.
- Ücretsiz hesap reklamı tamamladığında talep oluşmalı; reklam erken
  kapatıldığında oluşmamalı.
- Aynı cihaz/hesap aynı talepte ikinci kez “Dua ettim” sayısını artırmamalı.
- Beşinci gerçek eşlikten sonra bildirim açıldığında ilgili talep doğrudan
  görünmeli.
- Bildirim tokenı geçici olarak yokken iş `pending` kalmalı ve token
  yenilendiğinde yeniden teslim edilmeli.
- Bildirim işi 12 denemeden veya 7 günden sonra otomatik `expired` olarak
  işaretlenmeli, sonsuza kadar yeniden denenmemeli.
- Talep 24 saat dolduğunda callable akışında görünmemeli.
- Google/Apple girişinden önce ve sonra aynı kurulum Dua Halkası'nı
  kullanabilmeli; giriş/çıkış değişimi `permission-denied` üretmemeli.
- Android sistem geri tuşu pusula, zikir, nefes, şifa ve Dua Halkası
  ekranlarından önce Kıble araç paneline dönmeli.
- Debug APK Google test reklamını, release AAB ise production reklam birimini
  kullanmalı.

## Bilinen sınırlamalar (kabul edilen risk)

- Kurulum kimliği (`installId`) istemci tarafında üretilir; kullanıcı
  uygulama verisini silip yeniden kurarsa yeni bir kimlik oluşur. App Check
  (Play Integrity/DeviceCheck) sahte istemcileri engeller, IP ve kurulum bazlı
  hız sınırları kötüye kullanım maliyetini yükseltir, ancak telefon/e-posta
  doğrulaması olmadan tam Sybil direnci sağlanamaz. Bu, ödeme içermeyen bir
  topluluk özelliği için kabul edilen bir risktir; ölçek büyürse telefon
  doğrulaması değerlendirilebilir.
- `policyVersion` istemci tarafından gönderilen bir onay beyanıdır; sunucu
  yalnızca sürümün geçerli olduğunu doğrular, UI'da gerçekten gösterildiğini
  kanıtlayamaz.

AdMob SSV callback'i doğrulanmadan mağaza sürümü yayınlanmamalıdır.
