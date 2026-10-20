import 'package:flutter/material.dart';

import 'catalog/catalog_repository.dart';
import 'catalog/catalog_scope.dart';
import 'data/collection_store.dart';
import 'data/deck_store.dart';
import 'data/settings_store.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

class TcgBinderApp extends StatelessWidget {
  const TcgBinderApp({
    super.key,
    required this.collection,
    required this.settings,
    required this.catalog,
    DeckStore? decks,
  }) : decks = decks ?? _noDecks;

  static final DeckStore _noDecks = DeckStore();

  final CollectionStore collection;
  final SettingsStore settings;
  final CatalogRepository catalog;
  final DeckStore decks;

  @override
  Widget build(BuildContext context) {
    return CatalogScope(
        repository: catalog,
        child: SettingsScope(
          store: settings,
          child: CollectionScope(
            store: collection,
            child: DeckScope(
              store: decks,
              child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) {
                final skin = settings.activeSkin;
                return MaterialApp(
                  title: 'Le Binder',
                  debugShowCheckedModeBanner: false,
                  theme: buildTheme(Brightness.light, skin: skin),
                  darkTheme: buildTheme(Brightness.dark, skin: skin),
                  themeMode: ThemeMode.system,
                  home: const HomeShell(),
                );
              },
            ),
            ),
          ),
        ),
      );
  }
}
