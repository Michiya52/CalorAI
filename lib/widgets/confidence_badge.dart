import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ConfidenceBadge extends StatelessWidget {
  final String level;
  final int? percent;

  const ConfidenceBadge({super.key, required this.level, this.percent});

  @override
  Widget build(BuildContext context) {
    if (percent == null && level.isEmpty) return const SizedBox.shrink();

    final color = AppColors.confidenceColor(level.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        percent != null ? '$percent%' : level.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
