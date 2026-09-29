import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/programme_line.dart';
import '../car/car_mode_screen.dart';
import '../../l10n/l10n.dart';
import '../../platform/car_connection.dart';
import '../../state/premium.dart';
import '../premium/paywall_screen.dart';

void openPlayer(BuildContext context) {
  // Araç ekranında (Android Auto park uygulaması) doğrudan yatay Araç Modu.
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(carLinkProvider).value == CarLink.androidAutoDisplay) {
    container.read(premiumProvider).isPlus ? openCarMode(context) : openPaywall(context);
    return;
  }
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => const PlayerScreen(),
      transitionsBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
          child: child,
        );
      },
    ),
  );
}

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final current = state.current;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final video = Video(
      controller: notifier.video,
      pauseUponEnteringBackgroundMode: false,
      subtitleViewConfiguration: const SubtitleViewConfiguration(
        style: TextStyle(
          fontSize: 22,
          height: 1.4,
          color: Colors.white,
          backgroundColor: Color(0xAA000000),
        ),
      ),
    );

    if (landscape) {
      return Scaffold(backgroundColor: Colors.black, body: Center(child: video));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(title: current?.name ?? ''),
            AspectRatio(aspectRatio: 16 / 9, child: ColoredBox(color: Colors.black, child: video)),
            if (current != null) ...[_Details(), ProgrammeDetails(channel: current)],
            const Divider(height: 1, color: AppColors.stroke),
            Expanded(child: _Queue()),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: context.l10n.carMode,
            icon: const Icon(Icons.directions_car_filled_rounded, color: AppColors.gold),
            onPressed: () => openCarModeGated(context, ref),
          ),
        ],
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final channel = state.current!;
    final isFav = ref.watch(favoritesProvider).contains(channel.key);
    final notifier = ref.read(playerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(6),
            child: ChannelLogo(name: channel.name, url: channel.logo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(groupLabel(context.l10n, channel.group),
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.previous,
            onPressed: state.queue.length > 1 ? notifier.previous : null,
            icon: const Icon(Icons.skip_previous_rounded),
          ),
          IconButton(
            tooltip: context.l10n.next,
            onPressed: state.queue.length > 1 ? notifier.next : null,
            icon: const Icon(Icons.skip_next_rounded),
          ),
          IconButton(
            tooltip: isFav ? context.l10n.removeFavorite : context.l10n.addFavorite,
            onPressed: () => ref.read(favoritesProvider.notifier).toggle(channel),
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? AppColors.gold : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Oynatırken aynı gruptaki diğer kanallara tek dokunuşla geçiş.
class _Queue extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final queue = state.queue;
    if (queue.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      itemCount: queue.length,
      itemBuilder: (context, i) {
        final c = queue[i];
        final active = c.key == state.current?.key;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          leading: Container(
            width: 64,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: active ? Border.all(color: AppColors.gold) : null,
            ),
            padding: const EdgeInsets.all(4),
            child: ChannelLogo(name: c.name, url: c.logo, size: 32),
          ),
          title: Text(c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: active ? AppColors.goldLight : AppColors.textPrimary,
              )),
          subtitle: ProgrammeLine(channel: c),
          trailing: active
              ? const Icon(Icons.graphic_eq_rounded, color: AppColors.gold)
              : null,
          onTap: active
              ? null
              : () => ref.read(playerProvider.notifier).play(c, queue: queue),
        );
      },
    );
  }
}
