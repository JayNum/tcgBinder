import 'package:flutter_test/flutter_test.dart';
import 'package:tcg_binder/data/deck_store.dart';
import 'package:tcg_binder/models/catalog.dart';

CatalogCard card(String id) => CatalogCard(
      id: id,
      setId: 'set',
      gameId: 'magic',
      code: id,
      sortNumber: 1,
      name: 'Card $id',
      versionKey: id,
      cardmarketQuery: 'Card $id',
    );

void main() {
  test('free users get one deck per game, Pro unlimited', () {
    final s = DeckStore();
    expect(s.canCreate('magic', isPro: false), isTrue);
    s.create('magic', 'A');
    expect(s.canCreate('magic', isPro: false), isFalse);
    expect(s.canCreate('pokemon', isPro: false), isTrue);
    expect(s.canCreate('magic', isPro: true), isTrue);
  });

  test('add, change quantity and remove', () {
    final s = DeckStore();
    final d = s.create('magic', 'A');
    s.add(d.id, card('1'));
    expect(s.add(d.id, card('1')), 2);
    s.setQuantity(d.id, '1', 4);
    expect(s.quantityOf(d.id, '1'), 4);
    s.setQuantity(d.id, '1', 0);
    expect(s.byId(d.id)!.entries, isEmpty);
  });
}
