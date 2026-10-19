import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

/// Small app settings saved on the phone: custom game images, the last game
/// scanned, and the counter for full-screen ads.
class SettingsStore extends ChangeNotifier {
  SettingsStore({this.file, this.imageDir});

  final File? file;
  final Directory? imageDir;

  final Map<String, String> _gameImages = {};
  String? _lastScanGame;
  int _addsSinceAd = 0;

  /// The user's order of games (ids); games not listed follow in the
  /// default order.
  List<String> _gameOrder = [];
  final Set<String> _hiddenGames = {};

  Future<void> load() async {
    final f = file;
    if (f == null || !f.existsSync()) return;
    try {
      final json = jsonDecode(await f.readAsString());
      if (json is! Map) return;
      final images = json['gameImages'];
      if (images is Map) {
        images.forEach((k, v) {
          if (k is String && v is String && File(v).existsSync()) {
            _gameImages[k] = v;
          }
        });
      }
      _lastScanGame = json['lastScanGame'] as String?;
      _addsSinceAd = (json['addsSinceAd'] as num?)?.toInt() ?? 0;
      final order = json['gameOrder'];
      if (order is List) _gameOrder = order.whereType<String>().toList();
      final hidden = json['hiddenGames'];
      if (hidden is List) _hiddenGames.addAll(hidden.whereType<String>());
    } on Object catch (e) {
      debugPrint('Could not read settings: $e');
    }
    notifyListeners();
  }

  String? gameImage(String gameId) => _gameImages[gameId];

  /// [allIds] in the user's order.
  List<String> orderedGameIds(List<String> allIds) {
    final ordered = [
      for (final id in _gameOrder)
        if (allIds.contains(id)) id,
    ];
    for (final id in allIds) {
      if (!ordered.contains(id)) ordered.add(id);
    }
    return ordered;
  }

  void setGameOrder(List<String> ids) {
    _gameOrder = List.of(ids);
    _save();
  }

  bool isGameHidden(String gameId) => _hiddenGames.contains(gameId);

  void setGameHidden(String gameId, bool hidden) {
    final changed =
        hidden ? _hiddenGames.add(gameId) : _hiddenGames.remove(gameId);
    if (changed) _save();
  }

  void setGameImage(String gameId, String? path) {
    final old = _gameImages[gameId];
    if (path == null) {
      _gameImages.remove(gameId);
    } else {
      _gameImages[gameId] = path;
    }
    if (old != null && old != path) {
      try {
        File(old).deleteSync();
      } on Object catch (_) {}
    }
    _save();
  }

  String newImagePath(String gameId) {
    final dir = imageDir ?? Directory.systemTemp;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}${Platform.pathSeparator}game_${gameId}_$stamp.jpg';
  }

  String? get lastScanGame => _lastScanGame;

  set lastScanGame(String? gameId) {
    if (_lastScanGame == gameId) return;
    _lastScanGame = gameId;
    _save();
  }

  /// Counts an added card; true when a full-screen ad is due (every 3rd).
  bool countAddForAd() {
    _addsSinceAd++;
    final due = _addsSinceAd >= 3;
    if (due) _addsSinceAd = 0;
    _save();
    return due;
  }

  void _save() {
    notifyListeners();
    final f = file;
    if (f == null) return;
    final json = jsonEncode({
      'gameImages': _gameImages,
      'lastScanGame': _lastScanGame,
      'addsSinceAd': _addsSinceAd,
      'gameOrder': _gameOrder,
      'hiddenGames': _hiddenGames.toList(),
    });
    f.parent
        .create(recursive: true)
        .then((_) => f.writeAsString(json))
        .catchError((Object e) {
      debugPrint('Could not save settings: $e');
      return f;
    });
  }
}

class SettingsScope extends InheritedNotifier<SettingsStore> {
  const SettingsScope({
    super.key,
    required SettingsStore store,
    required super.child,
  }) : super(notifier: store);

  static SettingsStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'No SettingsScope above this widget');
    return scope!.notifier!;
  }
}
