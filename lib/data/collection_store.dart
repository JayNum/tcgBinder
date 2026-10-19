import 'package:flutter/widgets.dart';

import '../models/catalog.dart';
import '../models/collection.dart';

/// Holds the user's collection. In-memory for now; the next step is
/// persisting it in a local SQLite database (Drift) on the device.
class CollectionStore extends ChangeNotifier {
  CollectionStore([Map<String, CollectionEntry>? initial])
      : _entries = {...?initial};

  final Map<String, CollectionEntry> _entries;

  CollectionEntry? entryFor(String cardId) => _entries[cardId];

  bool owns(String cardId) => _entries.containsKey(cardId);

  int get totalCards =>
      _entries.values.fold(0, (sum, e) => sum + e.quantity);

  int ownedIn(Iterable<CatalogCard> cards) =>
      cards.where((c) => _entries.containsKey(c.id)).length;

  void add(String cardId) {
    _entries.putIfAbsent(cardId, () => CollectionEntry(cardId: cardId));
    notifyListeners();
  }

  void update(CollectionEntry entry) {
    _entries[entry.cardId] = entry;
    notifyListeners();
  }

  void remove(String cardId) {
    _entries.remove(cardId);
    notifyListeners();
  }

  /// Sample collection matching the mockups.
  factory CollectionStore.demo() {
    const purple = Color(0xFF8E6BB8);
    const blue = Color(0xFF4C7FC0);
    const red = Color(0xFFD2603A);
    const brown = Color(0xFFA6784A);
    const grey = Color(0xFF8C9198);
    const green = Color(0xFF5E9E6A);
    const yellow = Color(0xFFC9A227);
    const navy = Color(0xFF3B4A7A);

    CollectionEntry e(String id, {Color? color, int quantity = 1}) =>
        CollectionEntry(cardId: id, demoColor: color, quantity: quantity);

    final entries = [
      // Pokémon Base Set
      e('pokemon-base1-1', color: purple),
      e('pokemon-base1-2', color: blue),
      e('pokemon-base1-4', color: red, quantity: 2),
      e('pokemon-base1-7', color: brown),
      e('pokemon-base1-8'),
      e('pokemon-base1-9', color: grey),
      e('pokemon-base1-10', color: purple),
      e('pokemon-base1-15', color: green),
      // One Piece OP16
      e('onepiece-op16-1', color: red),
      e('onepiece-op16-3', color: red),
      e('onepiece-op16-11', color: red, quantity: 3),
      e('onepiece-op16-14', color: red),
      e('onepiece-op16-15', color: red),
      e('onepiece-op16-22', color: green),
      e('onepiece-op16-26'),
      // Magic Foundations
      e('magic-fdn-1', color: grey),
      e('magic-fdn-2', color: yellow),
      e('magic-fdn-9', color: yellow, quantity: 4),
      e('magic-fdn-17', color: yellow),
      // Lorcana The First Chapter
      e('lorcana-1-1', color: yellow),
      e('lorcana-1-12', color: yellow, quantity: 2),
      e('lorcana-1-18', color: yellow),
      e('lorcana-1-21', color: yellow),
      e('lorcana-1-23'),
      // Riftbound Origins
      e('riftbound-ogn-1', color: red),
      e('riftbound-ogn-13', color: navy, quantity: 3),
      e('riftbound-ogn-15', color: red),
      e('riftbound-ogn-25', color: red),
    ];
    return CollectionStore({for (final entry in entries) entry.cardId: entry});
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
