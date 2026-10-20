import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart' show AppLanguage;
import '../theme/app_theme.dart' show AppSkin;
import '../theme/label_colors.dart';

/// Small app settings saved on the phone: custom game images, game order,
/// label colours and the last game scanned.
class SettingsStore extends ChangeNotifier {
  SettingsStore({this.file, this.imageDir});

  final File? file;
  final Directory? imageDir;

  final Map<String, String> _gameImages = {};
  String? _lastScanGame;

  /// The user's order of games (ids); games not listed follow in the
  /// default order.
  List<String> _gameOrder = [];
  final Set<String> _hiddenGames = {};
  final Map<String, int> _labelColors = {};
  bool _isPro = false;
  String _artDay = '';
  int _artCount = 0;
  String _language = AppLanguage.system;
  AppSkin _skin = AppSkin.classic;

  Future<void> load() async {
    _applyLanguage();
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
      final order = json['gameOrder'];
      if (order is List) _gameOrder = order.whereType<String>().toList();
      _isPro = json['isPro'] == true;
      _artDay = json['artDay'] as String? ?? '';
      _artCount = (json['artCount'] as num?)?.toInt() ?? 0;
      _skin = AppSkin.byName(json['skin'] as String?);
      final lang = json['language'];
      if (lang is String && (lang == 'en' || lang == 'de')) _language = lang;
      _applyLanguage();
      final colors = json['labelColors'];
      if (colors is Map) {
        colors.forEach((k, v) {
          if (k is String && v is int) _labelColors[k.toLowerCase()] = v;
        });
      }
      final hidden = json['hiddenGames'];
      if (hidden is List) _hiddenGames.addAll(hidden.whereType<String>());
    } on Object catch (e) {
      debugPrint('Could not read settings: $e');
    }
    notifyListeners();
  }

  /// Pro unlocks card text in every language and scanning
  /// by artwork. (Purchases are not connected yet; the Pro screen has a test
  /// switch in debug builds.)
  bool get isPro => _isPro;

  /// The look the user chose. Without Pro the app always looks Classic.
  AppSkin get skin => _skin;

  AppSkin get activeSkin => _isPro ? _skin : AppSkin.classic;

  /// Free artwork scans a day for Magic (Scryfall does not allow its data
  /// to be put behind a paywall, so Magic gets a free daily allowance).
  static const freeMagicArtScansPerDay = 10;

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// How many free Magic artwork scans are left today.
  int get magicArtScansLeft {
    final used = _artDay == _today() ? _artCount : 0;
    return (freeMagicArtScansPerDay - used).clamp(0, freeMagicArtScansPerDay);
  }

  /// Counts one Magic artwork scan for today.
  void useMagicArtScan() {
    final today = _today();
    if (_artDay != today) {
      _artDay = today;
      _artCount = 0;
    }
    _artCount++;
    _save();
  }

  void setSkin(AppSkin value) {
    if (_skin == value) return;
    _skin = value;
    _save();
  }

  /// `system`, `en` or `de`.
  String get language => _language;

  void setLanguage(String value) {
    _language = value;
    _applyLanguage();
    _save();
  }

  void _applyLanguage() {
    AppLanguage.current = AppLanguage.resolve(
      _language,
      WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
  }

  void setPro(bool value) {
    if (_isPro == value) return;
    _isPro = value;
    _save();
  }


  /// The colour of a label: the one the user picked, or a steady default.
  Color labelColor(String label) {
    final stored = _labelColors[label.toLowerCase()];
    return stored == null ? defaultLabelColor(label) : Color(stored);
  }

  void setLabelColor(String label, Color color) {
    _labelColors[label.toLowerCase()] = color.toARGB32();
    _save();
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

  void _save() {
    notifyListeners();
    final f = file;
    if (f == null) return;
    final json = jsonEncode({
      'gameImages': _gameImages,
      'lastScanGame': _lastScanGame,
      'gameOrder': _gameOrder,
      'hiddenGames': _hiddenGames.toList(),
      'labelColors': _labelColors,
      'isPro': _isPro,
      'artDay': _artDay,
      'artCount': _artCount,
      'language': _language,
      'skin': _skin.name,
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
