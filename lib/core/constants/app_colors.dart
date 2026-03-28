import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF1B5E20);
  static const accent = Color(0xFFFF7043);

  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);

  static const success = Color(0xFF43A047);
  static const warning = Color(0xFFFFA726);
  static const error = Color(0xFFE53935);

  static const myfcdBadge = Color(0xFF1565C0);
  static const aiBadge = Color(0xFF6A1B9A);

  static Color confidenceColor(String confidence) => switch (confidence) {
    'high' => success,
    'medium' => warning,
    'low' => error,
    _ => textSecondary,
  };
}
