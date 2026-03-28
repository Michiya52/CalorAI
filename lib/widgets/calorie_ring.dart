import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_colors.dart';

class CalorieRing extends StatelessWidget {
  final int consumed;
  final int target;

  const CalorieRing({super.key, required this.consumed, required this.target});

  @override
  Widget build(BuildContext context) {
    final remaining = (target - consumed).clamp(0, target);
    final isOver = consumed > target;

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  value: consumed.toDouble().clamp(0, consumed.toDouble()),
                  color: isOver ? AppColors.error : AppColors.primary,
                  radius: 20,
                  showTitle: false,
                ),
                if (!isOver)
                  PieChartSectionData(
                    value: remaining.toDouble(),
                    color: AppColors.primary.withOpacity(0.15),
                    radius: 20,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$consumed',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isOver ? AppColors.error : AppColors.primaryDark,
                ),
              ),
              Text(
                'of $target kcal',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isOver)
                Text(
                  '${consumed - target} over',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
