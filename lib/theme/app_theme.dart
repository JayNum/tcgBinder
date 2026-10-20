import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show NoDefaultCupertinoThemeData;

// iOS system colours (systemBlue), so the app feels at home on an iPhone.
const _accentLight = Color(0xFF007AFF);
const _accentDark = Color(0xFF0A84FF);

/// Design tokens from the mockups, available via `context.binder`.
@immutable
class BinderColors extends ThemeExtension<BinderColors> {
  const BinderColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.divider,
    required this.text,
    required this.muted,
    required this.pocket,
    required this.pocketBorder,
    required this.labelMissing,
    required this.cardEdge,
    required this.accentSoft,
    required this.accentSoftText,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.adBackground,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color divider;
  final Color text;
  final Color muted;
  final Color pocket;
  final Color pocketBorder;
  final Color labelMissing;
  final Color cardEdge;
  final Color accentSoft;
  final Color accentSoftText;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color adBackground;

  // Grouped-list look: grey page, white rows, hairline separators.
  static const light = BinderColors(
    background: Color(0xFFF2F2F7), // systemGroupedBackground
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE5E5EA),
    divider: Color(0xFFD1D1D6),
    text: Color(0xFF000000),
    muted: Color(0xFF6C6C70),
    pocket: Color(0xFFF2F2F7),
    pocketBorder: Color(0xFFD1D1D6),
    labelMissing: Color(0xFF6C6C70),
    cardEdge: Color(0xFFE5E5EA),
    accentSoft: Color(0xFFE5F0FF),
    accentSoftText: Color(0xFF0058B8),
    success: Color(0xFF1E7B34),
    successSoft: Color(0xFFE3F5E8),
    danger: Color(0xFFD70015),
    adBackground: Color(0xFFE5E5EA),
  );

  static const dark = BinderColors(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E), // secondarySystemGroupedBackground
    border: Color(0xFF2C2C2E),
    divider: Color(0xFF38383A),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFF98989F),
    pocket: Color(0xFF2C2C2E),
    pocketBorder: Color(0xFF48484A),
    labelMissing: Color(0xFF98989F),
    cardEdge: Color(0xFFD9D4C6),
    accentSoft: Color(0xFF0A2A52),
    accentSoftText: Color(0xFF7DB8FF),
    success: Color(0xFF30D158),
    successSoft: Color(0xFF12301B),
    danger: Color(0xFFFF453A),
    adBackground: Color(0xFF1C1C1E),
  );

  @override
  BinderColors copyWith() => this;

  @override
  BinderColors lerp(ThemeExtension<BinderColors>? other, double t) {
    if (other is! BinderColors) return this;
    return t < 0.5 ? this : other;
  }
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final tokens = isDark ? BinderColors.dark : BinderColors.light;
  final accent = isDark ? _accentDark : _accentLight;

  final scheme = ColorScheme.fromSeed(
    seedColor: _accentLight,
    brightness: brightness,
  ).copyWith(
    primary: accent,
    onPrimary: Colors.white,
    surface: tokens.background,
    onSurface: tokens.text,
    error: tokens.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    // iOS behaviour everywhere: swipe-back, bouncy scrolling, no ripples.
    platform: TargetPlatform.iOS,
    splashFactory: NoSplash.splashFactory,
    scaffoldBackgroundColor: tokens.background,
    dividerColor: tokens.divider,
    extensions: [tokens],
    cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
      brightness: brightness,
      primaryColor: accent,
      scaffoldBackgroundColor: tokens.background,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: tokens.text,
      displayColor: tokens.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.background,
      foregroundColor: tokens.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: tokens.text,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: tokens.divider,
      thickness: 0.5,
      space: 0.5,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: accent,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: tokens.text,
      ),
      subtitleTextStyle: TextStyle(fontSize: 13, color: tokens.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        side: BorderSide.none,
        backgroundColor: tokens.accentSoft,
        foregroundColor: accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: tokens.surface,
      selectedColor: accent,
      secondarySelectedColor: accent,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: tokens.text,
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      checkmarkColor: Colors.white,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF34C759)
            : null,
      ),
    ),
  );
}

extension BinderThemeX on BuildContext {
  BinderColors get binder => Theme.of(this).extension<BinderColors>()!;
  Color get accent => Theme.of(this).colorScheme.primary;
  Color get onAccent => Theme.of(this).colorScheme.onPrimary;
}

/// Monospaced style for set numbers like `004/102`.
TextStyle numberStyle({
  required Color color,
  double size = 11,
  FontWeight weight = FontWeight.w600,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: const ['Courier New', 'Courier'],
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
