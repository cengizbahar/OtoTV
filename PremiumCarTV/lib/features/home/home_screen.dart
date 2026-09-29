import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/channel_card.dart';
import '../../widgets/common.dart';
import '../player/player_screen.dart';
import '../premium/paywall_screen.dart';
import '../servers/server_home_section.dart';
import '../web/apps_rail.dart';
import '../sources/sources_screen.dart';
import '../../l10n/l10n.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final library = ref.watch(libraryProvider);
    final query = ref.watch(searchQueryProvider).trim().toLowerCase();
    final servers = ref.watch(serverSourcesProvider);

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () {
        for (final s in servers) {
          ref.invalidate(serverViewsProvider(s.id));
          ref.invalidate(serverResumeProvider(s.id));
        }
        return ref.refresh(libraryProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    const Wordmark(),
                    const Spacer(),
                    PlusBadge(onTap: () => openPaywall(context)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: TextField(
                onChanged: ref.read(searchQueryProvider.notifier).set,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: AppsRail()),
          ...library.when(
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
              ),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: l.libraryLoadFailed,
                  message: describeError(l, e),
                  actionLabel: l.retry,
                  onAction: () => ref.invalidate(libraryProvider),
                ),
              ),
            ],
            data: (lib) {
              if (lib.isEmpty && servers.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.live_tv_rounded,
                      title: lib.errors.isEmpty ? l.emptyHomeTitle : l.sourcesUnreachable,
                      message: lib.errors.isEmpty
                          ? l.emptyHomeMessage
                          : lib.errors.values.map((e) => describeError(l, e)).toSet().join('\n'),
                      actionLabel: l.addSource,
                      onAction: () => openSources(context),
                    ),
                  ),
                ];
              }
              if (query.isNotEmpty) return [_SearchResults(lib: lib, query: query)];
              return [
                if (lib.errors.isNotEmpty) _ErrorBanner(errors: lib.errors),
                if (!lib.isEmpty) _Hero(lib: lib),
                for (final s in servers)
                  SliverToBoxAdapter(child: ServerHomeSection(source: s)),
                for (final g in lib.groups) _GroupRail(group: g),
                const SliverToBoxAdapter(child: SizedBox(height: 180)),
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// Üstteki büyük "şimdi izle" kartı: son favori ya da ilk kanal.
class _Hero extends ConsumerWidget {
  const _Hero({required this.lib});
  final Library lib;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    final pick = lib.channels.firstWhere(
      (c) => favs.contains(c.key),
      orElse: () => lib.channels.first,
    );
    final queue = lib.groups.firstWhere((g) => g.name == pick.group).channels;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: GestureDetector(
          onTap: () {
            ref.read(playerProvider.notifier).play(pick, queue: queue);
            openPlayer(context);
          },
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF3A2E1A), Color(0xFF16130E), Color(0xFF0C0C0E)],
              ),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
            ),
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        favs.contains(pick.key) ? context.l10n.heroFavorite : context.l10n.heroWatchNow,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(pick.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Color(0xFF1A1206)),
                            const SizedBox(width: 4),
                            Text(context.l10n.play,
                                style: const TextStyle(
                                    color: Color(0xFF1A1206),
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ChannelLogo(name: pick.name, url: pick.logo, size: 96),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupRail extends StatelessWidget {
  const _GroupRail({required this.group});
  final ChannelGroup group;

  @override
  Widget build(BuildContext context) {
    final preview = group.channels.take(20).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: groupLabel(context.l10n, group.name),
            trailing: context.l10n.channelCount(group.channels.length),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GroupScreen(group: group),
            )),
          ),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: preview.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => ChannelCard(
                width: 200,
                channel: preview[i],
                queue: group.channels,
                onOpen: () => openPlayer(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.lib, required this.query});
  final Library lib;
  final String query;

  @override
  Widget build(BuildContext context) {
    final results = lib.channels
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.group.toLowerCase().contains(query))
        .toList();
    if (results.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: context.l10n.noResults,
          message: context.l10n.noResultsMessage,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 180),
      sliver: _ChannelGrid(channels: results),
    );
  }
}

class _ChannelGrid extends StatelessWidget {
  const _ChannelGrid({required this.channels});
  final List<Channel> channels;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
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
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.errors});
  final Map<String, Object> errors;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.live.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          context.l10n.sourcesFailed(errors.length, errors.keys.join(', ')),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Bir grubun tüm kanalları.
class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key, required this.group});
  final ChannelGroup group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(groupLabel(context.l10n, group.name))),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
            sliver: _ChannelGrid(channels: group.channels),
          ),
        ],
      ),
    );
  }
}
