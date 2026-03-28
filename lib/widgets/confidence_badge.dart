import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ConfidenceBadge extends StatelessWidget {
  final String level;

  const ConfidenceBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.confidenceColor(level).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: AppColors.confidenceColor(level),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
