import 'package:flutter_test/flutter_test.dart';
import 'package:tcg_binder/catalog/sources/lorcana_source.dart';
import 'package:tcg_binder/catalog/sources/magic_source.dart';
import 'package:tcg_binder/catalog/sources/one_piece_source.dart';
import 'package:tcg_binder/catalog/sources/pokemon_source.dart';
import 'package:tcg_binder/catalog/sources/riftbound_source.dart';
import 'package:tcg_binder/models/catalog.dart';

/// The JSON below follows the real responses of each database.
void main() {
  group('One Piece (optcgapi.com)', () {
    final romanceDawn = CardSet(
      id: 'onepiece-OP-01',
      gameId: 'onepiece',
      sourceId: 'OP-01',
      code: 'OP-01',
      name: 'Romance Dawn',
      order: 0,
      released: DateTime(2022, 12, 2),
    );
    final theBest = CardSet(
      id: 'onepiece-PRB-01',
      gameId: 'onepiece',
      sourceId: 'PRB-01',
      code: 'PRB-01',
      name: 'Premium Booster -The Best-',
      order: 9,
      kind: SetKind.extra,
    );
    Map<String, Object?> row(String name, String setId, String imageId) => {
          'card_set_id': 'OP01-120',
          'card_name': name,
          'rarity': 'SEC',
          'set_id': setId,
          'card_image_id': imageId,
        };

    test('base card, parallels and versions', () {
      final cards = OnePieceSource.parseCards([
        row('Shanks (Parallel)', 'OP-01', 'OP01-120_p1'),
        row('Shanks', 'OP-01', 'OP01-120'),
        row('Shanks (Parallel) (Manga) (Alternate Art)', 'OP-01', 'OP01-120_p2'),
      ], romanceDawn);

      expect(cards.map((c) => c.variant), [null, 'P1', 'P2']);
      expect(cards.every((c) => c.name == 'Shanks'), isTrue);
      expect(cards.every((c) => c.code == 'OP01-120'), isTrue);
      expect(cards.every((c) => !c.reprint), isTrue);
      expect(cards[2].subtitle, 'Parallel · Manga · Alternate Art');
      expect(cards.first.isBase, isTrue);
      expect(cards.map((c) => c.versionKey).toSet(), {'onepiece|OP01-120'});
      expect(cards.first.cardmarketQuery, 'OP01-120');
    });

    test('reprints in a newer set keep their code and are marked', () {
      final cards = OnePieceSource.parseCards([
        row('Shanks (OP01-120) (Reprint)', 'PRB-01', 'OP01-120_p7'),
      ], theBest);
      expect(cards.single.reprint, isTrue);
      expect(cards.single.code, 'OP01-120');
      expect(cards.single.subtitle, 'Reprint');
      expect(cards.single.setId, 'onepiece-PRB-01');
    });

    test('drops number notes from names', () {
      final (name, notes) =
          OnePieceSource.splitName('Charlotte Linlin (112)', 'OP17-112');
      expect(name, 'Charlotte Linlin');
      expect(notes, isEmpty);
    });
  });

  group('Pokémon (pokemontcg.io)', () {
    test('sets and cards', () {
      final sets = PokemonSource.parseSets([
        {
          'id': 'base1',
          'name': 'Base',
          'series': 'Base',
          'printedTotal': 102,
          'total': 102,
          'ptcgoCode': 'BS',
          'releaseDate': '1999/01/09',
        },
      ]);
      final base = sets.single;
      expect(base.id, 'pokemon-base1');
      expect(base.code, 'BS');
      expect(base.released, DateTime(1999, 1, 9));
      expect(base.printedTotal, 102);

      final cards = PokemonSource.parseCards([
        {
          'id': 'base1-4',
          'name': 'Charizard',
          'number': '4',
          'rarity': 'Rare Holo',
          'tcgplayer': {'url': 'https://prices.pokemontcg.io/tcgplayer/base1-4'},
          'cardmarket': {'url': 'https://prices.pokemontcg.io/cardmarket/base1-4'},
        },
      ], base);
      final charizard = cards.single;
      expect(charizard.code, '4/102');
      expect(charizard.cardmarketQuery, 'Charizard BS 4');
      expect(charizard.cardmarketUrl, contains('cardmarket/base1-4'));
    });
  });

  group('Lorcana (lorcast.com)', () {
    test('sets and cards', () {
      final sets = LorcanaSource.parseSets([
        {'id': 'set_1', 'code': '1', 'name': 'The First Chapter', 'released_at': '2023-08-18'},
        {'id': 'set_p1', 'code': 'P1', 'name': 'Promo Set 1', 'released_at': '2023-08-18'},
      ]);
      expect(sets.first.code, 'Set 1');
      expect(sets.first.printedTotal, 204);
      expect(sets.last.kind, SetKind.promo);

      final cards = LorcanaSource.parseCards([
        {
          'id': 'crd_1',
          'name': 'Ariel',
          'version': 'On Human Legs',
          'rarity': 'Uncommon',
          'collector_number': '1',
          'tcgplayer_id': 494102,
          'purchase_uris': {'tcgplayer': 'https://www.tcgplayer.com/product/494102'},
        },
        {
          'id': 'crd_205',
          'name': 'Ariel',
          'version': 'On Human Legs',
          'rarity': 'Enchanted',
          'collector_number': '205',
          'tcgplayer_id': 1,
        },
      ], sets.first);
      expect(cards.first.code, '1/204');
      expect(cards.first.fullName, 'Ariel - On Human Legs');
      expect(cards.first.tcgplayerUrl, 'https://www.tcgplayer.com/product/494102');
      expect(cards.last.variant, 'Special');
      expect(cards.first.versionKey, cards.last.versionKey);
    });
  });

  group('Riftbound (riftcodex.com)', () {
    test('sets and cards', () {
      final sets = RiftboundSource.parseSets([
        {'id': 'x', 'name': 'Origins', 'set_id': 'OGN', 'card_count': 352, 'published_on': '2025-10-31T00:00:00'},
        {'id': 'y', 'name': 'Origins: Proving Grounds', 'set_id': 'OGS', 'card_count': 24, 'published_on': '2025-10-31T00:00:00'},
        {'id': 'z', 'name': 'Riftbound Promotional Cards', 'set_id': 'PR', 'card_count': 13, 'published_on': '2025-10-31T00:00:00'},
      ]);
      expect(sets.map((s) => s.kind), [SetKind.booster, SetKind.extra, SetKind.promo]);

      final cards = RiftboundSource.parseCards([
        {
          'id': 'a',
          'name': 'Fury Rune',
          'riftbound_id': 'ogn-007a-298',
          'tcgplayer_id': '123',
          'collector_number': 7,
          'classification': {'rarity': 'Common'},
          'metadata': {'alternate_art': true, 'signature': false},
        },
        {
          'id': 'b',
          'name': 'Fury Rune',
          'riftbound_id': 'ogn-007-298',
          'tcgplayer_id': '122',
          'collector_number': 7,
          'classification': {'rarity': 'Common'},
          'metadata': {'alternate_art': false, 'signature': false},
        },
      ], sets.first);
      expect(cards.map((c) => c.code), ['OGN-007', 'OGN-007a']);
      expect(cards.last.variant, 'Alt art');
      expect(cards.first.versionKey, cards.last.versionKey);
      expect(cards.first.tcgplayerUrl, 'https://www.tcgplayer.com/product/122');
    });
  });

  group('Magic (scryfall.com)', () {
    test('sets and cards', () {
      final sets = MagicSource.parseSets([
        {'code': 'fdn', 'name': 'Foundations', 'released_at': '2024-11-15', 'set_type': 'core', 'card_count': 730, 'printed_size': 271, 'digital': false},
        {'code': 'tfdn', 'name': 'Foundations Tokens', 'released_at': '2024-11-15', 'set_type': 'token', 'card_count': 50, 'digital': false},
      ]);
      expect(sets.single.code, 'FDN');

      final cards = MagicSource.parseCards([
        {
          'id': 'abc',
          'name': 'Sire of Seven Deaths',
          'collector_number': '1',
          'rarity': 'mythic',
          'purchase_uris': {'cardmarket': 'https://www.cardmarket.com/x', 'tcgplayer': 'https://www.tcgplayer.com/y'},
        },
        {'id': 'def', 'name': 'Sire of Seven Deaths', 'collector_number': '300', 'rarity': 'mythic'},
      ], sets.single);
      expect(cards.first.code, '0001');
      expect(cards.first.rarity, 'Mythic');
      expect(cards.first.cardmarketUrl, 'https://www.cardmarket.com/x');
      expect(cards.last.variant, 'Variant');
      expect(cards.first.versionKey, cards.last.versionKey);
    });
  });

  test('sets sort by date (unknown dates by list order) and by name', () {
    final sets = [
      CardSet(id: 'a', gameId: 'g', sourceId: 'a', code: 'A', name: 'Zeta', order: 0, released: DateTime(2020)),
      CardSet(id: 'b', gameId: 'g', sourceId: 'b', code: 'B', name: 'alpha', order: 1, released: DateTime(2024)),
      const CardSet(id: 'c', gameId: 'g', sourceId: 'c', code: 'C', name: 'Mid', order: 2),
    ];
    expect(sortSets(sets, SetSort.newest).map((s) => s.id), ['b', 'a', 'c']);
    expect(sortSets(sets, SetSort.oldest).map((s) => s.id), ['c', 'a', 'b']);
    expect(sortSets(sets, SetSort.name).map((s) => s.id), ['b', 'c', 'a']);
  });
}
