import '../../models/catalog.dart';
import 'source.dart';

/// Disney Lorcana via api.lorcast.com (no key needed).
class LorcanaSource extends CatalogSource {
  LorcanaSource(super.client);

  static const _host = 'api.lorcast.com';

  /// Main sets print `1/204`.
  static const _mainSetSize = 204;

  @override
  String get gameId => 'lorcana';

  @override
  Future<List<CardSet>> fetchSets() async {
    final json = await getJson(Uri.https(_host, '/v0/sets'));
    final rows = json is List
        ? asMapList(json)
        : json is Map
            ? asMapList(json['results'] ?? json['data'])
            : const <Map<String, Object?>>[];
    return parseSets(rows);
  }

  static List<CardSet> parseSets(List<Map<String, Object?>> rows) {
    final sets = <CardSet>[];
    var order = 0;
    for (final s in rows) {
      final code = s.str('code');
      if (code.isEmpty) continue;
      final numbered = RegExp(r'^\d+$').hasMatch(code);
      final name = s.str('name');
      final SetKind kind;
      if (numbered) {
        kind = SetKind.booster;
      } else if (name.toLowerCase().contains('promo') ||
          name.toLowerCase().contains('challenge')) {
        kind = SetKind.promo;
      } else {
        kind = SetKind.extra;
      }
      sets.add(CardSet(
        id: 'lorcana-$code',
        gameId: 'lorcana',
        sourceId: code,
        code: numbered ? 'Set $code' : code,
        name: name,
        order: order++,
        released: parseDate(s.strOrNull('released_at')),
        kind: kind,
        printedTotal: numbered ? _mainSetSize : null,
      ));
    }
    return sets;
  }

  @override
  Future<List<CatalogCard>> fetchCards(CardSet set) async {
    final json = await getJson(
      Uri.https(_host, '/v0/sets/${set.sourceId}/cards'),
      allowNotFound: true,
    );
    final rows = json is List
        ? asMapList(json)
        : json is Map
            ? asMapList(json['results'] ?? json['data'])
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
      final number = c.str('collector_number');
      if (id.isEmpty || number.isEmpty) continue;
      final name = c.str('name');
      final version = c.strOrNull('version');
      final total = set.printedTotal;
      final sortNumber = parseSortNumber(number);
      final tcgplayerId = c.strOrNull('tcgplayer_id');
      final tcgplayerUrl = c.obj('purchase_uris').strOrNull('tcgplayer') ??
          (tcgplayerId == null
              ? null
              : 'https://www.tcgplayer.com/product/$tcgplayerId');
      final fullName = version == null ? name : '$name - $version';
      cards.add(CatalogCard(
        id: 'lorcana-$id',
        setId: set.id,
        gameId: 'lorcana',
        code: total == null ? '#$number' : '$number/$total',
        sortNumber: sortNumber,
        name: name,
        subtitle: version,
        rarity: titleCase(c.str('rarity')),
        // Enchanted and other special cards are numbered above the set size.
        variant: total != null && sortNumber > total ? 'Special' : null,
        versionKey: 'lorcana|${fullName.toLowerCase()}',
        cardmarketQuery: version == null ? name : '$name $version',
        tcgplayerUrl: tcgplayerUrl,
      ));
    }
    cards.sort(compareBinderOrder);
    return cards;
  }
}
