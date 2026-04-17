import 'package:flutter/material.dart';
import '../../theme.dart';

class AppColors {
  AppColors._();

  static const primary = AppTheme.primary;
  static const primaryLight = AppTheme.primaryFixed;
  static const primaryDark = AppTheme.primaryContainer;
  static const accent = AppTheme.secondary;
  static const aura = AppTheme.tertiary;

  static ThemeMode _themeMode = ThemeMode.system;

  static void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
  }

  static bool get isDark {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  static Color get background =>
      isDark ? AppTheme.darkSurface : AppTheme.surface;
  static Color get surface =>
      isDark ? const Color(0xFF1E293B) : AppTheme.surfaceContainerLowest;
  static Color get surfaceContainer =>
      isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow;
  static Color get textPrimary =>
      isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
  static Color get textSecondary =>
      isDark ? AppTheme.darkOnSurfaceVariant : AppTheme.onSurfaceVariant;

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = AppTheme.error;

  static const myfcdBadge = Color(0xFF3B82F6);
  static const aiBadge = Color(0xFF8B5CF6);

  // ─── Gradient Helpers ────────────────────────────────────────────────

  static LinearGradient get primaryGradient =>
      isDark ? AppTheme.darkPrimaryGradient : AppTheme.primaryGradient;

  static const auraGradient = AppTheme.auraGradient;

  static LinearGradient get shimmerGradient => LinearGradient(
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF334155)]
            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
      );

  // ─── Glassmorphism ───────────────────────────────────────────────────

  static BoxDecoration get glassCard => BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration premiumCard({double radius = 20}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration gradientCard({
    required LinearGradient gradient,
    double radius = 20,
  }) =>
      BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      );

  // ─── Confidence ──────────────────────────────────────────────────────

  static Color confidenceColor(String confidence) => switch (confidence) {
        'high' => success,
        'medium' => warning,
        'low' => error,
        _ => textSecondary,
      };

  static Color densityColor(double density) {
    if (density < 0.6) return success; // Low density
    if (density < 1.5) return warning; // Medium density
    return error; // High density
  }

  static String densityLabel(double density) {
    if (density < 0.6) return 'Low';
    if (density < 1.5) return 'Med';
    return 'High';
  }
}
