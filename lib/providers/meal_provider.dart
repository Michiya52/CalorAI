import 'package:flutter/foundation.dart';
import '../models/meal_entry.dart';
import '../services/firestore_service.dart';

class MealProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<MealEntry> _todaysMeals = [];
  bool _isLoading = false;

  List<MealEntry> get todaysMeals => _todaysMeals;
  bool get isLoading => _isLoading;

  int get totalCaloriesToday =>
      _todaysMeals.fold(0, (sum, m) => sum + m.calories);

  Map<String, double> get totalMacrosToday => {
        'proteinG': _todaysMeals.fold(0.0, (s, m) => s + m.proteinG),
        'carbsG': _todaysMeals.fold(0.0, (s, m) => s + m.carbsG),
        'fatsG': _todaysMeals.fold(0.0, (s, m) => s + m.fatsG),
      };

  Future<void> loadMealsForDate(String uid, String date) async {
    _isLoading = true;
    notifyListeners();
    _todaysMeals = await _firestore.getMealsForDate(uid, date);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMeal(MealEntry entry) async {
    await _firestore.saveMealEntry(entry);
    _todaysMeals = [..._todaysMeals, entry];
    notifyListeners();
  }

  Future<void> updateMeal(
      String uid, String mealId, Map<String, dynamic> data) async {
    await _firestore.updateMealEntry(uid, mealId, data);
    final date = _todaysMeals.firstWhere((m) => m.id == mealId).date;
    await loadMealsForDate(uid, date);
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
}
