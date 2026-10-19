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
    return CollectionStore({
      'base1-1': const CollectionEntry(cardId: 'base1-1', demoColor: purple),
      'base1-2': const CollectionEntry(cardId: 'base1-2', demoColor: blue),
      'base1-4': const CollectionEntry(
          cardId: 'base1-4', quantity: 2, demoColor: red),
      'base1-7': const CollectionEntry(cardId: 'base1-7', demoColor: brown),
      'base1-8': const CollectionEntry(cardId: 'base1-8'),
      'base1-9': const CollectionEntry(cardId: 'base1-9', demoColor: grey),
      'base1-10': const CollectionEntry(cardId: 'base1-10', demoColor: purple),
      'base1-15': const CollectionEntry(cardId: 'base1-15', demoColor: green),
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
