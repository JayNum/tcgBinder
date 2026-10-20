import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../catalog/catalog_scope.dart';
import '../catalog/games.dart';
import '../models/catalog.dart';
import 'ios.dart';

/// Button that downloads the card lists of every set of a game, so search can
/// find any card of that game. [gameId] null = ask which game.
class DownloadAllSetsButton extends StatelessWidget {
  const DownloadAllSetsButton({super.key, this.gameId});

  final String? gameId;

  Future<void> _run(BuildContext context) async {
    final catalog = CatalogScope.of(context);
    var id = gameId;
    id ??= await showActionSheet<String>(
      context,
      title: 'Download all card lists of…',
      actions: [for (final g in games) SheetAction(g.name, g.id)],
    );
    if (id == null || !context.mounted) return;
    final gameName = gameById(id).name;

    final List<CardSet> sets;
    try {
      sets = await catalog.sets(id);
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not load sets: $e')));
      }
      return;
    }
    final todo = [
      for (final s in sets)
        if (catalog.cachedCards(s.id) == null) s,
    ];
    if (todo.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All $gameName sets are already on your phone.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final ok = await confirmDialog(
      context,
      title: 'Download $gameName',
      message: '${todo.length} card lists will be downloaded once, so you can '
          'search every $gameName card. Use Wi-Fi; it can take a few minutes.',
      confirmLabel: 'Download',
    );
    if (!ok || !context.mounted) return;

    final progress = ValueNotifier<String>('Starting…');
    var cancelled = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => AlertDialog(
        title: Text('Downloading $gameName'),
        content: ValueListenableBuilder<String>(
          valueListenable: progress,
          builder: (_, text, __) => Text(text),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cancelled = true;
              Navigator.pop(dialog);
            },
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    var done = 0;
    for (var i = 0; i < todo.length && !cancelled; i += 3) {
      await Future.wait(todo.skip(i).take(3).map((s) async {
        try {
          await catalog.cards(s);
        } on Object catch (_) {
          // A set that fails is skipped; the rest still work.
        }
        done++;
        progress.value = '$done of ${todo.length} sets';
      }));
    }
    if (!cancelled && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _run(context),
        icon: const Icon(Icons.download_rounded, size: 18),
        label: Text(gameId == null
            ? 'Download all sets to search everything'
            : 'Download all sets of this game'),
      ),
    );
  }
}
