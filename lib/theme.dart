import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/branding.dart';

class AppTheme {
  /// Active branding for the legacy `AppTheme.brand` / `AppTheme.brandDark`
  /// accessors. Updated by [BrandingProvider] every time agency branding
  /// changes so pre-existing screens that haven't migrated to
  /// [BrandColors.of(context)] still re-theme automatically.
  static Branding _activeBranding = Branding.fallback;

  /// Called by BrandingProvider whenever a new agency branding is applied.
  static void updateActiveBranding(Branding b) {
    _activeBranding = b;
  }

  /// Reactive — returns the current agency button colour. Note this is no
  /// longer a `const` so call sites that previously did
  /// `const TextStyle(color: AppTheme.brand)` must drop the `const`.
  static Color get brand => _activeBranding.button;
  static Color get brandDark => _activeBranding.defaultColor;

  /// Card/button corner radius. Bumped from 6 → 14 to feel less spreadsheet-y.
  static const double radius = 14.0;
  static const double radiusSmall = 8.0;
  static const double radiusLarge = 20.0;

  // --------------- Dark palette ---------------
  static const Color darkBackground = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF13161D);
  static const Color darkSurface2 = Color(0xFF1A1E28);
  static const Color darkBorder = Color(0x14FFFFFF);
  static const Color darkTextPrimary = Color(0xFFEEF0F5);
  static const Color darkTextSecondary = Color(0xFF8890A4);
  static const Color darkTextMuted = Color(0xFF545B6E);

  // --------------- Light palette (warmer off-white) ---------------
  static const Color lightBackground = Color(0xFFFAFAF7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF2F4F9);
  static const Color lightBorder = Color(0x14000000);
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

  /// Soft elevation shadow — one subtle layer, not Material 2 drop-shadow.
  static List<BoxShadow> softShadow(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: dark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.04),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // --------------- ThemeData builders ---------------

  static ThemeData dark(Branding branding) => _buildTheme(
        brightness: Brightness.dark,
        branding: branding,
        background: darkBackground,
        surface: darkSurface,
        border: darkBorder,
        textPrimary: darkTextPrimary,
      );

  static ThemeData light(Branding branding) => _buildTheme(
        brightness: Brightness.light,
        branding: branding,
        background: lightBackground,
        surface: lightSurface,
        border: lightBorder,
        textPrimary: lightTextPrimary,
      );

  // Backwards-compatible getters for code that hasn't been migrated yet.
  static ThemeData get darkTheme => dark(Branding.fallback);
  static ThemeData get lightTheme => light(Branding.fallback);

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Branding branding,
    required Color background,
    required Color surface,
    required Color border,
    required Color textPrimary,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();

    // Inter for body, Plus Jakarta Sans for display/headlines — pairs warm
    // and modern without breaking the data-dense feel of the existing UI.
    final body = GoogleFonts.interTextTheme(base.textTheme);
    final display = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    final mergedText = body.copyWith(
      displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w700, color: textPrimary),
      displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: textPrimary),
      displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: textPrimary),
      headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: textPrimary),
      headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: textPrimary),
      headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: textPrimary),
    );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: branding.button,
        onPrimary: branding.onButton,
        secondary: branding.icon,
        onSecondary: branding.onIcon,
        surface: surface,
        onSurface: textPrimary,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      ),
      textTheme: mergedText,
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
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: branding.button,
          foregroundColor: branding.onButton,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          minimumSize: const Size(double.infinity, 50),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? darkSurface2 : lightSurface2,
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
          borderSide: BorderSide(color: branding.icon, width: 1.5),
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
      extensions: <ThemeExtension<dynamic>>[
        BrandColors.fromBranding(branding),
      ],
    );
  }
}
