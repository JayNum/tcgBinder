import 'package:flutter/material.dart';

import 'data/collection_store.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

class TcgBinderApp extends StatefulWidget {
  const TcgBinderApp({super.key, this.store});

  /// Injected in tests; the app creates the demo collection otherwise.
  final CollectionStore? store;

  @override
  State<TcgBinderApp> createState() => _TcgBinderAppState();
}

class _TcgBinderAppState extends State<TcgBinderApp> {
  late final CollectionStore _store = widget.store ?? CollectionStore.demo();

  @override
  void dispose() {
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CollectionScope(
      store: _store,
      child: MaterialApp(
        title: 'TCG Binder',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}
