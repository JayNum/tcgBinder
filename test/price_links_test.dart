import 'package:flutter_test/flutter_test.dart';
import 'package:tcg_binder/data/sample_catalog.dart';
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

  test('Cardmarket falls back to a search on the right game', () {
    final uri = PriceLinks.forMarketplace(
      Marketplace.cardmarket,
      game: pokemon,
      card: charizard,
      set: baseSet,
    );
    expect(uri.host, 'www.cardmarket.com');
    expect(uri.path, '/en/Pokemon/Products/Search');
    expect(uri.queryParameters['searchString'], 'Charizard Base Set');
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
