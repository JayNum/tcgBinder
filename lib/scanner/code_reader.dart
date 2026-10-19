/// Finds card numbers in text read from a photo (OCR).
///
/// Each game prints its number differently:
/// - One Piece: `OP16-001`, `EB01-012`, `ST01-001`, `PRB01-…`, promos `P-001`
/// - Riftbound: `OGN • 011/298` (maybe `007a`)
/// - Pokémon: `4/102`, `TG01/TG30`
/// - Lorcana: `1/204 • EN • 1` (number / total • language • set number)
/// - Magic: `0001 M` and `FDN • EN` on the line below
library;

sealed class CardHint {
  const CardHint();
}

/// A full code that identifies the card: `OP16-001`, `OGN-011`.
class CodeHint extends CardHint {
  const CodeHint(this.code);
  final String code;

  @override
  bool operator ==(Object other) => other is CodeHint && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'CodeHint($code)';
}

/// A number over a set total: `4/102`; [setNumber] for Lorcana.
class NumberHint extends CardHint {
  const NumberHint(this.number, this.total, {this.setNumber});
  final String number;
  final int? total;
  final String? setNumber;

  @override
  bool operator ==(Object other) =>
      other is NumberHint &&
      other.number == number &&
      other.total == total &&
      other.setNumber == setNumber;

  @override
  int get hashCode => Object.hash(number, total, setNumber);

  @override
  String toString() => 'NumberHint($number/$total set $setNumber)';
}

/// A set code and collector number: Magic `FDN` + `1`.
class SetNumberHint extends CardHint {
  const SetNumberHint(this.setCode, this.number);
  final String setCode;
  final int number;

  @override
  bool operator ==(Object other) =>
      other is SetNumberHint &&
      other.setCode == setCode &&
      other.number == number;

  @override
  int get hashCode => Object.hash(setCode, number);

  @override
  String toString() => 'SetNumberHint($setCode $number)';
}

/// OCR often mixes up these letters and digits inside numbers.
String _digits(String s) => s
    .replaceAll('O', '0')
    .replaceAll('D', '0')
    .replaceAll('Q', '0')
    .replaceAll('I', '1')
    .replaceAll('L', '1')
    .replaceAll('|', '1')
    .replaceAll('S', '5')
    .replaceAll('B', '8');

const _dot = r'[\s•·*.,\-]*';

List<CardHint> readCardHints(String gameId, String rawText) {
  final text = rawText.toUpperCase();
  final hints = <CardHint>[];
  void add(CardHint h) {
    if (!hints.contains(h)) hints.add(h);
  }

  switch (gameId) {
    case 'onepiece':
      final code = RegExp(
        r'\b(OP|0P|EB|ST|5T|PRB)\s?-?\s?([0-9OILDQ]{2})\s?-\s?([0-9OILDQSB]{3})\b',
      );
      for (final m in code.allMatches(text)) {
        final prefix = m.group(1)!.replaceAll('0P', 'OP').replaceAll('5T', 'ST');
        add(CodeHint('$prefix${_digits(m.group(2)!)}-${_digits(m.group(3)!)}'));
      }
      for (final m in RegExp(r'\bP\s?-\s?([0-9OILDQ]{3})\b').allMatches(text)) {
        add(CodeHint('P-${_digits(m.group(1)!)}'));
      }

    case 'riftbound':
      final code = RegExp(
        '\\b([A-Z]{3})$_dot([0-9OILDQ]{3})([A-Z]?)\\s*/\\s*([0-9OILDQ]{3})',
      );
      for (final m in code.allMatches(text)) {
        final suffix = m.group(3)!.toLowerCase();
        add(CodeHint('${m.group(1)}-${_digits(m.group(2)!)}$suffix'));
      }

    case 'lorcana':
      final full = RegExp(
        '\\b(\\d{1,3})\\s*/\\s*(\\d{2,3})$_dot[A-Z]{2}$_dot(\\d{1,2})\\b',
      );
      for (final m in full.allMatches(text)) {
        add(NumberHint(
          int.parse(m.group(1)!).toString(),
          int.parse(m.group(2)!),
          setNumber: int.parse(m.group(3)!).toString(),
        ));
      }
      if (hints.isEmpty) _addSlashed(text, add);

    case 'pokemon':
      _addSlashed(text, add);
      final special = RegExp(r'\b([A-Z]{1,3}\d{1,3})\s*/\s*[A-Z]{1,3}\d{1,3}\b');
      for (final m in special.allMatches(text)) {
        add(NumberHint(m.group(1)!, null));
      }

    case 'magic':
      final setCodes = <String>[];
      final setLine = RegExp(
        '\\b([A-Z0-9]{3,5})$_dot(EN|DE|FR|IT|ES|PT|JA|JP|KO|RU|ZHS|ZHT|PH)\\b',
      );
      for (final m in setLine.allMatches(text)) {
        final code = m.group(1)!;
        if (!setCodes.contains(code)) setCodes.add(code);
      }
      final numbers = <int>[];
      // Modern: "0001 M"; older: "123/274 R".
      final number = RegExp(r'\b(\d{1,4})(?:\s*/\s*\d{1,4})?\s+[CURMLST]\b');
      for (final m in number.allMatches(text)) {
        final n = int.parse(m.group(1)!);
        if (!numbers.contains(n)) numbers.add(n);
      }
      if (numbers.isEmpty) {
        for (final m in RegExp(r'\b(\d{3,4})\b').allMatches(text)) {
          final n = int.parse(m.group(1)!);
          if (!numbers.contains(n)) numbers.add(n);
        }
      }
      for (final code in setCodes) {
        for (final n in numbers) {
          add(SetNumberHint(code, n));
        }
      }
  }
  return hints;
}

void _addSlashed(String text, void Function(CardHint) add) {
  final slashed = RegExp(r'\b(\d{1,3})\s*/\s*(\d{2,3})\b');
  for (final m in slashed.allMatches(text)) {
    final number = int.parse(m.group(1)!);
    final total = int.parse(m.group(2)!);
    if (total < 10) continue;
    add(NumberHint(number.toString(), total));
  }
}

/// One Piece card code → the set code used by the database:
/// `OP16-001` → `OP-16`, `PRB01-005` → `PRB-01`, `P-001` → `P`.
String? onePieceSetCode(String cardCode) {
  if (cardCode.startsWith('P-')) return 'P';
  final m = RegExp(r'^([A-Z]+)(\d{2})-').firstMatch(cardCode);
  if (m == null) return null;
  return '${m.group(1)}-${m.group(2)}';
}
