import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_item.dart';
import '../../models/food_suggestion.dart';
import '../../services/firestore_service.dart';

class ManualSearchScreen extends StatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  State<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends State<ManualSearchScreen> {
  final _searchController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();
  Timer? _debounce;
  List<FoodItem> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    _results = await _firestore.searchFoods(query);
    if (mounted) setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Food'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search for a food...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_isSearching)
            const LinearProgressIndicator()
          else if (_results.isEmpty && _searchController.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text('No results found',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final food = _results[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(food.nameEn,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${food.nameMy} • ${food.caloriesPer100g.toStringAsFixed(0)} kcal/100g',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.myfcdBadge,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('MyFCD',
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                      onTap: () {
                        // Create a FoodSuggestion from the FoodItem
                        final suggestion = FoodSuggestion(
                          rank: 1,
                          dishNameEn: food.nameEn,
                          dishNameMy: food.nameMy,
                          mainIngredients: [food.foodGroup],
                          estimatedPortionGrams:
                              food.portionSizes.mediumGrams,
                          confidence: 'high',
                          cookingMethod: '',
                          myfcdMatch: food,
                          resolvedCalories:
                              (food.caloriesPer100g *
                                      food.portionSizes.mediumGrams /
                                      100)
                                  .round(),
                          resolvedProteinG: food.proteinPer100g *
                              food.portionSizes.mediumGrams /
                              100,
                          resolvedCarbsG: food.carbsPer100g *
                              food.portionSizes.mediumGrams /
                              100,
                          resolvedFatsG: food.fatsPer100g *
                              food.portionSizes.mediumGrams /
                              100,
                          source: 'MyFCD',
                        );
                        context.push('/log/portion', extra: suggestion);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
