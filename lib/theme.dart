import 'package:flutter/material.dart';

/// Token warna diselaraskan dengan design system web VisualMath AI
/// (Material Design 3, palet indigo).
class Tk {
  final Color bg, sf, ink, mu, ln, ac, on, ac2, ok, okb, er, erb, pl, grid, container, onContainer;
  const Tk(this.bg, this.sf, this.ink, this.mu, this.ln, this.ac, this.on, this.ac2, this.ok, this.okb, this.er, this.erb, this.pl, this.grid, this.container, this.onContainer);
  static const light = Tk(
    Color(0xFFfaf8ff), // surface
    Color(0xFFffffff), // surface container
    Color(0xFF1c1b20), // on-surface
    Color(0xFF464651), // on-surface-variant
    Color(0xFFe2e0e8), // outline-variant
    Color(0xFF3525cd), // primary
    Color(0xFFffffff), // on-primary
    Color(0xFFe9e7ff), // primary-container
    Color(0xFF1b7f3b), // success
    Color(0xFFd2fbdc), // success-container
    Color(0xFFba1a1a), // error
    Color(0xFFffdad6), // error-container
    Color(0xFFe0562b), // plot accent
    Color(0xFFdddbe3), // surface-dim
    Color(0xFFf2f0f7), // surface-container
    Color(0xFF141055),  // on-primary-container
  );
  static const dark = Tk(
    Color(0xFF0e0d14),
    Color(0xFF17161f),
    Color(0xFFe6e1e9),
    Color(0xFFc9c4d0),
    Color(0xFF48454e),
    Color(0xFFc3c0ff),
    Color(0xFF1d0e8f),
    Color(0xFF3d34a8),
    Color(0xFF4fd1a8),
    Color(0xFF12352c),
    Color(0xFFFF8A7A),
    Color(0xFF3D1F1C),
    Color(0xFFFF8A5C),
    Color(0xFF232E4D),
    Color(0xFF2a2832),
    Color(0xFFe9e7ff),
  );
}
Tk tk(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? Tk.dark : Tk.light;

TextStyle monoStyle([double s = 14]) => TextStyle(fontFamily: 'monospace', fontSize: s, fontWeight: FontWeight.w500);

ThemeData buildTheme(Brightness b) {
  final t = b == Brightness.dark ? Tk.dark : Tk.light;
  final base = ThemeData(brightness: b, useMaterial3: true);
  final cs = ColorScheme(
    brightness: b,
    primary: t.ac,
    onPrimary: t.on,
    primaryContainer: t.ac2,
    onPrimaryContainer: t.onContainer,
    secondary: const Color(0xFF006a61),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFc5f2eb),
    onSecondaryContainer: const Color(0xFF04201b),
    tertiary: const Color(0xFF95002b),
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFffd9df),
    onTertiaryContainer: const Color(0xFF40000f),
    error: t.er,
    onError: t.on,
    errorContainer: t.erb,
    onErrorContainer: t.er,
    surface: t.sf,
    onSurface: t.ink,
    surfaceContainerHighest: t.container,
    onSurfaceVariant: t.mu,
    outline: t.mu,
    outlineVariant: t.ln,
  );
  OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
  return base.copyWith(
    colorScheme: cs,
    scaffoldBackgroundColor: t.bg,
    textTheme: base.textTheme.apply(bodyColor: t.ink, displayColor: t.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: t.sf,
      foregroundColor: t.ink,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.ink),
    ),
    cardTheme: CardThemeData(
      color: t.sf,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: t.ln)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: t.ln),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: t.ac)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.container,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: ob(t.ln),
      enabledBorder: ob(t.ln),
      disabledBorder: ob(t.ln),
      focusedBorder: ob(t.ac, 2),
      errorBorder: ob(t.er),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.sf,
      selectedColor: t.ac2,
      side: BorderSide(color: t.ln),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.ink),
      secondaryLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.ac),
    ),
    sliderTheme: SliderThemeData(activeTrackColor: t.ac, thumbColor: t.ac, inactiveTrackColor: t.grid, overlayColor: t.ac.withAlpha(30)),
    dividerTheme: DividerThemeData(color: t.ln, thickness: 1, space: 20),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.ink,
      contentTextStyle: TextStyle(color: t.bg, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.sf,
      indicatorColor: t.ac2,
      labelTextStyle: WidgetStateProperty.all(TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.ink)),
    ),
  );
}