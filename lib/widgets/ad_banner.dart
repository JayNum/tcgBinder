import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder for the 320×50 AdMob banner. Hidden for Premium users later.
class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      // heightFactor 1: only as tall as the banner, also when used as a
      // Scaffold's bottomNavigationBar (which would otherwise fill the screen).
      child: Center(
        heightFactor: 1,
        child: Container(
          width: 320,
          height: 50,
          decoration: BoxDecoration(
            color: tokens.adBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: tokens.pocketBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            'Ad · banner placeholder',
            style: TextStyle(fontSize: 12, color: tokens.muted),
          ),
        ),
      ),
    );
  }
}
