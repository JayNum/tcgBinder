import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../models/catalog.dart';
import '../models/collection.dart';

/// The user's collection, saved as a file on the phone. Nothing is sent
/// anywhere.
class CollectionStore extends ChangeNotifier {
  CollectionStore({this.file, this.photoDir});

  /// Where the collection is saved; null keeps it in memory (tests).
  final File? file;

  /// Where card photos are kept.
  final Directory? photoDir;

  final Map<String, CollectionEntry> _entries = {};

  Future<void> load() async {
    final f = file;
    if (f == null || !f.existsSync()) return;
    try {
      final json = jsonDecode(await f.readAsString());
      if (json is Map && json['entries'] is List) {
        for (final item in json['entries'] as List) {
          if (item is! Map) continue;
          final entry = CollectionEntry.fromJson(item.cast<String, Object?>());
          _entries[entry.cardId] = entry;
        }
      }
    } on Object catch (e) {
      debugPrint('Could not read the collection: $e');
    }
    notifyListeners();
  }

  Iterable<CollectionEntry> get entries => _entries.values;

  CollectionEntry? entryFor(String cardId) => _entries[cardId];

  bool owns(String cardId) => _entries.containsKey(cardId);

  /// Physical cards, counting copies.
  int get totalCards => _entries.values.fold(0, (sum, e) => sum + e.quantity);

  int copiesInGame(String gameId) => _entries.values
      .where((e) => e.gameId == gameId)
      .fold(0, (sum, e) => sum + e.quantity);

  /// Binders (sets) with at least one card, optionally for one game.
  Set<String> startedSets({String? gameId}) => {
        for (final e in _entries.values)
          if (gameId == null || e.gameId == gameId) e.setId,
      };

  /// How many different cards of [cards] the user owns.
  int ownedIn(Iterable<CatalogCard> cards) =>
      cards.where((c) => _entries.containsKey(c.id)).length;

  /// Cards with a heart, newest first.
  List<CollectionEntry> get favorites => [
        for (final e in _entries.values)
          if (e.favorite) e,
      ]..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  /// Every label the user has used, A–Z.
  List<String> get allLabels {
    final labels = <String>{for (final e in _entries.values) ...e.labels};
    return labels.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void toggleFavorite(String cardId) {
    final e = _entries[cardId];
    if (e == null) return;
    update(e.copyWith(favorite: !e.favorite));
  }

  /// Adds [label] to a card; labels are matched ignoring case so "trade"
  /// and "Trade" stay one label.
  void addLabel(String cardId, String label) {
    final e = _entries[cardId];
    final clean = label.trim();
    if (e == null || clean.isEmpty) return;
    final existing = allLabels.firstWhere(
      (l) => l.toLowerCase() == clean.toLowerCase(),
      orElse: () => clean,
    );
    if (e.labels.contains(existing)) return;
    update(e.copyWith(labels: [...e.labels, existing]));
  }

  void removeLabel(String cardId, String label) {
    final e = _entries[cardId];
    if (e == null) return;
    update(e.copyWith(labels: e.labels.where((l) => l != label).toList()));
  }

  /// Takes [label] off every card.
  void deleteLabel(String label) {
    for (final e in _entries.values.toList()) {
      if (e.labels.contains(label)) {
        _entries[e.cardId] =
            e.copyWith(labels: e.labels.where((l) => l != label).toList());
      }
    }
    _changed();
  }

  /// The newest cards added to the collection, newest first.
  List<CollectionEntry> recentAdditions({int limit = 10}) {
    final all = _entries.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return all.take(limit).toList();
  }

  /// Adds one copy of [card]; keeps the existing photo unless [photoPath]
  /// is given.
  void addCopy(CatalogCard card, {String? photoPath}) {
    final existing = _entries[card.id];
    if (existing == null) {
      _entries[card.id] = CollectionEntry(
        cardId: card.id,
        setId: card.setId,
        gameId: card.gameId,
        addedAt: DateTime.now(),
        photoPath: photoPath,
      );
    } else {
      _entries[card.id] = existing.copyWith(
        quantity: existing.quantity + 1,
        photoPath: photoPath ?? existing.photoPath,
      );
    }
    _changed();
  }

  void update(CollectionEntry entry) {
    _entries[entry.cardId] = entry;
    _changed();
  }

  /// Sets a new photo and deletes the old file.
  void setPhoto(String cardId, String photoPath) {
    final existing = _entries[cardId];
    if (existing == null) return;
    final old = existing.photoPath;
    _entries[cardId] = existing.copyWith(photoPath: photoPath);
    if (old != null && old != photoPath) _deleteFile(old);
    _changed();
  }

  void remove(String cardId) {
    final removed = _entries.remove(cardId);
    final photo = removed?.photoPath;
    if (photo != null) _deleteFile(photo);
    _changed();
  }

  /// A new, unique path for a card photo.
  String newPhotoPath() {
    final dir = photoDir ?? Directory.systemTemp;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '${dir.path}${Platform.pathSeparator}card_$stamp.jpg';
  }

  void _deleteFile(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } on Object catch (e) {
      debugPrint('Could not delete $path: $e');
    }
  }

  Future<void> _saving = Future.value();

  void _changed() {
    notifyListeners();
    final f = file;
    if (f == null) return;
    final json = jsonEncode({
      'version': 1,
      'entries': _entries.values.map((e) => e.toJson()).toList(),
    });
    // Write one save after the other, to a temp file first, so a crash
    // never leaves a half-written collection.
    _saving = _saving.then((_) async {
      try {
        await f.parent.create(recursive: true);
        final tmp = File('${f.path}.tmp');
        await tmp.writeAsString(json, flush: true);
        await tmp.rename(f.path);
      } on Object catch (e) {
        debugPrint('Could not save the collection: $e');
      }
    });
  }
}

/// Makes the store available to every screen below it.
class CollectionScope extends InheritedNotifier<CollectionStore> {
  const CollectionScope({
    super.key,
    required CollectionStore store,
    required super.child,
  }) : super(notifier: store);

  static CollectionStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CollectionScope>();
    assert(scope != null, 'No CollectionScope above this widget');
    return scope!.notifier!;
  }
}
