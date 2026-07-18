import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/meal_entry.dart';
import 'density_badge.dart';

class MealCard extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback? onTap;

  const MealCard({super.key, required this.meal, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.premiumCard(context, radius: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Food icon with gradient background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.restaurant_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              meal.foodNameEn,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DensityBadge(density: meal.effectiveCaloricDensity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${meal.portionLabel} \u2022 ${meal.portionGrams.toStringAsFixed(0)}g \u2022 ${meal.source}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Calories
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${meal.calories}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
