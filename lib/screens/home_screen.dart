import 'package:flutter/material.dart';

import '../data/collection_store.dart';
import '../data/sample_catalog.dart';
import '../models/catalog.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';
import '../widgets/ad_banner.dart';
import 'game_screen.dart';

/// Home: collection stats and one tile per supported game.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);

    final startedBinders = sets
        .where((s) => store.ownedIn(cardsInSet(s.id)) > 0)
        .length;
    final completeSets = sets.where((s) {
      final total = s.printedTotal;
      if (total == null) return false;
      final base = cardsInSet(s.id).where((c) => !c.isVariant && !c.isReprint);
      return store.ownedIn(base) >= total;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My collection',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Row(
                  children: [
                    _Stat(value: '${store.totalCards}', label: 'Cards'),
                    const SizedBox(width: 8),
                    _Stat(value: '$startedBinders', label: 'Binders started'),
                    const SizedBox(width: 8),
                    _Stat(value: '$completeSets', label: 'Sets complete'),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    'GAMES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: tokens.muted,
                    ),
                  ),
                ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.3,
                  children: [
                    for (final game in games) _GameTile(game: game),
                    const _CustomBinderTile(),
                  ],
                ),
              ],
            ),
          ),
          const AdBannerPlaceholder(),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final gameSets = setsOfGame(game.id);
    final gameCards = allCards.where((c) => gameSets.any((s) => s.id == c.setId));
    final copies = store.copiesIn(gameCards);
    final started =
        gameSets.where((s) => store.ownedIn(cardsInSet(s.id)) > 0).length;
    final line = copies == 0
        ? 'Not started yet'
        : '$copies cards · $started ${started == 1 ? 'binder' : 'binders'}';

    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => GameScreen(game: game)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 46,
              color: gameColor(game.id),
              alignment: Alignment.centerLeft,
              child: Container(
                width: 6,
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      game.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: tokens.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBinderTile extends StatelessWidget {
  const _CustomBinderTile();

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return OutlinedButton(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom binders are coming in a later version.'),
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.muted,
        side: BorderSide(color: tokens.pocketBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add),
          SizedBox(height: 6),
          Text(
            'Custom binder',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          children: [
            Text(value, style: numberStyle(color: tokens.text, size: 18)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
