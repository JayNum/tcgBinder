import 'package:flutter/painting.dart';

/// Colours a label can have: the iOS system colours.
const labelPalette = <Color>[
  Color(0xFFFF3B30), // red
  Color(0xFFFF9500), // orange
  Color(0xFFFFCC00), // yellow
  Color(0xFF34C759), // green
  Color(0xFF00C7BE), // mint
  Color(0xFF32ADE6), // cyan
  Color(0xFF007AFF), // blue
  Color(0xFF5856D6), // indigo
  Color(0xFFAF52DE), // purple
  Color(0xFFFF2D55), // pink
  Color(0xFFA2845E), // brown
  Color(0xFF8E8E93), // grey
];

/// A colour for a label nobody coloured yet: always the same one for the
/// same name, so labels are colourful from the start.
Color defaultLabelColor(String label) {
  var hash = 0;
  for (final unit in label.toLowerCase().codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return labelPalette[hash % labelPalette.length];
}

/// Text colour that reads well on [background].
Color onColor(Color background) => background.computeLuminance() > 0.55
    ? const Color(0xFF1C1C1E)
    : const Color(0xFFFFFFFF);
