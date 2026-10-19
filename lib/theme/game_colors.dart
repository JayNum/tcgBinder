import 'package:flutter/painting.dart';

/// Default tile / binder cover colour per game.
const gameColors = <String, Color>{
  'onepiece': Color(0xFFB42318),
  'pokemon': Color(0xFF2B50D6),
  'magic': Color(0xFF3A3A40),
  'lorcana': Color(0xFF6B46A8),
  'riftbound': Color(0xFF1F6B45),
};

Color gameColor(String gameId) => gameColors[gameId] ?? const Color(0xFF2B50D6);
