# OtoTV CarPlay kurulumu

OtoTV'nin mevcut CarPlay ses arayüzü, uygulama simgesinden açılan kanal
listelerini ve Şimdi Oynatılıyor ekranını sağlar. Telefonun Flutter video
ekranını CarPlay'e yansıtmaz.

`Runner/Runner.entitlements` dosyasında `com.apple.developer.carplay-audio`
yetkisi bulunur. CarPlay sahnesi `Info.plist` içinde tanımlıdır ve
`SceneDelegate.swift` ile uygulanır.

> **Şu an bağlı değil.** Hesap değişikliğiyle (Bundle ID `com.ototvplus.app`)
> CarPlay yetkisi yeni hesapta henüz onaylanmadı. Yetkisiz hesapta bu dosya
> bağlıysa imzalama başarısız olur ve TestFlight derlemesi çıkmaz. Apple onayı
> gelince `ios/Runner.xcodeproj/project.pbxproj` içinde Runner hedefinin
> Debug, Profile ve Release ayarlarına şu satır geri eklenir:
> `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;`

## İmzalama ve yükleme

1. Apple Developer hesabında `com.ototvplus.app` için CarPlay Audio yetkisinin
   onaylandığını doğrulayın. Henüz onay yoksa
   https://developer.apple.com/carplay/ üzerinden başvurun.
2. Yetkiyi içeren yeni provisioning profili oluşturun. Geliştirme ve
   TestFlight dağıtımı için kullanılan profillerin her biri bu yetkiyi
   içermelidir. Sadece yerel entitlements dosyasını değiştirmek yeterli değildir.
3. Xcode veya Codemagic'de güncel profili kullanarak yeni iOS derlemesi alın.
   Mevcut `ios-testflight` iş akışı profilleri uygular; Codemagic'deki profilin
   de güncellenmesi gerekir. Yetkisiz/eski profille imzalama başarısız olur.
4. Yeni sürümü iPhone'a yükleyin ve ilk açılışta kaynak listenizi hazırlayın.
5. CarPlay'e bağlanın. Gerekirse iPhone'da Ayarlar → Genel → CarPlay →
   aracınız → Özelleştir bölümünden OtoTV'yi ekleyin.

## Cihaz doğrulaması

Araç park halindeyken OtoTV simgesinin göründüğünü, simgeye dokununca
kanal listesinin açıldığını ve kanal seçiminin oynatma ekranına geçtiğini
kontrol edin. Telefon uygulaması kapalıyken CarPlay üzerinden açılışı da
ayrıca deneyin. Simgenin görünmesi video yansıtma desteği anlamına gelmez.

Windows ortamında Xcode derlemesi, Apple imzası veya gerçek CarPlay oturumu
doğrulanamaz; bu kontroller macOS ve cihaz üzerinde tamamlanmalıdır.
