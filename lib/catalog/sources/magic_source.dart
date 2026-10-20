import '../../models/catalog.dart';
import 'source.dart';

/// Magic: The Gathering via api.scryfall.com (no key needed).
class MagicSource extends CatalogSource {
  MagicSource(super.client);

  static const _host = 'api.scryfall.com';

  /// Paper set types that make sense as binders.
  static const _boosterTypes = {'core', 'expansion'};
  static const _extraTypes = {
    'masters',
    'draft_innovation',
    'commander',
    'funny',
    'starter',
    'duel_deck',
    'from_the_vault',
    'premium_deck',
    'spellbook',
  };

  @override
  String get gameId => 'magic';

  @override
  Future<List<CardSet>> fetchSets() async {
    final json = await getJson(Uri.https(_host, '/sets'));
    final rows = json is Map ? asMapList(json['data']) : const <Map<String, Object?>>[];
    return parseSets(rows);
  }

  static List<CardSet> parseSets(List<Map<String, Object?>> rows) {
    final sets = <CardSet>[];
    var order = 0;
    for (final s in rows) {
      final code = s.str('code');
      final type = s.str('set_type');
      if (code.isEmpty || s['digital'] == true) continue;
      if ((s['card_count'] as num? ?? 0) == 0) continue;
      final SetKind kind;
      if (_boosterTypes.contains(type)) {
        kind = SetKind.booster;
      } else if (_extraTypes.contains(type)) {
        kind = SetKind.extra;
      } else if (type == 'promo') {
        kind = SetKind.promo;
      } else {
        continue; // tokens, memorabilia, alchemy, …
      }
      sets.add(CardSet(
        id: 'magic-$code',
        gameId: 'magic',
        sourceId: code,
        code: code.toUpperCase(),
        name: s.str('name'),
        order: order++,
        released: parseDate(s.strOrNull('released_at')),
        kind: kind,
        printedTotal: (s['printed_size'] as num?)?.toInt(),
      ));
    }
    return sets;
  }

  @override
  Future<List<CatalogCard>> fetchCards(CardSet set) async {
    final rows = <Map<String, Object?>>[];
    Uri? next = Uri.https(_host, '/cards/search', {
      'q': 'e:${set.sourceId}',
      'unique': 'prints',
      'order': 'set',
    });
    while (next != null) {
      final json = await getJson(next, allowNotFound: true);
      if (json is! Map) break;
      rows.addAll(asMapList(json['data']));
      final more = json['has_more'] == true;
      final nextPage = json['next_page'];
      next = more && nextPage is String ? Uri.parse(nextPage) : null;
      // Scryfall asks for a short pause between requests.
      if (next != null) await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    return parseCards(rows, set);
  }

  static String? _image(Map<String, Object?> c) {
    final own = c.obj('image_uris').strOrNull('normal');
    if (own != null) return own;
    final faces = asMapList(c['card_faces']);
    return faces.isEmpty ? null : faces.first.obj('image_uris').strOrNull('normal');
  }

  static String? _oracle(Map<String, Object?> c) {
    final own = c.strOrNull('oracle_text');
    if (own != null) return own;
    final faces = [
      for (final f in asMapList(c['card_faces']))
        if (f.strOrNull('oracle_text') != null)
          '${f.str('name')}\n${f.str('oracle_text')}',
    ];
    return faces.isEmpty ? null : faces.join('\n\n');
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
      final purchase = c.obj('purchase_uris');
      final total = set.printedTotal;
      final numeric = RegExp(r'^\d+$').hasMatch(number);
      cards.add(CatalogCard(
        id: 'magic-$id',
        setId: set.id,
        gameId: 'magic',
        code: numeric ? number.padLeft(4, '0') : number,
        sortNumber: parseSortNumber(number),
        name: name,
        rarity: titleCase(c.str('rarity')),
        // Numbers above the set size are showcase / borderless versions.
        variant: numeric && total != null && int.parse(number) > total
            ? 'Variant'
            : null,
        versionKey: 'magic|${name.toLowerCase()}',
        cardmarketQuery: name,
        cardmarketUrl: purchase.strOrNull('cardmarket'),
        tcgplayerUrl: purchase.strOrNull('tcgplayer'),
        imageUrl: _image(c),
        text: _oracle(c),
      ));
    }
    cards.sort(compareBinderOrder);
    return cards;
  }
}
