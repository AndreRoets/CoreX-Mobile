import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand (shared across themes)
  static const Color brand = Color(0xFF0EA5E9);
  static const Color brandDark = Color(0xFF0B2A4A);

  static const double radius = 6.0;

  // --------------- Dark palette ---------------
  static const Color darkBackground = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF13161D);
  static const Color darkSurface2 = Color(0xFF1A1E28);
  static const Color darkBorder = Color(0x0FFFFFFF);
  static const Color darkTextPrimary = Color(0xFFEEF0F5);
  static const Color darkTextSecondary = Color(0xFF8890A4);
  static const Color darkTextMuted = Color(0xFF545B6E);

  // --------------- Light palette ---------------
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF0F2F8);
  static const Color lightBorder = Color(0x12000000);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF9CA3AF);

  // --- Convenience accessors (theme-aware) ---
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground;
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;
  static Color surface2(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface2 : lightSurface2;
  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : lightBorder;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;
  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextMuted : lightTextMuted;

  // --------------- ThemeData builders ---------------

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        background: darkBackground,
        surface: darkSurface,
        border: darkBorder,
        textPrimary: darkTextPrimary,
      );

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        background: lightBackground,
        surface: lightSurface,
        border: lightBorder,
        textPrimary: lightTextPrimary,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color border,
    required Color textPrimary,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: brand,
        onPrimary: Colors.white,
        secondary: brand,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(radius)),
          side: BorderSide(color: border),
        ),
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(6),
        thumbColor: WidgetStateProperty.all(
          brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary,
        ),
      ),
    );
  }
}
