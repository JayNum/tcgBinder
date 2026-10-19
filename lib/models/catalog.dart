/// Catalog data: games, sets and cards as published by the card databases.
/// This is reference data — it never contains anything about the user.
library;

/// How a game prints its card code, which is what collectors search for.
enum CardCodeStyle {
  /// Set code, dash, number: `OP16-001`, `OGN-011`.
  dashed,

  /// Number over set total: `4/102`.
  slashed,

  /// Just a collector number: Magic `0001`, Lorcana `#1`.
  number,
}

class Game {
  const Game({
    required this.id,
    required this.name,
    required this.cardmarketSlug,
    required this.codeStyle,
    required this.dataSource,
    this.hasEditions = false,
  });

  final String id;
  final String name;

  /// Path segment Cardmarket uses for this game, e.g. `Pokemon`.
  final String cardmarketSlug;
  final CardCodeStyle codeStyle;

  /// Where the card lists come from, shown in the app.
  final String dataSource;

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

  static SetKind byName(String? name) =>
      SetKind.values.firstWhere((k) => k.name == name, orElse: () => booster);
}

class CardSet {
  const CardSet({
    required this.id,
    required this.gameId,
    required this.sourceId,
    required this.code,
    required this.name,
    required this.order,
    this.released,
    this.kind = SetKind.booster,
    this.printedTotal,
  });

  /// Our id, unique across games, e.g. `pokemon-base1`.
  final String id;
  final String gameId;

  /// The id the card database uses for this set, e.g. `base1` or `OP-16`.
  final String sourceId;

  /// The code collectors know the set by, e.g. `OP-16`, `BS`, `FDN`.
  final String code;
  final String name;

  /// Release date if known.
  final DateTime? released;

  /// Position in the source's list, used when no date is known.
  final int order;
  final SetKind kind;

  /// The total printed on the cards, e.g. 102 in `4/102`.
  final int? printedTotal;

  int? get releaseYear => released?.year;

  Map<String, Object?> toJson() => {
        'id': id,
        'gameId': gameId,
        'sourceId': sourceId,
        'code': code,
        'name': name,
        'order': order,
        'released': released?.toIso8601String(),
        'kind': kind.name,
        'printedTotal': printedTotal,
      };

  factory CardSet.fromJson(Map<String, Object?> json) => CardSet(
        id: json['id']! as String,
        gameId: json['gameId']! as String,
        sourceId: json['sourceId']! as String,
        code: json['code']! as String,
        name: json['name']! as String,
        order: (json['order'] as num?)?.toInt() ?? 0,
        released: json['released'] == null
            ? null
            : DateTime.tryParse(json['released']! as String),
        kind: SetKind.byName(json['kind'] as String?),
        printedTotal: (json['printedTotal'] as num?)?.toInt(),
      );
}

/// One printing of a card. Alt arts, parallels and reprints are separate
/// printings; all printings of a card share a [versionKey].
class CatalogCard {
  const CatalogCard({
    required this.id,
    required this.setId,
    required this.gameId,
    required this.code,
    required this.sortNumber,
    required this.name,
    required this.versionKey,
    required this.cardmarketQuery,
    this.rarity = '',
    this.subtitle,
    this.variant,
    this.reprint = false,
    this.cardmarketUrl,
    this.tcgplayerUrl,
  });

  final String id;

  /// The set this printing is pulled from, i.e. the binder it belongs to.
  final String setId;
  final String gameId;

  /// What's printed on the card and shown above its pocket:
  /// `OP16-001`, `4/102`, `0001`.
  final String code;

  /// Numeric part of the collector number, for ordering the binder.
  final int sortNumber;
  final String name;
  final String rarity;

  /// Second part of the name, e.g. Lorcana's version "On Human Legs".
  final String? subtitle;

  /// Version label for alt arts and parallels, e.g. `P1`. Null = base card.
  final String? variant;

  /// A card from an older set that comes in this set's boosters with its
  /// old code. Reprints go at the end of the binder.
  final bool reprint;

  /// Equal for all printings of the same card.
  final String versionKey;

  /// What to search for on Cardmarket when there's no direct link.
  final String cardmarketQuery;
  final String? cardmarketUrl;
  final String? tcgplayerUrl;

  String get fullName => subtitle == null ? name : '$name - $subtitle';

  bool get isVariant => variant != null;

  /// Counts towards "x of y collected" (not an alt art or reprint).
  bool get isBase => variant == null && !reprint;

  Map<String, Object?> toJson() => {
        'id': id,
        'setId': setId,
        'gameId': gameId,
        'code': code,
        'sortNumber': sortNumber,
        'name': name,
        'rarity': rarity,
        'subtitle': subtitle,
        'variant': variant,
        'reprint': reprint,
        'versionKey': versionKey,
        'cardmarketQuery': cardmarketQuery,
        'cardmarketUrl': cardmarketUrl,
        'tcgplayerUrl': tcgplayerUrl,
      };

  factory CatalogCard.fromJson(Map<String, Object?> json) => CatalogCard(
        id: json['id']! as String,
        setId: json['setId']! as String,
        gameId: json['gameId']! as String,
        code: json['code']! as String,
        sortNumber: (json['sortNumber'] as num?)?.toInt() ?? 0,
        name: json['name']! as String,
        rarity: json['rarity'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        variant: json['variant'] as String?,
        reprint: json['reprint'] as bool? ?? false,
        versionKey: json['versionKey']! as String,
        cardmarketQuery: json['cardmarketQuery']! as String,
        cardmarketUrl: json['cardmarketUrl'] as String?,
        tcgplayerUrl: json['tcgplayerUrl'] as String?,
      );
}

/// Binder order: the set's own cards by number (each followed by its alt
/// arts), then reprints from other sets.
int compareBinderOrder(CatalogCard a, CatalogCard b) {
  final byReprint = (a.reprint ? 1 : 0).compareTo(b.reprint ? 1 : 0);
  if (byReprint != 0) return byReprint;
  if (a.reprint) {
    final byCode = a.code.compareTo(b.code);
    if (byCode != 0) return byCode;
  }
  final byNumber = a.sortNumber.compareTo(b.sortNumber);
  if (byNumber != 0) return byNumber;
  final byCode = a.code.compareTo(b.code);
  if (byCode != 0) return byCode;
  return (a.variant ?? '').compareTo(b.variant ?? '');
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
  // Sets without a date sort by their position in the source's list.
  int byDate(CardSet a, CardSet b) {
    final da = a.released, db = b.released;
    if (da != null && db != null) {
      final c = da.compareTo(db);
      if (c != 0) return c;
    } else if (da != null) {
      return 1;
    } else if (db != null) {
      return -1;
    }
    return a.order.compareTo(b.order);
  }

  switch (sort) {
    case SetSort.newest:
      list.sort((a, b) => byDate(b, a));
    case SetSort.oldest:
      list.sort(byDate);
    case SetSort.name:
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
  return list;
}

/// Leading digits of a collector number: `"007a"` → 7, `"TG01"` → 1.
int parseSortNumber(String number) {
  final match = RegExp(r'\d+').firstMatch(number);
  return match == null ? 0 : int.parse(match.group(0)!);
}
