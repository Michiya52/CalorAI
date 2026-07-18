import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const MacroBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.5) : 0.0;
    final isOver = current > target;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.premiumCard(context, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOver ? AppColors.warning : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              Text(
                '${current.toStringAsFixed(1)}g / ${target.toStringAsFixed(0)}g',
                style: TextStyle(
                  fontSize: 13,
                  color: isOver
                      ? AppColors.warning
                      : AppColors.textSecondary(context),
                  fontWeight: isOver ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  // Track
                  Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOver
                              ? [AppColors.warning, const Color(0xFFF97316)]
                              : [color, color.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
