import 'food_item.dart';

class FoodSuggestion {
  final int rank;
  final String dishNameEn;
  final String dishNameMy;
  final List<String> mainIngredients;
  final double estimatedPortionGrams;
  final String confidence; // 'high' | 'medium' | 'low'
  final String cookingMethod;

  // Populated after MyFCD cross-reference step:
  final FoodItem? myfcdMatch;
  final int? resolvedCalories;
  final double? resolvedProteinG;
  final double? resolvedCarbsG;
  final double? resolvedFatsG;
  final String source; // 'MyFCD' | 'AI Estimate'

  const FoodSuggestion({
    required this.rank,
    required this.dishNameEn,
    required this.dishNameMy,
    required this.mainIngredients,
    required this.estimatedPortionGrams,
    required this.confidence,
    required this.cookingMethod,
    this.myfcdMatch,
    this.resolvedCalories,
    this.resolvedProteinG,
    this.resolvedCarbsG,
    this.resolvedFatsG,
    this.source = 'AI Estimate',
  });

  factory FoodSuggestion.fromMap(Map<String, dynamic> map) => FoodSuggestion(
    rank: map['rank'] as int,
    dishNameEn: map['dishNameEn'] as String,
    dishNameMy: map['dishNameMy'] as String,
    mainIngredients: List<String>.from(map['mainIngredients'] as List),
    estimatedPortionGrams: (map['estimatedPortionGrams'] as num).toDouble(),
    confidence: map['confidence'] as String,
    cookingMethod: map['cookingMethod'] as String,
  );

  FoodSuggestion copyWith({
    FoodItem? myfcdMatch,
    int? resolvedCalories,
    double? resolvedProteinG,
    double? resolvedCarbsG,
    double? resolvedFatsG,
    String? source,
  }) {
    return FoodSuggestion(
      rank: rank,
      dishNameEn: dishNameEn,
      dishNameMy: dishNameMy,
      mainIngredients: mainIngredients,
      estimatedPortionGrams: estimatedPortionGrams,
      confidence: confidence,
      cookingMethod: cookingMethod,
      myfcdMatch: myfcdMatch ?? this.myfcdMatch,
      resolvedCalories: resolvedCalories ?? this.resolvedCalories,
      resolvedProteinG: resolvedProteinG ?? this.resolvedProteinG,
      resolvedCarbsG: resolvedCarbsG ?? this.resolvedCarbsG,
      resolvedFatsG: resolvedFatsG ?? this.resolvedFatsG,
      source: source ?? this.source,
    );
  }
}
