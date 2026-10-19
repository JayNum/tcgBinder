import 'package:flutter_test/flutter_test.dart';
import 'package:tcg_binder/data/sample_catalog.dart';
import 'package:tcg_binder/models/catalog.dart';
import 'package:tcg_binder/models/collection.dart';
import 'package:tcg_binder/services/price_links.dart';

void main() {
  final charizard = baseSetCards.firstWhere((c) => c.name == 'Charizard');
  final pokemon = gameById('pokemon');

  test('printed number is padded like on the card', () {
    expect(charizard.printedNumber(baseSet), '004/102');
  });

  test('search text includes the edition unless it is Unlimited', () {
    expect(
      PriceLinks.searchQuery(card: charizard, set: baseSet, edition: Edition.unlimited),
      'Charizard Base Set',
    );
    expect(
      PriceLinks.searchQuery(card: charizard, set: baseSet, edition: Edition.firstEdition),
      'Charizard Base Set 1st Edition',
    );
  });

  test('Europe gets Cardmarket first, elsewhere TCGplayer first', () {
    expect(PriceLinks.orderedFor('AT').first, Marketplace.cardmarket);
    expect(PriceLinks.orderedFor('US').first, Marketplace.tcgplayer);
    expect(PriceLinks.orderedFor(null).first, Marketplace.tcgplayer);
  });

  test('Cardmarket searches Pokémon by name and set code', () {
    final uri = PriceLinks.forMarketplace(
      Marketplace.cardmarket,
      game: pokemon,
      card: charizard,
      set: baseSet,
    );
    expect(uri.host, 'www.cardmarket.com');
    expect(uri.path, '/en/Pokemon/Products/Search');
    expect(uri.queryParameters['searchString'], 'Charizard BS 4');
  });

  test('Cardmarket searches One Piece by card code only', () {
    const op16 = CardSet(
      id: 'op16',
      gameId: 'onepiece',
      code: 'OP16',
      name: 'Test Set',
      releaseYear: 2026,
      printedTotal: 119,
    );
    const card = CatalogCard(
      id: 'op16-1',
      setId: 'op16',
      number: 1,
      name: 'Test Leader',
      rarity: 'Leader',
    );
    final onePiece = gameById('onepiece');

    expect(card.code(onePiece, op16), 'OP16-001');
    expect(card.displayNumber(onePiece, op16), 'OP16-001');
    final uri = PriceLinks.forMarketplace(
      Marketplace.cardmarket,
      game: onePiece,
      card: card,
      set: op16,
    );
    expect(uri.path, '/en/OnePiece/Products/Search');
    expect(uri.queryParameters['searchString'], 'OP16-001');
    expect(
      PriceLinks.ebayQuery(game: onePiece, card: card, set: op16),
      'OP16-001 Test Leader',
    );
  });

  test('games without a short code search by name and set', () {
    const set = CardSet(
      id: 'm1',
      gameId: 'magic',
      code: 'M1',
      name: 'Some Set',
      releaseYear: 2026,
      printedTotal: 300,
    );
    const card = CatalogCard(
      id: 'm1-7',
      setId: 'm1',
      number: 7,
      name: 'Some Card',
      rarity: 'Rare',
    );
    final magic = gameById('magic');
    expect(card.code(magic, set), isNull);
    expect(
      PriceLinks.cardmarketQuery(game: magic, card: card, set: set),
      'Some Card Some Set',
    );
  });

  test('eBay uses the local site and sold listings', () {
    final uri = PriceLinks.forMarketplace(
      Marketplace.ebay,
      game: pokemon,
      card: charizard,
      set: baseSet,
      countryCode: 'AT',
    );
    expect(uri.host, 'www.ebay.at');
    expect(uri.queryParameters['LH_Sold'], '1');
  });
}
