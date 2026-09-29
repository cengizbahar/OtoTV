import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../widgets/channel_card.dart';
import '../../widgets/common.dart';
import '../player/player_screen.dart';
import '../../l10n/l10n.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key, required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(favoritesProvider);
    final lib = ref.watch(libraryProvider).value;
    final channels = [for (final k in keys) ?lib?.byKey(k)];

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navFavorites)),
      body: channels.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: context.l10n.favoritesEmptyTitle,
              message: context.l10n.favoritesEmptyMessage,
              actionLabel: context.l10n.browseChannels,
              onAction: onBrowse,
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 180),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: 1.08,
              ),
              itemCount: channels.length,
              itemBuilder: (context, i) => ChannelCard(
                channel: channels[i],
                queue: channels,
                onOpen: () => openPlayer(context),
              ),
            ),
    );
  }
}
