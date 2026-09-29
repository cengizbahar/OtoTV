# OtoTV Plus — Ödeme kurulumu (Android + iOS)

Koddaki her şey hazır: satış ekranı, satın alma, geri yükleme, Plus kilitleri,
Android imzalama ve Codemagic derlemeleri. Bu belge, **senin hesaplarında**
yapılması gereken adımları sırasıyla anlatır.

---

## 0. Ürünler (her iki mağazada birebir aynı)

| Ürün kimliği | Tür | Önerilen fiyat (TR) | Not |
|---|---|---|---|
| `ototv_plus_monthly` | Otomatik yenilenen abonelik, 1 ay | ₺99,99 | |
| `ototv_plus_annual` | Otomatik yenilenen abonelik, 1 yıl | ₺599,99 | **7 gün ücretsiz deneme** |
| `ototv_plus_lifetime` | Tek seferlik (tüketilmeyen) | ₺999,99 | |

Fiyatlar öneridir; istediğin gibi değiştir. Diğer ülkeler için mağazalar kur
karşılığını otomatik önerir. Kimlikleri değiştirirsen `lib/state/premium.dart`
içindeki `PremiumConfig.product*` sabitlerini de güncelle.

---

## 1. Apple (iOS)

1. **Apple Developer Program** üyeliği (yıllık 99 $): developer.apple.com/programs
2. **App Store Connect › Anlaşmalar, Vergi ve Bankacılık**: *Ücretli Uygulamalar*
   anlaşmasını imzala, banka ve vergi bilgilerini gir. **Bu olmadan satın alma çalışmaz.**
3. **Sertifikalar, Kimlikler ve Profiller › Identifiers**: `com.ototv.app` App ID oluştur
   (In-App Purchase varsayılan olarak açıktır).
4. **App Store Connect › Uygulamalar › +**: OtoTV'yi oluştur (Bundle ID: `com.ototv.app`).
5. **Uygulama › Abonelikler**: "OtoTV Plus" abonelik grubu → `ototv_plus_monthly` ve
   `ototv_plus_annual` ürünleri. Yıllığa **Tanıtım Teklifi › Ücretsiz, 1 hafta** ekle.
6. **Uygulama › Uygulama İçi Satın Alımlar**: `ototv_plus_lifetime` (Tüketilmeyen).
7. Her ürüne Türkçe + İngilizce ad/açıklama ve inceleme ekran görüntüsü ekle
   (satış ekranının görüntüsü yeterli).
8. **Kullanıcılar ve Erişim › Entegrasyonlar › Uygulama İçi Satın Alma** anahtarı oluştur
   (RevenueCat için, `.p8` dosyası).

## 2. Google (Android)

1. **Google Play Console** hesabı (tek seferlik 25 $): play.google.com/console
2. **Ödeme profili** oluştur (satıcı hesabı). **Bu olmadan satın alma çalışmaz.**
3. OtoTV uygulamasını oluştur (paket adı: `com.ototv.app`).
4. **Yükleme anahtarı** oluştur (bir kez, kendi bilgisayarında):
   ```
   "C:\Program Files\Android\Android Studio\jbr\bin\keytool" -genkey -v -keystore C:\ototv-keys\ototv-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ototv-upload
   ```
   `android/key.properties.example` dosyasını `android/key.properties` olarak kopyala,
   şifreleri yaz. **.jks dosyasını ve şifreyi güvenli bir yerde yedekle.**
5. İlk AAB'yi **İç test** kanalına yükle (ürün oluşturabilmek için gerekli):
   ```
   flutter build appbundle --release --dart-define-from-file=.env.json
   ```
6. **Para kazanma › Abonelikler**: `ototv_plus_monthly` (temel plan: aylık) ve
   `ototv_plus_annual` (temel plan: yıllık + **7 günlük ücretsiz deneme** teklifi).
7. **Para kazanma › Uygulama içi ürünler**: `ototv_plus_lifetime`.
8. **Lisans testi**: Ayarlar › Lisans testi'ne kendi Gmail adresini ekle — test
   satın almaları ücretsiz olur.
9. Google Cloud'da RevenueCat için **hizmet hesabı** oluştur ve Play Console'a
   *Finansal veriler* izniyle ekle (RevenueCat panelindeki adım adım rehberi izle).

## 3. RevenueCat (ücretsiz, aylık 2.500 $ gelire kadar)

1. revenuecat.com'da hesap aç, **OtoTV** projesi oluştur.
2. **Apps**: iOS uygulaması (`com.ototv.app` + 1.8'deki `.p8` anahtarı) ve Android
   uygulaması (`com.ototv.app` + 2.9'daki hizmet hesabı JSON'u) ekle.
3. **Products**: Üç ürünü her iki mağazadan içe aktar.
4. **Entitlements**: kimliği tam olarak **`plus`** olan bir yetki oluştur, üç ürünü bağla.
5. **Offerings**: "default" teklifine üç paket ekle: **Monthly**, **Annual**, **Lifetime**
   (uygulama paketleri bu türlere göre tanır).
6. **API keys**: iOS (`appl_…`) ve Android (`goog_…`) genel anahtarlarını kopyala.

## 4. Anahtarları uygulamaya ver

Proje kökünde `.env.example.json` dosyasını `.env.json` olarak kopyala ve anahtarları yaz.
`.env.json` Git'e girmez. Derleme:

```
flutter run --dart-define-from-file=.env.json
```

Anahtar yokken geliştirme derlemesinde satış ekranı **önizleme fiyatlarıyla** görünür
(satın alınamaz). Mağaza sürümünde önizleme hiçbir zaman gösterilmez.

## 5. Codemagic (iOS derlemesi için Mac gerekmez)

1. codemagic.io'ya GitHub/GitLab hesabınla gir, depoyu ekle (`codemagic.yaml` hazır).
2. **Environment variables › Group `ototv_secrets`**: `RC_ANDROID_KEY`, `RC_IOS_KEY`,
   `APP_STORE_APPLE_ID`, `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`.
3. **Integrations › App Store Connect**: "OtoTV ASC" adıyla API anahtarı ekle.
4. **Code signing › Android keystores**: yükleme anahtarını `ototv_upload` referansıyla yükle.
5. `ios-testflight` akışını başlat → TestFlight'tan iPhone'una kur.

## 6. Yayından önce

- `lib/core/brand.dart` içindeki **Kullanım Koşulları** ve **Gizlilik Politikası**
  adreslerini gerçek sayfalarla değiştir (iki mağaza da zorunlu tutar).
- App Store Connect'te abonelik açıklamasına "otomatik yenilenir" bilgisini ekle.
- Test: Apple **Sandbox** hesabı / Google **lisans testi** hesabıyla satın al, uygulamayı
  silip yeniden kur ve **Satın alımları geri yükle**'yi dene.
