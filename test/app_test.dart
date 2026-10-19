import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tcg_binder/app.dart';
import 'package:tcg_binder/catalog/catalog_repository.dart';
import 'package:tcg_binder/catalog/sources/source.dart';
import 'package:tcg_binder/data/collection_store.dart';
import 'package:tcg_binder/data/settings_store.dart';
import 'package:tcg_binder/models/catalog.dart';
import 'package:tcg_binder/services/ads.dart';
import 'package:tcg_binder/services/price_links.dart';

/// A tiny stand-in for a card database, so tests never go online.
class FakeSource extends CatalogSource {
  FakeSource(this.gameId) : super(MockClient((_) async => http.Response('', 404)));

  @override
  final String gameId;

  static final testSet = CardSet(
    id: 'onepiece-OP-16',
    gameId: 'onepiece',
    sourceId: 'OP-16',
    code: 'OP-16',
    name: 'The Time of Battle',
    order: 1,
    released: DateTime(2026, 6, 12),
    printedTotal: 119,
  );

  static const emptySet = CardSet(
    id: 'onepiece-OP-01',
    gameId: 'onepiece',
    sourceId: 'OP-01',
    code: 'OP-01',
    name: 'Romance Dawn',
    order: 0,
  );

  @override
  Future<List<CardSet>> fetchSets() async =>
      gameId == 'onepiece' ? [emptySet, testSet] : const [];

  @override
  Future<List<CatalogCard>> fetchCards(CardSet set) async {
    if (set.id != testSet.id) return const [];
    return const [
      CatalogCard(
        id: 'op16-001',
        setId: 'onepiece-OP-16',
        gameId: 'onepiece',
        code: 'OP16-001',
        sortNumber: 1,
        name: 'Portgas.D.Ace',
        rarity: 'L',
        versionKey: 'onepiece|OP16-001',
        cardmarketQuery: 'OP16-001',
      ),
      CatalogCard(
        id: 'op16-001-p1',
        setId: 'onepiece-OP-16',
        gameId: 'onepiece',
        code: 'OP16-001',
        sortNumber: 1,
        name: 'Portgas.D.Ace',
        rarity: 'L',
        variant: 'P1',
        versionKey: 'onepiece|OP16-001',
        cardmarketQuery: 'OP16-001',
      ),
    ];
  }
}

void main() {
  void usePhoneScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Widget buildApp(CollectionStore store) => TcgBinderApp(
        collection: store,
        settings: SettingsStore(),
        catalog: CatalogRepository(
          sources: {
            for (final id in ['onepiece', 'pokemon', 'magic', 'lorcana', 'riftbound'])
              id: FakeSource(id),
          },
          cacheDir: null,
        ),
        ads: AdsService(enabled: false),
      );

  testWidgets('starts empty, add a card from a binder', (tester) async {
    usePhoneScreen(tester);
    final store = CollectionStore();
    await tester.pumpWidget(buildApp(store));

    expect(find.text('My collection'), findsOneWidget);
    expect(find.text('Not started yet'), findsNWidgets(5));

    // Game → sets (newest first) → binder.
    await tester.tap(find.text('One Piece'));
    await tester.pumpAndSettle();
    expect(find.text('Empty binder'), findsNWidgets(2));
    await tester.tap(find.text('The Time of Battle'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 119 collected'), findsOneWidget);
    expect(find.text('P1'), findsOneWidget);

    // Card → add without photo.
    await tester.tap(find.text('Portgas.D.Ace').first);
    await tester.pumpAndSettle();
    expect(find.text('2 versions of this card'), findsOneWidget);
    await tester.tap(find.text('Add without photo'));
    await tester.pumpAndSettle();

    expect(store.totalCards, 1);
    expect(find.text('YOUR COPY'), findsOneWidget);
    expect(find.text('Change photo'), findsNothing);
    expect(find.text('Add photo'), findsOneWidget);
  });

  testWidgets('sets can be sorted by name', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(buildApp(CollectionStore()));
    await tester.tap(find.text('One Piece'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Newest first'), findsOneWidget);

    await tester.tap(find.byTooltip('Sort sets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name A–Z').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Name A–Z'), findsOneWidget);

    final romance = tester.getTopLeft(find.text('Romance Dawn')).dy;
    final battle = tester.getTopLeft(find.text('The Time of Battle')).dy;
    expect(romance, lessThan(battle));
  });

  testWidgets('sets can be searched by name or code', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(buildApp(CollectionStore()));
    await tester.tap(find.text('One Piece'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'op16');
    await tester.pumpAndSettle();
    expect(find.text('The Time of Battle'), findsOneWidget);
    expect(find.text('Romance Dawn'), findsNothing);

    await tester.enterText(find.byType(TextField), 'romance');
    await tester.pumpAndSettle();
    expect(find.text('Romance Dawn'), findsOneWidget);
    expect(find.text('The Time of Battle'), findsNothing);
  });

  testWidgets('games can be hidden and moved', (tester) async {
    usePhoneScreen(tester);
    final settings = SettingsStore();
    await tester.pumpWidget(TcgBinderApp(
      collection: CollectionStore(),
      settings: settings,
      catalog: CatalogRepository(sources: const {}, cacheDir: null),
      ads: AdsService(enabled: false),
    ));

    // Magic first, Pokémon hidden.
    settings.setGameOrder(['magic', 'onepiece', 'pokemon', 'lorcana', 'riftbound']);
    settings.setGameHidden('pokemon', true);
    await tester.pumpAndSettle();

    expect(find.text('Pokémon'), findsNothing);
    final magic = tester.getTopLeft(find.text('Magic'));
    final onePiece = tester.getTopLeft(find.text('One Piece'));
    expect(magic.dx, lessThan(onePiece.dx));

    await tester.tap(find.text('Arrange'));
    await tester.pumpAndSettle();
    expect(find.text('Pokémon'), findsOneWidget); // listed, switched off
    expect(find.byType(Switch), findsNWidgets(5));
  });

  test('price links search Cardmarket by code', () {
    final uri = PriceLinks.forMarketplace(
      Marketplace.cardmarket,
      game: const Game(
        id: 'onepiece',
        name: 'One Piece',
        cardmarketSlug: 'OnePiece',
        codeStyle: CardCodeStyle.dashed,
        dataSource: 'test',
      ),
      card: const CatalogCard(
        id: 'x',
        setId: 's',
        gameId: 'onepiece',
        code: 'OP16-001',
        sortNumber: 1,
        name: 'Portgas.D.Ace',
        versionKey: 'k',
        cardmarketQuery: 'OP16-001',
      ),
      set: FakeSource.testSet,
    );
    expect(uri.path, '/en/OnePiece/Products/Search');
    expect(uri.queryParameters['searchString'], 'OP16-001');
  });
}
