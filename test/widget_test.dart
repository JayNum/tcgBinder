import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcg_binder/app.dart';
import 'package:tcg_binder/data/collection_store.dart';

void main() {
  // Phone-sized screen (390×844 logical pixels).
  void usePhoneScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('home → game → binder → card', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(TcgBinderApp(store: CollectionStore.demo()));

    expect(find.text('My collection'), findsOneWidget);
    expect(find.text('One Piece'), findsOneWidget);
    expect(find.text('Riftbound'), findsOneWidget);

    await tester.tap(find.text('Pokémon'));
    await tester.pumpAndSettle();
    expect(find.text('Team Rocket'), findsOneWidget);

    await tester.tap(find.text('Base Set'));
    await tester.pumpAndSettle();
    expect(find.text('004/102'), findsOneWidget);

    final charizard = find.text('Charizard');
    await tester.ensureVisible(charizard);
    await tester.tap(charizard);
    await tester.pumpAndSettle();

    expect(find.text('YOUR COPY'), findsOneWidget);
    expect(find.text('Near Mint'), findsOneWidget);

    // The banner must stay a banner, not fill the screen.
    final banner = find.text('Ad · banner placeholder');
    expect(tester.getSize(find.ancestor(
      of: banner,
      matching: find.byType(SafeArea),
    ).first).height, lessThan(100));
  });

  testWidgets('sets can be sorted by name', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(TcgBinderApp(store: CollectionStore.demo()));

    await tester.tap(find.text('One Piece'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Newest first'), findsOneWidget);

    await tester.tap(find.byTooltip('Sort sets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name A–Z').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Name A–Z'), findsOneWidget);
    expect(find.text('500 Years in the Future'), findsOneWidget);
  });

  testWidgets('empty binders say so', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(TcgBinderApp(store: CollectionStore.demo()));

    await tester.tap(find.text('Riftbound'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vendetta'));
    await tester.pumpAndSettle();
    expect(find.text('This binder is empty'), findsOneWidget);
  });

  testWidgets('settings tab shows backup options', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(TcgBinderApp(store: CollectionStore.demo()));

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Move to a new phone'), findsOneWidget);
    expect(find.byIcon(Icons.document_scanner_outlined), findsOneWidget);
  });
}
