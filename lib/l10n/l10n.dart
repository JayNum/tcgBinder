import 'package:flutter/material.dart' hide Text;
import 'package:flutter/widgets.dart' as w;

import '../data/settings_store.dart';
import 'german.dart';

/// Which language the app shows. The setting is `system`, `en` or `de`.
class AppLanguage {
  const AppLanguage._();

  static const system = 'system';

  /// The language in use right now: `en` or `de`.
  static String current = 'en';

  /// Works out the language from the user's choice and the phone's language.
  static String resolve(String setting, String phoneLanguageCode) {
    if (setting == 'en' || setting == 'de') return setting;
    return phoneLanguageCode.toLowerCase() == 'de' ? 'de' : 'en';
  }
}

/// Translates a built-in English text when the app is in German. Texts
/// without a translation stay as they are.
String tr(String english) {
  if (AppLanguage.current != 'de') return english;
  return translateToGerman(english);
}

/// Like Flutter's `Text`, but shows the German version of its string when the
/// app language is German. It redraws itself when the language changes.
class Text extends StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  }) : span = null;

  const Text.rich(
    InlineSpan this.span, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  }) : data = null;

  final String? data;
  final InlineSpan? span;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    // Subscribe to language changes (the scope may be missing in tests).
    context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    final s = span;
    if (s != null) {
      return w.Text.rich(
        s,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      );
    }
    return w.Text(
      tr(data!),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
