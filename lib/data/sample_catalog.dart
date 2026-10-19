import '../models/catalog.dart';

/// A small hand-written test catalog: the first cards of one set per game.
/// Next step: replace this with the full imported catalogs.
const games = <Game>[
  Game(
    id: 'pokemon',
    name: 'Pokémon',
    cardmarketSlug: 'Pokemon',
    codeStyle: CardCodeStyle.spaced,
    hasEditions: true,
  ),
  Game(id: 'magic', name: 'Magic: The Gathering', cardmarketSlug: 'Magic'),
  Game(
    id: 'onepiece',
    name: 'One Piece',
    cardmarketSlug: 'OnePiece',
    codeStyle: CardCodeStyle.dashed,
  ),
  Game(id: 'lorcana', name: 'Disney Lorcana', cardmarketSlug: 'Lorcana'),
  Game(
    id: 'riftbound',
    name: 'Riftbound',
    cardmarketSlug: 'Riftbound',
    codeStyle: CardCodeStyle.dashed,
  ),
];

const baseSet = CardSet(
  id: 'pokemon-base1',
  gameId: 'pokemon',
  code: 'BS',
  name: 'Base Set',
  releaseYear: 1999,
  printedTotal: 102,
);

const op16 = CardSet(
  id: 'onepiece-op16',
  gameId: 'onepiece',
  code: 'OP16',
  name: 'The Time of Battle',
  releaseYear: 2026,
  printedTotal: 119,
);

const foundations = CardSet(
  id: 'magic-fdn',
  gameId: 'magic',
  code: 'FDN',
  name: 'Foundations',
  releaseYear: 2024,
);

const firstChapter = CardSet(
  id: 'lorcana-1',
  gameId: 'lorcana',
  code: 'TFC',
  name: 'The First Chapter',
  releaseYear: 2023,
  printedTotal: 204,
);

const origins = CardSet(
  id: 'riftbound-ogn',
  gameId: 'riftbound',
  code: 'OGN',
  name: 'Origins',
  releaseYear: 2025,
  printedTotal: 298,
);

const sets = <CardSet>[op16, baseSet, foundations, firstChapter, origins];

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
  ..._baseSetCards,
  ..._op16Cards,
  ..._foundationsCards,
  ..._firstChapterCards,
  ..._originsCards,
];

/// Kept for existing code and tests.
List<CatalogCard> get baseSetCards => _baseSetCards;

Game gameById(String id) => games.firstWhere((g) => g.id == id);

List<CatalogCard> cardsInSet(String setId) =>
    allCards.where((c) => c.setId == setId).toList();
