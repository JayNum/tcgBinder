import '../models/catalog.dart';

/// A small hand-written test catalog. It lists the real sets of each game
/// (most binders are empty until the full card lists are imported) and the
/// first cards of a few sets.
///
/// Release dates: exact where the source gave one (Lorcana, Riftbound,
/// OP-16, Pokémon, Magic); for older One Piece sets only the year was known,
/// so the month is an estimate that keeps the release order right.
const games = <Game>[
  Game(
    id: 'onepiece',
    name: 'One Piece',
    cardmarketSlug: 'OnePiece',
    codeStyle: CardCodeStyle.dashed,
  ),
  Game(
    id: 'pokemon',
    name: 'Pokémon',
    cardmarketSlug: 'Pokemon',
    codeStyle: CardCodeStyle.spaced,
    hasEditions: true,
  ),
  Game(id: 'magic', name: 'Magic', cardmarketSlug: 'Magic'),
  Game(id: 'lorcana', name: 'Lorcana', cardmarketSlug: 'Lorcana'),
  Game(
    id: 'riftbound',
    name: 'Riftbound',
    cardmarketSlug: 'Riftbound',
    codeStyle: CardCodeStyle.dashed,
  ),
];

// ---------------------------------------------------------------------------
// Sets
// ---------------------------------------------------------------------------

CardSet _op(String code, String name, int year, int month,
        {SetKind kind = SetKind.booster, int? total, int day = 1}) =>
    CardSet(
      id: 'onepiece-${code.toLowerCase()}',
      gameId: 'onepiece',
      code: code,
      name: name,
      released: DateTime(year, month, day),
      kind: kind,
      printedTotal: total,
    );

final op13 = _op('OP13', 'Carrying on His Will', 2025, 11);
final op16 =
    _op('OP16', 'The Time of Battle', 2026, 6, day: 12, total: 119);
final op17 =
    _op('OP17', "The World's Strongest Warriors", 2026, 9, total: 119);

final _onePieceSets = <CardSet>[
  _op('OP01', 'Romance Dawn', 2022, 12),
  _op('OP02', 'Paramount War', 2023, 3),
  _op('OP03', 'Pillars of Strength', 2023, 6),
  _op('OP04', 'Kingdoms of Intrigue', 2023, 9),
  _op('OP05', 'Awakening of the New Era', 2023, 12),
  _op('OP06', 'Wings of the Captain', 2024, 3),
  _op('EB01', 'Memorial Collection', 2024, 5, kind: SetKind.extra),
  _op('OP07', '500 Years in the Future', 2024, 6),
  _op('OP08', 'Two Legends', 2024, 9),
  _op('PRB01', 'One Piece Card THE BEST', 2024, 11, kind: SetKind.extra),
  _op('OP09', 'Emperors in the New World', 2024, 12),
  _op('OP10', 'Royal Blood', 2025, 3),
  _op('EB02', 'Anime 25th Collection', 2025, 5, kind: SetKind.extra),
  _op('OP11', 'A Fist of Divine Speed', 2025, 6),
  _op('OP12', 'Legacy of the Master', 2025, 8),
  _op('PRB02', 'One Piece Card THE BEST Vol.2', 2025, 10,
      kind: SetKind.extra),
  op13,
  _op('EB03', 'One Piece Heroines Edition', 2026, 2, kind: SetKind.extra),
  _op('OP14', "The Azure Sea's Seven", 2026, 3),
  _op('OP15', "Adventure on Kami's Island", 2026, 4),
  op16,
  op17,
  _op('P', 'Promotion cards', 2022, 12, day: 2, kind: SetKind.promo),
];

CardSet _pkm(String id, String code, String name, DateTime released, int total) =>
    CardSet(
      id: 'pokemon-$id',
      gameId: 'pokemon',
      code: code,
      name: name,
      released: released,
      printedTotal: total,
    );

final baseSet = _pkm('base1', 'BS', 'Base Set', DateTime(1999, 1, 9), 102);

final _pokemonSets = <CardSet>[
  baseSet,
  _pkm('jungle', 'JU', 'Jungle', DateTime(1999, 6, 16), 64),
  _pkm('fossil', 'FO', 'Fossil', DateTime(1999, 10, 10), 62),
  _pkm('base2', 'B2', 'Base Set 2', DateTime(2000, 2, 24), 130),
  _pkm('rocket', 'TR', 'Team Rocket', DateTime(2000, 4, 24), 82),
];

CardSet _mtg(String code, String name, DateTime released) => CardSet(
      id: 'magic-${code.toLowerCase()}',
      gameId: 'magic',
      code: code,
      name: name,
      released: released,
    );

final foundations = _mtg('FDN', 'Foundations', DateTime(2024, 11, 15));

final _magicSets = <CardSet>[
  _mtg('BLB', 'Bloomburrow', DateTime(2024, 8, 2)),
  _mtg('DSK', 'Duskmourn: House of Horror', DateTime(2024, 9, 27)),
  foundations,
  _mtg('DFT', 'Aetherdrift', DateTime(2025, 2, 14)),
];

CardSet _lor(int number, String name, DateTime released, {int total = 204}) =>
    CardSet(
      id: 'lorcana-$number',
      gameId: 'lorcana',
      code: 'Set $number',
      name: name,
      released: released,
      printedTotal: total,
    );

final firstChapter = _lor(1, 'The First Chapter', DateTime(2023, 8, 18));

final _lorcanaSets = <CardSet>[
  firstChapter,
  _lor(2, 'Rise of the Floodborn', DateTime(2023, 11, 17)),
  _lor(3, 'Into the Inklands', DateTime(2024, 2, 23)),
  _lor(4, "Ursula's Return", DateTime(2024, 5, 17)),
  _lor(5, 'Shimmering Skies', DateTime(2024, 8, 9)),
  _lor(6, 'Azurite Sea', DateTime(2024, 11, 15)),
  _lor(7, "Archazia's Island", DateTime(2025, 3, 7)),
  _lor(8, 'Reign of Jafar', DateTime(2025, 5, 30)),
  _lor(9, 'Fabled', DateTime(2025, 8, 29)),
  _lor(10, 'Whispers in the Well', DateTime(2025, 11, 7)),
  _lor(11, 'Winterspell', DateTime(2026, 2, 13)),
  _lor(12, 'Wilds Unknown', DateTime(2026, 5, 8)),
  _lor(13, 'Attack of the Vine!', DateTime(2026, 7, 17)),
  _lor(14, 'Hyperia City', DateTime(2026, 10, 16)),
];

CardSet _rb(String code, String name, DateTime released,
        {SetKind kind = SetKind.booster, int? total}) =>
    CardSet(
      id: 'riftbound-${code.toLowerCase()}',
      gameId: 'riftbound',
      code: code,
      name: name,
      released: released,
      kind: kind,
      printedTotal: total,
    );

final origins = _rb('OGN', 'Origins', DateTime(2025, 10, 31), total: 298);

final _riftboundSets = <CardSet>[
  origins,
  _rb('OGS', 'Origins: Proving Grounds', DateTime(2025, 10, 31),
      kind: SetKind.extra),
  _rb('SFD', 'Spiritforged', DateTime(2026, 2, 13)),
  _rb('UNL', 'Unleashed', DateTime(2026, 5, 8)),
  _rb('VEN', 'Vendetta', DateTime(2026, 7, 31)),
  _rb('PR', 'Promotional cards', DateTime(2025, 10, 31), kind: SetKind.promo),
];

final List<CardSet> sets = [
  ..._onePieceSets,
  ..._pokemonSets,
  ..._magicSets,
  ..._lorcanaSets,
  ..._riftboundSets,
];

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

/// (number, name, rarity) rows, so the lists below stay readable.
typedef _Row = (int, String, String);

List<CatalogCard> _cards(CardSet set, List<_Row> rows) => [
      for (final (number, name, rarity) in rows)
        CatalogCard(
          id: '${set.id}-$number',
          setId: set.id,
          number: number,
          name: name,
          rarity: rarity,
        ),
    ];

/// A parallel / alt art / reprint pulled from [set]. [originSetCode] is set
/// when the card keeps the code of an older set.
CatalogCard _variant(CardSet set, int number, String name, String variant,
        {String? originSetCode, String rarity = ''}) =>
    CatalogCard(
      id: '${set.id}-${originSetCode ?? set.code}-$number-$variant'
          .toLowerCase(),
      setId: set.id,
      number: number,
      name: name,
      rarity: rarity,
      variant: variant,
      originSetCode: originSetCode,
    );

final _baseSetCards = _cards(baseSet, const [
  (1, 'Alakazam', 'Holo Rare'),
  (2, 'Blastoise', 'Holo Rare'),
  (3, 'Chansey', 'Holo Rare'),
  (4, 'Charizard', 'Holo Rare'),
  (5, 'Clefairy', 'Holo Rare'),
  (6, 'Gyarados', 'Holo Rare'),
  (7, 'Hitmonchan', 'Holo Rare'),
  (8, 'Machamp', 'Holo Rare'),
  (9, 'Magneton', 'Holo Rare'),
  (10, 'Mewtwo', 'Holo Rare'),
  (11, 'Nidoking', 'Holo Rare'),
  (12, 'Ninetales', 'Holo Rare'),
  (13, 'Poliwrath', 'Holo Rare'),
  (14, 'Raichu', 'Holo Rare'),
  (15, 'Venusaur', 'Holo Rare'),
  (16, 'Zapdos', 'Holo Rare'),
  (17, 'Beedrill', 'Rare'),
  (18, 'Dragonair', 'Rare'),
  (19, 'Dugtrio', 'Rare'),
  (20, 'Electabuzz', 'Rare'),
  (21, 'Electrode', 'Rare'),
  (22, 'Pidgeotto', 'Rare'),
]);

final _op16Cards = _cards(op16, const [
  (1, 'Portgas.D.Ace', 'Leader'),
  (2, 'Izo', 'Uncommon'),
  (3, 'Edward.Newgate', 'Super Rare'),
  (4, 'Curiel', 'Common'),
  (5, 'Thatch', 'Uncommon'),
  (6, 'Shanks', 'Common'),
  (7, 'Jozu', 'Uncommon'),
  (8, 'Squard', 'Common'),
  (9, 'Speed Jil', 'Common'),
  (10, 'Namule', 'Uncommon'),
  (11, 'Vista', 'Rare'),
  (12, 'Benn.Beckman', 'Rare'),
  (13, 'McGuy', 'Common'),
  (14, 'Marco', 'Rare'),
  (15, 'Monkey.D.Luffy', 'Super Rare'),
  (16, 'Ramba', 'Common'),
  (17, 'LittleOars Jr.', 'Rare'),
  (18, 'Rockstar', 'Common'),
  (19, "Let's Show 'Em What We're Made Of!!", 'Common'),
  (20, "If You're Coming with Me… Kiss Your Lives Goodbye!!", 'Uncommon'),
  (21, 'Moby Dick', 'Rare'),
  (22, 'Monkey.D.Luffy', 'Leader'),
  (23, 'Arlong', 'Common'),
  (24, 'Inazuma', 'Uncommon'),
  (25, 'Bunkov', 'Uncommon'),
  (26, 'Emporio.Ivankov', 'Super Rare'),
  (27, 'Jinbe', 'Rare'),
]);

/// OP-17 example: Kaido and his parallels, plus reprints of older cards
/// that come in OP-17 boosters with their old codes.
final _op17Cards = <CatalogCard>[
  CatalogCard(
    id: '${op17.id}-62',
    setId: op17.id,
    number: 62,
    name: 'Kaido',
    rarity: '',
  ),
  _variant(op17, 62, 'Kaido', 'P1'),
  _variant(op17, 62, 'Kaido', 'P2'),
  _variant(op17, 62, 'Kaido', 'P3'),
  _variant(op17, 4, 'Monkey.D.Luffy', 'P1',
      originSetCode: 'ST31', rarity: 'SP card'),
  _variant(op17, 28, 'Shanks', 'P2', originSetCode: 'OP13', rarity: 'SP card'),
  _variant(op17, 61, 'Monkey.D.Luffy', 'P3',
      originSetCode: 'EB04', rarity: 'Secret Rare'),
];

/// The base Shanks whose parallel is reprinted in OP-17.
final _op13Cards = <CatalogCard>[
  CatalogCard(
    id: '${op13.id}-28',
    setId: op13.id,
    number: 28,
    name: 'Shanks',
    rarity: '',
  ),
];

final _foundationsCards = _cards(foundations, const [
  (1, 'Sire of Seven Deaths', 'Mythic Rare'),
  (2, 'Arahbo, the First Fang', 'Rare'),
  (3, 'Armasaur Guide', 'Common'),
  (4, 'Cat Collector', 'Uncommon'),
  (5, 'Celestial Armor', 'Rare'),
  (6, 'Claws Out', 'Uncommon'),
  (7, 'Crystal Barricade', 'Rare'),
  (8, 'Dauntless Veteran', 'Uncommon'),
  (9, 'Dazzling Angel', 'Common'),
  (10, 'Divine Resilience', 'Uncommon'),
  (11, 'Exemplar of Light', 'Rare'),
  (12, 'Felidar Savior', 'Common'),
  (13, 'Fleeting Flight', 'Common'),
  (14, 'Guarded Heir', 'Uncommon'),
  (15, 'Hare Apparent', 'Common'),
  (16, 'Helpful Hunter', 'Common'),
  (17, 'Herald of Eternal Dawn', 'Mythic Rare'),
]);

/// Lorcana cards have a name and a version; Lorcast provides TCGplayer ids,
/// so these link straight to the product page.
const _firstChapterRows = <(int, String, String?, String, int)>[
  (1, 'Ariel', 'On Human Legs', 'Uncommon', 494102),
  (2, 'Ariel', 'Spectacular Singer', 'Super Rare', 504451),
  (3, 'Cinderella', 'Gentle and Kind', 'Uncommon', 508692),
  (4, 'Goofy', 'Musketeer', 'Uncommon', 501751),
  (5, 'Hades', 'King of Olympus', 'Rare', 485364),
  (6, 'Hades', 'Lord of the Underworld', 'Rare', 493480),
  (7, 'HeiHei', 'Boat Snack', 'Common', 493479),
  (8, 'LeFou', 'Bumbler', 'Uncommon', 492738),
  (9, 'Lilo', 'Making a Wish', 'Rare', 503315),
  (10, 'Maximus', 'Palace Horse', 'Super Rare', 506837),
  (11, 'Maximus', 'Relentless Pursuer', 'Uncommon', 494101),
  (12, 'Mickey Mouse', 'True Friend', 'Uncommon', 493476),
  (13, 'Minnie Mouse', 'Beloved Princess', 'Common', 493498),
  (14, 'Moana', 'Of Motunui', 'Rare', 492739),
  (15, 'Mr. Smee', 'Loyal First Mate', 'Common', 508697),
  (16, 'Prince Phillip', 'Dragonslayer', 'Uncommon', 505946),
  (17, 'Pumbaa', 'Friendly Warthog', 'Common', 508701),
  (18, 'Rapunzel', 'Gifted with Healing', 'Legendary', 506836),
  (19, 'Sebastian', 'Court Composer', 'Common', 504540),
  (20, 'Simba', 'Protective Cub', 'Common', 503356),
  (21, 'Stitch', 'Carefree Surfer', 'Legendary', 502009),
  (22, 'Stitch', 'New Dog', 'Common', 493499),
  (23, 'Stitch', 'Rock Star', 'Super Rare', 492708),
  (24, 'Timon', 'Grub Rustler', 'Common', 497197),
  (25, 'Be Our Guest', null, 'Uncommon', 494110),
  (26, 'Control Your Temper!', null, 'Common', 493501),
  (27, 'Hakuna Matata', null, 'Common', 506124),
];

final _firstChapterCards = [
  for (final (number, name, version, rarity, tcgplayerId) in _firstChapterRows)
    CatalogCard(
      id: '${firstChapter.id}-$number',
      setId: firstChapter.id,
      number: number,
      name: name,
      subtitle: version,
      rarity: rarity,
      tcgplayerUrl: 'https://www.tcgplayer.com/product/$tcgplayerId',
    ),
];

final _originsCards = _cards(origins, const [
  (1, 'Blazing Scorcher', 'Common'),
  (2, 'Brazen Buccaneer', 'Common'),
  (3, 'Chemtech Enforcer', 'Common'),
  (4, 'Cleave', 'Common'),
  (5, 'Disintegrate', 'Common'),
  (6, 'Flame Chompers', 'Common'),
  (7, 'Fury Rune', 'Common'),
  (8, 'Get Excited!', 'Common'),
  (9, 'Hextech Ray', 'Common'),
  (10, 'Legion Rearguard', 'Common'),
  (11, 'Magma Wurm', 'Common'),
  (12, 'Noxus Hopeful', 'Common'),
  (13, 'Pouty Poro', 'Common'),
  (14, 'Sky Splitter', 'Common'),
  (15, 'Captain Farron', 'Uncommon'),
  (16, 'Dangerous Duo', 'Uncommon'),
  (17, 'Iron Ballista', 'Uncommon'),
  (18, 'Noxus Saboteur', 'Uncommon'),
  (19, 'Raging Soul', 'Uncommon'),
  (20, 'Scrapyard Champion', 'Uncommon'),
  (21, 'Sun Disc', 'Uncommon'),
  (22, 'Thermo Beam', 'Uncommon'),
  (23, 'Unlicensed Armory', 'Uncommon'),
  (24, 'Void Seeker', 'Uncommon'),
  (25, 'Blind Fury', 'Rare'),
  (26, 'Brynhir Thundersong', 'Rare'),
]);

final List<CatalogCard> allCards = [
  ..._op16Cards,
  ..._op17Cards,
  ..._op13Cards,
  ..._baseSetCards,
  ..._foundationsCards,
  ..._firstChapterCards,
  ..._originsCards,
];

/// Kept for existing code and tests.
List<CatalogCard> get baseSetCards => _baseSetCards;

// ---------------------------------------------------------------------------
// Lookups
// ---------------------------------------------------------------------------

Game gameById(String id) => games.firstWhere((g) => g.id == id);

CardSet setById(String id) => sets.firstWhere((s) => s.id == id);

List<CardSet> setsOfGame(String gameId) =>
    sets.where((s) => s.gameId == gameId).toList();

/// Cards pulled from [setId], in binder order: the set's own cards by
/// number (each followed by its alt arts), then reprints from other sets.
List<CatalogCard> cardsInSet(String setId) {
  final cards = allCards.where((c) => c.setId == setId).toList();
  int group(CatalogCard c) => c.isReprint ? 1 : 0;
  cards.sort((a, b) {
    final byGroup = group(a).compareTo(group(b));
    if (byGroup != 0) return byGroup;
    final byOrigin = (a.originSetCode ?? '').compareTo(b.originSetCode ?? '');
    if (byOrigin != 0) return byOrigin;
    final byNumber = a.number.compareTo(b.number);
    if (byNumber != 0) return byNumber;
    return (a.variant ?? '').compareTo(b.variant ?? '');
  });
  return cards;
}

/// Key that is equal for all versions of the same card: its code for games
/// that print one (`OP13-028`), otherwise its full name.
String versionKey(CatalogCard card) {
  final set = setById(card.setId);
  final game = gameById(set.gameId);
  return '${game.id}|${card.code(game, set) ?? card.fullName}';
}

/// Every printing of [card] (including itself), oldest set first.
List<CatalogCard> versionsOf(CatalogCard card) {
  final key = versionKey(card);
  final versions = allCards.where((c) => versionKey(c) == key).toList();
  versions.sort((a, b) {
    final bySet = setById(a.setId).released.compareTo(setById(b.setId).released);
    if (bySet != 0) return bySet;
    return (a.variant ?? '').compareTo(b.variant ?? '');
  });
  return versions;
}
