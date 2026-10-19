import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/catalog.dart';

/// Downloads sets and cards of one game from a public card database.
abstract class CatalogSource {
  CatalogSource(this.client);

  final http.Client client;

  String get gameId;

  Future<List<CardSet>> fetchSets();

  Future<List<CatalogCard>> fetchCards(CardSet set);

  /// Every printing of [card] across all sets, when the database can look
  /// that up directly. Null means "use what's already downloaded".
  Future<List<CatalogCard>?> fetchVersions(
    CatalogCard card,
    List<CardSet> sets,
  ) async =>
      null;

  /// GET a URL and decode its JSON. Throws [CatalogException] on failure.
  Future<Object?> getJson(Uri uri, {bool allowNotFound = false}) async {
    final http.Response response;
    try {
      response = await client.get(uri, headers: const {
        'Accept': 'application/json',
        'User-Agent': 'TCGBinder/0.2',
      }).timeout(const Duration(seconds: 40));
    } on Exception catch (e) {
      throw CatalogException('Could not reach ${uri.host}: $e');
    }
    if (allowNotFound && response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw CatalogException(
        '${uri.host} answered ${response.statusCode}',
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

class CatalogException implements Exception {
  CatalogException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Small helpers for reading loosely typed JSON.
extension JsonMap on Map<String, Object?> {
  String str(String key) => (this[key] ?? '').toString().trim();

  String? strOrNull(String key) {
    final v = this[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  Map<String, Object?> obj(String key) {
    final v = this[key];
    return v is Map ? v.cast<String, Object?>() : const {};
  }
}

List<Map<String, Object?>> asMapList(Object? json) {
  if (json is List) {
    return json.whereType<Map>().map((m) => m.cast<String, Object?>()).toList();
  }
  return const [];
}

/// Parses `2023-08-18`, `1999/01/09` or ISO timestamps; null if unknown.
DateTime? parseDate(String? text) {
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceAll('/', '-'));
}

String titleCase(String text) => text
    .replaceAll('_', ' ')
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');
