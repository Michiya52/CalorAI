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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  )),
              Text(
                '${current.toStringAsFixed(1)}g / ${target.toStringAsFixed(0)}g',
                style: TextStyle(
                  fontSize: 12,
                  color: isOver ? AppColors.warning : AppColors.textSecondary,
                  fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(
                  isOver ? AppColors.warning : color),
            ),
          ),
        ],
      ),
    );
  }
}
