import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/portion_scaler.dart';
import '../../models/food_suggestion.dart';
import '../../models/meal_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';

class PortionSelectionScreen extends StatefulWidget {
  final FoodSuggestion suggestion;
  const PortionSelectionScreen({super.key, required this.suggestion});

  @override
  State<PortionSelectionScreen> createState() => _PortionSelectionScreenState();
}

class _PortionSelectionScreenState extends State<PortionSelectionScreen> {
  String _selectedPortion = 'Medium';
  final _customGramsController = TextEditingController();
  late int _displayCalories;
  late double _displayProtein;
  late double _displayCarbs;
  late double _displayFats;
  late double _displayGrams;

  @override
  void initState() {
    super.initState();
    _updateNutrition();
  }

  @override
  void dispose() {
    _customGramsController.dispose();
    super.dispose();
  }

  void _updateNutrition() {
    final suggestion = widget.suggestion;
    if (suggestion.myfcdMatch != null) {
      final scaled = PortionScaler.scale(
        food: suggestion.myfcdMatch!,
        portionLabel: _selectedPortion,
        customGrams: double.tryParse(_customGramsController.text),
      );
      _displayCalories = scaled['calories'] as int;
      _displayProtein = scaled['proteinG'] as double;
      _displayCarbs = scaled['carbsG'] as double;
      _displayFats = scaled['fatsG'] as double;
      _displayGrams = scaled['portionGrams'] as double;
    } else {
      // AI estimate — use estimated portion grams directly
      final portionMultiplier = switch (_selectedPortion) {
        'Small' => 0.7,
        'Large' => 1.4,
        'Custom' => (double.tryParse(_customGramsController.text) ?? 
                     suggestion.estimatedPortionGrams) /
                     suggestion.estimatedPortionGrams,
        _ => 1.0,
      };
      _displayGrams = suggestion.estimatedPortionGrams * portionMultiplier;
      _displayCalories = suggestion.resolvedCalories != null
          ? (suggestion.resolvedCalories! * portionMultiplier).round()
          : (_displayGrams * 1.5).round(); // rough estimate
      _displayProtein = (suggestion.resolvedProteinG ?? _displayGrams * 0.1) * portionMultiplier;
      _displayCarbs = (suggestion.resolvedCarbsG ?? _displayGrams * 0.5) * portionMultiplier;
      _displayFats = (suggestion.resolvedFatsG ?? _displayGrams * 0.15) * portionMultiplier;
    }
    setState(() {});
  }

  Future<void> _confirmAndLog() async {
    final uid = context.read<AuthProvider>().userId;
    if (uid == null) return;

    final now = DateTime.now();
    final entry = MealEntry(
      id: const Uuid().v4(),
      userId: uid,
      date: now.toIso8601String().substring(0, 10),
      timestamp: now,
      foodNameEn: widget.suggestion.dishNameEn,
      foodNameMy: widget.suggestion.dishNameMy,
      myfcdId: widget.suggestion.myfcdMatch?.id,
      source: widget.suggestion.source,
      calories: _displayCalories,
      proteinG: _displayProtein,
      carbsG: _displayCarbs,
      fatsG: _displayFats,
      portionLabel: _selectedPortion,
      portionGrams: _displayGrams,
      aiConfidence: widget.suggestion.confidence,
      imageDeleted: true,
    );

    await context.read<MealProvider>().addMeal(entry);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${entry.foodNameEn} logged!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Portion Size'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Food name
            Text(
              widget.suggestion.dishNameEn,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              widget.suggestion.dishNameMy,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.suggestion.source == 'MyFCD'
                    ? AppColors.myfcdBadge
                    : AppColors.aiBadge,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.suggestion.source,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Portion selector
            Text('Select Portion',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Small', label: Text('S')),
                ButtonSegment(value: 'Medium', label: Text('M')),
                ButtonSegment(value: 'Large', label: Text('L')),
                ButtonSegment(value: 'Custom', label: Text('Custom')),
              ],
              selected: {_selectedPortion},
              onSelectionChanged: (selected) {
                _selectedPortion = selected.first;
                _updateNutrition();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return Colors.white;
                }),
              ),
            ),

            if (_selectedPortion == 'Custom') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customGramsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'GRAMS',
                  hintText: 'Enter weight in grams',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => _updateNutrition(),
              ),
            ],
            const SizedBox(height: 24),

            // Nutrition display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  Text('${_displayGrams.round()}g',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('$_displayCalories',
                      style:
                          Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              )),
                  const Text('kcal'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _macroColumn('Protein',
                          '${_displayProtein.toStringAsFixed(1)}g',
                          const Color(0xFF42A5F5)),
                      _macroColumn('Carbs',
                          '${_displayCarbs.toStringAsFixed(1)}g',
                          AppColors.accent),
                      _macroColumn('Fats',
                          '${_displayFats.toStringAsFixed(1)}g',
                          AppColors.warning),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _confirmAndLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm & Log',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
