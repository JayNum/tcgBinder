import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/collection_store.dart';
import '../data/sample_catalog.dart';
import '../models/catalog.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    final store = CollectionScope.of(context);
    final game = gameById(widget.set.gameId);
    final cards = cardsInSet(widget.set.id);
    final owned = store.ownedIn(cards);
    final pageCount = math.max(1, (cards.length / _perPage).ceil());
    final percent = cards.isEmpty ? 0 : (owned * 100 / cards.length).round();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.set.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              '${game.name} · ${widget.set.code} · ${widget.set.printedTotal} cards',
              style: TextStyle(fontSize: 12, color: tokens.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search this set',
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$owned',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: tokens.text,
                              ),
                            ),
                            TextSpan(text: ' of ${cards.length} collected'),
                          ],
                        ),
                        style: TextStyle(fontSize: 12, color: tokens.muted),
                      ),
                      const Spacer(),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: cards.isEmpty ? 0.0 : owned / cards.length,
                      minHeight: 6,
                      backgroundColor: tokens.pocketBorder,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pageCount,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, page) {
                  final start = page * _perPage;
                  final pageCards = cards.sublist(
                    start,
                    math.min(start + _perPage, cards.length),
                  );
                  return _BinderPage(set: widget.set, cards: pageCards);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: _page > 0 ? () => _goTo(_page - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  'Page ${_page + 1} of $pageCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.muted,
                  ),
                ),
                IconButton(
                  tooltip: 'Next page',
                  onPressed:
                      _page < pageCount - 1 ? () => _goTo(_page + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const AdBannerPlaceholder(),
          ],
        ),
      ),
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
        set: set,
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
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.border),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
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
