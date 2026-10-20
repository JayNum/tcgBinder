/// Card condition on the European (Cardmarket) scale.
enum CardCondition {
  mint('Mint', 'MT'),
  nearMint('Near Mint', 'NM'),
  excellent('Excellent', 'EX'),
  good('Good', 'GD'),
  lightPlayed('Light Played', 'LP'),
  played('Played', 'PL'),
  poor('Poor', 'PO');

  const CardCondition(this.label, this.short);
  final String label;
  final String short;

  static CardCondition byName(String? name) => CardCondition.values
      .firstWhere((c) => c.name == name, orElse: () => nearMint);
}

enum Edition {
  firstEdition('1st Edition'),
  shadowless('Shadowless'),
  unlimited('Unlimited');

  const Edition(this.label);
  final String label;

  static Edition byName(String? name) =>
      Edition.values.firstWhere((e) => e.name == name, orElse: () => unlimited);
}

const cardLanguages = [
  'English',
  'German',
  'French',
  'Italian',
  'Spanish',
  'Portuguese',
  'Japanese',
  'Korean',
  'Chinese',
];

/// One card the user owns. Stored only on the device.
class CollectionEntry {
  const CollectionEntry({
    required this.cardId,
    required this.setId,
    required this.gameId,
    required this.addedAt,
    this.quantity = 1,
    this.condition = CardCondition.nearMint,
    this.edition = Edition.unlimited,
    this.language = 'English',
    this.photoPath,
    this.favorite = false,
    this.labels = const [],
  });

  final String cardId;

  /// Kept with the entry so the home screen can count without the catalog.
  final String setId;
  final String gameId;
  final DateTime addedAt;
  final int quantity;
  final CardCondition condition;
  final Edition edition;
  final String language;

  /// The user's own photo of the card on the device; null if none yet.
  final String? photoPath;

  bool get hasPhoto => photoPath != null;

  /// Shown on the Favorites tab (the heart on the card).
  final bool favorite;

  /// The user's own labels for this card, e.g. "Trade" or "Deck".
  final List<String> labels;

  CollectionEntry copyWith({
    int? quantity,
    CardCondition? condition,
    Edition? edition,
    String? language,
    String? photoPath,
    bool? favorite,
    List<String>? labels,
  }) {
    return CollectionEntry(
      cardId: cardId,
      setId: setId,
      gameId: gameId,
      addedAt: addedAt,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      edition: edition ?? this.edition,
      language: language ?? this.language,
      photoPath: photoPath ?? this.photoPath,
      favorite: favorite ?? this.favorite,
      labels: labels ?? this.labels,
    );
  }

  Map<String, Object?> toJson() => {
        'cardId': cardId,
        'setId': setId,
        'gameId': gameId,
        'addedAt': addedAt.toIso8601String(),
        'quantity': quantity,
        'condition': condition.name,
        'edition': edition.name,
        'language': language,
        'photoPath': photoPath,
        'favorite': favorite,
        'labels': labels,
      };

  factory CollectionEntry.fromJson(Map<String, Object?> json) =>
      CollectionEntry(
        cardId: json['cardId']! as String,
        setId: json['setId']! as String,
        gameId: json['gameId']! as String,
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
            DateTime.now(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        condition: CardCondition.byName(json['condition'] as String?),
        edition: Edition.byName(json['edition'] as String?),
        language: json['language'] as String? ?? 'English',
        photoPath: json['photoPath'] as String?,
        favorite: json['favorite'] as bool? ?? false,
        labels: [
          if (json['labels'] is List)
            for (final l in json['labels']! as List)
              if (l is String && l.trim().isNotEmpty) l.trim(),
        ],
      );
}
