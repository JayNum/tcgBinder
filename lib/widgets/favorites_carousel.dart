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

/// Favorite cards on a ring that turns slowly by itself. The user can drag
/// it, flick it, or tap a side card to bring it to the front; tapping the
/// front card opens it.
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
  /// Cards per second when nobody touches it: one card every ~7 seconds.
  static const _autoSpeed = 0.14;

  /// Angle between two neighbouring cards on the ring.
  static const _step = 0.62;

  /// How many pixels of dragging move the ring by one card.
  static const _pixelsPerCard = 120.0;

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  /// Position of the ring, in cards. Card `i` is in front when `_pos == i`.
  final ValueNotifier<double> _pos = ValueNotifier<double>(0);

  /// Faces are built once and reused every frame, so turning the ring only
  /// moves already painted cards.
  List<Widget> _faces = const [];
  List<FavoriteItem>? _facesFor;

  /// Current speed in cards per second; eases back to the automatic speed
  /// after a flick.
  double _speed = _autoSpeed;
  bool _dragging = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _wake();
  }

  @override
  void didUpdateWidget(FavoritesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _wake();
  }

  /// The ticker rests when there is nothing to animate (one card, or
  /// reduced motion), so idle screens cost no battery. Touch wakes it.
  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pos.dispose();
    super.dispose();
  }

  double get _restSpeed =>
      (_reduceMotion || widget.items.length < 2) ? 0 : _autoSpeed;

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_dragging || dt <= 0 || dt > 0.5) return;
    final rest = _restSpeed;
    if (_speed == rest && rest == 0) {
      _ticker.stop();
      return;
    }
    // Ease the speed back to the slow automatic turn.
    _speed += (rest - _speed) * (1 - math.exp(-1.6 * dt));
    if ((_speed - rest).abs() < 0.001) _speed = rest;
    _pos.value += _speed * dt;
  }

  int get _frontIndex {
    final n = widget.items.length;
    return ((_pos.value.round() % n) + n) % n;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final n = items.length;
    if (n == 0) return SizedBox(height: widget.height);

    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final cardWidth = math.min(width * 0.52, widget.height * 0.62);
        final radius = width * 0.36;

        if (!identical(_facesFor, items)) {
          _facesFor = items;
          _faces = [
            for (final item in items)
              RepaintBoundary(
                child: SizedBox(
                  width: cardWidth,
                  child: ExcludeSemantics(child: CardFace(item: item)),
                ),
              ),
          ];
        }

        return Semantics(
          label: 'Favorite cards, $n. Swipe to turn, double tap to open.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) {
              _dragging = true;
              _wake();
            },
            onHorizontalDragUpdate: (details) =>
                _pos.value -= details.delta.dx / _pixelsPerCard,
            onHorizontalDragEnd: (details) {
              _dragging = false;
              _speed = (-(details.primaryVelocity ?? 0) / _pixelsPerCard)
                  .clamp(-4.0, 4.0)
                  .toDouble();
              _wake();
            },
            onHorizontalDragCancel: () => _dragging = false,
            onTapUp: (details) {
              final dx = details.localPosition.dx - width / 2;
              if (dx.abs() < cardWidth / 2 || n == 1) {
                widget.onOpen(items[_frontIndex]);
              } else {
                // A tap on a side card spins it to the front.
                _speed = dx > 0 ? 2.2 : -2.2;
                _wake();
              }
            },
            child: SizedBox(
              height: widget.height,
              width: width,
              child: ValueListenableBuilder<double>(
                valueListenable: _pos,
                builder: (context, pos, _) {
                  // Distance of every card from the front, wrapped around
                  // the ring.
                  final placed = <({int index, double d})>[];
                  for (var i = 0; i < n; i++) {
                    var d = (i - pos) % n;
                    if (d > n / 2) d -= n;
                    if (d.abs() * _step < 1.5) placed.add((index: i, d: d));
                  }
                  // Far cards first, so the nearest one is painted on top.
                  placed.sort((a, b) => b.d.abs().compareTo(a.d.abs()));
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final p in placed)
                        _positioned(_faces[p.index], p.d, radius),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _positioned(Widget face, double d, double radius) {
    final angle = d * _step;
    final depth = math.cos(angle).clamp(0.0, 1.0).toDouble();
    final scale = 0.55 + 0.45 * depth;
    final tilt = Matrix4.rotationY(-angle * 0.8)..setEntry(3, 2, 0.0012);
    // Cards further back are darkened instead of faded: no extra layer.
    final shade = (1 - depth) * 0.55;
    return Transform.translate(
      offset: Offset(math.sin(angle) * radius, 0),
      child: Transform.scale(
        scale: scale,
        child: Transform(
          alignment: Alignment.center,
          transform: tilt,
          child: Stack(
            children: [
              face,
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black.withValues(alpha: shade),
                    ),
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
