import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tcg_binder/catalog/sources/pokemon_source.dart';
import 'package:tcg_binder/models/catalog.dart';
import 'package:tcg_binder/scanner/art_hash.dart';
import 'package:tcg_binder/services/card_text.dart';

Uint8List picture(int Function(int x, int y) red, {int w = 126, int h = 176}) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      image.setPixelRgb(x, y, red(x, y).clamp(0, 255), (x * 2) % 256, y % 256);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('Scryfall answer gives the printed text in that language', () {
    final t = CardTextService.parseScryfall({
      'data': [
        {
          'name': 'Lightning Bolt',
          'printed_name': 'Blitzschlag',
          'printed_text': 'Blitzschlag fügt einer Kreatur 3 Schaden zu.',
          'oracle_text': 'Lightning Bolt deals 3 damage to any target.',
        }
      ]
    }, 'German');
    expect(t!.name, 'Blitzschlag');
    expect(t.text, contains('Schaden'));
    expect(CardTextService.parseScryfall({'data': []}, 'German'), isNull);
  });

  test('TCGdex answer joins abilities, attacks and effects', () {
    final t = CardTextService.parseTcgdex({
      'name': 'Glurak',
      'attacks': [
        {'name': 'Feuerwirbel', 'damage': 100, 'effect': 'Wirf 2 Energien ab.'}
      ],
    }, 'German');
    expect(t!.name, 'Glurak');
    expect(t.text, 'Feuerwirbel 100: Wirf 2 Energien ab.');
    expect(CardTextService.parseTcgdex({'name': 'x'}, 'German'), isNull);
  });

  test('only Magic and Pokémon offer other languages', () {
    CatalogCard card(String game) => CatalogCard(
          id: '$game-1',
          setId: '$game-set',
          gameId: game,
          code: '1',
          sortNumber: 1,
          name: 'x',
          versionKey: 'k',
          cardmarketQuery: 'x',
        );
    expect(CardTextService.languagesFor(card('magic')).length, greaterThan(5));
    expect(CardTextService.languagesFor(card('pokemon')).length, greaterThan(5));
    expect(CardTextService.languagesFor(card('onepiece')), ['English']);
  });

  test('Pokémon cards keep their English text and picture', () {
    const set = CardSet(
      id: 'pokemon-base1',
      gameId: 'pokemon',
      sourceId: 'base1',
      code: 'BS',
      name: 'Base',
      order: 0,
      printedTotal: 102,
    );
    final cards = PokemonSource.parseCards([
      {
        'id': 'base1-4',
        'name': 'Charizard',
        'number': '4',
        'rarity': 'Rare Holo',
        'images': {'large': 'https://example.com/4.png'},
        'attacks': [
          {'name': 'Fire Spin', 'damage': '100', 'text': 'Discard 2 Energy.'}
        ],
      }
    ], set);
    expect(cards.single.imageUrl, 'https://example.com/4.png');
    expect(cards.single.text, 'Fire Spin 100: Discard 2 Energy.');
    final back = CatalogCard.fromJson(cards.single.toJson());
    expect(back.text, cards.single.text);
    expect(back.imageUrl, cards.single.imageUrl);
  });

  test('the same artwork is close, another artwork is far', () {
    final a = artPrintOf(picture((x, y) => x * 2), 'magic')!;
    // A photo of the same card: a bit brighter.
    final photo = artPrintOf(picture((x, y) => x * 2 + 12), 'magic')!;
    final other = artPrintOf(picture((x, y) => 255 - x * 2), 'magic')!;
    expect(a.distanceTo(photo), lessThan(a.distanceTo(other)));

    final ranked = rankArt(photo, {'same': a, 'other': other}, maxDistance: 1);
    expect(ranked.first.cardId, 'same');
  });

  test('fingerprints survive saving', () {
    final a = artPrintOf(picture((x, y) => x), 'pokemon')!;
    final back = ArtPrint.decode(a.encode())!;
    expect(back.hash, a.hash);
    expect(back.colors, a.colors);
    expect(a.distanceTo(back), 0);
  });
}
