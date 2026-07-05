import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../models/food_suggestion.dart';
import 'firestore_service.dart';

/// A service responsible for taking raw AI food suggestions and matching them
/// against the local database to obtain highly accurate, verified macro profiles.
///
/// This acts as the bridge between the generative AI estimates and the
/// ground-truth database records (like MyFCD and Curated entries).
class MyFCDService {
  final FirestoreService _firestore;
  MyFCDService(this._firestore);

  /// Attempts to find a perfect database match for an AI-generated [FoodSuggestion].
  ///
  /// [Strategy]:
  /// 1. Searches the database using both the English and Malay dish names.
  /// 2. If no name matches are found, it falls back to searching by main ingredients.
  /// 3. If a match is found, it scales the database's 100g nutritional profile
  ///    to the AI's estimated portion size (grams) and overwrites the AI's guesses.
  /// 4. If no match is found, it retains the AI's original estimates.
  Future<FoodSuggestion> crossReference(FoodSuggestion suggestion) async {
    try {
      // Phase 1: Search dish names in parallel (fast path)
      final nameQueries = <String>{
        suggestion.dishNameEn,
        suggestion.dishNameMy,
      }.where((q) => q.trim().isNotEmpty).toList();

      final nameResults = await Future.wait(
        nameQueries.map((q) => _firestore.searchFoods(q, limit: 5)),
      );

      // Collect unique matches
      final candidates = <String, FoodItem>{};
      for (final results in nameResults) {
        for (final item in results) {
          candidates[item.id] = item;
        }
      }

      // Phase 2: Only search ingredients if names didn't match
      if (candidates.isEmpty) {
        final ingredientQueries = suggestion.mainIngredients
            .take(2)
            .where((q) => q.trim().isNotEmpty)
            .toList();

        if (ingredientQueries.isNotEmpty) {
          final ingredientResults = await Future.wait(
            ingredientQueries.map((q) => _firestore.searchFoods(q, limit: 3)),
          );
          for (final results in ingredientResults) {
            for (final item in results) {
              candidates[item.id] = item;
            }
          }
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
          resolvedSodiumG: match.sodiumPer100g * factor,
          resolvedSugarG: match.sugarPer100g * factor,
          source: 'MyFCD',
        );
      }
    } catch (e) {
      debugPrint('MyFCDService.crossReference failed: $e');
      // Fall through to AI estimate fallback when Firestore lookup fails.
    }

    // No MyFCD match or lookup error - use Gemini's estimated macros.
    return suggestion.copyWith(
      source: 'AI Estimate',
      resolvedCalories: suggestion.estimatedCalories,
      resolvedProteinG: suggestion.estimatedProteinG,
      resolvedCarbsG: suggestion.estimatedCarbsG,
      resolvedFatsG: suggestion.estimatedFatsG,
      resolvedSodiumG: suggestion.estimatedSodiumG,
      resolvedSugarG: suggestion.estimatedSugarG,
    );
  }

  /// Run cross-reference concurrently on all suggestions
  Future<List<FoodSuggestion>> crossReferenceAll(
          List<FoodSuggestion> suggestions) =>
      Future.wait(suggestions.map(crossReference));
}
