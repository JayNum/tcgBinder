import 'dart:io';

import 'package:flutter/material.dart';

import '../catalog/games.dart';
import '../data/settings_store.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';

/// Drag games into the order you like and hide the ones you don't play.
class ArrangeGamesScreen extends StatelessWidget {
  const ArrangeGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final settings = SettingsScope.of(context);
    final ordered = arrangedGames(settings, includeHidden: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Arrange games',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Drag a game by its handle to move it. Switch a game off to '
              'hide it from the home screen and the scanner — your cards '
              'stay saved.',
              style: TextStyle(color: tokens.muted, height: 1.4),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              buildDefaultDragHandles: false,
              itemCount: ordered.length,
              onReorder: (oldIndex, newIndex) {
                final ids = [for (final g in ordered) g.id];
                if (newIndex > oldIndex) newIndex -= 1;
                final moved = ids.removeAt(oldIndex);
                ids.insert(newIndex, moved);
                settings.setGameOrder(ids);
              },
              itemBuilder: (context, index) {
                final game = ordered[index];
                final hidden = settings.isGameHidden(game.id);
                final image = settings.gameImage(game.id);
                return Padding(
                  key: ValueKey(game.id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: tokens.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: tokens.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.drag_handle,
                                color: tokens.muted,
                                semanticLabel: 'Drag to move ${game.name}',
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: image != null
                                  ? Image.file(
                                      File(image),
                                      fit: BoxFit.cover,
                                      cacheWidth: 160,
                                      errorBuilder: (context, error, stack) =>
                                          ColoredBox(color: gameColor(game.id)),
                                    )
                                  : ColoredBox(color: gameColor(game.id)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              game.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: hidden ? tokens.labelMissing : tokens.text,
                              ),
                            ),
                          ),
                          Switch(
                            value: !hidden,
                            onChanged: (show) =>
                                settings.setGameHidden(game.id, !show),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
