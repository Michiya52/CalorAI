import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette translated from Tailwind config
  static const Color primary = Color(0xFF0D631B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF2E7D32);
  static const Color onPrimaryContainer = Color(0xFFCBFFC2);
  static const Color primaryFixed = Color(0xFFA3F69C);
  static const Color onPrimaryFixed = Color(0xFF002204);

  static const Color secondary = Color(0xFFAC3509);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFE6F42);
  static const Color onSecondaryContainer = Color(0xFF631800);
  static const Color secondaryFixed = Color(0xFFFFDBD0);
  static const Color onSecondaryFixed = Color(0xFF3A0A00);

  static const Color tertiary = Color(0xFF6A3BAC);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF8355C7);
  static const Color onTertiaryContainer = Color(0xFFF8EDFF);
  static const Color tertiaryFixed = Color(0xFFEDDCFF);
  static const Color onTertiaryFixed = Color(0xFF280056);

  static const Color surface = Color(0xFFF9F9F9);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF40493D);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);

  static const Color outline = Color(0xFF707A6C);
  static const Color outlineVariant = Color(0xFFBFCABA);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

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
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w800,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.inter(
          color: onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.inter(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.inter(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      iconTheme: const IconThemeData(color: onSurface),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w900,
          fontSize: 24,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.inter(color: onSurfaceVariant.withOpacity(0.4)),
        labelStyle: GoogleFonts.inter(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
