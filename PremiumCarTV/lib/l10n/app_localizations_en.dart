// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Your cinema on the road';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get play => 'Play';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get refresh => 'Refresh';

  @override
  String get homePage => 'Home';

  @override
  String get otherGroup => 'Other';

  @override
  String get navHome => 'Home';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navCast => 'Car Screen';

  @override
  String get navSettings => 'Settings';

  @override
  String get searchHint => 'Search channels, movies or shows';

  @override
  String get libraryLoadFailed => 'Couldn\'t load your library';

  @override
  String get emptyHomeTitle => 'Your cinema is ready';

  @override
  String get emptyHomeMessage =>
      'Add your M3U playlist or Jellyfin/Emby server and your channels will appear here, neatly grouped.';

  @override
  String get sourcesUnreachable => 'Couldn\'t reach your sources';

  @override
  String get addSource => 'Add source';

  @override
  String get heroFavorite => 'YOUR FAVORITE';

  @override
  String get heroWatchNow => 'WATCH NOW';

  @override
  String channelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count channels',
      one: '1 channel',
    );
    return '$_temp0';
  }

  @override
  String get noResults => 'No results';

  @override
  String get noResultsMessage => 'Try a different word.';

  @override
  String sourcesFailed(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources failed to load',
      one: '1 source failed to load',
    );
    return '$_temp0: $names';
  }

  @override
  String get apps => 'Apps';

  @override
  String get appInside => 'Inside OtoTV';

  @override
  String get appInBrowser => 'Opens in browser';

  @override
  String appOpenFailed(String name) {
    return 'Couldn\'t open $name.';
  }

  @override
  String get nowPlayingBadge => 'NOW PLAYING';

  @override
  String favoriteAdded(String name) {
    return '$name added to favorites';
  }

  @override
  String favoriteRemoved(String name) {
    return '$name removed from favorites';
  }

  @override
  String get carMode => 'Car Mode';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get epgNext => 'NEXT';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyMessage =>
      'Long-press any channel to add it here — your best picks, one tap away.';

  @override
  String get browseChannels => 'Browse channels';

  @override
  String get castPhone => 'Phone';

  @override
  String get castCarScreen => 'Car screen';

  @override
  String get castNotConnected => 'No car connected';

  @override
  String get castNotConnectedMessage =>
      'Connect your iPhone to CarPlay or your Android phone to your car; OtoTV detects it automatically.';

  @override
  String get castStep1Title => 'Connect your car';

  @override
  String get castStep1Body =>
      'With a USB cable or wireless CarPlay / Android Auto.';

  @override
  String get castStep2Title => 'Pick something to watch';

  @override
  String get castStep2Body =>
      'Open a channel, a movie or an episode from your own server.';

  @override
  String get castStep3Title => 'Open it on the car screen';

  @override
  String get castStep3Body =>
      'Pick OtoTV from the apps on your car screen and tap a channel; its sound plays in the car.';

  @override
  String get passengerNotice =>
      'For passengers only. The driver must never watch video while driving.';

  @override
  String get openCarMode => 'Open Car Mode';

  @override
  String get openChannelFirst => 'Open a channel or movie from Home first.';

  @override
  String get dim => 'Dim';

  @override
  String get wakeHint => 'Double-tap to wake';

  @override
  String get sources => 'Sources';

  @override
  String get sourcesEmptyTitle => 'No sources yet';

  @override
  String get sourcesEmptyMessage =>
      'Add your M3U playlist or Jellyfin / Emby server. Addresses and sign-in details stay on this device.';

  @override
  String get addFirstSource => 'Add your first source';

  @override
  String get rename => 'Rename';

  @override
  String get remove => 'Remove';

  @override
  String get serverUrlRequired => 'Enter the server address.';

  @override
  String get listUrlRequired => 'Enter the playlist address.';

  @override
  String get usernameRequired => 'Enter your username.';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get qrAdd => 'Add with QR';

  @override
  String get serverPrivacyNote =>
      'Your password is never stored; only a session key is kept in your device\'s secure storage.';

  @override
  String get listPrivacyNote =>
      'The playlist address is stored only on this device.';

  @override
  String get connect => 'Connect';

  @override
  String get addAndLoad => 'Add and load';

  @override
  String get qrTitle => 'Scan QR code';

  @override
  String get qrCameraDenied =>
      'Couldn\'t access the camera. Allow camera access for OtoTV in Settings.';

  @override
  String get qrHint => 'Line up the QR code containing your playlist address';

  @override
  String get plusCardSubtitle => 'Car Mode, unlimited sources and more';

  @override
  String get plusActive => 'Plus is active';

  @override
  String get plusActiveSubtitle => 'Everything is unlocked. Thank you!';

  @override
  String get sectionMedia => 'Media';

  @override
  String get manageSources => 'Manage sources';

  @override
  String sourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources',
      one: '1 source',
    );
    return '$_temp0';
  }

  @override
  String get sectionPreferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get sectionLegal => 'Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get terms => 'Terms of Use (EULA)';

  @override
  String get sectionAbout => 'About';

  @override
  String get help => 'Help & FAQ';

  @override
  String get version => 'Version';

  @override
  String disclaimer(String appName) {
    return '$appName is only a player and provides no content. You are responsible for having the rights to the playlists you add.';
  }

  @override
  String get paywallCarModeTitle => 'Car Mode';

  @override
  String get paywallCarModeBody =>
      'A landscape cinema interface with giant controls for the dashboard, plus Dim mode';

  @override
  String get paywallSourcesTitle => 'Unlimited sources';

  @override
  String get paywallSourcesBody =>
      'As many M3U, Jellyfin and Emby sources as you like';

  @override
  String get paywallCarPlayTitle => 'CarPlay & Android Auto';

  @override
  String get paywallCarPlayBody =>
      'Pick channels on the car screen, control them from the steering wheel';

  @override
  String get paywallFutureTitle => 'Every new premium feature';

  @override
  String get paywallFutureBody => 'One membership, everything to come included';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planMonthlyDesc => 'Cancel anytime';

  @override
  String get planAnnual => 'Yearly';

  @override
  String get planAnnualDesc => 'One payment a year';

  @override
  String get planLifetime => 'Lifetime';

  @override
  String get planLifetimeDesc => 'Pay once, yours forever';

  @override
  String planTrial(String period) {
    return 'Try $period free';
  }

  @override
  String get bestValue => 'BEST VALUE';

  @override
  String periodDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String periodWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String periodMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String periodYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get paywallCta => 'Get Plus';

  @override
  String get paywallCtaTrial => 'Start free trial';

  @override
  String get paywallLegal =>
      'Payment is charged to your Apple / Google account. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the period. Manage your subscription in your store account settings.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restoreSuccess => 'Your purchases have been restored.';

  @override
  String get restoreNone => 'No purchases to restore were found.';

  @override
  String get purchaseSuccess => 'Welcome! OtoTV Plus is unlocked.';

  @override
  String purchaseFailed(String message) {
    return 'Purchase couldn\'t be completed: $message';
  }

  @override
  String get storeUnavailable =>
      'The store can\'t be reached right now. Please try again later.';

  @override
  String get storeNotConfigured =>
      'The store connection isn\'t configured in this build.';

  @override
  String freeSourceLimit(int count) {
    return 'The free plan allows up to $count sources.';
  }

  @override
  String get libraryOpenFailed => 'Couldn\'t open the library';

  @override
  String get libraryEmptyTitle => 'Nothing here yet';

  @override
  String get libraryEmptyMessage =>
      'This library doesn\'t have any content yet.';

  @override
  String get seasonsFailed => 'Couldn\'t load seasons';

  @override
  String get noEpisodesTitle => 'No episodes';

  @override
  String get noEpisodesMessage => 'The server has no episodes for this show.';

  @override
  String get continueWatching => 'Continue watching';

  @override
  String minutesLeft(int count) {
    return '$count min left';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get errInvalidAddress => 'Invalid address.';

  @override
  String errHttpStatus(int code) {
    return 'The server returned $code.';
  }

  @override
  String get errNoPlayable => 'No playable items were found in the playlist.';

  @override
  String get errDownload =>
      'Couldn\'t download the playlist. Check the address and your connection.';

  @override
  String get errServerUnexpected => 'The server sent an unexpected response.';

  @override
  String get errNoSession => 'No session found; please add the server again.';

  @override
  String get errUnreachable =>
      'Couldn\'t reach the server. Check the address and your network.';

  @override
  String get errSessionExpired =>
      'Your session has expired; please add the server again.';

  @override
  String get errBadCredentials => 'Wrong username or password.';

  @override
  String errServerNotFound(String kind) {
    return 'No $kind server was found at this address.';
  }

  @override
  String errServerStatus(int code) {
    return 'Server error ($code).';
  }

  @override
  String get errUnknown => 'Something unexpected went wrong.';

  @override
  String get notificationChannel => 'Playback';

  @override
  String get notificationChannelDesc =>
      'Playback controls while the screen is off';

  @override
  String get carFavorites => 'Favorites';

  @override
  String get carChannels => 'Channels';

  @override
  String carContinue(String server) {
    return '$server · Continue watching';
  }

  @override
  String get carNoSources => 'Open OtoTV on your phone to add channels';

  @override
  String get carEmpty => 'Nothing here yet';

  @override
  String get previewNotice =>
      'Preview: real prices appear here once the store is connected.';

  @override
  String get previewPurchase =>
      'Preview mode: purchasing works once the store is connected.';

  @override
  String get carPlusRequired => 'The car screen is unlocked with OtoTV Plus';

  @override
  String get castConnectedAndroidAuto => 'Android Auto connected';

  @override
  String get castConnectedAutomotive => 'Car system connected';

  @override
  String get castConnectedCarPlay => 'CarPlay connected';

  @override
  String get castConnectedMessage =>
      'Open OtoTV from the apps on your car screen. Picking a channel plays its sound through the car speakers; video plays on your phone in Car Mode.';

  @override
  String get castNeedsPlus => 'OtoTV on the car screen requires Plus.';

  @override
  String get castGetPlus => 'See Plus';

  @override
  String get castConnectedAudioMessage =>
      'Your iPhone is connected to CarPlay. Sound from the channel you open in OtoTV plays through the car speakers.';

  @override
  String get testBuildBadge => 'TEST BUILD · Plus unlocked without store';
}
