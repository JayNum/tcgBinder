import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../catalog/games.dart';
import '../data/collection_store.dart';
import '../data/settings_store.dart';
import '../models/catalog.dart';
import '../services/ads.dart';
import '../services/photos.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';
import 'arrange_games_screen.dart';
import 'game_screen.dart';

/// Home: collection stats and one tile per supported game.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final shown = arrangedGames(SettingsScope.of(context));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My collection',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: const BannerAdView(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Row(
            children: [
              _Stat(value: '${store.totalCards}', label: 'Cards'),
              const SizedBox(width: 8),
              _Stat(
                value: '${store.startedSets().length}',
                label: 'Binders started',
              ),
              const SizedBox(width: 8),
              _Stat(
                value: '${store.entries.where((e) => e.hasPhoto).length}',
                label: 'Photos',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'GAMES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: tokens.muted,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ArrangeGamesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.swap_vert, size: 18),
                  label: const Text('Arrange'),
                ),
              ],
            ),
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'All games are hidden. Tap Arrange to show them again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.muted),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.15,
              children: [for (final game in shown) _GameTile(game: game)],
            ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Tip: long-press a game to give it your own image.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: tokens.labelMissing),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final settings = SettingsScope.of(context);
    final image = settings.gameImage(game.id);
    final copies = store.copiesInGame(game.id);
    final started = store.startedSets(gameId: game.id).length;
    final line = copies == 0
        ? 'Not started yet'
        : '$copies cards · $started ${started == 1 ? 'binder' : 'binders'}';

    return Semantics(
      button: true,
      hint: 'Long-press to change the image',
      child: Material(
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => GameScreen(game: game)),
          ),
          onLongPress: () => _editImage(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image != null)
                      Image.file(
                        File(image),
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        errorBuilder: (context, error, stack) =>
                            ColoredBox(color: gameColor(game.id)),
                      )
                    else
                      ColoredBox(color: gameColor(game.id)),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _editImage(context),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Colors.white,
                              semanticLabel: 'Change image',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: tokens.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editImage(BuildContext context) async {
    final settings = SettingsScope.of(context);
    final hasImage = settings.gameImage(game.id) != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '${game.name} image',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Use the default colour'),
                onTap: () => Navigator.pop(context, 'reset'),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    if (choice == 'reset') {
      settings.setGameImage(game.id, null);
      return;
    }
    final path = await pickAndSavePhoto(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      targetPath: settings.newImagePath(game.id),
      maxWidth: 1000,
    );
    if (path != null) settings.setGameImage(game.id, path);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          children: [
            Text(value, style: numberStyle(color: tokens.text, size: 18)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
