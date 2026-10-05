import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'server_widgets.dart';
import '../../l10n/l10n.dart';

/// Ana sayfada her Jellyfin/Emby sunucusu için: izlemeye devam et + kitaplıklar.
class ServerHomeSection extends ConsumerWidget {
  const ServerHomeSection({super.key, required this.source});
  final MediaSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final views = ref.watch(serverViewsProvider(source.id));
    final resume = ref.watch(serverResumeProvider(source.id)).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resume.isNotEmpty) ...[
          SectionHeader(title: context.l10n.continueWatching),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: resume.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final item = resume[i];
                final left = item.runtime != null && item.position != null
                    ? item.runtime! - item.position!
                    : null;
                return WideCard(
                  width: 240,
                  sourceId: source.id,
                  item: item,
                  subtitle: [
                    ?item.seriesName,
                    if (left != null) context.l10n.minutesLeft(left.inMinutes),
                  ].join(' · '),
                  onTap: () => openServerItem(context, ref, sourceId: source.id, item: item),
                );
              },
            ),
          ),
        ],
        SectionHeader(title: source.name, trailing: source.kind.label),
        views.when(
          loading: () => const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
          ),
          error: (e, _) => _ServerError(message: describeError(context.l10n, e), onRetry: () {
            ref.invalidate(serverClientProvider(source.id));
          }),
          data: (libs) => SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: libs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => WideCard(
                width: 200,
                sourceId: source.id,
                item: libs[i],
                icon: libraryIcon(libs[i].collectionType),
                onTap: () => openServerItem(context, ref, sourceId: source.id, item: libs[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServerError extends StatelessWidget {
  const _ServerError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.live),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(height: 1.35))),
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
