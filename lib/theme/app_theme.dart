import 'package:flutter/material.dart';

const _accentLight = Color(0xFF2B50D6);
const _accentDark = Color(0xFF8FA3FF);

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

  static const light = BinderColors(
    background: Color(0xFFF4F2EE),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE3E0D8),
    divider: Color(0xFFEEEBE4),
    text: Color(0xFF18181B),
    muted: Color(0xFF5E5D58),
    pocket: Color(0xFFF6F5F1),
    pocketBorder: Color(0xFFDCD8CE),
    labelMissing: Color(0xFF6E6C66),
    cardEdge: Color(0xFFEEEAE0),
    accentSoft: Color(0xFFECEFFB),
    accentSoftText: Color(0xFF2B3E8F),
    success: Color(0xFF1F6B45),
    successSoft: Color(0xFFE7F3EC),
    danger: Color(0xFFB42318),
    adBackground: Color(0xFFECE9E2),
  );

  static const dark = BinderColors(
    background: Color(0xFF111214),
    surface: Color(0xFF1B1D21),
    border: Color(0xFF2A2D33),
    divider: Color(0xFF26292E),
    text: Color(0xFFEDEDEF),
    muted: Color(0xFFA1A3A9),
    pocket: Color(0xFF15171A),
    pocketBorder: Color(0xFF33363D),
    labelMissing: Color(0xFF8E9198),
    cardEdge: Color(0xFFD9D4C6),
    accentSoft: Color(0xFF1E2335),
    accentSoftText: Color(0xFFB4C2FF),
    success: Color(0xFF7FD3A1),
    successSoft: Color(0xFF16301F),
    danger: Color(0xFFFF8A7A),
    adBackground: Color(0xFF1A1C20),
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
    onPrimary: isDark ? const Color(0xFF0E1430) : Colors.white,
    // App bars and the scaffold sit on the page background; cards and lists
    // use `context.binder.surface` explicitly.
    surface: tokens.background,
    onSurface: tokens.text,
    error: tokens.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.background,
    dividerColor: tokens.divider,
    extensions: [tokens],
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: tokens.text,
      displayColor: tokens.text,
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
