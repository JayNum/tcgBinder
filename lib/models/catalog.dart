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

/// What kind of product a set is; used to filter the set list.
enum SetKind {
  booster('Boosters'),
  extra('Extra boosters'),
  starter('Starter decks'),
  promo('Promos');

  const SetKind(this.label);
  final String label;
}

class CardSet {
  const CardSet({
    required this.id,
    required this.gameId,
    required this.code,
    required this.name,
    required this.released,
    this.kind = SetKind.booster,
    this.printedTotal,
  });

  final String id;
  final String gameId;

  /// The code printed on the cards, e.g. `OP16` or `BS`.
  final String code;
  final String name;

  /// Release date, used for sorting. Where only the year is known we use
  /// the start of that year.
  final DateTime released;
  final SetKind kind;

  /// The total printed on the cards, e.g. 102 in `004/102`. Null when the
  /// cards only print their own number (modern Magic: `0001`).
  final int? printedTotal;

  int get releaseYear => released.year;
}

/// One printing of a card. Alt arts, parallels and reprints are separate
/// printings that share a code with their base card.
class CatalogCard {
  const CatalogCard({
    required this.id,
    required this.setId,
    required this.number,
    required this.name,
    required this.rarity,
    this.subtitle,
    this.variant,
    this.originSetCode,
    this.cardmarketUrl,
    this.tcgplayerUrl,
  });

  final String id;

  /// The set this printing is pulled from, i.e. the binder it belongs to.
  final String setId;
  final int number;
  final String name;
  final String rarity;

  /// Second part of the name, e.g. Lorcana's version "On Human Legs".
  final String? subtitle;

  /// Version label for alt arts and parallels, e.g. `P1`. Null = base card.
  final String? variant;

  /// For reprints that come in a newer set but keep their old code, the
  /// set code printed on the card (e.g. `OP13` for OP13-028 in OP-17 packs).
  final String? originSetCode;

  /// Direct product pages, when the catalog source provides them
  /// (Scryfall, pokemontcg.io, Lorcast do). Otherwise we fall back to a search.
  final String? cardmarketUrl;
  final String? tcgplayerUrl;

  String get fullName => subtitle == null ? name : '$name - $subtitle';

  bool get isVariant => variant != null;

  /// True for reprints from another set (they go at the end of a binder).
  bool get isReprint => originSetCode != null;

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
    final setCode = originSetCode ?? set.code;
    switch (game.codeStyle) {
      case CardCodeStyle.dashed:
        return '$setCode-${number.toString().padLeft(3, '0')}';
      case CardCodeStyle.spaced:
        return '$setCode $number';
      case CardCodeStyle.none:
        return null;
    }
  }
}

/// How the list of sets is sorted.
enum SetSort {
  newest('Newest first'),
  oldest('Oldest first'),
  name('Name A–Z');

  const SetSort(this.label);
  final String label;
}

List<CardSet> sortSets(Iterable<CardSet> sets, SetSort sort) {
  final list = sets.toList();
  switch (sort) {
    case SetSort.newest:
      list.sort((a, b) => b.released.compareTo(a.released));
    case SetSort.oldest:
      list.sort((a, b) => a.released.compareTo(b.released));
    case SetSort.name:
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
  return list;
}
