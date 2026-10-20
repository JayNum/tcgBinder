import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ios.dart';

/// Contact details of the app's provider (Austria: § 5 ECG, § 25 MedienG).
///
/// Fill in [contactEmail] before publishing: Austrian law also wants an
/// e-mail address (or another quick way to reach you).
class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({super.key});

  static const name = 'Wuthichai Siriket';
  static const street = 'Wiener Strasse 21';
  static const city = '2486 Pottendorf';
  static const country = 'Austria';

  /// Set this to your contact e-mail address.
  static const contactEmail = '';

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label, style: TextStyle(color: tokens.muted)),
              ),
              Expanded(child: SelectableText(value)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Impressum')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SectionHeader('Provider of this app'),
          GroupedSection(
            child: Column(
              children: [
                row('Name', name),
                const Divider(height: 1, indent: 16),
                row('Address', '$street\n$city\n$country'),
                if (contactEmail.isNotEmpty) ...[
                  const Divider(height: 1, indent: 16),
                  row('E-mail', contactEmail),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'TCG Binder is a private project. Card data comes from the '
              'public databases listed in Settings. Card names and images '
              'belong to their respective owners; this app is not affiliated '
              'with them.',
              style: TextStyle(fontSize: 13, height: 1.4, color: tokens.muted),
            ),
          ),
        ],
      ),
    );
  }
}
