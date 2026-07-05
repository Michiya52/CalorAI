import 'food_item.dart';

/// Represents a highly flexible, hybrid food record.
///
/// A [FoodSuggestion] is initially born from the AI's best guess (based on
/// image recognition or fuzzy text search). It contains `estimatedX` fields.
///
/// Later, if [MyFCDService] successfully matches it to a real database entry,
/// the `resolvedX` fields are populated with ground-truth data scaled to
/// the user's estimated portion size.
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

  // AI-estimated macros
  final int estimatedCalories;
  final double estimatedProteinG;
  final double estimatedCarbsG;
  final double estimatedFatsG;
  final double estimatedSodiumG;
  final double estimatedSugarG;

  // Populated after MyFCD cross-reference step:
  final FoodItem? myfcdMatch;
  final int? resolvedCalories;
  final double? resolvedProteinG;
  final double? resolvedCarbsG;
  final double? resolvedFatsG;
  final double? resolvedSodiumG;
  final double? resolvedSugarG;
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
    required this.estimatedCalories,
    required this.estimatedProteinG,
    required this.estimatedCarbsG,
    required this.estimatedFatsG,
    required this.estimatedSodiumG,
    required this.estimatedSugarG,
    this.myfcdMatch,
    this.resolvedCalories,
    this.resolvedProteinG,
    this.resolvedCarbsG,
    this.resolvedFatsG,
    this.resolvedSodiumG,
    this.resolvedSugarG,
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
        estimatedCalories: (map['estimatedCalories'] as num).toInt(),
        estimatedProteinG: (map['estimatedProteinG'] as num).toDouble(),
        estimatedCarbsG: (map['estimatedCarbsG'] as num).toDouble(),
        estimatedFatsG: (map['estimatedFatsG'] as num).toDouble(),
        estimatedSodiumG: (map['estimatedSodiumG'] as num?)?.toDouble() ?? 0.0,
        estimatedSugarG: (map['estimatedSugarG'] as num?)?.toDouble() ?? 0.0,
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
    double? resolvedSodiumG,
    double? resolvedSugarG,
    String? source,
    int? confidencePercent,
    double? caloricDensity,
    int? estimatedCalories,
    double? estimatedProteinG,
    double? estimatedCarbsG,
    double? estimatedFatsG,
    double? estimatedSodiumG,
    double? estimatedSugarG,
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
      resolvedSodiumG: resolvedSodiumG ?? this.resolvedSodiumG,
      resolvedSugarG: resolvedSugarG ?? this.resolvedSugarG,
      source: source ?? this.source,
      caloricDensity: caloricDensity ?? this.caloricDensity,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      estimatedProteinG: estimatedProteinG ?? this.estimatedProteinG,
      estimatedCarbsG: estimatedCarbsG ?? this.estimatedCarbsG,
      estimatedFatsG: estimatedFatsG ?? this.estimatedFatsG,
      estimatedSodiumG: estimatedSodiumG ?? this.estimatedSodiumG,
      estimatedSugarG: estimatedSugarG ?? this.estimatedSugarG,
    );
  }

  double get effectiveCaloricDensity {
    if (caloricDensity != null) return caloricDensity!;
    if (resolvedCalories != null && estimatedPortionGrams > 0) {
      return resolvedCalories! / estimatedPortionGrams;
    }
    if (estimatedCalories > 0 && estimatedPortionGrams > 0) {
      return estimatedCalories / estimatedPortionGrams;
    }
    return 0.0;
  }
}
