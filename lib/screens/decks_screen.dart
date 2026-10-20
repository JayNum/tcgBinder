import 'package:flutter/cupertino.dart' hide Text;
import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../catalog/games.dart';
import '../data/deck_store.dart';
import '../data/settings_store.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';
import '../widgets/ios.dart';
import 'deck_screen.dart';
import 'pro_screen.dart';

/// Every deck the user has built, grouped by game.
class DecksScreen extends StatelessWidget {
  const DecksScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final settings = SettingsScope.of(context);
    final store = DeckScope.of(context);
    final gameId = await showActionSheet<String>(
      context,
      title: 'Which game is the deck for?',
      actions: [
        for (final g in arrangedGames(settings)) SheetAction(g.name, g.id),
      ],
    );
    if (gameId == null || !context.mounted) return;

    if (!store.canCreate(gameId, isPro: settings.isPro)) {
      final seePro = await confirmDialog(
        context,
        title: 'One deck per game',
        message: 'The free version has ${DeckStore.freeDecksPerGame} deck for '
            'each game. Pro lets you build as many decks as you like.',
        confirmLabel: 'See Pro',
      );
      if (seePro && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProScreen()),
        );
      }
      return;
    }

    final name = await promptDialog(
      context,
      title: 'Name your deck',
      placeholder: 'e.g. Red aggro',
      confirmLabel: 'Create',
    );
    if (name == null || !context.mounted) return;
    final deck = store.create(gameId, name);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DeckScreen(deckId: deck.id)),
    );
  }

  Future<void> _manage(BuildContext context, Deck deck) async {
    final store = DeckScope.of(context);
    final action = await showActionSheet<String>(
      context,
      title: deck.name,
      actions: const [
        SheetAction('Rename', 'rename'),
        SheetAction('Delete deck', 'delete', destructive: true),
      ],
    );
    if (action == null || !context.mounted) return;
    if (action == 'rename') {
      final name = await promptDialog(
        context,
        title: 'Rename deck',
        placeholder: deck.name,
        confirmLabel: 'Save',
      );
      if (name != null) store.rename(deck.id, name);
    } else {
      final ok = await confirmDialog(
        context,
        title: 'Delete this deck?',
        message: 'The deck list is removed. Your collection is not touched.',
        confirmLabel: 'Delete',
        destructive: true,
      );
      if (ok) store.delete(deck.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = DeckScope.of(context);
    final settings = SettingsScope.of(context);
    final withDecks = [
      for (final g in games)
        if (store.decksFor(g.id).isNotEmpty) g,
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Decks'),
            transitionBetweenRoutes: false,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _create(context),
              child: Icon(CupertinoIcons.add, color: context.accent),
            ),
          ),
          if (withDecks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.style_rounded, size: 56, color: tokens.labelMissing),
                    const SizedBox(height: 14),
                    const Text(
                      'No decks yet',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Build a deck from any card. Cards you do not own are '
                      'greyed out and you can look for them on Cardmarket, '
                      'TCGplayer or eBay.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.35, color: tokens.muted),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => _create(context),
                      child: const Text('New deck'),
                    ),
                    if (!settings.isPro) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Free: 1 deck per game. Pro: as many as you like.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: tokens.muted),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(
                children: [
                  for (final g in withDecks) ...[
                    SectionHeader(g.name),
                    GroupedSection(
                      child: Column(
                        children: [
                          for (final deck in store.decksFor(g.id))
                            ListTile(
                              leading: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: gameColor(g.id),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.style_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(deck.name),
                              subtitle: Text('${deck.totalCards} cards'),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: tokens.muted,
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => DeckScreen(deckId: deck.id),
                                ),
                              ),
                              onLongPress: () => _manage(context, deck),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    'Touch and hold a deck to rename or delete it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: tokens.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
