/// Catalog data: games, sets and cards as published by the card databases.
/// This is reference data — it never contains anything about the user.
library;

/// How a game prints its card code, which is what collectors search for.
enum CardCodeStyle {
  /// Set code, dash, 3-digit number: `OP16-001`, `OGN-296`.
  dashed,

  /// Set code and plain number, as in Cardmarket's Pokémon names: `BS 4`.
  spaced,

  /// No short code people search by (Magic, Lorcana): use name + set.
  none,
}

class Game {
  const Game({
    required this.id,
    required this.name,
    required this.cardmarketSlug,
    this.codeStyle = CardCodeStyle.none,
    this.hasEditions = false,
  });

  final String id;
  final String name;

  /// Path segment Cardmarket uses for this game, e.g. `Pokemon`.
  final String cardmarketSlug;

  final CardCodeStyle codeStyle;

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

  /// The total printed on the cards, e.g. 102 in `004/102`. Null when the
  /// cards only print their own number (modern Magic: `0001`).
  final int? printedTotal;
}

class CatalogCard {
  const CatalogCard({
    required this.id,
    required this.setId,
    required this.number,
    required this.name,
    required this.rarity,
    this.subtitle,
    this.cardmarketUrl,
    this.tcgplayerUrl,
  });

  final String id;
  final String setId;
  final int number;
  final String name;
  final String rarity;

  /// Second part of the name, e.g. Lorcana's version "On Human Legs".
  final String? subtitle;

  /// Direct product pages, when the catalog source provides them
  /// (Scryfall and pokemontcg.io do). Otherwise we fall back to a search.
  final String? cardmarketUrl;
  final String? tcgplayerUrl;

  String get fullName => subtitle == null ? name : '$name - $subtitle';

  String printedNumber(CardSet set) {
    final total = set.printedTotal;
    if (total == null) return number.toString().padLeft(4, '0');
    final width = total.toString().length.clamp(3, 4);
    return '${number.toString().padLeft(width, '0')}/$total';
  }

  /// What's printed on the card and shown above its pocket:
  /// `OP16-001` for One Piece / Riftbound, `004/102` for Pokémon and others.
  String displayNumber(Game game, CardSet set) =>
      game.codeStyle == CardCodeStyle.dashed
          ? code(game, set)!
          : printedNumber(set);

  /// The card's code as collectors search for it, e.g. `OP16-001` or
  /// `BS 4`. Null for games without a short code.
  String? code(Game game, CardSet set) {
    switch (game.codeStyle) {
      case CardCodeStyle.dashed:
        return '${set.code}-${number.toString().padLeft(3, '0')}';
      case CardCodeStyle.spaced:
        return '${set.code} $number';
      case CardCodeStyle.none:
        return null;
    }
  }
}
