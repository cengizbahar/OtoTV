import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../cast/cast_screen.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../player/mini_player.dart';
import '../settings/settings_screen.dart';
import '../../l10n/l10n.dart';

/// Dört sekmeli ana iskelet. Her sekme kendi gezinme yığınını korur;
/// mini oynatıcı ve cam alt menü tüm sekmelerin üzerinde yüzer.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  void _select(int i) {
    HapticFeedback.selectionClick();
    if (i == _index) {
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const HomeScreen(),
      FavoritesScreen(onBrowse: () => _select(0)),
      const CastScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _index,
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
              _GlassNavBar(index: _index, onSelect: _select),
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
    (Icons.cast_outlined, Icons.cast_connected_rounded),
    (Icons.tune_outlined, Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = [l.navHome, l.navFavorites, l.navCast, l.navSettings];
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
                          fontSize: 11,
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
