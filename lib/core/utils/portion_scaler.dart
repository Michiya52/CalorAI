import '../../models/food_item.dart';

class PortionScaler {
  static Map<String, dynamic> scale({
    required FoodItem food,
    required String portionLabel,
    double? customGrams,
  }) {
    final double grams = switch (portionLabel) {
      'Small' => food.portionSizes.smallGrams,
      'Large' => food.portionSizes.largeGrams,
      'Custom' => customGrams ?? food.portionSizes.mediumGrams,
      _ => food.portionSizes.mediumGrams, // Default: 'Medium'
    };

    final factor = grams / 100.0;
    return {
      'calories': (food.caloriesPer100g * factor).round(),
      'proteinG': food.proteinPer100g * factor,
      'carbsG': food.carbsPer100g * factor,
      'fatsG': food.fatsPer100g * factor,
      'portionGrams': grams,
    };
  }
}
