import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/food_suggestion.dart';
import 'confidence_badge.dart';
import 'density_badge.dart';

class SuggestionCard extends StatelessWidget {
  final FoodSuggestion suggestion;
  final VoidCallback? onTap;

  const SuggestionCard({super.key, required this.suggestion, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.premiumCard(context, radius: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.dishNameEn,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          if (suggestion.dishNameEn != suggestion.dishNameMy)
                            Text(
                              suggestion.dishNameMy,
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (suggestion.source == 'AI Estimate')
                      ConfidenceBadge(
                        level: suggestion.confidence,
                        percent: suggestion.effectiveConfidencePercent,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                DensityBadge(density: suggestion.effectiveCaloricDensity),
                const SizedBox(height: 10),

                // Ingredients
                Text(
                  suggestion.mainIngredients.join(', '),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Portion estimate: ${suggestion.estimatedPortionGrams.toStringAsFixed(0)}g',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),

                // Separator
                Container(
                  height: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                const SizedBox(height: 14),

                // Nutrition wrap (responsive across narrow viewports)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _nutrient(
                      context,
                      '${suggestion.resolvedCalories ?? "~${(suggestion.estimatedPortionGrams * 1.5).round()}"} kcal',
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    if (suggestion.resolvedProteinG != null)
                      _nutrient(context,
                          'P: ${suggestion.resolvedProteinG!.toStringAsFixed(1)}g'),
                    if (suggestion.resolvedCarbsG != null)
                      _nutrient(context,
                          'C: ${suggestion.resolvedCarbsG!.toStringAsFixed(1)}g'),
                    if (suggestion.resolvedFatsG != null)
                      _nutrient(context,
                          'F: ${suggestion.resolvedFatsG!.toStringAsFixed(1)}g'),
                    // Source badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (suggestion.source == 'MyFCD' ||
                                suggestion.source == 'Curated')
                            ? AppColors.myfcdBadge
                            : AppColors.aiBadge,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        suggestion.source,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
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

  Widget _nutrient(BuildContext context, String text,
      {FontWeight fontWeight = FontWeight.w500, Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary(context),
      ),
    );
  }
}
