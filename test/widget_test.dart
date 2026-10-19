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

  testWidgets('shelf opens the binder and a card', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(TcgBinderApp(store: CollectionStore.demo()));

    expect(find.text('My binders'), findsOneWidget);
    await tester.tap(find.text('Base Set'));
    await tester.pumpAndSettle();

    expect(find.text('004/102'), findsOneWidget);
    final charizard = find.text('Charizard');
    await tester.ensureVisible(charizard);
    await tester.tap(charizard);
    await tester.pumpAndSettle();

    expect(find.text('YOUR COPY'), findsOneWidget);
    expect(find.text('Near Mint'), findsOneWidget);
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
