import '../data/collection_store.dart';
import '../models/catalog.dart';
import 'catalog_repository.dart';

/// One card found by the search, with the set it sits in.
class CardHit {
  const CardHit({required this.card, required this.set, required this.owned});

  final CatalogCard card;
  final CardSet set;
  final bool owned;
}

/// Lower-case and drop spaces, dashes and dots, so "op16-001", "OP16 001"
/// and "op16001" all look the same.
String normalizeForSearch(String text) =>
    text.toLowerCase().replaceAll(RegExp(r"[\s\-_:.'’]"), '');

/// Looks through every card list that is downloaded on this phone.
///
/// - [query] words must all appear in the card's name, code, variant, rarity
///   or set name.
/// - [gameId] limits the search to one game.
/// - [labels] keeps only owned cards that have at least one of these labels.
/// - [favoritesOnly] keeps only cards with a heart.
/// - [ownedOnly] keeps only cards the user owns.
///
/// Owned cards come first, then cards whose name starts with the query.
List<CardHit> searchCards(
  CatalogRepository catalog,
  CollectionStore store, {
  String query = '',
  String? gameId,
  Set<String> labels = const {},
  bool favoritesOnly = false,
  bool ownedOnly = false,
  int limit = 80,
}) {
  final words = [
    for (final w in query.split(RegExp(r'\s+')))
      if (normalizeForSearch(w).isNotEmpty) normalizeForSearch(w),
  ];
  final needsEntry = labels.isNotEmpty || favoritesOnly || ownedOnly;
  final first = words.isEmpty ? '' : words.first;

  final owned = <CardHit>[];
  final startsWith = <CardHit>[];
  final rest = <CardHit>[];

  catalog.allCachedCards.forEach((setId, cards) {
    final set = catalog.setById(setId);
    if (set == null) return;
    if (gameId != null && set.gameId != gameId) return;
    final setName = normalizeForSearch(set.name);

    for (final card in cards) {
      final entry = store.entryFor(card.id);
      if (needsEntry) {
        if (entry == null) continue;
        if (favoritesOnly && !entry.favorite) continue;
        if (labels.isNotEmpty && !entry.labels.any(labels.contains)) continue;
      }
      final name = normalizeForSearch(card.name);
      if (words.isNotEmpty) {
        final haystack = '$name${normalizeForSearch(card.code)}'
            '${normalizeForSearch(card.variant ?? '')}'
            '${normalizeForSearch(card.rarity)}'
            '${normalizeForSearch(card.subtitle ?? '')}$setName';
        if (!words.every(haystack.contains)) continue;
      }
      final hit = CardHit(card: card, set: set, owned: entry != null);
      if (hit.owned) {
        owned.add(hit);
      } else if (first.isNotEmpty && name.startsWith(first)) {
        startsWith.add(hit);
      } else {
        rest.add(hit);
      }
    }
  });

  return [...owned, ...startsWith, ...rest].take(limit).toList();
}
