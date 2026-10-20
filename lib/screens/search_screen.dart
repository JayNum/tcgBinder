import 'package:flutter/cupertino.dart' hide Text;
import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../catalog/catalog_scope.dart';
import '../data/collection_store.dart';
import '../theme/app_theme.dart';
import '../widgets/card_search_widgets.dart';

/// The Search tab: find any single card, or show only cards with the labels
/// you choose.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  CardFilters _filters = const CardFilters();

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final downloaded = CatalogScope.of(context).allCachedCards.length;
    final labels = CollectionScope.of(context).allLabels;

    return Scaffold(
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Search'),
            transitionBetweenRoutes: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: CupertinoSearchTextField(
                placeholder: tr('Name, code or set'),
                onChanged: (value) =>
                    setState(() => _filters = _filters.copyWith(query: value)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: CardFilterBar(
              filters: _filters,
              onChanged: (f) => setState(() => _filters = f),
            ),
          ),
          if (_filters.active)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: CardResults(filters: _filters),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded, size: 56, color: tokens.labelMissing),
                    const SizedBox(height: 14),
                    const Text(
                      'Find any card',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels.isEmpty
                          ? 'Search the $downloaded downloaded sets by name or '
                              'code. Give your cards labels on their card page '
                              'and they appear here as colourful filters.'
                          : 'Search the $downloaded downloaded sets by name or '
                              'code, or tap a label to see only those cards.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
