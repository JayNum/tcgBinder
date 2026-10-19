import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder. Next: camera preview + on-device text recognition that reads
/// the set code and collector number, then a confirm sheet.
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan cards')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.document_scanner_outlined, size: 56, color: context.accent),
              const SizedBox(height: 16),
              const Text(
                'Scanning is coming next',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Point the camera at a card: the app reads its set number, '
                'finds it in the catalog and files your photo into the binder.',
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
