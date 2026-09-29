import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../state/providers.dart';
import 'common.dart';
import 'programme_line.dart';
import '../l10n/l10n.dart';

/// 16:9 kanal kartı. Dokun → oynat, basılı tut → favorilere ekle/çıkar.
class ChannelCard extends ConsumerWidget {
  const ChannelCard({
    super.key,
    required this.channel,
    required this.queue,
    required this.onOpen,
    this.width,
  });

  final Channel channel;
  final List<Channel> queue;
  final VoidCallback onOpen;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).contains(channel.key);
    final isPlaying =
        ref.watch(playerProvider.select((s) => s.current?.key == channel.key));

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: () {
                  ref.read(playerProvider.notifier).play(channel, queue: queue);
                  onOpen();
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  ref.read(favoritesProvider.notifier).toggle(channel);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(isFav
                          ? context.l10n.favoriteRemoved(channel.name)
                          : context.l10n.favoriteAdded(channel.name)),
                    ));
                },
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF23232A), Color(0xFF121216)],
                    ),
                    border: Border.all(
                      color: isPlaying ? AppColors.gold : AppColors.stroke,
                      width: isPlaying ? 1.6 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: ChannelLogo(
                            name: channel.name, url: channel.logo, size: 64),
                      ),
                      if (isFav)
                        const Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(Icons.favorite_rounded,
                              size: 18, color: AppColors.gold),
                        ),
                      if (isPlaying)
                        const Positioned(left: 10, bottom: 10, child: _NowPlaying()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            channel.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 2),
          ProgrammeLine(channel: channel),
        ],
      ),
    );
  }
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.l10n.nowPlayingBadge,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: Color(0xFF1A1206),
        ),
      ),
    );
  }
}
