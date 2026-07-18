import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weight_log.dart';
import '../core/constants/app_colors.dart';

class WeightChart extends StatelessWidget {
  final List<WeightLog> logs;

  const WeightChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No weight logs yet.\nStart logging to see your progress!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
      );
    }

    final sortedLogs = List<WeightLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = sortedLogs.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weightKg);
    }).toList();

    final minWeight =
        sortedLogs.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
    final maxWeight =
        sortedLogs.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);

    // Dynamic interval based on range
    final range = maxWeight - minWeight;
    final interval = range > 10 ? 5.0 : (range > 5 ? 2.0 : 1.0);

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding:
            const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color:
                      AppColors.textSecondary(context).withValues(alpha: 0.1),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < 0 ||
                        value.toInt() >= sortedLogs.length) {
                      return const SizedBox();
                    }
                    // Show max 5 labels to prevent overlapping
                    final showLabel = sortedLogs.length <= 5 ||
                        value.toInt() % (sortedLogs.length / 5).ceil() == 0 ||
                        value.toInt() == sortedLogs.length - 1;

                    if (!showLabel) return const SizedBox();

                    final date = DateTime.parse(sortedLogs[value.toInt()].date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${date.day}/${date.month}',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary(context))),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary(context)));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX:
                (sortedLogs.length > 1 ? sortedLogs.length - 1 : 1).toDouble(),
            minY: (minWeight - interval).floorToDouble(),
            maxY: (maxWeight + interval).ceilToDouble(),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
