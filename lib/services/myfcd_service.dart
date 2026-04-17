import '../models/food_suggestion.dart';
import 'firestore_service.dart';

/// Cross-references Gemini suggestions against government-backed food data.
class MyFCDService {
  final FirestoreService _firestore;
  MyFCDService(this._firestore);

  Future<FoodSuggestion> crossReference(FoodSuggestion suggestion) async {
    try {
      final candidateQueries = <String>{
        suggestion.dishNameEn,
        suggestion.dishNameMy,
        ...suggestion.mainIngredients.take(3),
      }.where((query) => query.trim().isNotEmpty);

      final candidates = <String, dynamic>{};
      for (final query in candidateQueries) {
        final results = await _firestore.searchFoods(query);
        for (final result in results) {
          candidates[result.id] = result;
        }
      }

      final match = candidates.isNotEmpty ? candidates.values.first : null;

      if (match != null) {
        final factor = suggestion.estimatedPortionGrams / 100.0;
        return suggestion.copyWith(
          myfcdMatch: match,
          resolvedCalories: (match.caloriesPer100g * factor).round(),
          resolvedProteinG: match.proteinPer100g * factor,
          resolvedCarbsG: match.carbsPer100g * factor,
          resolvedFatsG: match.fatsPer100g * factor,
          source: 'MyFCD',
        );
      }
    } catch (_) {
      // Fall through to AI estimate fallback when Firestore lookup fails.
    }

    // No MyFCD match or lookup error - keep AI best guess with rough macros.
    final grams = suggestion.estimatedPortionGrams;
    return suggestion.copyWith(
      source: 'AI Estimate',
      resolvedCalories: (grams * 1.5).round(),
      resolvedProteinG: grams * 0.1,
      resolvedCarbsG: grams * 0.5,
      resolvedFatsG: grams * 0.15,
    );
  }

  /// Run cross-reference concurrently on all suggestions
  Future<List<FoodSuggestion>> crossReferenceAll(
          List<FoodSuggestion> suggestions) =>
      Future.wait(suggestions.map(crossReference));
}
