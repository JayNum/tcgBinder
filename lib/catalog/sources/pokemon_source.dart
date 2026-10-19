import '../../models/catalog.dart';
import 'source.dart';

/// Pokémon TCG via api.pokemontcg.io (no key needed for normal use).
class PokemonSource extends CatalogSource {
  PokemonSource(super.client);

  static const _host = 'api.pokemontcg.io';

  @override
  String get gameId => 'pokemon';

  @override
  Future<List<CardSet>> fetchSets() async {
    final json = await getJson(Uri.https(_host, '/v2/sets', {
      'pageSize': '250',
      'orderBy': 'releaseDate',
    }));
    final rows = json is Map ? asMapList(json['data']) : const <Map<String, Object?>>[];
    return parseSets(rows);
  }

  static List<CardSet> parseSets(List<Map<String, Object?>> rows) {
    final sets = <CardSet>[];
    var order = 0;
    for (final s in rows) {
      final id = s.str('id');
      if (id.isEmpty) continue;
      final name = s.str('name');
      final ptcgo = s.strOrNull('ptcgoCode');
      sets.add(CardSet(
        id: 'pokemon-$id',
        gameId: 'pokemon',
        sourceId: id,
        code: ptcgo ?? id.toUpperCase(),
        name: name,
        order: order++,
        released: parseDate(s.strOrNull('releaseDate')),
        kind: name.toLowerCase().contains('promo')
            ? SetKind.promo
            : SetKind.booster,
        printedTotal: (s['printedTotal'] as num?)?.toInt(),
      ));
    }
    return sets;
  }

  @override
  Future<List<CatalogCard>> fetchCards(CardSet set) async {
    final rows = <Map<String, Object?>>[];
    var page = 1;
    while (true) {
      final json = await getJson(Uri.https(_host, '/v2/cards', {
        'q': 'set.id:${set.sourceId}',
        'pageSize': '250',
        'page': '$page',
        'select': 'id,name,number,rarity,tcgplayer,cardmarket',
      }));
      if (json is! Map) break;
      final data = asMapList(json['data']);
      rows.addAll(data);
      final total = (json['totalCount'] as num?)?.toInt() ?? rows.length;
      if (data.isEmpty || rows.length >= total) break;
      page++;
    }
    return parseCards(rows, set);
  }

  static List<CatalogCard> parseCards(
    List<Map<String, Object?>> rows,
    CardSet set,
  ) {
    final cards = <CatalogCard>[];
    final hasCode = set.code != set.sourceId.toUpperCase();
    for (final c in rows) {
      final id = c.str('id');
      final number = c.str('number');
      if (id.isEmpty || number.isEmpty) continue;
      final name = c.str('name');
      final numeric = RegExp(r'^\d+$').hasMatch(number);
      final total = set.printedTotal;
      final code = numeric && total != null ? '$number/$total' : number;
      cards.add(CatalogCard(
        id: 'pokemon-$id',
        setId: set.id,
        gameId: 'pokemon',
        code: code,
        sortNumber: parseSortNumber(number),
        name: name,
        rarity: c.str('rarity'),
        versionKey: 'pokemon|$id',
        // Cardmarket names Pokémon cards like "Charizard (BS 4)".
        cardmarketQuery: hasCode ? '$name ${set.code} $number' : name,
        cardmarketUrl: c.obj('cardmarket').strOrNull('url'),
        tcgplayerUrl: c.obj('tcgplayer').strOrNull('url'),
      ));
    }
    cards.sort(compareBinderOrder);
    return cards;
  }
}
