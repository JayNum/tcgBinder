import '../../models/catalog.dart';
import 'source.dart';

/// Riftbound via api.riftcodex.com (no key needed).
class RiftboundSource extends CatalogSource {
  RiftboundSource(super.client);

  static const _host = 'api.riftcodex.com';
  static const _promoCodes = {'PR', 'JDG', 'OPP'};

  @override
  String get gameId => 'riftbound';

  @override
  Future<List<CardSet>> fetchSets() async {
    final json = await getJson(Uri.https(_host, '/sets', {'size': '100'}));
    final rows = json is Map
        ? asMapList(json['items'])
        : asMapList(json);
    return parseSets(rows);
  }

  static List<CardSet> parseSets(List<Map<String, Object?>> rows) {
    final sets = <CardSet>[];
    var order = 0;
    for (final s in rows) {
      final code = s.str('set_id').toUpperCase();
      if (code.isEmpty) continue;
      final name = s.str('name');
      final SetKind kind;
      if (_promoCodes.contains(code) || name.toLowerCase().contains('promo')) {
        kind = SetKind.promo;
      } else if (name.contains(':')) {
        kind = SetKind.extra; // e.g. "Origins: Proving Grounds"
      } else {
        kind = SetKind.booster;
      }
      sets.add(CardSet(
        id: 'riftbound-$code',
        gameId: 'riftbound',
        sourceId: code,
        code: code,
        name: name,
        order: order++,
        released: parseDate(s.strOrNull('published_on')),
        kind: kind,
      ));
    }
    return sets;
  }

  @override
  Future<List<CatalogCard>> fetchCards(CardSet set) async {
    const size = 100;
    final rows = <Map<String, Object?>>[];
    var page = 1;
    while (page <= 50) {
      final json = await getJson(Uri.https(_host, '/cards', {
        'set_id': set.sourceId.toLowerCase(),
        'size': '$size',
        'page': '$page',
        'sort': 'collector_number',
        'dir': '1',
      }));
      if (json is! Map) break;
      final items = asMapList(json['items']);
      rows.addAll(items);
      final pages = (json['pages'] as num?)?.toInt();
      if (items.length < size || (pages != null && page >= pages)) break;
      page++;
    }
    return parseCards(rows, set);
  }

  static List<CatalogCard> parseCards(
    List<Map<String, Object?>> rows,
    CardSet set,
  ) {
    final seen = <String>{};
    final cards = <CatalogCard>[];
    for (final c in rows) {
      final id = c.str('id');
      if (id.isEmpty || !seen.add(id)) continue;
      final name = c.str('name');
      final collector = (c['collector_number'] as num?)?.toInt() ?? 0;

      // riftbound_id looks like "ogn-011-298": set, number (maybe "007a"),
      // printed set size.
      final parts = c.str('riftbound_id').split('-');
      final number = parts.length >= 2 && parts[1].isNotEmpty
          ? parts[1]
          : collector.toString().padLeft(3, '0');
      final setCode = parts.length >= 2 && parts[0].isNotEmpty
          ? parts[0].toUpperCase()
          : set.code;
      final code = '$setCode-$number';
      final baseNumber = parseSortNumber(number).toString().padLeft(3, '0');

      final meta = c.obj('metadata');
      final String? variant;
      if (meta['signature'] == true) {
        variant = 'Signature';
      } else if (meta['alternate_art'] == true || number.contains(RegExp('[a-z]'))) {
        variant = 'Alt art';
      } else {
        variant = null;
      }
      final tcgplayerId = c.strOrNull('tcgplayer_id');

      cards.add(CatalogCard(
        id: 'riftbound-$id',
        setId: set.id,
        gameId: 'riftbound',
        code: code,
        sortNumber: collector != 0 ? collector : parseSortNumber(number),
        name: name,
        rarity: c.obj('classification').str('rarity'),
        variant: variant,
        reprint: setCode != set.code,
        versionKey: 'riftbound|$setCode-$baseNumber',
        cardmarketQuery: name,
        tcgplayerUrl: tcgplayerId == null
            ? null
            : 'https://www.tcgplayer.com/product/$tcgplayerId',
        imageUrl: c.obj('media').strOrNull('image_url'),
        text: c.obj('text').strOrNull('plain'),
      ));
    }
    cards.sort(compareBinderOrder);
    return cards;
  }
}
