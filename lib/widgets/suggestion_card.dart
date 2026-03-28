import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/food_suggestion.dart';
import 'confidence_badge.dart';

class SuggestionCard extends StatelessWidget {
  final FoodSuggestion suggestion;
  final VoidCallback? onTap;

  const SuggestionCard({super.key, required this.suggestion, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (suggestion.dishNameEn != suggestion.dishNameMy)
                          Text(
                            suggestion.dishNameMy,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ConfidenceBadge(level: suggestion.confidence),
                ],
              ),
              const SizedBox(height: 8),

              // Ingredients
              Text(
                suggestion.mainIngredients.join(', '),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),

              // Separator
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 12),

              // Nutrition row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _nutrient(
                    '${suggestion.resolvedCalories ?? "~${(suggestion.estimatedPortionGrams * 1.5).round()}"} kcal',
                    fontWeight: FontWeight.bold,
                  ),
                  if (suggestion.resolvedProteinG != null)
                    _nutrient(
                        'P: ${suggestion.resolvedProteinG!.toStringAsFixed(1)}g'),
                  if (suggestion.resolvedCarbsG != null)
                    _nutrient(
                        'C: ${suggestion.resolvedCarbsG!.toStringAsFixed(1)}g'),
                  if (suggestion.resolvedFatsG != null)
                    _nutrient(
                        'F: ${suggestion.resolvedFatsG!.toStringAsFixed(1)}g'),
                  // Source badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: suggestion.source == 'MyFCD'
                          ? AppColors.myfcdBadge
                          : AppColors.aiBadge,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      suggestion.source,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutrient(String text, {FontWeight fontWeight = FontWeight.normal}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: fontWeight,
        color: AppColors.textPrimary,
      ),
    );
  }
}
