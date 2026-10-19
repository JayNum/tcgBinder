import 'package:flutter/material.dart';

import '../data/collection_store.dart';
import '../data/sample_catalog.dart';
import '../models/catalog.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';
import '../widgets/ad_banner.dart';
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final allSets = setsOfGame(widget.game.id);
    final kinds = SetKind.values
        .where((k) => allSets.any((s) => s.kind == k))
        .toList();
    final shown = sortSets(
      allSets.where((s) => _kind == null || s.kind == _kind),
      _sort,
    );
    final started =
        allSets.where((s) => store.ownedIn(cardsInSet(s.id)) > 0).length;

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
              '$started of ${allSets.length} binders started',
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
      body: Column(
        children: [
          if (kinds.length > 1)
            SizedBox(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Row(
              children: [
                Text(
                  '${shown.length} ${shown.length == 1 ? 'set' : 'sets'} · ${_sort.label}',
                  style: TextStyle(fontSize: 12, color: tokens.muted),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: shown.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _SetRow(
                game: widget.game,
                set: shown[i],
              ),
            ),
          ),
          const AdBannerPlaceholder(),
        ],
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
    final cards = cardsInSet(set.id);
    final owned = store.ownedIn(cards);
    final total = set.printedTotal ?? cards.length;
    final started = owned > 0;
    final cover = started ? gameColor(game.id) : tokens.pocketBorder;
    final coverText = started ? Colors.white : tokens.muted;

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
                padding: const EdgeInsets.only(bottom: 6, left: 5),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${set.code} · ${set.releaseYear} · ${set.kind.label}',
                      style: TextStyle(fontSize: 12, color: tokens.muted),
                    ),
                    const SizedBox(height: 6),
                    if (started)
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: total == 0
                                    ? 0.0
                                    : (owned / total).clamp(0.0, 1.0).toDouble(),
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
                        'Empty binder',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tokens.labelMissing,
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
