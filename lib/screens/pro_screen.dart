import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../data/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ios.dart';

/// What TCG Binder Pro gives, and the two plans. Purchases are not switched
/// on yet: the button explains that.
class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  bool _yearly = true;

  static const _features = <(IconData, Color, String, String)>[
    (
      Icons.block_rounded,
      Color(0xFF34C759),
      'No ads',
      'No banners and no daily video. Just your cards.',
    ),
    (
      Icons.translate_rounded,
      Color(0xFF5AC8FA),
      'Card text in every language',
      'Read the printed card text in German, French, Japanese and more '
          '(Magic and Pokémon).',
    ),
    (
      Icons.image_search_rounded,
      Color(0xFFFF2D55),
      'Recognise by artwork',
      'Scan a card and the app finds it by its picture, then you confirm. '
          'Works when the code is hard to read.',
    ),
    (
      Icons.cloud_download_rounded,
      Color(0xFF007AFF),
      'Backup & restore',
      'Save your whole collection, photos included, as one file. Keep it '
          'anywhere and restore it on any phone.',
    ),
    (
      Icons.palette_rounded,
      Color(0xFFAF52DE),
      'Binder looks',
      'Choose colours and covers, or use your own images for every binder.',
    ),
    (
      Icons.burst_mode_rounded,
      Color(0xFFFF9500),
      'Batch scanning',
      'Scan a whole stack in a row. The camera stays open and files each card.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Scaffold(
      appBar: AppBar(title: const Text('TCG Binder Pro')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5856D6), Color(0xFFAF52DE), Color(0xFFFF2D55)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  'Get more from your binders',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your collection stays free and on your phone. Pro adds '
                  'tools for people with big collections.',
                  style: TextStyle(fontSize: 15, height: 1.35, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Included'),
          GroupedSection(
            child: Column(
              children: [
                for (var i = 0; i < _features.length; i++) ...[
                  if (i > 0) const Divider(indent: 64),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _features[i].$2,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(_features[i].$1, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _features[i].$3,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _features[i].$4,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.3,
                                  color: tokens.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Moving to a new phone stays free for everyone.',
              style: TextStyle(fontSize: 13, color: tokens.muted),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Plan(
                  title: 'Monthly',
                  price: '€2.99',
                  note: 'per month',
                  selected: !_yearly,
                  onTap: () => setState(() => _yearly = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Plan(
                  title: 'Yearly',
                  price: '€29.99',
                  note: 'per year · save 16%',
                  selected: _yearly,
                  onTap: () => setState(() => _yearly = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final settings = SettingsScope.of(context);
              if (kDebugMode) {
                // Debug builds only: flip Pro on and off to try the features.
                settings.setPro(!settings.isPro);
                return;
              }
              confirmDialog(
                context,
                title: 'Not switched on yet',
                message: 'Subscriptions are not connected in this test '
                    'version, so nothing was charged.',
                confirmLabel: 'OK',
              );
            },
            child: Text(
              kDebugMode
                  ? (SettingsScope.of(context).isPro
                      ? 'Switch Pro off (test build)'
                      : 'Switch Pro on (test build)')
                  : 'Continue',
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Restore purchases'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Plan extends StatelessWidget {
  const _Plan({
    required this.title,
    required this.price,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String price;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? context.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: tokens.muted)),
              const SizedBox(height: 4),
              Text(
                price,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              Text(note, style: TextStyle(fontSize: 12, color: tokens.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
