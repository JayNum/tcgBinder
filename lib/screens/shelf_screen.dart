import 'package:flutter/material.dart';

import '../data/collection_store.dart';
import '../data/sample_catalog.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
import 'binder_screen.dart';

/// Default binder cover per game, until users customize them (Premium).
const _coverColors = <String, Color>{
  'pokemon': Color(0xFF2B50D6),
  'onepiece': Color(0xFFB42318),
  'magic': Color(0xFF3A3A40),
  'lorcana': Color(0xFF6B46A8),
  'riftbound': Color(0xFF1F6B45),
};

/// Home: all of the user's binders.
class ShelfScreen extends StatelessWidget {
  const ShelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My binders',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                for (final set in sets)
                  Builder(
                    builder: (context) {
                      final cards = cardsInSet(set.id);
                      final owned = store.ownedIn(cards);
                      final game = gameById(set.gameId);
                      return Card(
                        elevation: 0,
                        color: tokens.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: tokens.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => BinderScreen(set: set),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    color: _coverColors[set.gameId] ??
                                        context.accent,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(3),
                                      right: Radius.circular(8),
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 6,
                                    color: Colors.black.withValues(alpha: 0.2),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        set.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${game.name} · ${set.releaseYear}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: tokens.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: cards.isEmpty
                                              ? 0.0
                                              : owned / cards.length,
                                          minHeight: 5,
                                          backgroundColor: tokens.pocketBorder,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$owned of ${cards.length} collected',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: tokens.muted,
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
                    },
                  ),
              ],
            ),
          ),
          const AdBannerPlaceholder(),
        ],
      ),
    );
  }
}
