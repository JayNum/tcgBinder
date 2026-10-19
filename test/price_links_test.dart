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
    final testSet = CardSet(
      id: 'op16-test',
      gameId: 'onepiece',
      code: 'OP16',
      name: 'Test Set',
      released: DateTime(2026, 6, 12),
      printedTotal: 119,
    );
    const card = CatalogCard(
      id: 'op16-test-1',
      setId: 'op16-test',
      number: 1,
      name: 'Test Leader',
      rarity: 'Leader',
    );
    final onePiece = gameById('onepiece');

    expect(card.code(onePiece, testSet), 'OP16-001');
    expect(card.displayNumber(onePiece, testSet), 'OP16-001');
    final uri = PriceLinks.forMarketplace(
      Marketplace.cardmarket,
      game: onePiece,
      card: card,
      set: testSet,
    );
    expect(uri.path, '/en/OnePiece/Products/Search');
    expect(uri.queryParameters['searchString'], 'OP16-001');
    expect(
      PriceLinks.ebayQuery(game: onePiece, card: card, set: testSet),
      'OP16-001 Test Leader',
    );
  });

  test('reprints keep their old code and sit at the end of the new binder',
      () {
    final onePiece = gameById('onepiece');
    final cards = cardsInSet(op17.id);
    final shanks = cards.firstWhere((c) => c.name == 'Shanks');
    expect(shanks.displayNumber(onePiece, op17), 'OP13-028');
    expect(shanks.variant, 'P2');
    expect(cards.first.displayNumber(onePiece, op17), 'OP17-062');
    expect(cards.last.isReprint, isTrue);
    expect(
      PriceLinks.cardmarketQuery(game: onePiece, card: shanks, set: op17),
      'OP13-028',
    );
  });

  test('versions are found across sets, oldest first', () {
    final shanksP2 = cardsInSet(op17.id).firstWhere((c) => c.name == 'Shanks');
    final versions = versionsOf(shanksP2);
    expect(versions.map((v) => v.setId), [op13.id, op17.id]);
    expect(versions.first.variant, isNull);

    final kaido = cardsInSet(op17.id).first;
    expect(versionsOf(kaido).length, 4);

    // A card without alt arts has only itself.
    final charizardVersions = versionsOf(charizard);
    expect(charizardVersions, [charizard]);
  });

  test('sets sort by release date and by name', () {
    final onePieceSets = setsOfGame('onepiece');
    final newest = sortSets(onePieceSets, SetSort.newest);
    expect(newest.first.code, 'OP17');
    final oldest = sortSets(onePieceSets, SetSort.oldest);
    expect(oldest.first.code, 'OP01');
    final byName = sortSets(onePieceSets, SetSort.name);
    expect(byName.first.name, '500 Years in the Future');
  });

  test('Lorcana searches by name and version, links straight to TCGplayer', () {
    final ariel = cardsInSet(firstChapter.id).first;
    final lorcana = gameById('lorcana');
    expect(ariel.fullName, 'Ariel - On Human Legs');
    expect(ariel.printedNumber(firstChapter), '001/204');
    expect(
      PriceLinks.cardmarketQuery(game: lorcana, card: ariel, set: firstChapter),
      'Ariel On Human Legs',
    );
    final uri = PriceLinks.forMarketplace(
      Marketplace.tcgplayer,
      game: lorcana,
      card: ariel,
      set: firstChapter,
    );
    expect(uri.toString(), 'https://www.tcgplayer.com/product/494102');
  });

  test('every sample card has a unique id and a known set', () {
    final ids = allCards.map((c) => c.id).toSet();
    expect(ids.length, allCards.length);
    for (final card in allCards) {
      expect(sets.any((s) => s.id == card.setId), isTrue, reason: card.id);
    }
  });

  test('modern Magic shows only the collector number', () {
    final sire = cardsInSet(foundations.id).first;
    expect(sire.displayNumber(gameById('magic'), foundations), '0001');
  });

  test('games without a short code search Cardmarket by card name', () {
    final set = CardSet(
      id: 'm1',
      gameId: 'magic',
      code: 'M1',
      name: 'Some Set',
      released: DateTime(2026),
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
      'Some Card',
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
