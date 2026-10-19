import 'dart:io';

import 'package:flutter/material.dart';

import '../models/collection.dart';
import '../theme/app_theme.dart';

/// Shows the user's own scan of a card. Until scanning exists, entries carry a
/// demo colour and we draw a simple card silhouette instead.
class CardPhoto extends StatelessWidget {
  const CardPhoto({super.key, required this.entry, this.scale = 1});

  final CollectionEntry entry;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final path = entry.photoPath;
    if (path != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4 * scale),
        child: Image.file(File(path), fit: BoxFit.cover),
      );
    }
    final color = entry.demoColor ?? tokens.muted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.cardEdge,
        borderRadius: BorderRadius.circular(4 * scale),
        boxShadow: const [
          BoxShadow(color: Color(0x2E000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3 * scale),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 5 * scale,
              vertical: 6 * scale,
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final line = Colors.white.withValues(alpha: 0.42);
                Widget bar(double widthFactor) => FractionallySizedBox(
                      widthFactor: widthFactor,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 4 * scale,
                        decoration: BoxDecoration(
                          color: line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    bar(0.62),
                    SizedBox(height: 4 * scale),
                    Container(
                      height: box.maxHeight * 0.44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    bar(0.9),
                    SizedBox(height: 4 * scale),
                    bar(0.7),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
