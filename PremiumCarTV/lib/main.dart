import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/brand.dart';
import 'core/theme.dart';
import 'features/shell/app_shell.dart';
import 'state/background_audio.dart';
import 'state/providers.dart';
import 'l10n/l10n.dart';
import 'state/locale.dart';
import 'state/premium.dart';
import 'platform/carplay_bridge.dart';
import 'state/car_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: AppColors.background,
  ));
  final (prefs, audio) = await (SharedPreferences.getInstance(), initBackgroundAudio()).wait;

  final container = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(prefs),
    audioHandlerProvider.overrideWithValue(audio),
  ]);

  // Araç ekranları (Android Auto / CarPlay) uygulama arayüzü hiç açılmadan
  // bağlanabilir; oynatıcı ve katalog bu yüzden burada, arayüzden önce kurulur.
  container.read(playerProvider);
  final catalog = container.read(carCatalogProvider);
  audio?.attachCatalog(catalog);
  CarPlayBridge.attach(catalog);

  runApp(UncontrolledProviderScope(container: container, child: const OtoTvApp()));
}

class OtoTvApp extends ConsumerWidget {
  const OtoTvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Plus durumunu açılışta yüklemeye başla.
    ref.watch(premiumProvider);
    return MaterialApp(
      title: Brand.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: ref.watch(localeProvider),
      localeResolutionCallback: (device, _) => resolveLocale(device),
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: L10n.localizationsDelegates,
      home: const AppShell(),
    );
  }
}
