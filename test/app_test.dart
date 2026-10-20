import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tcg_binder/app.dart';
import 'package:tcg_binder/catalog/card_search.dart';
import 'package:tcg_binder/catalog/catalog_repository.dart';
import 'package:tcg_binder/catalog/sources/source.dart';
import 'package:tcg_binder/data/collection_store.dart';
import 'package:tcg_binder/data/settings_store.dart';
import 'package:tcg_binder/models/catalog.dart';
import 'package:tcg_binder/models/collection.dart';
import 'package:tcg_binder/theme/app_theme.dart';
import 'package:tcg_binder/theme/label_colors.dart';
import 'package:tcg_binder/widgets/favorites_carousel.dart';
import 'package:tcg_binder/widgets/recent_strip.dart';
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

  /// The bar's own "Binders" label is the last one in the tree.
  Future<void> openBinders(WidgetTester tester) async {
    await tester.tap(find.text('Binders').last);
    await tester.pumpAndSettle();
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
      );

  testWidgets('starts empty, add a card from a binder', (tester) async {
    usePhoneScreen(tester);
    final store = CollectionStore();
    await tester.pumpWidget(buildApp(store));

    // First tab: no favorites yet.
    expect(find.text('No favorites yet'), findsOneWidget);

    await openBinders(tester);
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

  testWidgets('a heart puts a card on the Favorites tab', (tester) async {
    usePhoneScreen(tester);
    final store = CollectionStore();
    await tester.pumpWidget(buildApp(store));
    await openBinders(tester);
    await tester.tap(find.text('One Piece'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Time of Battle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portgas.D.Ace').first);
    await tester.pumpAndSettle();

    // Not owned yet: no heart.
    expect(find.byTooltip('Add to favorites'), findsNothing);
    await tester.tap(find.text('Add without photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    expect(store.favorites, hasLength(1));
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);

    // The bar is still there inside the card, so Favorites is one tap away.
    await tester.tap(find.text('Favorites').last);
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsNothing);
    expect(find.text('RECENT ADDITIONS'), findsOneWidget);
    expect(find.text('Portgas.D.Ace'), findsWidgets);
  });

  testWidgets('cards can be found by name and by label', (tester) async {
    usePhoneScreen(tester);
    final catalog = CatalogRepository(
      sources: {
        for (final id in ['onepiece', 'pokemon', 'magic', 'lorcana', 'riftbound'])
          id: FakeSource(id),
      },
      cacheDir: null,
    );
    await catalog.sets('onepiece');
    await catalog.cards(FakeSource.testSet);
    final store = CollectionStore()
      ..addCopy((await catalog.cards(FakeSource.testSet)).first)
      ..addLabel('op16-001', 'Trade');

    await tester.pumpWidget(TcgBinderApp(
      collection: store,
      settings: SettingsStore(),
      catalog: catalog,
    ));
    await openBinders(tester);
    await tester.tap(find.byIcon(CupertinoIcons.search));
    await tester.pumpAndSettle();

    // Search the cards themselves, from the search button in Binders.
    await tester.enterText(find.byType(CupertinoSearchTextField), 'ace');
    await tester.pumpAndSettle();
    expect(find.text('2 cards'.toUpperCase()), findsOneWidget);
    expect(find.textContaining('Trade'), findsWidgets);

    // Show only cards with the label.
    await tester.enterText(find.byType(CupertinoSearchTextField), '');
    await tester.tap(find.text('Trade').first);
    await tester.pumpAndSettle();
    expect(find.text('1 card'.toUpperCase()), findsOneWidget);
    expect(find.text('Portgas.D.Ace'), findsOneWidget);
  });

  test('search ranks owned cards first and understands codes', () async {
    final catalog = CatalogRepository(
      sources: {'onepiece': FakeSource('onepiece')},
      cacheDir: null,
    );
    await catalog.sets('onepiece');
    final cards = await catalog.cards(FakeSource.testSet);
    final store = CollectionStore()..addCopy(cards[1]);

    final byCode = searchCards(catalog, store, query: 'op16 001');
    expect(byCode, hasLength(2));
    expect(byCode.first.card.id, 'op16-001-p1'); // owned first
    expect(searchCards(catalog, store, query: 'OP16-001'), hasLength(2));
    expect(searchCards(catalog, store, query: 'zoro'), isEmpty);
    expect(searchCards(catalog, store, query: 'ace', gameId: 'pokemon'), isEmpty);

    store.addLabel('op16-001-p1', 'Deck');
    store.addLabel('op16-001-p1', 'deck'); // same label, other case
    expect(store.allLabels, ['Deck']);
    expect(
      searchCards(catalog, store, labels: {'Deck'}).map((h) => h.card.id),
      ['op16-001-p1'],
    );
    expect(searchCards(catalog, store, favoritesOnly: true), isEmpty);
    store.toggleFavorite('op16-001-p1');
    expect(searchCards(catalog, store, favoritesOnly: true), hasLength(1));
  });

  testWidgets('sets can be sorted by name', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(buildApp(CollectionStore()));
    await openBinders(tester);
    await tester.tap(find.text('One Piece'));
    await tester.pumpAndSettle();
    expect(find.textContaining('NEWEST FIRST'), findsOneWidget);

    await tester.tap(find.byTooltip('Sort sets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name A–Z'));
    await tester.pumpAndSettle();
    expect(find.textContaining('NAME A–Z'), findsOneWidget);

    final romance = tester.getTopLeft(find.text('Romance Dawn')).dy;
    final battle = tester.getTopLeft(find.text('The Time of Battle')).dy;
    expect(romance, lessThan(battle));
  });

  testWidgets('sets can be searched by name or code', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(buildApp(CollectionStore()));
    await openBinders(tester);
    await tester.tap(find.text('One Piece'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(CupertinoSearchTextField), 'op16');
    await tester.pumpAndSettle();
    expect(find.text('The Time of Battle'), findsOneWidget);
    expect(find.text('Romance Dawn'), findsNothing);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'romance');
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
    ));

    // Magic first, Pokémon hidden.
    settings.setGameOrder(['magic', 'onepiece', 'pokemon', 'lorcana', 'riftbound']);
    settings.setGameHidden('pokemon', true);
    await tester.pumpAndSettle();
    await openBinders(tester);

    expect(find.text('Pokémon'), findsNothing);
    final magic = tester.getTopLeft(find.text('Magic'));
    final onePiece = tester.getTopLeft(find.text('One Piece'));
    expect(magic.dx, lessThan(onePiece.dx));

    await tester.tap(find.text('Arrange'));
    await tester.pumpAndSettle();
    expect(find.text('Pokémon'), findsOneWidget); // listed, switched off
    expect(find.byType(Switch), findsNWidgets(5));
  });

  testWidgets('Settings offers the Pro upgrade', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(buildApp(CollectionStore()));
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Upgrade to Pro'), findsOneWidget);
    await tester.tap(find.text('Upgrade to Pro'));
    await tester.pumpAndSettle();
    expect(find.text('Card text in every language'), findsOneWidget);
    expect(find.text('Recognise by artwork', skipOffstage: false), findsOneWidget);
    expect(find.text('€2.99', skipOffstage: false), findsOneWidget);
    expect(find.text('€29.99', skipOffstage: false), findsOneWidget);
  });

  testWidgets('recent strip only scrolls and loops with more than 5 cards',
      (tester) async {
    usePhoneScreen(tester);
    FavoriteItem item(int i) => FavoriteItem(
          entry: CollectionEntry(
            cardId: 'c$i',
            setId: 's',
            gameId: 'onepiece',
            addedAt: DateTime(2026, 1, i + 1),
          ),
        );
    Future<void> show(int count) => tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: RecentStrip(
              items: [for (var i = 0; i < count; i++) item(i)],
              onOpen: (_) {},
            ),
          ),
        ));

    await show(5);
    expect(find.byType(ListView), findsNothing); // fixed row

    await show(7);
    expect(find.byType(ListView), findsOneWidget);
    // Drag far in both directions: it never runs out of cards.
    await tester.drag(find.byType(ListView), const Offset(-3000, 0));
    await tester.pump();
    expect(find.text('Saved card'), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(6000, 0));
    await tester.pump();
    expect(find.text('Saved card'), findsWidgets);
  });

  test('recent additions: newest first, at most 10', () {
    final store = CollectionStore();
    for (var i = 0; i < 12; i++) {
      store.update(CollectionEntry(
        cardId: 'c$i',
        setId: 's',
        gameId: 'onepiece',
        addedAt: DateTime(2026, 1, i + 1),
      ));
    }
    final recent = store.recentAdditions();
    expect(recent, hasLength(10));
    expect(recent.first.cardId, 'c11');
    expect(recent.last.cardId, 'c2');
  });

  test('labels have colours that can be changed', () {
    final settings = SettingsStore();
    expect(settings.labelColor('Trade'), defaultLabelColor('Trade'));
    expect(settings.labelColor('trade'), settings.labelColor('Trade'));
    settings.setLabelColor('Trade', labelPalette[3]);
    expect(settings.labelColor('trade'), labelPalette[3]);

    final store = CollectionStore()
      ..update(CollectionEntry(
        cardId: 'a',
        setId: 's',
        gameId: 'onepiece',
        addedAt: DateTime(2026),
        labels: const ['Trade', 'Deck'],
      ));
    store.deleteLabel('Trade');
    expect(store.allLabels, ['Deck']);
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
