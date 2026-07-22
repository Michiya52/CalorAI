import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── "Forest & Aura" Color Palette ───────────────────────────────────

  // Primary — Vibrant Mint/Emerald
  static const Color primary = Color(0xFF05CE91);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF003824);
  static const Color onPrimaryContainer = Color(0xFF8AF8D4);
  static const Color primaryFixed = Color(0xFF8AF8D4);
  static const Color onPrimaryFixed = Color(0xFF003824);

  // Secondary — Vibrant Coral/Orange
  static const Color secondary = Color(0xFFFF6B4A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFDADA);
  static const Color onSecondaryContainer = Color(0xFF410000);
  static const Color secondaryFixed = Color(0xFFFFDADA);
  static const Color onSecondaryFixed = Color(0xFF410000);

  // Tertiary — Vibrant Blue
  static const Color tertiary = Color(0xFF007BFF);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFCCE5FF);
  static const Color onTertiaryContainer = Color(0xFF004085);
  static const Color tertiaryFixed = Color(0xFFCCE5FF);
  static const Color onTertiaryFixed = Color(0xFF004085);

  // Surfaces — Subtle Light Mode
  static const Color surface = Color(0xFFFAFCFB);
  static const Color onSurface = Color(0xFF1C1D1D);
  static const Color onSurfaceVariant = Color(0xFF6F7477);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F7F6);
  static const Color surfaceContainer = Color(0xFFEDF1F0);
  static const Color surfaceContainerHigh = Color(0xFFE7EBEA);
  static const Color surfaceContainerHighest = Color(0xFFE1E5E4);

  // Outline
  static const Color outline = Color(0xFF757A79);
  static const Color outlineVariant = Color(0xFFC3C8C7);

  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  // ─── Dark Theme Palette ──────────────────────────────────────────────

  static const Color darkPrimary = Color(0xFF26E0A6);
  static const Color darkOnPrimary = Color(0xFF003824);
  static const Color darkPrimaryContainer = Color(0xFF005236);
  static const Color darkOnPrimaryContainer = Color(0xFF8AF8D4);

  static const Color darkSecondary = Color(0xFFFFB4A1);
  static const Color darkOnSecondary = Color(0xFF5E1605);
  static const Color darkSecondaryContainer = Color(0xFF7E2C19);
  static const Color darkOnSecondaryContainer = Color(0xFFFFDADA);

  static const Color darkTertiary = Color(0xFF66B2FF);
  static const Color darkOnTertiary = Color(0xFF002752);
  static const Color darkTertiaryContainer = Color(0xFF004085);
  static const Color darkOnTertiaryContainer = Color(0xFFCCE5FF);

  static const Color darkSurface = Color(0xFF101413);
  static const Color darkOnSurface = Color(0xFFE1E3E2);
  static const Color darkOnSurfaceVariant = Color(0xFFBFC4C3);
  static const Color darkSurfaceContainerLowest = Color(0xFF0B0F0E);
  static const Color darkSurfaceContainerLow = Color(0xFF1B211F);
  static const Color darkSurfaceContainer = Color(0xFF232927);
  static const Color darkSurfaceContainerHigh = Color(0xFF2C3230);
  static const Color darkSurfaceContainerHighest = Color(0xFF373D3B);

  static const Color darkOutline = Color(0xFF898E8D);
  static const Color darkOutlineVariant = Color(0xFF3F4443);

  static const Color darkError = Color(0xFFF87171);
  static const Color darkOnError = Color(0xFF450A0A);
  static const Color darkErrorContainer = Color(0xFF7F1D1D);
  static const Color darkOnErrorContainer = Color(0xFFFEE2E2);

  // ─── Gradient helpers ────────────────────────────────────────────────

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF05CE91), Color(0xFF00A26F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient auraGradient = LinearGradient(
    colors: [Color(0xFF007BFF), Color(0xFFFF6B4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFF26E0A6), Color(0xFF05CE91)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Light Theme ─────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: _buildTextTheme(onSurface, onSurfaceVariant),
      iconTheme: const IconThemeData(color: onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: surfaceContainerLowest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: primary.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle:
            GoogleFonts.inter(color: onSurfaceVariant.withValues(alpha: 0.5)),
        labelStyle: GoogleFonts.inter(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        primaryContainer: darkPrimaryContainer,
        onPrimaryContainer: darkOnPrimaryContainer,
        secondary: darkSecondary,
        onSecondary: darkOnSecondary,
        secondaryContainer: darkSecondaryContainer,
        onSecondaryContainer: darkOnSecondaryContainer,
        tertiary: darkTertiary,
        onTertiary: darkOnTertiary,
        tertiaryContainer: darkTertiaryContainer,
        onTertiaryContainer: darkOnTertiaryContainer,
        surface: darkSurface,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        surfaceContainerLowest: darkSurfaceContainerLowest,
        surfaceContainerLow: darkSurfaceContainerLow,
        surfaceContainer: darkSurfaceContainer,
        surfaceContainerHigh: darkSurfaceContainerHigh,
        surfaceContainerHighest: darkSurfaceContainerHighest,
        error: darkError,
        onError: darkOnError,
        errorContainer: darkErrorContainer,
        onErrorContainer: darkOnErrorContainer,
        outline: darkOutline,
        outlineVariant: darkOutlineVariant,
      ),
      scaffoldBackgroundColor: darkSurface,
      textTheme: _buildTextTheme(darkOnSurface, darkOnSurfaceVariant),
      iconTheme: const IconThemeData(color: darkOnSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: darkPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkOnSurface,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: darkSurfaceContainerLow,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: BorderSide(color: darkPrimary.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: darkOnSurfaceVariant.withValues(alpha: 0.6),
        ),
        labelStyle: GoogleFonts.inter(
          color: darkOnSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: darkOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  // ─── Shared Text Theme ───────────────────────────────────────────────

  static TextTheme _buildTextTheme(Color bodyColor, Color captionColor) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: bodyColor,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        color: captionColor,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.inter(
        color: bodyColor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        color: captionColor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        color: captionColor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
