import 'package:flutter/material.dart';

/// Token warna sama dengan versi HTML (:root).
class Tk {
  final Color bg, sf, ink, mu, ln, ac, on, ac2, ok, okb, er, erb, pl, grid;
  const Tk(this.bg, this.sf, this.ink, this.mu, this.ln, this.ac, this.on, this.ac2, this.ok, this.okb, this.er, this.erb, this.pl, this.grid);
  static const light = Tk(Color(0xFFEEF2F8), Color(0xFFFFFFFF), Color(0xFF14213D), Color(0xFF5B6785), Color(0xFFD3DCEB), Color(0xFF4338CA), Color(0xFFFFFFFF), Color(0xFFE8E7FB), Color(0xFF0F8F6F), Color(0xFFDDF3EC), Color(0xFFC0392B), Color(0xFFFBE5E2), Color(0xFFE0562B), Color(0xFFDCE5F2));
  static const dark = Tk(Color(0xFF0E1424), Color(0xFF172038), Color(0xFFE9EEFB), Color(0xFF9AA7C7), Color(0xFF2A3556), Color(0xFF8E8CFF), Color(0xFF0E1424), Color(0xFF25285A), Color(0xFF4FD1A8), Color(0xFF12352C), Color(0xFFFF8A7A), Color(0xFF3D1F1C), Color(0xFFFF8A5C), Color(0xFF232E4D));
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
    secondary: t.ac,
    onSecondary: t.on,
    tertiary: t.ok,
    onTertiary: t.on,
    error: t.er,
    onError: t.on,
    surface: t.sf,
    onSurface: t.ink,
    secondaryContainer: t.ac2,
    onSecondaryContainer: t.ac,
    tertiaryContainer: t.okb,
    onTertiaryContainer: t.ok,
    errorContainer: t.erb,
    onErrorContainer: t.er,
    outline: t.mu,
    outlineVariant: t.ln,
  );
  OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));
  return base.copyWith(
    colorScheme: cs,
    scaffoldBackgroundColor: t.bg,
    textTheme: base.textTheme.apply(bodyColor: t.ink, displayColor: t.ink),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: t.ac)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: ob(t.ln),
      enabledBorder: ob(t.ln),
      disabledBorder: ob(t.ln),
      focusedBorder: ob(t.ac, 2),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.sf,
      selectedColor: t.ac,
      side: BorderSide(color: t.ln),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.ink),
      secondaryLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.on),
    ),
    sliderTheme: SliderThemeData(activeTrackColor: t.ac, thumbColor: t.ac, inactiveTrackColor: t.grid, overlayColor: t.ac.withAlpha(30)),
    dividerTheme: DividerThemeData(color: t.ln, thickness: 1, space: 20),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.ink,
      contentTextStyle: TextStyle(color: t.bg, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
