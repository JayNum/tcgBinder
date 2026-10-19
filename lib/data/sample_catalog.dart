import '../models/catalog.dart';

/// A small hand-written catalog so the app has something to show.
/// Next step: replace this with the imported catalogs for all five games.
const games = <Game>[
  Game(id: 'pokemon', name: 'Pokémon', cardmarketSlug: 'Pokemon', hasEditions: true),
  Game(id: 'magic', name: 'Magic: The Gathering', cardmarketSlug: 'Magic'),
  Game(id: 'onepiece', name: 'One Piece', cardmarketSlug: 'OnePiece'),
  Game(id: 'lorcana', name: 'Disney Lorcana', cardmarketSlug: 'Lorcana'),
  Game(id: 'riftbound', name: 'Riftbound', cardmarketSlug: 'Riftbound'),
];

const baseSet = CardSet(
  id: 'pokemon-base1',
  gameId: 'pokemon',
  code: 'BS',
  name: 'Base Set',
  releaseYear: 1999,
  printedTotal: 102,
);

const _baseSetNames = <String>[
  'Alakazam', 'Blastoise', 'Chansey', 'Charizard', 'Clefairy', 'Gyarados',
  'Hitmonchan', 'Machamp', 'Magneton', 'Mewtwo', 'Nidoking', 'Ninetales',
  'Poliwrath', 'Raichu', 'Venusaur', 'Zapdos', 'Beedrill', 'Dragonair',
  'Dugtrio', 'Electabuzz', 'Electrode', 'Pidgeotto',
];

final List<CatalogCard> baseSetCards = [
  for (var i = 0; i < _baseSetNames.length; i++)
    CatalogCard(
      id: 'base1-${i + 1}',
      setId: baseSet.id,
      number: i + 1,
      name: _baseSetNames[i],
      rarity: i < 16 ? 'Holo Rare' : 'Rare',
    ),
];

const sets = <CardSet>[baseSet];

Game gameById(String id) => games.firstWhere((g) => g.id == id);

List<CatalogCard> cardsInSet(String setId) =>
    baseSetCards.where((c) => c.setId == setId).toList();
