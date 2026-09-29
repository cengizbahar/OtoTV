// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class L10nTr extends L10n {
  L10nTr([String locale = 'tr']) : super(locale);

  @override
  String get appTagline => 'Yolculuğun sinema salonu';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get save => 'Kaydet';

  @override
  String get play => 'Oynat';

  @override
  String get close => 'Kapat';

  @override
  String get back => 'Geri';

  @override
  String get refresh => 'Yenile';

  @override
  String get homePage => 'Ana sayfa';

  @override
  String get otherGroup => 'Diğer';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navFavorites => 'Favoriler';

  @override
  String get navCast => 'Araca Yansıt';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get searchHint => 'Kanal, film veya dizi ara';

  @override
  String get libraryLoadFailed => 'Kütüphane yüklenemedi';

  @override
  String get emptyHomeTitle => 'Sinema salonun hazır';

  @override
  String get emptyHomeMessage =>
      'M3U listeni ya da Jellyfin/Emby sunucunu ekle; kanalların gruplarıyla birlikte burada belirsin.';

  @override
  String get sourcesUnreachable => 'Kaynaklara ulaşılamadı';

  @override
  String get addSource => 'Kaynak ekle';

  @override
  String get heroFavorite => 'FAVORİN';

  @override
  String get heroWatchNow => 'ŞİMDİ İZLE';

  @override
  String channelCount(int count) {
    return '$count kanal';
  }

  @override
  String get noResults => 'Sonuç yok';

  @override
  String get noResultsMessage => 'Farklı bir kelimeyle tekrar dene.';

  @override
  String sourcesFailed(int count, String names) {
    return '$count kaynak yüklenemedi: $names';
  }

  @override
  String get apps => 'Uygulamalar';

  @override
  String get appInside => 'OtoTV içinde';

  @override
  String get appInBrowser => 'Tarayıcıda açılır';

  @override
  String appOpenFailed(String name) {
    return '$name açılamadı.';
  }

  @override
  String get nowPlayingBadge => 'OYNATILIYOR';

  @override
  String favoriteAdded(String name) {
    return '$name favorilere eklendi';
  }

  @override
  String favoriteRemoved(String name) {
    return '$name favorilerden çıkarıldı';
  }

  @override
  String get carMode => 'Araç Modu';

  @override
  String get previous => 'Önceki';

  @override
  String get next => 'Sonraki';

  @override
  String get addFavorite => 'Favorilere ekle';

  @override
  String get removeFavorite => 'Favorilerden çıkar';

  @override
  String get epgNext => 'SONRA';

  @override
  String get favoritesEmptyTitle => 'Henüz favori yok';

  @override
  String get favoritesEmptyMessage =>
      'Bir kanala basılı tutarak favorilerine ekle; en sevdiklerin burada, tek dokunuş uzağında.';

  @override
  String get browseChannels => 'Kanallara göz at';

  @override
  String get castPhone => 'Telefon';

  @override
  String get castCarScreen => 'Araç ekranı';

  @override
  String get castNotConnected => 'Araç bağlı değil';

  @override
  String get castNotConnectedMessage =>
      'iPhone\'unu CarPlay\'e ya da Android telefonunu aracına bağla; OtoTV bağlantıyı otomatik algılar.';

  @override
  String get castStep1Title => 'Aracını bağla';

  @override
  String get castStep1Body =>
      'USB kablo veya kablosuz CarPlay / Android Auto ile.';

  @override
  String get castStep2Title => 'İçeriğini seç';

  @override
  String get castStep2Body => 'Kanal, film veya kendi sunucundan bir bölüm aç.';

  @override
  String get castStep3Title => 'Araç ekranında aç';

  @override
  String get castStep3Body =>
      'Araç ekranındaki uygulamalardan OtoTV\'yi seç, bir kanala dokun; sesi araçta çalar.';

  @override
  String get passengerNotice =>
      'Yalnızca yolcular içindir. Sürücü araç kullanırken asla video izlememelidir.';

  @override
  String get openCarMode => 'Araç Modunu Aç';

  @override
  String get openChannelFirst => 'Önce Ana Sayfa\'dan bir kanal ya da film aç.';

  @override
  String get dim => 'Karart';

  @override
  String get wakeHint => 'Uyandırmak için çift dokun';

  @override
  String get sources => 'Kaynaklar';

  @override
  String get sourcesEmptyTitle => 'Henüz kaynak yok';

  @override
  String get sourcesEmptyMessage =>
      'M3U listeni ya da Jellyfin / Emby sunucunu ekle. Adresler ve oturum bilgileri yalnızca bu cihazda saklanır.';

  @override
  String get addFirstSource => 'İlk kaynağını ekle';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get remove => 'Kaldır';

  @override
  String get serverUrlRequired => 'Sunucu adresini gir.';

  @override
  String get listUrlRequired => 'Liste adresini gir.';

  @override
  String get usernameRequired => 'Kullanıcı adını gir.';

  @override
  String get username => 'Kullanıcı adı';

  @override
  String get password => 'Şifre';

  @override
  String get nameOptional => 'Ad (isteğe bağlı)';

  @override
  String get qrAdd => 'QR ile ekle';

  @override
  String get serverPrivacyNote =>
      'Şifren saklanmaz; yalnızca oturum anahtarı cihazının güvenli kasasında tutulur.';

  @override
  String get listPrivacyNote => 'Liste adresi yalnızca bu cihazda saklanır.';

  @override
  String get connect => 'Bağlan';

  @override
  String get addAndLoad => 'Ekle ve yükle';

  @override
  String get qrTitle => 'QR kodu okut';

  @override
  String get qrCameraDenied =>
      'Kameraya erişilemedi. Ayarlar\'dan OtoTV için kamera iznini aç.';

  @override
  String get qrHint => 'Liste adresini içeren QR kodu çerçeveye hizala';

  @override
  String get plusCardSubtitle => 'Araç Modu, sınırsız kaynak ve daha fazlası';

  @override
  String get plusActive => 'Plus aktif';

  @override
  String get plusActiveSubtitle => 'Tüm özellikler açık. Teşekkürler!';

  @override
  String get sectionMedia => 'Medya';

  @override
  String get manageSources => 'Kaynakları yönet';

  @override
  String sourceCount(int count) {
    return '$count kaynak';
  }

  @override
  String get sectionPreferences => 'Tercihler';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Sistem dili';

  @override
  String get sectionLegal => 'Yasal';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get terms => 'Kullanım Koşulları (EULA)';

  @override
  String get sectionAbout => 'Hakkında';

  @override
  String get help => 'Yardım ve SSS';

  @override
  String get version => 'Sürüm';

  @override
  String disclaimer(String appName) {
    return '$appName yalnızca bir oynatıcıdır; içerik sağlamaz. Eklediğiniz listeleri kullanma hakkına sahip olmaktan siz sorumlusunuz.';
  }

  @override
  String get paywallCarModeTitle => 'Araç Modu';

  @override
  String get paywallCarModeBody =>
      'Torpido için yatay, dev kontrollü sinema arayüzü ve Karartma modu';

  @override
  String get paywallSourcesTitle => 'Sınırsız kaynak';

  @override
  String get paywallSourcesBody => 'İstediğin kadar M3U, Jellyfin ve Emby';

  @override
  String get paywallCarPlayTitle => 'CarPlay ve Android Auto';

  @override
  String get paywallCarPlayBody =>
      'Kanallarını araç ekranından seç, direksiyondan kontrol et';

  @override
  String get paywallFutureTitle => 'Tüm yeni premium özellikler';

  @override
  String get paywallFutureBody => 'Tek üyelikle gelecekteki her şey dahil';

  @override
  String get planMonthly => 'Aylık';

  @override
  String get planMonthlyDesc => 'İstediğin zaman iptal et';

  @override
  String get planAnnual => 'Yıllık';

  @override
  String get planAnnualDesc => 'Yılda tek ödeme';

  @override
  String get planLifetime => 'Ömür boyu';

  @override
  String get planLifetimeDesc => 'Tek ödeme, sonsuza dek senin';

  @override
  String planTrial(String period) {
    return '$period ücretsiz dene';
  }

  @override
  String get bestValue => 'EN AVANTAJLI';

  @override
  String periodDays(int count) {
    return '$count gün';
  }

  @override
  String periodWeeks(int count) {
    return '$count hafta';
  }

  @override
  String periodMonths(int count) {
    return '$count ay';
  }

  @override
  String periodYears(int count) {
    return '$count yıl';
  }

  @override
  String get paywallCta => 'Plus\'a geç';

  @override
  String get paywallCtaTrial => 'Ücretsiz denemeyi başlat';

  @override
  String get paywallLegal =>
      'Ödeme Apple / Google hesabından alınır. Abonelik, dönem bitmeden en az 24 saat önce iptal edilmezse otomatik yenilenir. Aboneliğini mağaza hesap ayarlarından yönetebilirsin.';

  @override
  String get restorePurchases => 'Satın alımları geri yükle';

  @override
  String get restoreSuccess => 'Satın alımların geri yüklendi.';

  @override
  String get restoreNone => 'Geri yüklenecek satın alım bulunamadı.';

  @override
  String get purchaseSuccess => 'Hoş geldin! OtoTV Plus açıldı.';

  @override
  String purchaseFailed(String message) {
    return 'Satın alma tamamlanamadı: $message';
  }

  @override
  String get storeUnavailable =>
      'Mağazaya şu an ulaşılamıyor. Daha sonra tekrar dene.';

  @override
  String get storeNotConfigured =>
      'Bu derlemede mağaza bağlantısı yapılandırılmadı.';

  @override
  String freeSourceLimit(int count) {
    return 'Ücretsiz sürümde en fazla $count kaynak ekleyebilirsin.';
  }

  @override
  String get libraryOpenFailed => 'Kitaplık açılamadı';

  @override
  String get libraryEmptyTitle => 'Burası boş';

  @override
  String get libraryEmptyMessage => 'Bu kitaplıkta henüz içerik yok.';

  @override
  String get seasonsFailed => 'Sezonlar alınamadı';

  @override
  String get noEpisodesTitle => 'Bölüm yok';

  @override
  String get noEpisodesMessage => 'Bu dizi için sunucuda bölüm bulunamadı.';

  @override
  String get continueWatching => 'İzlemeye devam et';

  @override
  String minutesLeft(int count) {
    return '$count dk kaldı';
  }

  @override
  String minutes(int count) {
    return '$count dk';
  }

  @override
  String get errInvalidAddress => 'Geçersiz adres.';

  @override
  String errHttpStatus(int code) {
    return 'Sunucu $code döndürdü.';
  }

  @override
  String get errNoPlayable => 'Listede oynatılabilir öğe bulunamadı.';

  @override
  String get errDownload =>
      'Liste indirilemedi. Adresi ve internet bağlantını kontrol et.';

  @override
  String get errServerUnexpected => 'Sunucu beklenmeyen bir yanıt verdi.';

  @override
  String get errNoSession => 'Oturum bulunamadı; sunucuyu yeniden ekle.';

  @override
  String get errUnreachable =>
      'Sunucuya ulaşılamadı. Adresi ve ağ bağlantını kontrol et.';

  @override
  String get errSessionExpired => 'Oturum süresi doldu; sunucuyu yeniden ekle.';

  @override
  String get errBadCredentials => 'Kullanıcı adı veya şifre hatalı.';

  @override
  String errServerNotFound(String kind) {
    return 'Bu adreste $kind sunucusu bulunamadı.';
  }

  @override
  String errServerStatus(int code) {
    return 'Sunucu hatası ($code).';
  }

  @override
  String get errUnknown => 'Beklenmeyen bir hata oluştu.';

  @override
  String get notificationChannel => 'Oynatma';

  @override
  String get notificationChannelDesc => 'Ekran kapalıyken oynatma kontrolleri';

  @override
  String get carFavorites => 'Favoriler';

  @override
  String get carChannels => 'Kanallar';

  @override
  String carContinue(String server) {
    return '$server · İzlemeye devam et';
  }

  @override
  String get carNoSources => 'Kanal eklemek için telefonda OtoTV\'yi aç';

  @override
  String get carEmpty => 'Burada henüz bir şey yok';

  @override
  String get previewNotice =>
      'Önizleme: mağaza bağlanınca gerçek fiyatlar burada görünür.';

  @override
  String get previewPurchase =>
      'Önizleme modu: satın alma mağaza bağlanınca çalışır.';

  @override
  String get carPlusRequired => 'Araç ekranı OtoTV Plus ile açılır';

  @override
  String get castConnectedAndroidAuto => 'Android Auto bağlı';

  @override
  String get castConnectedAutomotive => 'Araç sistemi bağlı';

  @override
  String get castConnectedCarPlay => 'CarPlay bağlı';

  @override
  String get castConnectedMessage =>
      'Araç ekranındaki uygulamalardan OtoTV\'yi aç. Kanal seçince sesi araç hoparlöründen çalar; video telefonda Araç Modu\'nda oynar.';

  @override
  String get castNeedsPlus =>
      'Araç ekranında OtoTV\'yi kullanmak için Plus gerekli.';

  @override
  String get castGetPlus => 'Plus\'ı incele';
}
