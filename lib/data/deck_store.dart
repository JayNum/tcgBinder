import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../models/catalog.dart';

/// One card in a deck: a snapshot of the catalog card (so the deck still
/// shows when the card lists are cleared) and how many copies the deck uses.
class DeckEntry {
  const DeckEntry({required this.card, required this.quantity});

  final CatalogCard card;
  final int quantity;

  DeckEntry withQuantity(int q) => DeckEntry(card: card, quantity: q);

  Map<String, Object?> toJson() => {'card': card.toJson(), 'quantity': quantity};

  static DeckEntry? fromJson(Map<String, Object?> json) {
    final card = json['card'];
    if (card is! Map) return null;
    try {
      return DeckEntry(
        card: CatalogCard.fromJson(card.cast<String, Object?>()),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
    } on Object {
      return null;
    }
  }
}

class Deck {
  Deck({
    required this.id,
    required this.gameId,
    required this.name,
    required this.createdAt,
    List<DeckEntry>? entries,
  }) : entries = entries ?? [];

  final String id;
  final String gameId;
  String name;
  final DateTime createdAt;
  final List<DeckEntry> entries;

  int get totalCards => entries.fold(0, (sum, e) => sum + e.quantity);

  Map<String, Object?> toJson() => {
        'id': id,
        'gameId': gameId,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'entries': [for (final e in entries) e.toJson()],
      };

  static Deck? fromJson(Map<String, Object?> json) {
    final id = json['id'], gameId = json['gameId'], name = json['name'];
    if (id is! String || gameId is! String || name is! String) return null;
    final raw = json['entries'];
    final entries = <DeckEntry>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is! Map) continue;
        final entry = DeckEntry.fromJson(e.cast<String, Object?>());
        if (entry != null) entries.add(entry);
      }
    }
    return Deck(
      id: id,
      gameId: gameId,
      name: name,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      entries: entries,
    );
  }
}

/// The user's decks, saved as a file on the phone.
class DeckStore extends ChangeNotifier {
  DeckStore({this.file});

  /// Free users can build this many decks per game; Pro has no limit.
  static const freeDecksPerGame = 1;

  final File? file;
  final List<Deck> _decks = [];

  Future<void> load() async {
    final f = file;
    if (f == null || !f.existsSync()) return;
    try {
      final json = jsonDecode(await f.readAsString());
      if (json is Map && json['decks'] is List) {
        for (final d in json['decks'] as List) {
          if (d is! Map) continue;
          final deck = Deck.fromJson(d.cast<String, Object?>());
          if (deck != null) _decks.add(deck);
        }
      }
    } on Object catch (e) {
      debugPrint('Could not read the decks: $e');
    }
    notifyListeners();
  }

  List<Deck> get decks => List.unmodifiable(_decks);

  List<Deck> decksFor(String gameId) => [
        for (final d in _decks)
          if (d.gameId == gameId) d,
      ];

  Deck? byId(String id) {
    for (final d in _decks) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Whether a new deck for [gameId] is allowed.
  bool canCreate(String gameId, {required bool isPro}) =>
      isPro || decksFor(gameId).length < freeDecksPerGame;

  Deck create(String gameId, String name) {
    final now = DateTime.now();
    final deck = Deck(
      id: '${now.microsecondsSinceEpoch}',
      gameId: gameId,
      name: name.trim().isEmpty ? 'New deck' : name.trim(),
      createdAt: now,
    );
    _decks.add(deck);
    _changed();
    return deck;
  }

  void rename(String deckId, String name) {
    final deck = byId(deckId);
    if (deck == null || name.trim().isEmpty) return;
    deck.name = name.trim();
    _changed();
  }

  void delete(String deckId) {
    _decks.removeWhere((d) => d.id == deckId);
    _changed();
  }

  /// Adds one copy of [card]; returns the new quantity.
  int add(String deckId, CatalogCard card) {
    final deck = byId(deckId);
    if (deck == null) return 0;
    final i = deck.entries.indexWhere((e) => e.card.id == card.id);
    int q;
    if (i < 0) {
      deck.entries.add(DeckEntry(card: card, quantity: 1));
      q = 1;
    } else {
      q = deck.entries[i].quantity + 1;
      deck.entries[i] = deck.entries[i].withQuantity(q);
    }
    _changed();
    return q;
  }

  /// Sets the number of copies; 0 removes the card.
  void setQuantity(String deckId, String cardId, int quantity) {
    final deck = byId(deckId);
    if (deck == null) return;
    final i = deck.entries.indexWhere((e) => e.card.id == cardId);
    if (i < 0) return;
    if (quantity <= 0) {
      deck.entries.removeAt(i);
    } else {
      deck.entries[i] = deck.entries[i].withQuantity(quantity);
    }
    _changed();
  }

  int quantityOf(String deckId, String cardId) {
    final deck = byId(deckId);
    if (deck == null) return 0;
    for (final e in deck.entries) {
      if (e.card.id == cardId) return e.quantity;
    }
    return 0;
  }

  void _changed() {
    notifyListeners();
    final f = file;
    if (f == null) return;
    final json = jsonEncode({'decks': [for (final d in _decks) d.toJson()]});
    f.parent
        .create(recursive: true)
        .then((_) => f.writeAsString(json))
        .catchError((Object e) {
      debugPrint('Could not save the decks: $e');
      return f;
    });
  }
}

class DeckScope extends InheritedNotifier<DeckStore> {
  const DeckScope({
    super.key,
    required DeckStore store,
    required super.child,
  }) : super(notifier: store);

  static DeckStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DeckScope>();
    assert(scope != null, 'No DeckScope above this widget');
    return scope!.notifier!;
  }
}
