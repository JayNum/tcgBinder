import 'dart:io';

import 'package:flutter/cupertino.dart' hide Text;
import 'package:flutter/material.dart' hide Text;
import 'package:image_picker/image_picker.dart';

import '../l10n/l10n.dart';
import '../catalog/games.dart';
import '../data/collection_store.dart';
import '../data/settings_store.dart';
import '../models/catalog.dart';
import '../services/photos.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';
import '../widgets/ios.dart';
import 'arrange_games_screen.dart';
import 'game_screen.dart';

/// The Binders tab: pick a game, or search every card on the phone.
class BindersScreen extends StatefulWidget {
  const BindersScreen({super.key});

  @override
  State<BindersScreen> createState() => _BindersScreenState();
}

class _BindersScreenState extends State<BindersScreen> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final shown = arrangedGames(SettingsScope.of(context));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Binders'),
            transitionBetweenRoutes: false,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const ArrangeGamesScreen(),
                ),
              ),
              child: const Text('Arrange'),
            ),
          ),
          if (shown.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'All games are hidden. Tap Arrange to show them again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.muted),
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.12,
                ),
                delegate: SliverChildListDelegate([
                  for (final game in shown) _GameTile(game: game),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Text(
                  'Tip: touch and hold a game to give it your own image.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: tokens.muted),
                ),
              ),
            ),
          ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      _GameCover(color: gameColor(game.id)),
                    Positioned(
                      right: 8,
                      top: 8,
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
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: tokens.muted),
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
    final choice = await showActionSheet<String>(
      context,
      title: '${game.name} image',
      actions: [
        const SheetAction('Choose from gallery', 'gallery'),
        const SheetAction('Take a photo', 'camera'),
        if (hasImage)
          const SheetAction('Use the default colour', 'reset', destructive: true),
      ],
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

/// The tile cover when the user has not picked an image: a rich gradient
/// with two cards peeking out.
class _GameCover extends StatelessWidget {
  const _GameCover({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget card(double right, double top, double angle, double alpha) =>
        Positioned(
          right: right,
          top: top,
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: 34,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.18)!,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          card(48, 22, -0.1, 0.4),
          card(20, 26, 0.17, 0.25),
        ],
      ),
    );
  }
}
