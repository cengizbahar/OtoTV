import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/epg.dart';
import '../data/epg_repository.dart';
import '../data/m3u_parser.dart';
import '../data/media_server_client.dart';
import '../data/models.dart';
import '../data/secret_store.dart';
import '../data/source_repository.dart';
import 'background_audio.dart';
import '../platform/airplay.dart';

/// `main()` içinde gerçek örnekle override edilir.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider override edilmedi'),
);

/// `main()` içinde başlatılıp override edilir; testlerde null.
final audioHandlerProvider = Provider<OtoAudioHandler?>((ref) => null);

final secretStoreProvider = Provider<SecretStore>((ref) => const SecureSecretStore());

final repositoryProvider =
    Provider<SourceRepository>((ref) => SourceRepository(ref.watch(prefsProvider)));

/// Sunuculara kendimizi tanıtırken kullanılan, bu kuruluma özgü rastgele kimlik.
final deviceIdProvider = Provider<String>((ref) {
  final prefs = ref.watch(prefsProvider);
  const key = 'device.id';
  final existing = prefs.getString(key);
  if (existing != null) return existing;
  final id = const Uuid().v4();
  prefs.setString(key, id);
  return id;
});

String _tokenKey(String sourceId) => 'token.$sourceId';

// ───────────────────────── Kaynaklar ─────────────────────────

final sourcesProvider =
    NotifierProvider<SourcesNotifier, List<MediaSource>>(SourcesNotifier.new);

class SourcesNotifier extends Notifier<List<MediaSource>> {
  SourceRepository get _repo => ref.read(repositoryProvider);

  @override
  List<MediaSource> build() => _repo.loadSources();

  Future<MediaSource> addM3u({required String url, String? name}) async {
    final trimmed = url.trim();
    final source = MediaSource(
      id: const Uuid().v4(),
      name: _nameOr(name, _hostName(trimmed)),
      kind: SourceKind.m3u,
      url: trimmed,
      addedAt: DateTime.now(),
    );
    // Kaydetmeden önce listenin gerçekten açıldığını doğrula.
    await _repo.fetchChannels(source, forceRefresh: true);
    await _append(source);
    return source;
  }

  /// Giriş yapar; yalnızca erişim anahtarını kasaya yazar, şifre saklanmaz.
  Future<MediaSource> addServer({
    required SourceKind kind,
    required String url,
    required String username,
    required String password,
    String? name,
  }) async {
    final client = MediaServerClient(
      kind: kind,
      baseUrl: url,
      deviceId: ref.read(deviceIdProvider),
    );
    final auth = await client.authenticate(username.trim(), password);
    final source = MediaSource(
      id: const Uuid().v4(),
      name: _nameOr(name, auth.serverName ?? kind.label),
      kind: kind,
      url: client.baseUrl,
      userId: auth.userId,
      userName: auth.userName,
      addedAt: DateTime.now(),
    );
    await ref.read(secretStoreProvider).write(_tokenKey(source.id), auth.token);
    await _append(source);
    return source;
  }

  Future<void> rename(String id, String name) async {
    state = [for (final s in state) s.id == id ? s.copyWith(name: name) : s];
    await _repo.saveSources(state);
  }

  Future<void> remove(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _repo.saveSources(state);
    await _repo.clearCache(id);
    await ref.read(secretStoreProvider).delete(_tokenKey(id));
  }

  Future<void> _append(MediaSource source) async {
    state = [...state, source];
    await _repo.saveSources(state);
  }

  static String _nameOr(String? name, String fallback) =>
      (name == null || name.trim().isEmpty) ? fallback : name.trim();

  static String _hostName(String url) =>
      Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? 'M3U';
}

// ───────────────────────── M3U kütüphanesi ─────────────────────────

class Library {
  const Library({required this.channels, required this.groups, required this.errors});
  static const empty = Library(channels: [], groups: [], errors: {});

  final List<Channel> channels;
  final List<ChannelGroup> groups;

  /// Kaynak adı → hata. Bir kaynak bozuksa diğerleri yine gösterilir.
  final Map<String, Object> errors;

  bool get isEmpty => channels.isEmpty;

  Channel? byKey(String key) {
    for (final c in channels) {
      if (c.key == key) return c;
    }
    return null;
  }
}

final libraryProvider = FutureProvider<Library>((ref) async {
  final sources =
      ref.watch(sourcesProvider).where((s) => s.kind == SourceKind.m3u).toList();
  if (sources.isEmpty) return Library.empty;
  final repo = ref.read(repositoryProvider);

  final errors = <String, Object>{};
  final results = await Future.wait(sources.map((s) async {
    try {
      return await repo.fetchChannels(s);
    } catch (e) {
      errors[s.name] = e;
      return const <Channel>[];
    }
  }));
  final channels = results.expand((l) => l).toList();
  return Library(channels: channels, groups: M3uParser.group(channels), errors: errors);
});

// ───────────────────────── TV rehberi (EPG) ─────────────────────────

final epgRepositoryProvider = Provider<EpgRepository>((ref) => EpgRepository());

/// Tüm M3U kaynaklarının rehberleri, yalnızca listedeki kanallara süzülmüş.
/// Kütüphane yüklendikten sonra arka planda gelir; kanallar beklemez.
final epgProvider = FutureProvider<EpgIndex>((ref) async {
  final lib = await ref.watch(libraryProvider.future);
  if (lib.isEmpty) return EpgIndex.empty;
  final repo = ref.read(repositoryProvider);
  final epg = ref.read(epgRepositoryProvider);
  final sources = ref.read(sourcesProvider).where((s) => s.kind == SourceKind.m3u);

  var index = EpgIndex.empty;
  for (final s in sources) {
    final channels = lib.channels.where((c) => c.sourceId == s.id);
    index = index.merge(await epg.load(
      sourceId: s.id,
      urls: repo.epgUrls(s.id),
      wantedIds: {for (final c in channels) ?c.tvgId},
      wantedNames: {for (final c in channels) EpgIndex.normalizeName(c.name)},
    ));
  }
  return index;
});

/// Dakika başında güncellenen saat; "şimdi yayında" ilerlemesini canlı tutar.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  while (true) {
    final now = DateTime.now();
    await Future<void>.delayed(Duration(seconds: 60 - now.second));
    yield DateTime.now();
  }
});

/// Bir kanalın (şimdi, sonra) yayını; rehber yoksa (null, null).
final nowNextProvider = Provider.autoDispose.family<(Programme?, Programme?), Channel>((ref, c) {
  final epg = ref.watch(epgProvider).value;
  if (epg == null || epg.isEmpty || c.isServerItem) return (null, null);
  final now = ref.watch(clockProvider).value ?? DateTime.now();
  return epg.nowNext(c, now.toUtc());
});

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

// ───────────────────────── Jellyfin / Emby ─────────────────────────

final serverSourcesProvider = Provider<List<MediaSource>>(
  (ref) => ref.watch(sourcesProvider).where((s) => s.kind.isServer).toList(),
);

final serverClientProvider =
    FutureProvider.family<MediaServerClient, String>((ref, sourceId) async {
  final source = ref.watch(sourcesProvider).firstWhere((s) => s.id == sourceId);
  final token = await ref.read(secretStoreProvider).read(_tokenKey(sourceId));
  return MediaServerClient(
    kind: source.kind,
    baseUrl: source.url,
    deviceId: ref.read(deviceIdProvider),
    token: token,
    userId: source.userId,
  );
});

final serverViewsProvider =
    FutureProvider.family<List<ServerItem>, String>((ref, sourceId) async {
  final client = await ref.watch(serverClientProvider(sourceId).future);
  return client.views();
});

final serverResumeProvider =
    FutureProvider.family<List<ServerItem>, String>((ref, sourceId) async {
  final client = await ref.watch(serverClientProvider(sourceId).future);
  return client.resume();
});

typedef LibraryArg = ({String sourceId, String libraryId, String? collectionType});

final libraryItemsProvider =
    FutureProvider.family<List<ServerItem>, LibraryArg>((ref, arg) async {
  final client = await ref.watch(serverClientProvider(arg.sourceId).future);
  return client.libraryItems(ServerItem(
    id: arg.libraryId,
    name: '',
    type: 'CollectionFolder',
    collectionType: arg.collectionType,
  ));
});

final seasonsProvider =
    FutureProvider.family<List<ServerItem>, (String, String)>((ref, arg) async {
  final (sourceId, seriesId) = arg;
  final client = await ref.watch(serverClientProvider(sourceId).future);
  return client.seasons(seriesId);
});

final episodesProvider = FutureProvider.family<List<ServerItem>, (String, String, String)>(
    (ref, arg) async {
  final (sourceId, seriesId, seasonId) = arg;
  final client = await ref.watch(serverClientProvider(sourceId).future);
  return client.episodes(seriesId, seasonId);
});

// ───────────────────────── Favoriler ─────────────────────────

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  static const _key = 'favorites.v1';

  @override
  Set<String> build() =>
      (ref.read(prefsProvider).getStringList(_key) ?? const []).toSet();

  bool isFavorite(Channel c) => state.contains(c.key);

  Future<void> toggle(Channel c) async {
    final next = {...state};
    if (!next.remove(c.key)) next.add(c.key);
    state = next;
    await ref.read(prefsProvider).setStringList(_key, next.toList());
  }
}

// ───────────────────────── Oynatıcı ─────────────────────────

class PlaybackState {
  const PlaybackState({this.current, this.queue = const []});
  final Channel? current;
  final List<Channel> queue;
  bool get isActive => current != null;
}

/// Tek, uygulama çapında oynatıcı. Tam ekran, mini oynatıcı ve (ileride)
/// araç ekranı aynı [Player] örneğini paylaşır; geçişte yayın kesilmez.
final playerProvider =
    NotifierProvider<PlayerNotifier, PlaybackState>(PlayerNotifier.new);

class PlayerNotifier extends Notifier<PlaybackState> {
  late final Player player;
  late final VideoController video;
  Timer? _positionTimer;
  StreamSubscription<bool>? _completedSub;

  static const _posPrefix = 'pos.';

  @override
  PlaybackState build() {
    player = Player(
      configuration: const PlayerConfiguration(
        title: 'OtoTV',
        bufferSize: 64 * 1024 * 1024,
      ),
    );
    video = VideoController(player);
    ref.read(audioHandlerProvider)?.attach(
      player: player,
      onNext: next,
      onPrevious: previous,
      onStop: stop,
    );
    // Dizi bölümü bitince sıradakine geç (canlı yayınlarda tetiklenmez).
    _completedSub = player.stream.completed.listen((done) {
      final cur = state.current;
      if (done && cur != null && cur.isServerItem) _advanceWithinQueue();
    });
    ref.onDispose(() {
      _positionTimer?.cancel();
      _completedSub?.cancel();
      player.dispose();
    });
    return const PlaybackState();
  }

  Future<void> play(Channel channel, {List<Channel> queue = const []}) async {
    _onLeave();
    state = PlaybackState(current: channel, queue: queue);
    ref.read(audioHandlerProvider)?.setNowPlaying(channel, hasQueue: queue.length > 1);
    final resumeAt = _savedPosition(channel) ?? channel.startAt;
    await player.open(Media(
      channel.url,
      httpHeaders: channel.httpHeaders,
      start: resumeAt,
    ));
    _positionTimer?.cancel();
    _positionTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _savePosition());
    _report(channel, (c, id) => c.reportStart(id, resumeAt ?? Duration.zero));
  }

  Future<void> next() => _step(1);
  Future<void> previous() => _step(-1);

  Future<void> _step(int delta) async {
    final cur = state.current;
    final q = state.queue;
    if (cur == null || q.length < 2) return;
    final i = q.indexWhere((c) => c.key == cur.key);
    final target = q[(i + delta) % q.length];
    await play(target, queue: q);
  }

  /// Bölüm sırasında sona gelince başa sarmaz, durur.
  Future<void> _advanceWithinQueue() async {
    final cur = state.current!;
    final i = state.queue.indexWhere((c) => c.key == cur.key);
    if (i >= 0 && i < state.queue.length - 1) {
      await play(state.queue[i + 1], queue: state.queue);
    }
  }

  /// iOS: yayını Apple oynatıcısına (AirPlay → CarPlay/TV) devreder. Kullanıcı
  /// oradan dönünce film/bölüm kaldığı yerden OtoTV'de sürer.
  Future<void> handOffToAirPlay() async {
    final cur = state.current;
    if (cur == null) return;
    final live = player.state.duration.inSeconds < 60;
    final pos = player.state.position;
    await player.pause();
    final back = await AirPlay.play(cur, start: live ? null : pos);
    if (!live && back != null) await player.seek(back);
    await player.play();
  }

  Future<void> stop() async {
    _onLeave();
    _positionTimer?.cancel();
    await player.stop();
    state = const PlaybackState();
    ref.read(audioHandlerProvider)?.clear();
  }

  /// Mevcut öğeden ayrılırken konumu yerelde sakla ve sunucuya bildir.
  void _onLeave() {
    final cur = state.current;
    if (cur == null) return;
    _savePosition();
    final pos = player.state.position;
    _report(cur, (c, id) => c.reportStopped(id, pos));
  }

  void _report(Channel c, Future<void> Function(MediaServerClient, String) send) {
    final sourceId = c.sourceId, itemId = c.serverItemId;
    if (sourceId == null || itemId == null) return;
    ref
        .read(serverClientProvider(sourceId).future)
        .then((client) => send(client, itemId))
        .catchError((_) {});
  }

  /// Canlı yayınlarda süre 0'dır; yalnızca film/bölüm için konum saklanır.
  void _savePosition() {
    final cur = state.current;
    if (cur == null) return;
    final pos = player.state.position;
    final dur = player.state.duration;
    if (dur.inSeconds < 60) return;
    final prefs = ref.read(prefsProvider);
    final nearEnd = dur - pos < const Duration(seconds: 30);
    if (nearEnd) {
      prefs.remove('$_posPrefix${cur.key}');
    } else {
      prefs.setInt('$_posPrefix${cur.key}', pos.inSeconds);
    }
  }

  Duration? _savedPosition(Channel c) {
    final s = ref.read(prefsProvider).getInt('$_posPrefix${c.key}');
    return s == null ? null : Duration(seconds: s);
  }
}
