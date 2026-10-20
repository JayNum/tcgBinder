import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/catalog.dart';
import 'art_hash.dart';

class _Job {
  const _Job(this.bytes, this.gameId);
  final Uint8List bytes;
  final String gameId;
}

String? _fingerprintJob(_Job job) => artPrintOf(job.bytes, job.gameId)?.encode();

/// Fingerprints of the artwork of every card in the sets the user has
/// prepared. Saved on the phone; built once per set from the card pictures
/// the databases publish.
class ArtIndex {
  ArtIndex({required this.dir, http.Client? client})
      : client = client ?? http.Client();

  /// Folder for the saved fingerprints; null = memory only.
  final Directory? dir;
  final http.Client client;

  final _byset = <String, Map<String, ArtPrint>>{};

  bool hasSet(String setId) => _byset.containsKey(setId) || _file(setId)?.existsSync() == true;

  /// Fingerprints of one set (loaded from disk when needed).
  Map<String, ArtPrint> forSet(String setId) {
    final known = _byset[setId];
    if (known != null) return known;
    final file = _file(setId);
    final map = <String, ArtPrint>{};
    if (file != null && file.existsSync()) {
      try {
        final json = jsonDecode(file.readAsStringSync());
        if (json is Map) {
          json.forEach((k, v) {
            final p = v is String ? ArtPrint.decode(v) : null;
            if (p != null) map[k as String] = p;
          });
        }
      } on Object catch (e) {
        debugPrint('Broken art index for $setId: $e');
      }
    }
    return _byset[setId] = map;
  }

  /// Downloads the pictures of [cards] and saves their fingerprints.
  /// [onProgress] gets (done, total). [isCancelled] stops early (what is done
  /// so far is kept).
  Future<void> build(
    String setId,
    List<CatalogCard> cards, {
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final map = forSet(setId);
    final todo = [
      for (final c in cards)
        if (c.imageUrl != null && !map.containsKey(c.id)) c,
    ];
    var done = 0;
    onProgress?.call(0, todo.length);

    Future<void> one(CatalogCard card) async {
      try {
        final r = await client
            .get(Uri.parse(card.imageUrl!))
            .timeout(const Duration(seconds: 25));
        if (r.statusCode != 200) return;
        final encoded =
            await compute(_fingerprintJob, _Job(r.bodyBytes, card.gameId));
        final print = encoded == null ? null : ArtPrint.decode(encoded);
        if (print != null) map[card.id] = print;
      } on Object catch (_) {
        // A picture that fails is simply left out.
      }
    }

    // Four at a time keeps the phone and the server comfortable.
    for (var i = 0; i < todo.length; i += 4) {
      if (isCancelled?.call() == true) break;
      await Future.wait(todo.skip(i).take(4).map(one));
      done = (i + 4).clamp(0, todo.length);
      onProgress?.call(done, todo.length);
    }
    _save(setId, map);
  }

  File? _file(String setId) {
    final d = dir;
    if (d == null) return null;
    final safe = setId.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    return File('${d.path}${Platform.pathSeparator}$safe.json');
  }

  void _save(String setId, Map<String, ArtPrint> map) {
    final file = _file(setId);
    if (file == null) return;
    try {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        jsonEncode({for (final e in map.entries) e.key: e.value.encode()}),
      );
    } on Object catch (e) {
      debugPrint('Could not save art index: $e');
    }
  }
}

/// Fingerprint of a photo of a card, computed off the main isolate.
Future<ArtPrint?> fingerprintPhoto(Uint8List bytes, String gameId) async {
  final encoded = await compute(_fingerprintJob, _Job(bytes, gameId));
  return encoded == null ? null : ArtPrint.decode(encoded);
}
