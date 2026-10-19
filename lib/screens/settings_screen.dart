import 'package:flutter/material.dart';

import '../catalog/catalog_scope.dart';
import '../catalog/games.dart';
import '../data/collection_store.dart';
import '../services/ads.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final gamesStarted = games.where((g) => store.copiesInGame(g.id) > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Surface(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _Stat(value: '${store.totalCards}', label: 'Cards'),
                    const SizedBox(width: 8),
                    _Stat(
                      value: '${store.startedSets().length}',
                      label: 'Binders',
                    ),
                    const SizedBox(width: 8),
                    _Stat(value: '$gamesStarted', label: 'Games'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: context.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your collection and photos are stored only on this '
                        'phone.',
                        style: TextStyle(fontSize: 12, color: tokens.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Ads & privacy'),
          _Surface(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text(
                'Privacy & ad choices',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Change your consent for personalised ads'),
              trailing: Icon(Icons.chevron_right, color: tokens.muted),
              onTap: () => _privacyOptions(context),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Card data'),
          _Surface(
            child: Column(
              children: [
                for (final game in games)
                  ListTile(
                    dense: true,
                    title: Text(
                      game.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(game.dataSource),
                  ),
                Divider(height: 1, color: tokens.divider),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text(
                    'Delete downloaded card lists',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Frees space. Lists download again when you open a '
                    'binder. Your collection stays.',
                  ),
                  onTap: () => _clearCache(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'TCG Binder 0.2.0 · Card names and data © their publishers',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: tokens.labelMissing),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: tokens.pocket,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: numberStyle(color: tokens.text, size: 18)),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: context.binder.muted,
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
