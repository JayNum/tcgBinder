import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A small fingerprint of a card's artwork: a 64-bit difference hash of the
/// picture area plus a 3×3 grid of average colours. Two photos of the same
/// artwork give fingerprints that are close; different artworks are far apart.
class ArtPrint {
  const ArtPrint(this.hash, this.colors);

  /// 64 bits, one per neighbouring pair of pixels in a 9×8 grey picture.
  final BigInt hash;

  /// 27 numbers: red, green, blue of each cell of a 3×3 grid (0–255).
  final List<int> colors;

  String encode() => '${hash.toRadixString(16)}:${colors.join(',')}';

  static ArtPrint? decode(String text) {
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final hash = BigInt.tryParse(parts[0], radix: 16);
    final colors = parts[1].split(',').map(int.tryParse).toList();
    if (hash == null || colors.length != 27 || colors.contains(null)) return null;
    return ArtPrint(hash, colors.cast<int>());
  }

  /// 0 = identical, 1 = completely different.
  double distanceTo(ArtPrint other) {
    var bits = 0;
    var x = hash ^ other.hash;
    while (x > BigInt.zero) {
      if ((x & BigInt.one) == BigInt.one) bits++;
      x >>= 1;
    }
    var colour = 0;
    for (var i = 0; i < 27; i++) {
      colour += (colors[i] - other.colors[i]).abs();
    }
    return 0.65 * (bits / 64) + 0.35 * (colour / (27 * 255));
  }
}

/// Where the picture sits on a card, as fractions of the card
/// (left, top, width, height). Close enough for matching, not exact.
({double l, double t, double w, double h}) artRegion(String gameId) =>
    switch (gameId) {
      'pokemon' => (l: 0.07, t: 0.11, w: 0.86, h: 0.40),
      'magic' => (l: 0.08, t: 0.11, w: 0.84, h: 0.43),
      'onepiece' => (l: 0.09, t: 0.16, w: 0.82, h: 0.44),
      'lorcana' => (l: 0.08, t: 0.10, w: 0.84, h: 0.52),
      _ => (l: 0.08, t: 0.12, w: 0.84, h: 0.46),
    };

/// Fingerprint of the artwork in a picture of a whole card.
/// Null when the bytes are not an image this app can read.
ArtPrint? artPrintOf(Uint8List bytes, String gameId) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final r = artRegion(gameId);
  final x = (decoded.width * r.l).round();
  final y = (decoded.height * r.t).round();
  final w = (decoded.width * r.w).round().clamp(1, decoded.width - x);
  final h = (decoded.height * r.h).round().clamp(1, decoded.height - y);
  final art = img.copyCrop(decoded, x: x, y: y, width: w, height: h);

  // Difference hash.
  final grey = img.grayscale(img.copyResize(
    art,
    width: 9,
    height: 8,
    interpolation: img.Interpolation.average,
  ));
  var hash = BigInt.zero;
  for (var row = 0; row < 8; row++) {
    for (var col = 0; col < 8; col++) {
      hash <<= 1;
      if (grey.getPixel(col, row).luminance > grey.getPixel(col + 1, row).luminance) {
        hash |= BigInt.one;
      }
    }
  }

  // Average colours.
  final small = img.copyResize(
    art,
    width: 3,
    height: 3,
    interpolation: img.Interpolation.average,
  );
  final colors = <int>[];
  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 3; col++) {
      final p = small.getPixel(col, row);
      colors
        ..add(p.r.toInt())
        ..add(p.g.toInt())
        ..add(p.b.toInt());
    }
  }
  return ArtPrint(hash, colors);
}

/// A card and how close its artwork is to the photo.
class ArtMatch {
  const ArtMatch(this.cardId, this.distance);
  final String cardId;
  final double distance;
}

/// The closest cards, nearest first. Cards of equal artwork (alt arts of the
/// same picture) all show up, so the user picks the right version.
List<ArtMatch> rankArt(
  ArtPrint photo,
  Map<String, ArtPrint> candidates, {
  int limit = 3,
  double maxDistance = 0.32,
}) {
  final all = [
    for (final e in candidates.entries) ArtMatch(e.key, photo.distanceTo(e.value)),
  ]..sort((a, b) => a.distance.compareTo(b.distance));
  return all.where((m) => m.distance <= maxDistance).take(limit).toList();
}
