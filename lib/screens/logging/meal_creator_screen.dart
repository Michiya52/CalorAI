import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/meal_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/meal_ingredient_tile.dart';
import 'ingredient_library_browser.dart';

class MealCreatorScreen extends StatefulWidget {
  const MealCreatorScreen({super.key});

  @override
  State<MealCreatorScreen> createState() => _MealCreatorScreenState();
}

class _MealCreatorScreenState extends State<MealCreatorScreen> {
  final _mealNameController = TextEditingController();
  final List<IngredientDetail> _ingredients = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _mealNameController.dispose();
    super.dispose();
  }

  int get _totalCalories =>
      _ingredients.fold(0, (sum, item) => sum + item.calories);
  double get _totalProtein =>
      _ingredients.fold(0.0, (sum, item) => sum + item.proteinG);
  double get _totalCarbs =>
      _ingredients.fold(0.0, (sum, item) => sum + item.carbsG);
  double get _totalFats =>
      _ingredients.fold(0.0, (sum, item) => sum + item.fatsG);
  double get _totalWeight =>
      _ingredients.fold(0.0, (sum, item) => sum + item.grams);

  void _addIngredient(IngredientDetail detail) {
    setState(() {
      _ingredients.add(detail);
    });
    // Don't auto-pop if we want them to pick multiples in the library,
    // but the library is currently popping. This is fine.
  }

  void _updateIngredientWeight(int index, double newWeight) {
    if (newWeight <= 0) return;
    final item = _ingredients[index];
    final ratio = newWeight / item.grams;

    setState(() {
      _ingredients[index] = IngredientDetail(
        name: item.name,
        grams: newWeight,
        calories: (item.calories * ratio).round(),
        proteinG: item.proteinG * ratio,
        carbsG: item.carbsG * ratio,
        fatsG: item.fatsG * ratio,
        sourceId: item.sourceId,
      );
    });
  }

  Future<void> _saveMeal() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient.')),
      );
      return;
    }

    final name = _mealNameController.text.trim().isEmpty
        ? 'Homecooked Meal'
        : _mealNameController.text.trim();

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      final newMeal = MealEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        date: DateTime.now().toIso8601String().split('T').first,
        timestamp: DateTime.now(),
        foodNameEn: name,
        foodNameMy: name,
        source: 'Composite',
        calories: _totalCalories,
        proteinG: _totalProtein,
        carbsG: _totalCarbs,
        fatsG: _totalFats,
        portionLabel: 'Custom',
        portionGrams: _totalWeight,
        imageDeleted: true,
        ingredients: _ingredients,
      );

      await context.read<MealProvider>().addMeal(newMeal);
    }
    setState(() => _isSaving = false);

    if (mounted) {
      context.go('/home'); // Return to dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meal'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _mealNameController,
                    decoration: InputDecoration(
                      labelText: 'Meal Name (e.g. My Chicken Rice)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ingredients',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IngredientLibraryBrowser(
                                onIngredientSelected: _addIngredient,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle,
                            color: AppColors.primary),
                        label: const Text('Browse Library',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_ingredients.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No ingredients added yet.\nTap "Browse Library" to start cooking!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._ingredients.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return MealIngredientTile(
                        ingredient: item,
                        onWeightChanged: (newGrams) =>
                            _updateIngredientWeight(idx, newGrams),
                        onRemove: () =>
                            setState(() => _ingredients.removeAt(idx)),
                      );
                    }),
                ],
              ),
            ),
            _buildActionFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_totalCalories',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(width: 4),
              const Text('kcal', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _macroStat('Protein', _totalProtein, Colors.blue),
              _macroStat('Carbs', _totalCarbs, AppColors.accent),
              _macroStat('Fats', _totalFats, AppColors.warning),
            ],
          ),
          const SizedBox(height: 8),
          Text('Total Weight: ${_totalWeight.toStringAsFixed(0)}g',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _macroStat(String label, double val, Color color) {
    return Column(
      children: [
        Text('${val.toStringAsFixed(1)}g',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveMeal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Cook & Log Meal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
