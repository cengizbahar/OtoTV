import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'qr_scan_screen.dart';
import '../../l10n/l10n.dart';
import '../../state/premium.dart';
import '../premium/paywall_screen.dart';

void openSources(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const SourcesScreen()));

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(sourcesProvider);

    return Scaffold(
      // Yüzen buton cam alt menünün altında kalıyordu; ekleme üst çubukta.
      appBar: AppBar(
        title: Text(context.l10n.sources),
        actions: [
          IconButton(
            tooltip: context.l10n.addSource,
            onPressed: () => _showAddSheet(context, ref),
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.gold, size: 30),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: sources.isEmpty
          ? EmptyState(
              icon: Icons.podcasts_rounded,
              title: context.l10n.sourcesEmptyTitle,
              message: context.l10n.sourcesEmptyMessage,
              actionLabel: context.l10n.addFirstSource,
              onAction: () => _showAddSheet(context, ref),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              itemCount: sources.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _SourceTile(source: sources[i]),
            ),
    );
  }
}

class _SourceTile extends ConsumerWidget {
  const _SourceTile({required this.source});
  final MediaSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.stroke),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(18, 8, 6, 8),
        leading: Icon(
          source.kind.isServer ? Icons.dns_rounded : Icons.playlist_play_rounded,
          size: 30,
        ),
        title: Text(source.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          source.kind.isServer
              ? '${source.kind.label} · ${source.userName ?? ''} · ${_maskUrl(source.url)}'
              : _maskUrl(source.url),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.surfaceHigh,
          onSelected: (v) async {
            final notifier = ref.read(sourcesProvider.notifier);
            switch (v) {
              case 'refresh' when source.kind.isServer:
                ref.invalidate(serverClientProvider(source.id));
              case 'refresh':
                ref.invalidate(libraryProvider);
              case 'rename':
                final name = await _askName(context, source.name);
                if (name != null && name.isNotEmpty) await notifier.rename(source.id, name);
              case 'delete':
                await notifier.remove(source.id);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'refresh', child: Text(context.l10n.refresh)),
            PopupMenuItem(value: 'rename', child: Text(context.l10n.rename)),
            PopupMenuItem(
              value: 'delete',
              child: Text(context.l10n.remove, style: const TextStyle(color: AppColors.live)),
            ),
          ],
        ),
      ),
    );
  }

  /// Ekranda kullanıcı adı/şifre gibi sorgu parametrelerini gösterme.
  static String _maskUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}';
  }

  static Future<String?> _askName(BuildContext context, String current) {
    final ctrl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: Text(ctx.l10n.rename),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(ctx.l10n.save),
          ),
        ],
      ),
    );
  }
}

/// Ücretsiz sürümde kaynak sayısı sınırlı; sınıra gelindiyse satış ekranı açılır.
Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
  final count = ref.read(sourcesProvider).length;
  if (!ref.read(premiumProvider).isPlus && count >= PremiumConfig.freeSourceLimit) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.freeSourceLimit(PremiumConfig.freeSourceLimit))),
    );
    if (!await requirePlus(context, ref) || !context.mounted) return;
  }
  await showModalBottomSheet<void>(
    context: context,
    // Sekme navigatöründe açılırsa cam alt menü sayfanın üstünde kalır.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (_) => const _AddSourceSheet(),
  );
}

class _AddSourceSheet extends ConsumerStatefulWidget {
  const _AddSourceSheet();

  @override
  ConsumerState<_AddSourceSheet> createState() => _AddSourceSheetState();
}

class _AddSourceSheetState extends ConsumerState<_AddSourceSheet> {
  SourceKind _kind = SourceKind.m3u;
  final _url = TextEditingController();
  final _name = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _showPass = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_url, _name, _user, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scanQr() async {
    final value = await QrScanScreen.scan(context);
    if (value != null && mounted) setState(() => _url.text = value);
  }

  Future<void> _submit() async {
    final isServer = _kind.isServer;
    final l = context.l10n;
    if (_url.text.trim().isEmpty) {
      setState(() => _error = isServer ? l.serverUrlRequired : l.listUrlRequired);
      return;
    }
    if (isServer && _user.text.trim().isEmpty) {
      setState(() => _error = l.usernameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notifier = ref.read(sourcesProvider.notifier);
      if (isServer) {
        await notifier.addServer(
          kind: _kind,
          url: _url.text,
          username: _user.text,
          password: _pass.text,
          name: _name.text,
        );
      } else {
        await notifier.addM3u(url: _url.text, name: _name.text);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = describeError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isServer = _kind.isServer;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          22, 14, 22, MediaQuery.viewInsetsOf(context).bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stroke,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(l.addSource, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<SourceKind>(
            segments: [
              for (final k in SourceKind.values)
                ButtonSegment(value: k, label: Text(k.label)),
            ],
            selected: {_kind},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _error = null;
            }),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.gold,
              selectedForegroundColor: const Color(0xFF1A1206),
              side: const BorderSide(color: AppColors.stroke),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: isServer ? 'http://192.168.1.10:8096' : 'https://ornek.com/liste.m3u8',
              prefixIcon: Icon(isServer ? Icons.dns_outlined : Icons.link_rounded,
                  color: AppColors.textSecondary),
              suffixIcon: isServer
                  ? null
                  : IconButton(
                      tooltip: l.qrAdd,
                      onPressed: _scanQr,
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.gold),
                    ),
            ),
          ),
          if (isServer) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _user,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: l.username,
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: !_showPass,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: l.password,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showPass = !_showPass),
                  icon: Icon(
                    _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              hintText: l.nameOptional,
              prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lock_rounded, size: 14, color: AppColors.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isServer ? l.serverPrivacyNote : l.listPrivacyNote,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.live)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(isServer ? l.connect : l.addAndLoad),
          ),
        ],
      ),
    );
  }
}
