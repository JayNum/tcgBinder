import '../../models/catalog.dart';
import 'source.dart';

/// One Piece Card Game via optcgapi.com (no key needed).
///
/// Every printing is its own row: `card_set_id` is the code printed on the
/// card (`OP01-120`), `card_image_id` tells versions apart (`OP01-120_p1`)
/// and `set_id` is the set it's pulled from — reprints from older sets
/// appear in the newer set with their old code.
class OnePieceSource extends CatalogSource {
  OnePieceSource(super.client);

  static const _host = 'optcgapi.com';
  static const promoSetId = 'onepiece-promos';

  @override
  String get gameId => 'onepiece';

  /// English release dates; the API doesn't provide them. Where only the
  /// year was known, the month keeps the release order right.
  static final _released = <String, DateTime>{
    'OP-01': DateTime(2022, 12, 2),
    'OP-02': DateTime(2023, 3, 10),
    'OP-03': DateTime(2023, 6, 30),
    'OP-04': DateTime(2023, 9, 22),
    'OP-05': DateTime(2023, 12, 8),
    'OP-06': DateTime(2024, 3, 15),
    'EB-01': DateTime(2024, 5, 3),
    'OP-07': DateTime(2024, 6, 28),
    'OP-08': DateTime(2024, 9, 13),
    'PRB-01': DateTime(2024, 11, 8),
    'OP-09': DateTime(2024, 12, 13),
    'OP-10': DateTime(2025, 3, 21),
    'EB-02': DateTime(2025, 5, 9),
    'OP-11': DateTime(2025, 6, 6),
    'OP-12': DateTime(2025, 8, 22),
    'PRB-02': DateTime(2025, 10, 3),
    'OP-13': DateTime(2025, 11, 7),
    'EB-03': DateTime(2026, 2, 20),
    'OP-14': DateTime(2026, 3, 13),
    'OP-15': DateTime(2026, 4, 24),
    'OP-16': DateTime(2026, 6, 12),
    'OP-17': DateTime(2026, 9, 4),
  };

  @override
  Future<List<CardSet>> fetchSets() async {
    final boosters = asMapList(await getJson(Uri.https(_host, '/api/allSets/')));
    final decks = asMapList(await getJson(Uri.https(_host, '/api/allDecks/')));

    final sets = <CardSet>[];
    var order = 0;
    for (final s in boosters) {
      final code = s.str('set_id');
      if (code.isEmpty) continue;
      sets.add(CardSet(
        id: 'onepiece-$code',
        gameId: gameId,
        sourceId: code,
        code: code,
        name: s.str('set_name'),
        order: order++,
        released: _released[code],
        kind: code.startsWith('OP') ? SetKind.booster : SetKind.extra,
      ));
    }
    for (final d in decks) {
      final code = d.str('structure_deck_id');
      if (code.isEmpty) continue;
      sets.add(CardSet(
        id: 'onepiece-$code',
        gameId: gameId,
        sourceId: code,
        code: code,
        name: d.str('structure_deck_name'),
        order: order++,
        kind: SetKind.starter,
      ));
    }
    sets.add(CardSet(
      id: promoSetId,
      gameId: gameId,
      sourceId: 'promos',
      code: 'P',
      name: 'Promotion cards',
      order: order++,
      kind: SetKind.promo,
    ));
    return sets;
  }

  @override
  Future<List<CatalogCard>> fetchCards(CardSet set) async {
    final Uri uri;
    switch (set.kind) {
      case SetKind.starter:
        uri = Uri.https(_host, '/api/decks/${set.sourceId}/');
      case SetKind.promo:
        uri = Uri.https(_host, '/api/allPromoCards/');
      case SetKind.booster:
      case SetKind.extra:
        uri = Uri.https(_host, '/api/sets/${set.sourceId}/');
    }
    final rows = asMapList(await getJson(uri, allowNotFound: true));
    return parseCards(rows, set);
  }

  @override
  Future<List<CatalogCard>?> fetchVersions(
    CatalogCard card,
    List<CardSet> sets,
  ) async {
    final rows = asMapList(await getJson(
      Uri.https(_host, '/api/sets/card/${card.code}/'),
      allowNotFound: true,
    ));
    final result = <CatalogCard>[];
    for (final row in rows) {
      final setCode = row.str('set_id');
      final set = sets.where((s) => s.sourceId == setCode).firstOrNull;
      if (set == null) continue;
      result.addAll(parseCards([row], set));
    }
    return result;
  }

  /// Turns API rows into cards of [set]. Public for tests.
  static List<CatalogCard> parseCards(
    List<Map<String, Object?>> rows,
    CardSet set,
  ) {
    final seen = <String>{};
    final cards = <CatalogCard>[];
    final ownPrefix = set.code.replaceAll('-', '');
    for (final row in rows) {
      final code = row.str('card_set_id');
      if (code.isEmpty) continue;
      final imageId = row.strOrNull('card_image_id') ?? code;
      final id = '${set.id}|$imageId';
      if (!seen.add(id)) continue;

      final underscore = imageId.indexOf('_');
      final variant = underscore < 0
          ? null
          : imageId.substring(underscore + 1).toUpperCase();
      final (name, notes) = splitName(row.str('card_name'), code);
      final number = code.contains('-') ? code.split('-').last : code;

      cards.add(CatalogCard(
        id: id,
        setId: set.id,
        gameId: 'onepiece',
        code: code,
        sortNumber: parseSortNumber(number),
        name: name,
        subtitle: notes.isEmpty ? null : notes.join(' · '),
        rarity: row.str('rarity'),
        variant: variant,
        reprint: set.kind != SetKind.promo && !code.startsWith(ownPrefix),
        versionKey: 'onepiece|$code',
        cardmarketQuery: code,
      ));
    }
    cards.sort(compareBinderOrder);
    return cards;
  }

  /// `"Shanks (Parallel) (Manga)"` → `("Shanks", ["Parallel", "Manga"])`.
  /// Drops notes that are just the code or a number, like `(OP01-120)`.
  static (String, List<String>) splitName(String raw, String code) {
    final notes = <String>[];
    var name = raw;
    final trailing = RegExp(r'\s*\(([^()]*)\)\s*$');
    while (true) {
      final match = trailing.firstMatch(name);
      if (match == null) break;
      final note = match.group(1)!.trim();
      name = name.substring(0, match.start);
      final isCodeOrNumber =
          note == code || RegExp(r'^[A-Z0-9-]*\d[A-Z0-9-]*$').hasMatch(note);
      if (!isCodeOrNumber && note.isNotEmpty) notes.insert(0, note);
    }
    name = name.trim();
    return (name.isEmpty ? raw.trim() : name, notes);
  }
}
