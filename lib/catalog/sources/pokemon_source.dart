import '../../models/catalog.dart';
import 'source.dart';

/// Pokémon TCG via api.tcgdex.net (open data, MIT licensed, no key).
///
/// The card list of a set only has the number, name and picture; the
/// abilities and attacks are fetched when the user opens a card's text
/// (see CardTextService), so a set downloads with one request.
class PokemonSource extends CatalogSource {
  PokemonSource(super.client);

  static const _host = 'api.tcgdex.net';

  @override
  String get gameId => 'pokemon';

  @override
  Future<List<CardSet>> fetchSets() async {
    final json = await getJson(Uri.https(_host, '/v2/en/sets'));
    return parseSets(asMapList(json));
  }

  /// The list comes oldest first; sets have no date in the short list, so
  /// the position in the list is used for sorting.
  static List<CardSet> parseSets(List<Map<String, Object?>> rows) {
    final sets = <CardSet>[];
    var order = 0;
    for (final s in rows) {
      final id = s.str('id');
      if (id.isEmpty) continue;
      final name = s.str('name');
      sets.add(CardSet(
        id: 'pokemon-$id',
        gameId: 'pokemon',
        sourceId: id,
        code: id.toUpperCase(),
        name: name,
        order: order++,
        released: parseDate(s.strOrNull('releaseDate')),
        kind: name.toLowerCase().contains('promo')
            ? SetKind.promo
            : SetKind.booster,
        printedTotal: (s.obj('cardCount')['official'] as num?)?.toInt(),
      ));
    }
    return sets;
  }

  @override
  Future<List<CatalogCard>> fetchCards(CardSet set) async {
    final json = await getJson(Uri.https(_host, '/v2/en/sets/${set.sourceId}'));
    final rows = json is Map
        ? asMapList(json['cards'])
        : const <Map<String, Object?>>[];
    return parseCards(rows, set);
  }

  static List<CatalogCard> parseCards(
    List<Map<String, Object?>> rows,
    CardSet set,
  ) {
    final cards = <CatalogCard>[];
    for (final c in rows) {
      final id = c.str('id');
      final number = c.str('localId');
      if (id.isEmpty || number.isEmpty) continue;
      final name = c.str('name');
      final numeric = RegExp(r'^\d+$').hasMatch(number);
      final total = set.printedTotal;
      final code = numeric && total != null ? '$number/$total' : number;
      final image = c.strOrNull('image');
      cards.add(CatalogCard(
        id: 'pokemon-$id',
        setId: set.id,
        gameId: 'pokemon',
        code: code,
        sortNumber: parseSortNumber(number),
        name: name,
        versionKey: 'pokemon|$id',
        cardmarketQuery: '$name $number',
        // Only used in the background to recognise artwork, never shown.
        imageUrl: image == null ? null : '$image/low.png',
      ));
    }
    cards.sort(compareBinderOrder);
    return cards;
  }
}
