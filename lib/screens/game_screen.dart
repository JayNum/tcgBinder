import 'package:flutter/material.dart';

import '../catalog/catalog_scope.dart';
import '../data/collection_store.dart';
import '../models/catalog.dart';
import '../services/ads.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= CatalogScope.of(context).sets(widget.game.id);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.game.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              '${store.copiesInGame(widget.game.id)} cards · '
              '${started.length} ${started.length == 1 ? 'binder' : 'binders'} started',
              style: TextStyle(fontSize: 12, color: tokens.muted),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<SetSort>(
            tooltip: 'Sort sets',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (sort) => setState(() => _sort = sort),
            itemBuilder: (context) => [
              for (final sort in SetSort.values)
                CheckedPopupMenuItem<SetSort>(
                  value: sort,
                  checked: sort == _sort,
                  child: Text(sort.label),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdView(),
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
            allSets.where((s) => _kind == null || s.kind == _kind),
            _sort,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                if (kinds.length > 1)
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                    child: Text(
                      '${shown.length} ${shown.length == 1 ? 'set' : 'sets'} · '
                      '${_sort.label}',
                      style: TextStyle(fontSize: 12, color: tokens.muted),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList.separated(
                    itemCount: shown.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) => _SetRow(
                      game: widget.game,
                      set: shown[i],
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
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

    final cover = started ? gameColor(game.id) : tokens.pocketBorder;
    final coverText = started ? Colors.white : tokens.muted;
    final year = set.releaseYear;

    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tokens.border),
      ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
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
                              color: context.accent,
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
              Icon(Icons.chevron_right, color: tokens.muted),
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
