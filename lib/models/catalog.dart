/// Catalog data: games, sets and cards as published by the card databases.
/// This is reference data — it never contains anything about the user.
library;

class Game {
  const Game({
    required this.id,
    required this.name,
    required this.cardmarketSlug,
    this.hasEditions = false,
  });

  final String id;
  final String name;

  /// Path segment Cardmarket uses for this game, e.g. `Pokemon`.
  final String cardmarketSlug;

  /// Whether cards come in editions (1st Edition / Shadowless / Unlimited).
  final bool hasEditions;
}

class CardSet {
  const CardSet({
    required this.id,
    required this.gameId,
    required this.code,
    required this.name,
    required this.releaseYear,
    required this.printedTotal,
  });

  final String id;
  final String gameId;
  final String code;
  final String name;
  final int releaseYear;

  /// The total printed on the cards, e.g. 102 in `004/102`.
  final int printedTotal;
}

class CatalogCard {
  const CatalogCard({
    required this.id,
    required this.setId,
    required this.number,
    required this.name,
    required this.rarity,
    this.cardmarketUrl,
    this.tcgplayerUrl,
  });

  final String id;
  final String setId;
  final int number;
  final String name;
  final String rarity;

  /// Direct product pages, when the catalog source provides them
  /// (Scryfall and pokemontcg.io do). Otherwise we fall back to a search.
  final String? cardmarketUrl;
  final String? tcgplayerUrl;

  String printedNumber(CardSet set) {
    final width = set.printedTotal.toString().length.clamp(3, 4);
    return '${number.toString().padLeft(width, '0')}/${set.printedTotal}';
  }
}
