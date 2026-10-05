import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ototv/data/epg.dart';
import 'package:ototv/data/m3u_parser.dart';
import 'package:ototv/data/models.dart';
import 'package:ototv/state/car_catalog.dart';
import 'package:ototv/state/locale.dart';
import 'package:ototv/state/providers.dart';
import 'package:ototv/state/premium.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePremium extends PremiumNotifier {
  _FakePremium(this.plus);
  final bool plus;

  @override
  PremiumState build() => PremiumState(isPlus: plus, ready: true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channels = [
    Channel(name: 'TRT 1', url: 'http://a/1', group: 'Ulusal'),
    Channel(name: 'ATV', url: 'http://a/2', group: 'Ulusal'),
    Channel(name: 'Kral Pop', url: 'http://a/3', group: 'Müzik'),
    Channel(name: 'Grupsuz', url: 'http://a/4'),
  ];

  Future<ProviderContainer> container({List<String> favorites = const [], bool empty = false, bool plus = true}) async {
    SharedPreferences.setMockInitialValues({'favorites.v1': favorites, 'locale': 'tr'});
    final prefs = await SharedPreferences.getInstance();
    final lib = empty
        ? Library.empty
        : Library(channels: channels, groups: M3uParser.group(channels), errors: const {});
    final c = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(prefs),
      libraryProvider.overrideWith((ref) async => lib),
      epgProvider.overrideWith((ref) async => EpgIndex.empty),
      premiumProvider.overrideWith(() => _FakePremium(plus)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('kök: favoriler ve kanallar klasörleri', () async {
    final c = await container();
    final root = await c.read(carCatalogProvider).children(CarCatalog.root);
    expect(root.map((n) => n.id), [CarCatalog.favorites, CarCatalog.groups]);
    expect(root.map((n) => n.title), ['Favoriler', 'Kanallar']);
    expect(root.every((n) => !n.playable), isTrue);
    expect(root[1].subtitle, '4 kanal');
  });

  test('gruplar ve grup içeriği; grupsuz kanallar "Diğer"', () async {
    final catalog = (await container()).read(carCatalogProvider);
    final groups = await catalog.children(CarCatalog.groups);
    expect(groups.map((n) => n.title), ['Ulusal', 'Müzik', 'Diğer']);

    final ulusal = await catalog.children(groups.first.id);
    expect(ulusal.map((n) => n.title), ['TRT 1', 'ATV']);
    expect(ulusal.every((n) => n.playable), isTrue);
    expect(ulusal.first.id, 'http://a/1');
  });

  test('favoriler sırayla gelir; boşsa bilgilendirme satırı', () async {
    final withFav = (await container(favorites: ['http://a/3'])).read(carCatalogProvider);
    expect((await withFav.children(CarCatalog.favorites)).single.title, 'Kral Pop');

    final noFav = (await container()).read(carCatalogProvider);
    final empty = await noFav.children(CarCatalog.favorites);
    expect(empty.single.playable, isFalse);
  });

  test('kaynak yoksa telefona yönlendirir', () async {
    final catalog = (await container(empty: true)).read(carCatalogProvider);
    final root = await catalog.children(CarCatalog.root);
    expect(root.single.title, contains('telefonda'));
  });

  test('Plus değilse araç ekranı kilitli', () async {
    final catalog = (await container(plus: false)).read(carCatalogProvider);
    final root = await catalog.children(CarCatalog.root);
    expect(root.single.title, contains('Plus'));
    expect(root.single.playable, isFalse);
    expect(await catalog.children(CarCatalog.groups), isEmpty);
  });

  test('İngilizce seçiliyse başlıklar İngilizce', () async {
    final c = await container();
    await c.read(localeProvider.notifier).set(const Locale('en'));
    final root = await c.read(carCatalogProvider).children(CarCatalog.root);
    expect(root.map((n) => n.title), ['Favorites', 'Channels']);
    expect(root[1].subtitle, '4 channels');
  });
}
