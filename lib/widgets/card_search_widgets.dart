import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../catalog/card_search.dart';
import '../catalog/catalog_scope.dart';
import '../data/collection_store.dart';
import '../data/settings_store.dart';
import '../screens/card_detail_screen.dart';
import '../theme/app_theme.dart';
import '../theme/label_colors.dart';
import 'card_photo.dart';
import 'download_sets.dart';
import 'ios.dart';

/// What the user has switched on next to the search box.
class CardFilters {
  const CardFilters({
    this.query = '',
    this.labels = const {},
    this.favorites = false,
    this.owned = false,
  });

  final String query;
  final Set<String> labels;
  final bool favorites;
  final bool owned;

  /// True when the screen should show cards instead of its normal list.
  bool get active =>
      query.trim().isNotEmpty || labels.isNotEmpty || favorites || owned;

  CardFilters copyWith({
    String? query,
    Set<String>? labels,
    bool? favorites,
    bool? owned,
  }) =>
      CardFilters(
        query: query ?? this.query,
        labels: labels ?? this.labels,
        favorites: favorites ?? this.favorites,
        owned: owned ?? this.owned,
      );
}

/// Chips under the search box: Owned, Favorites, and one per label the user
/// has made. Switch a label on to see only cards with it.
class CardFilterBar extends StatelessWidget {
  const CardFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final CardFilters filters;
  final ValueChanged<CardFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = CollectionScope.of(context).allLabels;
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 2, 8, 6),
        children: [
          PillChip(
            label: 'Owned',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF34C759),
            selected: filters.owned,
            onTap: () => onChanged(filters.copyWith(owned: !filters.owned)),
          ),
          PillChip(
            label: 'Favorites',
            icon: Icons.favorite_rounded,
            color: const Color(0xFFFF2D55),
            selected: filters.favorites,
            onTap: () =>
                onChanged(filters.copyWith(favorites: !filters.favorites)),
          ),
          for (final label in labels)
            PillChip(
              label: label,
              color: SettingsScope.of(context).labelColor(label),
              selected: filters.labels.contains(label),
              onTap: () {
                final next = {...filters.labels};
                if (!next.remove(label)) next.add(label);
                onChanged(filters.copyWith(labels: next));
              },
            ),
        ],
      ),
    );
  }
}

/// The cards that match [filters], as one grouped list.
class CardResults extends StatelessWidget {
  const CardResults({super.key, required this.filters, this.gameId});

  final CardFilters filters;
  final String? gameId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final catalog = CatalogScope.of(context);
    final store = CollectionScope.of(context);
    final hits = searchCards(
      catalog,
      store,
      query: filters.query,
      gameId: gameId,
      labels: filters.labels,
      favoritesOnly: filters.favorites,
      ownedOnly: filters.owned,
    );
    final downloaded = catalog.allCachedCards.length;
    final onlyOwned =
        filters.labels.isNotEmpty || filters.favorites || filters.owned;

    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
        child: Column(children: [Text(
          downloaded == 0 && !onlyOwned
              ? 'No card lists are downloaded yet. Open a binder once and '
                  'its cards can be searched here.'
              : 'No card matches.',
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.muted, height: 1.4),
        ),
          if (!onlyOwned) DownloadAllSetsButton(gameId: gameId),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('${hits.length} ${hits.length == 1 ? 'card' : 'cards'}'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GroupedSection(
            child: Column(
              children: [
                for (var i = 0; i < hits.length; i++) ...[
                  if (i > 0) const Divider(indent: 72),
                  CardResultRow(hit: hits[i]),
                ],
              ],
            ),
          ),
        ),
        if (!onlyOwned)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
            child: Text(
              'Searching the $downloaded ${downloaded == 1 ? 'set' : 'sets'} '
              'downloaded on this phone. Open a binder to add its cards to '
              'the search.',
              style: TextStyle(fontSize: 13, color: tokens.muted),
            ),
          ),
        if (!onlyOwned) DownloadAllSetsButton(gameId: gameId),
      ],
    );
  }
}

class CardResultRow extends StatelessWidget {
  const CardResultRow({super.key, required this.hit});

  final CardHit hit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final entry = CollectionScope.of(context).entryFor(hit.card.id);
    final photo = entry?.photoPath;
    final card = hit.card;

    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => CardDetailScreen(card: card, set: hit.set),
      )),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: AspectRatio(
                aspectRatio: 63 / 88,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.pocket,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tokens.pocketBorder, width: 0.5),
                  ),
                  child: photo != null
                      ? CardPhoto(path: photo, radius: 4)
                      : const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      card.code,
                      if (card.variant != null) card.variant!,
                      hit.set.name,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: tokens.muted),
                  ),
                  if (entry != null && entry.labels.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final label in entry.labels)
                          _LabelDot(
                            label: label,
                            color: SettingsScope.of(context).labelColor(label),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (entry != null && entry.favorite)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: Color(0xFFFF2D55),
                  semanticLabel: 'Favorite',
                ),
              ),
            if (entry != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: tokens.success,
                  semanticLabel: 'Owned',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small coloured label tag inside a result row.
class _LabelDot extends StatelessWidget {
  const _LabelDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: onColor(color),
        ),
      ),
    );
  }
}
