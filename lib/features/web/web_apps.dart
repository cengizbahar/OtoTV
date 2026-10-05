import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// OtoTV'den açılabilen dış hizmetler.
///
/// [inApp] olanlar hizmetin kendi mobil sitesiyle OtoTV içinde (WebView)
/// açılır; API anahtarı gerekmez. Diğerleri telefondaki uygulamayı açar.
class WebApp {
  const WebApp({
    required this.name,
    required this.url,
    required this.color,
    required this.icon,
    this.inApp = true,
    this.allowedHosts = const [],
    this.playStoreId,
    this.appStoreUrl,
    this.browser = false,
  });

  final String name;
  final String url;
  final Color color;
  final IconData icon;
  final bool inApp;

  /// OtoTV içinde gezinmeye izin verilen alan adları; dışındakiler engellenir.
  final List<String> allowedHosts;

  /// Uygulama yüklü değilse açılacak mağaza sayfası.
  final String? playStoreId;
  final String? appStoreUrl;

  /// true: uygulama yerine sistem tarayıcısında aç.
  final bool browser;

  bool allows(Uri uri) {
    if (uri.scheme == 'about' || uri.scheme == 'data' || uri.scheme == 'blob') return true;
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    return allowedHosts.any((h) => uri.host == h || uri.host.endsWith('.$h'));
  }
}

abstract final class WebApps {
  static const youtube = WebApp(
    name: 'YouTube',
    url: 'https://m.youtube.com/',
    color: Color(0xFFFF0033),
    icon: Icons.smart_display_rounded,
    // Google girişi bilerek yok: accounts.google.com izinli değil.
    allowedHosts: ['youtube.com', 'youtu.be', 'gstatic.com', 'ggpht.com', 'ytimg.com', 'googlevideo.com'],
  );

  /// Netflix sitesi OtoTV içinde açılır (giriş, göz atma). Netflix, gömülü
  /// tarayıcıda video oynatmayı kendi tarafında engelleyebilir.
  static const netflix = WebApp(
    name: 'Netflix',
    url: 'https://www.netflix.com/',
    color: Color(0xFFE50914),
    icon: Icons.movie_filter_rounded,
    allowedHosts: ['netflix.com', 'nflxext.com', 'nflximg.net', 'nflxvideo.net', 'nflxso.net'],
  );

  static const all = [youtube, netflix];
}

/// Telefonda yüklü uygulamayı açar (Android App Links / iOS Universal Links).
/// Uygulama yoksa mağaza sayfasına gider; mobil siteler telefonda oynatmaz.
Future<bool> launchExternalApp(WebApp app) async {
  if (app.browser) {
    // Custom Tab / SFSafariViewController: App Links'i atlar, uygulamayı açmaz.
    return launchUrl(Uri.parse(app.url), mode: LaunchMode.inAppBrowserView);
  }
  try {
    if (await launchUrl(Uri.parse(app.url), mode: LaunchMode.externalNonBrowserApplication)) {
      return true;
    }
  } catch (_) {}
  final store = Platform.isIOS
      ? app.appStoreUrl
      : (app.playStoreId == null ? null : 'market://details?id=${app.playStoreId}');
  if (store == null) return false;
  try {
    return await launchUrl(Uri.parse(store), mode: LaunchMode.externalApplication);
  } catch (_) {
    // Play Store yoksa (ör. emülatör) web sayfası.
    return launchUrl(
      Uri.parse('https://play.google.com/store/apps/details?id=${app.playStoreId}'),
      mode: LaunchMode.externalApplication,
    );
  }
}
