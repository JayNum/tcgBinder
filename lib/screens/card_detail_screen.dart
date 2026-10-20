import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../catalog/catalog_scope.dart';
import '../catalog/games.dart';
import '../data/collection_store.dart';
import '../models/catalog.dart';
import '../models/collection.dart';
import '../services/add_card.dart';
import '../services/ads.dart';
import '../services/photos.dart';
import '../services/price_links.dart';
import '../theme/app_theme.dart';
import '../widgets/card_photo.dart';
import '../widgets/ios.dart';
import '../widgets/pocket.dart';

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
    final markets = PriceLinks.orderedFor(countryCode);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(
              [
                card.code,
                if (card.variant != null) card.variant!,
                card.reprint ? 'pulled from ${set.code}' : set.name,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: tokens.muted,
              ),
            ),
          ],
        ),
        actions: [
          // Only cards you own can be favorites.
          if (entry != null)
            IconButton(
              tooltip: entry.favorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              onPressed: () => store.toggleFavorite(card.id),
              icon: Icon(
                entry.favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: entry.favorite
                    ? const Color(0xFFFF2D55)
                    : context.accent,
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BannerAdView(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(child: _Photo(entry: entry)),
          const SizedBox(height: 12),
          if (card.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                card.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.muted, fontWeight: FontWeight.w600),
              ),
            ),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (card.variant != null)
                  VariantTag(label: card.variant!, large: true),
                if (card.rarity.isNotEmpty)
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
          const SizedBox(height: 12),
          if (entry == null)
            _AddButtons(card: card)
          else
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _changePhoto(context),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(entry.hasPhoto ? 'Change photo' : 'Add photo'),
              ),
            ),
          const SizedBox(height: 20),
          _VersionsSection(card: card),
          if (entry != null) _LabelsSection(entry: entry),
          if (entry != null) _YourCopy(entry: entry, game: game),
          const SizedBox(height: 16),
          const _SectionTitle('Check prices'),
          _Surface(
            child: Column(
              children: [
                for (final m in markets)
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
                        if (m == markets.first && m != Marketplace.ebay)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: _Badge('Your region'),
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
                onPressed: () => _confirmRemove(context),
                style: TextButton.styleFrom(foregroundColor: tokens.danger),
                child: const Text('Remove from collection'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _changePhoto(BuildContext context) async {
    final store = CollectionScope.of(context);
    final source = await askPhotoSource(context);
    if (source == null) return;
    final path = await pickAndSavePhoto(
      source: source,
      targetPath: store.newPhotoPath(),
    );
    if (path != null) store.setPhoto(card.id, path);
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final store = CollectionScope.of(context);
    final navigator = Navigator.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Remove this card?',
      message: '${card.name} and its photo will be removed from your binder.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (ok) {
      store.remove(card.id);
      navigator.pop();
    }
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

class _AddButtons extends StatelessWidget {
  const _AddButtons({required this.card});

  final CatalogCard card;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => _addWithPhoto(context),
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: const Text('Add with photo'),
        ),
        OutlinedButton.icon(
          onPressed: () => addCardToCollection(context, card),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add without photo'),
        ),
      ],
    );
  }

  Future<void> _addWithPhoto(BuildContext context) async {
    final store = CollectionScope.of(context);
    final source = await askPhotoSource(context);
    if (source == null) return;
    final path = await pickAndSavePhoto(
      source: source,
      targetPath: store.newPhotoPath(),
    );
    if (path == null || !context.mounted) return;
    addCardToCollection(context, card, photoPath: path);
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.entry});

  final CollectionEntry? entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final e = entry;
    final photo = e?.photoPath;
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
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 30,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 63 / 88,
            child: photo != null
                ? CardPhoto(path: photo, radius: 8)
                : Center(
                    child: Icon(
                      e == null
                          ? Icons.style_outlined
                          : Icons.photo_camera_outlined,
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
            child: _Badge('×${e.quantity}'),
          ),
      ],
    );
  }
}

/// "3 versions of this card": every printing that shares this card's code,
/// with the set it is pulled from and whether the user owns it.
class _VersionsSection extends StatefulWidget {
  const _VersionsSection({required this.card});

  final CatalogCard card;

  @override
  State<_VersionsSection> createState() => _VersionsSectionState();
}

class _VersionsSectionState extends State<_VersionsSection> {
  bool _open = false;
  Future<List<CatalogCard>>? _versions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _versions ??= CatalogScope.of(context).versionsOf(widget.card);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CatalogCard>>(
      future: _versions,
      builder: (context, snapshot) {
        final versions = snapshot.data ?? const <CatalogCard>[];
        if (versions.length < 2) return const SizedBox.shrink();

        final tokens = context.binder;
        final store = CollectionScope.of(context);
        final owned = versions.where((v) => store.owns(v.id)).length;
        final missing = versions.length - owned;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _Surface(
            child: Column(
              children: [
                ListTile(
                  onTap: () => setState(() => _open = !_open),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tokens.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.filter_none,
                      size: 18,
                      color: context.accent,
                    ),
                  ),
                  title: Text(
                    '${versions.length} versions of this card',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    missing == 0
                        ? 'You have all of them'
                        : 'You have $owned · $missing missing',
                    style: TextStyle(fontSize: 12, color: tokens.muted),
                  ),
                  trailing: AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, color: tokens.muted),
                  ),
                ),
                if (_open) ...[
                  Divider(height: 1, color: tokens.divider),
                  for (final version in versions)
                    _VersionRow(
                      version: version,
                      current: version.id == widget.card.id,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Text(
                      'Each version sits in the binder of the set it comes '
                      'out of. Tap a version to open it or add it.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: tokens.muted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.version, required this.current});

  final CatalogCard version;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final catalog = CatalogScope.of(context);
    final entry = store.entryFor(version.id);
    final set = catalog.setById(version.setId);
    final photo = entry?.photoPath;

    return Material(
      color: current
          ? tokens.accentSoft.withValues(alpha: 0.5)
          : Colors.transparent,
      child: InkWell(
        onTap: current || set == null
            ? null
            : () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => CardDetailScreen(card: version, set: set),
                  ),
                ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: AspectRatio(
                  aspectRatio: 63 / 88,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.pocket,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: tokens.pocketBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: photo != null
                          ? CardPhoto(path: photo, radius: 2)
                          : const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            version.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: numberStyle(color: tokens.text, size: 13),
                          ),
                        ),
                        const SizedBox(width: 6),
                        VariantTag(label: version.variant ?? 'Base', large: true),
                        if (current) ...[
                          const SizedBox(width: 6),
                          Text(
                            'This card',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      set == null ? version.name : 'In ${set.code} · ${set.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: tokens.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: entry != null ? tokens.successSoft : tokens.pocket,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry != null ? 'Owned ×${entry.quantity}' : 'Missing',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: entry != null ? tokens.success : tokens.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                    Icon(Icons.chevron_right_rounded, color: tokens.muted),
                  ],
                ),
                onTap: () async {
                  final language = await showActionSheet<String>(
                    context,
                    title: 'Language',
                    actions: [
                      for (final l in cardLanguages)
                        SheetAction(l, l, checked: l == entry.language),
                    ],
                  );
                  if (language != null) save(entry.copyWith(language: language));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The user's own labels for a card ("Trade", "Deck", ...). Tap a label to
/// put it on the card or take it off; "New label" makes another one.
class _LabelsSection extends StatelessWidget {
  const _LabelsSection({required this.entry});

  final CollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final labels = store.allLabels;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Labels'),
          _Surface(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  runSpacing: 8,
                  children: [
                    for (final label in labels)
                      PillChip(
                        label: label,
                        icon: Icons.sell_outlined,
                        background: tokens.pocket,
                        selected: entry.labels.contains(label),
                        onTap: () => entry.labels.contains(label)
                            ? store.removeLabel(entry.cardId, label)
                            : store.addLabel(entry.cardId, label),
                      ),
                    PillChip(
                      label: 'New label',
                      icon: Icons.add_rounded,
                      background: tokens.pocket,
                      selected: false,
                      onTap: () => _add(context),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: Text(
                    'Labels are only for you, like "Trade", "Deck" or '
                    '"Graded". Use them in Binders to show only those cards.',
                    style: TextStyle(fontSize: 13, height: 1.35, color: tokens.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final store = CollectionScope.of(context);
    final text = await promptDialog(
      context,
      title: 'New label',
      placeholder: 'e.g. Trade',
      confirmLabel: 'Add',
    );
    if (text != null && text.trim().isNotEmpty) {
      store.addLabel(entry.cardId, text);
    }
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
          fontSize: 13,
          color: context.binder.muted,
          letterSpacing: -0.1,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.onAccent,
        ),
      ),
    );
  }
}
