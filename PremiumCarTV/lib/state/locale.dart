import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Uygulama dili. null = telefonun dilini izle; kullanıcı Ayarlar'dan sabitleyebilir.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'locale';
  static const supported = [Locale('tr'), Locale('en')];

  @override
  Locale? build() {
    final code = ref.read(prefsProvider).getString(_key);
    return code == null ? null : Locale(code);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    final prefs = ref.read(prefsProvider);
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}

/// Telefon Türkçe ise Türkçe, diğer tüm dillerde İngilizce.
Locale resolveLocale(Locale? device) =>
    device?.languageCode == 'tr' ? const Locale('tr') : const Locale('en');

/// Uygulamanın o an kullandığı dil (seçim yoksa telefonun dili).
Locale effectiveLocale(Locale? chosen) =>
    chosen ?? resolveLocale(WidgetsBinding.instance.platformDispatcher.locale);
