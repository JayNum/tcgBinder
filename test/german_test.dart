import 'package:flutter_test/flutter_test.dart';
import 'package:tcg_binder/l10n/german.dart';
import 'package:tcg_binder/l10n/l10n.dart';

void main() {
  tearDown(() => AppLanguage.current = 'en');

  test('language follows the setting, then the phone', () {
    expect(AppLanguage.resolve('system', 'de'), 'de');
    expect(AppLanguage.resolve('system', 'fr'), 'en');
    expect(AppLanguage.resolve('en', 'de'), 'en');
    expect(AppLanguage.resolve('de', 'en'), 'de');
  });

  test('tr only translates in German', () {
    AppLanguage.current = 'en';
    expect(tr('Favorites'), 'Favorites');
    AppLanguage.current = 'de';
    expect(tr('Favorites'), 'Favoriten');
    expect(tr('Something unknown'), 'Something unknown');
  });

  test('texts with numbers and names are translated too', () {
    expect(translateToGerman('1 card'), '1 Karte');
    expect(translateToGerman('12 cards · 2 binders started'),
        '12 Karten · 2 Binder angelegt');
    expect(translateToGerman('Page 2 of 5'), 'Seite 2 von 5');
    expect(translateToGerman('Delete “Trade”?'), '„Trade“ löschen?');
    expect(translateToGerman('3 sets · Newest first'), '3 Sets · Neueste zuerst');
    expect(translateToGerman('Added Elsa to Frozen'), 'Elsa zu Frozen hinzugefügt');
  });
}
