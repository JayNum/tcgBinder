import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/catalog.dart';
import 'sources/lorcana_source.dart';
import 'sources/magic_source.dart';
import 'sources/one_piece_source.dart';
import 'sources/pokemon_source.dart';
import 'sources/riftbound_source.dart';
import 'sources/source.dart';

/// Gives the app sets and cards. Downloads them from the card databases the
/// first time and keeps a copy on the phone, so binders work offline.
class CatalogRepository extends ChangeNotifier {
  CatalogRepository({
    required Map<String, CatalogSource> sources,
    required this.cacheDir,
  }) : _sources = sources;

  /// The real databases for all five games.
  factory CatalogRepository.live(Directory cacheDir) {
    final client = http.Client();
    final sources = <CatalogSource>[
      OnePieceSource(client),
      PokemonSource(client),
      MagicSource(client),
      LorcanaSource(client),
      RiftboundSource(client),
    ];
    return CatalogRepository(
      sources: {for (final s in sources) s.gameId: s},
      cacheDir: cacheDir,
    );
  }

  final Map<String, CatalogSource> _sources;

  /// Folder for the downloaded lists; null keeps everything in memory only.
  final Directory? cacheDir;

  /// Set lists are refreshed when older than this.
  static const setListMaxAge = Duration(days: 3);

  /// Bump when the way lists are read changes, so old copies are replaced.
  static const cacheVersion = 2;

  final _sets = <String, List<CardSet>>{};
  final _cards = <String, List<CatalogCard>>{};
  final _loadingSets = <String, Future<List<CardSet>>>{};
  final _loadingCards = <String, Future<List<CatalogCard>>>{};

  /// Loads everything already downloaded. Call once at start-up.
  Future<void> loadCache() async {
    final dir = cacheDir;
    if (dir == null || !dir.existsSync()) return;
    for (final file in dir.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      try {
        final json = jsonDecode(await file.readAsString());
        if (json is! Map) continue;
        // Lists saved by an older app version are downloaded again.
        if (json['v'] != cacheVersion) continue;
        final items = asMapList(json['items']);
        if (name.startsWith('sets_')) {
          final sets = items.map(CardSet.fromJson).toList();
          if (sets.isNotEmpty) _sets[sets.first.gameId] = sets;
        } else if (name.startsWith('cards_')) {
          final cards = items.map(CatalogCard.fromJson).toList();
          final setId = json['setId'];
          if (setId is String) _cards[setId] = cards;
        }
      } on Object catch (e) {
        debugPrint('Ignoring broken cache file $name: $e');
      }
    }
    notifyListeners();
  }

  /// Sets already known for [gameId] (may be empty before the first load).
  List<CardSet> cachedSets(String gameId) => _sets[gameId] ?? const [];

  /// Cards already downloaded for [setId], or null.
  List<CatalogCard>? cachedCards(String setId) => _cards[setId];

  /// Every downloaded card list, by set id. Used by card search.
  Map<String, List<CatalogCard>> get allCachedCards =>
      Map.unmodifiable(_cards);

  /// The catalog card behind a collection entry, if its set is downloaded.
  CatalogCard? cardFor(String setId, String cardId) {
    final cards = _cards[setId];
    if (cards == null) return null;
    for (final c in cards) {
      if (c.id == cardId) return c;
    }
    return null;
  }

  CardSet? setById(String setId) {
    for (final sets in _sets.values) {
      for (final s in sets) {
        if (s.id == setId) return s;
      }
    }
    return null;
  }

  /// All sets of a game; downloads the list if it's missing or old.
  Future<List<CardSet>> sets(String gameId, {bool refresh = false}) {
    final cached = _sets[gameId];
    if (!refresh && cached != null && !_isOld('sets_$gameId')) {
      return SynchronousFuture(cached);
    }
    // Block body on purpose: returning the removed future from
    // whenComplete would make it wait for itself.
    return _loadingSets[gameId] ??= _downloadSets(gameId).whenComplete(() {
      _loadingSets.remove(gameId);
    });
  }

  Future<List<CardSet>> _downloadSets(String gameId) async {
    try {
      final sets = await _source(gameId).fetchSets();
      _sets[gameId] = sets;
      await _write('sets_$gameId', {
        'savedAt': DateTime.now().toIso8601String(),
        'items': sets.map((s) => s.toJson()).toList(),
      });
      notifyListeners();
      return sets;
    } on Object {
      // Offline or the database is down: keep using the old list.
      final cached = _sets[gameId];
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// All cards of a set; downloads them the first time.
  Future<List<CatalogCard>> cards(CardSet set, {bool refresh = false}) {
    final cached = _cards[set.id];
    if (!refresh && cached != null) return SynchronousFuture(cached);
    return _loadingCards[set.id] ??= _downloadCards(set).whenComplete(() {
      _loadingCards.remove(set.id);
    });
  }

  Future<List<CatalogCard>> _downloadCards(CardSet set) async {
    final cards = await _source(set.gameId).fetchCards(set);
    _cards[set.id] = cards;
    await _write('cards_${set.id}', {
      'setId': set.id,
      'savedAt': DateTime.now().toIso8601String(),
      'items': cards.map((c) => c.toJson()).toList(),
    });
    notifyListeners();
    return cards;
  }

  /// Every printing of [card] that the app knows about, oldest set first.
  /// For One Piece this asks the database, so versions from sets you
  /// haven't opened yet show up too.
  Future<List<CatalogCard>> versionsOf(CatalogCard card) async {
    final byId = <String, CatalogCard>{};
    for (final cards in _cards.values) {
      for (final c in cards) {
        if (c.versionKey == card.versionKey) byId[c.id] = c;
      }
    }
    byId[card.id] = card;
    final source = _sources[card.gameId];
    if (source != null) {
      try {
        final found = await source.fetchVersions(card, cachedSets(card.gameId));
        for (final c in found ?? const <CatalogCard>[]) {
          byId.putIfAbsent(c.id, () => c);
        }
      } on Object catch (e) {
        debugPrint('Version lookup failed: $e');
      }
    }
    final versions = byId.values.toList();
    versions.sort((a, b) {
      final sa = setById(a.setId), sb = setById(b.setId);
      final da = sa?.released, db = sb?.released;
      if (da != null && db != null && da != db) return da.compareTo(db);
      final byOrder = (sa?.order ?? 0).compareTo(sb?.order ?? 0);
      if (byOrder != 0) return byOrder;
      return (a.variant ?? '').compareTo(b.variant ?? '');
    });
    return versions;
  }

  /// Deletes all downloaded lists (the collection is not touched).
  Future<void> clearCache() async {
    _sets.clear();
    _cards.clear();
    final dir = cacheDir;
    if (dir != null && dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    notifyListeners();
  }

  CatalogSource _source(String gameId) {
    final source = _sources[gameId];
    if (source == null) throw CatalogException('Unknown game $gameId');
    return source;
  }

  final _savedAt = <String, DateTime>{};

  bool _isOld(String key) {
    final saved = _savedAt[key] ?? _readSavedAt(key);
    if (saved == null) return true;
    return DateTime.now().difference(saved) > setListMaxAge;
  }

  DateTime? _readSavedAt(String key) {
    final file = _file(key);
    if (file == null || !file.existsSync()) return null;
    final saved = file.lastModifiedSync();
    _savedAt[key] = saved;
    return saved;
  }

  File? _file(String key) {
    final dir = cacheDir;
    if (dir == null) return null;
    final safe = key.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    return File('${dir.path}${Platform.pathSeparator}$safe.json');
  }

  Future<void> _write(String key, Map<String, Object?> json) async {
    _savedAt[key] = DateTime.now();
    final file = _file(key);
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({...json, 'v': cacheVersion}));
    } on Object catch (e) {
      debugPrint('Could not save $key: $e');
    }
  }
}
