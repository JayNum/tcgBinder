import 'dart:ui' show Color;

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
}

enum Edition {
  firstEdition('1st Edition'),
  shadowless('Shadowless'),
  unlimited('Unlimited');

  const Edition(this.label);
  final String label;
}

/// One card the user owns. Stored only on the device.
class CollectionEntry {
  const CollectionEntry({
    required this.cardId,
    this.quantity = 1,
    this.condition = CardCondition.nearMint,
    this.edition = Edition.unlimited,
    this.language = 'English',
    this.photoPath,
    this.demoColor,
  });

  final String cardId;
  final int quantity;
  final CardCondition condition;
  final Edition edition;
  final String language;

  /// Path to the user's own scan on the device; null if added without photo.
  final String? photoPath;

  /// Stand-in for a photo until scanning is built. Remove later.
  final Color? demoColor;

  bool get hasPhoto => photoPath != null || demoColor != null;

  CollectionEntry copyWith({
    int? quantity,
    CardCondition? condition,
    Edition? edition,
    String? language,
    String? photoPath,
  }) {
    return CollectionEntry(
      cardId: cardId,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      edition: edition ?? this.edition,
      language: language ?? this.language,
      photoPath: photoPath ?? this.photoPath,
      demoColor: demoColor,
    );
  }
}
