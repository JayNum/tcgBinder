import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/collection.dart';
import '../theme/app_theme.dart';
import 'card_photo.dart';

/// One binder pocket: set number above, the sleeve, card name below.
class Pocket extends StatelessWidget {
  const Pocket({
    super.key,
    required this.card,
    required this.set,
    this.entry,
    this.onTap,
  });

  final CatalogCard card;
  final CardSet set;
  final CollectionEntry? entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final owned = entry != null;
    final labelColor = owned ? tokens.text : tokens.labelMissing;
    final number = card.printedNumber(set);

    return Semantics(
      button: true,
      label: '$number ${card.name}, ${owned ? 'owned' : 'missing'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 14,
                child: Text(
                  number,
                  maxLines: 1,
                  style: numberStyle(color: labelColor),
                ),
              ),
              const SizedBox(height: 4),
              AspectRatio(
                aspectRatio: 63 / 88,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.pocket,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tokens.pocketBorder),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: _content(context),
                        ),
                      ),
                    ),
                    if ((entry?.quantity ?? 0) > 1)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: _QuantityBadge(quantity: entry!.quantity),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 14,
                child: Text(
                  card.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 14 / 12,
                    fontWeight: owned ? FontWeight.w700 : FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final e = entry;
    if (e == null) return const SizedBox.expand();
    if (e.hasPhoto) return CardPhoto(entry: e);
    final tokens = context.binder;
    return Container(
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_outlined, size: 22, color: context.accent),
          const SizedBox(height: 6),
          Text(
            'Owned · add photo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: tokens.accentSoftText,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.accent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.binder.surface, width: 2),
      ),
      child: Text(
        '×$quantity',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.onAccent,
        ),
      ),
    );
  }
}
