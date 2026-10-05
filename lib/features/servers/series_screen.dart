import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/media_server_client.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'server_widgets.dart';
import '../../l10n/l10n.dart';

/// Dizi sayfası: arka plan afişi, sezon seçici ve sıralı bölüm listesi.
class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key, required this.sourceId, required this.series});
  final String sourceId;
  final ServerItem series;

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  String? _seasonId;

  @override
  Widget build(BuildContext context) {
    final seasons = ref.watch(seasonsProvider((widget.sourceId, widget.series.id)));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.series.name,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ServerImage(
                    sourceId: widget.sourceId,
                    itemId: widget.series.id,
                    tag: widget.series.backdropTag ?? widget.series.imageTag,
                    imageType: widget.series.backdropTag != null ? 'Backdrop' : 'Primary',
                    maxWidth: 1080,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), AppColors.background],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.series.overview case final overview? when overview.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(overview,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.45)),
              ),
            ),
          ...seasons.when(
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
              ),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: Icons.cloud_off_rounded, title: context.l10n.seasonsFailed, message: describeError(context.l10n, e)),
              ),
            ],
            data: (list) {
              if (list.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.tv_off_rounded,
                      title: context.l10n.noEpisodesTitle,
                      message: context.l10n.noEpisodesMessage,
                    ),
                  ),
                ];
              }
              final selected = _seasonId ?? _firstUnwatched(list).id;
              return [
                SliverToBoxAdapter(child: _SeasonPicker(
                  seasons: list,
                  selectedId: selected,
                  onSelect: (id) => setState(() => _seasonId = id),
                )),
                _EpisodeList(
                  sourceId: widget.sourceId,
                  seriesId: widget.series.id,
                  seasonId: selected,
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  /// Kullanıcıyı izlenmemiş ilk sezondan karşıla.
  static ServerItem _firstUnwatched(List<ServerItem> seasons) =>
      seasons.firstWhere((s) => !s.played, orElse: () => seasons.first);
}

class _SeasonPicker extends StatelessWidget {
  const _SeasonPicker({required this.seasons, required this.selectedId, required this.onSelect});
  final List<ServerItem> seasons;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        itemCount: seasons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = seasons[i];
          final active = s.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(s.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active ? AppColors.goldGradient : null,
                color: active ? null : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                s.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? const Color(0xFF1A1206) : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EpisodeList extends ConsumerWidget {
  const _EpisodeList({required this.sourceId, required this.seriesId, required this.seasonId});
  final String sourceId;
  final String seriesId;
  final String seasonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = ref.watch(episodesProvider((sourceId, seriesId, seasonId)));
    return episodes.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(padding: const EdgeInsets.all(20), child: Text(describeError(context.l10n, e))),
      ),
      data: (list) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
        sliver: SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final ep = list[i];
            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              // Sıra = sezonun tüm bölümleri; bitince sıradaki otomatik başlar.
              onTap: () => openServerItem(context, ref, sourceId: sourceId, item: ep, queue: list),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ServerImage(sourceId: sourceId, itemId: ep.id, tag: ep.imageTag, icon: Icons.tv_rounded),
                            if (ep.progress > 0)
                              Positioned(left: 0, right: 0, bottom: 0, child: ProgressStrip(ep.progress)),
                            if (ep.played)
                              const Positioned(
                                top: 6,
                                right: 6,
                                child: Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ep.episodeNumber ?? i + 1}. ${ep.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (ep.runtime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(context.l10n.minutes(ep.runtime!.inMinutes),
                                style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                          ),
                        if (ep.overview != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(ep.overview!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
