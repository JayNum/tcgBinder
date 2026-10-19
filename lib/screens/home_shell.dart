import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

/// Bottom bar with Binders, a raised Scan button, and Settings.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [HomeScreen(), SettingsScreen()],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Scan cards',
        shape: const CircleBorder(),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
        ),
        child: const Icon(Icons.document_scanner_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 64,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.collections_bookmark_outlined,
              label: 'Binders',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
            const SizedBox(width: 72),
            _NavItem(
              icon: Icons.tune,
              label: 'Settings',
              selected: _tab == 1,
              onTap: () => setState(() => _tab = 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.accent : context.binder.muted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkResponse(
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: color,
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
