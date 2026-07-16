import 'package:flutter/foundation.dart';
import '../services/logger_service.dart';
import 'package:flutter/widgets.dart';
import '../models/meal_entry.dart';
import '../services/firestore_service.dart';

/// Manages the state of the user's daily meals.
///
/// This provider fetches the meals for a specific date from [FirestoreService],
/// tallies the total calories and macros, and automatically notifies the UI
/// (like the Dashboard) whenever a meal is added, updated, or deleted.
class MealProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<MealEntry> _todaysMeals = [];
  bool _isLoading = false;

  List<MealEntry> get todaysMeals => _todaysMeals;
  bool get isLoading => _isLoading;

  int get totalCaloriesToday =>
      _todaysMeals.fold(0, (sum, m) => sum + m.calories);

  /// Calculates the total combined macros for all meals eaten on this date.
  Map<String, double> get totalMacrosToday => {
        'proteinG': _todaysMeals.fold(0.0, (s, m) => s + m.proteinG),
        'carbsG': _todaysMeals.fold(0.0, (s, m) => s + m.carbsG),
        'fatsG': _todaysMeals.fold(0.0, (s, m) => s + m.fatsG),
      };

  /// Fetches the meal history for a specific date (YYYY-MM-DD) from Firestore.
  Future<void> loadMealsForDate(String uid, String date) async {
    _isLoading = true;
    notifyListeners();
    try {
      _todaysMeals = await _firestore.getMealsForDate(uid, date);
    } catch (e, stack) {
      LoggerService().error(e, stack, reason: 'Failed to load meals for $date');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMeal(MealEntry entry) async {
    await _firestore.saveMealEntry(entry);
    _todaysMeals = [..._todaysMeals, entry];
    notifyListeners();
  }

  Future<void> updateMeal(
      String uid, String mealId, Map<String, dynamic> data) async {
    await _firestore.updateMealEntry(uid, mealId, data);
    final meal = _todaysMeals.cast<MealEntry?>().firstWhere(
          (m) => m?.id == mealId,
          orElse: () => null,
        );
    if (meal != null) {
      await loadMealsForDate(uid, meal.date);
    }
  }

  Future<void> deleteMeal(String uid, String mealId) async {
    await _firestore.deleteMealEntry(uid, mealId);
    _todaysMeals = _todaysMeals.where((m) => m.id != mealId).toList();
    notifyListeners();
  }

  Future<List<MealEntry>> getMealsForDateRange(
      String uid, String start, String end) async {
    return await _firestore.getMealsForDateRange(uid, start, end);
  }

  void clear() {
    _todaysMeals = [];
    notifyListeners();
  }
}
