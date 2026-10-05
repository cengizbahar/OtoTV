import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'player_screen.dart';
import '../../l10n/l10n.dart';

/// Sekmeler arasında gezinirken yayını sürdüren alt çubuk.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final channel = state.current;
    if (channel == null) return const SizedBox.shrink();
    final notifier = ref.read(playerProvider.notifier);

    return GestureDetector(
      onTap: () => openPlayer(context),
      child: Glass(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(5),
              child: ChannelLogo(name: channel.name, url: channel.logo, size: 36),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(groupLabel(context.l10n, channel.group),
                      maxLines: 1,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            StreamBuilder<bool>(
              stream: notifier.player.stream.playing,
              initialData: notifier.player.state.playing,
              builder: (_, snap) => IconButton(
                iconSize: 30,
                onPressed: notifier.player.playOrPause,
                icon: Icon(snap.data == true
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
              ),
            ),
            IconButton(
              onPressed: state.queue.length > 1 ? notifier.next : null,
              icon: const Icon(Icons.skip_next_rounded),
            ),
            IconButton(
              onPressed: notifier.stop,
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
