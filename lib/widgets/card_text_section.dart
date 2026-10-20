import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../data/settings_store.dart';
import '../models/catalog.dart';
import '../screens/pro_screen.dart';
import '../services/card_text.dart';
import '../theme/app_theme.dart';
import 'ios.dart';

/// "Card text": an expandable block on the card page with the rules text.
/// English is free; the other languages are a Pro feature, except for Magic:
/// Scryfall's rules do not allow its data behind a paywall.
class CardTextSection extends StatefulWidget {
  const CardTextSection({
    super.key,
    required this.card,
    required this.set,
    this.ownedLanguage,
    this.service,
  });

  final CatalogCard card;
  final CardSet set;

  /// The language of the copy the user owns; shown first when available.
  final String? ownedLanguage;
  final CardTextService? service;

  @override
  State<CardTextSection> createState() => _CardTextSectionState();
}

class _CardTextSectionState extends State<CardTextSection> {
  late final CardTextService _service = widget.service ?? CardTextService();
  final _loaded = <String, CardText?>{};
  final _loading = <String>{};
  bool _open = false;
  String _language = 'English';

  List<String> get _languages => CardTextService.languagesFor(widget.card);

  @override
  void initState() {
    super.initState();
    final owned = widget.ownedLanguage;
    if (owned != null && _languages.contains(owned)) _language = owned;
  }

  bool _locked(String language, bool isPro) =>
      language != 'English' && !isPro && widget.card.gameId != 'magic';

  Future<void> _select(String language, bool isPro) async {
    if (_locked(language, isPro)) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProScreen()),
      );
      return;
    }
    setState(() => _language = language);
    await _load(language);
  }

  Future<void> _load(String language) async {
    if (_loaded.containsKey(language) || _loading.contains(language)) return;
    setState(() => _loading.add(language));
    final text = await _service.fetch(widget.card, widget.set, language);
    if (!mounted) return;
    setState(() {
      _loading.remove(language);
      _loaded[language] = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final isPro = SettingsScope.of(context).isPro;
    // A free user reads English, except for Magic where every language is free.
    final language = _locked(_language, isPro) ? 'English' : _language;
    final text = language == 'English' && widget.card.text != null
        ? CardTextService.english(widget.card)
        : _loaded[language];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GroupedSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(Icons.notes_rounded, color: context.accent),
              title: const Text('Card text'),
              subtitle: Text(language),
              trailing: Icon(
                _open
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: tokens.muted,
              ),
              onTap: () {
                setState(() => _open = !_open);
                if (_open) _load(language);
              },
            ),
            if (_open) ...[
              if (_languages.length > 1)
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final l in _languages)
                        PillChip(
                          label: l,
                          selected: l == language,
                          icon: _locked(l, isPro)
                              ? Icons.lock_outline_rounded
                              : null,
                          onTap: () => _select(l, isPro),
                          background: tokens.divider.withValues(alpha: 0.35),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: _body(tokens, language, text, isPro),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(BinderColors tokens, String language, CardText? text, bool isPro) {
    if (_loading.contains(language)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (text == null || text.isEmpty) {
      final onlyEnglish = _languages.length == 1;
      return Text(
        _loaded.containsKey(language)
            ? 'No $language text found for this card.'
            : onlyEnglish
                ? 'No card text available for this card.'
                : 'Loading…',
        style: TextStyle(color: tokens.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.name.isNotEmpty && text.language != 'English')
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              text.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        SelectableText(text.text, style: const TextStyle(fontSize: 15, height: 1.4)),
        if (_languages.length == 1) ...[
          const SizedBox(height: 10),
          Text(
            'This game\'s database only has English text.',
            style: TextStyle(fontSize: 12, color: tokens.muted),
          ),
        ],
      ],
    );
  }
}
