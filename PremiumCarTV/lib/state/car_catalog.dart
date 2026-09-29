import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../l10n/l10n.dart';
import 'locale.dart';
import 'providers.dart';
import 'premium.dart';

/// Araç ekranındaki bir satır: klasör (gezinilir) ya da oynatılabilir öğe.
class CarNode {
  const CarNode({required this.id, required this.title, this.subtitle, this.artUri, this.playable = false});

  final String id;
  final String title;
  final String? subtitle;
  final String? artUri;
  final bool playable;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'artUri': artUri,
        'playable': playable,
      };
}

/// Android Auto ve CarPlay'in ortak içerik ağacı:
///
/// ```text
/// root
/// ├─ fav            Favoriler
/// ├─ groups         Kanallar → grp:{ad} → kanallar
/// └─ resume:{id}    {Sunucu} · İzlemeye devam et
/// ```
///
/// Araç ekranları videoyu değil sesi çalar; video yalnızca telefon/tablet
/// ekranında ya da park halinde AirPlay ile gösterilir.
class CarCatalog {
  CarCatalog(this._ref);
  final Ref _ref;

  static const root = 'root';
  static const favorites = 'fav';
  static const groups = 'groups';
  static const _groupPrefix = 'grp:';
  static const _resumePrefix = 'resume:';

  /// Listelenen oynatılabilir öğeler: kimlik → (kanal, sıra).
  final _playables = <String, (Channel, List<Channel>)>{};

  L10n get _l => lookupL10n(effectiveLocale(_ref.read(localeProvider)));

  Future<List<CarNode>> children(String parentId) async {
    final l = _l;
    final lib = await _ref.read(libraryProvider.future);
    final servers = _ref.read(serverSourcesProvider);

    // Araç ekranı bir Plus özelliğidir.
    if (!_ref.read(premiumProvider).isPlus) {
      return parentId == root ? [CarNode(id: 'empty', title: l.carPlusRequired)] : const [];
    }

    if (parentId == root) {
      if (lib.isEmpty && servers.isEmpty) {
        return [CarNode(id: 'empty', title: l.carNoSources)];
      }
      return [
        CarNode(id: favorites, title: l.carFavorites),
        if (!lib.isEmpty) CarNode(id: groups, title: l.carChannels, subtitle: l.channelCount(lib.channels.length)),
        for (final s in servers) CarNode(id: '$_resumePrefix${s.id}', title: l.carContinue(s.name)),
      ];
    }

    if (parentId == groups) {
      return [
        for (final g in lib.groups)
          CarNode(
            id: '$_groupPrefix${g.name}',
            title: groupLabel(l, g.name),
            subtitle: l.channelCount(g.channels.length),
          ),
      ];
    }

    if (parentId.startsWith(_groupPrefix)) {
      final name = parentId.substring(_groupPrefix.length);
      final group = lib.groups.where((g) => g.name == name).firstOrNull;
      return group == null ? const [] : _playableNodes(group.channels);
    }

    if (parentId == favorites) {
      final keys = _ref.read(favoritesProvider);
      final favs = [for (final k in keys) ?lib.byKey(k)];
      return favs.isEmpty ? [CarNode(id: 'empty', title: l.carEmpty)] : _playableNodes(favs);
    }

    if (parentId.startsWith(_resumePrefix)) {
      final sourceId = parentId.substring(_resumePrefix.length);
      try {
        final client = await _ref.read(serverClientProvider(sourceId).future);
        final items = await client.resume();
        return _playableNodes([for (final i in items) client.toChannel(i, sourceId: sourceId)]);
      } catch (_) {
        return [CarNode(id: 'empty', title: l.carEmpty)];
      }
    }
    return const [];
  }

  List<CarNode> _playableNodes(List<Channel> channels) {
    final epg = _ref.read(epgProvider).value;
    final now = DateTime.now().toUtc();
    return [
      for (final c in channels)
        () {
          _playables[c.key] = (c, channels);
          return CarNode(
            id: c.key,
            title: c.name,
            subtitle: epg?.nowNext(c, now).$1?.title ?? groupLabel(_l, c.group),
            artUri: c.logo,
            playable: true,
          );
        }(),
    ];
  }

  /// Araç ekranından seçilen öğeyi oynat. Önce listelenmiş olmalı; değilse
  /// kütüphanede aranır (ör. "son çalınan" ile doğrudan başlatma).
  Future<bool> play(String id) async {
    if (!_ref.read(premiumProvider).isPlus) return false;
    var entry = _playables[id];
    if (entry == null) {
      final lib = await _ref.read(libraryProvider.future);
      final c = lib.byKey(id);
      if (c == null) return false;
      final group = lib.groups.where((g) => g.name == c.group).firstOrNull;
      entry = (c, group?.channels ?? [c]);
    }
    await _ref.read(playerProvider.notifier).play(entry.$1, queue: entry.$2);
    return true;
  }
}

final carCatalogProvider = Provider<CarCatalog>(CarCatalog.new);
