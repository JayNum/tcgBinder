import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../catalog/catalog_scope.dart';
import '../catalog/games.dart';
import '../data/collection_store.dart';
import '../models/catalog.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';
import '../widgets/ios.dart';
import '../widgets/pocket.dart';
import 'card_detail_screen.dart';

/// A set binder: 9-pocket pages you swipe through.
class BinderScreen extends StatefulWidget {
  const BinderScreen({super.key, required this.set});

  final CardSet set;

  @override
  State<BinderScreen> createState() => _BinderScreenState();
}

class _BinderScreenState extends State<BinderScreen> {
  static const _perPage = 9;
  final _controller = PageController();
  int _page = 0;
  Future<List<CatalogCard>>? _loading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loading ??= CatalogScope.of(context).cards(widget.set);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reload({bool refresh = false}) {
    setState(() {
      _page = 0;
      _loading = CatalogScope.of(context).cards(widget.set, refresh: refresh);
    });
    if (_controller.hasClients) _controller.jumpToPage(0);
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final game = gameById(widget.set.gameId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.set.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(
              '${game.name} · ${widget.set.code}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: tokens.muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('More'),
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () async {
              final choice = await showActionSheet<String>(
                context,
                actions: const [
                  SheetAction('Download card list again', 'refresh'),
                ],
              );
              if (choice == 'refresh') _reload(refresh: true);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<CatalogCard>>(
        future: _loading,
        builder: (context, snapshot) {
          final cards = snapshot.data;
          if (cards == null) {
            if (snapshot.hasError) {
              return _Message(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load this set',
                text: 'Check your internet connection. The card list comes '
                    'from ${game.dataSource}. Once downloaded, the binder '
                    'works offline.\n\n${snapshot.error}',
                action: 'Try again',
                onAction: () => _reload(refresh: true),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          if (cards.isEmpty) {
            return _Message(
              icon: Icons.collections_bookmark_outlined,
              title: 'No cards listed yet',
              text: '${game.dataSource} has no cards for this set yet. '
                  'Try again later.',
              action: 'Check again',
              onAction: () => _reload(refresh: true),
            );
          }
          return _Binder(
            set: widget.set,
            cards: cards,
            controller: _controller,
            page: _page,
            onPageChanged: (p) => setState(() => _page = p),
            onGoTo: _goTo,
          );
        },
      ),
    );
  }
}

class _Binder extends StatelessWidget {
  const _Binder({
    required this.set,
    required this.cards,
    required this.controller,
    required this.page,
    required this.onPageChanged,
    required this.onGoTo,
  });

  final CardSet set;
  final List<CatalogCard> cards;
  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onGoTo;

  static const _perPage = _BinderScreenState._perPage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);
    final base = cards.where((c) => c.isBase);
    final extras = cards.where((c) => !c.isBase);
    final owned = store.ownedIn(base);
    final ownedExtras = store.ownedIn(extras);
    final total = set.printedTotal ?? base.length;
    final pageCount = math.max(1, (cards.length / _perPage).ceil());
    final percent = total == 0 ? 0 : (owned * 100 / total).round();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$owned',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: tokens.text,
                            ),
                          ),
                          TextSpan(text: tr(' of $total collected')),
                          if (ownedExtras > 0)
                            TextSpan(
                              text: tr(' · $ownedExtras '
                                  '${ownedExtras == 1 ? 'alt art' : 'alt arts'}'),
                            ),
                        ],
                      ),
                      style: TextStyle(fontSize: 12, color: tokens.muted),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: gameColor(set.gameId),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: total == 0
                      ? 0.0
                      : (owned / total).clamp(0.0, 1.0).toDouble(),
                  minHeight: 6,
                  color: gameColor(set.gameId),
                  backgroundColor: tokens.pocketBorder,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: controller,
            itemCount: pageCount,
            onPageChanged: onPageChanged,
            itemBuilder: (context, p) {
              final start = p * _perPage;
              final pageCards = cards.sublist(
                start,
                math.min(start + _perPage, cards.length),
              );
              return _BinderPage(set: set, cards: pageCards);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: tr('Previous page'),
              onPressed: page > 0 ? () => onGoTo(page - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              'Page ${page + 1} of $pageCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.muted,
              ),
            ),
            IconButton(
              tooltip: tr('Next page'),
              onPressed: page < pageCount - 1 ? () => onGoTo(page + 1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _BinderPage extends StatelessWidget {
  const _BinderPage({required this.set, required this.cards});

  final CardSet set;
  final List<CatalogCard> cards;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);

    Widget slot(int index) {
      if (index >= cards.length) return const SizedBox.shrink();
      final card = cards[index];
      return Pocket(
        card: card,
        entry: store.entryFor(card.id),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CardDetailScreen(card: card, set: set),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 8, 10, 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ring holes on the left edge, like a real binder sheet.
            Positioned(
              left: -16,
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (_) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tokens.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: tokens.pocketBorder),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                for (var row = 0; row < 3; row++) ...[
                  if (row > 0) const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: slot(row * 3)),
                      const SizedBox(width: 8),
                      Expanded(child: slot(row * 3 + 1)),
                      const SizedBox(width: 8),
                      Expanded(child: slot(row * 3 + 2)),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: tokens.labelMissing),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.muted, height: 1.4),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
