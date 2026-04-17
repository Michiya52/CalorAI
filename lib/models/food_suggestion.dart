import 'food_item.dart';

class FoodSuggestion {
  final int rank;
  final String dishNameEn;
  final String dishNameMy;
  final List<String> mainIngredients;
  final double estimatedPortionGrams;
  final String confidence; // 'high' | 'medium' | 'low'
  final int? confidencePercent;
  final String cookingMethod;
  final double? caloricDensity;

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
    this.confidencePercent,
    required this.cookingMethod,
    this.caloricDensity,
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
        confidencePercent: map['confidencePercent'] as int?,
        cookingMethod: map['cookingMethod'] as String,
        caloricDensity: (map['caloricDensity'] as num?)?.toDouble(),
      );

  int get effectiveConfidencePercent {
    if (confidencePercent != null) {
      return confidencePercent!.clamp(0, 100);
    }
    return switch (confidence.toLowerCase()) {
      'high' => 85,
      'low' => 45,
      _ => 65,
    };
  }

  FoodSuggestion copyWith({
    FoodItem? myfcdMatch,
    int? resolvedCalories,
    double? resolvedProteinG,
    double? resolvedCarbsG,
    double? resolvedFatsG,
    String? source,
    int? confidencePercent,
    double? caloricDensity,
  }) {
    return FoodSuggestion(
      rank: rank,
      dishNameEn: dishNameEn,
      dishNameMy: dishNameMy,
      mainIngredients: mainIngredients,
      estimatedPortionGrams: estimatedPortionGrams,
      confidence: confidence,
      confidencePercent: confidencePercent ?? this.confidencePercent,
      cookingMethod: cookingMethod,
      myfcdMatch: myfcdMatch ?? this.myfcdMatch,
      resolvedCalories: resolvedCalories ?? this.resolvedCalories,
      resolvedProteinG: resolvedProteinG ?? this.resolvedProteinG,
      resolvedCarbsG: resolvedCarbsG ?? this.resolvedCarbsG,
      resolvedFatsG: resolvedFatsG ?? this.resolvedFatsG,
      source: source ?? this.source,
      caloricDensity: caloricDensity ?? this.caloricDensity,
    );
  }

  double get effectiveCaloricDensity {
    if (caloricDensity != null) return caloricDensity!;
    if (resolvedCalories != null && estimatedPortionGrams > 0) {
      return resolvedCalories! / estimatedPortionGrams;
    }
    return 0.0;
  }
}
