import 'package:flutter/cupertino.dart' hide Text;
import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../catalog/catalog_scope.dart';
import '../data/collection_store.dart';
import '../models/catalog.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';
import '../widgets/card_search_widgets.dart';
import '../widgets/ios.dart';
import 'binder_screen.dart';

/// All sets of one game, each its own binder. Filterable and sortable.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.game});

  final Game game;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  /// Null shows every kind of set.
  SetKind? _kind;
  SetSort _sort = SetSort.newest;
  Future<List<CardSet>>? _loading;
  String _query = '';
  Set<String> _labels = {};
  bool _favorites = false;
  bool _owned = false;
  final _search = TextEditingController();

  CardFilters get _filters => CardFilters(
        query: _query,
        labels: _labels,
        favorites: _favorites,
        owned: _owned,
      );

  /// Labels, hearts and "owned" only make sense for cards, so they hide the
  /// list of sets and show cards instead.
  bool get _cardsOnly => _labels.isNotEmpty || _favorites || _owned;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Matches the set name or code, ignoring case, dashes and spaces:
  /// "op14", "OP-14" and "azure" all find "The Azure Sea's Seven".
  bool _matches(CardSet set) {
    if (_query.isEmpty) return true;
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[\s\-_:.]'), '');
    final q = norm(_query);
    return norm(set.name).contains(q) ||
        norm(set.code).contains(q) ||
        norm(set.sourceId).contains(q);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= CatalogScope.of(context).sets(widget.game.id);
  }

  Future<void> _pickSort() async {
    final sort = await showActionSheet<SetSort>(
      context,
      title: 'Sort sets',
      actions: [
        for (final sort in SetSort.values)
          SheetAction(sort.label, sort, checked: sort == _sort),
      ],
    );
    if (sort != null) setState(() => _sort = sort);
  }

  Future<void> _refresh() async {
    final future = CatalogScope.of(context).sets(widget.game.id, refresh: true);
    setState(() => _loading = future);
    await future.catchError((Object _) => const <CardSet>[]);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final catalog = CatalogScope.of(context);
    final started = store.startedSets(gameId: widget.game.id);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.game.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(
              '${store.copiesInGame(widget.game.id)} cards · '
              '${started.length} ${started.length == 1 ? 'binder' : 'binders'} started',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: tokens.muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('Sort sets'),
            icon: const Icon(Icons.swap_vert_rounded),
            onPressed: _pickSort,
          ),
        ],
      ),
      body: FutureBuilder<List<CardSet>>(
        future: _loading,
        builder: (context, snapshot) {
          final allSets = snapshot.data ?? catalog.cachedSets(widget.game.id);
          if (allSets.isEmpty) {
            if (snapshot.hasError) {
              return _Message(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load the sets',
                text: 'Check your internet connection. The set list comes '
                    'from ${widget.game.dataSource}.',
                action: 'Try again',
                onAction: _refresh,
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          final kinds = SetKind.values
              .where((k) => allSets.any((s) => s.kind == k))
              .toList();
          final shown = sortSets(
            allSets.where((s) => (_kind == null || s.kind == _kind) && _matches(s)),
            _sort,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: CupertinoSearchTextField(
                      controller: _search,
                      placeholder: tr('Search sets and cards'),
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: CardFilterBar(
                    filters: _filters,
                    onChanged: (f) => setState(() {
                      _labels = f.labels;
                      _favorites = f.favorites;
                      _owned = f.owned;
                    }),
                  ),
                ),
                if (kinds.length > 1 && !_cardsOnly)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _kind == null,
                            onSelected: () => setState(() => _kind = null),
                          ),
                          for (final kind in kinds)
                            _FilterChip(
                              label: kind.label,
                              selected: _kind == kind,
                              onSelected: () => setState(() => _kind = kind),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (!_cardsOnly) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      '${shown.length} ${shown.length == 1 ? 'set' : 'sets'} · '
                      '${_sort.label}',
                    ),
                  ),
                  if (shown.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _query.isEmpty
                              ? 'No sets of this kind.'
                              : 'No set matches "$_query".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: tokens.muted),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: shown.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) => _SetRow(
                        game: widget.game,
                        set: shown[i],
                      ),
                    ),
                  ),
                ],
                // Cards that match the search, or the chosen labels.
                if (_filters.active)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: CardResults(
                        filters: _filters,
                        gameId: widget.game.id,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) =>
      PillChip(label: label, selected: selected, onTap: onSelected);
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.game, required this.set});

  final Game game;
  final CardSet set;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final catalog = CatalogScope.of(context);
    final cards = catalog.cachedCards(set.id);
    final ownedCount = store.entries.where((e) => e.setId == set.id).length;
    final started = ownedCount > 0;

    // Progress needs the card list; before it's downloaded we show the
    // count of cards you have.
    int? owned;
    int? total;
    if (cards != null) {
      final base = cards.where((c) => c.isBase);
      owned = store.ownedIn(base);
      total = set.printedTotal ?? base.length;
    }

    final gameTint = gameColor(game.id);
    final cover = started ? gameTint : gameTint.withValues(alpha: 0.45);
    const coverText = Colors.white;
    final year = set.releaseYear;

    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => BinderScreen(set: set)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 56,
                decoration: BoxDecoration(
                  color: cover,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(3),
                    right: Radius.circular(7),
                  ),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 6, left: 5, right: 2),
                child: Text(
                  set.code,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: numberStyle(color: coverText, size: 8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [set.code, if (year != null) '$year', set.kind.label]
                          .join(' · '),
                      style: TextStyle(fontSize: 12, color: tokens.muted),
                    ),
                    const SizedBox(height: 6),
                    if (started && owned != null && total != null && total > 0)
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (owned / total)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                                minHeight: 5,
                                color: gameTint,
                                backgroundColor: tokens.pocketBorder,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$owned / $total',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: gameTint,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        started
                            ? '$ownedCount ${ownedCount == 1 ? 'card' : 'cards'}'
                            : 'Empty binder',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: started ? context.accent : tokens.labelMissing,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: tokens.labelMissing),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.muted, height: 1.4),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
