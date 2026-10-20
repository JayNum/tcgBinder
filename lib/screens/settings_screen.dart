import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../catalog/catalog_scope.dart';
import '../catalog/games.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';
import '../widgets/ios.dart';
import 'pro_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
            transitionBetweenRoutes: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList.list(
              children: [
                const _ProCard(),
                const SizedBox(height: 24),
                GroupedSection(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const _IconTile(Icons.lock_rounded, Color(0xFF34C759)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your collection and photos are stored only on this '
                          'phone. There is no account.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.3,
                            color: tokens.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader('Card data'),
                GroupedSection(
                  child: Column(
                    children: [
                      for (final game in games) ...[
                        ListTile(
                          leading: _IconTile(
                            Icons.style_rounded,
                            gameColor(game.id),
                          ),
                          title: Text(game.name),
                          subtitle: Text(game.dataSource),
                        ),
                        const Divider(indent: 16),
                      ],
                      ListTile(
                        leading: const _IconTile(
                          Icons.delete_rounded,
                          Color(0xFFFF3B30),
                        ),
                        title: const Text('Delete downloaded card lists'),
                        subtitle: const Text(
                          'Frees space. Lists download again when you open a '
                          'binder. Your collection stays.',
                        ),
                        onTap: () => _clearCache(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'TCG Binder 0.3.0 · Card names and data © their publishers',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: tokens.labelMissing),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final catalog = CatalogScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await catalog.clearCache();
    messenger.showSnackBar(
      const SnackBar(content: Text('Downloaded card lists deleted.')),
    );
  }
}

/// iOS-style coloured square with a white icon.
class _IconTile extends StatelessWidget {
  const _IconTile(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5856D6), Color(0xFFAF52DE), Color(0xFFFF2D55)],
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Backup & restore, binder looks, batch scanning',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
