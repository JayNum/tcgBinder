import 'package:flutter/material.dart';

import 'favorites_carousel.dart';

/// A row of small cards. Five fit on screen; with more than five it scrolls
/// sideways and loops, so you can keep going in either direction.
class RecentStrip extends StatefulWidget {
  const RecentStrip({super.key, required this.items, required this.onOpen});

  /// The newest cards first (the caller keeps it to the last 10).
  final List<FavoriteItem> items;
  final ValueChanged<FavoriteItem> onOpen;

  static const visible = 5;
  static const gap = 8.0;
  static const sidePadding = 16.0;

  @override
  State<RecentStrip> createState() => _RecentStripState();
}

class _RecentStripState extends State<RecentStrip> {
  static const _repeats = 200000;
  ScrollController? _controller;
  double _extent = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final n = items.length;
    if (n == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, box) {
        const gap = RecentStrip.gap;
        const pad = RecentStrip.sidePadding;
        final tile =
            (box.maxWidth - pad * 2 - gap * (RecentStrip.visible - 1)) /
                RecentStrip.visible;
        final height = tile * 88 / 63 + 26;

        Widget cell(FavoriteItem item) => SizedBox(
              width: tile,
              child: Semantics(
                button: true,
                label: item.title,
                child: GestureDetector(
                  onTap: () => widget.onOpen(item),
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CardFace(item: item, radius: 5),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

        // Up to five cards: they just sit in a row.
        if (n <= RecentStrip.visible) {
          return SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: pad),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in items) ...[
                    cell(item),
                    const SizedBox(width: gap),
                  ],
                ],
              ),
            ),
          );
        }

        // More than five: an endless strip made of the same cards again and
        // again. It starts in the middle so both directions work.
        final extent = tile + gap;
        if (_controller == null || _extent != extent) {
          _controller?.dispose();
          _extent = extent;
          _controller = ScrollController(
            initialScrollOffset: extent * (_repeats ~/ 2 - (_repeats ~/ 2) % n),
          );
        }
        return SizedBox(
          height: height,
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: pad),
            itemExtent: extent,
            itemCount: _repeats,
            itemBuilder: (context, i) => Align(
              alignment: Alignment.topLeft,
              child: cell(items[i % n]),
            ),
          ),
        );
      },
    );
  }
}
