import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../cast/cast_screen.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../player/mini_player.dart';
import '../settings/settings_screen.dart';
import '../sources/sources_screen.dart';
import '../../l10n/l10n.dart';

enum ShellTab { home, favorites, sources, cast, settings }

/// Seçili alt menü sekmesi; başka ekranlar da sekme değiştirebilsin diye provider.
final shellTabProvider = NotifierProvider<ShellTabNotifier, ShellTab>(ShellTabNotifier.new);

class ShellTabNotifier extends Notifier<ShellTab> {
  @override
  ShellTab build() => ShellTab.home;
  void select(ShellTab tab) => state = tab;
}

/// Uygulamanın herhangi bir yerinden alt menü sekmesine geç.
void goToTab(BuildContext context, ShellTab tab) =>
    ProviderScope.containerOf(context, listen: false).read(shellTabProvider.notifier).select(tab);

/// Beş sekmeli ana iskelet. Her sekme kendi gezinme yığınını korur;
/// mini oynatıcı ve cam alt menü tüm sekmelerin üzerinde yüzer.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _navKeys = List.generate(ShellTab.values.length, (_) => GlobalKey<NavigatorState>());

  void _select(int i) {
    HapticFeedback.selectionClick();
    if (i == ref.read(shellTabProvider).index) {
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      ref.read(shellTabProvider.notifier).select(ShellTab.values[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(shellTabProvider).index;
    final tabs = <Widget>[
      const HomeScreen(),
      FavoritesScreen(onBrowse: () => _select(0)),
      const SourcesScreen(),
      const CastScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navKeys[index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (index != 0) {
          ref.read(shellTabProvider.notifier).select(ShellTab.home);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: index,
          children: [
            for (var i = 0; i < tabs.length; i++)
              Navigator(
                key: _navKeys[i],
                onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => tabs[i]),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              const SizedBox(height: 10),
              _GlassNavBar(index: index, onSelect: _select),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  static const _icons = [
    (Icons.home_outlined, Icons.home_rounded),
    (Icons.favorite_border_rounded, Icons.favorite_rounded),
    (Icons.playlist_add_outlined, Icons.playlist_add_check_rounded),
    (Icons.cast_outlined, Icons.cast_connected_rounded),
    (Icons.tune_outlined, Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = [l.navHome, l.navFavorites, l.sources, l.navCast, l.navSettings];
    return Glass(
      radius: 30,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (var i = 0; i < _icons.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.gold.withValues(alpha: 0.16) : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        i == index ? _icons[i].$2 : _icons[i].$1,
                        color: i == index ? AppColors.gold : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                          color: i == index ? AppColors.gold : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
