import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğun sinema salonu'**
  String get appTagline;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @play.
  ///
  /// In tr, this message translates to:
  /// **'Oynat'**
  String get play;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @refresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get refresh;

  /// No description provided for @homePage.
  ///
  /// In tr, this message translates to:
  /// **'Ana sayfa'**
  String get homePage;

  /// No description provided for @otherGroup.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get otherGroup;

  /// No description provided for @navHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get navHome;

  /// No description provided for @navFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get navFavorites;

  /// No description provided for @navCast.
  ///
  /// In tr, this message translates to:
  /// **'Araca Yansıt'**
  String get navCast;

  /// No description provided for @navSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get navSettings;

  /// No description provided for @searchHint.
  ///
  /// In tr, this message translates to:
  /// **'Kanal, film veya dizi ara'**
  String get searchHint;

  /// No description provided for @libraryLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kütüphane yüklenemedi'**
  String get libraryLoadFailed;

  /// No description provided for @emptyHomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sinema salonun hazır'**
  String get emptyHomeTitle;

  /// No description provided for @emptyHomeMessage.
  ///
  /// In tr, this message translates to:
  /// **'M3U listeni ya da Jellyfin/Emby sunucunu ekle; kanalların gruplarıyla birlikte burada belirsin.'**
  String get emptyHomeMessage;

  /// No description provided for @sourcesUnreachable.
  ///
  /// In tr, this message translates to:
  /// **'Kaynaklara ulaşılamadı'**
  String get sourcesUnreachable;

  /// No description provided for @addSource.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak ekle'**
  String get addSource;

  /// No description provided for @heroFavorite.
  ///
  /// In tr, this message translates to:
  /// **'FAVORİN'**
  String get heroFavorite;

  /// No description provided for @heroWatchNow.
  ///
  /// In tr, this message translates to:
  /// **'ŞİMDİ İZLE'**
  String get heroWatchNow;

  /// No description provided for @channelCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kanal'**
  String channelCount(int count);

  /// No description provided for @noResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç yok'**
  String get noResults;

  /// No description provided for @noResultsMessage.
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir kelimeyle tekrar dene.'**
  String get noResultsMessage;

  /// No description provided for @sourcesFailed.
  ///
  /// In tr, this message translates to:
  /// **'{count} kaynak yüklenemedi: {names}'**
  String sourcesFailed(int count, String names);

  /// No description provided for @apps.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamalar'**
  String get apps;

  /// No description provided for @appInside.
  ///
  /// In tr, this message translates to:
  /// **'OtoTV içinde'**
  String get appInside;

  /// No description provided for @appInBrowser.
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcıda açılır'**
  String get appInBrowser;

  /// No description provided for @appOpenFailed.
  ///
  /// In tr, this message translates to:
  /// **'{name} açılamadı.'**
  String appOpenFailed(String name);

  /// No description provided for @nowPlayingBadge.
  ///
  /// In tr, this message translates to:
  /// **'OYNATILIYOR'**
  String get nowPlayingBadge;

  /// No description provided for @favoriteAdded.
  ///
  /// In tr, this message translates to:
  /// **'{name} favorilere eklendi'**
  String favoriteAdded(String name);

  /// No description provided for @favoriteRemoved.
  ///
  /// In tr, this message translates to:
  /// **'{name} favorilerden çıkarıldı'**
  String favoriteRemoved(String name);

  /// No description provided for @carMode.
  ///
  /// In tr, this message translates to:
  /// **'Araç Modu'**
  String get carMode;

  /// No description provided for @previous.
  ///
  /// In tr, this message translates to:
  /// **'Önceki'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki'**
  String get next;

  /// No description provided for @addFavorite.
  ///
  /// In tr, this message translates to:
  /// **'Favorilere ekle'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden çıkar'**
  String get removeFavorite;

  /// No description provided for @epgNext.
  ///
  /// In tr, this message translates to:
  /// **'SONRA'**
  String get epgNext;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz favori yok'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bir kanala basılı tutarak favorilerine ekle; en sevdiklerin burada, tek dokunuş uzağında.'**
  String get favoritesEmptyMessage;

  /// No description provided for @browseChannels.
  ///
  /// In tr, this message translates to:
  /// **'Kanallara göz at'**
  String get browseChannels;

  /// No description provided for @castPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get castPhone;

  /// No description provided for @castCarScreen.
  ///
  /// In tr, this message translates to:
  /// **'Araç ekranı'**
  String get castCarScreen;

  /// No description provided for @castNotConnected.
  ///
  /// In tr, this message translates to:
  /// **'Araç bağlı değil'**
  String get castNotConnected;

  /// No description provided for @castNotConnectedMessage.
  ///
  /// In tr, this message translates to:
  /// **'iPhone\'unu CarPlay\'e ya da Android telefonunu aracına bağla; OtoTV bağlantıyı otomatik algılar.'**
  String get castNotConnectedMessage;

  /// No description provided for @castStep1Title.
  ///
  /// In tr, this message translates to:
  /// **'Aracını bağla'**
  String get castStep1Title;

  /// No description provided for @castStep1Body.
  ///
  /// In tr, this message translates to:
  /// **'USB kablo veya kablosuz CarPlay / Android Auto ile.'**
  String get castStep1Body;

  /// No description provided for @castStep2Title.
  ///
  /// In tr, this message translates to:
  /// **'İçeriğini seç'**
  String get castStep2Title;

  /// No description provided for @castStep2Body.
  ///
  /// In tr, this message translates to:
  /// **'Kanal, film veya kendi sunucundan bir bölüm aç.'**
  String get castStep2Body;

  /// No description provided for @castStep3Title.
  ///
  /// In tr, this message translates to:
  /// **'Araç ekranında aç'**
  String get castStep3Title;

  /// No description provided for @castStep3Body.
  ///
  /// In tr, this message translates to:
  /// **'Araç ekranındaki uygulamalardan OtoTV\'yi seç, bir kanala dokun; sesi araçta çalar.'**
  String get castStep3Body;

  /// No description provided for @passengerNotice.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca yolcular içindir. Sürücü araç kullanırken asla video izlememelidir.'**
  String get passengerNotice;

  /// No description provided for @openCarMode.
  ///
  /// In tr, this message translates to:
  /// **'Araç Modunu Aç'**
  String get openCarMode;

  /// No description provided for @openChannelFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce Ana Sayfa\'dan bir kanal ya da film aç.'**
  String get openChannelFirst;

  /// No description provided for @dim.
  ///
  /// In tr, this message translates to:
  /// **'Karart'**
  String get dim;

  /// No description provided for @wakeHint.
  ///
  /// In tr, this message translates to:
  /// **'Uyandırmak için çift dokun'**
  String get wakeHint;

  /// No description provided for @sources.
  ///
  /// In tr, this message translates to:
  /// **'Kaynaklar'**
  String get sources;

  /// No description provided for @sourcesEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kaynak yok'**
  String get sourcesEmptyTitle;

  /// No description provided for @sourcesEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'M3U listeni ya da Jellyfin / Emby sunucunu ekle. Adresler ve oturum bilgileri yalnızca bu cihazda saklanır.'**
  String get sourcesEmptyMessage;

  /// No description provided for @addFirstSource.
  ///
  /// In tr, this message translates to:
  /// **'İlk kaynağını ekle'**
  String get addFirstSource;

  /// No description provided for @rename.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden adlandır'**
  String get rename;

  /// No description provided for @remove.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get remove;

  /// No description provided for @serverUrlRequired.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu adresini gir.'**
  String get serverUrlRequired;

  /// No description provided for @listUrlRequired.
  ///
  /// In tr, this message translates to:
  /// **'Liste adresini gir.'**
  String get listUrlRequired;

  /// No description provided for @usernameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adını gir.'**
  String get usernameRequired;

  /// No description provided for @username.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı'**
  String get username;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @nameOptional.
  ///
  /// In tr, this message translates to:
  /// **'Ad (isteğe bağlı)'**
  String get nameOptional;

  /// No description provided for @qrAdd.
  ///
  /// In tr, this message translates to:
  /// **'QR ile ekle'**
  String get qrAdd;

  /// No description provided for @serverPrivacyNote.
  ///
  /// In tr, this message translates to:
  /// **'Şifren saklanmaz; yalnızca oturum anahtarı cihazının güvenli kasasında tutulur.'**
  String get serverPrivacyNote;

  /// No description provided for @listPrivacyNote.
  ///
  /// In tr, this message translates to:
  /// **'Liste adresi yalnızca bu cihazda saklanır.'**
  String get listPrivacyNote;

  /// No description provided for @connect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlan'**
  String get connect;

  /// No description provided for @addAndLoad.
  ///
  /// In tr, this message translates to:
  /// **'Ekle ve yükle'**
  String get addAndLoad;

  /// No description provided for @qrTitle.
  ///
  /// In tr, this message translates to:
  /// **'QR kodu okut'**
  String get qrTitle;

  /// No description provided for @qrCameraDenied.
  ///
  /// In tr, this message translates to:
  /// **'Kameraya erişilemedi. Ayarlar\'dan OtoTV için kamera iznini aç.'**
  String get qrCameraDenied;

  /// No description provided for @qrHint.
  ///
  /// In tr, this message translates to:
  /// **'Liste adresini içeren QR kodu çerçeveye hizala'**
  String get qrHint;

  /// No description provided for @plusCardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Araç Modu, sınırsız kaynak ve daha fazlası'**
  String get plusCardSubtitle;

  /// No description provided for @plusActive.
  ///
  /// In tr, this message translates to:
  /// **'Plus aktif'**
  String get plusActive;

  /// No description provided for @plusActiveSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm özellikler açık. Teşekkürler!'**
  String get plusActiveSubtitle;

  /// No description provided for @sectionMedia.
  ///
  /// In tr, this message translates to:
  /// **'Medya'**
  String get sectionMedia;

  /// No description provided for @manageSources.
  ///
  /// In tr, this message translates to:
  /// **'Kaynakları yönet'**
  String get manageSources;

  /// No description provided for @sourceCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kaynak'**
  String sourceCount(int count);

  /// No description provided for @sectionPreferences.
  ///
  /// In tr, this message translates to:
  /// **'Tercihler'**
  String get sectionPreferences;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem dili'**
  String get languageSystem;

  /// No description provided for @sectionLegal.
  ///
  /// In tr, this message translates to:
  /// **'Yasal'**
  String get sectionLegal;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @terms.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları (EULA)'**
  String get terms;

  /// No description provided for @sectionAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get sectionAbout;

  /// No description provided for @help.
  ///
  /// In tr, this message translates to:
  /// **'Yardım ve SSS'**
  String get help;

  /// No description provided for @version.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm'**
  String get version;

  /// No description provided for @disclaimer.
  ///
  /// In tr, this message translates to:
  /// **'{appName} yalnızca bir oynatıcıdır; içerik sağlamaz. Eklediğiniz listeleri kullanma hakkına sahip olmaktan siz sorumlusunuz.'**
  String disclaimer(String appName);

  /// No description provided for @paywallCarModeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Araç Modu'**
  String get paywallCarModeTitle;

  /// No description provided for @paywallCarModeBody.
  ///
  /// In tr, this message translates to:
  /// **'Torpido için yatay, dev kontrollü sinema arayüzü ve Karartma modu'**
  String get paywallCarModeBody;

  /// No description provided for @paywallSourcesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız kaynak'**
  String get paywallSourcesTitle;

  /// No description provided for @paywallSourcesBody.
  ///
  /// In tr, this message translates to:
  /// **'İstediğin kadar M3U, Jellyfin ve Emby'**
  String get paywallSourcesBody;

  /// No description provided for @paywallCarPlayTitle.
  ///
  /// In tr, this message translates to:
  /// **'CarPlay ve Android Auto'**
  String get paywallCarPlayTitle;

  /// No description provided for @paywallCarPlayBody.
  ///
  /// In tr, this message translates to:
  /// **'Kanallarını araç ekranından seç, direksiyondan kontrol et'**
  String get paywallCarPlayBody;

  /// No description provided for @paywallFutureTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm yeni premium özellikler'**
  String get paywallFutureTitle;

  /// No description provided for @paywallFutureBody.
  ///
  /// In tr, this message translates to:
  /// **'Tek üyelikle gelecekteki her şey dahil'**
  String get paywallFutureBody;

  /// No description provided for @planMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get planMonthly;

  /// No description provided for @planMonthlyDesc.
  ///
  /// In tr, this message translates to:
  /// **'İstediğin zaman iptal et'**
  String get planMonthlyDesc;

  /// No description provided for @planAnnual.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get planAnnual;

  /// No description provided for @planAnnualDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yılda tek ödeme'**
  String get planAnnualDesc;

  /// No description provided for @planLifetime.
  ///
  /// In tr, this message translates to:
  /// **'Ömür boyu'**
  String get planLifetime;

  /// No description provided for @planLifetimeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tek ödeme, sonsuza dek senin'**
  String get planLifetimeDesc;

  /// No description provided for @planTrial.
  ///
  /// In tr, this message translates to:
  /// **'{period} ücretsiz dene'**
  String planTrial(String period);

  /// No description provided for @bestValue.
  ///
  /// In tr, this message translates to:
  /// **'EN AVANTAJLI'**
  String get bestValue;

  /// No description provided for @periodDays.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün'**
  String periodDays(int count);

  /// No description provided for @periodWeeks.
  ///
  /// In tr, this message translates to:
  /// **'{count} hafta'**
  String periodWeeks(int count);

  /// No description provided for @periodMonths.
  ///
  /// In tr, this message translates to:
  /// **'{count} ay'**
  String periodMonths(int count);

  /// No description provided for @periodYears.
  ///
  /// In tr, this message translates to:
  /// **'{count} yıl'**
  String periodYears(int count);

  /// No description provided for @paywallCta.
  ///
  /// In tr, this message translates to:
  /// **'Plus\'a geç'**
  String get paywallCta;

  /// No description provided for @paywallCtaTrial.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz denemeyi başlat'**
  String get paywallCtaTrial;

  /// No description provided for @paywallLegal.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Apple / Google hesabından alınır. Abonelik, dönem bitmeden en az 24 saat önce iptal edilmezse otomatik yenilenir. Aboneliğini mağaza hesap ayarlarından yönetebilirsin.'**
  String get paywallLegal;

  /// No description provided for @restorePurchases.
  ///
  /// In tr, this message translates to:
  /// **'Satın alımları geri yükle'**
  String get restorePurchases;

  /// No description provided for @restoreSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Satın alımların geri yüklendi.'**
  String get restoreSuccess;

  /// No description provided for @restoreNone.
  ///
  /// In tr, this message translates to:
  /// **'Geri yüklenecek satın alım bulunamadı.'**
  String get restoreNone;

  /// No description provided for @purchaseSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldin! OtoTV Plus açıldı.'**
  String get purchaseSuccess;

  /// No description provided for @purchaseFailed.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma tamamlanamadı: {message}'**
  String purchaseFailed(String message);

  /// No description provided for @storeUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Mağazaya şu an ulaşılamıyor. Daha sonra tekrar dene.'**
  String get storeUnavailable;

  /// No description provided for @storeNotConfigured.
  ///
  /// In tr, this message translates to:
  /// **'Bu derlemede mağaza bağlantısı yapılandırılmadı.'**
  String get storeNotConfigured;

  /// No description provided for @freeSourceLimit.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz sürümde en fazla {count} kaynak ekleyebilirsin.'**
  String freeSourceLimit(int count);

  /// No description provided for @libraryOpenFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kitaplık açılamadı'**
  String get libraryOpenFailed;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Burası boş'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu kitaplıkta henüz içerik yok.'**
  String get libraryEmptyMessage;

  /// No description provided for @seasonsFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sezonlar alınamadı'**
  String get seasonsFailed;

  /// No description provided for @noEpisodesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm yok'**
  String get noEpisodesTitle;

  /// No description provided for @noEpisodesMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu dizi için sunucuda bölüm bulunamadı.'**
  String get noEpisodesMessage;

  /// No description provided for @continueWatching.
  ///
  /// In tr, this message translates to:
  /// **'İzlemeye devam et'**
  String get continueWatching;

  /// No description provided for @minutesLeft.
  ///
  /// In tr, this message translates to:
  /// **'{count} dk kaldı'**
  String minutesLeft(int count);

  /// No description provided for @minutes.
  ///
  /// In tr, this message translates to:
  /// **'{count} dk'**
  String minutes(int count);

  /// No description provided for @errInvalidAddress.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz adres.'**
  String get errInvalidAddress;

  /// No description provided for @errHttpStatus.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu {code} döndürdü.'**
  String errHttpStatus(int code);

  /// No description provided for @errNoPlayable.
  ///
  /// In tr, this message translates to:
  /// **'Listede oynatılabilir öğe bulunamadı.'**
  String get errNoPlayable;

  /// No description provided for @errDownload.
  ///
  /// In tr, this message translates to:
  /// **'Liste indirilemedi. Adresi ve internet bağlantını kontrol et.'**
  String get errDownload;

  /// No description provided for @errServerUnexpected.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu beklenmeyen bir yanıt verdi.'**
  String get errServerUnexpected;

  /// No description provided for @errNoSession.
  ///
  /// In tr, this message translates to:
  /// **'Oturum bulunamadı; sunucuyu yeniden ekle.'**
  String get errNoSession;

  /// No description provided for @errUnreachable.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuya ulaşılamadı. Adresi ve ağ bağlantını kontrol et.'**
  String get errUnreachable;

  /// No description provided for @errSessionExpired.
  ///
  /// In tr, this message translates to:
  /// **'Oturum süresi doldu; sunucuyu yeniden ekle.'**
  String get errSessionExpired;

  /// No description provided for @errBadCredentials.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı veya şifre hatalı.'**
  String get errBadCredentials;

  /// No description provided for @errServerNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu adreste {kind} sunucusu bulunamadı.'**
  String errServerNotFound(String kind);

  /// No description provided for @errServerStatus.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu hatası ({code}).'**
  String errServerStatus(int code);

  /// No description provided for @errUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu.'**
  String get errUnknown;

  /// No description provided for @notificationChannel.
  ///
  /// In tr, this message translates to:
  /// **'Oynatma'**
  String get notificationChannel;

  /// No description provided for @notificationChannelDesc.
  ///
  /// In tr, this message translates to:
  /// **'Ekran kapalıyken oynatma kontrolleri'**
  String get notificationChannelDesc;

  /// No description provided for @carFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get carFavorites;

  /// No description provided for @carChannels.
  ///
  /// In tr, this message translates to:
  /// **'Kanallar'**
  String get carChannels;

  /// No description provided for @carContinue.
  ///
  /// In tr, this message translates to:
  /// **'{server} · İzlemeye devam et'**
  String carContinue(String server);

  /// No description provided for @carNoSources.
  ///
  /// In tr, this message translates to:
  /// **'Kanal eklemek için telefonda OtoTV\'yi aç'**
  String get carNoSources;

  /// No description provided for @carEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Burada henüz bir şey yok'**
  String get carEmpty;

  /// No description provided for @previewNotice.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme: mağaza bağlanınca gerçek fiyatlar burada görünür.'**
  String get previewNotice;

  /// No description provided for @previewPurchase.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme modu: satın alma mağaza bağlanınca çalışır.'**
  String get previewPurchase;

  /// No description provided for @carPlusRequired.
  ///
  /// In tr, this message translates to:
  /// **'Araç ekranı OtoTV Plus ile açılır'**
  String get carPlusRequired;

  /// No description provided for @castConnectedAndroidAuto.
  ///
  /// In tr, this message translates to:
  /// **'Android Auto bağlı'**
  String get castConnectedAndroidAuto;

  /// No description provided for @castConnectedAutomotive.
  ///
  /// In tr, this message translates to:
  /// **'Araç sistemi bağlı'**
  String get castConnectedAutomotive;

  /// No description provided for @castConnectedCarPlay.
  ///
  /// In tr, this message translates to:
  /// **'CarPlay bağlı'**
  String get castConnectedCarPlay;

  /// No description provided for @castConnectedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Araç ekranındaki uygulamalardan OtoTV\'yi aç. Kanal seçince sesi araç hoparlöründen çalar; video telefonda Araç Modu\'nda oynar.'**
  String get castConnectedMessage;

  /// No description provided for @castNeedsPlus.
  ///
  /// In tr, this message translates to:
  /// **'Araç ekranında OtoTV\'yi kullanmak için Plus gerekli.'**
  String get castNeedsPlus;

  /// No description provided for @castGetPlus.
  ///
  /// In tr, this message translates to:
  /// **'Plus\'ı incele'**
  String get castGetPlus;

  /// No description provided for @castConnectedAudioMessage.
  ///
  /// In tr, this message translates to:
  /// **'iPhone\'un CarPlay\'e bağlı. OtoTV\'de açtığın kanalın sesi araç hoparlöründen çalar.'**
  String get castConnectedAudioMessage;

  /// No description provided for @testBuildBadge.
  ///
  /// In tr, this message translates to:
  /// **'TEST SÜRÜMÜ · Plus mağazasız açık'**
  String get testBuildBadge;

  /// No description provided for @airplayTooltip.
  ///
  /// In tr, this message translates to:
  /// **'AirPlay ile araç ekranına gönder'**
  String get airplayTooltip;

  /// No description provided for @castAirplayTitle.
  ///
  /// In tr, this message translates to:
  /// **'Park halinde araç ekranında izle'**
  String get castAirplayTitle;

  /// No description provided for @castAirplayBody.
  ///
  /// In tr, this message translates to:
  /// **'iPhone\'da oynatıcıdaki AirPlay düğmesine dokun ve listeden aracını seç. iOS 26+ ve destekleyen araçlarda, yalnızca park halinde çalışır.'**
  String get castAirplayBody;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'tr':
      return L10nTr();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
