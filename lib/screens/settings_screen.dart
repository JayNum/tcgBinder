import 'package:flutter/material.dart';

import '../data/collection_store.dart';
import '../data/sample_catalog.dart';
import '../theme/app_theme.dart';

const _appRows = [
  'Appearance',
  'Preferred marketplace',
  'Restore purchases',
  'Privacy & ad choices',
  'Contact support',
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is coming in a later version.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final store = CollectionScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Surface(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _Stat(value: '${store.totalCards}', label: 'Cards'),
                    const SizedBox(width: 8),
                    _Stat(value: '${sets.length}', label: 'Binders'),
                    const SizedBox(width: 8),
                    _Stat(value: '${games.length}', label: 'Games'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 16, color: context.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your collection is stored only on this phone.',
                        style: TextStyle(fontSize: 12, color: tokens.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PremiumCard(onTap: () => _soon(context, 'Premium')),
          const SizedBox(height: 16),
          const _SectionTitle('Backup & transfer'),
          _Surface(
            child: Column(
              children: [
                _Row(
                  icon: Icons.phonelink_outlined,
                  title: 'Move to a new phone',
                  subtitle: 'Scan a QR code · same Wi-Fi',
                  badge: const _Tag.free(),
                  onTap: () => _soon(context, 'Phone transfer'),
                ),
                _Row(
                  icon: Icons.upload_outlined,
                  title: 'Export backup file',
                  subtitle: 'Cards + photos · last export: never',
                  badge: const _Tag.premium(),
                  onTap: () => _soon(context, 'Backup export'),
                ),
                _Row(
                  icon: Icons.download_outlined,
                  title: 'Import backup file',
                  subtitle: 'Restore a collection from a file',
                  badge: const _Tag.free(),
                  onTap: () => _soon(context, 'Backup import'),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('App'),
          _Surface(
            child: Column(
              children: [
                for (var i = 0; i < _appRows.length; i++)
                  _Row(
                    title: _appRows[i],
                    onTap: () => _soon(context, _appRows[i]),
                    last: i == _appRows.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Version 0.1.0',
              style: TextStyle(fontSize: 11, color: tokens.labelMissing),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = context.onAccent;
    Widget perk(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.check, size: 16, color: fg),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: TextStyle(color: fg, fontSize: 13))),
            ],
          ),
        );
    Widget price(String amount, String per, {bool highlight = false}) => Expanded(
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: highlight ? fg : fg.withValues(alpha: 0.35),
                width: highlight ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amount,
                  style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  highlight ? '$per · save 16%' : per,
                  style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 11),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: context.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PREMIUM',
            style: TextStyle(
              color: fg.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No ads. Never lose your binders.',
            style: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          perk('No banners, no full-screen ads while scanning'),
          perk('Export a backup of your cards and photos'),
          perk('Customize your binders with colors and your own images'),
          const SizedBox(height: 4),
          Row(
            children: [
              price('€2.99', 'per month'),
              const SizedBox(width: 8),
              price('€29.99', 'per year', highlight: true),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: fg,
              foregroundColor: context.accent,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text(
              'Go Premium',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: tokens.pocket,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: numberStyle(color: tokens.text, size: 18)),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag.free() : premium = false;
  const _Tag.premium() : premium = true;

  final bool premium;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: premium ? tokens.accentSoft : tokens.successSoft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (premium) ...[
            Icon(Icons.lock_outline, size: 11, color: tokens.accentSoftText),
            const SizedBox(width: 3),
          ],
          Text(
            premium ? 'Premium' : 'Free',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: premium ? tokens.accentSoftText : tokens.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.badge,
    this.last = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? badge;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: tokens.divider)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: icon == null
            ? null
            : Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: context.accent),
              ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: TextStyle(fontSize: 12, color: tokens.muted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null) badge!,
            Icon(Icons.chevron_right, color: tokens.muted),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: context.binder.muted,
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
