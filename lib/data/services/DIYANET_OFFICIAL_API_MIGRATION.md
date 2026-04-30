# Diyanet Resmî API (awqatsalah) Entegrasyon Plan Belgesi

> **Okuyucu: Gelecekteki bir AI veya geliştirici (veya dönmüş ben).**
> Bu belge, projede Türkiye namaz vakitleri için henüz tamamlanmamış
> tek adımı — Diyanet'in resmî API'sine geçişi — net şekilde anlatır.
> Spekülasyon yapmadan, önce bu belgeyi sonuna kadar oku.

## 1. Bağlam (neden bu belge var)

Arın uygulamasında TR namaz vakitleri bugün (migration v2 sonrası)
`ezanvakti.emushaf.net` community mirror'ından çekiliyor. Mirror,
Diyanet'in **ham astronomik** hesap çıktısını yayınlıyor; Diyanet'in
resmî sitesi aynı değerlere "ihtiyat payı" ekleyip yayınlıyor. Bu
yüzden bizim değerlerle Diyanet resmî sitesinin değerleri arasında
bazı vakitlerde ~1 dk fark oluşuyor.

Gözlemlenen fark (19.04.2026, Kocaeli/Gebze):

| Vakit   | Bizim (mirror) | Diyanet resmî | Fark |
|---------|----------------|---------------|------|
| İmsak   | 04:38          | 04:37 (?)     | muhtemelen −1 |
| Güneş   | 06:11          | 06:11         | 0    |
| Öğle    | 13:07          | 13:07         | 0    |
| İkindi  | 16:51          | 16:51         | 0    |
| Akşam   | 19:52          | 19:53         | +1   |
| Yatsı   | 21:19          | 21:19         | 0    |

Tek kesin gözlem **Akşam**. Diğer satırlar tahmindir.
**Sabit offset koymadık** çünkü:

- Diyanet'in tahayyüt (ihtiyat) dakikaları enleme / mevsime göre
  değişken yayınlanmış olabilir (kanıt: resmî dokümantasyonu
  okunmadı, tek gün gözlemine dayanarak genelleme tehlikeli)
- Doğru kaynağı kullanmak, tahmin katmanı eklemekten her zaman
  daha temiz bir çözüm

## 2. Tek kesin çözüm: Diyanet resmî API'si

Din İşleri Yüksek Kurulu'nun kendi GitHub repo'su:
<https://github.com/DinIsleriYuksekKurulu/AwqatSalah>

- **URL**: `https://awqatsalah.diyanet.gov.tr`
- **Auth**: Email + password (basic auth token-exchange)
- **Token ömrü**: access 30 dk, refresh 45 dk
- **Rate limit**: endpoint başına ~5 istek (tam dok yok,
  kullanım pattern'i: günde 1 login + 1 prayer fetch / kullanıcı)
- **Endpoint'ler**:
  - `/Auth/Login` → access + refresh token
  - `/Auth/RefreshToken`
  - `/Place/Countries`
  - `/Place/States?countryId=2` (Türkiye)
  - `/Place/Cities?stateId=...`
  - `/PrayerTime/Daily/{locationId}` (ya da `/Monthly`)

Referans kütüphaneler:

- Python: <https://pypi.org/project/pydiyanet/> (MIT, açık kod)
- Go: <https://github.com/abduelhamit/DiyanetAwqatSalahAPI>
- C#: `DinIsleriYuksekKurulu/AwqatSalah` (resmî örnek)

## 3. Credentials başvurusu

Diyanet'e gönderilmiş / gönderilecek mail:

- **Alıcı**: <support@diyanet.gov.tr>
- **Gönderim tarihi**: __________ (doldur)
- **Cevap beklenen süre**: 1-5 iş günü

Mail taslağı bu dosyanın `§7. Mail taslağı` bölümünde.

## 4. Credentials geldiğinde yapılacaklar (sıra kritik)

### 4.1. Güvenlik

Credentials'ı APK içine **gömme**. İki seçenek:

1. **Firebase Remote Config** (önerilen, 30 dk iş):
   - Console → Remote Config → iki key: `diyanet_api_email`,
     `diyanet_api_password`
   - İstemci `firebase_remote_config` paketiyle runtime'da okur
   - Default boş; fetch sonrası dolar
   - Attack surface: Firebase rules ile sıkılanırsa çıkarılamaz

2. **Firebase Cloud Functions proxy** (daha güvenli, 2-3 saat iş):
   - Function `fetchDiyanetPrayerTimes({ilceId})` → fonksiyon
     Diyanet'e login olur, vakitleri döndürür
   - APK'da credentials hiç yok
   - Masraf: Firebase Blaze gerek (free tier yeterli muhtemelen)

### 4.2. Yeni servis

`lib/data/services/diyanet_official_service.dart`:

```dart
class DiyanetOfficialService {
  Future<PrayerTimesModel?> fetchToday({required int ilceId, ...});
  PrayerTimesModel? tryLoadTodayCached({...});
  // OAuth2 token yönetimi içeride; access expire olursa
  // refresh; refresh expire olursa re-login.
}
```

Cache key format: `diyanet_official_v1_{ilceId}` (mevcut
`diyanet_v1_{ilceId}` ile çakışmaz).

### 4.3. Resolver güncellemesi

`lib/data/services/prayer_service_resolver.dart`'ta Tier sıralaması:

1. **Diyanet resmî** (yeni) — varsa kimlik doğrulaması geçti ve TR ise
2. **Diyanet (ezanvakti)** — kimlik doğrulaması yoksa / resmî API düştüyse
3. **Aladhan** — TR dışı veya her ikisi de düştü

Bu değişiklik `PrayerServiceResolver` sınıfının mevcut Tier
mantığına **bir tier ekleme**; yapı hazır, dokümantasyon
comment'lerinde "Tier 0/1/2" olarak belirt.

### 4.4. Migration v3

`lib/main.dart`'taki `_migratePrayerCacheV2IfNeeded` yanına
`_migratePrayerCacheV3IfNeeded`: eski `diyanet_v1_*` entry'lerini
temizler (resmî API farklı değer verecek, eskisi yanıltır).

Flag: `prayer_cache_migration_v3_done`.

### 4.5. Test

- Kocaeli/Gebze için 19.04.2026 Akşam ~19:53'te kalmalı (resmî
  Diyanet sitesiyle dakikası dakikasına aynı)
- APK build → cihaz kurulum → dashboard'daki vakitlerin screenshot'u
- Log'da `source: diyanet_official` görünmeli

## 5. Bu arada ezanvakti kodu silinmeyecek

`DiyanetPrayerService` (ezanvakti) fallback olarak kalır. Sebep:

- Resmî API düşerse bizim uygulama yine çalışmalı
- Resmî API rate-limit'i aşılabilir
- Mirror ücretsiz ve authentication istemiyor → son-çare olarak
  idealdir

Tier 2 olarak konumu korur. Silme.

## 6. Spekülasyon yapılmaması gereken şeyler

(Bu bölüm gelecekteki AI'a uyarı.)

- **"Akşama +1 ekle"** — yapma. Enleme/mevsime göre değişebilir.
- **"İmsaka −1 ekle"** — yapma. Aynı sebep.
- **"Diyanet sitesinden HTML scraping yap"** — yapma.
  Cloudflare koruması var, kırılgan. Resmî API'yi bekle.
- **"Aladhan'a `tune` parametresi geç"** — yapma. Diyanet'in
  enlem-bazlı ihtiyatını `tune` ile çoğaltamazsın.

Tek doğru yol: resmî API. Credentials gelmediyse ezanvakti'ye
dokunma, bu 1 dk farkı kabullen.

## 7. Mail taslağı (başvuru yapılmamışsa)

```text
Konu: AwqatSalah API erişim talebi — Arın uygulaması

Merhaba,

Geliştirdiğim "Arın" (paket: com.arin.arin) isimli Android
uygulamasında Türkiye'deki Müslüman kullanıcılar için Diyanet
İşleri Başkanlığınızın resmî namaz vakti verilerini kullanmak
istiyorum. Din İşleri Yüksek Kurulu'nun GitHub'da yayınladığı
AwqatSalah örnek projesinden haberdar oldum.

awqatsalah.diyanet.gov.tr için kullanıcı adı ve şifre talep
ediyorum.

Kullanım amacı: kullanıcının ilçesine özel günlük namaz vakitleri
(5 vakit + İmsak + Güneş) göstermek, bildirim zamanlaması yapmak.
Tahmini trafik: günde 1-2 istek / kullanıcı.

Saygılarımla,
[ad soyad]
[e-posta]
```

## 8. Başka bir AI'a context vereceğinde

Bu dosyayı + aşağıdaki dosyaları paylaş, başka bir şeye gerek yok:

1. Bu dosya (`DIYANET_OFFICIAL_API_MIGRATION.md`)
2. `lib/data/services/prayer_service_resolver.dart` (mimarinin
   nerede genişleyeceğini gösterir)
3. `lib/data/services/diyanet_prayer_service.dart` (yeni servisin
   deseneğini kopyalayacak)
4. `lib/data/services/diyanet_district_matcher.dart` (ilçe → ID
   çözümü aynen kullanılacak)
5. `lib/main.dart`'ın `_migratePrayerCacheV2IfNeeded` bölümü
   (migration v3 için kopya kalıbı)

Mesaj template'i:

```text
Arın projesinde Diyanet resmî API'ye geçmek istiyorum.
`lib/data/services/DIYANET_OFFICIAL_API_MIGRATION.md` dosyasını
oku, orada adım adım plan var. Credentials elimde: [email],
[password]. Planı uygula.
```

## 9. Belge sürümü

- **v1 — 2026-04-19**: İlk yazım. Ezanvakti migration v2 tamamlandı,
  resmî API başvurusu bekleniyor.
