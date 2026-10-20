import 'package:flutter/material.dart';

import 'catalog/catalog_repository.dart';
import 'catalog/catalog_scope.dart';
import 'data/collection_store.dart';
import 'data/settings_store.dart';
import 'screens/home_shell.dart';
import 'services/ads.dart';
import 'theme/app_theme.dart';

class TcgBinderApp extends StatelessWidget {
  const TcgBinderApp({
    super.key,
    required this.collection,
    required this.settings,
    required this.catalog,
    required this.ads,
  });

  final CollectionStore collection;
  final SettingsStore settings;
  final CatalogRepository catalog;
  final AdsService ads;

  @override
  Widget build(BuildContext context) {
    return AdsScope(
      ads: ads,
      child: CatalogScope(
        repository: catalog,
        child: SettingsScope(
          store: settings,
          child: CollectionScope(
            store: collection,
            child: MaterialApp(
              title: 'Le Binder',
              debugShowCheckedModeBanner: false,
              theme: buildTheme(Brightness.light),
              darkTheme: buildTheme(Brightness.dark),
              themeMode: ThemeMode.system,
              home: const HomeShell(),
            ),
          ),
        ),
      ),
    );
  }
}
