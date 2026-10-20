import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../catalog/catalog_scope.dart';
import '../catalog/games.dart';
import '../services/ads.dart';
import '../theme/app_theme.dart';
import '../widgets/ios.dart';

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
                GroupedSection(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 22,
                        color: context.accent,
                      ),
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
                const SectionHeader('Ads & privacy'),
                GroupedSection(
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy & ad choices'),
                    subtitle:
                        const Text('Change your consent for personalised ads'),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: tokens.muted,
                    ),
                    onTap: () => _privacyOptions(context),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader('Card data'),
                GroupedSection(
                  child: Column(
                    children: [
                      for (final game in games) ...[
                        ListTile(
                          title: Text(game.name),
                          subtitle: Text(game.dataSource),
                        ),
                        const Divider(indent: 16),
                      ],
                      ListTile(
                        leading: const Icon(Icons.delete_outline_rounded),
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

  Future<void> _privacyOptions(BuildContext context) async {
    final ads = AdsScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (await ads.hasPrivacyOptions()) {
      ads.showPrivacyOptions();
    } else {
      messenger.showSnackBar(const SnackBar(
        content: Text('There are no ad choices to make in your region.'),
      ));
    }
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
