import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/collection_store.dart';
import '../data/sample_catalog.dart';
import '../models/catalog.dart';
import '../models/collection.dart';
import '../services/price_links.dart';
import '../theme/app_theme.dart';
import '../widgets/card_photo.dart';

class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({super.key, required this.card, required this.set});

  final CatalogCard card;
  final CardSet set;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final entry = store.entryFor(card.id);
    final game = gameById(set.gameId);
    final countryCode =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              '${card.printedNumber(set)} · ${set.name} · ${game.name}',
              style: TextStyle(fontSize: 12, color: tokens.muted),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(child: _Photo(entry: entry)),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (entry != null)
                  OutlinedButton.icon(
                    onPressed: () => _comingSoon(context, 'Scanning'),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(entry.hasPhoto ? 'Retake photo' : 'Add photo'),
                  ),
                Chip(
                  label: Text(card.rarity),
                  backgroundColor: tokens.accentSoft,
                  labelStyle: TextStyle(
                    color: tokens.accentSoftText,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (entry == null)
            _NotOwned(onAdd: () => store.add(card.id))
          else
            _YourCopy(entry: entry, game: game),
          const SizedBox(height: 16),
          const _SectionTitle('Check prices'),
          _Surface(
            child: Column(
              children: [
                for (final m in PriceLinks.orderedFor(countryCode))
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tokens.accentSoft,
                      foregroundColor: tokens.accentSoftText,
                      child: Text(
                        m.label.substring(0, 1),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Text(
                      m.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(m.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (m == PriceLinks.orderedFor(countryCode).first &&
                            m != Marketplace.ebay)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: _Badge('Your region', filled: true),
                          ),
                        Icon(Icons.open_in_new, size: 18, color: tokens.muted),
                      ],
                    ),
                    onTap: () => _open(
                      context,
                      PriceLinks.forMarketplace(
                        m,
                        game: game,
                        card: card,
                        set: set,
                        edition: game.hasEditions ? entry?.edition : null,
                        countryCode: countryCode,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'Opens the card on the marketplace in your browser. '
              'Prices are checked there, not stored in the app.',
              style: TextStyle(fontSize: 12, height: 1.4, color: tokens.muted),
            ),
          ),
          if (entry != null) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  store.remove(card.id);
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: tokens.danger),
                child: const Text('Remove from collection'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the browser.')),
      );
    }
  }
}

void _comingSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$what is coming in a later version.')),
  );
}

class _Photo extends StatelessWidget {
  const _Photo({required this.entry});

  final CollectionEntry? entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final e = entry;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 210,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: tokens.pocket,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.pocketBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x2E000000), blurRadius: 30, offset: Offset(0, 12)),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 63 / 88,
            child: e != null && e.hasPhoto
                ? CardPhoto(entry: e, scale: 2)
                : Center(
                    child: Icon(
                      e == null ? Icons.style_outlined : Icons.photo_camera_outlined,
                      size: 40,
                      color: tokens.labelMissing,
                    ),
                  ),
          ),
        ),
        if (e != null && e.quantity > 1)
          Positioned(
            top: -8,
            right: -8,
            child: _Badge('×${e.quantity}', filled: true),
          ),
      ],
    );
  }
}

class _NotOwned extends StatelessWidget {
  const _NotOwned({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return _Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Not in your collection yet',
            style: TextStyle(fontWeight: FontWeight.w700, color: tokens.muted),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add to collection'),
          ),
        ],
      ),
    );
  }
}

class _YourCopy extends StatelessWidget {
  const _YourCopy({required this.entry, required this.game});

  final CollectionEntry entry;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    void save(CollectionEntry e) => store.update(e);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Your copy'),
        _Surface(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Quantity',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'One less',
                    onPressed: entry.quantity > 1
                        ? () => save(entry.copyWith(quantity: entry.quantity - 1))
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${entry.quantity}',
                      textAlign: TextAlign.center,
                      style: numberStyle(color: tokens.text, size: 16),
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'One more',
                    onPressed: () =>
                        save(entry.copyWith(quantity: entry.quantity + 1)),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Divider(color: tokens.divider, height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Condition',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    'Your estimate',
                    style: TextStyle(fontSize: 12, color: tokens.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in CardCondition.values)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: entry.condition == c,
                      onSelected: (_) => save(entry.copyWith(condition: c)),
                    ),
                ],
              ),
              if (game.hasEditions) ...[
                Divider(color: tokens.divider, height: 28),
                const Text(
                  'Edition',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SegmentedButton<Edition>(
                  showSelectedIcon: false,
                  segments: [
                    for (final e in Edition.values)
                      ButtonSegment(value: e, label: Text(e.label)),
                  ],
                  selected: {entry.edition},
                  onSelectionChanged: (s) =>
                      save(entry.copyWith(edition: s.first)),
                ),
              ],
              Divider(color: tokens.divider, height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Language',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.language, style: TextStyle(color: tokens.muted)),
                    Icon(Icons.chevron_right, color: tokens.muted),
                  ],
                ),
                onTap: () => _comingSoon(context, 'Choosing the language'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Graded',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Not graded', style: TextStyle(color: tokens.muted)),
                    Icon(Icons.chevron_right, color: tokens.muted),
                  ],
                ),
                onTap: () => _comingSoon(context, 'Grading details'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: context.binder.muted,
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.filled = false});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? context.accent : context.binder.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: filled ? context.onAccent : context.binder.accentSoftText,
        ),
      ),
    );
  }
}
