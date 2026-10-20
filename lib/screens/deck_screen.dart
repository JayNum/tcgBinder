import 'package:flutter/material.dart' hide Text;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../catalog/catalog_scope.dart';
import '../catalog/card_search.dart';
import '../catalog/games.dart';
import '../data/collection_store.dart';
import '../data/deck_store.dart';
import '../models/catalog.dart';
import '../services/price_links.dart';
import '../theme/app_theme.dart';
import '../widgets/download_sets.dart';
import '../widgets/ios.dart';

/// Opens the marketplace list for one card and launches the chosen one.
Future<void> buyCard(BuildContext context, CatalogCard card) async {
  final catalog = CatalogScope.of(context);
  final set = catalog.setById(card.setId) ??
      CardSet(
        id: card.setId,
        gameId: card.gameId,
        sourceId: '',
        code: '',
        name: '',
        order: 0,
      );
  final game = gameById(card.gameId);
  final country =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode;
  final market = await showActionSheet<Marketplace>(
    context,
    title: 'Find ${card.name}',
    message: 'Opens the marketplace in your browser.',
    actions: [
      for (final m in PriceLinks.orderedFor(country))
        SheetAction('${m.label} · ${m.description}', m),
    ],
  );
  if (market == null || !context.mounted) return;
  final uri = PriceLinks.forMarketplace(
    market,
    game: game,
    card: card,
    set: set,
    countryCode: country,
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the browser.')),
    );
  }
}

/// One deck: its cards, which of them the user owns, and where to buy the
/// rest.
class DeckScreen extends StatelessWidget {
  const DeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final decks = DeckScope.of(context);
    final store = CollectionScope.of(context);
    final deck = decks.byId(deckId);
    if (deck == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This deck was deleted.')),
      );
    }

    final entries = [...deck.entries]
      ..sort((a, b) => a.card.name.compareTo(b.card.name));
    var have = 0, missing = 0;
    for (final e in entries) {
      final owned = store.entryFor(e.card.id)?.quantity ?? 0;
      have += owned < e.quantity ? owned : e.quantity;
      missing += owned < e.quantity ? e.quantity - owned : 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          IconButton(
            tooltip: tr('Add cards'),
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AddToDeckScreen(deckId: deck.id),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GroupedSection(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _Stat('${deck.totalCards}', 'Cards', context.accent),
                _Stat('$have', 'You have', tokens.success),
                _Stat('$missing', 'Missing', tokens.danger),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'This deck is empty. Add any card of '
                    '${gameById(deck.gameId).name}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.muted, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AddToDeckScreen(deckId: deck.id),
                      ),
                    ),
                    child: const Text('Add cards'),
                  ),
                ],
              ),
            )
          else
            GroupedSection(
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const Divider(indent: 72),
                    _DeckRow(deckId: deck.id, entry: entries[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: context.binder.muted)),
        ],
      ),
    );
  }
}

/// A small card picture: the card database's image, or a plain tile.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.card, this.dim = false});

  final CatalogCard card;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final url = card.imageUrl;
    Widget child = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.pocket,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tokens.pocketBorder, width: 0.5),
      ),
      child: const SizedBox.expand(),
    );
    if (url != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => child,
        ),
      );
    }
    if (dim) {
      // Grey and see-through: a card the user does not have.
      child = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: Opacity(opacity: 0.55, child: child),
      );
    }
    return SizedBox(
      width: 44,
      child: AspectRatio(aspectRatio: 63 / 88, child: child),
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deckId, required this.entry});

  final String deckId;
  final DeckEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final decks = DeckScope.of(context);
    final catalog = CatalogScope.of(context);
    final card = entry.card;
    final owned = CollectionScope.of(context).entryFor(card.id)?.quantity ?? 0;
    final missing = entry.quantity > owned ? entry.quantity - owned : 0;
    final notOwned = owned == 0;
    final set = catalog.setById(card.setId);
    final muted = tokens.muted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          _Thumb(card: card, dim: notOwned),
          const SizedBox(width: 14),
          Expanded(
            child: Opacity(
              opacity: notOwned ? 0.5 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    [card.code, if (set != null) set.name].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
          ),
          if (missing > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => buyCard(context, card),
                child: Text('Buy · missing $missing'),
              ),
            ),
          IconButton(
            tooltip: tr('One less'),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            onPressed: () =>
                decks.setQuantity(deckId, card.id, entry.quantity - 1),
          ),
          Text(
            '${entry.quantity}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(
            tooltip: tr('One more'),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => decks.add(deckId, card),
          ),
        ],
      ),
    );
  }
}

/// Search every downloaded card of the deck's game and tap to add it.
class AddToDeckScreen extends StatefulWidget {
  const AddToDeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<AddToDeckScreen> createState() => _AddToDeckScreenState();
}

class _AddToDeckScreenState extends State<AddToDeckScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final decks = DeckScope.of(context);
    final deck = decks.byId(widget.deckId);
    if (deck == null) return Scaffold(appBar: AppBar());
    final catalog = CatalogScope.of(context);
    final store = CollectionScope.of(context);
    final hits = searchCards(
      catalog,
      store,
      query: _query,
      gameId: deck.gameId,
      limit: 60,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Add to ${deck.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: tr('Name, code or set'),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: tokens.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (hits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No card matches. Cards that are not on your phone yet '
                      'can be added after you download the sets.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tokens.muted, height: 1.4),
                    ),
                  )
                else
                  GroupedSection(
                    child: Column(
                      children: [
                        for (var i = 0; i < hits.length; i++) ...[
                          if (i > 0) const Divider(indent: 72),
                          _AddRow(deckId: deck.id, hit: hits[i]),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                DownloadAllSetsButton(gameId: deck.gameId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.deckId, required this.hit});

  final String deckId;
  final CardHit hit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final decks = DeckScope.of(context);
    final inDeck = decks.quantityOf(deckId, hit.card.id);
    final owned =
        CollectionScope.of(context).entryFor(hit.card.id)?.quantity ?? 0;

    return InkWell(
      onTap: () => decks.add(deckId, hit.card),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        child: Row(
          children: [
            _Thumb(card: hit.card, dim: owned == 0),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.card.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    [
                      hit.card.code,
                      if (hit.card.variant != null) hit.card.variant!,
                      hit.set.name,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: tokens.muted),
                  ),
                  if (owned > 0)
                    Text(
                      'Owned ×$owned',
                      style: TextStyle(fontSize: 12, color: tokens.success),
                    ),
                ],
              ),
            ),
            if (inDeck > 0)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  '×$inDeck',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.accent,
                  ),
                ),
              ),
            Icon(Icons.add_circle_rounded, color: context.accent),
          ],
        ),
      ),
    );
  }
}
