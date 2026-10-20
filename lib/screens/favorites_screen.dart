import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../catalog/catalog_scope.dart';
import '../data/collection_store.dart';
import '../theme/app_theme.dart';
import '../widgets/favorites_carousel.dart';
import '../widgets/ios.dart';
import '../widgets/recent_strip.dart';
import 'card_detail_screen.dart';

/// The first tab: the cards the user gave a heart, on a slowly turning
/// carousel.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final catalog = CatalogScope.of(context);

    final items = [
      for (final e in store.favorites)
        FavoriteItem(
          entry: e,
          card: catalog.cardFor(e.setId, e.cardId),
          set: catalog.setById(e.setId),
        ),
    ];

    // The last 10 cards added to the collection.
    final recent = [
      for (final e in store.recentAdditions(limit: 10))
        FavoriteItem(
          entry: e,
          card: catalog.cardFor(e.setId, e.cardId),
          set: catalog.setById(e.setId),
        ),
    ];

    void open(FavoriteItem item) {
      final card = item.card, set = item.set;
      if (card == null || set == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Open this binder once to load its card list.'),
        ));
        return;
      }
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => CardDetailScreen(card: card, set: set),
      ));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Favorites'),
            transitionBetweenRoutes: false,
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 56,
                      color: tokens.labelMissing,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No favorites yet',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the heart on a card you own and it shows up here, '
                      'turning slowly like a display case.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.accent.withValues(alpha: 0.22),
                      context.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FavoritesCarousel(items: items, onOpen: open),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _Summary(count: items.length)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: SectionHeader('Recent additions'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: RecentStrip(items: recent, onOpen: open),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    Widget stat(String value, String label, Color color) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: tokens.muted),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GroupedSection(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            stat('${store.totalCards}', 'Cards', context.accent),
            stat('${store.startedSets().length}', 'Binders', const Color(0xFFFF9500)),
            stat('$count', count == 1 ? 'Favorite' : 'Favorites', const Color(0xFFFF2D55)),
          ],
        ),
      ),
    );
  }
}
