import '../data/settings_store.dart';
import '../models/catalog.dart';

/// The games the app supports, in the order shown on the home screen.
const games = <Game>[
  Game(
    id: 'onepiece',
    name: 'One Piece',
    cardmarketSlug: 'OnePiece',
    codeStyle: CardCodeStyle.dashed,
    dataSource: 'OPTCG API (optcgapi.com)',
  ),
  Game(
    id: 'pokemon',
    name: 'Pokémon',
    cardmarketSlug: 'Pokemon',
    codeStyle: CardCodeStyle.slashed,
    dataSource: 'Pokémon TCG API (pokemontcg.io)',
    hasEditions: true,
  ),
  Game(
    id: 'magic',
    name: 'Magic',
    cardmarketSlug: 'Magic',
    codeStyle: CardCodeStyle.number,
    dataSource: 'Scryfall (scryfall.com)',
  ),
  Game(
    id: 'lorcana',
    name: 'Lorcana',
    cardmarketSlug: 'Lorcana',
    codeStyle: CardCodeStyle.number,
    dataSource: 'Lorcast (lorcast.com)',
  ),
  Game(
    id: 'riftbound',
    name: 'Riftbound',
    cardmarketSlug: 'Riftbound',
    codeStyle: CardCodeStyle.dashed,
    dataSource: 'Riftcodex (riftcodex.com)',
  ),
];

Game gameById(String id) => games.firstWhere((g) => g.id == id);

/// Games in the user's order, without hidden ones unless [includeHidden].
List<Game> arrangedGames(SettingsStore settings, {bool includeHidden = false}) {
  final ids = settings.orderedGameIds([for (final g in games) g.id]);
  return [
    for (final id in ids)
      if (includeHidden || !settings.isGameHidden(id)) gameById(id),
  ];
}
