import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/media_server_client.dart';
import '../../state/providers.dart';
import '../player/player_screen.dart';
import 'library_screen.dart';
import 'series_screen.dart';

/// Bir sunucu öğesini aç: oynatılabilirse oynat, diziyse bölümlere git,
/// klasörse içeriğini göster.
Future<void> openServerItem(
  BuildContext context,
  WidgetRef ref, {
  required String sourceId,
  required ServerItem item,
  List<ServerItem> queue = const [],
}) async {
  if (item.type == 'Series') {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SeriesScreen(sourceId: sourceId, series: item),
    ));
    return;
  }
  if (item.isFolder) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LibraryScreen(sourceId: sourceId, library: item),
    ));
    return;
  }
  final client = await ref.read(serverClientProvider(sourceId).future);
  final playable = (queue.isEmpty ? [item] : queue).where((i) => i.isPlayable);
  final channels = [for (final i in playable) client.toChannel(i, sourceId: sourceId)];
  final current = channels.firstWhere((c) => c.serverItemId == item.id);
  await ref.read(playerProvider.notifier).play(current, queue: channels);
  if (context.mounted) openPlayer(context);
}

/// Sunucudan gelen görsel; yoksa ya da yüklenemezse zarif bir yer tutucu.
class ServerImage extends ConsumerWidget {
  const ServerImage({
    super.key,
    required this.sourceId,
    required this.itemId,
    required this.tag,
    this.icon = Icons.movie_outlined,
    this.maxWidth = 480,
    this.imageType = 'Primary',
  });

  final String sourceId;
  final String itemId;
  final String? tag;
  final IconData icon;
  final int maxWidth;

  /// Primary (afiş/küçük resim) veya Backdrop (geniş arka plan).
  final String imageType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = ColoredBox(
      color: AppColors.surfaceHigh,
      child: Center(child: Icon(icon, color: AppColors.textSecondary, size: 32)),
    );
    final client = ref.watch(serverClientProvider(sourceId)).value;
    final url = client?.imageUrl(itemId, tag, maxWidth: maxWidth, type: imageType);
    if (url == null) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      headers: client!.authHeaders,
      errorBuilder: (_, _, _) => placeholder,
      frameBuilder: (_, child, frame, sync) => AnimatedOpacity(
        opacity: sync || frame != null ? 1 : 0,
        duration: const Duration(milliseconds: 280),
        child: child,
      ),
    );
  }
}

/// 2:3 film / dizi afişi.
class PosterCard extends ConsumerWidget {
  const PosterCard({
    super.key,
    required this.sourceId,
    required this.item,
    required this.onTap,
    this.width,
  });

  final String sourceId;
  final ServerItem item;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ServerImage(sourceId: sourceId, itemId: item.id, tag: item.imageTag),
                    if (item.played)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.gold,
                          child: Icon(Icons.check_rounded, size: 16, color: Color(0xFF1A1206)),
                        ),
                      ),
                    if (item.progress > 0)
                      Positioned(left: 0, right: 0, bottom: 0, child: ProgressStrip(item.progress)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (item.year != null)
              Text('${item.year}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// 16:9 kart: izlemeye devam et, kitaplıklar ve bölümler.
class WideCard extends StatelessWidget {
  const WideCard({
    super.key,
    required this.sourceId,
    required this.item,
    required this.onTap,
    this.subtitle,
    this.width,
    this.icon = Icons.movie_outlined,
  });

  final String sourceId;
  final ServerItem item;
  final VoidCallback onTap;
  final String? subtitle;
  final double? width;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ServerImage(
                      sourceId: sourceId,
                      itemId: item.id,
                      tag: item.imageTag,
                      icon: icon,
                    ),
                    if (item.progress > 0) ...[
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC000000)],
                          ),
                        ),
                      ),
                      const Center(
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0x99000000),
                          child: Icon(Icons.play_arrow_rounded, color: AppColors.goldLight, size: 30),
                        ),
                      ),
                      Positioned(left: 0, right: 0, bottom: 0, child: ProgressStrip(item.progress)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (subtitle != null)
              Text(subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class ProgressStrip extends StatelessWidget {
  const ProgressStrip(this.value, {super.key});
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0x55FFFFFF))),
          FractionallySizedBox(
            widthFactor: value,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.goldGradient),
              child: SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

IconData libraryIcon(String? collectionType) => switch (collectionType) {
      'movies' => Icons.movie_rounded,
      'tvshows' => Icons.tv_rounded,
      'music' => Icons.music_note_rounded,
      'livetv' => Icons.live_tv_rounded,
      _ => Icons.video_library_rounded,
    };
