import 'package:flutter_test/flutter_test.dart';
import 'package:tcg_binder/scanner/code_reader.dart';

void main() {
  group('One Piece', () {
    test('reads the card code', () {
      final hints = readCardHints('onepiece', 'Portgas.D.Ace\nOP16-001 L\nLEADER');
      expect(hints, [const CodeHint('OP16-001')]);
    });

    test('fixes letters OCR mistakes for digits', () {
      final hints = readCardHints('onepiece', 'opI6-0O1');
      expect(hints, [const CodeHint('OP16-001')]);
    });

    test('reads extra booster, premium booster, starter and promo codes', () {
      expect(readCardHints('onepiece', 'EB01-012'), [const CodeHint('EB01-012')]);
      expect(readCardHints('onepiece', 'PRB01-005'), [const CodeHint('PRB01-005')]);
      expect(readCardHints('onepiece', 'ST01-001'), [const CodeHint('ST01-001')]);
      expect(readCardHints('onepiece', 'P-001'), [const CodeHint('P-001')]);
    });

    test('maps card codes to set codes', () {
      expect(onePieceSetCode('OP16-001'), 'OP-16');
      expect(onePieceSetCode('PRB01-005'), 'PRB-01');
      expect(onePieceSetCode('ST01-001'), 'ST-01');
      expect(onePieceSetCode('P-001'), 'P');
    });
  });

  group('Riftbound', () {
    test('reads set and number', () {
      final hints = readCardHints('riftbound', 'Pouty Poro\nOGN • 013/298');
      expect(hints, [const CodeHint('OGN-013')]);
    });

    test('keeps the letter of alt arts', () {
      final hints = readCardHints('riftbound', 'OGN · 007a/298');
      expect(hints, [const CodeHint('OGN-007a')]);
    });
  });

  group('Pokémon', () {
    test('reads number over total', () {
      final hints = readCardHints('pokemon', 'Charizard\n120 HP\n4/102 ★');
      expect(hints, contains(const NumberHint('4', 102)));
    });

    test('reads gallery numbers', () {
      final hints = readCardHints('pokemon', 'TG01/TG30');
      expect(hints, contains(const NumberHint('TG01', null)));
    });
  });

  group('Lorcana', () {
    test('reads number, total and set number', () {
      final hints = readCardHints('lorcana', 'Ariel\nOn Human Legs\n1/204 • EN • 1');
      expect(hints, [const NumberHint('1', 204, setNumber: '1')]);
    });
  });

  group('Magic', () {
    test('reads collector number and set code', () {
      final hints = readCardHints('magic', 'Sire of Seven Deaths\n0001 M\nFDN • EN');
      expect(hints, contains(const SetNumberHint('FDN', 1)));
    });

    test('nothing readable gives no hints', () {
      expect(readCardHints('magic', 'just some words'), isEmpty);
    });
  });
}
