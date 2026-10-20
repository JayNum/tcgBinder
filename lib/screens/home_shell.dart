import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'binders_screen.dart';
import 'favorites_screen.dart';
import 'scan_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// The app's frame: Favorites, Scan, Binders and Settings along the bottom.
///
/// Every tab keeps its own stack of screens, so the bar (and the Scan
/// button) stays on screen when you open a game, a binder or a card.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _roots = <Widget>[
    FavoritesScreen(),
    BindersScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  final _navigators = List.generate(4, (_) => GlobalKey<NavigatorState>());
  int _tab = 0;

  void _select(int tab) {
    if (tab == _tab) {
      // Tapping the tab you are on goes back to its first screen.
      _navigators[tab].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _tab = tab);
    }
  }

  void _scan() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const ScanScreen(),
      ),
    );
  }

  void _back() {
    final navigator = _navigators[_tab].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    } else if (_tab != 0) {
      setState(() => _tab = 0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // The bar below already covers the bottom safe area.
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: IndexedStack(
                      index: _tab,
                      children: [
                        for (var i = 0; i < _roots.length; i++)
                          // Only the visible tab runs animations.
                          TickerMode(
                            enabled: i == _tab,
                            child: Navigator(
                              key: _navigators[i],
                              onGenerateRoute: (settings) =>
                                  MaterialPageRoute<void>(
                                settings: settings,
                                builder: (_) => _roots[i],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _TabBar(selected: _tab, onSelect: _select),
              ],
            ),
            // The big Scan button sits in the middle of the bar, rising out
            // of it.
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + _TabBar.height - 46,
              child: Center(child: _ScanButton(onTap: _scan)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelect});

  static const height = 56.0;

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (dark ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9F9))
                .withValues(alpha: 0.94),
            border: Border(
              top: BorderSide(color: tokens.divider, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: height,
              child: Row(
                children: [
                  _TabItem(
                    icon: Icons.favorite_border_rounded,
                    activeIcon: Icons.favorite_rounded,
                    label: 'Favorites',
                    color: const Color(0xFFFF2D55),
                    selected: selected == 0,
                    onTap: () => onSelect(0),
                  ),
                  _TabItem(
                    icon: Icons.collections_bookmark_outlined,
                    activeIcon: Icons.collections_bookmark_rounded,
                    label: 'Binders',
                    color: const Color(0xFFFF9500),
                    selected: selected == 1,
                    onTap: () => onSelect(1),
                  ),
                  // Room for the Scan button in the middle.
                  const Expanded(child: SizedBox.shrink()),
                  _TabItem(
                    icon: Icons.search_rounded,
                    activeIcon: Icons.search_rounded,
                    label: 'Search',
                    color: const Color(0xFF34C759),
                    selected: selected == 2,
                    onTap: () => onSelect(2),
                  ),
                  _TabItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    color: const Color(0xFF5856D6),
                    selected: selected == 3,
                    onTap: () => onSelect(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The main action of the app: a big filled button that is always there.
class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Semantics(
      button: true,
      label: 'Scan cards',
      child: GestureDetector(
        onTap: onTap,
        // A ring in the page colour makes the button look cut into the bar.
        child: Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: tokens.background,
            shape: BoxShape.circle,
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(context.accent, Colors.white, 0.25)!,
                  context.accent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: context.accent.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shown = selected ? color : context.binder.muted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? activeIcon : icon, color: shown, size: 26),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: shown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
