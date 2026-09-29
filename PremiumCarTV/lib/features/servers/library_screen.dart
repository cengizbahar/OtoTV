import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/media_server_client.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'server_widgets.dart';
import '../../l10n/l10n.dart';

/// Bir kitaplığın (veya klasörün) afiş ızgarası.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key, required this.sourceId, required this.library});
  final String sourceId;
  final ServerItem library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = (
      sourceId: sourceId,
      libraryId: library.id,
      collectionType: library.collectionType,
    );
    final items = ref.watch(libraryItemsProvider(arg));

    return Scaffold(
      appBar: AppBar(title: Text(library.name)),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: context.l10n.libraryOpenFailed,
          message: describeError(context.l10n, e),
          actionLabel: context.l10n.retry,
          onAction: () => ref.invalidate(libraryItemsProvider(arg)),
        ),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.folder_open_rounded,
                title: context.l10n.libraryEmptyTitle,
                message: context.l10n.libraryEmptyMessage,
              )
            : RefreshIndicator(
                color: AppColors.gold,
                onRefresh: () => ref.refresh(libraryItemsProvider(arg).future),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 180),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.52,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) => PosterCard(
                    sourceId: sourceId,
                    item: list[i],
                    onTap: () => openServerItem(
                      context,
                      ref,
                      sourceId: sourceId,
                      item: list[i],
                      // Film kitaplığında sıradaki filme otomatik geçme.
                      queue: const [],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
