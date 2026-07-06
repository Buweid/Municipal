import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary     = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color accent      = Color(0xFFBFA15A);
  static const Color navy        = Color(0xFF0D1B2A);
  static const Color background  = Color(0xFFF5F1E8);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color textPrimary    = Color(0xFF0D1B2A);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color border      = Color(0xFFE5E7EB);
  static const Color error       = Color(0xFFDC2626);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color info        = Color(0xFF3B82F6);
  static const Color purple      = Color(0xFF7C3AED);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> floatShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double spaceSm  = 8;
  static const double spaceMd  = 16;
  static const double spaceLg  = 24;
  static const double spaceXl  = 32;

  // ── SEMANTIC HELPERS ─────────────────────────────────────────────
  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF161B22) : Colors.white;

  static Color backgroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D1117) : const Color(0xFFF5F1E8);

  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF30363D) : const Color(0xFFE5E7EB);

  static Color textPrimaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white : const Color(0xFF0D1B2A);

  static Color textSecondaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8B949E) : const Color(0xFF6B7280);

  static Color shadowColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.transparent : const Color(0x0A000000);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ── LIGHT THEME ──────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  // ── DARK THEME ───────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    dialogBackgroundColor: const Color(0xFF161B22),
    cardColor: const Color(0xFF161B22),
    canvasColor: const Color(0xFF161B22),
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: Color(0xFF161B22),
      error: error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D1117),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF161B22),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF161B22),
      contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF161B22),
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF8B949E),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}