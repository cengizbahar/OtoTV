import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../l10n/l10n.dart';
import 'locale.dart';
import 'car_catalog.dart';

/// Kilit ekranı, bildirim, kulaklık ve araç tuşlarından gelen komutları
/// oynatıcıya iletir; ekran kapalıyken yayının sürmesini sağlar.
class OtoAudioHandler extends BaseAudioHandler with SeekHandler {
  Player? _player;
  CarCatalog? _catalog;

  /// Android Auto (ve kilit ekranı "son çalınanlar") için içerik ağacı.
  void attachCatalog(CarCatalog catalog) => _catalog = catalog;
  Future<void> Function()? _onNext;
  Future<void> Function()? _onPrevious;
  Future<void> Function()? _onStop;

  static Future<OtoAudioHandler> init() async {
    // Bildirim kanalı adı sistem ayarlarında görünür; telefon diliyle adlandır.
    final l = lookupL10n(effectiveLocale(null));
    final session = await AudioSession.instance;
    // iOS: sessiz anahtarı ve ekran kilidi oynatmayı kesmesin.
    await session.configure(const AudioSessionConfiguration.music());
    return AudioService.init(
      builder: OtoAudioHandler.new,
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.ototvplus.app.playback',
        androidNotificationChannelName: l.notificationChannel,
        androidNotificationChannelDescription: l.notificationChannelDesc,
        androidNotificationIcon: 'drawable/ic_stat_ototv',
        notificationColor: AppColors.gold,
        androidStopForegroundOnPause: false,
        // Android Auto: klasörler liste, kanallar ızgara olarak gösterilsin.
        androidBrowsableRootExtras: {
          'android.media.browse.CONTENT_STYLE_SUPPORTED': true,
          'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': 1,
          'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT': 2,
        },
      ),
    );
  }

  /// [PlayerNotifier] oluşturulunca bağlanır.
  void attach({
    required Player player,
    required Future<void> Function() onNext,
    required Future<void> Function() onPrevious,
    required Future<void> Function() onStop,
  }) {
    _player = player;
    _onNext = onNext;
    _onPrevious = onPrevious;
    _onStop = onStop;
    player.stream.playing.listen((_) => _broadcast());
    player.stream.buffering.listen((_) => _broadcast());
    player.stream.completed.listen((_) => _broadcast());
  }

  void setNowPlaying(Channel c, {required bool hasQueue}) {
    _hasQueue = hasQueue;
    mediaItem.add(MediaItem(
      id: c.key,
      title: c.name,
      album: c.group,
      artist: 'OtoTV',
      artUri: c.logo == null ? null : Uri.tryParse(c.logo!),
      artHeaders: c.extraHeaders.isEmpty ? null : c.extraHeaders,
      isLive: !c.isServerItem,
    ));
    _broadcast();
  }

  void clear() {
    mediaItem.add(null);
    playbackState.add(PlaybackState(processingState: AudioProcessingState.idle));
  }

  bool _hasQueue = false;

  void _broadcast() {
    final p = _player;
    if (p == null) return;
    final playing = p.state.playing;
    playbackState.add(PlaybackState(
      controls: [
        if (_hasQueue) MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        if (_hasQueue) MediaControl.skipToNext,
        MediaControl.stop,
      ],
      androidCompactActionIndices: _hasQueue ? const [0, 1, 2] : const [0],
      systemActions: const {MediaAction.seek},
      processingState: p.state.buffering
          ? AudioProcessingState.buffering
          : AudioProcessingState.ready,
      playing: playing,
      updatePosition: p.state.position,
      bufferedPosition: p.state.buffer,
    ));
  }

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic>? options]) async {
    final catalog = _catalog;
    if (catalog == null) return const [];
    final id = parentMediaId == AudioService.recentRootId ? CarCatalog.favorites : parentMediaId;
    final nodes = await catalog.children(id);
    return [
      for (final n in nodes)
        MediaItem(
          id: n.id,
          title: n.title,
          displaySubtitle: n.subtitle,
          artUri: n.artUri == null ? null : Uri.tryParse(n.artUri!),
          playable: n.playable,
        ),
    ];
  }

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    await _catalog?.play(mediaId);
  }

  @override
  Future<void> play() async => _player?.play();

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> seek(Duration position) async => _player?.seek(position);

  @override
  Future<void> skipToNext() async => _onNext?.call();

  @override
  Future<void> skipToPrevious() async => _onPrevious?.call();

  @override
  Future<void> stop() async {
    await _onStop?.call();
    await super.stop();
  }
}

/// `main()` beklemeden başlatılabilsin diye, kurulamazsa null kalır
/// (ör. testlerde ya da desteklenmeyen platformlarda).
Future<OtoAudioHandler?> initBackgroundAudio() async {
  try {
    return await OtoAudioHandler.init();
  } catch (e) {
    debugPrint('Arka plan sesi başlatılamadı: $e');
    return null;
  }
}
