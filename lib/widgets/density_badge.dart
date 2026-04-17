import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class DensityBadge extends StatelessWidget {
  final double density;

  const DensityBadge({super.key, required this.density});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.densityColor(density);
    final label = AppColors.densityLabel(density);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconForDensity(density),
            size: 10,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${density.toStringAsFixed(1)} kcal/g ($label)',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForDensity(double density) {
    if (density < 0.6) return Icons.eco_rounded;
    if (density < 1.5) return Icons.restaurant_rounded;
    return Icons.warning_rounded;
  }
}
