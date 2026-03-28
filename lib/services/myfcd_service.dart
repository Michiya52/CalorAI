import '../models/food_suggestion.dart';
import 'firestore_service.dart';

/// Cross-references Gemini suggestions against MyFCD database.
class MyFCDService {
  final FirestoreService _firestore;
  MyFCDService(this._firestore);

  Future<FoodSuggestion> crossReference(FoodSuggestion suggestion) async {
    // 1. Try exact English name
    var match = await _firestore.getFoodByName(suggestion.dishNameEn);
    // 2. Try exact Malay name
    match ??= await _firestore.getFoodByName(suggestion.dishNameMy);
    // 3. Try prefix search
    if (match == null) {
      final results = await _firestore.searchFoods(suggestion.dishNameEn);
      if (results.isNotEmpty) match = results.first;
    }

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

    // No MyFCD match — use Gemini's estimate directly
    return suggestion.copyWith(source: 'AI Estimate');
  }

  /// Run cross-reference concurrently on all suggestions
  Future<List<FoodSuggestion>> crossReferenceAll(
      List<FoodSuggestion> suggestions) =>
      Future.wait(suggestions.map(crossReference));
}
