import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/catalog.dart';
import '../models/collection.dart';
import '../theme/app_theme.dart';
import '../theme/game_colors.dart';
import 'card_photo.dart';

/// A favorite card: what the user saved, plus the catalog card (name, code)
/// when its set is downloaded.
class FavoriteItem {
  const FavoriteItem({required this.entry, this.card, this.set});

  final CollectionEntry entry;
  final CatalogCard? card;
  final CardSet? set;

  String get title => card?.name ?? 'Saved card';
  String get code => card?.code ?? '';
}

/// A card as it looks in the carousel and the grid: the user's photo, or a
/// coloured card showing the code and name when there is no photo yet.
class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.item, this.radius = 10});

  final FavoriteItem item;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = item.entry.photoPath;
    final color = gameColor(item.entry.gameId);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 63 / 88,
        child: photo != null
            ? CardPhoto(path: photo, radius: radius)
            : ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, Color.lerp(color, Colors.black, 0.45)!],
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      // Everything scales with the card, so small cards in
                      // a row never overflow.
                      final k = (box.maxWidth / 190).clamp(0.3, 1.2).toDouble();
                      return Padding(
                        padding: EdgeInsets.all(10 * k),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: numberStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                size: math.max(6.5, 12 * k),
                              ),
                            ),
                            SizedBox(height: 6 * k),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: math.max(8, 15 * k),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

/// Favorite cards in one flat row that drifts slowly to the left by itself
/// and loops endlessly. Touch it to scroll either way; it carries on drifting
/// a moment after you let go. Tap a card to open it.
class FavoritesCarousel extends StatefulWidget {
  const FavoritesCarousel({
    super.key,
    required this.items,
    required this.onOpen,
    this.height = 400,
  });

  final List<FavoriteItem> items;
  final ValueChanged<FavoriteItem> onOpen;
  final double height;

  @override
  State<FavoritesCarousel> createState() => _FavoritesCarouselState();
}

class _FavoritesCarouselState extends State<FavoritesCarousel>
    with SingleTickerProviderStateMixin {
  static const _repeats = 200000;

  /// Pixels per second while drifting.
  static const _drift = 26.0;

  late final Ticker _ticker;
  ScrollController? _controller;
  double _extent = 0;
  Duration _last = Duration.zero;
  bool _touching = false;
  bool _reduceMotion = false;
  DateTime _resumeAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final c = _controller;
    if (c == null || !c.hasClients || dt <= 0 || dt > 0.25) return;
    if (_touching || _reduceMotion || widget.items.length < 2) return;
    if (DateTime.now().isBefore(_resumeAt)) return;
    // Do not fight a fling that is still coasting.
    if (c.position.isScrollingNotifier.value) return;
    c.jumpTo(c.offset + _drift * dt);
  }

  void _pause() {
    _touching = true;
  }

  void _release() {
    _touching = false;
    _resumeAt = DateTime.now().add(const Duration(milliseconds: 1500));
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final n = items.length;
    if (n == 0) return SizedBox(height: widget.height);

    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        const gap = 14.0;
        final cardWidth = math.min(width * 0.5, widget.height * 0.62);
        final extent = cardWidth + gap;
        final rowHeight = cardWidth * 88 / 63 + 40;

        Widget cell(FavoriteItem item) => Padding(
              padding: const EdgeInsets.only(right: gap),
              child: SizedBox(
                width: cardWidth,
                child: Semantics(
                  button: true,
                  label: item.title,
                  child: GestureDetector(
                    onTap: () => widget.onOpen(item),
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RepaintBoundary(child: CardFace(item: item)),
                          const SizedBox(height: 10),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );

        // One card: just show it in the middle.
        if (n == 1) {
          return SizedBox(
            height: rowHeight,
            child: Center(child: cell(items.first)),
          );
        }

        if (_controller == null || _extent != extent) {
          _controller?.dispose();
          _extent = extent;
          _controller = ScrollController(
            initialScrollOffset: extent * (_repeats ~/ 2 - (_repeats ~/ 2) % n),
          );
        }
        return SizedBox(
          height: rowHeight,
          child: Listener(
            onPointerDown: (_) => _pause(),
            onPointerUp: (_) => _release(),
            onPointerCancel: (_) => _release(),
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: (width - cardWidth) / 2),
              itemExtent: extent,
              itemCount: _repeats,
              itemBuilder: (context, i) => cell(items[i % n]),
            ),
          ),
        );
      },
    );
  }
}
