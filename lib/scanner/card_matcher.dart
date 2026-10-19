import '../catalog/catalog_repository.dart';
import '../catalog/sources/one_piece_source.dart';
import '../models/catalog.dart';
import 'code_reader.dart';

/// Turns what was read from a photo into matching cards from the catalog.
/// Downloads set lists when needed (they're cached afterwards).
class CardMatcher {
  CardMatcher(this.catalog, {this.startedSets = const {}});

  final CatalogRepository catalog;

  /// Sets the user already collects; searched first when unsure.
  final Set<String> startedSets;

  Future<List<CatalogCard>> find(
    String gameId,
    List<CardHint> hints,
    String ocrText,
  ) async {
    if (hints.isEmpty) return const [];
    final sets = await catalog.sets(gameId);
    final found = <String, CatalogCard>{};

    for (final hint in hints) {
      final matches = switch (hint) {
        CodeHint h => await _byCode(gameId, sets, h.code),
        NumberHint h => await _byNumber(gameId, sets, h),
        SetNumberHint h => await _bySetNumber(sets, h),
      };
      for (final c in matches) {
        found[c.id] = c;
      }
      if (found.isNotEmpty) break;
    }
    return _rankByName(found.values.toList(), ocrText);
  }

  Future<List<CatalogCard>> _byCode(
    String gameId,
    List<CardSet> sets,
    String code,
  ) async {
    if (gameId == 'onepiece') {
      final setCode = onePieceSetCode(code);
      final set = setCode == 'P'
          ? sets.where((s) => s.id == OnePieceSource.promoSetId).firstOrNull
          : sets.where((s) => s.code == setCode).firstOrNull;
      final result = <CatalogCard>[];
      if (set != null) {
        final cards = await catalog.cards(set);
        result.addAll(cards.where((c) => c.code == code));
      }
      // Parallels and reprints can come from other sets too.
      if (result.isNotEmpty) {
        final versions = await catalog.versionsOf(result.first);
        for (final v in versions) {
          if (!result.any((c) => c.id == v.id)) result.add(v);
        }
      }
      return result;
    }
    // Riftbound: "OGN-011" or "OGN-007a".
    final setCode = code.split('-').first;
    final set = sets.where((s) => s.code == setCode).firstOrNull;
    if (set == null) return const [];
    final cards = await catalog.cards(set);
    final base = code.replaceAll(RegExp('[a-z]\$'), '');
    return cards
        .where((c) => c.code == code || c.versionKey == 'riftbound|$base')
        .toList();
  }

  Future<List<CatalogCard>> _byNumber(
    String gameId,
    List<CardSet> sets,
    NumberHint hint,
  ) async {
    List<CardSet> candidates;
    if (gameId == 'lorcana' && hint.setNumber != null) {
      candidates = sets.where((s) => s.sourceId == hint.setNumber).toList();
    } else if (hint.total != null) {
      candidates = sets.where((s) => s.printedTotal == hint.total).toList();
    } else {
      candidates = sets.toList();
    }
    // Sets you already collect first, then the newest.
    candidates = sortSets(candidates, SetSort.newest);
    candidates.sort((a, b) {
      final sa = startedSets.contains(a.id) ? 0 : 1;
      final sb = startedSets.contains(b.id) ? 0 : 1;
      return sa.compareTo(sb);
    });

    final result = <CatalogCard>[];
    // Without a set number we may have to look through several sets; cap
    // it so a scan never downloads half the catalog.
    for (final set in candidates.take(8)) {
      final cards = await catalog.cards(set);
      for (final c in cards) {
        final number = c.code.split('/').first.replaceAll('#', '');
        if (number == hint.number ||
            (int.tryParse(hint.number) != null &&
                c.sortNumber == int.parse(hint.number) &&
                RegExp(r'^\d+$').hasMatch(number))) {
          result.add(c);
        }
      }
    }
    return result;
  }

  Future<List<CatalogCard>> _bySetNumber(
    List<CardSet> sets,
    SetNumberHint hint,
  ) async {
    final set = sets
        .where((s) => s.code.toUpperCase() == hint.setCode.toUpperCase())
        .firstOrNull;
    if (set == null) return const [];
    final cards = await catalog.cards(set);
    return cards
        .where((c) =>
            c.sortNumber == hint.number && RegExp(r'^\d+$').hasMatch(c.code))
        .toList();
  }

  /// Cards whose name appears in the photo come first; if any do, the
  /// others are dropped.
  static List<CatalogCard> _rankByName(List<CatalogCard> cards, String text) {
    final upper = text.toUpperCase();
    final named =
        cards.where((c) => upper.contains(c.name.toUpperCase())).toList();
    return named.isNotEmpty ? named : cards;
  }
}
