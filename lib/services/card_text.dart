import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/catalog.dart';

/// The printed name and rules text of a card in one language.
class CardText {
  const CardText({required this.language, required this.name, required this.text});

  final String language;
  final String name;
  final String text;

  bool get isEmpty => text.trim().isEmpty;
}

/// Looks up the text of a card in other languages.
///
/// Only Magic (Scryfall) and Pokémon (TCGdex) publish this for free. The
/// other games give English only, which is already stored with the card.
/// Nothing is saved: it is fetched when the user opens the section.
class CardTextService {
  CardTextService([http.Client? client]) : client = client ?? http.Client();

  final http.Client client;

  /// Scryfall language codes.
  static const magicCodes = {
    'English': 'en',
    'German': 'de',
    'French': 'fr',
    'Italian': 'it',
    'Spanish': 'es',
    'Portuguese': 'pt',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Chinese': 'zhs',
  };

  /// TCGdex language codes.
  static const pokemonCodes = {
    'English': 'en',
    'German': 'de',
    'French': 'fr',
    'Italian': 'it',
    'Spanish': 'es',
    'Portuguese': 'pt',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Chinese': 'zh-tw',
  };

  /// Which languages we can offer for this card.
  static List<String> languagesFor(CatalogCard card) {
    switch (card.gameId) {
      case 'magic':
        return magicCodes.keys.toList();
      case 'pokemon':
        return pokemonCodes.keys.toList();
      default:
        return const ['English'];
    }
  }

  /// English text comes with the card list; no network needed.
  static CardText? english(CatalogCard card) => card.text == null
      ? null
      : CardText(language: 'English', name: card.fullName, text: card.text!);

  /// Fetches one language. Null when the database has no such printing.
  Future<CardText?> fetch(CatalogCard card, CardSet set, String language) async {
    if (language == 'English' && card.text != null) return english(card);
    try {
      switch (card.gameId) {
        case 'magic':
          return await _magic(card, set, language);
        case 'pokemon':
          return await _pokemon(card, set, language);
      }
    } on Exception {
      return null;
    }
    return null;
  }

  Future<Object?> _get(Uri uri) async {
    final r = await client.get(uri, headers: const {
      'Accept': 'application/json',
      'User-Agent': 'TCGBinder/0.4',
    }).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) return null;
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  Future<CardText?> _magic(CatalogCard card, CardSet set, String language) async {
    final code = magicCodes[language];
    if (code == null) return null;
    final number = card.code.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final json = await _get(Uri.https('api.scryfall.com', '/cards/search', {
      'q': 'e:${set.sourceId} cn:$number lang:$code',
      'include_multilingual': 'true',
      'unique': 'prints',
    }));
    return parseScryfall(json, language);
  }

  /// Picks the first card of a Scryfall search answer.
  static CardText? parseScryfall(Object? json, String language) {
    if (json is! Map) return null;
    final data = json['data'];
    if (data is! List || data.isEmpty || data.first is! Map) return null;
    final c = (data.first as Map).cast<String, Object?>();
    String name(Map<String, Object?> m) =>
        (m['printed_name'] ?? m['name'] ?? '').toString();
    String text(Map<String, Object?> m) =>
        (m['printed_text'] ?? m['oracle_text'] ?? '').toString();

    final faces = c['card_faces'];
    if (text(c).isEmpty && faces is List && faces.isNotEmpty) {
      final parts = [
        for (final f in faces.whereType<Map>())
          '${name(f.cast<String, Object?>())}\n${text(f.cast<String, Object?>())}',
      ];
      return CardText(language: language, name: name(c), text: parts.join('\n\n'));
    }
    final t = CardText(language: language, name: name(c), text: text(c));
    return t.isEmpty ? null : t;
  }

  Future<CardText?> _pokemon(CatalogCard card, CardSet set, String language) async {
    final code = pokemonCodes[language];
    if (code == null) return null;
    final number = card.code.split('/').first;
    // TCGdex numbers are sometimes padded ("004"), sometimes not ("4").
    for (final n in {number, number.padLeft(3, '0')}) {
      final json = await _get(
        Uri.https('api.tcgdex.net', '/v2/$code/cards/${set.sourceId}-$n'),
      );
      final parsed = parseTcgdex(json, language);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static CardText? parseTcgdex(Object? json, String language) {
    if (json is! Map) return null;
    final c = json.cast<String, Object?>();
    final lines = <String>[];
    final abilities = c['abilities'];
    if (abilities is List) {
      for (final a in abilities.whereType<Map>()) {
        lines.add('${a['name'] ?? ''}: ${a['effect'] ?? ''}');
      }
    }
    final attacks = c['attacks'];
    if (attacks is List) {
      for (final a in attacks.whereType<Map>()) {
        final damage = a['damage'] == null ? '' : ' ${a['damage']}';
        final effect = a['effect'] == null ? '' : ': ${a['effect']}';
        lines.add('${a['name'] ?? ''}$damage$effect');
      }
    }
    final effect = c['effect'];
    if (effect is String && effect.isNotEmpty) lines.add(effect);
    if (lines.isEmpty) return null;
    return CardText(
      language: language,
      name: (c['name'] ?? '').toString(),
      text: lines.join('\n'),
    );
  }
}
