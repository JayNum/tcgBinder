import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The user's own photo of a card, filling its pocket like a sleeved card.
class CardPhoto extends StatelessWidget {
  const CardPhoto({super.key, required this.path, this.radius = 4});

  final String path;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth.isFinite ? box.maxWidth : 300.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // Decode at the size it's shown: keeps binder pages smooth.
            cacheWidth: (width * dpr).round().clamp(64, 1200),
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) => ColoredBox(
              color: context.binder.pocket,
              child: Icon(
                Icons.broken_image_outlined,
                color: context.binder.labelMissing,
              ),
            ),
          ),
        );
      },
    );
  }
}
