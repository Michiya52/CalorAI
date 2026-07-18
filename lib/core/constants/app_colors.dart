import 'package:flutter/material.dart';
import '../../theme.dart';

class AppColors {
  AppColors._();

  static const primary = AppTheme.primary;
  static const primaryLight = AppTheme.primaryFixed;
  static const primaryDark = AppTheme.primaryContainer;
  static const accent = AppTheme.secondary;
  static const aura = AppTheme.tertiary;

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = AppTheme.error;

  static const myfcdBadge = Color(0xFF3B82F6);
  static const aiBadge = AppTheme.tertiary;

  // Theme-dependent colors go through Theme.of(context) so widgets
  // rebuild when the theme changes.

  static Color background(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color surface(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.brightness == Brightness.dark
        ? cs.surfaceContainerLow
        : cs.surfaceContainerLowest;
  }

  static Color surfaceContainer(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  // ─── Gradient Helpers ────────────────────────────────────────────────

  static LinearGradient primaryGradient(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkPrimaryGradient
          : AppTheme.primaryGradient;

  static const auraGradient = AppTheme.auraGradient;

  // ─── Glassmorphism ───────────────────────────────────────────────────

  static BoxDecoration glassCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
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
  }

  static BoxDecoration premiumCard(BuildContext context, {double radius = 20}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: surface(context),
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
  }

  // ─── Confidence ──────────────────────────────────────────────────────

  static Color confidenceColor(String confidence) => switch (confidence) {
        'high' => success,
        'medium' => warning,
        'low' => error,
        _ => Colors.grey,
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
